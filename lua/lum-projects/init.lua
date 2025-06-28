local M = {}

-- Конфигурация по умолчанию
local config = {
    projects_dir = vim.fn.expand("~/LumProjects"),
    templates_dir = vim.fn.expand("~/.lumProjectsTemplates"),
    window = {
        width = 60,
        height = 20,
        border = "rounded"
    }
}

-- Глобальные переменные для хранения состояния
local state = {
    win = nil,
    buf = nil
}

-- Закрытие окна с проверкой
local function safe_close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.api.nvim_buf_delete(state.buf, {force = true})
    end
    state.win = nil
    state.buf = nil
end

-- Проверка и создание директорий если нужно
local function ensure_dirs()
    if vim.fn.isdirectory(config.projects_dir) == 0 then
        vim.fn.mkdir(config.projects_dir, "p")
    end
    if vim.fn.isdirectory(config.templates_dir) == 0 then
        vim.fn.mkdir(config.templates_dir, "p")
    end
end

-- Получение списка проектов
local function get_projects()
    local projects = {}
    local handle = vim.loop.fs_scandir(config.projects_dir)
    if handle then
        while true do
            local name, typ = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if typ == "directory" then
                table.insert(projects, name)
            end
        end
    end
    return projects
end

-- Получение списка шаблонов
local function get_templates()
    local templates = {}
    local handle = vim.loop.fs_scandir(config.templates_dir)
    if handle then
        while true do
            local name, typ = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if typ == "directory" then
                table.insert(templates, name)
            end
        end
    end
    return templates
end

-- Создание нового проекта
local function create_project(name, template, description)
    local project_path = config.projects_dir .. "/" .. name
    
    if vim.fn.isdirectory(project_path) == 1 then
        return false, "Project already exists"
    end
    
    if template and template ~= "empty" then
        local template_path = config.templates_dir .. "/" .. template
        if vim.fn.isdirectory(template_path) == 0 then
            return false, "Template not found"
        end
        -- Копируем шаблон
        os.execute("cp -r " .. template_path .. " " .. project_path)
    else
        -- Создаем пустую папку
        vim.fn.mkdir(project_path, "p")
    end
    
    -- Создаем файл с описанием
    if description then
        local desc_file = io.open(project_path .. "/.lumproject", "w")
        if desc_file then
            desc_file:write("name=" .. name .. "\n")
            desc_file:write("description=" .. description .. "\n")
            desc_file:close()
        end
    end
    
    return true
end

-- Удаление проекта
local function delete_project(name)
    local project_path = config.projects_dir .. "/" .. name
    if vim.fn.isdirectory(project_path) == 0 then
        return false, "Project not found"
    end
    
    os.execute("rm -rf " .. project_path)
    return true
end

-- Получение информации о проекте
local function get_project_info(name)
    local info = {name = name, description = ""}
    local desc_file = io.open(config.projects_dir .. "/" .. name .. "/.lumproject", "r")
    if desc_file then
        for line in desc_file:lines() do
            if line:match("^description=") then
                info.description = line:sub(13)
            end
        end
        desc_file:close()
    end
    return info
end

-- Функция для создания нового проекта через инпут
local function prompt_create_project()
    vim.ui.input({prompt = "Project name: "}, function(name)
        if not name or name == "" then return end
        
        local templates = get_templates()
        table.insert(templates, 1, "empty")
        
        vim.ui.select(templates, {
            prompt = "Select template:",
            format_item = function(item)
                return item
            end
        }, function(template)
            if not template then return end
            
            vim.ui.input({prompt = "Description (optional): ", default = ""}, function(description)
                if description == nil then return end -- Пользователь нажал Esc
                
                local success, err = create_project(name, template, description)
                if success then
                    vim.notify("Project created: " .. name, vim.log.levels.INFO)
                    M.open_project_manager() -- Обновляем список
                else
                    vim.notify("Error: " .. err, vim.log.levels.ERROR)
                end
            end)
        end)
    end)
end

-- Обновление содержимого буфера
local function update_buffer_content()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
    
    local projects = get_projects()
    local lines = {
        -- "Lum Projects Manager",
        -- "====================",
        -- "",
        -- "Available projects: (j/k to navigate, o/<Enter> to open, d to delete, a to add, q to close)",
        -- ""
    }
    
    for i, project in ipairs(projects) do
        local info = get_project_info(project)
        table.insert(lines, string.format("%d. %s - %s", i, info.name, info.description))
    end
    
    vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end

-- Основное окно
function M.open_project_manager()
    ensure_dirs()
    
    -- Закрываем предыдущее окно если оно есть
    safe_close()
    
    -- Создаем новый буфер
    state.buf = vim.api.nvim_create_buf(false, true)
    local width = config.window.width
    local height = config.window.height
    
    -- Получаем размеры окна
    local ui = vim.api.nvim_list_uis()[1]
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = (ui.width - width) / 2,
        row = (ui.height - height) / 2 - 5,
        style = "minimal",
        border = config.window.border
    }
    
    -- Создаем окно
    state.win = vim.api.nvim_open_win(state.buf, true, opts)
    
    -- Устанавливаем содержимое
    update_buffer_content()
    
    -- Настраиваем буфер
    vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
    vim.api.nvim_buf_set_name(state.buf, "lum-projects-manager-" .. os.time())
    
    -- Устанавливаем keymaps
    local keymaps = {
        {mode = "n", key = "<CR>", action = function()
            local line = vim.api.nvim_win_get_cursor(state.win)[1]
            local projects = get_projects()
            if line >= 1 and line <= #projects then
                local project = projects[line]
                local project_path = config.projects_dir .. "/" .. project
                vim.cmd("cd " .. project_path)
                safe_close()
                vim.notify("Opened project: " .. project, vim.log.levels.INFO)
            end
        end},
        {mode = "n", key = "o", action = function()
            local line = vim.api.nvim_win_get_cursor(state.win)[1]
            local projects = get_projects()
            if line >= 1 and line <= #projects then
                local project = projects[line]
                local project_path = config.projects_dir .. "/" .. project
                vim.cmd("cd " .. project_path)
                safe_close()
                vim.notify("Opened project: " .. project, vim.log.levels.INFO)
            end
        end},
        {mode = "n", key = "d", action = function()
            local line = vim.api.nvim_win_get_cursor(state.win)[1]
            local projects = get_projects()
            if line >= 1 and line <= #projects then
                local project = projects[line]
                vim.ui.select({"Yes", "No"}, {
                    prompt = "Delete project '" .. project .. "'?"
                }, function(choice)
                    if choice == "Yes" then
                        local success, err = delete_project(project)
                        if success then
                            vim.notify("Project deleted: " .. project, vim.log.levels.INFO)
                            update_buffer_content()
                        else
                            vim.notify("Error: " .. err, vim.log.levels.ERROR)
                        end
                    end
                end)
            end
        end},
        {mode = "n", key = "a", action = function()
            prompt_create_project()
        end},
        {mode = "n", key = "q", action = function()
            safe_close()
        end},
        {mode = "n", key = "<Esc>", action = function()
            safe_close()
        end},
    }
    
    for _, km in ipairs(keymaps) do
        vim.api.nvim_buf_set_keymap(state.buf, km.mode, km.key, "", {
            callback = km.action,
            noremap = true,
            silent = true
        })
    end
end

-- Команда для вызова менеджера
vim.api.nvim_create_user_command("ShowLumProjects", M.open_project_manager, {})

return M
