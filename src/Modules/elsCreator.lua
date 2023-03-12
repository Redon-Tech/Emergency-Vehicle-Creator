--[[
Redon Tech 2022
WS V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local pluginRoot = script.Parent.Parent.Parent
local elsCreator = {}

local colors = {
	[0] = Color3.fromRGB(40, 40, 40),
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

--------------------------------------------------------------------------------
-- UI Setup --
--------------------------------------------------------------------------------

local Components = script.Parent.Parent:WaitForChild("Components")
elsCreator["topBarButton"] = require(Components:WaitForChild("topBarButton"))("elsCreator", 1, "ELS Creator", 0.104, true)
local elsCreatorComponents = Components:WaitForChild("elsCreator")

local controls = require(elsCreatorComponents:WaitForChild("controls"))()

local pauseButton = require(elsCreatorComponents:WaitForChild("iconButton"))("Pause", 7, "rbxassetid://12758044683")
local lockButton = require(elsCreatorComponents:WaitForChild("iconButton"))("Lock", 8, "rbxassetid://12758042236")
local resetButton = require(elsCreatorComponents:WaitForChild("iconButton"))("Reset", 9, "rbxassetid://12758045258")
pauseButton.Parent = controls
lockButton.Parent = controls
resetButton.Parent = controls

--------------------------------------------------------------------------------
-- Module Functions --
--------------------------------------------------------------------------------

local function setColor(value: number)
	color = value
	for i,v in pairs(controls:GetChildren()) do
		if v:IsA("Frame") and v:FindFirstChild("Text") then
			if v.Name == tostring(value) then
				v.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
				v.Text.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
				v:SetAttribute("Active", true)
			else
				v.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
				v.Text.TextColor3 = colors[tonumber(v.Name)]
				v:SetAttribute("Active", false)
			end
		end
	end
end

for i,v in pairs(colors) do
	if i ~= 0 then
		local color = require(elsCreatorComponents:WaitForChild("textButton"))(i, i, colorLabels[i], v)
		color.Parent = controls

		color.Text.MouseButton1Click:Connect(function()
			setColor(i)
		end)
	end
end
setColor(1)

elsCreator.InputBegan = function(input: InputObject)
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
	end
end

elsCreator.Display = function(container: Frame)
	controls.Parent = container
end

elsCreator.StopDisplay = function()
	controls.Parent = nil
end

return elsCreator