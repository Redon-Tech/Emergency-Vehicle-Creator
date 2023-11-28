--[[
Redon Tech 2023
EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local pluginRoot = script.Parent.Parent.Parent
local faders = {enabled = false, canExport = true, container = nil}

local colors = {
	[0] = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
	[1] = Color3.fromRGB(47, 71, 255),
	[2] = Color3.fromRGB(185, 58, 60),
	[3] = Color3.fromRGB(253, 194, 66),
	[4] = Color3.fromRGB(255, 255, 255),
	[5] = Color3.fromRGB(75, 255, 75),
	[6] = Color3.fromRGB(188, 12, 211),
}
local colorDropdown = {
	[0] = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText),
	[1] = Color3.fromRGB(47, 71, 255),
	[2] = Color3.fromRGB(185, 58, 60),
	[3] = Color3.fromRGB(253, 194, 66),
	[4] = Color3.fromRGB(255, 255, 255),
	[5] = Color3.fromRGB(75, 255, 75),
	[6] = Color3.fromRGB(188, 12, 211),
}
local colorLabels = {
	[0] = "None",
	[1] = "Blue",
	[2] = "Red",
	[3] = "Amber",
	[4] = "White",
	[5] = "Green",
	[6] = "Purple",
}
local pause, pauseLocked = true, false
local tweenPreviews, tweenPreviewCompletedConnections, coroutines = {}, {}, {}

--------------------------------------------------------------------------------
-- UI Setup --
--------------------------------------------------------------------------------

local Components = script.Parent.Parent:WaitForChild("Components")
faders["topBarButton"] = require(Components:WaitForChild("topBarButton"))("faders", 1, "Faders", 0.104, true)
local faderComponents = Components:WaitForChild("faders")
local reusedContent = Components:WaitForChild("reusedContent")
local confirmPrompt = require(Components:WaitForChild("popups"):WaitForChild("confirm"))

local controls = require(reusedContent:WaitForChild("controls"))()
local faderContainer = require(faderComponents:WaitForChild("container"))(colorDropdown, colorLabels)

local pauseButton = require(reusedContent:WaitForChild("iconButton"))("Pause", 7, "rbxassetid://12758044104", "rbxassetid://12758044683")
local resetButton = require(reusedContent:WaitForChild("iconButton"))("Reset", 9, "rbxassetid://12758045258")
pauseButton.Parent = controls
pauseButton:SetAttribute("Icon", pause)
resetButton.Parent = controls

--------------------------------------------------------------------------------
-- Module Functions --
--------------------------------------------------------------------------------

local function setPause(value: boolean)
	pause = value
	pauseButton:SetAttribute("Icon", pause)

	for i,v in pairs(faderContainer:GetChildren()) do
		if v:IsA("ScrollingFrame") then
			v.Options.TopOptions.NameBox.TextBox.Visible = pause
		end
	end

	if pause then
		for i,v in pairs(tweenPreviews) do
			v:Pause()
		end
	else
		for i,v in pairs(tweenPreviews) do
			v:Play()
		end
	end
end

-- Register Tween
local function registerTween(sectionFrame: Frame, tween: number)
	local tweenFrame = sectionFrame.Options:FindFirstChild(`Tween{tween}`)
	local connections = {}
	local didSetPause = false

	local function pauseFocus()
		didSetPause = if pause == false then true else false
		setPause(true)
		pauseLocked = true
	end

	local function pauseFocusLost()
		pauseLocked = false
		if didSetPause then
			setPause(false)
			didSetPause = false
		end
	end

	connections[#connections+1] = tweenFrame.DelayTime.TextBox.Focused:Connect(pauseFocus)
	connections[#connections+1] = tweenFrame.RepeatCount.TextBox.Focused:Connect(pauseFocus)
	connections[#connections+1] = tweenFrame.Time.TextBox.Focused:Connect(pauseFocus)
	connections[#connections+1] = tweenFrame.TransparencyGoal.TextBox.Focused:Connect(pauseFocus)
	connections[#connections+1] = tweenFrame.DelayTime.TextBox.FocusLost:Connect(pauseFocusLost)
	connections[#connections+1] = tweenFrame.RepeatCount.TextBox.FocusLost:Connect(pauseFocusLost)
	connections[#connections+1] = tweenFrame.Time.TextBox.FocusLost:Connect(pauseFocusLost)
	connections[#connections+1] = tweenFrame.TransparencyGoal.TextBox.FocusLost:Connect(function(enterPressed)
		pauseFocusLost()

		if enterPressed and (tweenFrame.Time.TextBox.Text == nil or tweenFrame.Time.TextBox.Text == "") then
			tweenFrame.Time.TextBox:CaptureFocus()
			RunService.Heartbeat:Wait()
			tweenFrame.Time.TextBox.Text = ""
		end
	end)

	tweenFrame.Reverses:SetAttribute("Checked", false)
	connections[#connections+1] = tweenFrame.Reverses:GetAttributeChangedSignal("Checked"):Connect(function()
		tweenFrame.Reverses.Checkbox.Checkmark.Visible = tweenFrame.Reverses:GetAttribute("Checked")
	end)

	connections[#connections+1] = tweenFrame.Reverses.Checkbox.Button.MouseButton1Click:Connect(function()
		tweenFrame.Reverses:SetAttribute("Checked", not tweenFrame.Reverses:GetAttribute("Checked"))
	end)

	tweenFrame.Color:SetAttribute("Color", 0)
	tweenFrame.EasingStyle:SetAttribute("EasingStyle", "Linear")
	tweenFrame.EasingDirection:SetAttribute("EasingDirection", "InOut")

	connections[#connections+1] = tweenFrame.Color:GetAttributeChangedSignal("Color"):Connect(function()
		tweenFrame.Color.BackgroundColor3 = colors[tweenFrame.Color:GetAttribute("Color")]
		if tweenFrame.Color:GetAttribute("Color") == 0 then
			tweenFrame.Color.TextButton.Text = "Color"
		else
			tweenFrame.Color.TextButton.Text = ""
		end
	end)

	connections[#connections+1] = tweenFrame.Color.TextButton.MouseButton1Click:Connect(function()
		if sectionFrame.Dropdown:GetAttribute("Debounce") then return end
		sectionFrame.Dropdown:SetAttribute("Debounce", true)

		if sectionFrame.Dropdown:GetAttribute("Dropdown") == "Color" and sectionFrame.Dropdown:GetAttribute("CurrentTween") == tween then
			sectionFrame.Dropdown.Color.Visible = false
			sectionFrame.Dropdown:SetAttribute("Dropdown", nil)
			sectionFrame.Dropdown:SetAttribute("CurrentTween", nil)
		elseif sectionFrame.Dropdown:GetAttribute("Dropdown") == nil and sectionFrame.Dropdown:GetAttribute("CurrentTween") == nil then
			sectionFrame.Dropdown:SetAttribute("Dropdown", "Color")
			sectionFrame.Dropdown:SetAttribute("CurrentTween", tween)
			local colorConnections = {}

			colorConnections[#colorConnections+1] = sectionFrame.Dropdown:GetAttributeChangedSignal("CurrentTween"):Connect(function()
				for i = 1, #colorConnections do
					colorConnections[i]:Disconnect()
				end
			end)

			sectionFrame.Dropdown.Color.Visible = true
			sectionFrame.Dropdown.Color.Position = UDim2.new(0.5, 0, 0, (295*(tween - 1)) + 70)
			for i,v in pairs(sectionFrame.Dropdown.Color:GetChildren()) do
				if v:IsA("TextButton") then
					colorConnections[#colorConnections+1] = v.MouseButton1Click:Connect(function()
						tweenFrame.Color:SetAttribute("Color", v.LayoutOrder)
						sectionFrame.Dropdown.Color.Visible = false
						sectionFrame.Dropdown:SetAttribute("Dropdown", nil)
						sectionFrame.Dropdown:SetAttribute("CurrentTween",nil)
					end)
				end
			end
		end

		sectionFrame.Dropdown:SetAttribute("Debounce", false)
	end)

	connections[#connections+1] = tweenFrame.EasingStyle:GetAttributeChangedSignal("EasingStyle"):Connect(function()
		tweenFrame.EasingStyle.TextButton.Text = tweenFrame.EasingStyle:GetAttribute("EasingStyle")
	end)

	connections[#connections+1] = tweenFrame.EasingStyle.TextButton.MouseButton1Click:Connect(function()
		if sectionFrame.Dropdown:GetAttribute("Debounce") then return end
		sectionFrame.Dropdown:SetAttribute("Debounce", true)

		if sectionFrame.Dropdown:GetAttribute("Dropdown") == "EasingStyle" and sectionFrame.Dropdown:GetAttribute("CurrentTween") == tween then
			sectionFrame.Dropdown.EasingStyle.Visible = false
			sectionFrame.Dropdown:SetAttribute("Dropdown", nil)
			sectionFrame.Dropdown:SetAttribute("CurrentTween", nil)
		elseif sectionFrame.Dropdown:GetAttribute("Dropdown") == nil and sectionFrame.Dropdown:GetAttribute("CurrentTween") == nil then
			sectionFrame.Dropdown:SetAttribute("Dropdown", "EasingStyle")
			sectionFrame.Dropdown:SetAttribute("CurrentTween", tween)
			local easingStyleConnections = {}

			easingStyleConnections[#easingStyleConnections+1] = sectionFrame.Dropdown:GetAttributeChangedSignal("CurrentTween"):Connect(function()
				for i = 1, #easingStyleConnections do
					easingStyleConnections[i]:Disconnect()
				end
			end)

			sectionFrame.Dropdown.EasingStyle.Visible = true
			sectionFrame.Dropdown.EasingStyle.Position = UDim2.new(0.5, 0, 0, (295*(tween - 1)) + (70 + 105))
			for i,v in pairs(sectionFrame.Dropdown.EasingStyle:GetChildren()) do
				if v:IsA("TextButton") then
					easingStyleConnections[#easingStyleConnections+1] = v.MouseButton1Click:Connect(function()
						tweenFrame.EasingStyle:SetAttribute("EasingStyle", v.Name)
						sectionFrame.Dropdown.EasingStyle.Visible = false
						sectionFrame.Dropdown:SetAttribute("Dropdown", nil)
						sectionFrame.Dropdown:SetAttribute("CurrentTween",nil)
					end)
				end
			end
		end

		sectionFrame.Dropdown:SetAttribute("Debounce", false)
	end)

	connections[#connections+1] = tweenFrame.EasingDirection:GetAttributeChangedSignal("EasingDirection"):Connect(function()
		tweenFrame.EasingDirection.TextButton.Text = tweenFrame.EasingDirection:GetAttribute("EasingDirection")
	end)

	connections[#connections+1] = tweenFrame.EasingDirection.TextButton.MouseButton1Click:Connect(function()
		if sectionFrame.Dropdown:GetAttribute("Debounce") then return end
		sectionFrame.Dropdown:SetAttribute("Debounce", true)

		if sectionFrame.Dropdown:GetAttribute("Dropdown") == "EasingDirection" and sectionFrame.Dropdown:GetAttribute("CurrentTween") == tween then
			sectionFrame.Dropdown.EasingDirection.Visible = false
			sectionFrame.Dropdown:SetAttribute("Dropdown", nil)
			sectionFrame.Dropdown:SetAttribute("CurrentTween", nil)
		elseif sectionFrame.Dropdown:GetAttribute("Dropdown") == nil and sectionFrame.Dropdown:GetAttribute("CurrentTween") == nil then
			sectionFrame.Dropdown:SetAttribute("Dropdown", "EasingDirection")
			sectionFrame.Dropdown:SetAttribute("CurrentTween", tween)
			local easingDirectionConnections = {}

			easingDirectionConnections[#easingDirectionConnections+1] = sectionFrame.Dropdown:GetAttributeChangedSignal("CurrentTween"):Connect(function()
				for i = 1, #easingDirectionConnections do
					easingDirectionConnections[i]:Disconnect()
				end
			end)

			sectionFrame.Dropdown.EasingDirection.Visible = true
			sectionFrame.Dropdown.EasingDirection.Position = UDim2.new(0.5, 0, 0, (295*(tween - 1)) + (70 + 140))
			for i,v in pairs(sectionFrame.Dropdown.EasingDirection:GetChildren()) do
				if v:IsA("TextButton") then
					easingDirectionConnections[#easingDirectionConnections+1] = v.MouseButton1Click:Connect(function()
						tweenFrame.EasingDirection:SetAttribute("EasingDirection", v.Name)
						sectionFrame.Dropdown.EasingDirection.Visible = false
						sectionFrame.Dropdown:SetAttribute("Dropdown", nil)
						sectionFrame.Dropdown:SetAttribute("CurrentTween",nil)
					end)
				end
			end
		end

		sectionFrame.Dropdown:SetAttribute("Debounce", false)
	end)

	tweenFrame.Destroying:Connect(function()
		for i = 1, #connections do
			connections[i]:Disconnect()
		end
	end)
end

-- Update Coro
local function update(coro: table, section: number)
	local sectionFrame = faderContainer:WaitForChild(`Section{section}`)
	local currentTween = 1

	while RunService.Heartbeat:Wait() do
		if coro["run"] and pause == false then
			if sectionFrame.Options:FindFirstChild(`Tween{currentTween}`) then
				local success, message = pcall(function()
					if tweenPreviews[section] then
						tweenPreviews[section]:Cancel()
					end
					if tweenPreviewCompletedConnections[section] then
						tweenPreviewCompletedConnections[section]:Disconnect()
					end
	
					local tweenFrame = sectionFrame.Options:WaitForChild(`Tween{currentTween}`)
					if
						tonumber(tweenFrame.Time.TextBox.Text) == nil
						or tonumber(tweenFrame.RepeatCount.TextBox.Text) == nil
						or tonumber(tweenFrame.DelayTime.TextBox.Text) == nil
						or tonumber(tweenFrame.TransparencyGoal.TextBox.Text) == nil
					then
						tweenPreviews[section] = nil
						tweenPreviewCompletedConnections[section] = nil
						currentTween += 1
						RunService.Heartbeat:Wait()
						return
					end
					local tweenInfo = TweenInfo.new(
						tonumber(tweenFrame.Time.TextBox.Text),
						Enum.EasingStyle[tweenFrame.EasingStyle:GetAttribute("EasingStyle")],
						Enum.EasingDirection[tweenFrame.EasingDirection:GetAttribute("EasingDirection")],
						tonumber(tweenFrame.RepeatCount.TextBox.Text),
						tweenFrame.Reverses:GetAttribute("Checked"),
						tonumber(tweenFrame.DelayTime.TextBox.Text)
					)
					sectionFrame.Options.TopOptions.NameBox.BackgroundColor3 = colors[tweenFrame.Color:GetAttribute("Color")]
					tweenPreviews[section] = TweenService:Create(
						sectionFrame.Options.TopOptions.NameBox,
						tweenInfo,
						{BackgroundTransparency = tonumber(tweenFrame.TransparencyGoal.TextBox.Text)}
					)
					tweenPreviews[section]:Play()
					tweenPreviewCompletedConnections[section] = tweenPreviews[section].Completed:Wait()
					tweenPreviews[section] = nil
					tweenPreviewCompletedConnections[section] = nil
					currentTween += 1
				end)

				if not success then
					warn(message, debug.traceback())
					currentTween += 1
				end
			else
				currentTween = 1
			end
		elseif coro["run"] == false then
			break
		end
	end
end

-- Register Section
local function registerSection(section: number)
	local sectionFrame = faderContainer:FindFirstChild(`Section{section}`)
	local connections = {}

	sectionFrame:SetAttribute("Tweens", 1)

	registerTween(sectionFrame, 1)

	coroutines[section] = {
		run = true,
		coro = coroutine.create(update)
	}
	coroutine.resume(coroutines[section].coro, coroutines[section], section)

	sectionFrame.Options.TopOptions.NameBox.TextBox.PlaceholderText = `Fader{section}`

	connections[#connections+1] = sectionFrame.Options.TopOptions.NameBox.TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			if faderContainer:FindFirstChild(`Section{section+1}`) then
				faderContainer:FindFirstChild(`Section{section+1}`).Options.TopOptions.NameBox.TextBox:CaptureFocus()
				RunService.Heartbeat:Wait()
				faderContainer:FindFirstChild(`Section{section+1}`).Options.TopOptions.NameBox.TextBox.Text = ""
			end
		end
	end)

	-- Handle Controls

	if section == 1 then
		sectionFrame.Buttons.TopControls.RemoveHolder.Visible = false
	end

	local function sectionAddVisible()
		if section ~= #faderContainer:GetChildren() - 2 then
			sectionFrame.Buttons.TopControls.AddHolder.Visible = false
			sectionFrame.Buttons.TopControls.RemoveHolder.Visible = false
		else
			sectionFrame.Buttons.TopControls.AddHolder.Visible = true
			sectionFrame.Buttons.TopControls.RemoveHolder.Visible = if section ~= 1 then true else false
		end
	end
	sectionAddVisible()
	connections[#connections+1] = faderContainer.ChildAdded:Connect(sectionAddVisible)
	connections[#connections+1] = faderContainer.ChildRemoved:Connect(sectionAddVisible)

	local function tweenChildrenChange()
		if sectionFrame:FindFirstChild("Buttons") == nil then return end
		if sectionFrame:GetAttribute("Tweens") == 1 then
			sectionFrame.Buttons.Controls.RemoveHolder.Visible = false
		else
			sectionFrame.Buttons.Controls.RemoveHolder.Visible = true
		end
		
		if sectionFrame:FindFirstChild("Options") == nil then return end
		if sectionFrame:FindFirstChild("Buttons") == nil then return end
		if #sectionFrame.Options:GetChildren() ~= (#sectionFrame.Buttons:GetChildren() - 1) then
			local difference = #sectionFrame.Options:GetChildren() - (#sectionFrame.Buttons:GetChildren() - 1)
			if difference > 0 then
				for i = 1, difference do
					local newFrame = Instance.new("Frame")
					newFrame.Name = `TweenFiller{#sectionFrame.Buttons:GetChildren()}`
					newFrame.BackgroundTransparency = 1
					newFrame.Size = UDim2.new(1, 0, 0, 290)
					newFrame.Parent = sectionFrame.Buttons
				end
			else
				for i = 1, -difference do
					sectionFrame.Buttons:FindFirstChild(`TweenFiller{(#sectionFrame.Buttons:GetChildren() - 1)}`):Destroy()
				end
			end
		end
	end
	tweenChildrenChange()
	connections[#connections+1] = sectionFrame.Options.ChildAdded:Connect(tweenChildrenChange)
	connections[#connections+1] = sectionFrame.Options.ChildRemoved:Connect(tweenChildrenChange)
	connections[#connections+1] = sectionFrame:GetAttributeChangedSignal("Tweens"):Connect(tweenChildrenChange)

	-- Add Section
	connections[#connections+1] = sectionFrame.Buttons.TopControls.AddHolder.Add.MouseButton1Click:Connect(function()
		local newSection = require(faderComponents:WaitForChild("section"))(section+1, colorDropdown, colorLabels)
		newSection.Parent = faderContainer
		registerSection(section+1)
	end)

	-- Remove Section
	connections[#connections+1] = sectionFrame.Buttons.TopControls.RemoveHolder.RemoveButton.MouseButton1Click:Connect(function()
		if section == 1 then return end
		if faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency ~= 1 then return end
		faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		confirmPrompt("Are you sure you want to remove this section? <b>Any unsaved progress will be lost!</b>", function(confirm)
			faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
			if confirm then
				sectionFrame:Destroy()
			end
		end).Parent = faders.container.Parent.PopUps
	end)

	-- Add Angle
	connections[#connections+1] = sectionFrame.Buttons.Controls.AddHolder.Add.MouseButton1Click:Connect(function()
		sectionFrame:SetAttribute("Tweens", sectionFrame:GetAttribute("Tweens") + 1)
		local newTween = require(faderComponents:WaitForChild("tweenFrame"))(sectionFrame:GetAttribute("Tweens"))
		newTween.Parent = sectionFrame.Options
		registerTween(sectionFrame, sectionFrame:GetAttribute("Tweens"))
	end)

	-- Remove Angle
	connections[#connections+1] = sectionFrame.Buttons.Controls.RemoveHolder.RemoveButton.MouseButton1Click:Connect(function()
		if sectionFrame:GetAttribute("Tweens") == 1 then return end
		if confirmPrompt.container.Parent:WaitForChild("PopUps").BackgroundTransparency ~= 1 then return end
		faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		confirmPrompt("Are you sure you want to remove this tween? <b>Any unsaved progress will be lost!</b>", function(confirm)
			faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
			if confirm then
				sectionFrame.Options:FindFirstChild(`Tween{sectionFrame:GetAttribute("Tweens")}`):Destroy()
				sectionFrame:SetAttribute("Tweens", sectionFrame:GetAttribute("Tweens") - 1)
			end
		end).Parent = faders.container.Parent.PopUps
	end)

	connections[#connections+1] = sectionFrame.Destroying:Connect(function()
		coroutines[section].run = false
		for i = 1, #connections do
			connections[i]:Disconnect()
		end
	end)
end

registerSection(1)

-- Reset Handler
local function reset()
	setPause(true)
	pauseLocked = false

	for _,v in pairs(tweenPreviews) do
		v:Cancel()
	end

	for _,v in pairs(tweenPreviewCompletedConnections) do
		v:Disconnect()
	end

	for _,v in pairs(faderContainer:GetChildren()) do
		if v:IsA("ScrollingFrame") and v.Name ~= "Section1" then
			v:Destroy()
		end
	end

	faderContainer.Section1:SetAttribute("Tweens", 1)
	for _,v in pairs(faderContainer.Section1.Options:GetChildren()) do
		if v:IsA("Frame") and (v.Name ~= "Tween1" and v.Name ~= "TopOptions") then
			v:Destroy()
		end
	end

	faderContainer.Section1.Options.TopOptions.NameBox.BackgroundTransparency = 0
	faderContainer.Section1.Options.Tween1.DelayTime.TextBox.Text = ""
	faderContainer.Section1.Options.Tween1.RepeatCount.TextBox.Text = ""
	faderContainer.Section1.Options.Tween1.Time.TextBox.Text = ""
	faderContainer.Section1.Options.Tween1.TransparencyGoal.TextBox.Text = ""
	faderContainer.Section1.Options.Tween1.Color:SetAttribute("Color", 0)
	faderContainer.Section1.Options.Tween1.EasingStyle:SetAttribute("EasingStyle", "Linear")
	faderContainer.Section1.Options.Tween1.EasingDirection:SetAttribute("EasingDirection", "InOut")
	faderContainer.Section1.Options.TopOptions.NameBox.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	faderContainer.Section1.Options.TopOptions.NameBox.TextBox.Text = ""
end

local function confirmReset()
	if faders.container == nil then return end
	if faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency ~= 1 then return end
	faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
	confirmPrompt("Are you sure you want to reset? \n<b>Any unsaved progress will be lost!</b>", function(confirm)
		if confirm then
			reset()
		end
		faders.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
	end).Parent = faders.container.Parent.PopUps
end

faders.loadFromTable = function(data: {number:{string:any}})
	reset()

	task.wait(0.1)

	for section=1,#data do
		local sectionData = data[section]
		if typeof(sectionData) == "table" and typeof(sectionData["Name"]) == "string" and typeof(sectionData["Tweens"]) == "table" then
			local sectionFrame = faderContainer.Section1
			if section ~= 1 then
				sectionFrame = require(faderComponents:WaitForChild("section"))(section, colorDropdown, colorLabels)
				sectionFrame.Parent = faderContainer
				registerSection(section)
			end
			
			sectionFrame.Options.TopOptions.NameBox.TextBox.Text = sectionData.Name
			sectionFrame:SetAttribute("Tweens", #sectionData.Tweens)

			for tween=1,#sectionData.Tweens do
				local tweenData = sectionData.Tweens[tween]
				if
					typeof(tweenData) == "table"
					and typeof(tweenData["DelayTime"]) == "number"
					and typeof(tweenData["RepeatCount"]) == "number"
					and typeof(tweenData["Time"]) == "number"
					and typeof(tweenData["TransparencyGoal"]) == "number"
					and typeof(tweenData["Color"]) == "number"
					and typeof(tweenData["EasingStyle"]) == "string"
					and typeof(tweenData["EasingDirection"]) == "string"
					and typeof(tweenData["Reverses"]) == "boolean"
				then
					local tweenFrame = sectionFrame.Options:FindFirstChild(`Tween{tween}`)
					if tweenFrame == nil then
						tweenFrame = require(faderComponents:WaitForChild("tweenFrame"))(tween)
						tweenFrame.Parent = sectionFrame.Options
						registerTween(sectionFrame, tween)
					end

					tweenFrame.DelayTime.TextBox.Text = tweenData.DelayTime
					tweenFrame.RepeatCount.TextBox.Text = tweenData.RepeatCount
					tweenFrame.Time.TextBox.Text = tweenData.Time
					tweenFrame.TransparencyGoal.TextBox.Text = tweenData.TransparencyGoal
					tweenFrame.Color:SetAttribute("Color", tweenData.Color)
					tweenFrame.EasingStyle:SetAttribute("EasingStyle", tweenData.EasingStyle)
					tweenFrame.EasingDirection:SetAttribute("EasingDirection", tweenData.EasingDirection)
					tweenFrame.Reverses:SetAttribute("Checked", tweenData.Reverses)
				elseif typeof(tweenData) == "table" then
					local tweenFrame = sectionFrame.Options:FindFirstChild(`Tween{tween}`)
					if tweenFrame == nil then
						tweenFrame = require(faderComponents:WaitForChild("tweenFrame"))(tween)
						tweenFrame.Parent = sectionFrame.Options
						registerTween(sectionFrame, tween)
					end
				end
			end
		end
	end
end

faders.toTable = function()
	local data = {}

	for _,section in pairs(faderContainer:GetChildren()) do
		if section:IsA("ScrollingFrame") then
			local sectionTable = {
				Name = section.Options.TopOptions.NameBox.TextBox.Text,
				Tweens = {}
			}

			for _,tween in pairs(section.Options:GetChildren()) do
				if tween:IsA("Frame") and tween.Name ~= "TopOptions" then
					local tweenTable = {
						DelayTime = tonumber(tween.DelayTime.TextBox.Text),
						RepeatCount = tonumber(tween.RepeatCount.TextBox.Text),
						Time = tonumber(tween.Time.TextBox.Text),
						TransparencyGoal = tonumber(tween.TransparencyGoal.TextBox.Text),
						Color = tween.Color:GetAttribute("Color"),
						EasingStyle = tween.EasingStyle:GetAttribute("EasingStyle"),
						EasingDirection = tween.EasingDirection:GetAttribute("EasingDirection"),
						Reverses = tween.Reverses:GetAttribute("Checked")
					}

					sectionTable.Tweens[tween.LayoutOrder] = tweenTable
				end
			end

			data[section.LayoutOrder] = sectionTable
		end
	end
	-- print(data)

	return data
end

-- Input Handler
faders.InputBegan = function(input: InputObject)
	if faders.enabled == false then return end

	if input.KeyCode == Enum.KeyCode.P then
		if pauseLocked then return end
		setPause(not pause)
	elseif input.KeyCode == Enum.KeyCode.R then
		confirmReset()
	end
end

pauseButton.Image.MouseButton1Click:Connect(function()
	if pauseLocked then return end
	setPause(not pause)
end)

resetButton.Image.MouseButton1Click:Connect(function()
	confirmReset()
end)

faders.Display = function(container: Frame)
	faderContainer.Parent = container
	controls.Parent = container
	faders.container = container
	faders.enabled = true
end

faders.StopDisplay = function()
	setPause(true)

	faderContainer.Parent = nil
	controls.Parent = nil
	faders.container = nil
	faders.enabled = false
end

pluginRoot.Destroying:Connect(function()
	faders.enabled = false
end)

return faders