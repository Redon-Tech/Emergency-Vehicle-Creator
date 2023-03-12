--[[
Redon Tech 2022
WS V2
--]]

return function()
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	topBar.BorderSizePixel = 0
	topBar.Position = UDim2.fromScale(0.5, 0)
	topBar.Size = UDim2.fromScale(1, 0.046)
	topBar.ZIndex = 3

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	title.Text = "Emergency Vehicle Creator"
	title.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	title.TextScaled = true
	title.TextSize = 30
	title.AnchorPoint = Vector2.new(0, 0.5)
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0, 0.5)
	title.Size = UDim2.fromScale(0.209, 1)
	title.ZIndex = 4

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 35
	uITextSizeConstraint.Parent = title

	title.Parent = topBar

	local centerContainer = Instance.new("Frame")
	centerContainer.Name = "CenterContainer"
	centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	centerContainer.BackgroundTransparency = 1
	centerContainer.Position = UDim2.fromScale(0.5, 0.5)
	centerContainer.Size = UDim2.fromScale(1, 1)
	centerContainer.ZIndex = 4

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0.00521, 0)
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.Parent = centerContainer

	centerContainer.Parent = topBar

	local rightContainer = Instance.new("Frame")
	rightContainer.Name = "RightContainer"
	rightContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	rightContainer.BackgroundTransparency = 1
	rightContainer.Position = UDim2.fromScale(0.5, 0.5)
	rightContainer.Size = UDim2.fromScale(1, 1)
	rightContainer.ZIndex = 4

	local uIListLayout1 = Instance.new("UIListLayout")
	uIListLayout1.Name = "UIListLayout"
	uIListLayout1.Padding = UDim.new(0.00521, 0)
	uIListLayout1.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Right
	uIListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout1.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout1.Parent = rightContainer

	rightContainer.Parent = topBar

	return topBar
end