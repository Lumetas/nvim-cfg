return function(lnpm)
	lnpm.load('nvim-lua/plenary.nvim')
	lnpm.load('nvim-tree/nvim-web-devicons', nil, {lrule = function(next) vim.defer_fn(next, 1000) end})
	lnpm.load('kevinhwang91/promise-async')

	-- lnpm.load('kylechui/nvim-surround', function(surround) surround.setup() end, {lrule = function (next) vim.defer_fn(next, 1000) end})

-- 	lnpm.load('nvim-treesitter/nvim-treesitter', function(ts)
-- 		ts.setup({
-- 			ensure_installed = {
-- 				'php', 'javascript', 'css', 'html', 'markdown', 
-- 				'lua', 'go', 'python', 'blade'
-- 			},
-- 			-- Опционально: автоматическая установка недостающих парсеров
-- 			auto_install = true,
--
-- 			-- Остальные настройки (пример):
-- 			highlight = {
-- 				enable = true,
-- 				additional_vim_regex_highlighting = false,
-- 			},
-- 			indent = {
-- 				enable = true,
-- 			},
-- 		})
-- 	end, {
-- 	lrule = function(next) 
-- 		vim.defer_fn(next, 100) 
-- 	end
-- })

-- lnpm.load('mattn/emmet-vim', nil, {lrule = function(next) vim.defer_fn(next, 1000) end})

-- lnpm.load('AndrewRadev/quickpeek.vim', nil)

lnpm.load('mikavilpas/yazi.nvim', function() 
	vim.api.nvim_set_keymap('n', 'zx', ':Yazi<CR>', { noremap = true })
end, {lrule = function (next) 
vim.keymap.set('n', 'zx', function() 
	next()
	vim.cmd('Yazi')
end, { noremap = true })
	end})



	lnpm.load("Skardyy/neo-img", function(img) 
	img.setup({
	  supported_extensions = {
		png = true,
		jpg = true,
		jpeg = true,
		tiff = true,
		tif = true,
		svg = true,
		webp = true,
		bmp = true,
		gif = true, -- static only
		docx = true,
		xlsx = true,
		pdf = true,
		pptx = true,
		odg = true,
		odp = true,
		ods = true,
		odt = true
	  },

	  ----- Important ones -----
	  size = "60%",  -- size of the image in percent
	  center = true, -- rather or not to center the image in the window
	  ----- Important ones -----

	  ----- Less Important -----
	  auto_open = true,   -- Automatically open images when buffer is loaded
	  oil_preview = false, -- changes oil preview of images too
	  backend = "auto",   -- auto / kitty / iterm / sixel
	  resizeMode = "Fit", -- Fit / Stretch / Crop
	  offset = "1x1",     -- that exmp is 2 cells offset x and 3 y.
	  ttyimg = "local"    -- local / global
	  ----- Less Important -----
	})
	end, {lrule = function(next) vim.defer_fn(next, 1000) end})

end
