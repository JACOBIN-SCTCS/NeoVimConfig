local M = {}

local tomcat_job_id = nil
local buffer_id = nil

local MACOS_IDENTIFIER = "Darwin"
local WINDOWS_IDENTIFIER = "Windows_NT"

local logger = require("custom.logger").create_logger("javaserver_logs")

-- windows equivalent of listing  dir /a /b
-- Identifying the OS : print(vim.loop.os_uname().sysname)
--
if vim.loop.os_uname().sysname == MACOS_IDENTIFIER then
	M.tomcatdirectory = "/Users/depressedcoder/Downloads/apache-tomcat-10.1.44/"
elseif vim.loop.os_uname().sysname == WINDOWS_IDENTIFIER then
	--M.tomcatdirectory = "C:\\Users\\X\\Downloads\\apache-tomcat-10.1.46\\apache-tomcat-10.1.46"
	M.tomcatdirectory = "C:\\Users\\X\\Downloads\\apache-tomcat-8.0.1\\apache-tomcat-8.0.1"
end

local function validateDefaultTomcatApps(app_name)
	local defaultApps = { "docs", "examples", "host-manager", "manager", "ROOT" }
	for index, app in ipairs(defaultApps) do
		if app == app_name then
			return true
		end
	end
	return false
end

local function scanTomcatWebAppsFolder()
	local i, t, popen = 0, {}, io.popen
	local pfile = nil

	if vim.loop.os_uname().sysname == WINDOWS_IDENTIFIER then
		--pfile = popen("dir /a /b " .. M.tomcatdirectory .. "/webapps/")

		local enumerationcommand = 'for /f "delims=" %i in (\'dir /a /b '
			.. M.tomcatdirectory
			.. "\\webapps') do @echo "
			.. M.tomcatdirectory
			.. "\\webapps\\%i"
		--logger.info(enumerationcommand)
		pfile = popen(enumerationcommand)
	elseif vim.loop.os_uname().sysname == MACOS_IDENTIFIER then
		pfile = popen('ls -a -d -1 "' .. M.tomcatdirectory .. '/webapps/"**')
	end

	--local pfile = popen('ls -a -d -1 "' .. M.tomcatdirectory .. 'webapps/"**')
	if pfile ~= nil then
		for filename in pfile:lines() do
			i = i + 1
			t[i] = filename
			--logger.info(filename)
		end
		pfile:close()
	end
	return t
end

function M.cleanWebAppsFolder()
	local folders = scanTomcatWebAppsFolder()
	for _, folder in ipairs(folders) do
		local foldername = vim.fn.fnamemodify(folder, ":t")
		if not validateDefaultTomcatApps(foldername) then
			--logger.info("Deleting " .. folder)
			vim.fs.rm(folder, {
				recursive = true,
			})
		end
	end
end

function M.startTomcat(debug)
	--local bufnr = vim.api.nvim_win_call()

	debug = debug or false

	local runcommand = nil
	local script_suffix = ".sh"

	if vim.loop.os_uname().sysname == WINDOWS_IDENTIFIER then
		vim.env.CATALINA_HOME = M.tomcatdirectory
		script_suffix = ".bat"
	else
		script_suffix = ".sh"
	end

	if debug then
		if vim.loop.os_uname().sysname == WINDOWS_IDENTIFIER then
			runcommand = M.tomcatdirectory .. "\\bin\\catalina" .. script_suffix .. " jpda run"
		elseif vim.loop.os_uname().sysname == MACOS_IDENTIFIER then
			runcommand = "bash " .. M.tomcatdirectory .. "bin/catalina" .. script_suffix .. " jpda run"
		end
	else
		if vim.loop.os_uname().sysname == WINDOWS_IDENTIFIER then
			runcommand = M.tomcatdirectory .. "\\bin\\catalina" .. script_suffix .. " run"
		elseif vim.loop.os_uname().sysname == MACOS_IDENTIFIER then
			runcommand = "bash " .. M.tomcatdirectory .. "bin/catalina" .. script_suffix .. " run"
		end
	end

	--print(runcommand)
	if tomcat_job_id == nil then
		local buf = nil
		if buffer_id ~= nil and vim.api.nvim_buf_is_loaded(buffer_id) then
			buf = buffer_id
		else
			buf = vim.api.nvim_create_buf(true, true)
			buffer_id = buf
		end
		vim.api.nvim_buf_set_name(buf, "Tomcat Server Logs [" .. buf .. "]")

		--vim.bo[buf].buftype = 'nofile'
		--vim.bo[buf].bufhidden = 'hide'
		--vim.bo[buf].swapfile = false

		vim.api.nvim_set_current_buf(buf)
		vim.api.nvim_buf_call(buf, function()
			tomcat_job_id = vim.fn.jobstart(runcommand, {

				on_stdout = function(_, data, _)
					if data then
						vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
						vim.api.nvim_command("normal! G")
					end
				end,
				on_stderr = function(_, data, _)
					if data then
						vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
						vim.api.nvim_command("normal! G")
					end
				end,
			})
		end)
		vim.api.nvim_buf_attach(buf, false, {
			on_detach = function()
				M.stopTomcat()
			end,
		})
	else
		if buffer_id ~= nil and vim.api.nvim_buf_is_loaded(buffer_id) then
			vim.api.nvim_set_current_buf(buffer_id)
		end
	end
end

function M.stopTomcat()
	if tomcat_job_id ~= nil then
		vim.fn.jobstop(tomcat_job_id)
		vim.fn.jobwait({ tomcat_job_id }, 100)
		tomcat_job_id = nil
		M.cleanWebAppsFolder()
		-- print 'Tomcat Stopped'
	end
end

function M.create_war(runWar)
	runWar = runWar or false

	local command = ""
	local move_command = nil
	local war_file_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t") .. ".war"

	if vim.loop.os_uname().sysname == WINDOWS_IDENTIFIER then
		command = "xcopy build WebContent\\WEB-INF /s /e /h /I & xcopy src\\* WebContent\\WEB-INF\\classes /s /e /h /I & jar -cvf "
			.. war_file_name
			.. " -C WebContent/ . &  rmdir WebContent\\WEB-INF\\classes /s /q "
		move_command = "move /y " .. war_file_name .. " " .. M.tomcatdirectory .. "\\webapps\\"
	else
		command = "cp -r build/ WebContent/WEB-INF ; cp -R src/* WebContent/WEB-INF/classes ; jar -cvf "
			.. war_file_name
			.. " -C WebContent/ .; rm -rf WebContent/WEB-INF/classes "
		move_command = "mv " .. war_file_name .. " " .. M.tomcatdirectory .. "webapps/"
	end

	if
		vim.fn.isdirectory(vim.fn.getcwd() .. "/" .. "WebContent")
		and vim.fn.isdirectory(vim.fn.getcwd() .. "/" .. "build")
	then
		vim.fn.jobstart(command, {
			on_exit = function(_, code, _)
				-- print('Create War Exited : Code ' .. code)
				if runWar and vim.uv.fs_stat(war_file_name) then
					os.execute(move_command)
					if buffer_id ~= nil then
						vim.api.nvim_set_current_buf(buffer_id)
					end
				end
			end,
		})
		return war_file_name
	end
end

function M.run_project()
	M.stopTomcat()
	M.startTomcat()
	M.create_war({
		runWar = true,
	})
end

function M.debug_project()
	M.stopTomcat()
	M.startTomcat({
		debug = true,
	})
	M.create_war({
		runWar = true,
	})
end

return M
