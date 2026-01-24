return function(lnpm)
  lnpm.load("lumetas/ht.nvim", function(ht)
    ht.setup({
      response = {
        auto_focus_response = false 
      }
    })
    
  end, {
  name = "ht",
  lrule = function(next)
    -- Переопределяем команду HT с ленивой загрузкой
    vim.api.nvim_create_user_command("HT", function(opts)
      next()  -- Загружаем плагин
      -- Запускаем переданную подкоманду
      vim.cmd("HT " .. (opts.args or ""))
    end, {
      desc = "HTTP client (lazy loaded)",
      nargs = "*",  -- Принимает аргументы (run, last, favorite и т.д.)
      complete = function(arg_lead)
        -- Автодополнение подкоманд после загрузки плагина
        return {"run", "last", "favorite"}
      end
    })

    vim.keymap.set({"n","v"},"<leader>RR", ":HT run<CR>",{desc="[R]esty [R]un request under the cursor"})
    vim.keymap.set({"n","v"},"<leader>Rr", ":HT last<CR>",{desc="[R]esty [r]un last request"})
    vim.keymap.set({"n","v"},"<leader>RF", ":HT favorite<CR>",{desc="[R]esty [V]iew favorites"})
    
  end
  })
end
