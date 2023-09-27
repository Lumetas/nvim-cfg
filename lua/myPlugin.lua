local nut = require("nut"):new("myPlugin")

local function animateProgress(progressBar, durationMs)
	local startTime = vim.loop.now()
	local maxValue = 1000

	local function update()
		local elapsed = vim.loop.now() - startTime
		local progress = math.min(elapsed / durationMs, 1.0) * maxValue

		progressBar.setValue(progress)

		if progress < maxValue then
			vim.defer_fn(update, 16) -- ~60 FPS
		end
	end

	update()
end

vim.keymap.set("n", "<leader>ts", function()
	local document, console, http, json, components = nut:load("document", "console", "http", "json", "components")

	local window = document:createElement("window", {
		windowType = "popup",
		position = "bottom-right",
		center = true,
		title = "select"
	}):show()

	local selectContainer = document:createElement("container", { direction = "rows" })

	local select = components:createSelect({"name", "version", "description", "author", "license"})

	select.mount(selectContainer)
	local echoBtn = document:createElement("button", {text = "echo"})

	local responseField = document:createElement("p", {text = "select and press echo"})

	local checkbox = components:createCheckbox("log?", false)


	echoBtn:on("click", function(element)
		selected = select.getSelected()
		if selected ~= nil then
			local response = http.sync:get("http://localhost:8080")
			if response.success then
				data = json:decode(response.data)
				responseField:setText(data[selected])
				if checkbox.isChecked() then
					console:log(data[selected])
				end
			end
		end
	end)





	window:addElement(selectContainer)
	window:addElement(document:createElement("p", {text = ""}))
	window:addElement(checkbox.element)
	window:addElement(echoBtn)
	window:addElement(document:createElement("p", {text = ""}))
	window:addElement(responseField)
	window:addElement(document:createElement("p", {text = ""}))

	local multi = components:createMultiselect({"Опция 1", "Опция 2", "Опция 3"}, {"Опция 1"})
	multi.mount(window)
	local btn = document:createElement("button", {text = "log"})
	btn:on("click", function()
		console:log(multi:getSelected())
	end)
	window:addElement(btn)


end)
