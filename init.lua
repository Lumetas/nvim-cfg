lnpm = require("lnpm")
org_path = '~/org/'

require("themes/neofusion")(lnpm)

require('settings')

lnpm.load('nvim-lua/plenary.nvim')
lnpm.load('nvim-tree/nvim-web-devicons')
lnpm.load('kevinhwang91/promise-async')

require("plugins/nvim-tree")(lnpm)
require("plugins/cmp")(lnpm)
require("plugins/lsp")(lnpm)
require("plugins/telescope")(lnpm)
-- require("plugins/ufo")(lnpm)
require("plugins/hop")(lnpm)
require("plugins/startup")(lnpm)

lnpm.load('tpope/vim-commentary')
lnpm.load('nvim-treesitter/nvim-treesitter')
lnpm.load('tpope/vim-fugitive')
lnpm.load('mattn/emmet-vim')

require('plugins/orgmode')(lnpm)
require('plugins/supermaven')(lnpm)
lnpm.load('kevinhwang91/nvim-bqf')
require('custom')
require('russian')
require('statusline')
lnpm.load('mikavilpas/yazi.nvim', function() 
	vim.api.nvim_set_keymap('n', 'zx', ':Yazi<CR>', { noremap = true })
end)

require('lum-projects')


require("hotkeys")

lnpm.load_after_install()
