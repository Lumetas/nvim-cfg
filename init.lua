vim.g.reset_layout_on_leave = true -- Сбрасывать ли расскладку на английский при выходе из insert mode

-- vim_theme = { "gruvbox", "vim" }
-- vim_theme = { "monokai", "vim" }
-- vim_theme = { "neofusion", "nvim" }
vim_theme = { "lumos", "nvim" }
-- vim_theme = { "everforest", "scheme" }

vim_dir = vim.fn.stdpath('config')

-- Подключение модулей
require('settings')    -- Основные настройки

require('color') -- Цветовые схемы
require('lsp') -- LSP Автодополнение и прочее
require('statusline') -- статус-лайн
require('commands') -- Произвольные команды
require('map') -- Русский язык
-- require('lumSnippets') -- Сниппеты
require('file_search') -- Поиск файлов
require('php-cs') -- Интеграия с php-cs-fixer : composer global require friendsofphp/php-cs-fixer
require("lum-projects"); -- Менеджер проектов
require('keymaps')     -- Хоткеи
require('nvimtree') -- config для nvim-tree

require("dapconf") -- debug(для php)
require("ufo-conf") -- ufo config
require("org") -- orgmode
require('hop-conf') -- Конфиг для быстрых перемещений
require("startup-conf") -- Конфиг для стартового меню
require("tabbar") -- Вкладки

vim.cmd('hi Normal guibg=NONE ctermbg=NONE');

vim.g.neovide_opacity = 0.75

vim.opt.shortmess:append("I")

require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<C-i>",
    clear_suggestion = "<C-c>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = { cpp = true }, -- or { "cpp", }
  color = {
    suggestion_color = "#ffffff",
    cterm = 244,
  },
  log_level = "info", -- set to "off" to disable logging completely
  disable_inline_completion = false, -- disables inline completion for use with cmp
  disable_keymaps = false, -- disables built in keymaps for more manual control
  condition = function()
    return false
  end -- condition to check for stopping supermaven, `true` means to stop supermaven when the condition is true.
})
