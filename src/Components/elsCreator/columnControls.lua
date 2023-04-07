--[[
Redon Tech 2023
EVC V2
--]]

return function()
	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.AnchorPoint = Vector2.new(0.5, 0.5)
	controls.BackgroundTransparency = 1
	controls.BorderSizePixel = 0
	controls.LayoutOrder = 1000000
	controls.Size = UDim2.new(1, 0, 0, 15) -- 30

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5) -- 10
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = controls

	local holder = Instance.new("Frame")
	holder.Name = "RemoveHolder"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 15) -- 30

	local remove = Instance.new("ImageButton")
	remove.Name = "RemoveButton"
	remove.Image = "rbxassetid://12788801841"
	remove.ScaleType = Enum.ScaleType.Fit
	remove.AnchorPoint = Vector2.new(0.5, 0.5)
	remove.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	remove.ImageTransparency = 0.5
	remove.BackgroundTransparency = 1
	remove.BorderSizePixel = 0
	remove.LayoutOrder = 1
	remove.Position = UDim2.fromScale(0.5, 0.5)
	remove.Size = UDim2.fromOffset(11.5, 11.5) -- 23, 23
	remove.Parent = holder

	holder.Parent = controls

	local holder1 = Instance.new("Frame")
	holder1.Name = "AddHolder"
	holder1.BackgroundTransparency = 1
	holder1.Size = UDim2.new(1, 0, 0, 15)

	local add = Instance.new("ImageButton")
	add.Name = "Add"
	add.Image = "rbxassetid://12788800986"
	add.ScaleType = Enum.ScaleType.Fit
	add.AnchorPoint = Vector2.new(0.5, 0.5)
	add.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	add.BackgroundTransparency = 1
	add.BorderSizePixel = 0
	add.LayoutOrder = 3
	add.Position = UDim2.fromScale(0.5, 0.5)
	add.Size = UDim2.fromOffset(11.5, 11.5)
	add.Parent = holder1

	holder1.Parent = controls

	return controls
end