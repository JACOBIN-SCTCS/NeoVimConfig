-- Copied from https://moritzhamann.com/blog/2024-10-27-logging-in-neovim.html

--- @class LogOptions
--- @field namespace string namespace the log belongs to

local M = {}

--- @param msg string|table<string> log message (either single line or array
---                                 of lines to accept vim.inspect() output)
--- @param level integer|nil log level defined in vim.log.levels
--- @param options LogOptions allows us to set different logging namespaces
M.log = function(msg, level, options)
	-- extracting a namespace to determine which buffer to log to
	local opts = options or {}
	local ns = opts.namespace or "default"

	-- find the corresponding buffer and if there is no such buffer, create one
	local buffer_name = M.buffer_name(ns)
	local buffer = M.find_log_buffer(buffer_name)
	if buffer == nil then
		buffer = vim.api.nvim_create_buf(true, true)
		vim.api.nvim_buf_set_name(buffer, buffer_name)
	end

	-- transform the integer log level to its string representation.
	local level_str = "INFO"
	for l, i in pairs(vim.log.levels) do
		if level == i then
			level_str = l
		end
	end

	-- ensure `msg` is always a table to make processing simpler
	if type(msg) == "string" then
		msg = { msg }
	end

	-- Split `msg` on newlines, since nvim_buf_set_lines() does not like them
	msg = vim.tbl_map(function(line)
		return vim.split(line, "\n")
	end, msg)
	msg = vim.iter(msg):flatten(1):totable()

	-- for each line add the log level
	local complete_msg = vim.tbl_map(function(line)
		return "[" .. level_str .. "] " .. line
	end, msg)

	-- actually add the lines to the buffer
	vim.api.nvim_buf_set_lines(buffer, -1, -1, true, complete_msg)
end

--- @param namespace string
M.buffer_name = function(namespace)
	return "LOG-" .. namespace
end

--- @param buffer_name string
M.find_log_buffer = function(buffer_name)
	local buffer_list = vim.api.nvim_list_bufs()
	for _, buf_num in ipairs(buffer_list) do
		local name = vim.fn.bufname(buf_num)
		if name == buffer_name then
			return buf_num
		end
	end
	return nil
end

--- @param namespace string
M.create_logger = function(namespace)
	local opts = { namespace = namespace }
	local logging_func_for = function(level)
		return function(msg)
			M.log(msg, level, opts)
		end
	end

	return {
		trace = logging_func_for(vim.log.levels.TRACE),
		debug = logging_func_for(vim.log.levels.DEBUG),
		info = logging_func_for(vim.log.levels.INFO),
		warn = logging_func_for(vim.log.levels.WARN),
		error = logging_func_for(vim.log.levels.ERROR),
	}
end

return M
