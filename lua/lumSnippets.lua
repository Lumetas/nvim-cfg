local M = {}

-- Путь к папке со сниппетами в корневой директории пользователя
local snippets_dir = vim.fn.expand(vim_dir .. "/lumSnippets/")

-- Функция для чтения содержимого файла
local function read_file(file_path)
    local file = io.open(file_path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

-- Функция для замены плейсхолдеров
local function replace_placeholders(content, placeholders)
    for key, value in pairs(placeholders) do
        content = content:gsub("%%{" .. key .. "}%%", value)
    end
    return content
end

-- Функция для обработки условных блоков
local function process_conditional_blocks(content)
    -- Обрабатываем условные блоки
    local processed_content = content:gsub("%%{(.-)}%?%%(.-)%%%?{(.-)}%%", function(condition, block, _)
        -- Запрашиваем у пользователя подтверждение
        local response = vim.fn.input(condition .. "? (y/n): ")
        -- Если ответ "y" или "yes", вставляем блок
        if response:lower() == "y" or response:lower() == "yes" then
            return block
        else
            return ""  -- Иначе пропускаем блок
        end
    end)
    return processed_content
end

-- Функция для регистрации команды
local function register_snippet_command(file_name)
    -- Команда в формате LumSN<file>
    local command_name = "LumSN" .. file_name
    vim.api.nvim_create_user_command(command_name, function()
        -- Путь к файлу сниппета
        local snippet_path = snippets_dir .. file_name

        -- Читаем содержимое файла
        local snippet_content = read_file(snippet_path)
        if not snippet_content then
            vim.notify("Сниппет " .. file_name .. " не найден!", vim.log.levels.ERROR)
            return
        end

        -- Собираем плейсхолдеры
        local placeholders = {}
        for placeholder in snippet_content:gmatch("%%{([^}]+)}%%") do
            -- Если плейсхолдер уже был запрошен, пропускаем его
            if not placeholders[placeholder] then
                local value = vim.fn.input(placeholder .. "? ")
                placeholders[placeholder] = value
            end
        end

        -- Заменяем плейсхолдеры на введенные значения
        local final_content = replace_placeholders(snippet_content, placeholders)

        -- Обрабатываем условные блоки
        final_content = process_conditional_blocks(final_content)

        -- Разбиваем содержимое на строки
        local lines = {}
        for line in final_content:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        -- Вставляем результат в буфер
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
    end, {})
end

-- Функция для инициализации плагина
function M.setup()
    -- Проверяем, существует ли папка со сниппетами
    if vim.fn.isdirectory(snippets_dir) == 0 then
        return  -- Если папки нет, просто выходим
    end

    -- Проходим по всем файлам в папке и регистрируем команды
    local files = vim.fn.readdir(snippets_dir)
    for _, file_name in ipairs(files) do
        register_snippet_command(file_name)
    end
end

-- Вызываем setup при загрузке плагина
M.setup()

return M
