--[[
Redon Tech 2023
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

	local saveName = Instance.new("TextLabel")
	saveName.Name = "SaveName"
	saveName.BackgroundTransparency = 1
	saveName.Size = UDim2.new(0, 363, 0.95, 0)
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
	
	loadButton.MouseEnter:Connect(function()
		local baseColor = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		loadButton.BackgroundColor3 = Color3.new(baseColor.R + 0.05, baseColor.G + 0.05, baseColor.B + 0.05)
		loadButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	loadButton.MouseLeave:Connect(function()
		loadButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
		loadButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	return save
end