local M = {}

local ROOT_MARKERS = { ".git", "package.json", "pyproject.toml", "go.mod", "Cargo.toml" }

---@param path string
---@return string
local function normalize(path)
	return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

M._session_root = nil
M.started_with_directory = false

local function capture_session()
	for _, arg in ipairs(vim.v.argv) do
		if arg ~= "-" and arg:sub(1, 1) ~= "-" and vim.fn.isdirectory(arg) == 1 then
			M.started_with_directory = true
			M._session_root = normalize(arg)
			return
		end
	end
	M._session_root = normalize(vim.uv.cwd() or vim.fn.getcwd())
end

--- Directory Neovim was started with (e.g. `nvim .config/nvim`), else initial cwd.
---@return string
function M.session_root()
	if not M._session_root then
		capture_session()
	end
	return M._session_root
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = capture_session,
})

---@param ancestor string
---@param path string
---@return boolean
local function is_ancestor(ancestor, path)
	ancestor = normalize(ancestor)
	path = normalize(path)
	if ancestor == path then
		return false
	end
	return vim.startswith(path, ancestor .. "/")
end

--- Nearest project root, never above the session directory from startup.
---@param search_path string
---@return string
local function resolve_root(search_path)
	search_path = normalize(search_path)
	local session = M.session_root()
	local found = vim.fs.root(search_path, ROOT_MARKERS)

	if not found then
		if is_ancestor(session, search_path) or session == search_path then
			return session
		end
		return search_path
	end

	found = normalize(found)
	if found ~= session and is_ancestor(found, session) then
		return session
	end
	return found
end

---@param bufnr integer
---@return boolean
local function is_tree_buffer(bufnr)
	if vim.api.nvim_buf_get_option(bufnr, "filetype") == "netrw" then
		return true
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	return name:match("NetrwTreeListing$") ~= nil
end

--- Root for Telescope / search: scoped to session dir when no local marker.
---@param bufnr? integer
---@return string
function M.project_root(bufnr)
	local session = M.session_root()
	if M.started_with_directory then
		return session
	end

	bufnr = bufnr or 0
	local cwd = normalize(vim.uv.cwd() or vim.fn.getcwd())
	local name = vim.api.nvim_buf_get_name(bufnr)
	local search = cwd

	if name ~= "" then
		if vim.fn.isdirectory(name) == 1 then
			search = normalize(name)
		else
			search = normalize(vim.fn.fnamemodify(name, ":h"))
		end
	end

	if not is_ancestor(session, search) and session ~= search then
		search = cwd
	end

	return resolve_root(search)
end

--- Display path: relative to project root, else cwd, else ~.
---@param bufnr? integer
---@return string
function M.get(bufnr)
	bufnr = bufnr or 0
	if is_tree_buffer(bufnr) then
		return ""
	end
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		return "[No Name]"
	end

	local root = resolve_root(vim.fn.fnamemodify(name, ":h"))
	local rel = vim.fs.relpath(root, name)
	if rel and rel ~= "" and not vim.startswith(rel, "/") then
		return rel
	end

	local rel_cwd = vim.fn.fnamemodify(name, ":.")
	if rel_cwd ~= name and not vim.startswith(rel_cwd, "/") then
		return rel_cwd
	end

	return vim.fn.fnamemodify(name, ":~:.")
end

---@param name string
---@param is_dir boolean
---@return string
local function segment_hl(name, is_dir)
	if name:sub(1, 1) == "." then
		return is_dir and "FocusPathHiddenDir" or "FocusPathHidden"
	end
	return is_dir and "Directory" or "FocusPathFilename"
end

--- Statusline-style path: directories colored; dot segments dimmer.
---@param bufnr? integer
---@return string
function M.get_colored(bufnr)
	local path = M.get(bufnr)
	if path == "" or path == "[No Name]" then
		return path
	end

	local function hl(group, text)
		return "%#" .. group .. "#" .. text
	end

	local parts = vim.split(path, "/", { plain = true })
	local file = table.remove(parts)
	local chunks = {}

	for _, seg in ipairs(parts) do
		if seg ~= "" then
			table.insert(chunks, hl(segment_hl(seg, true), seg .. "/"))
		end
	end

	if file and file ~= "" then
		table.insert(chunks, hl(segment_hl(file, false), file))
	end

	return table.concat(chunks)
end

return M
