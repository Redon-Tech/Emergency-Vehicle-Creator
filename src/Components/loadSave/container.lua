--[[
Redon Tech 2023
EVC V2
--]]

return function()
	local mainContainer = Instance.new("ScrollingFrame")
	mainContainer.Name = "MainContainer"
	mainContainer.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	mainContainer.CanvasSize = UDim2.new()
	mainContainer.ScrollBarThickness = 5
	mainContainer.ScrollingDirection = Enum.ScrollingDirection.XY
	mainContainer.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.BackgroundTransparency = 1
	mainContainer.BorderSizePixel = 0
	mainContainer.Position = UDim2.fromScale(0.5, 0.5)
	mainContainer.Selectable = false
	mainContainer.Size = UDim2.fromScale(1, 1)

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.Parent = mainContainer

	local mainLoadSave = Instance.new("Frame")
	mainLoadSave.Name = "MainLoadSave"
	mainLoadSave.AnchorPoint = Vector2.new(0.5, 0.5)
	mainLoadSave.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	mainLoadSave.BorderSizePixel = 0
	mainLoadSave.Position = UDim2.fromScale(0.5, 0.5)
	mainLoadSave.Size = UDim2.fromOffset(600, 617)
	mainLoadSave.Parent = mainContainer

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 10)
	UICorner.Parent = mainLoadSave

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0.5, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromScale(0.5, 0.02)
	textLabel.Size = UDim2.new(1, 0, 0, 30)
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = "Load/Save"
	textLabel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textLabel.TextScaled = true
	textLabel.TextSize = 45
	
	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.MaxTextSize = 45
	uITextSizeConstraint.Parent = textLabel
	
	textLabel.Parent = mainLoadSave

	local controlsHolder = Instance.new("Frame")
	controlsHolder.Name = "ControlsHolder"
	controlsHolder.AnchorPoint = Vector2.new(0.5, 0)
	controlsHolder.BackgroundTransparency = 1
	controlsHolder.Position = UDim2.fromScale(0.5, 0.1)
	controlsHolder.Size = UDim2.new(1, 0, 0, 33)

	local uIListLayout_1 = Instance.new("UIListLayout")
	uIListLayout_1.Padding = UDim.new(0, 7)
	uIListLayout_1.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout_1.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout_1.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout_1.Parent = controlsHolder

	local saveName = Instance.new("TextBox")
	saveName.Name = "SaveName"
	saveName.AnchorPoint = Vector2.new(0.5, 0)
	saveName.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	saveName.BorderSizePixel = 0
	saveName.LayoutOrder = 1
	saveName.Position = UDim2.fromScale(0.5, 0.13)
	saveName.Size = UDim2.fromOffset(233, 33)
	saveName.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	saveName.Text = ""
	saveName.PlaceholderText = "Save Name"
	saveName.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	saveName.TextScaled = true
	saveName.TextSize = 25

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = saveName

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 7)
	uICorner_2.Parent = saveName

	saveName.Parent = controlsHolder

	local createSave = Instance.new("TextButton")
	createSave.Name = "CreateSave"
	createSave.AnchorPoint = Vector2.new(0.5, 0)
	createSave.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	createSave.BorderSizePixel = 0
	createSave.LayoutOrder = 1
	createSave.Position = UDim2.fromScale(0.5, 0.13)
	createSave.Size = UDim2.fromOffset(113, 33)
	createSave.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	createSave.Text = "Create Save"
	createSave.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	createSave.AutoButtonColor = false
	createSave.TextScaled = true
	createSave.TextSize = 25

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = createSave

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 7)
	uICorner_2.Parent = createSave

	createSave.Parent = controlsHolder

	local importSave = Instance.new("TextButton")
	importSave.Name = "ImportSave"
	importSave.AnchorPoint = Vector2.new(0.5, 0)
	importSave.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	importSave.BorderSizePixel = 0
	importSave.LayoutOrder = 1
	importSave.Position = UDim2.fromScale(0.5, 0.13)
	importSave.Size = UDim2.fromOffset(113, 33)
	importSave.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	importSave.Text = "Import Save"
	importSave.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	importSave.AutoButtonColor = false
	importSave.TextScaled = true
	importSave.TextSize = 25

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = importSave

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 7)
	uICorner_2.Parent = importSave

	importSave.Parent = controlsHolder

	controlsHolder.Parent = mainLoadSave

	local savesContainer = Instance.new("ScrollingFrame")
	savesContainer.Name = "SavesContainer"
	savesContainer.AnchorPoint = Vector2.new(0.5, 1)
	savesContainer.BackgroundTransparency = 1
	savesContainer.Position = UDim2.fromScale(0.5, 0.96)
	savesContainer.Size = UDim2.fromOffset(533, 467)
	savesContainer.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	savesContainer.CanvasSize = UDim2.new()
	savesContainer.ScrollBarThickness = 5
	savesContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	savesContainer.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	savesContainer.VerticalScrollBarInset = Enum.ScrollBarInset.Always

	local uIListLayout_2 = Instance.new("UIListLayout")
	uIListLayout_2.Padding = UDim.new(0, 7)
	uIListLayout_2.FillDirection = Enum.FillDirection.Vertical
	uIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout_2.Parent = savesContainer

	savesContainer.Parent = mainLoadSave

	local mainLegacySaves = Instance.new("Frame")
	mainLegacySaves.Name = "MainLegacySaves"
	mainLegacySaves.AnchorPoint = Vector2.new(0.5, 0.5)
	mainLegacySaves.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	mainLegacySaves.BorderSizePixel = 0
	mainLegacySaves.Position = UDim2.fromScale(0.5, 0.5)
	mainLegacySaves.Size = UDim2.fromOffset(500, 617)
	mainLegacySaves.Parent = mainContainer

	local uICorner_3 = Instance.new("UICorner")
	uICorner_3.CornerRadius = UDim.new(0, 10)
	uICorner_3.Parent = mainLegacySaves

	local textLabel_2 = Instance.new("TextLabel")
	textLabel_2.Name = "TextLabel"
	textLabel_2.AnchorPoint = Vector2.new(0.5, 0)
	textLabel_2.BackgroundTransparency = 1
	textLabel_2.Position = UDim2.fromScale(0.5, 0.02)
	textLabel_2.Size = UDim2.new(1, 0, 0, 30)
	textLabel_2.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel_2.Text = "Legacy Saves"
	textLabel_2.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textLabel_2.TextScaled = true
	textLabel_2.TextSize = 45
	
	local uITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_3.MaxTextSize = 45
	uITextSizeConstraint_3.Parent = textLabel_2
	
	textLabel_2.Parent = mainLegacySaves

	local hideLegacySaves = Instance.new("TextButton")
	hideLegacySaves.Name = "HideLegacySaves"
	hideLegacySaves.BackgroundTransparency = 1
	hideLegacySaves.Position = UDim2.fromScale(0.01, 0.005)
	hideLegacySaves.Size = UDim2.new(0.25, 0, 0, 15)
	hideLegacySaves.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	hideLegacySaves.Text = "Hide Legacy Saves"
	hideLegacySaves.TextXAlignment = Enum.TextXAlignment.Left
	hideLegacySaves.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	hideLegacySaves.TextScaled = true
	hideLegacySaves.TextSize = 12
	
	local uITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_3.MaxTextSize = 12
	uITextSizeConstraint_3.Parent = hideLegacySaves
	
	hideLegacySaves.Parent = mainLegacySaves

	local showLegacySaves = Instance.new("TextButton")
	showLegacySaves.Name = "ShowLegacySaves"
	showLegacySaves.BackgroundTransparency = 1
	showLegacySaves.AnchorPoint = Vector2.new(1, 1)
	showLegacySaves.Position = UDim2.fromScale(.995, .999)
	showLegacySaves.Size = UDim2.new(0.25, 0, 0, 15)
	showLegacySaves.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	showLegacySaves.Text = "Show Legacy Saves"
	showLegacySaves.TextXAlignment = Enum.TextXAlignment.Right
	showLegacySaves.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	showLegacySaves.TextScaled = true
	showLegacySaves.TextSize = 12
	
	local uITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_3.MaxTextSize = 12
	uITextSizeConstraint_3.Parent = showLegacySaves
	
	showLegacySaves.Parent = mainLoadSave

	local importLegacySaves = Instance.new("TextButton")
	importLegacySaves.Name = "ImportLegacySaves"
	importLegacySaves.BackgroundTransparency = 1
	importLegacySaves.AnchorPoint = Vector2.new(.5, 1)
	importLegacySaves.Position = UDim2.fromScale(0.5, 1)
	importLegacySaves.Size = UDim2.new(0.25, 0, 0, 15)
	importLegacySaves.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	importLegacySaves.Text = "Import Legacy Saves"
	importLegacySaves.TextXAlignment = Enum.TextXAlignment.Center
	importLegacySaves.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	importLegacySaves.TextScaled = true
	importLegacySaves.TextSize = 12
	
	local uITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_3.MaxTextSize = 12
	uITextSizeConstraint_3.Parent = importLegacySaves
	
	importLegacySaves.Parent = mainLegacySaves

	local legacySavesContainer = Instance.new("ScrollingFrame")
	legacySavesContainer.Name = "SavesContainer"
	legacySavesContainer.AnchorPoint = Vector2.new(0.5, 1)
	legacySavesContainer.BackgroundTransparency = 1
	legacySavesContainer.Position = UDim2.fromScale(0.5, 0.96)
	legacySavesContainer.Size = UDim2.fromOffset(450, 467)
	legacySavesContainer.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	legacySavesContainer.CanvasSize = UDim2.new()
	legacySavesContainer.ScrollBarThickness = 5
	legacySavesContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	legacySavesContainer.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	legacySavesContainer.VerticalScrollBarInset = Enum.ScrollBarInset.Always

	local uIListLayout_3 = Instance.new("UIListLayout")
	uIListLayout_3.Padding = UDim.new(0, 7)
	uIListLayout_3.FillDirection = Enum.FillDirection.Vertical
	uIListLayout_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout_3.Parent = legacySavesContainer
	
	legacySavesContainer.Parent = mainLegacySaves

	local function updateSavesCanvas()
		savesContainer.CanvasSize = UDim2.fromOffset(0, uIListLayout_2.AbsoluteContentSize.Y)
	end
	savesContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSavesCanvas)
	uIListLayout_2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSavesCanvas)

	local function sortSavesCanvas()
		local children = {}
		for _, child in pairs(savesContainer:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(children, child.Name)
			end
		end
		table.sort(children)

		for i=1, #children do
			savesContainer:FindFirstChild(children[i]).LayoutOrder = i
		end
	end
	savesContainer.ChildAdded:Connect(sortSavesCanvas)
	savesContainer.ChildRemoved:Connect(sortSavesCanvas)

	local function updateLegacySavesCanvas()
		savesContainer.CanvasSize = UDim2.fromOffset(0, uIListLayout_2.AbsoluteContentSize.Y)
	end
	legacySavesContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLegacySavesCanvas)
	uIListLayout_3:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateLegacySavesCanvas)

	local function sortLegacySavesCanvas()
		local children = {}
		for _, child in pairs(legacySavesContainer:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(children, child.Name)
			end
		end
		table.sort(children)

		for i=1, #children do
			legacySavesContainer:FindFirstChild(children[i]).LayoutOrder = i
		end
	end
	legacySavesContainer.ChildAdded:Connect(sortLegacySavesCanvas)
	legacySavesContainer.ChildRemoved:Connect(sortLegacySavesCanvas)

	local function updateCanvas()
		mainContainer.CanvasSize = UDim2.fromOffset(uIListLayout.AbsoluteContentSize.X, uIListLayout.AbsoluteContentSize.Y)
	end
	
	mainContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
	uIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

	createSave.MouseEnter:Connect(function()
		createSave.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		createSave.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	createSave.MouseLeave:Connect(function()
		createSave.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		createSave.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	importSave.MouseEnter:Connect(function()
		importSave.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		importSave.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	importSave.MouseLeave:Connect(function()
		importSave.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		importSave.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	return mainContainer
end