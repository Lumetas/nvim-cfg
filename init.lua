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
-- require('lumSnippets') -- Сниппеты
require('file_search') -- Поиск файлов
require('php-cs') -- Интеграия с php-cs-fixer : composer global require friendsofphp/php-cs-fixer
require("lum-projects"); -- Менеджер проектов
require('keymaps')     -- Хоткеи
require('nvimtree') -- config для nvim-tree

require("dapconf") -- debug(для php)

vim.cmd('hi Normal guibg=NONE ctermbg=NONE');

vim.g.neovide_opacity = 0.75

vim.opt.shortmess:append("I")
