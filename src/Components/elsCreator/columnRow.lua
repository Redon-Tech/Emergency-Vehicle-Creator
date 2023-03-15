--[[
Redon Tech 2022
EVC V2
--]]

return function(rowNumber: number)
	local w = Instance.new("Frame")
	w.Name = rowNumber
	w.AnchorPoint = Vector2.new(0.5, 0.5)
	w.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	w.BorderSizePixel = 0
	w.LayoutOrder = rowNumber
	w.Size = UDim2.new(1, 0, 0, 15) -- 30

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 2.5) -- 5
	uICorner.Parent = w

	return w
end