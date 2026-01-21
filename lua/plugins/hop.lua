return function(lnpm)
	local lrule = function(next)

		vim.keymap.set('n', 's', function() 
			next()
			vim.cmd('HopWord')
		end, { desc = "Hop Word" })

		vim.keymap.set('n', 'S', function() 
			next()
			vim.cmd('HopAnywhere')
		end, { desc = "Hop Anywhere" })

		vim.keymap.set('v', 's', function() 
			next()
			vim.cmd('HopWord')
		end, { desc = "Hop Word" })

		vim.keymap.set('v', 'S', function() 
			next()
			vim.cmd('hopanywhere')
		end, { desc = "hop anywhere" })
	end
	lnpm.load('phaazon/hop.nvim', function(hop)
		hop.setup()
		vim.api.nvim_set_keymap('n', 's', ':HopWord<CR>', { noremap = true, desc = "Hop Word" })
		vim.api.nvim_set_keymap('n', 'S', ':HopAnywhere<CR>', { noremap = true, desc = "Hop Anywhere" })
		vim.keymap.set('v', 's', function () vim.cmd('HopWord') end, { noremap = true , desc = "Hop Word" })
		vim.keymap.set('v', 'S', function () vim.cmd('HopAnywhere') end, { noremap = true, desc = "Hop Anywhere" })
	end, {name = "hop", lrule = lrule})
end
