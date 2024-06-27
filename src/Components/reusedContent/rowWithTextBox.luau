--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(placeholderText: string, name: string, layoutOrder: number?)
	local w = Instance.new("Frame")
	w.Name = name
	w.AnchorPoint = Vector2.new(0.5, 0.5)
	w.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	w.BorderSizePixel = 0
	w.LayoutOrder = layoutOrder
	w.Size = UDim2.new(1, 0, 0, 30) -- 30

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 5) -- 5
	uICorner.Parent = w

	local textBox = Instance.new("TextBox")
	textBox.Name = "TextBox"
	textBox.AnchorPoint = Vector2.new(0.5, 0.5)
	textBox.BackgroundTransparency = 1
	textBox.Position = UDim2.fromScale(0.5, 0.5)
	textBox.Size = UDim2.fromScale(1, 1)
	textBox.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textBox.TextScaled = true
	textBox.PlaceholderText = placeholderText
	textBox.Text = ""
	textBox.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textBox.TextSize = 25
	textBox.Parent = w

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 25
	uITextSizeConstraint.Parent = textBox

	return w
end