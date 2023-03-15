--[[
Redon Tech 2022
EVC V2
--]]

local column = require(script.Parent.column)
local columnButtons = require(script.Parent.columnButtons)

return function()
	local columns = Instance.new("ScrollingFrame")
	columns.Name = "Columns"
	columns.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	columns.CanvasSize = UDim2.new()
	columns.ScrollBarThickness = 5
	columns.ScrollingDirection = Enum.ScrollingDirection.Y
	columns.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	columns.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	columns.AnchorPoint = Vector2.new(0.5, 0)
	columns.BackgroundTransparency = 1
	columns.BorderSizePixel = 0
	columns.Position = UDim2.new(0.5, -20, 0, 75) -- -40, 150
	columns.Selectable = false
	columns.Size = UDim2.fromOffset(62.5, 500) -- 165, 700

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5) -- 10
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = columns

	local indicatorHolder = Instance.new("ScrollingFrame")
	indicatorHolder.Name = "IndicatorHolder"
	indicatorHolder.CanvasSize = columns.CanvasSize
	indicatorHolder.CanvasPosition = columns.CanvasPosition
	indicatorHolder.AnchorPoint = columns.AnchorPoint
	indicatorHolder.Position = UDim2.new(0.5, -1, 0, 75)
	indicatorHolder.Size = columns.Size
	indicatorHolder.ScrollBarThickness = 0
	indicatorHolder.ScrollingDirection = Enum.ScrollingDirection.Y
	indicatorHolder.BackgroundTransparency = 1
	indicatorHolder.Selectable = false
	indicatorHolder.ScrollingEnabled = false
	indicatorHolder.ClipsDescendants = false

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.AnchorPoint = Vector2.new(0.5, 0)
	indicator.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Pressed)
	indicator.BackgroundTransparency = 0.7
	indicator.Position = UDim2.fromScale(0.5, 0)
	indicator.Size = UDim2.fromOffset(42.5, 21) -- 85, 40
	indicator.Parent = indicatorHolder
	indicator.ZIndex = 0

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 4)
	uICorner.Parent = indicator
	
	local function changeSize()
		-- 75, 10, 700
		columns.Size = UDim2.fromOffset((37.5 * (#columns:GetChildren() - 1)) + (5 * (#columns:GetChildren() - 2)) + 5, 500)
		columns.Position = UDim2.new(0.5, -((37.5 * (#columns:GetChildren() - 2)) + (5 * (#columns:GetChildren() - 2)) - 5)/2, 0, 75)

		indicatorHolder.Size = UDim2.fromOffset((37.5 * (#columns:GetChildren() - 2)) + (5 * (#columns:GetChildren() - 2)), 500)

		indicator.Size = UDim2.fromOffset((37.5 * (#columns:GetChildren() - 2)) + 5, 20) -- 75, 10, 40
		if columns:FindFirstChild("Buttons") then
			columns.CanvasSize = UDim2.fromOffset(0, columns["Buttons"].UIListLayout.AbsoluteContentSize.Y)
		end
	end

	columns.ChildAdded:Connect(changeSize)
	columns.ChildRemoved:Connect(changeSize)
	columns:GetPropertyChangedSignal("AbsoluteSize"):Connect(changeSize)

	local function updateCanvis()
		indicatorHolder.CanvasSize = columns.CanvasSize
		indicatorHolder.CanvasPosition = columns.CanvasPosition

		if indicatorHolder.CanvasPosition.Y > 0.5 then
			indicatorHolder.ClipsDescendants = true
		else
			indicatorHolder.ClipsDescendants = false
		end
	end

	columns:GetPropertyChangedSignal("CanvasSize"):Connect(updateCanvis)
	columns:GetPropertyChangedSignal("CanvasPosition"):Connect(updateCanvis)

	column(1, 20).Parent = columns
	columnButtons(20).Parent = columns

	return columns, indicatorHolder
end