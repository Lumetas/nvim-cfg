local M = {}

-- Буквы для выбора
local LETTERS = {'j','f','g','a','d','s','h','k','l'}

-- Функция для чтения игнорируемых директорий из lumignore
local function read_ignore_patterns()
    local ignore_file = vim.fn.getcwd() .. '/lumignore'
    if vim.fn.filereadable(ignore_file) == 0 then
        return {}
    end
    
    local content = vim.fn.readfile(ignore_file)
    if #content == 0 then
        return {}
    end
    
    -- Разделяем по запятым, удаляем пробелы и фильтруем пустые строки
    local patterns = {}
    for part in string.gmatch(content[1], '([^,]+)') do
        local cleaned = vim.fn.trim(part)
        if cleaned ~= '' then
            table.insert(patterns, cleaned)
        end
    end
    
    return patterns
end

-- Функция для проверки, находится ли файл в игнорируемой директории
local function is_ignored(file_path, ignore_patterns)
    for _, pattern in ipairs(ignore_patterns) do
        if string.find(file_path, pattern) then
            return true
        end
    end
    return false
end

function M.find_file()
    -- Читаем игнорируемые директории
    local ignore_patterns = read_ignore_patterns()
    
    -- Запрашиваем ввод
    local input = vim.fn.input("🔍 Search file: ")
    if input == "" then return end

    -- Ищем файлы (исключаем директории)
    local files = vim.split(vim.fn.globpath(vim.fn.getcwd(), "**/"..input.."*"), "\n")
    files = vim.tbl_filter(function(file)
        return vim.fn.isdirectory(file) == 0 and not is_ignored(file, ignore_patterns)
    end, files)

    if #files == 0 then
        vim.notify("No files found!", vim.log.levels.WARN)
        return
    end

    -- Формируем строку вывода
    local output = ""
    local file_map = {}
    
    for i = 1, math.min(#LETTERS, #files) do
        local rel_path = vim.fn.fnamemodify(files[i], ":~:.")
        file_map[LETTERS[i]] = files[i]
        output = output .. "  " .. LETTERS[i] .. ": " .. rel_path .. "\n"
    end
    
    -- Выводим всё сразу
    vim.notify(output)

    -- Ждем выбора
    local char = vim.fn.getcharstr():lower()
    local selected = file_map[char]

    if selected then
        vim.cmd("edit "..vim.fn.fnameescape(selected))
    else
        vim.notify("Invalid selection: "..char, vim.log.levels.ERROR)
    end
end

vim.keymap.set("n", "<C-f>", M.find_file, { desc = "Quick file picker" })

return M
