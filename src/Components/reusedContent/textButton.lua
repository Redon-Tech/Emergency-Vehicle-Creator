--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(Name: string, Position: number, Text: string, Color: Color3)
	local frame = Instance.new("Frame")
	frame.Name = Name
	frame.LayoutOrder = Position
	frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(0.0652, 0.75)
	frame.ZIndex = 3

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0.15, 0)
	uICorner.Parent = frame

	local text = Instance.new("TextButton")
	text.Name = "Text"
	text.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	text.Text = Text
	text.TextColor3 = Color
	text.TextScaled = true
	text.TextSize = 14
	text.TextWrapped = true
	text.AnchorPoint = Vector2.new(0.5, 0.5)
	text.BackgroundTransparency = 1
	text.Position = UDim2.fromScale(0.5, 0.525)
	text.Size = UDim2.fromScale(1, 1)
	text.ZIndex = 4

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 30
	uITextSizeConstraint.Parent = text

	text.Parent = frame

	frame.MouseEnter:Connect(function()
		if frame:GetAttribute("Active") ~= true then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
			text.TextColor3 = Color3.new(Color.R + 0.1, Color.G + 0.1, Color.B + 0.1)
		else
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
			text.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
		end
	end)

	frame.MouseLeave:Connect(function()
		if frame:GetAttribute("Active") ~= true then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
			text.TextColor3 = Color
		else
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
			text.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
		end
	end)

	return frame
end