--[[
Redon Tech 2023-2024
EVC V2
--]]

local exportOption = require(script.Parent:WaitForChild("exportOption"))

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

	local selectExportOption = Instance.new("Frame")
	selectExportOption.Name = "SelectExportOption"
	selectExportOption.AnchorPoint = Vector2.new(0.5, 0.5)
	selectExportOption.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	selectExportOption.BorderSizePixel = 0
	selectExportOption.Position = UDim2.fromScale(0.5, 0.5)
	selectExportOption.Size = UDim2.fromOffset(350, 200)
	selectExportOption.Parent = mainContainer
	-- selectExportOption.Visible = false

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 10)
	UICorner.Parent = selectExportOption

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
	textLabel.Text = "Select Export Option"
	textLabel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textLabel.TextScaled = true
	textLabel.TextSize = 45
	
	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.MaxTextSize = 45
	uITextSizeConstraint.Parent = textLabel
	
	textLabel.Parent = selectExportOption

	local options = Instance.new("Frame")
	options.Name = "Options"
	options.AnchorPoint = Vector2.new(0.5, 1)
	options.BackgroundTransparency = 1
	options.Position = UDim2.fromScale(0.5, 0.95)
	options.Size = UDim2.new(1, 0, 0, 150)

	exportOption("ChassisPlugin", "Chassis Plugin").Parent = options
	exportOption("CustomCode", "Custom Code").Parent = options

	options.Parent = selectExportOption

	local uIGridLayout = Instance.new("UIGridLayout")
	uIGridLayout.Name = "UIGridLayout"
	uIGridLayout.CellPadding = UDim2.new(0, 7, 0, 7)
	uIGridLayout.CellSize = UDim2.new(0, 113, 0, 33)
	uIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIGridLayout.Parent = options

	local selection = Instance.new("Frame")
	selection.Name = "Selection"
	selection.AnchorPoint = Vector2.new(0.5, 0.5)
	selection.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	selection.BorderSizePixel = 0
	selection.Position = UDim2.fromScale(0.5, 0.5)
	selection.Size = UDim2.fromOffset(350, 150)
	selection.Parent = mainContainer
	selection.Visible = false

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 10)
	uICorner.Parent = selection

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.FontFace = Font.new(
	"rbxasset://fonts/families/Arial.json",
	Enum.FontWeight.Bold,
	Enum.FontStyle.Normal
	)
	textLabel.Text = "Select The Car You Want To Export To"
	textLabel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textLabel.TextScaled = true
	textLabel.TextSize = 45
	textLabel.TextWrapped = true
	textLabel.AnchorPoint = Vector2.new(0.5, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromScale(0.5, 0.1)
	textLabel.Size = UDim2.new(1, 0, 0, 30)

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 45
	uITextSizeConstraint.Parent = textLabel

	textLabel.Parent = selection

	local options = Instance.new("Frame")
	options.Name = "Options"
	options.AnchorPoint = Vector2.new(0.5, 1)
	options.BackgroundTransparency = 1
	options.Position = UDim2.fromScale(0.5, 0.9)
	options.Size = UDim2.new(1, 0, 0, 33)

	local selectButton = Instance.new("TextButton")
	selectButton.Name = "SelectButton"
	selectButton.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	selectButton.Text = "Select"
	selectButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	selectButton.TextScaled = true
	selectButton.TextSize = 25
	selectButton.TextWrapped = true
	selectButton.AutoButtonColor = false
	selectButton.AnchorPoint = Vector2.new(0.5, 0)
	selectButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
	selectButton.BorderSizePixel = 0
	selectButton.LayoutOrder = 1
	selectButton.Position = UDim2.fromScale(0.5, 0.13)
	selectButton.Size = UDim2.fromOffset(113, 33)

	local uITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint1.Name = "UITextSizeConstraint"
	uITextSizeConstraint1.MaxTextSize = 25
	uITextSizeConstraint1.Parent = selectButton

	local uICorner1 = Instance.new("UICorner")
	uICorner1.Name = "UICorner"
	uICorner1.CornerRadius = UDim.new(0, 7)
	uICorner1.Parent = selectButton

	selectButton.Parent = options

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	cancelButton.TextScaled = true
	cancelButton.TextSize = 25
	cancelButton.TextWrapped = true
	cancelButton.AutoButtonColor = false
	cancelButton.AnchorPoint = Vector2.new(0.5, 0)
	cancelButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	cancelButton.BorderSizePixel = 0
	cancelButton.LayoutOrder = 1
	cancelButton.Position = UDim2.fromScale(0.5, 0.13)
	cancelButton.Size = UDim2.fromOffset(113, 33)

	local uITextSizeConstraint2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint2.Name = "UITextSizeConstraint"
	uITextSizeConstraint2.MaxTextSize = 25
	uITextSizeConstraint2.Parent = cancelButton

	local uICorner2 = Instance.new("UICorner")
	uICorner2.Name = "UICorner"
	uICorner2.CornerRadius = UDim.new(0, 7)
	uICorner2.Parent = cancelButton

	cancelButton.Parent = options

	local uIGridLayout = Instance.new("UIGridLayout")
	uIGridLayout.Name = "UIGridLayout"
	uIGridLayout.CellPadding = UDim2.fromOffset(7, 7)
	uIGridLayout.CellSize = UDim2.fromOffset(113, 33)
	uIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIGridLayout.Parent = options

	options.Parent = selection

	local selection1 = Instance.new("TextLabel")
	selection1.Name = "Selection"
	selection1.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	selection1.RichText = true
	selection1.Text = "<b>Currently Selecting:</b> Nothing"
	selection1.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
	selection1.TextScaled = true
	selection1.TextSize = 45
	selection1.TextWrapped = true
	selection1.AnchorPoint = Vector2.new(0.5, 0.5)
	selection1.BackgroundTransparency = 1
	selection1.Position = UDim2.fromScale(0.5, 0.5)
	selection1.Size = UDim2.new(1, 0, 0, 30)

	local uITextSizeConstraint3 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint3.Name = "UITextSizeConstraint"
	uITextSizeConstraint3.MaxTextSize = 25
	uITextSizeConstraint3.Parent = selection1

	selection1.Parent = selection

	local chassisPluginExports = Instance.new("Frame")
	chassisPluginExports.Name = "ChassisPluginExports"
	chassisPluginExports.AnchorPoint = Vector2.new(0.5, 0.5)
	chassisPluginExports.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	chassisPluginExports.BorderSizePixel = 0
	chassisPluginExports.Position = UDim2.fromScale(0.5, 0.5)
	chassisPluginExports.Size = UDim2.fromOffset(600, 617)
	chassisPluginExports.Parent = mainContainer
	chassisPluginExports.Visible = false

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 10)
	UICorner.Parent = chassisPluginExports

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
	textLabel.Text = "Select Pattern To Export To"
	textLabel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textLabel.TextScaled = true
	textLabel.TextSize = 45
	
	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.MaxTextSize = 45
	uITextSizeConstraint.Parent = textLabel
	
	textLabel.Parent = chassisPluginExports

	local functionsHolder = Instance.new("ScrollingFrame")
	functionsHolder.Name = "FunctionsHolder"
	functionsHolder.AnchorPoint = Vector2.new(0.5, 0)
	functionsHolder.BackgroundTransparency = 1
	functionsHolder.BorderSizePixel = 0
	functionsHolder.Position = UDim2.fromScale(0.5, 0.16)
	functionsHolder.Size = UDim2.new(1, 0, 0, 38)
	functionsHolder.Parent = chassisPluginExports
	functionsHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
	functionsHolder.ClipsDescendants = true
	functionsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	functionsHolder.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	functionsHolder.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	functionsHolder.ScrollBarThickness = 5

	local uIListLayout_10 = Instance.new("UIListLayout")
	uIListLayout_10.Padding = UDim.new(0, 7)
	uIListLayout_10.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout_10.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout_10.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout_10.Parent = functionsHolder

	local createPatternHolder = Instance.new("Frame")
	createPatternHolder.Name = "CreatePatternHolder"
	createPatternHolder.AnchorPoint = Vector2.new(0.5, 0)
	createPatternHolder.BackgroundTransparency = 1
	createPatternHolder.Position = UDim2.fromScale(0.5, 0.1)
	createPatternHolder.Size = UDim2.new(1, 0, 0, 33)

	local uIListLayout_1 = Instance.new("UIListLayout")
	uIListLayout_1.Padding = UDim.new(0, 7)
	uIListLayout_1.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout_1.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout_1.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout_1.Parent = createPatternHolder

	local patternName = Instance.new("TextBox")
	patternName.Name = "PatternName"
	patternName.AnchorPoint = Vector2.new(0.5, 0)
	patternName.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	patternName.BorderSizePixel = 0
	patternName.LayoutOrder = 1
	patternName.Position = UDim2.fromScale(0.5, 0.13)
	patternName.Size = UDim2.fromOffset(233, 33)
	patternName.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	patternName.Text = ""
	patternName.PlaceholderText = "Pattern Number/Function Name"
	patternName.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	patternName.TextScaled = true
	patternName.TextSize = 25

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = patternName

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 7)
	uICorner_2.Parent = patternName

	patternName.Parent = createPatternHolder

	local createPattern = Instance.new("TextButton")
	createPattern.Name = "CreatePattern"
	createPattern.AnchorPoint = Vector2.new(0.5, 0)
	createPattern.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	createPattern.BorderSizePixel = 0
	createPattern.LayoutOrder = 1
	createPattern.Position = UDim2.fromScale(0.5, 0.13)
	createPattern.Size = UDim2.fromOffset(113, 33)
	createPattern.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	createPattern.Text = "Create Pattern"
	createPattern.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	createPattern.AutoButtonColor = false
	createPattern.TextScaled = true
	createPattern.TextSize = 25

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = createPattern

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 7)
	uICorner_2.Parent = createPattern

	createPattern.Parent = createPatternHolder

	local createFunction = Instance.new("TextButton")
	createFunction.Name = "CreateFunction"
	createFunction.AnchorPoint = Vector2.new(0.5, 0)
	createFunction.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	createFunction.BorderSizePixel = 0
	createFunction.LayoutOrder = 1
	createFunction.Position = UDim2.fromScale(0.5, 0.13)
	createFunction.Size = UDim2.fromOffset(113, 33)
	createFunction.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	createFunction.Text = "Create Function"
	createFunction.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	createFunction.AutoButtonColor = false
	createFunction.TextScaled = true
	createFunction.TextSize = 25

	local uITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint_2.MaxTextSize = 25
	uITextSizeConstraint_2.Parent = createFunction

	local uICorner_2 = Instance.new("UICorner")
	uICorner_2.CornerRadius = UDim.new(0, 7)
	uICorner_2.Parent = createFunction

	createFunction.Parent = createPatternHolder

	createPatternHolder.Parent = chassisPluginExports

	local exportsContainer = Instance.new("ScrollingFrame")
	exportsContainer.Name = "ExportsContainer"
	exportsContainer.AnchorPoint = Vector2.new(0.5, 1)
	exportsContainer.BackgroundTransparency = 1
	exportsContainer.Position = UDim2.fromScale(0.5, 0.96)
	exportsContainer.Size = UDim2.fromOffset(533, 450)
	exportsContainer.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	exportsContainer.CanvasSize = UDim2.new()
	exportsContainer.ScrollBarThickness = 5
	exportsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	exportsContainer.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	exportsContainer.VerticalScrollBarInset = Enum.ScrollBarInset.Always

	local uIListLayout_2 = Instance.new("UIListLayout")
	uIListLayout_2.Padding = UDim.new(0, 7)
	uIListLayout_2.FillDirection = Enum.FillDirection.Vertical
	uIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout_2.Parent = exportsContainer

	exportsContainer.Parent = chassisPluginExports

	local function updateSavesCanvas()
		exportsContainer.CanvasSize = UDim2.fromOffset(0, uIListLayout_2.AbsoluteContentSize.Y)
	end
	exportsContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSavesCanvas)
	uIListLayout_2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSavesCanvas)

	local function sortSavesCanvas()
		local children = {}
		for _, child in pairs(exportsContainer:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(children, child.Name)
			end
		end
		table.sort(children)

		for i=1, #children do
			exportsContainer:FindFirstChild(children[i]).LayoutOrder = i
		end
	end
	exportsContainer.ChildAdded:Connect(sortSavesCanvas)
	exportsContainer.ChildRemoved:Connect(sortSavesCanvas)

	local function updateCanvas()
		mainContainer.CanvasSize = UDim2.fromOffset(uIListLayout.AbsoluteContentSize.X, uIListLayout.AbsoluteContentSize.Y)
	end
	
	mainContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
	uIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

	createPattern.MouseEnter:Connect(function()
		createPattern.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		createPattern.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	createPattern.MouseLeave:Connect(function()
		createPattern.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		createPattern.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	createFunction.MouseEnter:Connect(function()
		createFunction.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		createFunction.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	createFunction.MouseLeave:Connect(function()
		createFunction.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		createFunction.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	selectButton.MouseEnter:Connect(function()
		selectButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
		selectButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	selectButton.MouseLeave:Connect(function()
		selectButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
		selectButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)

	cancelButton.MouseEnter:Connect(function()
		cancelButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		cancelButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	cancelButton.MouseLeave:Connect(function()
		cancelButton.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		cancelButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	return mainContainer
end