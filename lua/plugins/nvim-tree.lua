local tree_rule = function(next)
	vim.keymap.set('n', '<C-n>', function()
		next()
		vim.schedule(function()
			require("nvim-tree.api").tree.toggle()  -- потом открываем
		end)
	end, { noremap = true, desc = "Toggle NvimTree" })
end


return function(lnpm)

  lnpm.load('nvim-tree/nvim-tree.lua', function(tree)
    tree.setup({
      git = {
        enable = true,
        timeout = 400,
      },
      filesystem_watchers = {
        enable = false,
      },
      renderer = {
        group_empty = true,
        indent_markers = {
          enable = true,
        },
        root_folder_label = false
      },
      view = { 
        side = "right",
        width = 30,
      },
      actions = {
        change_dir = {
          global = false,
        },
        open_file = {
          quit_on_open = false,
        },
      },
    })

    -- Обновляем хоткей после загрузки плагина
    vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { noremap = true })

    -- Автообновление корня при смене директории
    vim.api.nvim_create_augroup('NvimTreeAutoUpdate', { clear = true })
    vim.api.nvim_create_autocmd('DirChanged', {
      group = 'NvimTreeAutoUpdate',
      pattern = '*',
      callback = function()
        if require("nvim-tree.api").tree then
          require("nvim-tree.api").tree.change_root(vim.fn.getcwd())
        end
      end,
    })

  end, {
    name = "nvim-tree",
    lrule = tree_rule
  })
end
