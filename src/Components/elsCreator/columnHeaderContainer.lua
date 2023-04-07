--[[
Redon Tech 2023
EVC V2
--]]

local columnHeader = require(script.Parent.columnHeader)
local columnHeaderButtons = require(script.Parent.columnHeaderButtons)

return function()
	local columnHeaders = Instance.new("Frame")
	columnHeaders.Name = "ColumnHeaders"
	columnHeaders.AnchorPoint = Vector2.new(0.5, 0)
	columnHeaders.BackgroundTransparency = 1
	columnHeaders.Position = UDim2.new(0.5, 20, 0, 35) -- 70
	columnHeaders.Size = UDim2.fromOffset(37.5, 50) -- 75, 80
	columnHeaders.ZIndex = 2

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5) -- 10
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = columnHeaders

	columnHeader(1).Parent = columnHeaders
	columnHeaderButtons().Parent = columnHeaders

	local function changeSize()
		-- 75, 10, 80
		columnHeaders.Size = UDim2.fromOffset((37.5 * (#columnHeaders:GetChildren() - 1)) + (5 * (#columnHeaders:GetChildren() - 2)), 40)
	end

	columnHeaders.ChildAdded:Connect(changeSize)
	columnHeaders.ChildRemoved:Connect(changeSize)
	columnHeaders:GetPropertyChangedSignal("AbsoluteSize"):Connect(changeSize)

	return columnHeaders
end