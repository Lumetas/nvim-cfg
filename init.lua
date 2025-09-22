lnpm = require("lnpm")
org_path = '~/org/'

require("themes")(lnpm)

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
require('scratch')
require("plugins/startup")(lnpm)
require("plugins/whichkey")(lnpm)

lnpm.load('tpope/vim-commentary')

lnpm.load('nvim-treesitter/nvim-treesitter', nil, { onInstall = function() 
	vim.cmd('TSInstall php javascript css html markdown lua go python')
end })

require("plugins/git")(lnpm)
lnpm.load('mattn/emmet-vim')

require('plugins/orgmode')(lnpm)
require('plugins/supermaven')(lnpm)

require('plugins/dap')(lnpm)

lnpm.load('kevinhwang91/nvim-bqf')
require('custom')
require('russian')
require('statusline')

lnpm.load('mikavilpas/yazi.nvim', function() 
	vim.api.nvim_set_keymap('n', 'zx', ':Yazi<CR>', { noremap = true })
end)

require('plugins/lumprojects')(lnpm)
require('plugins/lqc')(lnpm)

require("hotkeys")

vim.g.neovide_opacity = 0.75

vim.cmd('colorscheme leos')

vim.lsp.enable({"intelephense", "ts_ls"})

lnpm.load_after_install()
