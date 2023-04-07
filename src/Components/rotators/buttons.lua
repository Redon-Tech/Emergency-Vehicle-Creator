--[[
Redon Tech 2023
EVC V2
--]]

return function(buttons: Frame)
	local controls = Instance.new("Frame")
	controls.Name = "Controls"
	controls.AnchorPoint = Vector2.new(0.5, 0.5)
	controls.BackgroundTransparency = 1
	controls.BorderSizePixel = 0
	controls.LayoutOrder = 1e+04
	controls.Size = UDim2.new(1, 0, 0, 100)

	local uIListLayout1 = Instance.new("UIListLayout")
	uIListLayout1.Name = "UIListLayout"
	uIListLayout1.Padding = UDim.new(0, 5)
	uIListLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout1.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout1.Parent = controls

	local removeHolder = Instance.new("Frame")
	removeHolder.Name = "RemoveHolder"
	removeHolder.BackgroundTransparency = 1
	removeHolder.Size = UDim2.new(1, 0, 0, 30)

	local remove = Instance.new("ImageButton")
	remove.Name = "RemoveButton"
	remove.Image = "rbxassetid://12788801841"
	remove.ScaleType = Enum.ScaleType.Fit
	remove.AnchorPoint = Vector2.new(0.5, 0.5)
	remove.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	remove.ImageTransparency = 0.2
	remove.BackgroundTransparency = 1
	remove.LayoutOrder = 1
	remove.Position = UDim2.fromScale(0.5, 0.5)
	remove.Size = UDim2.fromOffset(23, 23)
	remove.Parent = removeHolder

	removeHolder.Parent = controls

	local addHolder = Instance.new("Frame")
	addHolder.Name = "AddHolder"
	addHolder.BackgroundTransparency = 1
	addHolder.Size = UDim2.new(1, 0, 0, 30)

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
	add.Size = UDim2.fromOffset(23, 23)
	add.Parent = addHolder

	addHolder.Parent = controls

	controls.Parent = buttons

	local topControls = Instance.new("Frame")
	topControls.Name = "TopControls"
	topControls.AnchorPoint = Vector2.new(0.5, 0.5)
	topControls.BackgroundTransparency = 1
	topControls.BorderSizePixel = 0
	topControls.LayoutOrder = -1
	topControls.Size = UDim2.new(1, 0, 0, 30)

	local uIListLayout2 = Instance.new("UIListLayout")
	uIListLayout2.Name = "UIListLayout"
	uIListLayout2.Padding = UDim.new(0, 10)
	uIListLayout2.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout2.Parent = topControls

	local removeHolder1 = Instance.new("Frame")
	removeHolder1.Name = "RemoveHolder"
	removeHolder1.BackgroundTransparency = 1
	removeHolder1.Size = UDim2.fromOffset(23, 30)

	local remove1 = Instance.new("ImageButton")
	remove1.Name = "RemoveButton"
	remove1.Image = "rbxassetid://12788801841"
	remove1.ScaleType = Enum.ScaleType.Fit
	remove1.AnchorPoint = Vector2.new(0.5, 0.5)
	remove1.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	remove1.ImageTransparency = 0.2
	remove1.BackgroundTransparency = 1
	remove1.LayoutOrder = 1
	remove1.Position = UDim2.fromScale(0.5, 0.5)
	remove1.Size = UDim2.fromOffset(23, 23)
	remove1.Parent = removeHolder1

	removeHolder1.Parent = topControls

	local addHolder1 = Instance.new("Frame")
	addHolder1.Name = "AddHolder"
	addHolder1.BackgroundTransparency = 1
	addHolder1.Size = UDim2.fromOffset(23, 30)

	local add1 = Instance.new("ImageButton")
	add1.Name = "Add"
	add1.Image = "rbxassetid://12788800986"
	add1.ScaleType = Enum.ScaleType.Fit
	add1.AnchorPoint = Vector2.new(0.5, 0.5)
	add1.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	add1.BackgroundTransparency = 1
	add1.BorderSizePixel = 0
	add1.LayoutOrder = 3
	add1.Position = UDim2.fromScale(0.5, 0.5)
	add1.Size = UDim2.fromOffset(23, 23)
	add1.Parent = addHolder1

	addHolder1.Parent = topControls

	topControls.Parent = buttons

	local topFill = Instance.new("Frame")
	topFill.Name = "TopFill"
	topFill.AnchorPoint = Vector2.new(0.5, 1)
	topFill.BackgroundTransparency = 1
	topFill.BorderSizePixel = 0
	topFill.Position = UDim2.fromScale(0.5, 0.251)
	topFill.Size = UDim2.new(1, 0, 0, 130)
	topFill.Parent = buttons
end