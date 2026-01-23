return function(lnpm)
  lnpm.load("lumetas/ht.nvim", function(ht)
    ht.setup({
		response = {
			auto_focus_response = false 
		}
    })
	vim.keymap.set({"n","v"},"<leader>RR", ":HT run<CR>",{desc="[R]esty [R]un request under the cursor"})
	vim.keymap.set({"n","v"},"<leader>Rr", ":HT last<CR>",{desc="[R]esty [r]un last request"})
	vim.keymap.set({"n","v"},"<leader>Rf", ":HT favorite<CR>",{desc="[R]esty [V]iew favorites"})   

  end, {
  name = "ht",
  lrule = function(next)
	  vim.keymap.set("n", "<leader>Rr", function()
		  next()
		  vim.cmd("HT last")
	  end, {desc="[R]esty [r]un last request"})

	  vim.keymap.set("n", "<leader>RF", function()
		  next()
		  vim.cmd("HT favorite")
	  end, {desc="[R]esty [V]iew favorites"})

	  vim.keymap.set("n", "<leader>RR", function()
		  next()
		  vim.cmd("HT run")
	  end, {desc="[R]esty [R]un request under the cursor"})
  end
  })
end
