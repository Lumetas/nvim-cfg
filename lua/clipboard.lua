-- clipboard.lua - Использует встроенные возможности Neovim
local M = {}

--- Копирует текст в системный буфер обмена
---@param text string Текст для копирования
---@param context string|nil Контекст для сообщения
---@return boolean Успешность операции
function M.copy(text, context)
    if not text or text == '' then
        vim.notify('Nothing to copy', vim.log.levels.WARN)
        return false
    end

    -- Используем регистр '+' для системного буфера обмена
    -- Neovim сам разруливает особенности ОС (Wayland/X11/Windows/macOS)
    vim.fn.setreg('+', text)
    
    local message = context and string.format('Copied: %s', context) or 'Copied to clipboard'
    vim.notify('✓ ' .. message, vim.log.levels.INFO)
    
    -- Генерируем событие для статусбара
    vim.api.nvim_exec_autocmds('User', { 
        pattern = 'ClipboardCopy', 
        data = { text = text, context = context } 
    })
    
    return true
end

--- Вставляет текст из буфера обмена
---@return string Текст из буфера обмена
function M.paste()
    return vim.fn.getreg('+')
end

return M
