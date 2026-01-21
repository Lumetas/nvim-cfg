return function(lnpm)
  lnpm.load("mistweaverco/kulala.nvim", function(kulala)
    kulala.setup({
      global_keymaps = false,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",
    })
    
    -- Маппинги создаются только когда плагин загружен
    vim.keymap.set("n", "<leader>RR", function()
      kulala.run()
    end, { desc = "Send request" })

    vim.keymap.set("n", "<leader>Ra", function()
      kulala.run_all()
    end, { desc = "Send all requests" })

    vim.keymap.set("n", "<leader>Rb", function()
      kulala.scratchpad()
    end, { desc = "Open scratchpad" })

    vim.keymap.set("n", "<leader>Rr", function()
      kulala.replay()
    end, { desc = "Toggle UI", noremap = true })

  end, {
    name = "kulala",
	  lrule = function(next)
		  vim.defer_fn(next, 500)
	  end
  })
end
