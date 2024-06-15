--[[
Redon Tech 2023-2024
EVC V2
--]]

local rowWithTextBox = require(script.Parent.Parent.reusedContent.rowWithTextBox)
local rowWithTextButton = require(script.Parent.Parent.reusedContent.rowWithTextButton)

return function(angleNumber: number)
	local angle1 = Instance.new("Frame")
	angle1.Name = `Angle{angleNumber}`
	angle1.AnchorPoint = Vector2.new(0.5, 0.5)
	angle1.BackgroundTransparency = 1
	angle1.BorderSizePixel = 0
	angle1.LayoutOrder = angleNumber
	angle1.Size = UDim2.new(1, 0, 0, 100)

	-- local angle = Instance.new("Frame")
	-- angle.Name = "Angle"
	-- angle.AnchorPoint = Vector2.new(0.5, 0.5)
	-- angle.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	-- angle.BorderSizePixel = 0
	-- angle.LayoutOrder = 1
	-- angle.Position = UDim2.fromScale(0.5, 0.5)
	-- angle.Size = UDim2.new(1, 0, 0, 30)

	-- local uICorner = Instance.new("UICorner")
	-- uICorner.Name = "UICorner"
	-- uICorner.CornerRadius = UDim.new(0, 5)
	-- uICorner.Parent = angle

	-- local textBox = Instance.new("TextBox")
	-- textBox.Name = "TextBox"
	-- textBox.FontFace = Font.new(
	-- 	"rbxasset://fonts/families/Arial.json",
	-- 	Enum.FontWeight.Bold,
	-- 	Enum.FontStyle.Normal
	-- )
	-- textBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
	-- textBox.PlaceholderText = "Angle"
	-- textBox.Text = ""
	-- textBox.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	-- textBox.TextScaled = true
	-- textBox.TextSize = 14
	-- textBox.TextWrapped = true
	-- textBox.AnchorPoint = Vector2.new(0.5, 0.5)
	-- textBox.BackgroundTransparency = 1
	-- textBox.Position = UDim2.fromScale(0.5, 0.5)
	-- textBox.Size = UDim2.fromScale(1, 1)
	-- textBox.ClearTextOnFocus = false

	-- local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	-- uITextSizeConstraint.Name = "UITextSizeConstraint"
	-- uITextSizeConstraint.MaxTextSize = 25
	-- uITextSizeConstraint.Parent = textBox

	-- textBox.Parent = angle
	local angle = rowWithTextBox("Angle", "Angle", 1)
	angle.AnchorPoint = Vector2.new(0.5, 0.5)
	angle.Position = UDim2.fromScale(0.5, 0.5)
	angle.TextBox.ClearTextOnFocus = false
	angle.Parent = angle1

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "ImageLabel"
	imageLabel.Image = "rbxassetid://12878056105"
	imageLabel.ScaleType = Enum.ScaleType.Slice
	imageLabel.SliceCenter = Rect.new(4, 4, 33, 31)
	imageLabel.AnchorPoint = Vector2.new(1, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Position = UDim2.fromScale(-0.05, 0)
	imageLabel.Size = UDim2.fromScale(0.2, 1)
	imageLabel.ImageColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	imageLabel.Parent = angle1

	-- local color = Instance.new("Frame")
	-- color.Name = "Color"
	-- color.AnchorPoint = Vector2.new(0.5, 0)
	-- color.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	-- color.BorderSizePixel = 0
	-- color.LayoutOrder = 1
	-- color.Position = UDim2.fromScale(0.5, 0)
	-- color.Size = UDim2.new(1, 0, 0, 30)

	-- local uICorner1 = Instance.new("UICorner")
	-- uICorner1.Name = "UICorner"
	-- uICorner1.CornerRadius = UDim.new(0, 5)
	-- uICorner1.Parent = color

	-- local textBox1 = Instance.new("TextButton")
	-- textBox1.Name = "TextButton"
	-- textBox1.FontFace = Font.new(
	-- 	"rbxasset://fonts/families/Arial.json",
	-- 	Enum.FontWeight.Bold,
	-- 	Enum.FontStyle.Normal
	-- )
	-- textBox1.Text = "Color"
	-- textBox1.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	-- textBox1.TextScaled = true
	-- textBox1.TextSize = 14
	-- textBox1.TextWrapped = true
	-- textBox1.Active = true
	-- textBox1.AnchorPoint = Vector2.new(0.5, 0.5)
	-- textBox1.BackgroundTransparency = 1
	-- textBox1.Position = UDim2.fromScale(0.5, 0.5)
	-- textBox1.Selectable = true
	-- textBox1.Size = UDim2.fromScale(1, 1)

	-- local uITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
	-- uITextSizeConstraint1.Name = "UITextSizeConstraint"
	-- uITextSizeConstraint1.MaxTextSize = 25
	-- uITextSizeConstraint1.Parent = textBox1

	-- textBox1.Parent = color
	local color = rowWithTextButton("Color", "Color", 1)
	color.AnchorPoint = Vector2.new(0.5, 0)
	color.Position = UDim2.fromScale(0.5, 0)
	color.Parent = angle1

	-- local velocity = Instance.new("Frame")
	-- velocity.Name = "Velocity"
	-- velocity.AnchorPoint = Vector2.new(0.5, 1)
	-- velocity.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	-- velocity.BorderSizePixel = 0
	-- velocity.LayoutOrder = 1
	-- velocity.Position = UDim2.fromScale(0.5, 1)
	-- velocity.Size = UDim2.new(1, 0, 0, 30)

	-- local uICorner2 = Instance.new("UICorner")
	-- uICorner2.Name = "UICorner"
	-- uICorner2.CornerRadius = UDim.new(0, 5)
	-- uICorner2.Parent = velocity

	-- local textBox2 = Instance.new("TextBox")
	-- textBox2.Name = "TextBox"
	-- textBox2.FontFace = Font.new(
	-- 	"rbxasset://fonts/families/Arial.json",
	-- 	Enum.FontWeight.Bold,
	-- 	Enum.FontStyle.Normal
	-- )
	-- textBox2.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
	-- textBox2.PlaceholderText = "Velocity"
	-- textBox2.Text = ""
	-- textBox2.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	-- textBox2.TextScaled = true
	-- textBox2.TextSize = 14
	-- textBox2.TextWrapped = true
	-- textBox2.AnchorPoint = Vector2.new(0.5, 0.5)
	-- textBox2.BackgroundTransparency = 1
	-- textBox2.Position = UDim2.fromScale(0.5, 0.5)
	-- textBox2.Size = UDim2.fromScale(1, 1)
	-- textBox2.ClearTextOnFocus = false

	-- local uITextSizeConstraint2 = Instance.new("UITextSizeConstraint")
	-- uITextSizeConstraint2.Name = "UITextSizeConstraint"
	-- uITextSizeConstraint2.MaxTextSize = 25
	-- uITextSizeConstraint2.Parent = textBox2

	-- textBox2.Parent = velocity
	local velocity = rowWithTextBox("Velocity", "Velocity", 1)
	velocity.AnchorPoint = Vector2.new(0.5, 1)
	velocity.Position = UDim2.fromScale(0.5, 1)
	velocity.TextBox.ClearTextOnFocus = false
	velocity.Parent = angle1

	return angle1
end