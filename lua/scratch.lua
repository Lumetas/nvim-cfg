-- Плагин для работы с scratch-буферами
vim.api.nvim_create_user_command('LScratch', function()
    local org_path = vim.g.org_path or vim.fn.expand('~/org')
    local current_day = os.date('%Y-%m-%d')
    local file_path = org_path .. '/calendar/' .. current_day .. '.org'
    
    vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
end, { desc = 'Open today\'s org calendar file' })

vim.api.nvim_create_user_command('LScratchClean', function()
    -- Создаем временный буфер с уникальным именем
    local buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_set_current_buf(buf)
    
    -- Устанавливаем тип файла для подсветки синтаксиса
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    
    -- Устанавливаем имя буфера для удобства
    vim.api.nvim_buf_set_name(buf, '*scratch*')
end, { desc = 'Open clean scratch buffer' })
