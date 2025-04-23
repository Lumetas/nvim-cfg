
local function add_plugins_to_runtime()
  -- Путь до папки с плагинами (относительно конфига Neovim)
  local plugins_dir = vim_dir .. '/plugins'

  -- Проверяем, существует ли папка с плагинами
  if vim.fn.isdirectory(plugins_dir) == 0 then
    vim.notify('Папка с плагинами не найдена: ' .. plugins_dir, vim.log.levels.WARN)
    return
  end

  -- Получаем список папок в plugins_dir
  local folders = vim.fn.readdir(plugins_dir)

  -- Добавляем каждую папку в runtimepath
  for _, folder in ipairs(folders) do
    local plugin_path = plugins_dir .. '/' .. folder
    vim.opt.runtimepath:append(plugin_path)
  end
end

-- Вызываем функцию при старте Neovim
add_plugins_to_runtime()
