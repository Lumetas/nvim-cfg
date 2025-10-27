local M = {}

-- Конфигурация по умолчанию
M.promt_win = nil
M.prompt_buf = nil
M.response_buffer = nil
M.config = {
	api_url = "https://api.openai.com/v1/chat/completions",
	api_key = nil,
	model = "gpt-4",
	system_prompt = nil,
	max_tokens = 4000
}

-- Установка конфигурации
function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	-- Создаем команду для вызова AI ассистента
	vim.api.nvim_create_user_command('AIAssistant', function()
		M.open_prompt_window()
	end, {})
end

-- Получение информации о текущем контексте
function M.get_context_info()
	local current_file = vim.api.nvim_buf_get_name(0)
	local cwd = vim.fn.getcwd()
	local filetype = vim.bo.filetype
	local line_count = vim.api.nvim_buf_line_count(0)

	-- Получаем информацию о системе
	local os_info = vim.loop.os_uname()
	local system_info = string.format("%s %s", os_info.sysname, os_info.release)

	return {
		current_file = current_file,
		cwd = cwd,
		filetype = filetype,
		line_count = line_count,
		system = system_info,
		open_buffers = #vim.api.nvim_list_bufs()
	}
end

-- Построение системного промпта с контекстом
function M.build_system_prompt()
	local context = M.get_context_info()
	local base_prompt = [[
	Ты - AI ассистент для программиста, работающего в Neovim.

	КОНТЕКСТ ПОЛЬЗОВАТЕЛЯ:
	- Текущий файл: ]] .. (context.current_file ~= "" and context.current_file or "не открыт") .. [[
	- Рабочая директория: ]] .. context.cwd .. [[
	- Тип файла: ]] .. context.filetype .. [[
	- Размер файла: ]] .. context.line_count .. [[ строк
	- Система: ]] .. context.system .. [[
	- Открыто буферов: ]] .. context.open_buffers .. [[

	ИНСТРУКЦИИ ПО ФАЙЛАМ:
	Если пользователь упоминает файл начинающийся с @ (например @path/to/file), это означает что нужно работать с содержимым этого файла. 
	Относительные пути рассчитываются от текущей рабочей директории.

	ФОРМАТ ОТВЕТА:
	Для выполнения команд в Neovim используй следующий формат:

	```VIM
	команда_режима_vim
	```

	```VIMLUA
	lua код для выполнения
	```
	ПРАВИЛА:

	Перед работой с файлом открой его через команду "e path/to/file"

	Для замен текста предпочтительно использовать :%s/pattern/replacement/gc чтобы пользователь видел изменения или :g/patern/command

	Всегда экранируй специальные символы

	Выдавай только готовый код или команды для решения задачи

	Взаимодействуй с кодом пользователя только через команды Vim или Lua код

	В каждом блоке код VIM команд должны быть только ОДНО команда без двоеточия в начале

	ЦЕЛЬ: Помочь пользователю эффективно решать задачи программирования и редактирования кода.
	]]

	return base_prompt
end

-- Извлечение файлов из промпта и добавление их содержимого
function M.extract_files_from_prompt(prompt)
	local file_pattern = "@([%w%p]-)%s"
	local files = {}
	local enhanced_prompt = prompt

	for file_path in prompt:gmatch(file_pattern) do
		local full_path = vim.fn.expand(file_path)
		if vim.fn.filereadable(full_path) == 1 then
			local content = vim.fn.readfile(full_path)
			files[file_path] = table.concat(content, "\n")
			enhanced_prompt = enhanced_prompt:gsub("@" .. file_path, "Содержимое файла " .. file_path .. ":\n" .. vim.fn.fnamemodify(full_path, ":e") .. "\n" .. files[file_path] .. "\n")
		end
	end

	return enhanced_prompt, files
end

