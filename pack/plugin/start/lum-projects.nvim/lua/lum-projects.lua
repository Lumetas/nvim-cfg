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

-- Setup функция
function M.setup(user_config)
    if user_config then
        if user_config.projects_dir then
            config.projects_dir = vim.fn.expand(user_config.projects_dir)
        end
        if user_config.templates_dir then
            config.templates_dir = vim.fn.expand(user_config.templates_dir)
        end
        if user_config.window then
            config.window = vim.tbl_extend("force", config.window, user_config.window)
        end
    end
end

-- Закрытие окна с проверкой
local function safe_close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        vim.api.nvim_buf_delete(state.buf, { force = true })
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

-- Безопасное копирование директории
local function copy_directory(src, dest)
    local success, err = pcall(function()
        -- Создаем целевую директорию
        vim.fn.mkdir(dest, "p")

        -- Копируем содержимое
        local handle = vim.loop.fs_scandir(src)
        if not handle then
            return false, "Cannot scan source directory"
        end

        while true do
            local name, typ = vim.loop.fs_scandir_next(handle)
            if not name then break end

            local src_path = src .. "/" .. name
            local dest_path = dest .. "/" .. name

            if typ == "directory" then
                local ok, copy_err = copy_directory(src_path, dest_path)
                if not ok then
                    return false, copy_err
                end
            else
                local src_file = io.open(src_path, "rb")
                if not src_file then
                    return false, "Cannot open source file: " .. src_path
                end

                local content = src_file:read("*a")
                src_file:close()

                local dest_file = io.open(dest_path, "wb")
                if not dest_file then
                    return false, "Cannot create destination file: " .. dest_path
                end

                dest_file:write(content)
                dest_file:close()
            end
        end

        return true
    end)

    if not success then
        return false, err
    end
    return true
end

-- Безопасное удаление директории
local function delete_directory(path)
    local success, err = pcall(function()
        local handle = vim.loop.fs_scandir(path)
        if not handle then
            -- Директория уже не существует
            return true
        end

        while true do
            local name, typ = vim.loop.fs_scandir_next(handle)
            if not name then break end

            local item_path = path .. "/" .. name

            if typ == "directory" then
                local ok, del_err = delete_directory(item_path)
                if not ok then
                    return false, del_err
                end
            else
                local ok, rm_err = pcall(vim.loop.fs_unlink, item_path)
                if not ok then
                    return false, "Cannot delete file: " .. item_path .. " - " .. rm_err
                end
            end
        end

        local ok, rmdir_err = pcall(vim.loop.fs_rmdir, path)
        if not ok then
            return false, "Cannot remove directory: " .. path .. " - " .. rmdir_err
        end

        return true
    end)

    if not success then
        return false, err
    end
    return true
end

-- Получение списка проектов
local function get_projects()
    local projects = {}
    local handle = vim.loop.fs_scandir(config.projects_dir)
    if handle then
        while true do
            local name, typ = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if typ == "directory" and name ~= "." and name ~= ".." then
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
            if typ == "directory" and name ~= "." and name ~= ".." then
                table.insert(templates, name)
            end
        end
    end
    return templates
end

-- Экранирование специальных символов
local function escape_special_chars(str)
    if not str then return "" end
    return str:gsub("=", "\\="):gsub("\n", "\\n")
end

-- Раскодирование специальных символов
local function unescape_special_chars(str)
    if not str then return "" end
    return str:gsub("\\=", "="):gsub("\\n", "\n")
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
        -- Копируем шаблон используя нашу безопасную функцию
        local ok, err = copy_directory(template_path, project_path)
        if not ok then
            return false, "Failed to copy template: " .. err
        end
    else
        -- Создаем пустую папку
        vim.fn.mkdir(project_path, "p")
    end

    -- Создаем файл с описанием
    if description then
        local desc_file = io.open(project_path .. "/.lumproject", "w")
        if desc_file then
            desc_file:write("name=" .. escape_special_chars(name) .. "\n")
            desc_file:write("description=" .. escape_special_chars(description) .. "\n")
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

    local ok, err = delete_directory(project_path)
    if not ok then
        return false, "Failed to delete project: " .. err
    end

    return true
