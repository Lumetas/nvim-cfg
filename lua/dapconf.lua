local dap = require('dap')
dap.adapters.php = {
    type = "executable",
    command = "node",
    args = { os.getenv("HOME") .. "/vscode-php-debug/out/phpDebug.js" }
}

dap.configurations.php = {
    {
        type = "php",
        request = "launch",
        name = "Listen for Xdebug",
        port = 9003
    }
}

vim.keymap.set('n', '<Leader>dc', function() require('dap').continue() end, { desc = '[D]ebug [C]onnect menu' })
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug Step Over' })
vim.keymap.set('n', '<F8>', function() require('dap').step_into() end, { desc = 'Debug Step Into' })
vim.keymap.set('n', '<F9>', function() require('dap').step_out() end, { desc = 'Debug Step Out' })
-- vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
-- vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
vim.keymap.set('n', '<Leader>db', function() require('dap').toggle_breakpoint() end, { desc = '[D]ebug [B]reakpoint' })
vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
  require('dap.ui.widgets').hover()
end, { desc = '[D]ebug [H]over' })
vim.keymap.set('n', '<Leader>df', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.frames)
end, { desc = '[D]ebug [F]orce-tree' })
vim.keymap.set('n', '<Leader>dv', function()
  local widgets = require('dap.ui.widgets')
  widgets.centered_float(widgets.scopes)
end, { desc = '[D]ebug [V]alues' })
