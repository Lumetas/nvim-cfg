lnpm = require("lnpm")

require("plugins/custom")(lnpm)

org_path = '~/org/'

require("themes")(lnpm)

require('settings')


require("plugins/nvim-tree")(lnpm)
require("plugins/oil")(lnpm)
require("plugins/cmp")(lnpm)
require("plugins/lsp")(lnpm)
require("plugins/telescope")(lnpm)
-- require("plugins/ufo")(lnpm)
require("plugins/hop")(lnpm)
require('scratch')
-- require("plugins/startup")(lnpm)
require("plugins/whichkey")(lnpm)

-- lnpm.load('tpope/vim-commentary')


require("plugins/git")(lnpm)

require('plugins/orgmode')(lnpm)
require('plugins/supermaven')(lnpm)

require('plugins/dap')(lnpm)

require('custom')
require('russian')
require('statusline')


require('plugins/lumprojects')(lnpm)
require('plugins/lqc')(lnpm)
-- require('plugins/http')(lnpm)
require('plugins/sql')(lnpm)

require("hotkeys")

vim.g.neovide_opacity = 0.75

vim.cmd('colorscheme leos')

-- lnpm.load_after_install()
