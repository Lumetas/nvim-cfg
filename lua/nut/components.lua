local M = {}

function M:new(nut) 
	local document = nut.document

	local components = {}

	function components:createProgressbar(currentValue, maxValue, symbol)
		local document = nut.document

		-- Параметры по умолчанию
		currentValue = currentValue or 0
		maxValue = maxValue or 100
		symbol = symbol or "#"

		local value = currentValue
		local max = maxValue
		local progressChar = symbol

		-- Создаем текстовый элемент для отображения прогресса
		local progressElement = document:createElement("p", {text = ""})

		-- Функция обновления отображения
		local function updateDisplay()
			local percentage = math.min(math.max(value / max, 0), 1)  -- Ограничиваем от 0 до 1
			local filledBlocks = math.floor(percentage * 10)  -- 10 блоков для прогресса
			local emptyBlocks = 10 - filledBlocks

			local progressBar = "[" .. string.rep(progressChar, filledBlocks) 
			.. string.rep("-", emptyBlocks) .. "] "
			.. math.floor(percentage * 100) .. "%"

			progressElement:setText(progressBar)
		end

		-- Инициализируем отображение
		updateDisplay()

		-- Функции для управления прогрессом

		-- Установить абсолютное значение
		local function setValue(newValue)
			value = math.min(math.max(newValue, 0), max)
			updateDisplay()
			return value
		end

		-- Увеличить значение
		local function add()
			return setValue(value + 1)
		end

		local function addCustom(amount)
			return setValue(value + amount)
		end

		-- Уменьшить значение
		local function subtract(amount)
			amount = amount or 1
			return setValue(value - amount)
		end

		-- Получить текущее значение
		local function getValue()
			return value
		end

		-- Получить процент выполнения
		local function getPercentage()
			return math.floor((value / max) * 100)
		end

		-- Установить максимальное значение
		local function setMax(newMax)
			max = newMax > 0 and newMax or 100
			value = math.min(value, max)  -- Корректируем текущее значение если нужно
			updateDisplay()
			return max
		end

		-- Установить символ прогресса
		local function setSymbol(newSymbol)
			progressChar = newSymbol or "#"
			updateDisplay()
			return progressChar
		end

		-- Сбросить в 0
		local function reset()
			return setValue(0)
		end

		-- Заполнить полностью
		local function complete()
			return setValue(max)
		end

		local function mount(window)
			window:addElement(progressElement)
			return window
		end

		return {
			element = progressElement,
			setValue = setValue,
			add = add,
			subtract = subtract,
			getValue = getValue,
			getPercentage = getPercentage,
			setMax = setMax,
			setSymbol = setSymbol,
			reset = reset,
			complete = complete,
			mount = mount,
			addCustom = addCustom
		}
	end

	function components:createCheckbox(label, initialState)
		local document = nut.document
		local checked = initialState or false

		local checkbox = document:createElement("button", {
			text = checked and "☑ " .. label or "☐ " .. label
		})

		local function setChecked(value)
			checked = value
			checkbox:setText(checked and "☑ " .. label or "☐ " .. label)
			return checked
		end

		local function toggle()
			return setChecked(not checked)
		end

		local function isChecked()
			return checked
		end

		local function getLabel()
			return label
		end

		local function setLabel(newLabel)
			label = newLabel
			checkbox:setText(checked and "☑ " .. label or "☐ " .. label)
		end

		-- Обработчик клика
		checkbox:on("click", function()
			toggle()
		end)

		local function mount(window)
			window:addElement(checkbox)
			return window
		end	

		return {
			element = checkbox,
			setChecked = setChecked,
			toggle = toggle,
			isChecked = isChecked,
			getLabel = getLabel,
			setLabel = setLabel,
			mount = mount
		}
	end

	function components:createSelect(neededOptions)
		local document = nut.document

		local options = {}
		local selected = nil

		-- Создаем кнопки для всех опций
		for _, value in ipairs(neededOptions) do
			options[value] = document:createElement("button", {text = value})
		end

		-- Функция для снятия выделения со всех кнопок кроме выбранной
		local function unselectAll(exceptKey)
			for key, element in pairs(options) do
				if key == exceptKey then
					element:setText("✓ " .. key)
				else
					element:setText(key)
				end
			end
		end

		-- Назначаем обработчики кликов для всех кнопок
		for key, element in pairs(options) do
			element:on("click", function()
				if selected == key then
					-- Если кликаем на уже выбранную опцию - снимаем выделение
					element:setText(key)
					selected = nil
				else
					-- Выбираем новую опцию
					unselectAll(key)
					selected = key
				end
			end)
		end

		local function getSelected()
			return selected
		end

		local function setSelected(value)
			if options[value] then
				unselectAll(value)
				selected = value
			end
		end

		local function mountToWindow(window)
			for _, element in pairs(options) do
				window:addElement(element)
			end
			return window
		end

		local function getOptions()
			return neededOptions
		end

		return {
			getSelected = getSelected,
			setSelected = setSelected,
			getOptions = getOptions,
			mount = mountToWindow
		}
	end


