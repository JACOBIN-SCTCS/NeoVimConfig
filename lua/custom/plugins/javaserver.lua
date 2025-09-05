local M = {}

M.tomcat_job_id = nil

function M.startTomcat()
  local tomcatdirectory = '/Users/depressedcoder/Downloads/apache-tomcat-10.1.44/'
  --local bufnr = vim.api.nvim_win_call()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(buf, 'Tomcat Server Logs')
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_call(buf, function()
    tomcat_job_id = vim.fn.jobstart('bash ' .. tomcatdirectory .. 'bin/catalina.sh run', {
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
end

function M.stopTomcat()
  if tomcat_job_id ~= nil then
    vim.fn.jobstop(tomcat_job_id)
    tomcat_job_id = nil
    print 'Tomcat Stopped'
  end
end

function M.create_war()
  if vim.fn.isdirectory(vim.fn.getcwd() .. '/' .. 'WebContent') and vim.fn.isdirectory(vim.fn.getcwd() .. '/' .. 'build') then
    local war_file_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t') .. '.war'

    vim.fn.jobstart(
      'cp -r build/ WebContent/WEB-INF ; cp -r src WebContent/WEB-INF ; jar -cvf '
        .. war_file_name
        .. ' -C WebContent/ .; rm -rf WebContent/WEB-INF/classes; rm -rf WebContent/WEB-INF/src',
      {
        on_exit = function(_, code, _)
          print('Create War Exited : Code ' .. code)
        end,
      }
    )
  end
end

return M
