--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(functionNameStringWithSpaces: string, functionNameStringWithoutSpaces: string)
	local functionButton = Instance.new("TextButton")
	functionButton.Name = functionNameStringWithoutSpaces
	functionButton.AnchorPoint = Vector2.new(0.5, 0)
	functionButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	functionButton.BorderSizePixel = 0
	functionButton.LayoutOrder = 1
	functionButton.Position = UDim2.fromScale(0.5, 0.13)
	functionButton.Size = UDim2.fromOffset(113, 33)
	functionButton.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	functionButton.Text = functionNameStringWithSpaces
	functionButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	functionButton.AutoButtonColor = false
	functionButton.TextScaled = true
	functionButton.TextSize = 25

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = functionButton

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 7)
	uICorner_2.Parent = functionButton

	functionButton.MouseEnter:Connect(function()
		if functionButton:GetAttribute("Selected") == true then return end
		functionButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		functionButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	functionButton.MouseLeave:Connect(function()
		if functionButton:GetAttribute("Selected") == true then return end
		functionButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		functionButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	functionButton:GetAttributeChangedSignal("Selected"):Connect(function()
		if functionButton:GetAttribute("Selected") == true then
			functionButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
			functionButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
		else
			functionButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
			functionButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		end
	end)

	return functionButton
end