-- Открытие окна для ввода промпта
function M.open_prompt_window()
    -- Создаем буфер для ввода промпта
    local prompt_buf = vim.api.nvim_create_buf(false, true)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.4)

    local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 4),
        style = "minimal",
        border = "rounded"
    })

    -- Устанавливаем параметры буфера
    vim.bo[prompt_buf].filetype = "markdown"
    vim.bo[prompt_buf].buftype = "acwrite"
    vim.bo[prompt_buf].bufhidden = "delete"
    
    -- Устанавливаем имя файла для буфера
    vim.api.nvim_buf_set_name(prompt_buf, "AI_Assistant_Prompt")

    -- Добавляем подсказку как начальное содержимое
    -- local initial_lines = {
    --     "-- Введите ваш запрос к AI ассистенту --",
    --     "-- Для ссылки на файл используйте @path/to/file --", 
    --     "-- Нажмите :w для отправки или :q для отмены --",
    --     "",
    --     "Ваш запрос:"
    -- }
    vim.cmd("startinsert!")

    -- Сохраняем ссылку на окно и буфер
    M.prompt_win = prompt_win
    M.prompt_buf = prompt_buf

    -- Автокоманда для обработки сохранения - правильный подход
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = prompt_buf,
        callback = function()

			local line_count = vim.api.nvim_buf_line_count(prompt_buf) 
            local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, line_count, false)
            local user_prompt = table.concat(lines, "\n")

            -- Закрываем окно
            if M.prompt_win and vim.api.nvim_win_is_valid(M.prompt_win) then
                vim.api.nvim_win_close(M.prompt_win, true)
            end
            
            
            -- Удаляем буфер
            vim.api.nvim_buf_delete(prompt_buf, {force = true})
            
            -- Очищаем ссылки
            M.prompt_win = nil
            M.prompt_buf = nil
            
			local clean_prompt = user_prompt
            
            if #clean_prompt > 10 then  -- Минимальная длина реального запроса
                local enhanced_prompt, files = M.extract_files_from_prompt(clean_prompt)
                M.send_to_ai(enhanced_prompt, files)
            else
                vim.notify("Запрос слишком короткий или отсутствует", vim.log.levels.WARN)
            end
        end
    })
end
-- Обработка промпта пользователя
function M.process_user_prompt(prompt_buf)
	local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
	local user_prompt = table.concat(lines, "\n")

	-- Очищаем буфер промпта
	vim.api.nvim_buf_delete(prompt_buf, {force = true})

	-- Улучшаем промпт с информацией о файлах
	local enhanced_prompt, files = M.extract_files_from_prompt(user_prompt)

	-- Отправляем запрос к API
	M.send_to_ai(enhanced_prompt, files)
end

-- Отправка запроса к AI API
function M.send_to_ai(user_prompt, files)
    if not M.config.api_key then
        vim.notify("API ключ не установлен. Используйте :AISetup для настройки", vim.log.levels.ERROR)
        return
    end

    local system_prompt = M.config.system_prompt or M.build_system_prompt()

    local messages = {
        {role = "system", content = system_prompt},
        {role = "user", content = user_prompt}
    }

    -- Показываем индикатор загрузки
    vim.notify("Отправка запроса к AI...", vim.log.levels.INFO)

    -- Выполняем HTTP запрос
    local job_id = vim.fn.jobstart({
        "curl", "-X", "POST",
        "-H", "Content-Type: application/json",
        "-H", "Authorization: Bearer " .. M.config.api_key,
        "-d", vim.json.encode({
            model = M.config.model,
            messages = messages,
            max_tokens = M.config.max_tokens,
            temperature = 0.7
        }),
        M.config.api_url
    }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if data and #data > 0 then
                local response = table.concat(data, "")
                local ok, result = pcall(vim.json.decode, response)
                if ok and result.choices and #result.choices > 0 then
                    local ai_response = result.choices[1].message.content
                    M.show_ai_response(ai_response)
                else
                    vim.notify("Ошибка при разборе ответа AI: " .. (result and result.error and result.error.message or "неизвестная ошибка"), vim.log.levels.ERROR)
                end
            else
                vim.notify("Пустой ответ от AI", vim.log.levels.ERROR)
            end
        end,
        on_stderr = function(_, error_data)
            if error_data and #error_data > 0 then
                local error_msg = table.concat(error_data, " ")
                -- vim.notify("Ошибка API: " .. error_msg, vim.log.levels.ERROR)
            end
        end,
        on_exit = function(_, exit_code)
            if exit_code ~= 0 then
                vim.notify("Ошибка выполнения curl, код: " .. exit_code, vim.log.levels.ERROR)
            end
        end
    })

    if job_id == 0 then
        vim.notify("Не удалось запустить запрос", vim.log.levels.ERROR)
    elseif job_id == -1 then
        vim.notify("Команда не найдена (убедитесь что curl установлен)", vim.log.levels.ERROR)
    end
