return function(lnpm)
  lnpm.load('stevearc/oil.nvim', function(oil)
    oil.setup({
      -- Боковая панель как в nvim-tree
      view_options = {
        show_hidden = true,
        is_hidden_file = function(name, _)
          return vim.startswith(name, ".")
        end,
      },
      
      -- Использовать предварительный просмотр как nvim-tree
      preview = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = 0.9,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
      
      -- Настройка отображения
      renderer = {
        add_user_key_map = false,
        highlight_dir = true,
        highlight_full_name = false,
      },
      
      -- Опции столбцов
      columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
      },
      
      -- Клавиши для навигации как в дереве
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-s>"] = "actions.select_vsplit",
        ["<C-h>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
		["s"] = {
			  callback = function()
				require("oil").save({ confirm = true })
			  end,
			  desc = "Save oil changes",
		},
		["S"] = {
			  callback = function()
				require("oil").save({ confirm = false })
			  end,
			  desc = "Save oil changes",
		},
      },
      
      -- Настройки для плавающего окна
      float = {
        padding = 2,
        max_width = 120,
        max_height = 40,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
      
      -- Git интеграция (если установлено oil-git-status)
      git = {
        enable = true,
      },
    })

    -- Клавиши для открытия/закрытия
    vim.api.nvim_set_keymap('n', '<C-b>', '<cmd>Oil --float .<CR>', { 
      noremap = true, 
      silent = true,
      desc = "Open Oil float in current directory"
    })
    vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>Oil --float<CR>', { 
      noremap = true, 
      silent = true,
      desc = "Open Oil float in current directory"
    })

  end, {
    name = "oil",
    git = false,
    install_path = '~'
  })
end
