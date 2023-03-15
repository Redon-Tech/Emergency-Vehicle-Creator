--[[
Redon Tech 2022
EVC V2
--]]

return function(Name: string, Position: number, Icon: string)
	local frame = Instance.new("Frame")
	frame.Name = Name
	frame.LayoutOrder = Position
	frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(0.023, 0.75)
	frame.ZIndex = 3

	local uIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uIAspectRatioConstraint.AspectRatio = 1
	uIAspectRatioConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
	uIAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Height
	uIAspectRatioConstraint.Parent = frame

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0.15, 0)
	uICorner.Parent = frame

	local image = Instance.new("ImageButton")
	image.Name = "Image"
	image.Image = Icon
	image.ScaleType = Enum.ScaleType.Fit
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	image.BackgroundTransparency = 1
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(0.75, 0.75)
	image.Parent = frame
	image.ZIndex = 4

	frame.MouseEnter:Connect(function()
		if frame:GetAttribute("Active") ~= true then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		end
	end)

	frame.MouseLeave:Connect(function()
		if frame:GetAttribute("Active") ~= true then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		end
	end)

	return frame
end