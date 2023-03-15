--[[
Redon Tech 2022
EVC V2
--]]

return function(Name: string, Position: number, Text: string, Size: number, Underline: boolean)
	local active = false

	local TextButton = Instance.new("TextButton")
	TextButton.Name = Name
	TextButton.LayoutOrder = Position
	TextButton.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	TextButton.Text = Text
	TextButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	TextButton.TextScaled = true
	TextButton.TextSize = 14
	TextButton.TextWrapped = true
	TextButton.BackgroundTransparency = 1
	TextButton.LayoutOrder = 1
	TextButton.Size = UDim2.fromScale(if Size then Size else 0.104, 0.6)
	TextButton.ZIndex = 4

	if Underline then
		local frame = Instance.new("Frame")
		frame.Name = "Underline"
		frame.AnchorPoint = Vector2.new(0.5, 1)
		frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
		frame.BorderSizePixel = 0
		frame.Position = UDim2.fromScale(0.5, 1.1)
		frame.Size = UDim2.fromScale(1, 0.1)
		frame.Visible = false
		frame.Parent = TextButton
		frame.ZIndex = 4
	end

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 30
	uITextSizeConstraint.Parent = TextButton

	local function setEnabled(value: boolean)
		TextButton.TextColor3 = if value then settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton) else settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		if Underline then
			TextButton.Underline.Visible = value
		end
		active = value
	end

	TextButton.MouseEnter:Connect(function()
		TextButton.BackgroundColor3 = if active then settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover) else settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		if Underline then
			TextButton.Underline.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
		end
	end)

	TextButton.MouseLeave:Connect(function()
		TextButton.BackgroundColor3 = if active then settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton) else settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		if Underline then
			TextButton.Underline.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
		end
	end)

	return {TextButton = TextButton, setEnabled = setEnabled}
end