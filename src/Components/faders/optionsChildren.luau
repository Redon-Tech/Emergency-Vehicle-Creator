--[[
Redon Tech 2023-2024
EVC V2
--]]

local tweenFrame = require(script.Parent.tweenFrame)
local rowWithTextBox = require(script.Parent.Parent.reusedContent.rowWithTextBox)

return function(options: Frame)
	local topOptions = Instance.new("Frame")
	topOptions.Name = "TopOptions"
	topOptions.AnchorPoint = Vector2.new(0.5, 0.5)
	topOptions.BackgroundTransparency = 1
	topOptions.BorderSizePixel = 0
	topOptions.LayoutOrder = -1
	topOptions.Size = UDim2.new(1, 0, 0, 65)

	local name = rowWithTextBox("Name", "NameBox", 1)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.fromScale(0.5, 0)
	name.Parent = topOptions

	local devider = Instance.new("Frame")
	devider.Name = "Devider"
	devider.AnchorPoint = Vector2.new(0, 1)
	devider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	devider.BackgroundTransparency = 1
	devider.LayoutOrder = 1
	devider.Position = UDim2.fromScale(0, 1)
	devider.Size = UDim2.new(1, 0, 0, 30)

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(86, 86, 86)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(50, 10)
	frame.Parent = devider

	devider.Parent = topOptions
	
	topOptions.Parent = options

	tweenFrame(1).Parent = options
end