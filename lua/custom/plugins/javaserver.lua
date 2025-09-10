local M = {}

local tomcat_job_id = nil
local buffer_id = nil

M.tomcatdirectory = '/Users/depressedcoder/Downloads/apache-tomcat-10.1.44/'
-- Identifying the OS : print(vim.loop.os_uname().sysname)

local function validateDefaultTomcatApps(app_name)
  local defaultApps = { 'docs', 'examples', 'host-manager', 'manager', 'ROOT' }
  for index, app in ipairs(defaultApps) do
    if app == app_name then
      return true
    end
  end
  return false
end

local function scanTomcatWebAppsFolder()
  local i, t, popen = 0, {}, io.popen
  local pfile = popen('ls -a -d -1 "' .. M.tomcatdirectory .. 'webapps/"**')
  if pfile ~= nil then
    for filename in pfile:lines() do
      i = i + 1
      t[i] = filename
    end
    pfile:close()
  end
  return t
end

function M.cleanWebAppsFolder()
  local folders = scanTomcatWebAppsFolder()
  for _, folder in ipairs(folders) do
    local foldername = vim.fn.fnamemodify(folder, ':t')
    if not validateDefaultTomcatApps(foldername) then
      vim.fs.rm(folder, {
        recursive = true,
      })
    end
  end
end

function M.startTomcat()
  --local bufnr = vim.api.nvim_win_call()
  if tomcat_job_id == nil then
    local buf = nil
    if buffer_id ~= nil and vim.api.nvim_buf_is_loaded(buffer_id) then
      buf = buffer_id
    else
      buf = vim.api.nvim_create_buf(true, true)
      buffer_id = buf
    end
    vim.api.nvim_buf_set_name(buf, 'Tomcat Server Logs [' .. buf .. ']')

    --vim.bo[buf].buftype = 'nofile'
    --vim.bo[buf].bufhidden = 'hide'
    --vim.bo[buf].swapfile = false

    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_call(buf, function()
      tomcat_job_id = vim.fn.jobstart('bash ' .. M.tomcatdirectory .. 'bin/catalina.sh run', {

        on_stdout = function(_, data, _)
          if data then
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
            vim.api.nvim_command 'normal! G'
          end
        end,
        on_stderr = function(_, data, _)
          if data then
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
            vim.api.nvim_command 'normal! G'
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
    tomcat_job_id = nil
    M.cleanWebAppsFolder()
    -- print 'Tomcat Stopped'
  end
end

function M.create_war(runWar)
  runWar = runWar or false

  if vim.fn.isdirectory(vim.fn.getcwd() .. '/' .. 'WebContent') and vim.fn.isdirectory(vim.fn.getcwd() .. '/' .. 'build') then
    local war_file_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t') .. '.war'

    vim.fn.jobstart(
      'cp -r build/ WebContent/WEB-INF ; cp -r src WebContent/WEB-INF ; jar -cvf '
        .. war_file_name
        .. ' -C WebContent/ .; rm -rf WebContent/WEB-INF/classes; rm -rf WebContent/WEB-INF/src',
      {
        on_exit = function(_, code, _)
          print('Create War Exited : Code ' .. code)
          if runWar and vim.uv.fs_stat(war_file_name) then
            os.execute('mv ' .. war_file_name .. ' ' .. M.tomcatdirectory .. 'webapps/')
            if buffer_id ~= nil then
              vim.api.nvim_set_current_buf(buffer_id)
            end
          end
        end,
      }
    )
    return war_file_name
  end
end

function M.run_project()
  M.startTomcat()
  M.create_war {
    runWar = true,
  }
end

function M.debug_project() end

return M
