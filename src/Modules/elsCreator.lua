--[[
Redon Tech 2022
EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local pluginRoot = script.Parent.Parent.Parent
local elsCreator = {enabled = false, canExport = false, container = nil}

local colors = {
	[0] = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
	[1] = Color3.fromRGB(47, 71, 255),
	[2] = Color3.fromRGB(185, 58, 60),
	[3] = Color3.fromRGB(253, 194, 66),
	[4] = Color3.fromRGB(255, 255, 255),
	[5] = Color3.fromRGB(75, 255, 75),
	[6] = Color3.fromRGB(188, 12, 211),
}
local colorLabels = {
	[1] = "Blue",
	[2] = "Red",
	[3] = "Amber",
	[4] = "White",
	[5] = "Green",
	[6] = "Purple",
}
local color = 1
local mouseDown, mouse2Down, startingColumn = false, false, nil
local pause, locked = true, false
local coroutines = {}

--------------------------------------------------------------------------------
-- UI Setup --
--------------------------------------------------------------------------------

local Components = script.Parent.Parent:WaitForChild("Components")
elsCreator["topBarButton"] = require(Components:WaitForChild("topBarButton"))("elsCreator", 1, "ELS Creator", 0.104, true)
local elsCreatorComponents = Components:WaitForChild("elsCreator")
local confirmPrompt = require(Components:WaitForChild("popups"):WaitForChild("confirm"))

local controls = require(elsCreatorComponents:WaitForChild("controls"))()
local elsContainer = require(elsCreatorComponents:WaitForChild("container"))()

local pauseButton = require(elsCreatorComponents:WaitForChild("iconButton"))("Pause", 7, "rbxassetid://12758044104", "rbxassetid://12758044683")
local lockButton = require(elsCreatorComponents:WaitForChild("iconButton"))("Lock", 8, "rbxassetid://12758042236")
local resetButton = require(elsCreatorComponents:WaitForChild("iconButton"))("Reset", 9, "rbxassetid://12758045258")
pauseButton.Parent = controls
pauseButton:SetAttribute("Icon", pause)
lockButton.Parent = controls
lockButton:SetAttribute("Active", locked)
resetButton.Parent = controls

--------------------------------------------------------------------------------
-- Module Functions --
--------------------------------------------------------------------------------


-- Color Setup
local function setColor(value: number)
	color = value
	for i,v in pairs(controls:GetChildren()) do
		if v:IsA("Frame") and v:FindFirstChild("Text") then
			if v.Name == tostring(value) then
				v.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
				v.Text.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
				v:SetAttribute("Active", true) -- Not remove the background color when the button is hovered
			else
				v.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
				v.Text.TextColor3 = if v.Name == "4" then settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText) else colors[tonumber(v.Name)]
				v:SetAttribute("Active", false)
			end
		end
	end
end

for i,v in pairs(colors) do
	if i ~= 0 then
		local color = require(elsCreatorComponents:WaitForChild("textButton"))(i, i, colorLabels[i], if i == 4 then settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText) else v)
		color.Parent = controls

		color.Text.MouseButton1Click:Connect(function()
			setColor(i)
		end)
	end
end
setColor(1)

-- Reset Counters Handler
local function resetCounters()
	pause = true
	pauseButton:SetAttribute("Icon", pause)

	for i,v in pairs(elsContainer:GetChildren()) do
		if v:IsA("Frame") then
			v:SetAttribute("Count", 1)
			v.IndicatorHolder.Indicator.Position = UDim2.new(0.5, 1, 0, -3)
		end
	end
end

-- Register Row
local function registerRow(row: Frame)
	local enter = nil
	row:SetAttribute("Color", 0)

	row:GetAttributeChangedSignal("Color"):Connect(function()
		row.BackgroundColor3 = colors[row:GetAttribute("Color")]
	end)

	row.MouseEnter:Connect(function()
		if mouseDown and ((startingColumn == nil or startingColumn == tonumber(row.Parent.Name)) or locked == false) then
			row:SetAttribute("Color", color)
			if startingColumn == nil then
				startingColumn = tonumber(row.Parent.Name)
			end
		elseif mouse2Down and ((startingColumn == nil or startingColumn == tonumber(row.Parent.Name)) or locked == false) then
			row:SetAttribute("Color", 0)
			if startingColumn == nil then
				startingColumn = tonumber(row.Parent.Name)
			end
		else
			enter = elsContainer.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					row:SetAttribute("Color", color)
					if startingColumn == nil then
						startingColumn = tonumber(row.Parent.Name)
					end
				elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
					row:SetAttribute("Color", 0)
					if startingColumn == nil then
						startingColumn = tonumber(row.Parent.Name)
					end
				end
			end)
		end
	end)

	row.MouseLeave:Connect(function()
		if enter then
			enter:Disconnect()
			enter = nil
		end
	end)
