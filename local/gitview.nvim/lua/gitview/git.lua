local config = require("gitview.config")
local util = require("gitview.util")

local M = {}

---@param start_path string?
---@return Gitview.Repo|nil repo
---@return string|nil err
function M.find_root(start_path)
  local cfg = config.get()
  local path = start_path or vim.loop.cwd()

  if vim.fn.filereadable(path) == 1 then
    path = vim.fn.fnamemodify(path, ":h")
  end

  local git_dir = vim.fs.find(".git", { upward = true, path = path, type = "directory" })[1]
    or vim.fs.find(".git", { upward = true, path = path, type = "file" })[1]

  if git_dir then
    local root = vim.fn.fnamemodify(git_dir, ":h")
    return { root = root, git_cmd = cfg.git.cmd }, nil
  end

  local obj = vim.system(
    { cfg.git.cmd, "-C", path, "rev-parse", "--show-toplevel" },
    { text = true, cwd = path }
  ):wait()

  if obj.code ~= 0 or not obj.stdout then
    return nil, (obj.stderr or "not a git repository"):gsub("\n$", "")
  end

  local root = obj.stdout:gsub("\n$", "")
  return { root = root, git_cmd = cfg.git.cmd }, nil
end

---@param repo Gitview.Repo
---@param argv string[]
---@param on_done fun(stdout: string|nil, stderr: string|nil)
function M.run_async(repo, argv, on_done)
  local cmd = { repo.git_cmd, "-C", repo.root, unpack(argv) }
  vim.system(cmd, { text = true, cwd = repo.root }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        on_done(nil, (obj.stderr or ""):gsub("\n$", ""))
      else
        on_done(obj.stdout or "", nil)
      end
    end)
  end)
end

---@param repo Gitview.Repo
---@param argv string[]
---@return string|nil stdout
---@return string|nil stderr
function M.run_sync(repo, argv)
  local cmd = { repo.git_cmd, "-C", repo.root, unpack(argv) }
  local obj = vim.system(cmd, { text = true, cwd = repo.root }):wait()
  if obj.code ~= 0 then
    return nil, (obj.stderr or ""):gsub("\n$", "")
  end
  return obj.stdout or "", nil
end

function M.status_async(repo, on_done)
  local cfg = config.get()
  local untracked = cfg.untracked_files == "all" and "all" or "normal"
  M.run_async(repo, {
    "status",
    "--porcelain=v2",
    "-z",
    "--untracked-files=" .. untracked,
  }, on_done)
end

---@param rev Gitview.Revision
---@param path string
---@param path_old string|nil
function M.revision_label(rev, path, path_old)
  if rev.kind == "HEAD" then
    if path_old then
      return "HEAD:" .. path_old
    end
    return "HEAD:" .. path
  elseif rev.kind == "INDEX" then
    return "INDEX:" .. path
  elseif rev.kind == "WORKTREE" then
    return "WORKTREE:" .. path
  elseif rev.kind == "EMPTY" then
    return "(empty)"
  end
  return path
end

---@param repo Gitview.Repo
---@param rev Gitview.Revision
---@param path string
---@param path_old string|nil
---@param on_done fun(content: string|nil, err: string|nil, binary: boolean)
function M.load_revision_async(repo, rev, path, path_old, on_done)
  if rev.kind == "EMPTY" then
    on_done(nil, nil, false)
    return
  end

  if rev.kind == "WORKTREE" then
    local abs = util.join_path(repo.root, path)
    vim.schedule(function()
      local stat = vim.uv.fs_stat(abs)
      if not stat then
        on_done(nil, "file not in working tree", false)
        return
      end
      if stat.size > config.get().max_file_size then
        on_done(nil, "file too large for diff", false)
        return
      end
      local fd = io.open(abs, "r")
      if not fd then
        on_done(nil, "cannot read file", false)
        return
      end
      local data = fd:read("*a")
      fd:close()
      if data and data:find("\0", 1, true) then
        on_done(nil, nil, true)
      else
        on_done(data or "", nil, false)
      end
    end)
    return
  end

  local show_path = path
  if rev.kind == "HEAD" and path_old then
    show_path = path_old
  end

  local ref = rev.kind == "INDEX" and (":" .. show_path) or ("HEAD:" .. show_path)
  M.run_async(repo, { "show", ref }, function(stdout, stderr)
    if stderr and stderr ~= "" then
      if stderr:find("exists on disk") or stderr:find("does not exist") then
        on_done(nil, nil, false)
        return
      end
      on_done(nil, stderr, false)
      return
    end
    if stdout and stdout:find("\0", 1, true) then
      on_done(nil, nil, true)
    else
      on_done(stdout or "", nil, false)
    end
  end)
