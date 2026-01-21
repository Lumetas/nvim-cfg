return function(lnpm)
    lnpm.load('hrsh7th/nvim-cmp', function()
        lnpm.load('hrsh7th/cmp-nvim-lsp')
        lnpm.load('hrsh7th/cmp-buffer')
        lnpm.load('hrsh7th/cmp-path')
        lnpm.load('hrsh7th/cmp-cmdline')
        
        local cmp = require("cmp")
        
        cmp.setup({
            completion = {
                completeopt = "menu,menuone,noinsert,noselect",
                keyword_length = 1,
            },
            
            mapping = cmp.mapping.preset.insert({
				['<C-space>'] = cmp.mapping.complete(),
                ["<C-CR>"] = cmp.mapping.confirm({ select = true }),
                ["<C-n>"] = cmp.mapping.select_next_item(),
                ["<C-p>"] = cmp.mapping.select_prev_item(),
                
            }),
            
            sources = cmp.config.sources({
                { 
                    name = "nvim_lsp",
                    keyword_pattern = [=[[\%(\$\k*\)\|\k\+]]=],
                },
                { 
                    name = "buffer",
                    option = {
                        get_bufnrs = function()
                            return vim.api.nvim_list_bufs()
                        end
                    }
                },
                { name = "path" },
            }),
            
            -- Минимальные настройки производительности
            performance = {
                debounce = 150,
                throttle = 60,
                fetching_timeout = 500,
            },
        })
        
        -- Настройка автодополнения для командной строки
        cmp.setup.cmdline({ '/', '?' }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = 'buffer' }
            }
        })
        
        cmp.setup.cmdline(':', {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = 'path' }
            }, {
                { name = 'cmdline' }
            })
        })

        
    end, {lrule = function(next) vim.defer_fn(next, 5000) end})
end
