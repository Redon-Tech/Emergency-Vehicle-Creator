--[[
Redon Tech 2023-2024
EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local pluginRoot = script.Parent.Parent.Parent
local rotators = {enabled = false, canExport = true, container = nil}

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
local pause, currentPreview, currentPreviewAngle = true, nil, nil

--------------------------------------------------------------------------------
-- UI Setup --
--------------------------------------------------------------------------------

local Components = script.Parent.Parent:WaitForChild("Components")
rotators["topBarButton"] = require(Components:WaitForChild("topBarButton"))("rotators", 2, "Rotators", 0.104, true)
local rotatorComponents = Components:WaitForChild("rotators")
local reusedContent = Components:WaitForChild("reusedContent")
local confirmPrompt = require(Components:WaitForChild("popups"):WaitForChild("confirm"))

local controls = require(reusedContent:WaitForChild("controls"))()
local rotatorContainer = require(rotatorComponents:WaitForChild("container"))(colorDropdown, colorLabels)

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
end

-- Preview
local function threadFunction()
	-- local currentTargetAngle = 0
	-- local currentMaxVelocity = 100
	-- local currentTween = nil

	-- while true do
	-- 	if rotators.enabled == false then break end

	-- 	if pause or currentPreview == nil then
	-- 		RunService.Heartbeat:Wait()
	-- 	else
	-- 		if
	-- 			rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D.DesiredAngle ~= currentTargetAngle
	-- 			or rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D.MaxVelocity ~= currentMaxVelocity
	-- 		then
	-- 			if currentTween then currentTween:Cancel() end

	-- 			currentTargetAngle = rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D.DesiredAngle
	-- 			currentTween = TweenService:Create(
	-- 				rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D,
	-- 				TweenInfo.new(math.abs(currentTargetAngle) - (rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D.MaxVelocity * 2.5), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
	-- 				{C1 = CFrame.Angles(math.rad(90), 0, math.rad(math.deg(currentTargetAngle)))}
	-- 			)
	-- 			currentTween:Play()
	-- 		end

	-- 		RunService.Heartbeat:Wait()
	-- 	end
	-- end

	local currentRad = 0
	local currentTarget = 0
	local currentVelocity = 0
	local motor = rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if rotators.enabled == false then connection:Disconnect() end

		if motor:GetAttribute("Reset") == true then
			-- if currentPreview ~= nil and currentPreviewAngle ~= nil then
			-- 	local currentPreviewFrame = rotatorContainer.ControlsHolder:FindFirstChild(`Section{currentPreview}`)
			-- 	local currentPreviewAngleFrame = currentPreviewFrame.Options:FindFirstChild(`Angle{currentPreviewAngle}`)
			-- 	currentPreviewAngleFrame.ImageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
			-- end
			-- currentPreview, currentPreviewAngle = nil, nil

			currentRad = 0
			currentTarget = 0
			currentVelocity = 0
			motor.MaxVelocity = 100
			motor:SetAttribute("DesiredAngle", 0)
			motor.C1 = CFrame.Angles(math.rad(90), 0, 0)

			rotatorContainer.ViewportFrame.WorldModel.Part:SetAttribute("Color", 0)


			motor:SetAttribute("Reset", false)
		end

		if pause == false and currentPreview ~= nil then
			if -motor:GetAttribute("DesiredAngle") ~= currentTarget then
				currentTarget = -motor:GetAttribute("DesiredAngle")
			end
			if currentVelocity ~= motor.MaxVelocity then
				currentVelocity = motor.MaxVelocity
			end

			local diff = currentTarget - currentRad
			if diff < 0.05 and diff > -0.05 then
				motor.C1 = CFrame.Angles(math.rad(90), 0, currentTarget)
				-- if rotatorContainer.ControlsHolder:FindFirstChild(`Section{currentPreview}`):GetAttribute("Angles") == currentPreviewAngle then
				-- 	setPause(true)
				-- 	rotatorContainer.ControlsHolder:FindFirstChild(`Section{currentPreview}`).Options:FindFirstChild(`Angle{currentPreviewAngle}`).ImageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
				-- else
				-- 	if currentPreview ~= nil and currentPreviewAngle ~= nil then
				-- 		rotatorContainer.ControlsHolder:FindFirstChild(`Section{currentPreview}`).Options:FindFirstChild(`Angle{currentPreviewAngle}`).ImageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
				-- 	end
				-- 	if currentPreviewAngle == nil then
				-- 		currentPreviewAngle = 1
				-- 	else
				-- 		currentPreviewAngle += 1
				-- 	end
				-- 	if currentPreview == nil or currentPreviewAngle == nil then return end
				-- 	local angleFrame = rotatorContainer.ControlsHolder:FindFirstChild(`Section{currentPreview}`).Options:FindFirstChild(`Angle{currentPreviewAngle}`)
				-- 	angleFrame.ImageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
				-- 	rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D.MaxVelocity = tonumber(angleFrame.Velocity.TextBox.Text)
				-- 	rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D.DesiredAngle = math.rad(tonumber(angleFrame.Angle.TextBox.Text))
				-- 	rotatorContainer.ViewportFrame.WorldModel.Part:SetAttribute("Color", angleFrame.Color:GetAttribute("Color"))
				-- end
				if currentPreview ~= nil and currentPreviewAngle ~= nil then
					local currentPreviewFrame = rotatorContainer.ControlsHolder:FindFirstChild(`Section{currentPreview}`)
					local currentPreviewAngleFrame = currentPreviewFrame.Options:FindFirstChild(`Angle{currentPreviewAngle}`)

					if currentPreviewFrame:GetAttribute("Angles") == currentPreviewAngle then
						currentPreviewAngle = 1
					else
						currentPreviewAngle += 1
					end

					local angleFrame = currentPreviewFrame.Options:FindFirstChild(`Angle{currentPreviewAngle}`)
					currentPreviewAngleFrame.ImageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
					angleFrame.ImageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
					if tonumber(angleFrame.Velocity.TextBox.Text) == nil or tonumber(angleFrame.Angle.TextBox.Text) == nil then
						setPause(true)
						return
					end
					motor.MaxVelocity = tonumber(angleFrame.Velocity.TextBox.Text)
					motor:SetAttribute("DesiredAngle", math.rad(tonumber(angleFrame.Angle.TextBox.Text)))
					rotatorContainer.ViewportFrame.WorldModel.Part:SetAttribute("Color", angleFrame.Color:GetAttribute("Color"))
				end
			else
				currentRad += if diff > 0 then currentVelocity else -currentVelocity
				motor.C1 = CFrame.Angles(math.rad(90), 0, currentRad)
			end
		end
	end)
end

rotatorContainer.ViewportFrame.WorldModel.Part:GetAttributeChangedSignal("Color"):Connect(function()
	local color = rotatorContainer.ViewportFrame.WorldModel.Part:GetAttribute("Color")

	if color == nil or color == 0 then
		rotatorContainer.ViewportFrame.WorldModel.Part.Transparency = 1
	else
		rotatorContainer.ViewportFrame.WorldModel.Part.Color = colors[color]
		rotatorContainer.ViewportFrame.WorldModel.Part.Transparency = 0
	end
end)

-- local function setPause(value: boolean)
-- 	if value == true then
-- 		pause = true
-- 		pauseButton:SetAttribute("Icon", pause)
-- 	else
-- 		if acceptedPause == false then
-- 			rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
-- 			confirmPrompt("<b>⚠️ WARNING ⚠️</b>\nBecause of the way Roblox works in order to simulate the rotator we must run the games physics.\n<b>Any unanchored parts will be simulated, THIS CAN NOT BE UNDONE</b>", function(confirm)
-- 				rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
-- 				if confirm then
-- 					pause = false
-- 					pauseButton:SetAttribute("Icon", pause)
-- 					acceptedPause = true
-- 				end
-- 			end).Parent = rotators.container.Parent.PopUps
-- 		else
-- 			pause = false
-- 			pauseButton:SetAttribute("Icon", pause)
-- 		end
-- 	end

-- 	if pause then
-- 		RunService:Stop()
-- 	elseif pause == true then
-- 		RunService:Run()
-- 	end
-- end

local function resetPreview()
	setPause(true)
	rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D:SetAttribute("Reset", true)
	-- rotatorContainer.ViewportFrame.WorldModel.Motor.Motor6D:GetAttributeChangedSignal("Reset"):Wait()
end

local function changePreview(section: number)
	setPause(true)
	pauseButton:SetAttribute("Icon", pause)
	resetPreview()
	task.wait(.1)

	if currentPreview == section then
		currentPreview = nil
		rotatorContainer.ControlsHolder:FindFirstChild(`Section{section}`).Options.TopOptions.Enabled.Checkbox.Checkmark.Visible = false
	else
		local oldSection = currentPreview
		local oldSectionFrame = rotatorContainer.ControlsHolder:FindFirstChild(`Section{oldSection}`)
		local sectionFrame = rotatorContainer.ControlsHolder:FindFirstChild(`Section{section}`)

		if oldSectionFrame then oldSectionFrame.Options.TopOptions.Enabled.Checkbox.Checkmark.Visible = false end
		sectionFrame.Options.TopOptions.Enabled.Checkbox.Checkmark.Visible = true

		currentPreview = section
		currentPreviewAngle = 1
	end
end

-- Register Angle
local function registerAngle(sectionFrame: Frame, angle: number)
	local angleFrame = sectionFrame.Options:FindFirstChild(`Angle{angle}`)
	local connections = {}
	local didSetPause = false

	connections[#connections+1] = angleFrame.Color:GetAttributeChangedSignal("Color"):Connect(function()
		angleFrame.Color.BackgroundColor3 = colors[angleFrame.Color:GetAttribute("Color")]
		-- if angleFrame.Color:GetAttribute("Color") == 0 then
		-- 	angleFrame.Color.TextButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		-- 	angleFrame.Color.TextButton.Text = "Color"
		-- elseif angleFrame.Color:GetAttribute("Color") == 4 then
		-- 	angleFrame.Color.TextButton.Text = "White"
		-- 	angleFrame.Color.TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		-- else
		-- 	angleFrame.Color.TextButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		-- 	angleFrame.Color.TextButton.Text = colorLabels[angleFrame.Color:GetAttribute("Color")]
		-- end
		if angleFrame.Color:GetAttribute("Color") == 0 then
			angleFrame.Color.TextButton.Text = "Color"
		else
			angleFrame.Color.TextButton.Text = ""
		end
	end)

	angleFrame.Color:SetAttribute("Color", 0)
	connections[#connections+1] = angleFrame.Color.TextButton.MouseButton1Click:Connect(function()
		if sectionFrame.Dropdown.Color:GetAttribute("debounce") == true then return end
		sectionFrame.Dropdown.Color:SetAttribute("debounce", true)
		if sectionFrame.Dropdown.Color:GetAttribute("currentFrame") == angle then
			sectionFrame.Dropdown.Color.Visible = false
		else
			local colorConnections = {}
			sectionFrame.Dropdown.Color:SetAttribute("currentFrame", angle)
			colorConnections[#colorConnections+1] = sectionFrame.Dropdown.Color:GetAttributeChangedSignal("currentFrame"):Connect(function()
				for i = 1, #colorConnections do
					colorConnections[i]:Disconnect()
				end
			end)
			sectionFrame.Dropdown.Color.Visible = true
			sectionFrame.Dropdown.Color.Position = UDim2.new(0.5, 0, 0, (105*(angle - 1)) + 170)
			for i,v in pairs(sectionFrame.Dropdown.Color:GetChildren()) do
				if v:IsA("TextButton") then
					colorConnections[#colorConnections+1] = v.MouseButton1Click:Connect(function()
						angleFrame.Color:SetAttribute("Color", v.LayoutOrder)
						sectionFrame.Dropdown.Color.Visible = false
						sectionFrame.Dropdown.Color:SetAttribute("currentFrame", nil)
						for i = 1, #colorConnections do
							colorConnections[i]:Disconnect()
						end
					end)
				end
			end
		end
		sectionFrame.Dropdown.Color:SetAttribute("debounce", false)
	end)

	connections[#connections+1] = angleFrame.Angle.TextBox.Focused:Connect(function()
		didSetPause = if pause == false then true else false
		setPause(true)
	end)

	connections[#connections+1] = angleFrame.Angle.TextBox.FocusLost:Connect(function(enterPressed)
		if didSetPause then
			setPause(false)
			didSetPause = false
		end

		if enterPressed and (angleFrame.Velocity.TextBox.Text == "" or angleFrame.Velocity.TextBox.Text == nil) then
			angleFrame.Velocity.TextBox:CaptureFocus()
			RunService.Heartbeat:Wait()
			angleFrame.Velocity.TextBox.Text = ""
		end
	end)

	connections[#connections+1] = angleFrame.Velocity.TextBox.Focused:Connect(function()
		didSetPause = if pause == false then true else false
		setPause(true)
	end)

	connections[#connections+1] = angleFrame.Velocity.TextBox.FocusLost:Connect(function()
		if didSetPause then
			setPause(false)
			didSetPause = false
		end
	end)

	connections[#connections+1] = angleFrame.Destroying:Connect(function()
		for i = 1, #connections do
			connections[i]:Disconnect()
		end
	end)
end

-- Register Sections
local function registerSection(section: number)
	local sectionFrame = rotatorContainer.ControlsHolder:FindFirstChild(`Section{section}`)
	local connections = {}

	sectionFrame:SetAttribute("Angles", 1)

	registerAngle(sectionFrame, 1)

	sectionFrame.Options.TopOptions.NameBox.TextBox.PlaceholderText = `Rotator{section}`

	connections[#connections+1] = sectionFrame.Options.TopOptions.NameBox.TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			if rotatorContainer.ControlsHolder:FindFirstChild(`Section{section+1}`) then
				rotatorContainer.ControlsHolder:FindFirstChild(`Section{section+1}`).Options.TopOptions.NameBox.TextBox:CaptureFocus()
				RunService.Heartbeat:Wait()
				rotatorContainer.ControlsHolder:FindFirstChild(`Section{section+1}`).Options.TopOptions.NameBox.TextBox.Text = ""
			end
		end
	end)

	-- Handle Controls

	-- Set Preview
	connections[#connections+1] = sectionFrame.Options.TopOptions.Enabled.Checkbox.Button.MouseButton1Click:Connect(function()
		changePreview(section)
	end)

	if section == 1 then
		sectionFrame.Buttons.TopControls.RemoveHolder.Visible = false
	end

	local function sectionAddVisible()
		if rotatorContainer:FindFirstChild("ControlsHolder") == nil then return end
		if section ~= #rotatorContainer.ControlsHolder:GetChildren() - 2 then
			sectionFrame.Buttons.TopControls.AddHolder.Visible = false
			sectionFrame.Buttons.TopControls.RemoveHolder.Visible = false
		else
			sectionFrame.Buttons.TopControls.AddHolder.Visible = true
			sectionFrame.Buttons.TopControls.RemoveHolder.Visible = if section ~= 1 then true else false
		end
	end
	sectionAddVisible()
	connections[#connections+1] = rotatorContainer.ControlsHolder.ChildAdded:Connect(sectionAddVisible)
	connections[#connections+1] = rotatorContainer.ControlsHolder.ChildRemoved:Connect(sectionAddVisible)

	local function angleChildrenChange()
		if sectionFrame:FindFirstChild("Buttons") == nil then return end
		if sectionFrame:GetAttribute("Angles") == 1 then
			sectionFrame.Buttons.Controls.RemoveHolder.Visible = false
		else
			sectionFrame.Buttons.Controls.RemoveHolder.Visible = true
		end
		
		if sectionFrame:FindFirstChild("Options") == nil then return end
		if sectionFrame:FindFirstChild("Buttons") == nil then return end
		if #sectionFrame.Options:GetChildren() ~= #sectionFrame.Buttons:GetChildren() then
			local difference = #sectionFrame.Options:GetChildren() - #sectionFrame.Buttons:GetChildren()
			if difference > 0 then
				for i = 1, difference do
					local newFrame = Instance.new("Frame")
					newFrame.Name = `AngleFiller{#sectionFrame.Buttons:GetChildren() + 1}`
					newFrame.BackgroundTransparency = 1
					newFrame.Size = UDim2.new(1, 0, 0, 100)
					newFrame.Parent = sectionFrame.Buttons
				end
			else
				for i = 1, -difference do
					sectionFrame.Buttons:FindFirstChild(`AngleFiller{#sectionFrame.Buttons:GetChildren()}`):Destroy()
				end
			end
		end
	end
	angleChildrenChange()
	connections[#connections+1] = sectionFrame.Options.ChildAdded:Connect(angleChildrenChange)
	connections[#connections+1] = sectionFrame.Options.ChildRemoved:Connect(angleChildrenChange)
	connections[#connections+1] = sectionFrame:GetAttributeChangedSignal("Angles"):Connect(angleChildrenChange)

	-- Add Section
	connections[#connections+1] = sectionFrame.Buttons.TopControls.AddHolder.Add.MouseButton1Click:Connect(function()
		local newSection = require(rotatorComponents:WaitForChild("section"))(section+1, colorDropdown, colorLabels)
		newSection.Parent = rotatorContainer.ControlsHolder
		registerSection(section+1)
	end)

	-- Remove Section
	connections[#connections+1] = sectionFrame.Buttons.TopControls.RemoveHolder.RemoveButton.MouseButton1Click:Connect(function()
		if section == 1 then return end
		if rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency ~= 1 then return end
		rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		confirmPrompt("Are you sure you want to remove this section? <b>Any unsaved progress will be lost!</b>", function(confirm)
			rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
			if confirm then
				sectionFrame:Destroy()
			end
		end).Parent = rotators.container.Parent.PopUps
	end)

	-- Add Angle
	connections[#connections+1] = sectionFrame.Buttons.Controls.AddHolder.Add.MouseButton1Click:Connect(function()
		sectionFrame:SetAttribute("Angles", sectionFrame:GetAttribute("Angles") + 1)
		local newAngle = require(rotatorComponents:WaitForChild("angleRows"))(sectionFrame:GetAttribute("Angles"))
		newAngle.Parent = sectionFrame.Options
		registerAngle(sectionFrame, sectionFrame:GetAttribute("Angles"))
	end)

	-- Remove Angle
	connections[#connections+1] = sectionFrame.Buttons.Controls.RemoveHolder.RemoveButton.MouseButton1Click:Connect(function()
		if sectionFrame:GetAttribute("Angles") == 1 then return end
		if rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency ~= 1 then return end
		rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		confirmPrompt("Are you sure you want to remove this angle? <b>Any unsaved progress will be lost!</b>", function(confirm)
			rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
			if confirm then
				sectionFrame.Options:FindFirstChild(`Angle{sectionFrame:GetAttribute("Angles")}`):Destroy()
				sectionFrame:SetAttribute("Angles", sectionFrame:GetAttribute("Angles") - 1)
			end
		end).Parent = rotators.container.Parent.PopUps
	end)

	connections[#connections+1] = sectionFrame.Destroying:Connect(function()
		for i = 1, #connections do
			connections[i]:Disconnect()
		end
	end)
end

registerSection(1)
changePreview(1)

-- Reset Handler
local function reset()
	setPause(true)
	resetPreview()
	for i,v in pairs(rotatorContainer.ControlsHolder:GetChildren()) do
		if v:IsA("ScrollingFrame") and v.Name ~= "Section1" then
			v:Destroy()
		end
	end

	rotatorContainer.ControlsHolder.Section1:SetAttribute("Angles", 1)
	for i,v in pairs(rotatorContainer.ControlsHolder.Section1.Options:GetChildren()) do
		if v:IsA("Frame") and (v.Name ~= "Angle1" and v.Name ~= "Label" and v.Name ~= "TopOptions") then
			v:Destroy()
		end
	end

	rotatorContainer.ControlsHolder.Section1.Options.TopOptions.NameBox.TextBox.Text = ""
	rotatorContainer.ControlsHolder.Section1.Options.Angle1.Angle.TextBox.Text = ""
	rotatorContainer.ControlsHolder.Section1.Options.Angle1.Velocity.TextBox.Text = ""
	rotatorContainer.ControlsHolder.Section1.Options.Angle1.Color:SetAttribute("Color", 0)

	changePreview(1)
end

local function confirmReset()
	if rotators.container == nil then return end
	if rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency ~= 1 then return end
	rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
	confirmPrompt("Are you sure you want to reset? \n<b>Any unsaved progress will be lost!</b>", function(confirm)
		if confirm then
			reset()
		end
		rotators.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
	end).Parent = rotators.container.Parent.PopUps
end

rotators.loadFromTable = function(data: {number:{string:any}})
	reset()

	task.wait(0.1)

	for section=1,#data do
		local sectionData = data[section]
		if typeof(sectionData) == "table" and typeof(sectionData["Name"]) == "string" and typeof(sectionData["Angles"]) == "table" then
			local sectionFrame = rotatorContainer.ControlsHolder.Section1
			if section ~= 1 then
				sectionFrame = require(rotatorComponents:WaitForChild("section"))(section, colorDropdown, colorLabels)
				sectionFrame.Parent = rotatorContainer.ControlsHolder
				registerSection(section)
			end

			sectionFrame:SetAttribute("Angles", #sectionData.Angles)
			sectionFrame.Options.TopOptions.NameBox.TextBox.Text = sectionData.Name
			
			for angle=1,#sectionData.Angles do
				local angleData = sectionData.Angles[angle]
				if typeof(angleData) == "table" and typeof(angleData["Angle"]) == "number" and typeof(angleData["Velocity"]) == "number" and typeof(angleData["Color"]) == "number" then
					local angleFrame = sectionFrame.Options:FindFirstChild(`Angle{angle}`)
					if angleFrame == nil then
						angleFrame = require(rotatorComponents:WaitForChild("angleRows"))(sectionFrame:GetAttribute("Angles"))
						angleFrame.Parent = sectionFrame.Options
						registerAngle(sectionFrame, sectionFrame:GetAttribute("Angles"))
					end

					angleFrame.Angle.TextBox.Text = angleData.Angle
					angleFrame.Velocity.TextBox.Text = angleData.Velocity
					angleFrame.Color:SetAttribute("Color", angleData.Color)
				end
			end
		end
	end

	changePreview(1)
end

rotators.toTable = function()
	local data = {}

	for _,section in pairs(rotatorContainer.ControlsHolder:GetChildren()) do
		if section:IsA("ScrollingFrame") then
			local sectionData = {
				Name = section.Options.TopOptions.NameBox.TextBox.Text,
				Angles = {}
			}

			for _,angle in pairs(section.Options:GetChildren()) do
				if angle:IsA("Frame") and angle.Name ~= "Label" and angle.Name ~= "TopOptions" then
					local angleData = {
						Angle = tonumber(angle.Angle.TextBox.Text),
						Velocity = tonumber(angle.Velocity.TextBox.Text),
						Color = angle.Color:GetAttribute("Color")
					}

					-- table.insert(sectionData.Angles, angleData)
					sectionData.Angles[angle.LayoutOrder] = angleData
				end
			end

			-- table.insert(data, sectionData)
			data[section.LayoutOrder] = sectionData
		end
	end

	return data
end

-- Input Handler
rotators.InputBegan = function(input: InputObject)
	if rotators.enabled == false then return end

	if input.KeyCode == Enum.KeyCode.P then
		setPause(not pause)
		pauseButton:SetAttribute("Icon", pause)
	elseif input.KeyCode == Enum.KeyCode.R then
		confirmReset()
	end
end

pauseButton.Image.MouseButton1Click:Connect(function()
	setPause(not pause)
	pauseButton:SetAttribute("Icon", pause)
end)

resetButton.Image.MouseButton1Click:Connect(function()
	confirmReset()
end)

rotators.Display = function(container: Frame)
	rotatorContainer.Parent = container
	controls.Parent = container
	rotators.container = container
	rotators.enabled = true

	task.spawn(threadFunction)
end

rotators.StopDisplay = function()
	setPause(true)

	rotatorContainer.Parent = nil
	controls.Parent = nil
	rotators.container = nil
	rotators.enabled = false
end

pluginRoot.Destroying:Connect(function()
	rotators.enabled = false
end)

return rotators