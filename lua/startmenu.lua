local projects_dir = os.getenv("HOME") .. "/lumProjects"
if package.config:sub(1, 1) == '\\' then
    projects_dir = os.getenv("USERPROFILE") .. "\\lumProjects"  -- Путь для Windows
end

-- Функция для создания директории, если она не существует
local function create_projects_dir()
    local dir_exists = os.rename(projects_dir, projects_dir) -- Проверяем, существует ли директория
    if not dir_exists then
        os.execute("mkdir \"" .. projects_dir .. "\"") -- Создаем директорию
    end
end

-- Функция для создания нового проекта
local function create_project()
    local new_project_name = vim.fn.input("Enter new project name: ")
    if new_project_name and new_project_name ~= "" then
        local new_project_path = projects_dir .. "/" .. new_project_name
        local creation_result = os.execute("mkdir \"" .. new_project_path .. "\"")

        if creation_result then
			local file_path = new_project_path .. "/" .. "README.md"  -- Например, создаем .txt файл
			os.execute("type nul > \"" .. file_path .. "\"") -- Создаём пустой файл
        else
            print("Failed to create project directory.")
        end
    end
end

-- Модуль для выбора проекта
local M = {}

function M.select_project()
    local projects = vim.fn.readdir(projects_dir)

    if #projects == 0 then
        print("No projects found in " .. projects_dir)
        return
    end

    local selected_index = 1

    local function display_projects()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, projects)
        vim.api.nvim_buf_add_highlight(0, -1, "CursorLine", selected_index - 1, 0, -1)
    end

    local function open_project()
        local selected_project = projects[selected_index]
        local project_path = projects_dir .. "/" .. selected_project
        vim.cmd("bdelete!")
		vim.cmd("e " .. project_path .. "/README.md")
        vim.cmd("cd " .. project_path)
    end

    vim.cmd("enew")
    vim.cmd("setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap")
    display_projects()

    vim.api.nvim_buf_set_keymap(0, "n", "j", "", {
        callback = function()
            if selected_index < #projects then
                selected_index = selected_index + 1
                display_projects()
            end
        end,
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(0, "n", "k", "", {
        callback = function()
            if selected_index > 1 then
                selected_index = selected_index - 1
                display_projects()
            end
        end,
        noremap = true,
        silent = true,
    })

    vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "", {
        callback = open_project,
        noremap = true,
        silent = true,
    })
end

-- Функция для открытия проекта
local function open_project()
    M.select_project()
end

-- Создаем директорию проектов при запуске
create_projects_dir()

-- Если Neovim запущен без аргументов, показываем список проектов
if vim.fn.argc() == 0 then
    open_project()
end

-- Набор команд для открытия и создания проекта
vim.api.nvim_create_user_command("OpenProject", open_project, {})
vim.api.nvim_create_user_command("CreateProject", create_project, {})
