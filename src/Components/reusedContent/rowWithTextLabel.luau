--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(text: string, name: string, layoutOrder: number?)
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

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.TextScaled = true
	textLabel.Text = text
	textLabel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textLabel.TextSize = 25
	textLabel.Parent = w

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 25
	uITextSizeConstraint.Parent = textLabel

	return w
end