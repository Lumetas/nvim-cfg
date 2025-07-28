local lexecute = {}

local function escape_pattern(text)
    return text:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

local function has_prefix_or_suffix(text, prefix, suffix)
    if prefix then
        local escaped_prefix = escape_pattern(prefix)
        if not text:find("^%s*" .. escaped_prefix) then
            text = prefix .. text
        end
    end
    
    if suffix then
        local escaped_suffix = escape_pattern(suffix)
        if not text:find(escaped_suffix .. "%s*$") then
            text = text .. suffix
        end
    end
    
    return text
end

local function execute_code(mode_config, selected_text)
    local command = mode_config.command
    local run_mode = mode_config.run or "stdin"
    local prefix = mode_config.prefix
    local suffix = mode_config.postfix
    
    local processed_text = has_prefix_or_suffix(selected_text, prefix, suffix)
    
    if run_mode == "stdin" then
        local handle = io.popen(command .. " 2>/dev/null", "w")
        handle:write(processed_text)
        local output = handle:read("*a")
        handle:close()
    elseif run_mode == "tmpfile" then
        local temp_file = os.tmpname()
        local file = io.open(temp_file, "w")
        file:write(processed_text)
        file:close()
        
        local handle = io.popen(command .. " " .. temp_file .. " 2>/dev/null")
        local output = handle:read("*a")
        handle:close()
        os.remove(temp_file)
    end
end

local function get_visual_selection()
    local saved_reg = vim.fn.getreg('"')
    local saved_regtype = vim.fn.getregtype('"')
    vim.cmd('silent normal! y')
    local text = vim.fn.getreg('"')
    vim.fn.setreg('"', saved_reg, saved_regtype)
    return text
end

function lexecute.setup(user_config)
    for key, config in pairs(user_config) do
        if type(config) == "string" and config == "neovim" then
            vim.api.nvim_set_keymap('v', key, ':lua<CR>', { noremap = true, silent = true })
        elseif type(config) == "table" then
            vim.keymap.set('v', key, function()
                local selected_text = get_visual_selection()
                execute_code(config, selected_text)
            end, { noremap = true, silent = true })
        end
    end
end

return lexecute
