return function(lnpm)
	lnpm.load('tpope/vim-fugitive', function()
		vim.api.nvim_set_keymap('n', '<Leader>ga', ':G add .<CR>', { noremap = true, desc = 'Git add'})
		vim.api.nvim_set_keymap('n', '<Leader>gc', ':G commit<CR>', { noremap = true, desc = 'Git commit'})
		vim.api.nvim_set_keymap('n', '<Leader>gp', ':G pull<CR>', { noremap = true, desc = 'Git pull'})
		vim.api.nvim_set_keymap('n', '<Leader>gP', ':G push<CR>', { noremap = true, desc = 'Git push'})
		vim.api.nvim_set_keymap('n', '<Leader>gl', ':Gllog<CR>', { noremap = true, desc = 'Git log'})
		vim.api.nvim_set_keymap('n', '<Leader>gs', ':G status<CR>', { noremap = true, desc = 'Git status'})
		vim.api.nvim_set_keymap('n', '<Leader>gac', ':G add . | G commit<CR>', { noremap = true, desc = 'and commit'})
		vim.api.nvim_set_keymap('n', '<Leader>gg', ':G ', { noremap = true, desc = 'Git custom'})


		vim.api.nvim_set_keymap('n', '<Leader>gC', '', { noremap = true, desc = 'Git config'})



		vim.api.nvim_set_keymap('n', '<Leader>gCem', ':G config user.email lumetas506@gmail.com | echo "set main email"<CR>', { noremap = true, desc = 'Set main email'})
		vim.api.nvim_set_keymap('n', '<Leader>gCew', ':G config user.email p.teplyakov@emfy.com | echo "set work email"<CR>', { noremap = true, desc = 'Set work email'})
		vim.api.nvim_set_keymap('n', '<Leader>gCe', ':G config user.email<CR>', { noremap = true, desc = 'Email'})




		vim.api.nvim_set_keymap('n', '<Leader>gCnm', ':G config user.name Lumetas | echo "set main name"<CR>', { noremap = true, desc = 'Set main name'})
		vim.api.nvim_set_keymap('n', '<Leader>gCnw', ':G config user.name Pavel | echo "set work name"<CR>', { noremap = true, desc = 'Set work name'})
		vim.api.nvim_set_keymap('n', '<Leader>gCn', ':G config user.name<CR>', { noremap = true, desc = 'Name'})




		vim.api.nvim_set_keymap('n', '<Leader>ge', '', { noremap = true, desc = 'Git edit'})
		vim.keymap.set('n', '<leader>gel', function()
			-- Получаем ID последнего коммита
			local cid = vim.fn.system('git log -1 --pretty=format:"%H"')
			-- Убираем перенос строки
			cid = cid:gsub('\n', '')

			if cid and cid ~= '' then
				-- Выполняем команду Gedit
				vim.cmd('Gedit ' .. cid .. ':%')
			else
				vim.notify('Не удалось получить ID последнего коммита', vim.log.levels.ERROR)
			end
		end, { desc = 'Last Commit' })




		vim.keymap.set('n', '<leader>ges', function()
			-- Получаем список коммитов
			local commits = vim.fn.systemlist('git log --oneline -20')  -- последние 20 коммитов

			-- Создаем picker для Telescope
			local pickers = require('telescope.pickers')
			local finders = require('telescope.finders')
			local conf = require('telescope.config').values
			local actions = require('telescope.actions')
			local action_state = require('telescope.actions.state')

			pickers.new({}, {
				prompt_title = 'Выбери коммит для Gedit',
				finder = finders.new_table({
					results = commits,
					entry_maker = function(entry)
						return {
							value = entry:match('^(%x+)'),  -- хэш коммита
							display = entry,
							ordinal = entry,
						}
					end
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						if selection then
							vim.cmd('Gedit ' .. selection.value .. ':%')
						end
					end)
					return true
				end,
			}):find()
		end, { desc = 'Select commit for Gedit' })
	end)
end
