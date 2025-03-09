-- Команда для форматирования кода
vim.api.nvim_create_user_command('Format', function()
    -- Устанавливаем метку 'b' на текущей строке
    vim.cmd('normal mbgg=G`b')
end, {})
