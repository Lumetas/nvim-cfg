-- local vimdir = "C:\\Users\\pokh9\\AppData\\Local\\nvim\\themes" -- vim themes directory
local vimdir = vim_dir .. '/themes'

if vim_theme[2] == "vim" then
	vim.cmd('source ' .. vim.fn.fnameescape(vimdir .. '/' .. vim_theme[1] .. '.vim'))
elseif vim_theme[2] == "nvim" then
	require(vim_theme[1]).start()
else 
	print("no theme")
end



