return function(lnpm)
	lnpm.load('mfussenegger/nvim-dap', function(dap)

		lnpm.load('rcarriga/nvim-dap-ui')
		dap.adapters.php = {
			type = "executable",
			command = "node",
			args = { vim.fn.stdpath('config') .. "/xdebug/out/phpDebug.js" }
		}

		dap.configurations.php = {
			{
				type = "php",
				request = "launch",
				name = "Listen for Xdebug",
				idekey = "PHPSTORM",
				port = 9003,

				pathMappings = {
					['/var/www/widgets/controllers/google_sheets/private_tech'] = '/home/lum/LumProjects/google_sheets/widget',
					['/var/www/'] = '/home/lum/LumProjects/google_sheets/core',
				}
			}



		}

		vim.keymap.set('n', '<Leader>dc', function() require('dap').continue() end, { desc = '[D]ebug [C]onnect menu' })
		vim.keymap.set('n', '<leader>dn', function() require('dap').step_over() end, { desc = 'Debug Step Over' })
		vim.keymap.set('n', '<leader>di', function() require('dap').step_into() end, { desc = 'Debug Step Into' })
		vim.keymap.set('n', '<leader>do', function() require('dap').step_out() end, { desc = 'Debug Step Out' })
		-- vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
		-- vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
		vim.keymap.set('n', '<Leader>db', function() require('dap').toggle_breakpoint() end, { desc = '[D]ebug [B]reakpoint' })
		vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
			require('dap.ui.widgets').hover()
		end, { desc = '[D]ebug [H]over' })
		vim.keymap.set('n', '<Leader>df', function()
			local widgets = require('dap.ui.widgets')
			widgets.centered_float(widgets.frames)
		end, { desc = '[D]ebug [F]orce-tree' })
		vim.keymap.set('n', '<Leader>dv', function()
			local widgets = require('dap.ui.widgets')
			widgets.centered_float(widgets.scopes)
		end, { desc = '[D]ebug [V]alues' })
	end, {name = 'dap', lrule = function(next) vim.defer_fn(next, 5000) end})
end