end

-- Register Column
local function registerColumn(column: number, section: Frame)
	local frame = section.Columns:WaitForChild(column)
	local frameHeader = section.ColumnHeaders:WaitForChild(column)
	local rows = #frame:GetChildren() - 1

	if rows ~= section:GetAttribute("Rows") then
		if rows > section:GetAttribute("Rows") then
			for i=1, rows-section:GetAttribute("Rows") do
				frame:WaitForChild(i):Destroy()
			end
		elseif rows < section:GetAttribute("Rows") then
			for i = 1, section:GetAttribute("Rows")-rows do
				local row = require(elsCreatorComponents:WaitForChild("columnRow"))(i)
				row.Parent = frame
				registerRow(row)
			end
		end
	end

	local connection = section:GetAttributeChangedSignal("Count"):Connect(function()
		local color = frame:FindFirstChild(section:GetAttribute("Count")):GetAttribute("Color")
		frameHeader.Top.BackgroundColor3 = colors[color]
		local enabled = if color == 0 then false else true
		frameHeader.Top.Light.ImageColor3 = colors[color]
		frameHeader.Top.Light.Visible = enabled
		frameHeader.Top.Light1.ImageColor3 = colors[color]
		frameHeader.Top.Light1.Visible = enabled
		frameHeader.Top.Light2.ImageColor3 = colors[color]
		frameHeader.Top.Light2.Visible = enabled
	end)

	for i,v in pairs(frame:GetChildren()) do
		if v:IsA("Frame") then
			registerRow(v)
		end
	end

	frame.Destroying:Connect(function()
		connection:Disconnect()
	end)
end

-- Register Section
local function update(coro: table, section: number)
	local sectionFrame = elsContainer:WaitForChild(`Section{section}`)

	while task.wait(tonumber(sectionFrame.SectionControls.WaitTime.Text)) do
		if coro["run"] and pause == false and sectionFrame:GetAttribute("ConnectedTo") == nil then
			local lastCount = sectionFrame:GetAttribute("Count")
			if lastCount >= sectionFrame:GetAttribute("Rows") then
				sectionFrame:SetAttribute("Count", 1)
			else
				sectionFrame:SetAttribute("Count", lastCount+1)
			end

			sectionFrame.IndicatorHolder.Indicator.Position = UDim2.new(0.5, 1, 0, ((sectionFrame:GetAttribute("Count")-1)*20)-3)
		elseif coro["run"] == false then
			coroutines[section] = nil
			for i,v in pairs(elsContainer:GetChildren()) do
				if v:IsA("Frame") and v:GetAttribute("ConnectedTo") == section then
					v:SetAttribute("ConnectedTo", nil)
				end
			end
			break
		end
	end
end

