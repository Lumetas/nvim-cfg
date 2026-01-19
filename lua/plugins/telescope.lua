return function(lnpm)
	lnpm.load('nvim-telescope/telescope.nvim', function()

		local action_state = require('telescope.actions.state')
		local telescope = require('telescope')
		local actions = require('telescope.actions')
		local builtin = require('telescope.builtin')


		function select_all()
			local prompt_bufnr = vim.api.nvim_get_current_buf()
			local current_picker = action_state.get_current_picker(prompt_bufnr)
			local i = 1
			for entry in current_picker.manager:iter() do
				current_picker._multi:toggle(entry)
				-- highlighting
				local row = current_picker:get_row(i)
				-- validate row is visible; otherwise result negative
				if row > 0 then
					if current_picker:can_select_row(row) then
						current_picker.highlighter:hi_multiselect(row, current_picker._multi:is_selected(entry))
					end
				end
				i = i + 1
			end
		end

		local function send_selected_to_args(prompt_bufnr)
			local picker = action_state.get_current_picker(prompt_bufnr)
			local selections = picker:get_multi_selection()

			-- Если ничего не выбрано множественным выбором, берем текущий элемент
			if vim.tbl_isempty(selections) then
				selections = { action_state.get_selected_entry(prompt_bufnr) }
			end

			local file_paths = {}
			for _, selection in ipairs(selections) do
				-- Убедитесь, что у элемента есть путь (например, в live_grep может быть не путь, а строка текста)
				if selection.path then
					table.insert(file_paths, vim.fn.fnameescape(selection.path))
				end
			end

			if #file_paths > 0 then
				-- Используем команду :args {файл1} {файл2} ...
				local args_command = "args! " .. table.concat(file_paths, " ")

				vim.cmd(args_command)

			else
				print("Нет файлов для добавления в args.")
			end
		end


		-- Основная настройка Telescope
		telescope.setup({
			defaults = {
				file_previewer = require('telescope.previewers').vim_buffer_cat.new({
					preview_limit = 1024 * 1024  -- 1 МБ
				}),
				mappings = {
					i = {
						['<Esc>'] = actions.close,                           -- Закрыть по Esc
						['<C-CR>'] = send_selected_to_args,
						['<M-q>'] = actions.send_selected_to_qflist,
						['<C-a>'] = select_all,
						['<A-f>'] = actions.close,                           -- Закрыть по Alt+F (если настроено в терминале)
						['<C-j>'] = actions.move_selection_next,             -- Навигация вниз
						['<C-k>'] = actions.move_selection_previous,         -- Навигация вверх
						['<C-p>'] = actions.cycle_history_prev,              -- История поиска назад
						["<C-l>"] = function(bufnr)
							require("telescope.state").get_status(bufnr).picker.layout_config.scroll_speed = 1
							return require("telescope.actions").preview_scrolling_down(bufnr)
						end,
						["<C-h>"] = function(bufnr)
							require("telescope.state").get_status(bufnr).picker.layout_config.scroll_speed = 1
							return require("telescope.actions").preview_scrolling_up(bufnr)
						end,
					},
				},
				sorting_strategy = 'ascending',                          -- Сортировка сверху
				file_ignore_patterns = {
					"vendor/*",      -- Игнор всей папки vendor
					"node_modules/*", 
					-- "storage/*",
					-- "bootstrap/*",
					-- "public/*",
					-- "docker/*",
					".git/*",
				},
			},
			pickers = {
				find_files = {
					hidden = true,                                         -- Показывать скрытые файлы
					no_ignore = true,                                    -- Учитывать .gitignore
				},
			},
		})

		-- Глобальные маппинги
		vim.keymap.set('n', '<C-f>', builtin.find_files, { desc = '[F]ind [F]iles' })
		-- Редко используемые
		vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
		vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = '[F]ind [K]eymaps' })
		vim.keymap.set('n', '<leader>ff', builtin.live_grep, { desc = '[F]ind in [F]iles' })

		vim.keymap.set('n', '<leader>fc', builtin.command_history, { desc = '[F]ind [C]ommand history' })

		-- Автокоманда для Telescope (опционально)
		vim.api.nvim_create_autocmd('FileType', {
			pattern = 'TelescopeResults',
			callback = function()
				vim.opt.cursorline = true                               -- Подсветка текущей строки
			end,
		})


		vim.keymap.set("n", "<leader>fb", function()  
			builtin.buffers({  
				sort_mru = true,      -- Сначала последние использованные  
				ignore_current = true, -- Показывать текущий буфер  
				previewer = true,      -- Превью содержимого  
				layout_strategy = "horizontal", -- Или "horizontal"  
			})  
		end, { desc = "[F]ind [B]uffers (Telescope)" })  

		vim.api.nvim_set_keymap('n', '<leader>f/', ':Telescope current_buffer_fuzzy_find<CR>', { noremap = true , desc = "[F]ind [/] this"})
		vim.api.nvim_set_keymap('n', '<leader>ft', ':Telescope treesitter<CR>', { noremap = true , desc = "[F]ind [T]reesitter"})
		vim.api.nvim_set_keymap('n', '<leader>fls', ':Telescope lsp_document_symbols<CR>', { noremap = true , desc = "[F]ind [L]sp [S]ymbols"})



		vim.api.nvim_set_keymap('n', '<leader>gb', ':Telescope git_branches<CR>', { noremap = true , desc = "Git Branches"})

		local custom_actions = require("getRelativePath")
		vim.keymap.set("i", "<C-f>", function()
			require("telescope.builtin").find_files({
				attach_mappings = function(_, map)
					-- Настройка маппингов только для этого вызова
					map("i", "<CR>", custom_actions.insert_relative_path)
					map("n", "<CR>", custom_actions.insert_relative_path)
					return true
				end
			})
		end, {desc = "Вставить относительный путь файла"})

		
		vim.api.nvim_set_keymap('n', '<leader>fe', '' , { noremap = true , desc = "LSP Diagnostics"})

		vim.keymap.set('n', '<leader>few', function()
			require('telescope.builtin').diagnostics({ severity = "warn" })
		end, { desc = 'LSP Warnings Only' })

		vim.keymap.set('n', '<leader>fee', function()
			require('telescope.builtin').diagnostics({ severity = "error" })
		end, { desc = 'LSP Errors Only' })

		vim.keymap.set('n', '<leader>feh', function()
			require('telescope.builtin').diagnostics({ severity = "hint" })
		end, { desc = 'LSP Hints Only' })



	end)
end

