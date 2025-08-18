-- NOTE: Java specific keymaps with which key
vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_compile JdtCompile lua require('jdtls').compile(<f-args>)"
vim.cmd "command! -buffer -nargs=? -complete=custom,v:lua.require'jdtls'._complete_set_runtime JdtSetRuntime lua require('jdtls').set_runtime(<f-args>)"
vim.cmd "command! -buffer JdtUpdateConfig lua require('jdtls').update_project_config()"
vim.cmd "command! -buffer JdtJol lua require('jdtls').jol()"
vim.cmd "command! -buffer JdtBytecode lua require('jdtls').javap()"
vim.cmd "command! -buffer JdtJshell lua require('jdtls').jshell()"

vim.keymap.set('n', '<leader>di', "<Cmd>lua require'jdtls'.organize_imports()<CR>", { desc = '' })
vim.keymap.set('n', '<leader>dt', "<Cmd>lua require'jdtls'.test_class()<CR>", { desc = '' })
vim.keymap.set('n', '<leader>dn', "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", { desc = '' })
vim.keymap.set('v', '<leader>de', "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", { desc = '' })
vim.keymap.set('n', '<leader>de', "<Cmd>lua require('jdtls').extract_variable()<CR>", { desc = '' })
vim.keymap.set('v', '<leader>dm', "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", { desc = '' })
