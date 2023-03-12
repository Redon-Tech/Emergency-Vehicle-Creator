--[[
Redon Tech 2022
WS V2
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

	return Container
end