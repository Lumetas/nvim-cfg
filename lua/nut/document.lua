local M = {}

function M:new(nut)
  local document = {}
  setmetatable(document, { __index = M })
  
  document._nut = nut
  return document
end

function M:createElement(elementType, options)
  options = options or {}
  
  if elementType == "window" then
    return self:createWindow(options)
  elseif elementType == "button" then
    return self:createButton(options)
  elseif elementType == "input" then
    return self:createInput(options)
  elseif elementType == "p" then
    return self:createParagraph(options)
  elseif elementType == "container" then
    return self:createContainer(options)
  else
    error("Unsupported element type: " .. elementType)
  end
end

function M:createWindow(options)
  local window = {
    _type = "window",
    _buf = nil,
    _win = nil,
    _options = options,
    _elements = {},
    _eventHandlers = {},
    _visible = true,
    _elementLines = {} -- Маппинг строк к элементам
  }
  
  function window:show()
    if self._win and vim.api.nvim_win_is_valid(self._win) then
      vim.api.nvim_win_set_config(self._win, {})
      return self
    end
    
    self._buf = vim.api.nvim_create_buf(false, true)
    
    local win_opts = {
      style = "minimal",
      border = options.border or "single",
      title = options.title or "NUT Window",
      title_pos = "center"
    }
    
    -- Определяем тип окна и настраиваем соответствующим образом
    if options.windowType == "split" then
      local direction = options.direction or "vertical"
      local size = options.size or 20
      
      if direction == "vertical" then
        win_opts.vertical = true
      elseif direction == "horizontal" then
        win_opts.vertical = false
      end
      
      win_opts.split = options.position or "right"
      win_opts.size = size
      
      self._win = vim.api.nvim_open_win(self._buf, true, win_opts)
    elseif options.windowType == "popup" then
      local position = options.position or "top-right"
      local row, col = self:_calculatePopupPosition(position, options.width or 40, options.height or 10)
      
      win_opts.relative = "editor"
      win_opts.width = options.width or 40
      win_opts.height = options.height or 10
      win_opts.col = col
      win_opts.row = row
      win_opts.zindex = options.zindex or 50
      
      self._win = vim.api.nvim_open_win(self._buf, true, win_opts)
      
      -- Автоматическое закрытие для popup
      if options.autoClose then
        local closeTime = options.closeTime or 3000
        vim.defer_fn(function()
          if self._win and vim.api.nvim_win_is_valid(self._win) then
            self:close()
          end
        end, closeTime)
      end
    else -- float (по умолчанию)
      local editor_width = vim.api.nvim_get_option("columns")
      local editor_height = vim.api.nvim_get_option("lines")
      
      win_opts.relative = "editor"
      win_opts.width = options.width or math.min(80, editor_width - 10)
      win_opts.height = options.height or math.min(20, editor_height - 10)
      win_opts.col = math.max(0, math.floor((editor_width - win_opts.width) / 2))
      win_opts.row = math.max(0, math.floor((editor_height - win_opts.height - 5) / 2))
      
      self._win = vim.api.nvim_open_win(self._buf, true, win_opts)
    end
    
    -- Настраиваем маппинги для интерактивности
    self:_setupKeymaps()
    
    -- Рендерим элементы если они уже добавлены
    if #self._elements > 0 then
      self:_renderElements()
    end
    
    return self
  end
  
  function window:_calculatePopupPosition(position, width, height)
    local editor_width = vim.api.nvim_get_option("columns")
    local editor_height = vim.api.nvim_get_option("lines")
    
    local row, col = 1, 1
    
    if position == "top-left" then
      row, col = 1, 1
    elseif position == "top-right" then
      row, col = 1, editor_width - width - 1
    elseif position == "bottom-left" then
      row, col = editor_height - height - 5, 1
    elseif position == "bottom-right" then
      row, col = editor_height - height - 5, editor_width - width - 1
    elseif position == "top-center" then
      row, col = 1, math.floor((editor_width - width) / 2)
    elseif position == "bottom-center" then
      row, col = editor_height - height - 5, math.floor((editor_width - width) / 2)
    end
    
    return row, col
  end
  
  function window:_setupKeymaps()
    if not self._buf or not vim.api.nvim_buf_is_valid(self._buf) then return end
    
    vim.api.nvim_buf_set_keymap(self._buf, 'n', '<CR>', '', {
      callback = function()
        self:_handleEnter()
      end
    })
    
    vim.api.nvim_buf_set_keymap(self._buf, 'n', 'i', '', {
      callback = function()
        self:_handleInputMode()
      end
    })
    
    vim.api.nvim_buf_set_keymap(self._buf, 'n', 'q', '', {
      callback = function()
        self:close()
      end
    })
  end
  
  function window:_handleEnter()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local element = self:_getElementAtLine(line)
    
    if element and element._type == "button" then
      self:_triggerEvent(element, "click")
    elseif element and element._type == "input" then
      self:_startInput(element)
    end
  end
  
  function window:_handleInputMode()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local element = self:_getElementAtLine(line)
    
    if element and element._type == "input" then
      self:_startInput(element)
    end
  end
  
  function window:_startInput(inputElement)
    if not self._buf or not vim.api.nvim_buf_is_valid(self._buf) then return end
    
    vim.api.nvim_buf_set_option(self._buf, 'modifiable', true)
    
    -- Сохраняем текущую позицию курсора
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    
    -- Переходим в режим вставки
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("A", true, false, true),
      'n', false
    )
    
    -- Устанавливаем autocmd для выхода из режима вставки
    vim.api.nvim_create_autocmd("InsertLeave", {
      buffer = self._buf,
      once = true,
      callback = function()
        vim.schedule(function()
          vim.api.nvim_buf_set_option(self._buf, 'modifiable', false)
          
          -- Получаем введенный текст
          local lines = vim.api.nvim_buf_get_lines(self._buf, inputElement._displayLine - 1, inputElement._displayLine, false)
          if lines[1] then
            local text = lines[1]:gsub("^" .. inputElement._label .. "%s*:?%s*", "")
            inputElement._value = text
            self:_triggerEvent(inputElement, "change", text)
          end
          
          -- Восстанавливаем позицию курсор
          vim.api.nvim_win_set_cursor(0, {current_line, 0})
        end)
      end
    })
  end
  
  function window:_getElementAtLine(line)
    return self._elementLines[line]
  end
  
  function window:_triggerEvent(element, event, ...)
    if element._eventHandlers and element._eventHandlers[event] then
      for _, handler in ipairs(element._eventHandlers[event]) do
        handler(element, ...)
      end
    end
  end

  function window:_renderElements()
    if not self._buf or not vim.api.nvim_buf_is_valid(self._buf) then return end
    
    -- Сбрасываем маппинг
    self._elementLines = {}
    
    -- Собираем все строки и маппинг
    local allLines = {}
    local currentLine = 1
    
    local function processElement(element, startLine)
      if not element._visible then return startLine end
      
      local elementLines = {}
      
      if element._type == "button" then
        table.insert(elementLines, "[ " .. element._text .. " ]")
      elseif element._type == "input" then
        table.insert(elementLines, element._label .. ": " .. (element._value or ""))
      elseif element._type == "p" then
        table.insert(elementLines, element._text or "")
      elseif element._type == "container" then
        -- Рекурсивно обрабатываем контейнер
        local containerResult = element:_renderContainer()
        elementLines = containerResult.lines
        -- Сохраняем маппинг из контейнера
        for lineNum, childElement in pairs(containerResult.elementLines) do
          self._elementLines[startLine + lineNum - 1] = childElement
          childElement._displayLine = startLine + lineNum - 1
        end
      end
      
      -- Сохраняем маппинг для самого элемента
      for i = 1, #elementLines do
        self._elementLines[startLine + i - 1] = element
        element._displayLine = startLine + i - 1
      end
      
      -- Добавляем строки
      for _, line in ipairs(elementLines) do
        table.insert(allLines, line)
      end
      
      return startLine + #elementLines
    end
    
    -- Обрабатываем все элементы окна
    for _, element in ipairs(self._elements) do
      currentLine = processElement(element, currentLine)
    end
    
    -- Центрирование элементов
    if self._options.center then
      allLines = self:_centerElements(allLines)
    end
    
    -- Обновляем буфер
    vim.api.nvim_buf_set_option(self._buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self._buf, 0, -1, false, allLines)
    vim.api.nvim_buf_set_option(self._buf, 'modifiable', false)
  end
  
  function window:_centerElements(lines)
    local centered_lines = {}
    local max_width = 0
    
    -- Находим максимальную ширину
    for _, line in ipairs(lines) do
      max_width = math.max(max_width, #line)
    end
    
    -- Центрируем каждую строку
    for _, line in ipairs(lines) do
      local padding = math.floor((max_width - #line) / 2)
      local centered_line = string.rep(" ", padding) .. line .. string.rep(" ", padding)
      table.insert(centered_lines, centered_line)
    end
    
    return centered_lines
  end
  
  function window:addElement(element)
    table.insert(self._elements, element)
    element._window = self
    
    -- Рендерим элементы только если окно уже показано
    if self._buf and vim.api.nvim_buf_is_valid(self._buf) then
      self:_renderElements()
    end
    
    return element
  end
  
  function window:removeElement(element)
    for i, el in ipairs(self._elements) do
      if el == element then
        table.remove(self._elements, i)
        if self._buf and vim.api.nvim_buf_is_valid(self._buf) then
          self:_renderElements()
        end
        return true
      end
    end
    return false
  end
  
  function window:close()
    if self._win and vim.api.nvim_win_is_valid(self._win) then
      vim.api.nvim_win_close(self._win, true)
    end
    if self._buf and vim.api.nvim_buf_is_valid(self._buf) then
      vim.api.nvim_buf_delete(self._buf, { force = true })
    end
  end
  
  return window
end

function M:createButton(options)
  local button = {
    _type = "button",
    _text = options.text or "Button",
    _eventHandlers = {},
    _visible = true
  }
  
  function button:on(event, callback)
    if not self._eventHandlers[event] then
      self._eventHandlers[event] = {}
    end
    table.insert(self._eventHandlers[event], callback)
    return self
  end
  
  function button:setText(text)
    self._text = text
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function button:remove()
    if self._window then
      return self._window:removeElement(self)
    end
    return false
  end
  
  function button:show()
    self._visible = true
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function button:hide()
    self._visible = false
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  return button
end

function M:createInput(options)
  local input = {
    _type = "input",
    _label = options.label or "Input",
    _value = options.value or "",
    _placeholder = options.placeholder or "",
    _eventHandlers = {},
    _visible = true
  }
  
  function input:on(event, callback)
    if not self._eventHandlers[event] then
      self._eventHandlers[event] = {}
    end
    table.insert(self._eventHandlers[event], callback)
    return self
  end
  
  function input:getValue()
    return self._value
  end
  
  function input:setValue(value)
    self._value = value
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function input:setLabel(label)
    self._label = label
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function input:remove()
    if self._window then
      return self._window:removeElement(self)
    end
    return false
  end
  
  function input:show()
    self._visible = true
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function input:hide()
    self._visible = false
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  return input
end

function M:createParagraph(options)
  local p = {
    _type = "p",
    _text = options.text or "",
    _eventHandlers = {},
    _visible = true
  }
  
  function p:on(event, callback)
    if not self._eventHandlers[event] then
      self._eventHandlers[event] = {}
    end
    table.insert(self._eventHandlers[event], callback)
    return self
  end
  
  function p:setText(text)
    self._text = text
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function p:getText()
    return self._text
  end
  
  function p:remove()
    if self._window then
      return self._window:removeElement(self)
    end
    return false
  end
  
  function p:show()
    self._visible = true
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function p:hide()
    self._visible = false
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  return p
end

function M:createContainer(options)
  local container = {
    _type = "container",
    _direction = options.direction or "rows",
    _children = {},
    _eventHandlers = {},
    _visible = true
  }
  
  function container:addElement(element)
    table.insert(self._children, element)
    element._parent = self
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return element
  end
  
  function container:removeElement(element)
    for i, child in ipairs(self._children) do
      if child == element then
        table.remove(self._children, i)
        if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
          self._window:_renderElements()
        end
        return true
      end
    end
    return false
  end

  function container:_renderContainer()
    local lines = {}
    local elementLines = {}
    local currentLine = 1
    
    local function renderChild(child, startLine)
      if not child._visible then return startLine end
      
      local childLines = {}
      
      if child._type == "button" then
        table.insert(childLines, "[ " .. child._text .. " ]")
      elseif child._type == "input" then
        table.insert(childLines, child._label .. ": " .. (child._value or ""))
      elseif child._type == "p" then
        table.insert(childLines, child._text or "")
      elseif child._type == "container" then
        -- Рекурсивно рендерим вложенный контейнер
        local nestedResult = child:_renderContainer()
        childLines = nestedResult.lines
        -- Сохраняем маппинг из вложенного контейнера
        for nestedLineNum, nestedElement in pairs(nestedResult.elementLines) do
          elementLines[startLine + nestedLineNum - 1] = nestedElement
        end
      end
      
      -- Сохраняем маппинг для дочернего элемента
      for i = 1, #childLines do
        elementLines[startLine + i - 1] = child
      end
      
      -- Добавляем строки
      for _, line in ipairs(childLines) do
        table.insert(lines, line)
      end
      
      return startLine + #childLines
    end
    
    if self._direction == "rows" then
      -- Вертикальное расположение
      for _, child in ipairs(self._children) do
        currentLine = renderChild(child, currentLine)
      end
    elseif self._direction == "columns" then
      -- Горизонтальное расположение
      local columnLines = {}
      local maxChildLines = 0
      
      -- Сначала собираем все строки для каждого ребенка
      for _, child in ipairs(self._children) do
        if child._visible then
          local childLines = {}
          
          if child._type == "button" then
            table.insert(childLines, "[ " .. child._text .. " ]")
          elseif child._type == "input" then
            table.insert(childLines, child._label .. ": " .. (child._value or ""))
          elseif child._type == "p" then
            table.insert(childLines, child._text or "")
          elseif child._type == "container" then
            local nestedResult = child:_renderContainer()
            childLines = nestedResult.lines
          end
          
          table.insert(columnLines, {
            element = child,
            lines = childLines
          })
          maxChildLines = math.max(maxChildLines, #childLines)
        end
      end
      
      -- Формируем горизонтальные строки
      for lineNum = 1, maxChildLines do
        local lineParts = {}
        
        for colIndex, column in ipairs(columnLines) do
          local content = column.lines[lineNum] or ""
          table.insert(lineParts, content)
          
          -- Сохраняем маппинг для этой строки
          if column.lines[lineNum] then
            elementLines[#lines + 1] = column.element
          end
        end
        
        if #lineParts > 0 then
          table.insert(lines, table.concat(lineParts, "  "))
        end
      end
    end
    
    return {
      lines = lines,
      elementLines = elementLines
    }
  end
  
  function container:on(event, callback)
    if not self._eventHandlers[event] then
      self._eventHandlers[event] = {}
    end
    table.insert(self._eventHandlers[event], callback)
    return self
  end
  
  function container:remove()
    if self._window then
      return self._window:removeElement(self)
    end
    return false
  end
  
  function container:show()
    self._visible = true
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  function container:hide()
    self._visible = false
    if self._window and self._window._buf and vim.api.nvim_buf_is_valid(self._window._buf) then
      self._window:_renderElements()
    end
    return self
  end
  
  return container
end

return M
