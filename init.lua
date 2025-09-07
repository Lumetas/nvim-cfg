lnpm = require("lnpm")

require("themes/neofusion")(lnpm)

require('settings')

lnpm.load('nvim-lua/plenary.nvim')
lnpm.load('nvim-tree/nvim-web-devicons')
lnpm.load('kevinhwang91/promise-async')

require("plugins/nvim-tree")(lnpm)
require("plugins/cmp")(lnpm)
require("plugins/lsp")(lnpm)
require("plugins/telescope")(lnpm)
require("plugins/ufo")(lnpm)
