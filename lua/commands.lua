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

-- Команда для форматирования кода
vim.api.nvim_create_user_command('Format', function()
	-- Устанавливаем метку 'b' на текущей строке
	vim.cmd('normal mbgg=G`b')
end, {})
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
	vim.cmd('normal mbgg=G`b')

	-- Восстанавливаем оригинальные настройки
	vim.bo.expandtab = old_expandtab
	vim.bo.shiftwidth = old_shiftwidth
	vim.bo.tabstop = old_tabstop
	vim.bo.softtabstop = old_softtabstop
end, {})

-- Автоматическое обновление древа NERDTree при смене директории
vim.api.nvim_create_augroup('NERDTreeAutoUpdate', { clear = true })
vim.api.nvim_create_autocmd('DirChanged', {
	group = 'NERDTreeAutoUpdate',
	pattern = '*',
	callback = function()
		require("nvim-tree.api").tree.change_root(vim.fn.getcwd())
	end,
})


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
