--[[
Redon Tech 2023-2024
EVC V2
--]]

local columnHeaderContainer = require(script.Parent.columnHeaderContainer)
local columnContainer = require(script.Parent.columnContainer)

return function(sectionNumer: number)
	local section = Instance.new("Frame")
	section.Name = "Section"..sectionNumer
	section.BackgroundTransparency = 1
	section.LayoutOrder = sectionNumer
	section.Size = UDim2.fromOffset(235, 550) -- 900

	local sectionControls = Instance.new("Frame")
	sectionControls.Name = "SectionControls"
	sectionControls.AnchorPoint = Vector2.new(0.5, 0)
	sectionControls.BackgroundTransparency = 1
	sectionControls.Position = UDim2.new(0.5, 0, 0, 7.5) -- 15
	sectionControls.Size = UDim2.fromOffset(75, 22.5) -- 150, 45

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5) -- 10
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.Parent = sectionControls

	local waitTime = Instance.new("TextBox")
	waitTime.Name = "WaitTime"
	waitTime.CursorPosition = -1
	waitTime.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	waitTime.PlaceholderText = "Wait Time"
	waitTime.Text = "0.1"
	waitTime.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	waitTime.TextScaled = true
	waitTime.TextSize = 40
	waitTime.TextWrapped = true
	waitTime.TextYAlignment = Enum.TextYAlignment.Bottom
	waitTime.AnchorPoint = Vector2.new(0.5, 0)
	waitTime.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	waitTime.LayoutOrder = 2
	waitTime.Position = UDim2.new(0.5, 0, 0, 7.5) -- 15
	waitTime.Size = UDim2.fromOffset(75, 22.5) -- 150, 45
	waitTime.ZIndex = 4

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0, 5)
	uICorner.Parent = waitTime

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 40
	uITextSizeConstraint.Parent = waitTime

	waitTime.Parent = sectionControls

	local add = Instance.new("ImageButton")
	add.Name = "Add"
	add.Image = "rbxassetid://12788800986"
	add.ScaleType = Enum.ScaleType.Fit
	add.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	add.BackgroundTransparency = 1
	add.BorderSizePixel = 0
	add.LayoutOrder = 3
	add.Size = UDim2.fromOffset(11.5, 11.5) -- 23, 23
	add.Parent = sectionControls
	add.ZIndex = 4

	local remove = Instance.new("ImageButton")
	remove.Name = "RemoveButton"
	remove.Image = "rbxassetid://12788801841"
	remove.ScaleType = Enum.ScaleType.Fit
	remove.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	remove.ImageTransparency = 0.5
	remove.BackgroundTransparency = 1
	remove.BorderSizePixel = 0
	remove.LayoutOrder = 1
	remove.Size = UDim2.fromOffset(11.5, 11.5)
	remove.Parent = sectionControls
	remove.ZIndex = 4

	sectionControls.Parent = section

	local columnHeaders = columnHeaderContainer()
	columnHeaders.Parent = section
	
	local columnContainer, indicator = columnContainer()
	columnContainer.Parent = section
	indicator.Parent = section

	-- indicator.Indicator.Position = UDim2.new(0.5, 1.25, 0, (columnContainer["1"]["1"].AbsolutePosition.Y - 2.5) + 37.5) -- 2.5, 5
	indicator.Indicator.Position = UDim2.new(0.5, 1.25, 0, ((columnContainer["1"]["1"].LayoutOrder - 1) * 20)-3)

	return section
end