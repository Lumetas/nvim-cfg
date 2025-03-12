-- Генерация файла lumlaravel (доступна всегда)
local function generate_lumlaravel()
    local paths = {
        models = "app/Models",
        controllers = "app/Http/Controllers",
        views = "resources/views",
        routes = "routes",
        migrations = "database/migrations",
        seeders = "database/seeders"
    }

    local content = "return " .. vim.inspect(paths)
    local file = io.open("lumlaravel", "w")
    if file then
        file:write(content)
        file:close()
        vim.notify("Файл lumlaravel успешно создан!", vim.log.levels.INFO)
    else
        vim.notify("Не удалось создать файл lumlaravel!", vim.log.levels.ERROR)
    end
end

-- Команда для генерации lumlaravel (доступна всегда)
vim.api.nvim_create_user_command('GenerateLumLaravel', generate_lumlaravel, {})

-- Проверка наличия файла artisan и lumlaravel
local function is_laravel_project()
    return vim.fn.filereadable("artisan") == 1 and vim.fn.filereadable("lumlaravel") == 1
end

-- Чтение конфигурации из lumlaravel
local function read_lumlaravel_config()
    local config_file = vim.fn.getcwd() .. "/lumlaravel"
    if vim.fn.filereadable(config_file) == 1 then
        local config = dofile(config_file)
        return config
    else
        return nil
    end
end

-- Функция RunArtisan (глобальная)
function _G.run_artisan()
	local command = vim.fn.input('artisan: ')
	if new_project_name and new_project_name ~= "" then
		local output = vim.fn.system("php artisan " .. command)
		vim.notify(output, vim.log.levels.INFO)
	end
end

-- Инициализация плагина (только при наличии artisan и lumlaravel)
local function init_plugin()
    if not is_laravel_project() then
        return
    end

    local config = read_lumlaravel_config()

    if config then
        -- Маппинги для навигации по директориям
        vim.api.nvim_set_keymap('n', '<C-m>m', ':e ' .. config.models .. '<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-m>c', ':e ' .. config.controllers .. '<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-m>v', ':e ' .. config.views .. '<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-m>r', ':e ' .. config.routes .. '<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-m>g', ':e ' .. config.migrations .. '<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-m>s', ':e ' .. config.seeders .. '<CR>', { noremap = true, silent = true })
    end

    -- Команда Artisan
    vim.api.nvim_create_user_command('Artisan', function(opts)
        local output = vim.fn.system("php artisan " .. opts.args)
        vim.notify(output, vim.log.levels.INFO)
    end, { nargs = 1 })

    -- Маппинг для RunArtisan
    vim.api.nvim_set_keymap('n', '<C-a>', ':lua _G.run_artisan()<CR>', { noremap = true })
end


vim.api.nvim_create_augroup('lumLaravelUpdate', { clear = true })
vim.api.nvim_create_autocmd('DirChanged', {
  group = 'lumLaravelUpdate',
  pattern = '*',
  callback = init_plugin,
})

-- Автоматическая инициализация плагина при запуске Neovim
init_plugin()