end

-- Получение информации о проекте
local function get_project_info(name)
    local info = { name = name, description = "" }
    local desc_file = io.open(config.projects_dir .. "/" .. name .. "/.lumproject", "r")
    if desc_file then
        for line in desc_file:lines() do
            if line:match("^description=") then
                info.description = unescape_special_chars(line:sub(13))
            end

            if line:match("^run=") then
                info.run = unescape_special_chars(line:sub(5))
            end

            if line:match("^build=") then
                info.build = unescape_special_chars(line:sub(7))
            end

            if line:match("^runInTerm=") then
                info.runInTerm = unescape_special_chars(line:sub(11))
            end

            if line:match("^buildInTerm=") then
                info.buildInTerm = unescape_special_chars(line:sub(13))
            end
        end
        desc_file:close()
    end
    return info
end

-- Функция для создания нового проекта через инпут
local function prompt_create_project()
    vim.ui.input({ prompt = "Project name: " }, function(name)
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

            vim.ui.input({ prompt = "Description (optional): ", default = "" }, function(description)
                if description == nil then return end -- Пользователь нажал Esc

                local success, err = create_project(name, template, description)
                if success then
                    vim.notify("Project created: " .. name, vim.log.levels.INFO)
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

    state.buf = vim.api.nvim_create_buf(false, true)
    local ui = vim.api.nvim_list_uis()[1]
    local width = math.min(config.window.width, ui.width - 20)
    local height = math.min(config.window.height, ui.height - 10)

    -- Получаем размеры окна
    local opts = {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((ui.width - width) / 2),
        row = math.floor((ui.height - height) / 2 - 5),
        style = "minimal",
        border = config.window.border
    }

    -- Создаем окно
    state.win = vim.api.nvim_open_win(state.buf, true, opts)

    -- Устанавливаем содержимое
    update_buffer_content()

    -- Настраиваем буфер
    vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
    vim.api.nvim_buf_set_name(state.buf, "lum-projects-manager")

    -- Устанавливаем keymaps
    local keymaps = {
        { mode = "n", key = "<CR>", action = function()
            local line = vim.api.nvim_win_get_cursor(state.win)[1]
            local projects = get_projects()
			local project = projects[line]
			local project_path = config.projects_dir .. "/" .. project
			vim.cmd("cd " .. vim.fn.fnameescape(project_path))
			safe_close()
			vim.notify("Opened project: " .. project, vim.log.levels.INFO)
        end },
        { mode = "n", key = "o", action = function()
            local line = vim.api.nvim_win_get_cursor(state.win)[1]
            local projects = get_projects()
			local project = projects[line]
			local project_path = config.projects_dir .. "/" .. project
			vim.cmd("cd " .. vim.fn.fnameescape(project_path))
			safe_close()
			vim.notify("Opened project: " .. project, vim.log.levels.INFO)
        end },
        { mode = "n", key = "d", action = function()
            local line = vim.api.nvim_win_get_cursor(state.win)[1]
            local projects = get_projects()
			local project = projects[line]
			vim.ui.select({ "Yes", "No" }, {
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
        end },
        { mode = "n", key = "a", action = function()
            prompt_create_project()
        end },
        { mode = "n", key = "r", action = function()
            update_buffer_content()
            vim.notify("Projects list refreshed", vim.log.levels.INFO)
        end },
        { mode = "n", key = "q", action = function()
            safe_close()
        end },
        { mode = "n", key = "<Esc>", action = function()
            safe_close()
        end },
    }

    for _, km in ipairs(keymaps) do
        vim.api.nvim_buf_set_keymap(state.buf, km.mode, km.key, "", {
            callback = km.action,
            noremap = true,
            silent = true
        })
    end

    -- Автоматическое обновление при повторном открытии
    vim.api.nvim_create_autocmd("BufEnter", {
        buffer = state.buf,
        callback = update_buffer_content
    })
end

local function get_project_name()
    -- Получаем текущую директорию
    local current_dir = vim.fn.getcwd()
    local projects_dir = vim.fn.fnamemodify(config.projects_dir, ':p')

    -- Нормализуем пути
    current_dir = vim.fn.fnamemodify(current_dir, ':p')
    projects_dir = vim.fn.fnamemodify(projects_dir, ':p')

    -- Проверяем, что current_dir начинается с projects_dir
    if current_dir:sub(1, #projects_dir) == projects_dir then
        -- Получаем оставшуюся часть пути
        local relative_path = current_dir:sub(#projects_dir + 1)
        -- Убираем ведущие и завершающие слеши
        relative_path = relative_path:gsub('^[/\\]+', ''):gsub('[/\\]+$', '')

        local parts = {}
        for part in relative_path:gmatch('[^/\\]+') do
            table.insert(parts, part)
        end

        if #parts > 0 then
            return parts[1]
        end
    end

    return nil
end

local function run_command_live(command)
    -- Создаём новый буфер
    local buf = vim.api.nvim_create_buf(false, true)
    local ui = vim.api.nvim_list_uis()[1]
    local width = math.min(80, ui.width - 20)
    local height = math.min(20, ui.height - 10)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((ui.width - width) / 2),
        row = math.floor((ui.height - height) / 2),
        style = "minimal",
        border = "rounded",
    })

    -- Настройки буфера
    vim.api.nvim_buf_set_name(buf, "LumProject Output")
    vim.api.nvim_buf_set_option(buf, "filetype", "log")
    vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    -- Добавим переменную для отслеживания состояния
    local is_window_valid = true

    -- Функция для безопасного добавления текста
    local function safe_add_lines(lines)
        if not is_window_valid or not vim.api.nvim_buf_is_valid(buf) then
            return
        end

        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
                local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                for _, line in ipairs(lines) do
                    if line ~= "" then
                        table.insert(current_lines, line)
                    end
                end
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, current_lines)
                vim.api.nvim_win_set_cursor(win, { #current_lines, 0 })
            end
        end)
    end

    -- Запускаем команду асинхронно
    local job_id
    job_id = vim.fn.jobstart(command, {
        stdout_buffered = false,
        on_stdout = function(_, data, _)
            if data then
                safe_add_lines(data)
            end
        end,
        on_exit = function(_, exit_code, _)
            safe_add_lines({ "---", "Process exited with code: " .. exit_code })
        end,
    })

    -- Закрытие окна по `q`
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = function()
            is_window_valid = false
            if job_id and vim.fn.jobstop(job_id) == 1 then
                print("Command stopped")
            end
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end,
        noremap = true,
        silent = true,
    })

    -- Автоматическое закрытие при выходе из буфера
    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        callback = function()
            is_window_valid = false
            if job_id and vim.fn.jobstop(job_id) == 1 then
                print("Command stopped")
            end
        end,
    })
