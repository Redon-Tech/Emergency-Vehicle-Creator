--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(saveNameString: string)
	local export = Instance.new("Frame")
	export.Name = saveNameString
	export.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	export.BorderSizePixel = 0
	export.Size = UDim2.new(1, 0, 0, 33)
	
	local uICorner = Instance.new("UICorner")
	uICorner.CornerRadius = UDim.new(0, 7)
	uICorner.Parent = export

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Padding = UDim.new(0, 3)
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = export

	local uIPadding = Instance.new("UIPadding")
	uIPadding.PaddingLeft = UDim.new(0, 7)
	uIPadding.PaddingRight = UDim.new(0, 7)
	uIPadding.Parent = export

	local exportName = Instance.new("TextLabel")
	exportName.Name = "ExportName"
	exportName.BackgroundTransparency = 1
	exportName.Size = UDim2.new(0, 310, 0.95, 0)
	exportName.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	exportName.Text = saveNameString
	exportName.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	exportName.TextScaled = true
	exportName.TextSize = 40
	exportName.TextXAlignment = Enum.TextXAlignment.Left
	exportName.Parent = export

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.MaxTextSize = 40
	uITextSizeConstraint.Parent = exportName

	local overwriteButton = Instance.new("TextButton")
	overwriteButton.Name = "OverwriteButton"
	overwriteButton.LayoutOrder = 2
	overwriteButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	overwriteButton.BorderSizePixel = 0
	overwriteButton.Size = UDim2.new(0, 67, 0.8, 0)
	overwriteButton.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	overwriteButton.Text = "Overwrite"
	overwriteButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	overwriteButton.AutoButtonColor = false
	overwriteButton.TextScaled = true
	overwriteButton.TextWrapped = true
	overwriteButton.Parent = export

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 5)
	uICorner_2.Parent = overwriteButton

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = overwriteButton

	local uIPadding_2 = Instance.new("UIPadding")
	uIPadding_2.PaddingLeft = UDim.new(0, 5)
	uIPadding_2.PaddingRight = UDim.new(0, 5)
	uIPadding_2.Parent = overwriteButton

	local saveToButton = Instance.new("TextButton")
	saveToButton.Name = "AddToButton"
	saveToButton.LayoutOrder = 3
	saveToButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	saveToButton.BorderSizePixel = 0
	saveToButton.Size = UDim2.new(0, 67, 0.8, 0)
	saveToButton.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	saveToButton.Text = "Add To"
	saveToButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	saveToButton.AutoButtonColor = false
	saveToButton.TextScaled = true
	saveToButton.TextWrapped = true
	saveToButton.Parent = export

	local uICorner_3 = Instance.new("UICorner")
	uICorner_3.CornerRadius = UDim.new(0, 5)
	uICorner_3.Parent = saveToButton

	local uITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_3.MaxTextSize = 25
	uITextSizeConstraint_3.Parent = saveToButton

	local uIPadding_3 = Instance.new("UIPadding")
	uIPadding_3.PaddingLeft = UDim.new(0, 5)
	uIPadding_3.PaddingRight = UDim.new(0, 5)
	uIPadding_3.Parent = saveToButton

	local deleteButton = Instance.new("TextButton")
	deleteButton.Name = "DeleteButton"
	deleteButton.LayoutOrder = 5
	deleteButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	deleteButton.BorderSizePixel = 0
	deleteButton.Size = UDim2.new(0, 67, 0.8, 0)
	deleteButton.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	deleteButton.Text = "Delete"
	deleteButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	deleteButton.AutoButtonColor = false
	deleteButton.TextScaled = true
	deleteButton.TextWrapped = true
	deleteButton.Parent = export

	local uICorner_5 = Instance.new("UICorner")
	uICorner_5.CornerRadius = UDim.new(0, 5)
	uICorner_5.Parent = deleteButton

	local uITextSizeConstraint_5 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_5.MaxTextSize = 25
	uITextSizeConstraint_5.Parent = deleteButton

	local uIPadding_5 = Instance.new("UIPadding")
	uIPadding_5.PaddingLeft = UDim.new(0, 5)
	uIPadding_5.PaddingRight = UDim.new(0, 5)
	uIPadding_5.Parent = deleteButton

	overwriteButton.MouseEnter:Connect(function()
		local baseColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		overwriteButton.BackgroundColor3 = Color3.new(baseColor.R + 0.05, baseColor.G + 0.05, baseColor.B + 0.05)
		overwriteButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	overwriteButton.MouseLeave:Connect(function()
		overwriteButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		overwriteButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	saveToButton.MouseEnter:Connect(function()
		local baseColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		saveToButton.BackgroundColor3 = Color3.new(baseColor.R + 0.05, baseColor.G + 0.05, baseColor.B + 0.05)
		saveToButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	saveToButton.MouseLeave:Connect(function()
		saveToButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		saveToButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	deleteButton.MouseEnter:Connect(function()
		local baseColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		deleteButton.BackgroundColor3 = Color3.new(baseColor.R + 0.05, baseColor.G + 0.05, baseColor.B + 0.05)
		deleteButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	deleteButton.MouseLeave:Connect(function()
		deleteButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		deleteButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	return export
end