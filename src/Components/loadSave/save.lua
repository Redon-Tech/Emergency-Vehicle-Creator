--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(saveNameString: string)
	local save = Instance.new("Frame")
	save.Name = saveNameString
	save.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	save.BorderSizePixel = 0
	save.Size = UDim2.new(1, 0, 0, 33)
	
	local uICorner = Instance.new("UICorner")
	uICorner.CornerRadius = UDim.new(0, 7)
	uICorner.Parent = save

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Padding = UDim.new(0, 3)
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = save

	local uIPadding = Instance.new("UIPadding")
	uIPadding.PaddingLeft = UDim.new(0, 7)
	uIPadding.PaddingRight = UDim.new(0, 7)
	uIPadding.Parent = save

	local saveName = Instance.new("TextBox")
	saveName.Name = "SaveName"
	saveName.BackgroundTransparency = 1
	saveName.Size = UDim2.new(0, 236, 0.95, 0)
	saveName.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	saveName.Text = saveNameString
	saveName.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	saveName.TextScaled = true
	saveName.TextSize = 40
	saveName.TextXAlignment = Enum.TextXAlignment.Left
	saveName.Parent = save

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.MaxTextSize = 40
	uITextSizeConstraint.Parent = saveName

	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.LayoutOrder = 2
	saveButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	saveButton.BorderSizePixel = 0
	saveButton.Size = UDim2.new(0, 67, 0.8, 0)
	saveButton.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	saveButton.Text = "Save"
	saveButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	saveButton.AutoButtonColor = false
	saveButton.TextScaled = true
	saveButton.TextWrapped = true
	saveButton.Parent = save

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 5)
	uICorner_2.Parent = saveButton

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = saveButton

	local uIPadding_2 = Instance.new("UIPadding")
	uIPadding_2.PaddingLeft = UDim.new(0, 5)
	uIPadding_2.PaddingRight = UDim.new(0, 5)
	uIPadding_2.Parent = saveButton

	local loadButton = Instance.new("TextButton")
	loadButton.Name = "LoadButton"
	loadButton.LayoutOrder = 3
	loadButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	loadButton.BorderSizePixel = 0
	loadButton.Size = UDim2.new(0, 67, 0.8, 0)
	loadButton.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	loadButton.Text = "Load"
	loadButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	loadButton.AutoButtonColor = false
	loadButton.TextScaled = true
	loadButton.TextWrapped = true
	loadButton.Parent = save

	local uICorner_3 = Instance.new("UICorner")
	uICorner_3.CornerRadius = UDim.new(0, 5)
	uICorner_3.Parent = loadButton

	local uITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_3.MaxTextSize = 25
	uITextSizeConstraint_3.Parent = loadButton

	local uIPadding_3 = Instance.new("UIPadding")
	uIPadding_3.PaddingLeft = UDim.new(0, 5)
	uIPadding_3.PaddingRight = UDim.new(0, 5)
	uIPadding_3.Parent = loadButton

	local exportButton = Instance.new("TextButton")
	exportButton.Name = "ExportButton"
	exportButton.LayoutOrder = 4
	exportButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	exportButton.BorderSizePixel = 0
	exportButton.Size = UDim2.new(0, 67, 0.8, 0)
	exportButton.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	exportButton.Text = "Export"
	exportButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	exportButton.AutoButtonColor = false
	exportButton.TextScaled = true
	exportButton.TextWrapped = true
	exportButton.Parent = save

	local uICorner_4 = Instance.new("UICorner")
	uICorner_4.CornerRadius = UDim.new(0, 5)
	uICorner_4.Parent = exportButton

	local uITextSizeConstraint_4 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_4.MaxTextSize = 25
	uITextSizeConstraint_4.Parent = exportButton

	local uIPadding_4 = Instance.new("UIPadding")
	uIPadding_4.PaddingLeft = UDim.new(0, 5)
	uIPadding_4.PaddingRight = UDim.new(0, 5)
	uIPadding_4.Parent = exportButton

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
	deleteButton.Parent = save

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

	saveButton.MouseEnter:Connect(function()
		local baseColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		saveButton.BackgroundColor3 = Color3.new(baseColor.R + 0.05, baseColor.G + 0.05, baseColor.B + 0.05)
		saveButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	saveButton.MouseLeave:Connect(function()
		saveButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		saveButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	loadButton.MouseEnter:Connect(function()
		local baseColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		loadButton.BackgroundColor3 = Color3.new(baseColor.R + 0.05, baseColor.G + 0.05, baseColor.B + 0.05)
		loadButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	loadButton.MouseLeave:Connect(function()
		loadButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		loadButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	exportButton.MouseEnter:Connect(function()
		local baseColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		exportButton.BackgroundColor3 = Color3.new(baseColor.R + 0.05, baseColor.G + 0.05, baseColor.B + 0.05)
		exportButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	exportButton.MouseLeave:Connect(function()
		exportButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		exportButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
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

	return save
end