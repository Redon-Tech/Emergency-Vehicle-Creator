--[[
Redon Tech 2023-2024
EVC V2
--]]

return function(Name: string, Position: number, Icon: string, IconActive: string)
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
	image.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	image.BackgroundTransparency = 1
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(0.75, 0.75)
	image.Parent = frame
	image.ZIndex = 4

	frame.MouseEnter:Connect(function()
		if frame:GetAttribute("Active") ~= true then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
			image.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
		elseif frame:GetAttribute("Active") == true and IconActive == nil then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
			image.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
		end
	end)

	frame.MouseLeave:Connect(function()
		if frame:GetAttribute("Active") ~= true then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
			image.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		elseif frame:GetAttribute("Active") == true and IconActive == nil then
			frame.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected)
			image.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected)
		end
	end)

	frame:GetAttributeChangedSignal("Active"):Connect(function()
		frame.BackgroundColor3 = if frame:GetAttribute("Active") == true then settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Selected) else settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		image.ImageColor3 = if frame:GetAttribute("Active") == true then settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Selected) else settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	frame:GetAttributeChangedSignal("Icon"):Connect(function()
		image.Image = if frame:GetAttribute("Icon") == true then IconActive else Icon
	end)

	return frame
end