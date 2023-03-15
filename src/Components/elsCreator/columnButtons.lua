--[[
Redon Tech 2022
EVC V2
--]]

local columnRow = require(script.Parent.columnRow)
local columnControls = require(script.Parent.columnControls)

return function(rows: number)
	local w = Instance.new("Frame")
	w.Name = "Buttons"
	w.BackgroundTransparency = 1
	w.LayoutOrder = 0
	w.Size = UDim2.new(0, 37.5, 1, 0) -- 75

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5) -- 10
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = w

	for i = 1, rows-1 do
		local row = columnRow(i)
		row.Parent = w
		row.BackgroundTransparency = 1
		row.UICorner:Destroy()
	end

	columnControls().Parent = w

	return w
end