--[[
Redon Tech 2022
EVC V2
--]]

local topBar = require(script.Parent.topBar)

return function()
	local Container = Instance.new("Frame")
	Container.Name = "Container"
	Container.ZIndex = 1
	Container.AnchorPoint = Vector2.new(0.5, 0.5)
	Container.Position = UDim2.fromScale(0.5, 0.5)
	Container.Size = UDim2.fromScale(1, 1)
	Container.BackgroundTransparency = 1

	local Tabs = topBar()
	Tabs.Parent = Container

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromScale(0.5, 0.523)
	content.Size = UDim2.fromScale(1, 0.954)
	content.ZIndex = 2
	content.Parent = Container

	local popUps = Instance.new("Frame")
	popUps.Name = "PopUps"
	popUps.AnchorPoint = Vector2.new(0.5, 0.5)
	popUps.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	popUps.BackgroundTransparency = 1
	popUps.Position = UDim2.fromScale(0.5, 0.5)
	popUps.Size = UDim2.fromScale(1, 1)
	popUps.ZIndex = 100000
	popUps.Parent = Container

	return Container
end