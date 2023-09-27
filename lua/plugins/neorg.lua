return function(lnpm)
	lnpm.load("nvim-neorg/neorg", function(org)
		org.setup()
	end, { name = "neorg" })
end
