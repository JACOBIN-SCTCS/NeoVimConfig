local M = {}

function startTomcat()
  local tomcatdirectory = '/Users/depressedcoder/Downloads/apache-tomcat-10.1.44/'
  local bufnr = vim.api.nvim_create_buf(true, false)
end

function stopTomcat() end

function M.create_war()
  if vim.fn.isdirectory(vim.fn.getcwd() .. '/' .. 'WebContent') and vim.fn.isdirectory(vim.fn.getcwd() .. '/' .. 'build') then
    local war_file_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t') .. '.war'

    vim.fn.jobstart(
      'cp -r build/ WebContent/WEB-INF ; cp -r src WebContent/WEB-INF ; jar -cvf '
        .. war_file_name
        .. ' -C WebContent/ .; rm -rf WebContent/WEB-INF/classes; rm -rf WebContent/WEB-INF/src'
    )
    print 'War File Created Successfully'
  end
end

return M
