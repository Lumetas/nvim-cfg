vim.api.nvim_create_autocmd('LspAttach', { callback = function(ev) local client = vim.lsp.get_client_by_id(ev.data.client_id) if client:supports_method('textDocument/completion') then vim.lsp.completion.enable(true, client.id , ev.buf, { autotrigger = false }) end end, }) 
vim.api.nvim_set_keymap('i', '<C-Space>', '<C-x><C-o>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('i', '<C-j>', '<C-y>', {noremap = true, silent = true})

