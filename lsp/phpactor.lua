return {
    cmd = { "phpactor", "language-server" },
    filetypes = { "php" },
    root_markers = { "composer.json", ".git", "phpstan.neon", "lstart.conf", ".lumproject" },
    settings = {
        -- Включаем все возможные подсказки (Inlay Hints)
        ["phpactor.lsp.inlay_hints.enable"] = true,
        ["phpactor.lsp.inlay_hints.parameter_names"] = true,
        ["phpactor.lsp.inlay_hints.types"] = true,
        
        -- Мощная диагностика и анализ
        ["phpactor.language_server_php_code_explorer.enabled"] = true,
        ["phpactor.language_server_diagnostics.enabled"] = true,
        ["phpactor.composer.autoloader_path"] = "vendor/autoload.php",
        
        -- Рефакторинг и трансформация кода
        ["phpactor.code_transform.indentation_size"] = 4,
        ["phpactor.code_transform.indentation_max_column_length"] = 120,
        
        -- Индексация (чтобы видел всё в проекте)
        ["phpactor.indexer.enabled"] = true,
        ["phpactor.indexer.include_patterns"] = { "src/**/*.php", "vendor/**/*.php", "lib/**/*.php", "tests/**/*.php" },
        ["phpactor.indexer.exclude_patterns"] = { "/cache/", "/zf2/" },
        
        -- Показ статуса (будешь видеть внизу, когда он индексирует или тупит)
        ["phpactor.language_server_configuration.show_status"] = true,
    },
    on_attach = function(client, bufnr)
        -- Принудительный старт инлайнов
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

        -- Маппинг для рефакторинга (Phpactor в этом бог)
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "<leader>re", ":PhpactorContextMenu<CR>", opts) -- Меню рефакторинга
        vim.keymap.set("n", "<leader>ri", ":PhpactorImportClass<CR>", opts)  -- Быстрый импорт use

    end,
}