end

function M.start_project()
    local name = get_project_name()
    if name ~= nil then
        local project_info = get_project_info(name)
        if project_info.run and type(project_info.run) == 'string' and project_info.run ~= "" then
            if project_info.runInTerm and project_info.runInTerm == 'true' then
                local current_win = vim.api.nvim_get_current_win()
                vim.cmd("botright vsplit | terminal " .. vim.fn.fnameescape(project_info.run))
                vim.api.nvim_set_current_win(current_win)
            else
                run_command_live(project_info.run)
            end
        else
            vim.notify("No run command configured for project: " .. name, vim.log.levels.WARN)
        end
    else
        vim.notify("Not in a Lum project directory", vim.log.levels.WARN)
    end
end

function M.build_project()
    local name = get_project_name()
    if name ~= nil then
        local project_info = get_project_info(name)
        if project_info.build and type(project_info.build) == 'string' and project_info.build ~= "" then
            if project_info.buildInTerm and project_info.buildInTerm == 'true' then
                local current_win = vim.api.nvim_get_current_win()
                vim.cmd("botright vsplit | terminal " .. vim.fn.fnameescape(project_info.build))
                vim.api.nvim_set_current_win(current_win)
            else
                run_command_live(project_info.build)
            end
        else
            vim.notify("No build command configured for project: " .. name, vim.log.levels.WARN)
        end
    else
        vim.notify("Not in a Lum project directory", vim.log.levels.WARN)
    end
