--[[
Redon Tech 2023
EVC V2
--]]

return function(columnName: string, columnNumber: number)
	local w = Instance.new("Frame")
	w.Name = columnName
	w.BackgroundTransparency = 1
	w.LayoutOrder = columnNumber
	w.Size = UDim2.new(0, 75, 1, 0)

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = w

	return w
end