end

-- Показать ответ AI
function M.show_ai_response(response)
    -- Создаем буфер для ответа
    local response_buf = vim.api.nvim_create_buf(false, true)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.6)

    local response_win = vim.api.nvim_open_win(response_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 4),
        style = "minimal",
        border = "rounded"
    })

    -- Устанавливаем параметры буфера
    vim.bo[response_buf].filetype = "markdown"
    vim.bo[response_buf].buftype = "nofile"
    vim.bo[response_buf].bufhidden = "delete"
    
    -- Устанавливаем имя файла для буфера
    vim.api.nvim_buf_set_name(response_buf, "AI_Assistant_Response")

    -- Сначала записываем ответ (буфер еще modifiable)
    local lines = vim.split(response, "\n")
    vim.api.nvim_buf_set_lines(response_buf, 0, -1, false, lines)

    -- Только ПОСЛЕ записи делаем буфер неизменяемым
    vim.bo[response_buf].modifiable = false
    vim.bo[response_buf].modified = false

    -- Добавляем маппинг для выполнения кода
    vim.api.nvim_buf_set_keymap(response_buf, 'n', 'y', ':lua require("lumai").execute_code()<CR>',
    {noremap = true, silent = true, nowait = true})
    vim.api.nvim_buf_set_keymap(response_buf, 'n', 'q', ':q!<CR>',
    {noremap = true, silent = true, nowait = true})

    -- Сохраняем ссылку на буфер ответа
    M.response_buffer = response_buf

    -- Добавляем подсказку в статусную строку (сначала разрешаем запись)
    vim.bo[response_buf].modifiable = true
    vim.api.nvim_buf_set_lines(response_buf, -1, -1, false, {"", "---", "Нажмите 'y' для выполнения кода, 'q' для выхода"})
    vim.bo[response_buf].modifiable = false
    vim.bo[response_buf].modified = false
end

-- Выполнение кода из ответа
function M.execute_code()
	if not M.response_buffer or not vim.api.nvim_buf_is_valid(M.response_buffer) then
		vim.notify("Буфер ответа не найден", vim.log.levels.ERROR)
		return
	end

	local lines = vim.api.nvim_buf_get_lines(M.response_buffer, 0, -1, false)
	local content = table.concat(lines, "\n")

	-- Извлекаем блоки кода
	local vim_blocks = {}
	local lua_blocks = {}

	-- Ищем блоки VIM 
	for block in content:gmatch("VIM\n(.-)\n```") do
		table.insert(vim_blocks, block)
	end

	-- Ищем блоки VIMLUA 
	for block in content:gmatch("VIMLUA\n(.-)\n```") do
		table.insert(lua_blocks, block)
	end

	-- Выполняем Vim команды
	for _, cmd in ipairs(vim_blocks) do
		vim.cmd(cmd)
	end

	-- Выполняем Lua код
	for _, lua_code in ipairs(lua_blocks) do
		local ok, err = pcall(loadstring(lua_code))
		if not ok then
			vim.notify("Ошибка выполнения Lua кода: " .. err, vim.log.levels.ERROR)
		end
	end

	if #vim_blocks > 0 or #lua_blocks > 0 then
		vim.notify("Выполнено " .. #vim_blocks .. " Vim команд и " .. #lua_blocks .. " Lua блоков", vim.log.levels.INFO)
	else
		vim.notify("Не найдено блоков кода для выполнения", vim.log.levels.WARN)
	end

end
return M
