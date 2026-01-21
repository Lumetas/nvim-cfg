function OpenTerminalWithCommand(cmd)
	-- Создаём вертикальное окно справа (40% ширины) и сразу переходим в него
	vim.cmd('rightbelow vsplit | vertical resize 50')

	-- Открываем терминал и запускаем команду
	vim.cmd('terminal ' .. cmd)

	-- Автоматически переходим в режим вставки
	vim.cmd('startinsert')

	-- Жёстко биндим Esc на закрытие терминала
	vim.cmd([[
	tnoremap <buffer> <Esc> <C-\><C-n>:close!<CR>
	]])
end



vim.api.nvim_create_user_command('Format', function()
    local filetype = vim.bo.filetype
    local filename = vim.fn.expand('%:e')
    local buf = vim.api.nvim_get_current_buf()
    
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd('normal mb')
    
    -- Проверяем JSON-like файлы
    if filetype == 'json' or filetype == 'jsonc' or filename == 'vil' then
        local indent = vim.bo.shiftwidth
        local use_tabs = not vim.bo.expandtab and ' --tab' or ' --space'
        
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, '\n')
        
        local jq_cmd = string.format('jq --indent %d%s .', indent, use_tabs)
        local formatted = vim.fn.system(jq_cmd, content)
        
        if vim.v.shell_error == 0 then
            local formatted_lines = vim.split(formatted, '\n', { plain = true })
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted_lines)
        else
            vim.notify('Ошибка jq, используется стандартное форматирование', vim.log.levels.WARN)
            vim.cmd('normal gg=G`b')
        end
    else
        vim.cmd('normal gg=G`b')
    end
    
    vim.api.nvim_win_set_cursor(0, cursor_pos)
end, {})







-- vim.api.nvim_create_user_command('Format', function()
-- 	-- Устанавливаем метку 'b' на текущей строке
-- 	vim.cmd('normal mbgg=G`b')
-- end, {})
-- Команда форматирования кода для emfy
vim.api.nvim_create_user_command('EmfyFormat', function()
	-- Сохраняем текущие настройки табов
	local old_expandtab = vim.bo.expandtab
	local old_shiftwidth = vim.bo.shiftwidth
	local old_tabstop = vim.bo.tabstop
	local old_softtabstop = vim.bo.softtabstop

	-- Устанавливаем настройки для 2 пробелов
	vim.bo.expandtab = true
	vim.bo.shiftwidth = 2
	vim.bo.tabstop = 2
	vim.bo.softtabstop = 2

	-- Выполняем форматирование
	vim.lsp.buf.format()
	-- Восстанавливаем оригинальные настройки
	vim.bo.expandtab = old_expandtab
	vim.bo.shiftwidth = old_shiftwidth
	vim.bo.tabstop = old_tabstop
	vim.bo.softtabstop = old_softtabstop
end, {})



vim.api.nvim_create_user_command('EmfyFormatNoLsp', function()
	-- Сохраняем текущие настройки табов
	local old_expandtab = vim.bo.expandtab
	local old_shiftwidth = vim.bo.shiftwidth
	local old_tabstop = vim.bo.tabstop
	local old_softtabstop = vim.bo.softtabstop

	-- Устанавливаем настройки для 2 пробелов
	vim.bo.expandtab = true
	vim.bo.shiftwidth = 2
	vim.bo.tabstop = 2
	vim.bo.softtabstop = 2

	-- Выполняем форматирование
	vim.cmd('normal mbgg=G`b')

	-- Восстанавливаем оригинальные настройки
	vim.bo.expandtab = old_expandtab
	vim.bo.shiftwidth = old_shiftwidth
	vim.bo.tabstop = old_tabstop
	vim.bo.softtabstop = old_softtabstop
end, {})

-- Автоматическое обновление древа NERDTree при смене директории
-- vim.api.nvim_create_augroup('NERDTreeAutoUpdate', { clear = true })
-- vim.api.nvim_create_autocmd('DirChanged', {
-- 	group = 'NERDTreeAutoUpdate',
-- 	pattern = '*',
-- 	callback = function()
-- 		require("nvim-tree.api").tree.change_root(vim.fn.getcwd())
-- 	end,
-- })


