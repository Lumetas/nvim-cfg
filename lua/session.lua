local session_file = ".session.lnvimsession"

-- 1. Проверяем существование именно этого файла
local stat = vim.uv.fs_stat(session_file)

-- 2. Автозагрузка (только если nvim запущен без открытия конкретных файлов)
if stat and stat.type == "file" and vim.fn.argc() == 0 then
    -- Используем schedule, чтобы UI успел прогрузиться
    vim.schedule(function()
        vim.cmd('source ' .. session_file)
    end)
end

-- 3. Команда сохранения
vim.api.nvim_create_user_command('SSave', function()
    vim.cmd('mksession! ' .. session_file)
    print("Session saved to " .. session_file)
end, {})
