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
vim.api.nvim_command 'command! CreateWar lua require("custom.plugins.javaserver").create_war()'
