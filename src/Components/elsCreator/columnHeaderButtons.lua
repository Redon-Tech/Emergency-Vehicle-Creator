--[[
Redon Tech 2022
EVC V2
--]]

return function()
	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.BackgroundTransparency = 1
	buttons.LayoutOrder = 100000
	buttons.Size = UDim2.new(0, 37, 1, 0)

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = buttons

	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.BackgroundTransparency = 1
	controls.LayoutOrder = 1
	controls.Size = UDim2.new(1, 0, 0, 15)

	local addHolder = Instance.new("Frame")
	addHolder.Name = "AddHolder"
	addHolder.AnchorPoint = Vector2.new(0, 0.5)
	addHolder.BackgroundTransparency = 1
	addHolder.BorderSizePixel = 0
	addHolder.Position = UDim2.fromScale(0, 0.5)
	addHolder.Size = UDim2.fromScale(0.5, 1)

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
	add.Size = UDim2.fromOffset(11, 11)
	add.Parent = addHolder

	addHolder.Parent = controls

	local removeHolder = Instance.new("Frame")
	removeHolder.Name = "RemoveHolder"
	removeHolder.AnchorPoint = Vector2.new(1, 0.5)
	removeHolder.BackgroundTransparency = 1
	removeHolder.BorderSizePixel = 0
	removeHolder.Position = UDim2.fromScale(1, 0.5)
	removeHolder.Size = UDim2.fromScale(0.5, 1)

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
	remove.Size = UDim2.fromOffset(11, 11)
	remove.Parent = removeHolder

	removeHolder.Parent = controls

	controls.Parent = buttons

	local top = Instance.new("Frame")
	top.Name = "Top"
	top.AnchorPoint = Vector2.new(0.5, 0.5)
	top.BackgroundTransparency = 1
	top.BorderSizePixel = 0
	top.LayoutOrder = 0
	top.Size = UDim2.new(1, 0, 0, 15)
	top.Parent = buttons

	return buttons
end