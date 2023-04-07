--[[
Redon Tech 2023
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

	local textButton = Instance.new("TextButton")
	textButton.Name = "TextButton"
	textButton.AnchorPoint = Vector2.new(0.5, 0.5)
	textButton.BackgroundTransparency = 1
	textButton.Position = UDim2.fromScale(0.5, 0.5)
	textButton.Size = UDim2.fromScale(1, 1)
	textButton.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textButton.TextScaled = true
	textButton.Text = text
	textButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textButton.TextSize = 25
	textButton.Parent = w

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 25
	uITextSizeConstraint.Parent = textButton

	return w
end