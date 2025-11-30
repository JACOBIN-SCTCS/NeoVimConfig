-- Remove all highlighted search
function toggle_terminal()
  for i, buffer in ipairs(vim.api.nvim_list_bufs()) do
    local buffer_name = vim.api.nvim_buf_get_name(buffer)
    if string.sub(buffer_name, 1, 7) == 'term://' then
      vim.api.nvim_win_set_buf(0, buffer)
      return
    end
  end
  vim.api.nvim_command ':terminal'
end

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Remove all highlighted search' })

-- Vertical split
vim.keymap.set('n', '<leader>wv', ':vsplit<CR>', { desc = 'Window vertical split' })
vim.keymap.set('n', '<leader>wh', ':split<CR>', { desc = 'Window horizontal split' })

vim.keymap.set('v', '<', '<gv', { desc = 'Indent left in visual mode' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right in visual mode' })

vim.keymap.set('n', '<C-z>', 'u', { desc = 'Undo' })

vim.keymap.set('n', '<C-t>', toggle_terminal, { desc = 'Open Terminal' })

-- vim.api.nvim_command('command! CreateWar lua require("plugins.javaserver").create_war()')

-- Java Server Plugin Keymaps custom made
vim.api.nvim_command 'command! CreateWar lua require("custom.plugins.javaserver").create_war()'
vim.api.nvim_command 'command! StartTomcat lua require("custom.plugins.javaserver").startTomcat()'
vim.api.nvim_command 'command! StopTomcat lua require("custom.plugins.javaserver").stopTomcat()'
vim.api.nvim_command 'command! RunProject lua require("custom.plugins.javaserver").run_project()'
vim.api.nvim_command 'command! DebugProject lua require("custom.plugins.javaserver").debug_project()'
vim.api.nvim_command('command! FrontendSync lua require("custom.plugins.javaserver").sync_frontendfiles()')
vim.api.nvim_command('command! BackendSync lua require("custom.plugins.javaserver").sync_backendfiles()')

-- Persistence nvim
-- load the session for the current directory
vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end)
-- select a session to load
vim.keymap.set("n", "<leader>qS", function() require("persistence").select() end)
-- load the last session
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end)
-- stop Persistence => session won't be saved on exit
vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end)