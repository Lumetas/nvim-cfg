-- ~/.config/nvim/lua/env_loader.lua

local M = {}

-- Хранилище для переменных окружения, загруженных из локальных файлов
local loaded_envs = {}
-- Хранилище для исходных значений переменных (для восстановления)
local original_values = {}
-- Текущая рабочая директория
local current_cwd = vim.loop.cwd()
-- Флаг загрузки конфигурационного файла
local config_loaded = false

-- Функция для парсинга env файла
local function parse_env_file(filepath)
    local env_vars = {}
    local file = io.open(filepath, "r")
    if not file then
        return env_vars
    end

    for line in file:lines() do
        -- Пропускаем комментарии и пустые строки
        line = line:gsub("%s+", "") -- Удаляем пробелы
        if line ~= "" and not line:match("^#") then
            -- Разделяем на ключ и значение
            local key, value = line:match("^([^=]+)=(.*)$")
            if key then
                -- Удаляем кавычки, если они есть
                value = value:gsub("^['\"](.*)['\"]$", "%1")
                env_vars[key] = value
            end
        end
    end
    
    file:close()
    return env_vars
end

-- Функция для загрузки переменных из файла
local function load_env_from_file(filepath, source_name)
    local env_vars = parse_env_file(filepath)
    if not next(env_vars) then
        return false
    end
    
    -- Сохраняем информацию о загруженных переменных
    loaded_envs[source_name] = loaded_envs[source_name] or {}
    
    for key, value in pairs(env_vars) do
        -- Сохраняем оригинальное значение, если его еще нет
        if original_values[key] == nil then
            original_values[key] = os.getenv(key)
        end
        -- Устанавливаем новое значение
        vim.fn.setenv(key, value)
        -- Запоминаем, что переменная загружена из этого источника
        loaded_envs[source_name][key] = true
    end
    
    return true
end

-- Функция для выгрузки переменных из определенного источника
local function unload_env_from_source(source_name)
    if not loaded_envs[source_name] then
        return
    end
    
    for key, _ in pairs(loaded_envs[source_name]) do
        -- Восстанавливаем оригинальное значение
        vim.fn.setenv(key, original_values[key])
        -- Очищаем запись о загрузке
        loaded_envs[source_name][key] = nil
    end
    
    loaded_envs[source_name] = nil
end

-- Функция для загрузки глобального конфигурационного файла
local function load_global_config()
    local config_root = vim.fn.stdpath("config")
    local global_env_file = config_root .. "/nvim.env"
    
    if vim.loop.fs_stat(global_env_file) then
        return load_env_from_file(global_env_file, "global")
    end
    return false
end

-- Функция для загрузки локального env файла
local function load_local_env(cwd)
    local local_env_file = cwd .. "/.env"
    
    if vim.loop.fs_stat(local_env_file) then
        return load_env_from_file(local_env_file, "local_" .. cwd)
    end
    return false
end

-- Функция для проверки и обновления окружения при смене директории
local function check_and_update_env()
    local new_cwd = vim.loop.cwd()
    
    if new_cwd ~= current_cwd then
        -- Выгружаем переменные из предыдущей локальной директории
        if loaded_envs["local_" .. current_cwd] then
            unload_env_from_source("local_" .. current_cwd)
        end
        
        -- Загружаем переменные из новой директории
        current_cwd = new_cwd
        load_local_env(current_cwd)
    end
end

-- Функция для ручной перезагрузки env файлов
function M.reload()
    -- Перезагружаем глобальный конфиг только если он еще не загружен
    if not config_loaded then
        load_global_config()
        config_loaded = true
    end
    
    -- Обновляем локальное окружение
    check_and_update_env()
end

-- Функция для получения текущего статуса загруженных переменных
function M.status()
    local status = {
        current_cwd = current_cwd,
        loaded_sources = {},
        variables = {}
    }
    
    for source_name, vars in pairs(loaded_envs) do
        status.loaded_sources[source_name] = vars
        for key, _ in pairs(vars) do
            status.variables[key] = os.getenv(key)
        end
    end
    
    return status
end

-- Функция для отображения статуса (для удобства)
function M.show_status()
    local status = M.status()
    print("Current directory: " .. status.current_cwd)
    print("Loaded sources:")
    for source_name, vars in pairs(status.loaded_sources) do
        print("  " .. source_name .. ":")
        for key, _ in pairs(vars) do
            print("    " .. key .. " = " .. (status.variables[key] or "nil"))
        end
    end
end

-- Инициализация
function M.setup()
    -- Загружаем глобальный конфигурационный файл один раз при старте
    if load_global_config() then
        config_loaded = true
    end
    
    -- Загружаем локальный env файл для текущей директории
    load_local_env(current_cwd)
    
    -- Создаем автокоманду для отслеживания смены директории
    local group = vim.api.nvim_create_augroup("EnvLoader", { clear = true })
    
    vim.api.nvim_create_autocmd({ "DirChanged" }, {
        group = group,
        pattern = "*",
        callback = function()
            check_and_update_env()
        end,
    })
    
    -- Также отслеживаем VimEnter для начальной загрузки
    vim.api.nvim_create_autocmd({ "VimEnter" }, {
        group = group,
        pattern = "*",
        callback = function()
            -- Небольшая задержка для гарантии корректной инициализации
            vim.defer_fn(function()
                M.reload()
            end, 100)
        end,
    })
    
    -- Опционально: отслеживаем изменения в файлах nvim.env
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = group,
        pattern = { "*/nvim.env" },
        callback = function()
            -- Перезагружаем окружение при сохранении файла nvim.env
            M.reload()
            print("Environment reloaded from " .. vim.fn.expand("<afile>"))
        end,
    })
end

return M
