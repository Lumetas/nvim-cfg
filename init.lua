-- Переменные и флаги для модулей и плагинов
vim.g.reset_layout_on_leave = true -- Сбрасывать ли расскладку на английский при выходе из insert mode

vim_theme = { "gruvbox", "vim" }
-- vim_theme = { "neofusion", "nvim" }

vim_dir = vim.fn.stdpath('config')



-- Подключение модулей
require('settings')    -- Основные настройки

require('color') -- Цветовые схемы
require('statusline') -- Полоса
require('lsp') -- LSP Автодополнение и прочее
require('commands') -- Произвольные команды
require('map') -- Русский язык
-- require('startmenu') -- Стартовое меню
require('lumSnippets') -- Сниппеты
require('file_search') -- Поиск файлов
require('php-cs') -- Интеграия с php-cs-fixer : composer global require friendsofphp/php-cs-fixer
require("lum-projects"); -- Менеджер проектов
require('keymaps')     -- Хоткеи

vim.cmd('hi Normal guibg=NONE ctermbg=NONE');

vim.g.neovide_opacity = 0.75

require("nvim-tree").setup({
  git = {
    enable = true,
    timeout = 400,
  },
  filesystem_watchers = {
    enable = false,  -- ускоряет работу, но требует ручного обновления (клавиша `R`)
  },
  renderer = {
    group_empty = true,  -- схлопывать пустые папки
    indent_markers = {
      enable = true,
    },
  },
  actions = {
    change_dir = {
      global = false,  -- не менять корневую папку без указания
    },
    open_file = {
      quit_on_open = false,
    },
  },
})



