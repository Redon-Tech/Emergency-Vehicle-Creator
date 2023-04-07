--[[
Redon Tech 2023
EVC V2
--]]

local section = require(script.Parent.section)

return function(colors: { number:Color3 }, colorLabels: { number:string })
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
	mainContainer.Position = UDim2.fromScale(0.5, 0.529)
	mainContainer.Selectable = false
	mainContainer.Size = UDim2.fromScale(1, 0.942)

	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Name = "ViewportFrame"
	viewportFrame.Ambient = Color3.fromRGB(138, 138, 138)
	viewportFrame.AnchorPoint = Vector2.new(0.5, 0)
	viewportFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.Position = UDim2.fromScale(0.5, 0)
	viewportFrame.Size = UDim2.fromScale(1, 0.3)

	local camera = Instance.new("Camera")
	camera.Name = "Camera"
	camera.CFrame = CFrame.new(0, 0, -1, -1, 0, 1.50995803e-07, 0, 1, 0, -1.50995803e-07, 0, -1)
	camera.Focus = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	camera.Parent = viewportFrame

	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "WorldModel"

	local part = Instance.new("Part")
	part.Name = "Part"
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.BrickColor = BrickColor.new("Institutional white")
	part.CanCollide = false
	part.Color = Color3.fromRGB(248, 248, 248)
	part.Material = Enum.Material.Neon
	part.Size = Vector3.new(0.75, 0.3, 0.1)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Parent = worldModel

	local motor = Instance.new("Part")
	motor.Name = "Motor"
	motor.Anchored = true
	motor.Transparency = 1
	motor.Size = Vector3.new(0.1, 0.1, 0.1)

	local motor6D = Instance.new("Motor6D")
	motor6D.Name = "Motor6D"
	motor6D.MaxVelocity = 0.05
	motor6D.Part0 = motor
	motor6D.Part1 = part
	motor6D.C0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, -4.37113883e-08, -1, 0, 1, -4.37113883e-08)
	motor6D.C1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, -4.37113883e-08, -1, 0, 1, -4.37113883e-08)
	motor6D.Parent = motor
	motor6D:SetAttribute("DesiredAngle", 0)

	motor.Parent = worldModel

	worldModel.Parent = viewportFrame

	viewportFrame.CurrentCamera = camera
	viewportFrame.Parent = mainContainer

	local controlsHolder = Instance.new("Frame")
	controlsHolder.Name = "ControlsHolder"
	controlsHolder.AnchorPoint = Vector2.new(0.5, 1)
	controlsHolder.BackgroundTransparency = 1
	controlsHolder.Position = UDim2.fromScale(0.5, 1)
	controlsHolder.Size = UDim2.fromScale(1, 0.7)
	controlsHolder.Parent = mainContainer

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.Parent = controlsHolder

	local uIPadding = Instance.new("UIPadding")
	uIPadding.Name = "UIPadding"
	uIPadding.PaddingBottom = UDim.new(0.0361, 0)
	uIPadding.PaddingLeft = UDim.new(0.0182, 0)
	uIPadding.PaddingRight = UDim.new(0.018, 0)
	uIPadding.PaddingTop = UDim.new(0.036, 0)
	uIPadding.Parent = controlsHolder

	local function changeSize()
		mainContainer.CanvasSize = UDim2.fromOffset(uIListLayout.AbsoluteContentSize.X, uIListLayout.AbsoluteContentSize.Y)
	end
	
	mainContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(changeSize)
	uIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(changeSize)

	section(1, colors, colorLabels).Parent = controlsHolder

	return mainContainer
end