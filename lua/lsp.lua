-- Настройки LSP
local lspconfig = require('lspconfig')

lspconfig.intelephense.setup {
    cmd = { "intelephense", "--stdio" }, -- Путь к инсталляции Intelephense
    filetypes = { "php" },
    root_dir = function(fname)
        return lspconfig.util.root_pattern("composer.json", ".git")(fname) or vim.fn.getcwd()
    end,
    settings = {
        intelephense = {
            format = {
                enable = true -- Включить автоформатирование
            },
            diagnostics = {
                enable = true -- Включить диагностику
            }
        }
    }
}
