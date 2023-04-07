--[[
Redon Tech 2023
EVC V2
--]]

return function(name:string, text: string)
	local exportOption = Instance.new("TextButton")
	exportOption.Name = name
	exportOption.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	exportOption.Text = text
	exportOption.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	exportOption.TextScaled = true
	exportOption.TextSize = 25
	exportOption.TextWrapped = true
	exportOption.AutoButtonColor = false
	exportOption.AnchorPoint = Vector2.new(0.5, 0)
	exportOption.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	exportOption.BorderSizePixel = 0
	exportOption.LayoutOrder = 1
	exportOption.Position = UDim2.fromScale(0.5, 0.13)
	exportOption.Size = UDim2.fromOffset(113, 33)

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 25
	uITextSizeConstraint.Parent = exportOption

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 7)
	uICorner.Parent = exportOption

	exportOption.MouseEnter:Connect(function()
		exportOption.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		exportOption.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	exportOption.MouseLeave:Connect(function()
		exportOption.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		exportOption.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	return exportOption
end