vim.api.nvim_create_user_command(
	'ClearWIN',
	function()
		vim.cmd([[%s/\r//g]])  -- выполняем замену
		print("Удалены все ^M (CR) из файла")
	end,
	{ desc = "Remove all Windows CR (^M) characters" }
)


vim.api.nvim_create_user_command('W', function()
	local tmpfile = vim.fn.tempname()
	local filepath = vim.fn.expand('%:p')
	vim.cmd('w! ' .. tmpfile)
	vim.fn.inputsave()  -- Сохраняем текущий ввод
	local password = vim.fn.inputsecret('Пароль sudo: ')  -- Скрытый ввод пароля
	vim.fn.inputrestore()  -- Восстанавливаем ввод
	local cmd = string.format('echo %s | sudo -S cp -f %s %s && rm -f %s', 
	vim.fn.shellescape(password), tmpfile, filepath, tmpfile)
	vim.cmd('!' .. cmd)
end, { bang = true })

local function setup_resize_mode()
	local opts = { noremap = true, silent = true }

	-- Вход в режим ресайза
	vim.keymap.set('n', '<Leader>r', function()
		-- Сохраняем предыдущие маппинги
		local original_maps = {}
		local keys = { 'h', 'j', 'k', 'l', 'q', '<Esc>' }

		for _, key in ipairs(keys) do
			original_maps[key] = vim.fn.maparg(key, 'n')
		end

		-- Устанавливаем временные маппинги
		vim.cmd('echo "Resize mode: h/j/k/l to resize, q/Esc to quit"')

		local maps = {
			{ 'h', ':vertical resize -2<CR>' },
			{ 'j', ':resize -2<CR>' },
			{ 'k', ':resize +2<CR>' },
			{ 'l', ':vertical resize +2<CR>' },
			{ 'q', function() 
				-- Восстанавливаем оригинальные маппинги
				for key, cmd in pairs(original_maps) do
					if cmd ~= '' then
						vim.api.nvim_set_keymap('n', key, cmd, { noremap = true, silent = true })
					else
						vim.api.nvim_del_keymap('n', key)
					end
				end
				vim.cmd('echo ""')
			end },
			{ '<Esc>', function() 
				-- Восстанавливаем оригинальные маппинги
				for key, cmd in pairs(original_maps) do
					if cmd ~= '' then
						vim.api.nvim_set_keymap('n', key, cmd, { noremap = true, silent = true })
					else
						vim.api.nvim_del_keymap('n', key)
					end
				end
				vim.cmd('echo ""')
			end }
		}

		for _, map in ipairs(maps) do
			if type(map[2]) == 'string' then
				vim.api.nvim_set_keymap('n', map[1], map[2], { noremap = true, silent = true })
			else
				vim.keymap.set('n', map[1], map[2], { noremap = true, silent = true })
			end
		end
	end, opts)
end

setup_resize_mode()

vim.api.nvim_create_autocmd("FileType", { -- Скрипт для отключения автоотступов в указанных типах буферов
  pattern = { "org", "markdown", "text", "gitcommit" },
  callback = function()
    vim.bo.autoindent = false
    vim.bo.smartindent = false
    vim.bo.cindent = false
    vim.bo.indentexpr = ""
    vim.bo.formatoptions = vim.bo.formatoptions:gsub("[cro]", "")
  end,
})



vim.api.nvim_create_user_command('LumInstallXdebug', function()
    local config_dir = vim.fn.stdpath('config')
    local xdebug_dir = config_dir .. '/xdebug'
    
    -- Проверяем существование директории
    if vim.fn.isdirectory(xdebug_dir) == 0 then
        vim.notify("❌ Директория xdebug не найдена: " .. xdebug_dir, vim.log.levels.ERROR)
        return
    end
    
    -- Проверяем наличие package.json
    local package_json = xdebug_dir .. '/package.json'
    if vim.fn.filereadable(package_json) == 0 then
        vim.notify("❌ package.json не найден в директории xdebug", vim.log.levels.WARN)
        return
    end
    
    vim.notify("🚀 Переход в " .. xdebug_dir .. " и запуск npm install...", vim.log.levels.INFO)
    
    -- Меняем рабочую директорию и выполняем команду
    vim.cmd('cd ' .. vim.fn.fnameescape(xdebug_dir))
    vim.cmd('terminal npm install')
end, {})


vim.api.nvim_create_user_command('EmfyGenerateEnvWithConfig', function()
    local json_str = vim.fn.getline(1, '$')
    json_str = table.concat(json_str, '\n')
    
    -- Парсим JSON
    local ok, json_data = pcall(vim.fn.json_decode, json_str)
    if not ok or type(json_data) ~= 'table' or #json_data == 0 then
        vim.notify('Invalid JSON format', vim.log.levels.ERROR)
        return
    end
    
    local widget_data = json_data[1]
    local first_key = next(widget_data)
    if not first_key then
        vim.notify('No widget data found', vim.log.levels.ERROR)
        return
    end
    
    local data = widget_data[first_key]
    
    -- Создаем .env содержимое
    local env_lines = {
        string.format('FOLDER_WIDGET="%s"', data.developer or ''),
        string.format('WIDGET_NAME="%s"', first_key),
        string.format('CLIENT_SECRET="%s"', data.client_secret or ''),
        string.format('CLIENT_ID="%s"', data.client_id or ''),
        string.format('APP_NAME="%s"', data.app_name or ''),
        string.format('WIDGET_NAME_RU="%s"', data.widget_name or ''),
        string.format('API_KEY="%s"', data.api_key or ''),
        string.format('REDIRECT_URL="%s"', data.redirect_uri or ''),
        string.format('PARENT_FOLDER_NAME="%s"', data.folder or ''),
        'API_TOKEN=028d485e3428d07a563b140239a28b34',
        '',
        'RABBIT_MQ_HOST=api.emfy.com',
        'RABBIT_MQ_PORT=5672',
        'RABBIT_MQ_USER=rabbitmqadmin',
        'RABBIT_MQ_PASSWORD=aY9DeshWP6awkWIB'
    }
    
    -- Заменяем содержимое буфера
    vim.api.nvim_buf_set_lines(0, 0, -1, false, env_lines)
    vim.notify('JSON converted to .env format', vim.log.levels.INFO)
end, {})

local COPY = {}
COPY.copy_file = function(filepath)
    -- Expand path to absolute with proper escaping
    filepath = vim.fn.fnamemodify(filepath, ':p')
    
    -- Check if file exists and is readable
    local stat = vim.loop.fs_stat(filepath)
    if not stat or stat.type ~= 'file' then
        vim.notify(string.format("❌ Файл не существует или недоступен: '%s'", filepath), vim.log.levels.ERROR)
        return false
    end
    
    -- Detect clipboard tool based on environment
    local clipboard_tool = nil
    local copy_cmd = nil
    
    if os.getenv("WAYLAND_DISPLAY") then
        -- Wayland
        if vim.fn.executable('wl-copy') == 1 then
            clipboard_tool = 'wl-copy'
            local file_uri = "file://" .. vim.fn.shellescape(filepath)
            copy_cmd = string.format("echo '%s' | wl-copy --type text/uri-list", file_uri)
        end
    else
        -- X11 or other
        if vim.fn.executable('xclip') == 1 then
            clipboard_tool = 'xclip'
            local file_uri = "file://" .. vim.fn.shellescape(filepath)
            copy_cmd = string.format("echo '%s' | xclip -selection clipboard -t text/uri-list", file_uri)
        elseif vim.fn.executable('xsel') == 1 then
            clipboard_tool = 'xsel'
            local file_uri = "file://" .. vim.fn.shellescape(filepath)
            copy_cmd = string.format("echo '%s' | xsel --clipboard --input", file_uri)
        end
    end
    
    -- Fallback for macOS
    if not clipboard_tool and vim.fn.has('mac') == 1 then
        if vim.fn.executable('pbcopy') == 1 then
            clipboard_tool = 'pbcopy'
            copy_cmd = string.format("echo '%s' | pbcopy", vim.fn.shellescape(filepath))
        end
    end
    
    if not clipboard_tool then
        vim.notify("🚫 Не найден подходящий инструмент буфера обмена (wl-copy/xclip/xsel/pbcopy)", vim.log.levels.ERROR)
        return false
    end
    
    -- Execute copy command
    local success, result = pcall(vim.fn.system, copy_cmd)
    
    if success and vim.v.shell_error == 0 then
        local filename = vim.fn.fnamemodify(filepath, ':t')
        vim.notify(string.format("📎 Файл скопирован в буфер: '%s' (%s)", filename, clipboard_tool), vim.log.levels.INFO)
        
        -- Additional: copy file content as text fallback
        local content_success = pcall(function()
            local content = vim.fn.system(string.format("head -n 100 '%s'", vim.fn.shellescape(filepath)))
            if vim.fn.executable('wl-copy') == 1 then
                vim.fn.system(string.format("echo '%s' | wl-copy --type text/plain", vim.fn.shellescape(content)))
            elseif vim.fn.executable('xclip') == 1 then
                vim.fn.system(string.format("echo '%s' | xclip -selection clipboard -t text/plain", vim.fn.shellescape(content)))
            end
        end)
        
        return true
    else
        vim.notify(string.format("💥 Ошибка копирования файла: %s", result or 'unknown error'), vim.log.levels.ERROR)
        return false
    end
end

-- Bonus: функция для копирования нескольких файлов
COPY.copy_files = function(filepaths)
    local results = {}
    for _, path in ipairs(filepaths) do
        table.insert(results, COPY.copy_file(path))
    end
    return results
end

-- Bonus: функция для копирования файла с разными типами контента
COPY.copy_file_advanced = function(filepath, options)
    options = options or {}
    local content_type = options.content_type or "uri" -- uri, path, content
    
    filepath = vim.fn.fnamemodify(filepath, ':p')
    
    local stat = vim.loop.fs_stat(filepath)
    if not stat or stat.type ~= 'file' then
        vim.notify(string.format("❌ Файл не существует: '%s'", filepath), vim.log.levels.ERROR)
        return false
    end
    
    local copy_text = ""
    
    if content_type == "uri" then
        copy_text = "file://" .. filepath
    elseif content_type == "path" then
        copy_text = filepath
    elseif content_type == "content" then
        local file = io.open(filepath, "r")
        if file then
            copy_text = file:read("*a")
            file:close()
        else
            vim.notify("❌ Не удалось прочитать файл", vim.log.levels.ERROR)
            return false
        end
    end
    
    -- Use the same clipboard detection logic from above
    local clipboard_tool = nil
    if os.getenv("WAYLAND_DISPLAY") and vim.fn.executable('wl-copy') == 1 then
        vim.fn.system(string.format("echo '%s' | wl-copy", vim.fn.shellescape(copy_text)))
    elseif vim.fn.executable('xclip') == 1 then
        vim.fn.system(string.format("echo '%s' | xclip -selection clipboard", vim.fn.shellescape(copy_text)))
    elseif vim.fn.executable('xsel') == 1 then
        vim.fn.system(string.format("echo '%s' | xsel --clipboard --input", vim.fn.shellescape(copy_text)))
    elseif vim.fn.has('mac') == 1 and vim.fn.executable('pbcopy') == 1 then
        vim.fn.system(string.format("echo '%s' | pbcopy", vim.fn.shellescape(copy_text)))
    else
        vim.notify("🚫 Clipboard tool not found", vim.log.levels.ERROR)
        return false
    end
    
    vim.notify(string.format("✅ Скопировано как %s: %s", content_type, vim.fn.fnamemodify(filepath, ':t')), vim.log.levels.INFO)
    return true
end

vim.api.nvim_set_keymap('n', '<leader>c', '', { desc = 'Copy', noremap = true, silent = true })
-- Хоткеи для обычных буферов
vim.keymap.set('n', '<leader>cf', function()
    if COPY.copy_file(vim.fn.expand('%:p')) then
		print("File copied")
	else 
		print("File copy failed")
	end
end, { desc = 'File' })

vim.keymap.set('n', '<leader>ct', function() 
	vim.cmd("%y+")
	print("Text copied")
end, { desc = 'Text' })

if vim.fn.has('gui_running') ~= 0 then 
	local current_font_size = 12
	local default_font_size = 12
	local font_name = "FiraCode Nerd Font Mono Med"

	-- Функция для обновления шрифта
	local function update_font()
		vim.opt.guifont = string.format("%s:h%d", font_name, current_font_size)
	end

	-- Увеличить размер шрифта
	vim.keymap.set('n', '<C-=>', function()
		current_font_size = current_font_size + 1
		update_font()
	end, { noremap = true, silent = true, desc = "Увеличить шрифт" })

	-- Уменьшить размер шрифта
	vim.keymap.set('n', '<C-->', function()
		if current_font_size > 6 then  -- Минимальный размер 6
			current_font_size = current_font_size - 1
			update_font()
		end
	end, { noremap = true, silent = true, desc = "Уменьшить шрифт" })

	-- Сбросить размер шрифта к 12
	vim.keymap.set('n', '<C-0>', function()
		current_font_size = default_font_size
		update_font()
	end, { noremap = true, silent = true, desc = "Сбросить шрифт" })

	-- Инициализация шрифта при запуске
	update_font()
end





-- Хоткеи для работы с org-файлами
vim.keymap.set('n', '<leader>ofn', function()
    -- Проверяем, что переменная установлена
    if not org_path then
        vim.notify("Ошибка: переменная org_path не установлена", vim.log.levels.ERROR)
        return
    end
    
    -- Разворачиваем путь (~/org/ -> /home/user/org/)
    local expanded_path = vim.fn.expand(org_path)
    
    -- Проверяем существование директории
    if vim.fn.isdirectory(expanded_path) == 0 then
        vim.notify("Ошибка: директория " .. expanded_path .. " не существует", vim.log.levels.ERROR)
        return
    end
    
    -- Поиск файлов по имени с помощью Telescope
    require('telescope.builtin').find_files({
        cwd = expanded_path,
        prompt_title = "Поиск org-файлов по имени",
        find_command = {"find", ".", "-name", "*.org", "-type", "f"},
    })
end, { desc = "Поиск org-файлов по имени" })

vim.keymap.set('n', '<leader>ofc', function()
    -- Проверяем, что переменная установлена
    if not org_path then
        vim.notify("Ошибка: переменная org_path не установлена", vim.log.levels.ERROR)
        return
    end
    
    -- Разворачиваем путь
    local expanded_path = vim.fn.expand(org_path)
    
    -- Проверяем существование директории
    if vim.fn.isdirectory(expanded_path) == 0 then
        vim.notify("Ошибка: директория " .. expanded_path .. " не существует", vim.log.levels.ERROR)
        return
    end
    
    -- Поиск по содержимому с помощью Telescope
    require('telescope.builtin').live_grep({
        cwd = expanded_path,
        prompt_title = "Поиск org-файлов по содержимому",
        type_filter = "org", -- фильтр для org-файлов
    })
end, { desc = "Поиск org-файлов по содержимому" })

vim.keymap.set('n', '<leader>ofa', function()
    -- Проверяем, что переменная установлена
    if not org_path then
        vim.notify("Ошибка: переменная org_path не установлена", vim.log.levels.ERROR)
        return
    end
    
    -- Разворачиваем путь
    local expanded_path = vim.fn.expand(org_path)
    
    -- Проверяем существование директории
    if vim.fn.isdirectory(expanded_path) == 0 then
        vim.notify("Ошибка: директория " .. expanded_path .. " не существует", vim.log.levels.ERROR)
        return
    end
    
    -- Запрашиваем имя файла у пользователя
    local filename = vim.fn.input("Имя файла (без расширения .org): ")
    
    -- Проверяем, что пользователь ввел имя
    if filename == "" then
        vim.notify("Отменено: не введено имя файла", vim.log.levels.WARN)
        return
    end
    
    -- Добавляем расширение .org если его нет
    if not filename:match("%.org$") then
        filename = filename .. ".org"
    end
    
    -- Создаем полный путь к файлу
    local full_path = expanded_path .. "/" .. filename
    
    -- Создаем директории если их нет (для вложенных путей)
    local dir_path = vim.fn.fnamemodify(full_path, ":h")
    if vim.fn.isdirectory(dir_path) == 0 then
        vim.fn.mkdir(dir_path, "p")
    end
    
    -- Создаем файл и открываем его
    vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    
    vim.notify("Создан файл: " .. full_path)
end, { desc = "Создать новый org-файл" })



vim.keymap.set('n', '<leader>ml', function()
    local targets = {}
    -- Улучшенная команда для поиска целей
    local handle = io.popen("grep -E '^[^#[:space:]\\.][^:]*:' Makefile | cut -d ':' -f 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'")
    if handle then
        for target in handle:read("*a"):gmatch("[^\r\n]+") do
            if target ~= "" then
                table.insert(targets, target)
            end
        end
        handle:close()
    end

    if #targets == 0 then
        vim.notify("No make targets found", vim.log.levels.WARN)
        return
    end

    require('telescope.pickers').new({}, {
        prompt_title = "Make Targets (" .. #targets .. ")",
        finder = require('telescope.finders').new_table({
            results = targets,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry,
                    ordinal = entry,
                }
            end
        }),
        sorter = require('telescope.config').values.generic_sorter({}),
        -- Отключаем все игноры и фильтры
        file_ignore_patterns = {},
        hidden = true,
        no_ignore = true,
        no_ignore_parent = true,
        attach_mappings = function(prompt_bufnr, map)
            map({'i', 'n'}, '<CR>', function()
                local selection = require('telescope.actions.state').get_selected_entry()
                require('telescope.actions').close(prompt_bufnr)
                if selection then
                    vim.cmd("!make " .. selection.value .. "")
                end
            end)
            return true
        end,
    }):find()
end, { desc = "List make targets" })

vim.keymap.set('n', '<leader>Q', ':bnext | bdelete! #<CR>', { desc = "Switch to prev and kill current buffer" })




vim.cmd([[function! CT(char) abort
    let current_line = getline('.')
    let cursor_col = col('.') - 1
    
    " Ищем первое вхождение символа ПОСЛЕ курсора
    let char_pos = stridx(current_line, a:char, cursor_col + 1)
    
    if char_pos == -1
        return ''
    else
        " Возвращаем текст от курсора до символа (исключая символ)
        return strpart(current_line, cursor_col, char_pos - cursor_col)
    endif
endfunction]])