end

function M.is_binary_async(repo, path, on_done)
  M.run_async(repo, { "diff", "--no-ext-diff", "--numstat", "HEAD", "--", path }, function(out)
    if not out or out == "" then
      M.run_async(repo, { "diff", "--no-ext-diff", "--numstat", "--cached", "--", path }, function(out2)
        local line = out2 and out2:match("[^\n]+") or ""
        local a, b = line:match("^(%S+)%s+(%S+)")
        on_done(a == "-" and b == "-")
      end)
      return
    end
    local line = out:match("[^\n]+") or ""
    local a, b = line:match("^(%S+)%s+(%S+)")
    on_done(a == "-" and b == "-")
  end)
end

function M.stage_paths(repo, paths, on_done)
  local argv = { "add", "--" }
  for _, p in ipairs(paths) do
    table.insert(argv, p)
  end
  M.run_async(repo, argv, function(_, err)
    on_done(err == nil, err)
  end)
end

function M.unstage_paths(repo, paths, on_done)
  if #paths == 0 then
    on_done(true, nil)
    return
  end
  local argv = { "restore", "--staged", "--" }
  for _, p in ipairs(paths) do
    table.insert(argv, p)
  end
  M.run_async(repo, argv, function(_, err)
    on_done(err == nil, err)
  end)
end

function M.stage_all(repo, on_done)
  M.run_async(repo, { "add", "-A" }, function(_, err)
    on_done(err == nil, err)
  end)
end

function M.unstage_all(repo, on_done)
  M.run_async(repo, { "restore", "--staged", "." }, function(_, err)
    on_done(err == nil, err)
  end)
end

function M.current_branch_async(repo, on_done)
  M.run_async(repo, { "branch", "--show-current" }, function(out, err)
    if err then
      on_done(nil, err)
      return
    end
    on_done((out or ""):gsub("\n$", ""), nil)
  end)
end

function M.ahead_behind_async(repo, on_done)
  M.run_async(repo, { "rev-list", "--left-right", "--count", "HEAD...@{upstream}" }, function(out, err)
    if err then
      on_done(0, 0, err)
      return
    end
    local ahead, behind = util.parse_ahead_behind(out)
    on_done(ahead, behind, nil)
  end)
end

function M.commit_async(repo, on_done)
  M.run_async(repo, { "commit" }, function(_, err)
    on_done(err == nil, err)
  end)
end

function M.push_async(repo, on_done)
  M.run_async(repo, { "push" }, function(_, err)
    on_done(err == nil, err)
  end)
end

function M.pull_async(repo, on_done)
  M.run_async(repo, { "pull" }, function(_, err)
    on_done(err == nil, err)
  end)
end

--- Unified diff for path (worktree vs index or HEAD depending on staged)
function M.diff_unified_async(repo, path, cached, on_done)
  local argv = { "diff", "--no-color", "-U3" }
  if cached then
    table.insert(argv, "--cached")
  end
  table.insert(argv, "--")
  table.insert(argv, path)
  M.run_async(repo, argv, on_done)
end

function M.apply_hunk_async(repo, patch, cached, on_done)
  local tmp = vim.fn.tempname()
  local f = io.open(tmp, "w")
  if not f then
    on_done(false, "cannot write temp patch")
    return
  end
  f:write(patch)
  f:close()

  local argv = { "apply" }
  if cached then
    table.insert(argv, "--cached")
  end
  table.insert(argv, tmp)

  M.run_async(repo, argv, function(_, err)
    vim.fn.delete(tmp)
    on_done(err == nil, err)
  end)
end

return M
