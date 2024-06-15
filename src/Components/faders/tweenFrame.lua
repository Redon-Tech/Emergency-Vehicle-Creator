--[[
Redon Tech 2023-2024
EVC V2
--]]

local rowWithTextBox = require(script.Parent.Parent.reusedContent.rowWithTextBox)
local rowWithTextButton = require(script.Parent.Parent.reusedContent.rowWithTextButton)
local checkboxFrame = require(script.Parent.Parent.reusedContent.checkbox)

return function(tweenNumber: number)
	local tweenFrame = Instance.new("Frame")
	tweenFrame.Name = `Tween{tweenNumber}`
	tweenFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	tweenFrame.BackgroundTransparency = 1
	tweenFrame.BorderSizePixel = 0
	tweenFrame.LayoutOrder = tweenNumber
	tweenFrame.Size = UDim2.new(1, 0, 0, 290)

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = tweenFrame

	local color = rowWithTextButton("Color", "Color", 1)
	color.Parent = tweenFrame

	local transparencyGoal = rowWithTextBox("Transparency Goal", "TransparencyGoal", 2)
	transparencyGoal.TextBox.ClearTextOnFocus = false
	transparencyGoal.Parent = tweenFrame

	local timeToRun = rowWithTextBox("Time", "Time", 3)
	timeToRun.TextBox.ClearTextOnFocus = false
	timeToRun.Parent = tweenFrame

	local easingStyle = rowWithTextButton("Easing Style", "EasingStyle", 4)
	easingStyle.Parent = tweenFrame

	local easingDirection = rowWithTextButton("Easing Direction", "EasingDirection", 5)
	easingDirection.Parent = tweenFrame

	local repeatCount = rowWithTextBox("Repeat Count", "RepeatCount", 6)
	repeatCount.TextBox.ClearTextOnFocus = false
	repeatCount.Parent = tweenFrame

	
	local reverses = Instance.new("Frame")
	reverses.Name = "Reverses"
	reverses.AnchorPoint = Vector2.new(0.5, 1)
	reverses.BackgroundTransparency = 1
	reverses.LayoutOrder = 7
	reverses.Position = UDim2.fromScale(0.5, 1)
	reverses.Size = UDim2.fromOffset(30, 45)

	local uIListLayout1 = Instance.new("UIListLayout")
	uIListLayout1.Name = "UIListLayout"
	uIListLayout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout1.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout1.Parent = reverses

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = "Reverses"
	textLabel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textLabel.TextScaled = true
	textLabel.TextSize = 14
	textLabel.TextWrapped = true
	textLabel.Active = true
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.LayoutOrder = 0
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromOffset(75, 15)

	local uITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint1.Name = "UITextSizeConstraint"
	uITextSizeConstraint1.MaxTextSize = 25
	uITextSizeConstraint1.Parent = textLabel

	textLabel.Parent = reverses
	
	local checkbox = checkboxFrame()
	checkbox.Size = UDim2.fromOffset(30, 30)
	checkbox.Parent = reverses

	reverses.Parent = tweenFrame

	local delayTime = rowWithTextBox("Delay Time", "DelayTime", 8)
	delayTime.TextBox.ClearTextOnFocus = false
	delayTime.Parent = tweenFrame

	local bracketContainer = Instance.new("Frame")
	bracketContainer.Name = "BracketContainer"
	bracketContainer.BackgroundTransparency = 1
	bracketContainer.LayoutOrder = -100
	bracketContainer.Size = UDim2.fromOffset(0, -5)

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "ImageLabel"
	imageLabel.Image = "rbxassetid://12878056105"
	imageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	imageLabel.ScaleType = Enum.ScaleType.Slice
	imageLabel.SliceCenter = Rect.new(4, 4, 33, 31)
	imageLabel.AnchorPoint = Vector2.new(1, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Position = UDim2.fromOffset(-42, 5)
	imageLabel.Size = UDim2.fromOffset(15, 290)
	imageLabel.Parent = bracketContainer

	bracketContainer.Parent = tweenFrame

	return tweenFrame
end