function components:createMultiselect(neededOptions, initialSelected)
    local checkboxes = {}
    local selected = {}

    -- Инициализируем выбранные опции
    if initialSelected then
        for _, value in ipairs(initialSelected) do
            selected[value] = true
        end
    end

    -- Создаем чекбоксы для всех опций используя существующий компонент
    for _, value in ipairs(neededOptions) do
        local checkbox = self:createCheckbox(value, selected[value])
        checkboxes[value] = checkbox
        
        -- Сохраняем оригинальный обработчик
        local originalOnClick = checkbox.element.handlers and checkbox.element.handlers.click
        if originalOnClick then
            -- Удаляем оригинальный обработчик
            checkbox.element.handlers.click = nil
        end
        
        -- Устанавливаем новый обработчик
        checkbox.element:on("click", function()
            local newState = not selected[value]
            selected[value] = newState
            checkbox:setChecked(newState)
        end)
    end

    -- Получить все выбранные опции
    local function getSelected()
        local result = {}
        for value, isSelected in pairs(selected) do
            if isSelected then
                table.insert(result, value)
            end
        end
        return result
    end

    -- Установить выбранные опции
    local function setSelected(selectedValues)
        -- Очищаем текущее состояние
        for value in pairs(selected) do
            selected[value] = false
            if checkboxes[value] then
                checkboxes[value]:setChecked(false)
            end
        end
        
        -- Устанавливаем новые значения
        for _, value in ipairs(selectedValues) do
            if checkboxes[value] then
                selected[value] = true
                checkboxes[value]:setChecked(true)
            end
        end
    end

    -- Выбрать все опции
    local function selectAll()
        for value, checkbox in pairs(checkboxes) do
            selected[value] = true
            checkbox:setChecked(true)
        end
    end

    -- Снять выделение со всех опций
    local function clearAll()
        for value, checkbox in pairs(checkboxes) do
            selected[value] = false
            checkbox:setChecked(false)
        end
    end

    -- Проверить, выбрана ли конкретная опция
    local function isSelected(value)
        return selected[value] == true
    end

    -- Переключить конкретную опцию
    local function toggle(value)
        if checkboxes[value] then
            local newState = not selected[value]
            selected[value] = newState
            checkboxes[value]:setChecked(newState)
            return newState
        end
        return false
    end

    -- Получить количество выбранных опций
    local function getSelectedCount()
        local count = 0
        for _, isSelected in pairs(selected) do
            if isSelected then
                count = count + 1
            end
        end
        return count
    end

    -- Монтировать в окно
    local function mount(window)
        for _, checkbox in pairs(checkboxes) do
            checkbox.mount(window)  -- Используем .mount вместо :mount
        end
        return window
    end

    -- Получить все доступные опции
    local function getOptions()
        return neededOptions
    end

    return {
        getSelected = getSelected,
        setSelected = setSelected,
        selectAll = selectAll,
        clearAll = clearAll,
        isSelected = isSelected,
        toggle = toggle,
        getSelectedCount = getSelectedCount,
        mount = mount,
        getOptions = getOptions
    }
end


	return components
end



return M