end

function M.telescope_projects()
    local has_telescope, telescope = pcall(require, "telescope")
    if not has_telescope then
        vim.notify("Telescope not found. Please install telescope.nvim", vim.log.levels.ERROR)
        return
    end

    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local previewers = require("telescope.previewers")

    ensure_dirs()
    local projects = get_projects()

    -- Создаем кастомный previewer
    local project_previewer = previewers.new_buffer_previewer({
        title = "Project Info",
        define_preview = function(self, entry)
            local info = get_project_info(entry.value)
            local lines = {
                "Name: " .. info.name,
                "Description: " .. info.description,
                "",
                "Path: " .. config.projects_dir .. "/" .. info.name,
                ""
            }

            if info.run then
                table.insert(lines, "Run command: " .. info.run)
                table.insert(lines, "Run in terminal: " .. (info.runInTerm == "true" and "Yes" or "No"))
                table.insert(lines, "")
            end

            if info.build then
                table.insert(lines, "Build command: " .. info.build)
                table.insert(lines, "Build in terminal: " .. (info.buildInTerm == "true" and "Yes" or "No"))
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end
    })

    pickers.new({
        prompt_title = "Lum Projects",
        finder = finders.new_table({
            results = projects,
            entry_maker = function(entry)
                local info = get_project_info(entry)
                return {
                    value = entry,
                    display = entry .. (info.description ~= "" and (" - " .. info.description) or ""),
                    ordinal = entry,
                    info = info
                }
            end
        }),
        sorter = conf.generic_sorter({}),
        previewer = project_previewer,
        layout_config = {
            width = 0.8,
            height = 0.8
        },
        attach_mappings = function(prompt_bufnr, map)
            -- Открытие проекта при нажатии Enter
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    local project_path = config.projects_dir .. "/" .. selection.value
                    vim.cmd("cd " .. vim.fn.fnameescape(project_path))
                    vim.notify("Opened project: " .. selection.value, vim.log.levels.INFO)
                end
            end)

            -- Удаление проекта при нажатии d
            map("i", "<c-d>", function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    vim.ui.select({ "Yes", "No" }, {
                        prompt = "Delete project '" .. selection.value .. "'?"
                    }, function(choice)
                        if choice == "Yes" then
                            local success, err = delete_project(selection.value)
                            if success then
                                vim.notify("Project deleted: " .. selection.value, vim.log.levels.INFO)
                                M.telescope_projects() -- Обновляем список
                            else
                                vim.notify("Error: " .. err, vim.log.levels.ERROR)
                            end
                        end
                    end)
                end
            end)

            -- Создание нового проекта при нажатии a
            map("i", "<c-a>", function()
                actions.close(prompt_bufnr)
                prompt_create_project()
                vim.defer_fn(function()
                    M.telescope_projects() -- Обновляем список
                end, 100)
            end)

            return true
        end
    }):find()
end

-- Команда для вызова менеджера
vim.api.nvim_create_user_command("LumProjectsShow", M.open_project_manager, {})
vim.api.nvim_create_user_command("LumProjectsRun", M.start_project, {})
vim.api.nvim_create_user_command("LumProjectsBuild", M.build_project, {})
vim.api.nvim_create_user_command("LumProjectsTelescope", M.telescope_projects, {})

return M