local function registerSection(section: number)
	local sectionFrame = elsContainer:WaitForChild(`Section{section}`)
	local connections = {}
	local connectedTo = nil
	
	sectionFrame:SetAttribute("Rows", 20)
	
	-- Handle Lighting Functions
	connections[#connections+1] = sectionFrame:GetAttributeChangedSignal("ConnectedTo"):Connect(function()
		if connectedTo then connectedTo:Disconnect() connectedTo = nil end
		print(sectionFrame:GetAttribute("ConnectedTo"))

		if sectionFrame:GetAttribute("ConnectedTo") then
			connectedTo = elsContainer:WaitForChild(`Section{sectionFrame:GetAttribute("ConnectedTo")}`):GetAttributeChangedSignal("Count"):Connect(function()
				local lastCount = sectionFrame:GetAttribute("Count")
				if lastCount >= sectionFrame:GetAttribute("Rows") then
					sectionFrame:SetAttribute("Count", 1)
				else
					sectionFrame:SetAttribute("Count", lastCount+1)
				end

				sectionFrame.IndicatorHolder.Indicator.Position = UDim2.new(0.5, 1, 0, ((sectionFrame:GetAttribute("Count")-1)*20)-3)
			end)
		else
			for i,v in pairs(coroutines) do
				if v.waitTime == tonumber(sectionFrame.SectionControls.WaitTime.Text) and i ~= section then
					sectionFrame:SetAttribute("ConnectedTo", i)
					return
				end
			end
			sectionFrame:SetAttribute("ConnectedTo", nil)
		end
	end)

	connections[#connections+1] = sectionFrame.SectionControls.WaitTime.Focused:Connect(function()
		pause = true
		resetCounters()
	end)

	connections[#connections+1] = sectionFrame.SectionControls.WaitTime.FocusLost:Connect(function()
		local waitTime = tonumber(sectionFrame.SectionControls.WaitTime.Text)
		if waitTime >= 0.001 and waitTime <= 10 then
			pause = false
			resetCounters()
		elseif waitTime < 0.001 then
			sectionFrame.SectionControls.WaitTime.Text = "0.001"
			pause = false
			resetCounters()
		elseif waitTime > 10 then
			sectionFrame.SectionControls.WaitTime.Text = "10"
			pause = false
			resetCounters()
		end

		coroutines[section].waitTime = tonumber(sectionFrame.SectionControls.WaitTime.Text)

		for i,v in pairs(elsContainer:GetChildren()) do
			if v:IsA("Frame") and v:GetAttribute("ConnectedTo") == section then
				if v.SectionControls.WaitTime.Text ~= sectionFrame.SectionControls.WaitTime.Text then
					v:SetAttribute("ConnectedTo", nil)
				end
			end
		end

		for i,v in pairs(coroutines) do
			if v.waitTime == tonumber(sectionFrame.SectionControls.WaitTime.Text) and i ~= section then
				sectionFrame:SetAttribute("ConnectedTo", i)
				return
			end
		end
		sectionFrame:SetAttribute("ConnectedTo", nil)
	end)

	sectionFrame:SetAttribute("Count", 1)
	coroutines[section] = {
		run = true,
		waitTime = tonumber(sectionFrame.SectionControls.WaitTime.Text),
		coro = coroutine.create(update)
	}

	for i,v in pairs(coroutines) do
		print(v.waitTime == tonumber(sectionFrame.SectionControls.WaitTime.Text), i ~= section)
		if v.waitTime == tonumber(sectionFrame.SectionControls.WaitTime.Text) and i ~= section then
			sectionFrame:SetAttribute("ConnectedTo", i)
		end
	end
	coroutine.resume(coroutines[section].coro, coroutines[section], section)

	-- Handle Controls

	for i,v in pairs(sectionFrame.Columns:GetChildren()) do
		if v.Name ~= "Buttons" and v:IsA("Frame") then
			registerColumn(tonumber(v.Name), sectionFrame)
		end
	end
	
	if section == 1 then
		sectionFrame.SectionControls.RemoveButton.ImageTransparency = 1
	end
	
	local function addVisible()
		if section ~= #elsContainer:GetChildren() - 2 then
			sectionFrame.SectionControls.Add.Visible = false
			sectionFrame.SectionControls.RemoveButton.Visible = false
		else
			sectionFrame.SectionControls.Add.Visible = true
			sectionFrame.SectionControls.RemoveButton.Visible = true
		end
	end
	addVisible()
	connections[#connections+1] = elsContainer.ChildAdded:Connect(addVisible)
	connections[#connections+1] = elsContainer.ChildRemoved:Connect(addVisible)
	
	local function removeRowVisible()
		if sectionFrame:GetAttribute("Rows") == 1 then
			sectionFrame.Columns.Buttons.Controls.RemoveHolder.Visible = false
		else
			sectionFrame.Columns.Buttons.Controls.RemoveHolder.Visible = true
		end
	end
	removeRowVisible()
	connections[#connections+1] = sectionFrame:GetAttributeChangedSignal("Rows"):Connect(removeRowVisible)

	local function removeColumnVisible()
		if #sectionFrame.Columns:GetChildren() == 3 then
			sectionFrame.ColumnHeaders.Buttons.Controls.RemoveHolder.Visible = false
		else
			sectionFrame.ColumnHeaders.Buttons.Controls.RemoveHolder.Visible = true
		end
	end
	removeColumnVisible()
	connections[#connections+1] = sectionFrame.Columns.ChildAdded:Connect(removeColumnVisible)
	connections[#connections+1] = sectionFrame.Columns.ChildRemoved:Connect(removeColumnVisible)
	
	-- Add/Remove Row
	connections[#connections+1] = sectionFrame.Columns.Buttons.Controls.AddHolder.Add.MouseButton1Click:Connect(function()
		for i,v in pairs(sectionFrame.Columns:GetChildren()) do
			if v:IsA("Frame") and v.Name ~= "Buttons" then
				local row = require(elsCreatorComponents:WaitForChild("columnRow"))(sectionFrame:GetAttribute("Rows")+1)
				row.Parent = v
				registerRow(row)
			elseif v:IsA("Frame") and v.Name == "Buttons" then
				local row = require(elsCreatorComponents:WaitForChild("columnRow"))(sectionFrame:GetAttribute("Rows"))
				row.BackgroundTransparency = 1
				row.UICorner:Destroy()
				row.Parent = v
			end
		end
		sectionFrame:SetAttribute("Rows", sectionFrame:GetAttribute("Rows")+1)
	end)

	connections[#connections+1] = sectionFrame.Columns.Buttons.Controls.RemoveHolder.RemoveButton.MouseButton1Click:Connect(function()
		elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		confirmPrompt("Are you sure you want to remove this row? <b>Any unsaved progress will be lost!</b>", function(confirm)
			if confirm then
				if sectionFrame:GetAttribute("Rows") == 1 then return end
				for i,v in pairs(sectionFrame.Columns:GetChildren()) do
					if v:IsA("Frame") and v.Name ~= "Buttons" then
						v:WaitForChild(sectionFrame:GetAttribute("Rows")):Destroy()
						elseif v:IsA("Frame") and v.Name == "Buttons" then
							v:WaitForChild(sectionFrame:GetAttribute("Rows")-1):Destroy()
						end
					end
				end
				sectionFrame:SetAttribute("Rows", sectionFrame:GetAttribute("Rows")-1)
			elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
		end).Parent = elsCreator.container.Parent.PopUps
	end)

	-- Add/Remove Columns
	connections[#connections+1] = sectionFrame.ColumnHeaders.Buttons.Controls.AddHolder.Add.MouseButton1Click:Connect(function()
		local column = require(elsCreatorComponents:WaitForChild("column"))(#sectionFrame.Columns:GetChildren()-1, sectionFrame:GetAttribute("Rows"))
		column.Parent = sectionFrame.Columns
		local columnHeader = require(elsCreatorComponents:WaitForChild("columnHeader"))(tonumber(column.Name))
		columnHeader.Parent = sectionFrame.ColumnHeaders
		registerColumn(tonumber(column.Name), sectionFrame)
	end)

	connections[#connections+1] = sectionFrame.ColumnHeaders.Buttons.Controls.RemoveHolder.RemoveButton.MouseButton1Click:Connect(function()
		elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		confirmPrompt("Are you sure you want to remove this column? <b>Any unsaved progress will be lost!</b>", function(confirm)
			elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
			if confirm then
				if #sectionFrame.Columns:GetChildren() == 3 then return end
				sectionFrame.Columns:WaitForChild(#sectionFrame.Columns:GetChildren()-2):Destroy()
				sectionFrame.ColumnHeaders:WaitForChild(#sectionFrame.ColumnHeaders:GetChildren()-2):Destroy()
			end
		end).Parent = elsCreator.container.Parent.PopUps
	end)

	-- Add/Remove Section
	connections[#connections+1] = sectionFrame.SectionControls.Add.MouseButton1Click:Connect(function()
		resetCounters()
		require(elsCreatorComponents:WaitForChild("section"))(section+1).Parent = elsContainer
		registerSection(section+1)
	end)

	connections[#connections+1] = sectionFrame.SectionControls.RemoveButton.MouseButton1Click:Connect(function()
		if section == 1 then return end
		resetCounters()
		elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		confirmPrompt("Are you sure you want to remove this section? <b>Any unsaved progress will be lost!</b>", function(confirm)
			elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
			if confirm then
				sectionFrame:Destroy()
			end
		end).Parent = elsCreator.container.Parent.PopUps
	end)

	connections[#connections+1] = sectionFrame.Destroying:Connect(function()
		coroutines[section].run = false
		for i,v in pairs(connections) do
			v:Disconnect()
		end
	end)
end

registerSection(1)

-- Reset Handler

local function reset()
	resetCounters()
	for i,v in pairs(elsContainer:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Section1" then
			v:Destroy()
		end
	end

	for i,v in pairs(elsContainer.Section1.Columns:GetChildren()) do
		if v:IsA("Frame") and (v.Name ~= "1" and v.Name ~= "Buttons") then
			v:Destroy()
		end
	end
	for i,v in pairs(elsContainer.Section1.ColumnHeaders:GetChildren()) do
		if v:IsA("Frame") and (v.Name ~= "1" and v.Name ~= "Buttons") then
			v:Destroy()
		end
	end

	elsContainer.Section1.SectionControls.WaitTime.Text = "0.1"
	elsContainer.Section1:SetAttribute("Rows", 20)
	local rows = #elsContainer.Section1.Columns["1"]:GetChildren() - 1

	if rows ~= elsContainer.Section1:GetAttribute("Rows") then
		if rows > elsContainer.Section1:GetAttribute("Rows") then
			for i=1, rows-elsContainer.Section1:GetAttribute("Rows") do
				elsContainer.Section1.Columns["1"]:WaitForChild(i):Destroy()
			end
		elseif rows < elsContainer.Section1:GetAttribute("Rows") then
			for i = 1, elsContainer.Section1:GetAttribute("Rows")-rows do
				local row = require(elsCreatorComponents:WaitForChild("columnRow"))(i)
				row.Parent = elsContainer.Section1.Columns["1"]
				registerRow(row)
			end
		end
	end

	for i,v in pairs(elsContainer.Section1.Columns["1"]:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Buttons" then
			v:SetAttribute("Color", 0)
		end
	end
end

local function confirmReset()
	if elsCreator.container == nil then return end
	elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
	confirmPrompt("Are you sure you want to reset? \n<b>Any unsaved progress will be lost!</b>", function(confirm)
		if confirm then
			reset()
		end
		elsCreator.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
	end).Parent = elsCreator.container.Parent.PopUps
end

resetButton.Image.MouseButton1Click:Connect(function()
	confirmReset()
end)

-- Input Handler
elsCreator.InputBegan = function(input: InputObject)
	if elsCreator.enabled == false then return end

	if input.KeyCode == Enum.KeyCode.One then
		setColor(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		setColor(2)
	elseif input.KeyCode == Enum.KeyCode.Three then
		setColor(3)
	elseif input.KeyCode == Enum.KeyCode.Four then
		setColor(4)
	elseif input.KeyCode == Enum.KeyCode.Five then
		setColor(5)
	elseif input.KeyCode == Enum.KeyCode.Six then
		setColor(6)
	elseif input.KeyCode == Enum.KeyCode.R then
		confirmReset()
	elseif input.KeyCode == Enum.KeyCode.P then
		pause = not pause
		pauseButton:SetAttribute("Icon", pause)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = true
		mouse2Down = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		mouseDown = false
		mouse2Down = true
	end
end

pauseButton.Image.MouseButton1Click:Connect(function()
	pause = not pause
	pauseButton:SetAttribute("Icon", pause)
end)

lockButton.Image.MouseButton1Click:Connect(function()
	locked = not locked
	lockButton:SetAttribute("Active", locked)
end)

elsCreator.InputEnded = function(input: InputObject)
	if elsCreator.enabled == false then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = false
		mouse2Down = false
		startingColumn = nil
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseDown = false
		mouse2Down = false
		startingColumn = nil
	end
end

elsCreator.Display = function(container: Frame)
	controls.Parent = container
	elsContainer.Parent = container
	elsCreator.container = container
	elsCreator.enabled = true
end

elsCreator.StopDisplay = function()
	controls.Parent = nil
	elsContainer.Parent = nil
	elsCreator.container = nil
	elsCreator.enabled = false
end

return elsCreator