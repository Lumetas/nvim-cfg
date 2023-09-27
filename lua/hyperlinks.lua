local M = {}

--- Возвращает относительный путь текущего файла (аналог :!echo %)
function M.filePath()
    local filepath = vim.fn.expand('%')
    return filepath
end

--- Возвращает путь к файлу с номером строки (%:<stringNumber>)
---@param line_number number|nil Номер строки (опционально, по умолчанию текущая строка)
function M.filePathAndString(line_number)
    local filepath = vim.fn.expand('%')
    local line = line_number or vim.fn.line('.')
    return string.format("%s:%d", filepath, line)
end

--- Возвращает полный путь к текущему файлу
function M.fullPath()
    return vim.fn.expand('%:p')
end

--- Возвращает имя текущего файла без пути
function M.fileName()
    return vim.fn.expand('%:t')
end

--- Возвращает директорию текущего файла
function M.fileDir()
    return vim.fn.expand('%:p:h')
end

--- Копирует относительный путь в буфер обмена (с оповещением)
function M.copyFilePath()
    local path = M.filePath()
    require('clipboard').copy(path, 'FilePath')
end

--- Копирует путь с номером строки в буфер обмена
---@param line_number number|nil Номер строки
function M.copyFilePathAndString(line_number)
    local path_with_line = M.filePathAndString(line_number)
    require('clipboard').copy(path_with_line, 'FilePath:Line')
end

return M
