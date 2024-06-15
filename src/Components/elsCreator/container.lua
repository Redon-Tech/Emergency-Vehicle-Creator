--[[
Redon Tech 2023-2024
EVC V2
--]]

local section = require(script.Parent.section)

return function()
	local mainContainer = Instance.new("ScrollingFrame")
	mainContainer.Name = "MainContainer"
	mainContainer.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	mainContainer.CanvasSize = UDim2.new()
	mainContainer.ScrollBarThickness = 5
	mainContainer.ScrollingDirection = Enum.ScrollingDirection.XY
	mainContainer.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.BackgroundTransparency = 1
	mainContainer.BorderSizePixel = 0
	mainContainer.Position = UDim2.fromScale(0.5, 0.529)
	mainContainer.Selectable = false
	mainContainer.Size = UDim2.fromScale(1, 0.942)

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.Parent = mainContainer

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Name = "UIPadding"
	uIPadding.PaddingBottom = UDim.new(0.0361, 0)
	uIPadding.PaddingLeft = UDim.new(0.0182, 0)
	uIPadding.PaddingRight = UDim.new(0.018, 0)
	uIPadding.PaddingTop = UDim.new(0.036, 0)
	uIPadding.Parent = mainContainer

	local function changeSize()
		mainContainer.CanvasSize = UDim2.fromOffset(uIListLayout.AbsoluteContentSize.X, uIListLayout.AbsoluteContentSize.Y)
	end
	
	mainContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(changeSize)
	uIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(changeSize)

	section(1).Parent = mainContainer

	return mainContainer
end