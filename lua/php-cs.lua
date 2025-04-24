vim.api.nvim_create_user_command('PhpCsCheck', function() 
	OpenTerminalWithCommand('php-cs-fixer check .')
end, {})

vim.api.nvim_create_user_command('PhpCsFix', function() 
	OpenTerminalWithCommand('php-cs-fixer fix .')
end, {})
