return function(lnpm) 
	lnpm.load("MunifTanjim/nui.nvim")
	lnpm.load("m4xshen/hardtime.nvim", function(hard) 
		hard.setup()
	end, { name = "hardtime" })
end
