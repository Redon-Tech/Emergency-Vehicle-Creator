--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(ColumnNumber: number)
	local w = Instance.new("Frame")
	w.Name = ColumnNumber
	w.LayoutOrder = ColumnNumber
	w.BackgroundTransparency = 1
	w.Size = UDim2.new(0, 37.5, 1, 0) -- 75

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5) -- 10
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = w

	local devider = Instance.new("Frame")
	devider.Name = "Devider"
	devider.BackgroundTransparency = 1
	devider.LayoutOrder = 1
	devider.Size = UDim2.new(1, 0, 0, 15) -- 30

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(35, 5) -- 50, 10
	frame.Parent = devider

	devider.Parent = w

	local top = Instance.new("Frame")
	top.Name = "Top"
	top.AnchorPoint = Vector2.new(0.5, 0.5)
	top.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	top.BorderSizePixel = 0
	top.LayoutOrder = 0
	top.Size = UDim2.new(1, 0, 0, 15) -- 30
	top.ZIndex = 3

	local textBox = Instance.new("TextBox")
	textBox.Name = "TextBox"
	textBox.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	textBox.PlaceholderText = "Light1"
	textBox.Text = ""
	textBox.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textBox.TextScaled = true
	textBox.TextWrapped = true
	textBox.AnchorPoint = Vector2.new(0.5, 0.5)
	textBox.BackgroundTransparency = 1
	textBox.Position = UDim2.fromScale(0.5, 0.5)
	textBox.Size = UDim2.fromScale(0.95, 1)
	textBox.Visible = false
	textBox.ZIndex = 4
	textBox.Parent = top

	local light1 = Instance.new("ImageLabel")
	light1.Name = "Light1"
	light1.Image = "rbxassetid://17838553865"
	light1.ImageTransparency = 0.2
	light1.ScaleType = Enum.ScaleType.Slice
	light1.SliceCenter = Rect.new(256, 256, 256, 256)
	light1.AnchorPoint = Vector2.new(0.5, 0.5)
	light1.BackgroundTransparency = 1
	light1.Position = UDim2.fromScale(0.5, 0.5)
	light1.Size = UDim2.new(1, 150, 1, 150)
	light1.ZIndex = 2
	light1.Parent = top
	light1.Visible = false

	local light = Instance.new("ImageLabel")
	light.Name = "Light"
	light.Image = "rbxassetid://17838553865"
	light.ScaleType = Enum.ScaleType.Slice
	light.SliceCenter = Rect.new(256, 256, 256, 256)
	light.AnchorPoint = Vector2.new(0.5, 0.5)
	light.BackgroundTransparency = 1
	light.Position = UDim2.fromScale(0.5, 0.5)
	light.Size = UDim2.new(1, 25, 1, 25)
	light.ZIndex = 2
	light.Parent = top
	light.Visible = false

	local light2 = Instance.new("ImageLabel")
	light2.Name = "Light2"
	light2.Image = "rbxassetid://17838553865"
	light2.ImageTransparency = 0.5
	light2.ScaleType = Enum.ScaleType.Slice
	light2.SliceCenter = Rect.new(256, 256, 256, 256)
	light2.AnchorPoint = Vector2.new(0.5, 0.5)
	light2.BackgroundTransparency = 1
	light2.Position = UDim2.fromScale(0.5, 0.5)
	light2.Size = UDim2.new(1, 200, 1, 200)
	light2.ZIndex = 2
	light2.Parent = top
	light2.Visible = false
	
	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 2.5) -- 5
	uICorner.Parent = top

	top.Parent = w

	return w
end