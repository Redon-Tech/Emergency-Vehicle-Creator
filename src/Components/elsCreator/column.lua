--[[
Redon Tech 2022
EVC V2
--]]

local columnRow = require(script.Parent.columnRow)

return function(columnNumber: number, rows: number)
	local w = Instance.new("Frame")
	w.Name = columnNumber
	w.BackgroundTransparency = 1
	w.LayoutOrder = columnNumber
	w.Size = UDim2.new(0, 37.5, 1, 0) -- 75

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5) -- 10
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = w

	for i = 1, rows do
		columnRow(i).Parent = w
	end

	return w
end