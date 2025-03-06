-- Команда Artisan
vim.api.nvim_create_user_command('Artisan', function(opts)
    vim.cmd('echo system("php artisan ' .. opts.args .. '")')
end, { nargs = 1 })

-- Функция RunArtisan
function run_artisan()
    local command = vim.fn.input('artisan: ')
    vim.cmd('echo system("php artisan ' .. command .. '")')
end

-- Маппинг для RunArtisan
vim.api.nvim_set_keymap('n', '<C-a>', ':lua run_artisan()<CR>', { noremap = true })
