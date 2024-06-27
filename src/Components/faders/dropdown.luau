--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(colors: { number:Color3 }, colorLabels: { number:string })
	local color = Instance.new("ScrollingFrame")
	color.Name = "Color"
	color.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	color.CanvasSize = UDim2.new()
	color.ScrollBarThickness = 5
	color.ScrollingDirection = Enum.ScrollingDirection.Y
	color.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	color.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	color.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
	color.AnchorPoint = Vector2.new(0.5, 0)
	color.BackgroundColor3 = Color3.fromRGB(64, 64, 64)
	color.BorderSizePixel = 0
	color.LayoutOrder = 1
	color.Position = UDim2.new(0.5, 0, 0, 170)
	color.Size = UDim2.new(1, 0, 0, 100)
	color.ZIndex = 2
	color.Visible = false

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 5)
	uICorner.Parent = color

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = color

	local function canvasSize()
		color.CanvasSize = UDim2.fromOffset(0, uIListLayout.AbsoluteContentSize.Y)
	end
	uIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(canvasSize)

	for i: number,v: Color3 in pairs(colors) do
		local textButton = Instance.new("TextButton")
		textButton.Name = colorLabels[i]
		textButton.FontFace = Font.new(
			"rbxasset://fonts/families/Arial.json",
			Enum.FontWeight.Bold,
			Enum.FontStyle.Normal
		)
		textButton.Text = colorLabels[i]
		textButton.TextColor3 = v
		textButton.TextScaled = true
		textButton.TextSize = 14
		textButton.TextWrapped = true
		textButton.Active = true
		textButton.AnchorPoint = Vector2.new(0.5, 0.5)
		textButton.BackgroundTransparency = 1
		textButton.Position = UDim2.fromScale(0.5, 0.5)
		textButton.Selectable = true
		textButton.Size = UDim2.new(1, 0, 0, 15)
		textButton.ZIndex = 3
		textButton.LayoutOrder = i

		local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
		uITextSizeConstraint.Name = "UITextSizeConstraint"
		uITextSizeConstraint.MaxTextSize = 25
		uITextSizeConstraint.Parent = textButton

		textButton.Parent = color
	end

	local easingStyle = Instance.new("ScrollingFrame")
	easingStyle.Name = "EasingStyle"
	easingStyle.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	easingStyle.CanvasSize = UDim2.new()
	easingStyle.ScrollBarThickness = 5
	easingStyle.ScrollingDirection = Enum.ScrollingDirection.Y
	easingStyle.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	easingStyle.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	easingStyle.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
	easingStyle.AnchorPoint = Vector2.new(0.5, 0)
	easingStyle.BackgroundColor3 = Color3.fromRGB(64, 64, 64)
	easingStyle.BorderSizePixel = 0
	easingStyle.LayoutOrder = 1
	easingStyle.Position = UDim2.new(0.5, 0, 0, 170)
	easingStyle.Size = UDim2.new(1, 0, 0, 100)
	easingStyle.ZIndex = 2
	easingStyle.Visible = false

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 5)
	uICorner.Parent = easingStyle

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = easingStyle

	local function easingStyleCanvasSize()
		easingStyle.CanvasSize = UDim2.fromOffset(0, uIListLayout.AbsoluteContentSize.Y)
	end
	uIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(easingStyleCanvasSize)

	for i: number,v: EnumItem in pairs(Enum.EasingStyle:GetEnumItems()) do
		local textButton = Instance.new("TextButton")
		textButton.Name = v.Name
		textButton.FontFace = Font.new(
			"rbxasset://fonts/families/Arial.json",
			Enum.FontWeight.Bold,
			Enum.FontStyle.Normal
		)
		textButton.Text = v.Name
		textButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		textButton.TextScaled = true
		textButton.TextSize = 14
		textButton.TextWrapped = true
		textButton.Active = true
		textButton.AnchorPoint = Vector2.new(0.5, 0.5)
		textButton.BackgroundTransparency = 1
		textButton.Position = UDim2.fromScale(0.5, 0.5)
		textButton.Selectable = true
		textButton.Size = UDim2.new(1, 0, 0, 15)
		textButton.ZIndex = 3
		textButton.LayoutOrder = i

		local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
		uITextSizeConstraint.Name = "UITextSizeConstraint"
		uITextSizeConstraint.MaxTextSize = 25
		uITextSizeConstraint.Parent = textButton

		textButton.Parent = easingStyle
	end

	local easingDirection = Instance.new("ScrollingFrame")
	easingDirection.Name = "EasingDirection"
	easingDirection.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	easingDirection.CanvasSize = UDim2.new()
	easingDirection.ScrollBarThickness = 5
	easingDirection.ScrollingDirection = Enum.ScrollingDirection.Y
	easingDirection.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	easingDirection.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	easingDirection.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
	easingDirection.AnchorPoint = Vector2.new(0.5, 0)
	easingDirection.BackgroundColor3 = Color3.fromRGB(64, 64, 64)
	easingDirection.BorderSizePixel = 0
	easingDirection.LayoutOrder = 1
	easingDirection.Position = UDim2.new(0.5, 0, 0, 170)
	easingDirection.Size = UDim2.new(1, 0, 0, 100)
	easingDirection.ZIndex = 2
	easingDirection.Visible = false

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 5)
	uICorner.Parent = easingDirection

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = easingDirection

	local function easingDirectionCanvasSize()
		easingDirection.CanvasSize = UDim2.fromOffset(0, uIListLayout.AbsoluteContentSize.Y)
	end
	uIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(easingDirectionCanvasSize)

	for i: number,v: EnumItem in pairs(Enum.EasingDirection:GetEnumItems()) do
		local textButton = Instance.new("TextButton")
		textButton.Name = v.Name
		textButton.FontFace = Font.new(
			"rbxasset://fonts/families/Arial.json",
			Enum.FontWeight.Bold,
			Enum.FontStyle.Normal
		)
		textButton.Text = v.Name
		textButton.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		textButton.TextScaled = true
		textButton.TextSize = 14
		textButton.TextWrapped = true
		textButton.Active = true
		textButton.AnchorPoint = Vector2.new(0.5, 0.5)
		textButton.BackgroundTransparency = 1
		textButton.Position = UDim2.fromScale(0.5, 0.5)
		textButton.Selectable = true
		textButton.Size = UDim2.new(1, 0, 0, 15)
		textButton.ZIndex = 3
		textButton.LayoutOrder = i

		local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
		uITextSizeConstraint.Name = "UITextSizeConstraint"
		uITextSizeConstraint.MaxTextSize = 25
		uITextSizeConstraint.Parent = textButton

		textButton.Parent = easingDirection
	end

	return color, easingStyle, easingDirection
end