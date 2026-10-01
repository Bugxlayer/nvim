local M = {}

---@param dir string
---@return string|nil
local function venv_in_dir(dir)
	if dir == nil or dir == "" then
		return nil
	end
	local venv = vim.fs.joinpath(dir, ".venv")
	if vim.fn.isdirectory(venv) == 1 then
		return venv
	end
	return nil
end

--- Walk upward from a directory looking for `.venv`.
---@param start_dir string
---@return string|nil
local function find_venv_upwards(start_dir)
	local dir = vim.fn.fnamemodify(start_dir, ":p")
	while dir and dir ~= "" do
		local venv = venv_in_dir(dir)
		if venv then
			return venv
		end
		local parent = vim.fs.dirname(dir)
		if not parent or parent == dir then
			break
		end
		dir = parent
	end
	return nil
end

--- Nearest `.venv` for the buffer, then cwd.
---@param bufnr? integer
---@return string|nil
function M.get_venv(bufnr)
	bufnr = bufnr or 0
	local bufname = vim.api.nvim_buf_get_name(bufnr)

	if bufname ~= "" then
		local start = vim.fn.isdirectory(bufname) == 1 and bufname
			or vim.fs.dirname(vim.fn.fnamemodify(bufname, ":p"))
		local venv = find_venv_upwards(start)
		if venv then
			return venv
		end
	end

	return find_venv_upwards(vim.fn.getcwd())
end

function M.get_python(bufnr)
	local venv = M.get_venv(bufnr)

	if venv then
		local python = venv .. "/bin/python"

		if vim.fn.executable(python) == 1 then
			return python
		end
	end

	return vim.fn.exepath("python3")
end

--- `.venv` at or above a project root directory.
---@param root_dir string
---@return string|nil
function M.venv_for_root(root_dir)
	return venv_in_dir(root_dir) or find_venv_upwards(root_dir)
end

--- Settings fragment for Pyright when a venv is found.
---@param bufnr? integer
---@return table|nil
function M.pyright_venv_settings(bufnr)
	local venv = M.get_venv(bufnr)
	if not venv then
		return nil
	end
	return {
		python = {
			venvPath = vim.fs.dirname(venv),
			venv = vim.fn.fnamemodify(venv, ":t"),
		},
	}
end

return M
