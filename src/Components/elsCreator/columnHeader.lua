--[[
Redon Tech 2022
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
	top.Size = UDim2.new(1, 0, 0, 15) -- 30

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

	local light = Instance.new("ImageLabel")
	light.Name = "Light"
	light.Image = "rbxassetid://8081553398"
	light.ImageColor3 = Color3.fromRGB(47, 71, 255)
	light.AnchorPoint = Vector2.new(0.5, 0.5)
	light.BackgroundTransparency = 1
	light.Position = UDim2.fromScale(0.5, 0.5)
	light.Size = UDim2.fromScale(1.25, 1.75)
	light.Visible = false
	light.ZIndex = 2
	light.Parent = top

	local light2 = Instance.new("ImageLabel")
	light2.Name = "Light2"
	light2.Image = "http://www.roblox.com/asset/?id=9957617181"
	light2.ImageColor3 = Color3.fromRGB(47, 71, 255)
	light2.ScaleType = Enum.ScaleType.Slice
	light2.SliceCenter = Rect.new(244, 256, 244, 256)
	light2.SliceScale = 0.05
	light2.AnchorPoint = Vector2.new(0.5, 0.5)
	light2.BackgroundTransparency = 1
	light2.Position = UDim2.fromScale(0.5, 0.5)
	light2.Size = UDim2.fromScale(1.25, 1.5)
	light2.Visible = false
	light2.ZIndex = 2
	light2.Parent = top

	local light1 = Instance.new("ImageLabel")
	light1.Name = "Light1"
	light1.Image = "rbxassetid://2468100097"
	light1.ImageColor3 = Color3.fromRGB(47, 71, 255)
	light1.AnchorPoint = Vector2.new(0.5, 0.5)
	light1.BackgroundTransparency = 1
	light1.Position = UDim2.fromScale(0.5, 0.5)
	light1.Size = UDim2.fromScale(2, 4)
	light1.Visible = false
	light1.ZIndex = 2
	light1.Parent = top

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 2.5) -- 5
	uICorner.Parent = top

	top.Parent = w

	return w
end