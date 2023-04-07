--[[
Redon Tech 2023
EVC V2
--]]

local angleRows = require(script.Parent.angleRows)
local rowWithTextBox = require(script.Parent.Parent.reusedContent.rowWithTextBox)
local checkboxFrame = require(script.Parent.Parent.reusedContent.checkbox)

return function(options: Frame)
	local topOptions = Instance.new("Frame")
	topOptions.Name = "TopOptions"
	topOptions.AnchorPoint = Vector2.new(0.5, 0.5)
	topOptions.BackgroundTransparency = 1
	topOptions.BorderSizePixel = 0
	topOptions.LayoutOrder = -1
	topOptions.Size = UDim2.new(1, 0, 0, 100)

	-- local name = Instance.new("Frame")
	-- name.Name = "NameBox"
	-- name.AnchorPoint = Vector2.new(0.5, 0)
	-- name.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	-- name.BorderSizePixel = 0
	-- name.LayoutOrder = 1
	-- name.Position = UDim2.fromScale(0.5, 0)
	-- name.Size = UDim2.new(1, 0, 0, 30)

	-- local uICorner = Instance.new("UICorner")
	-- uICorner.Name = "UICorner"
	-- uICorner.CornerRadius = UDim.new(0, 5)
	-- uICorner.Parent = name

	-- local textBox = Instance.new("TextBox")
	-- textBox.Name = "TextBox"
	-- textBox.FontFace = Font.new(
	-- 	"rbxasset://fonts/families/Arial.json",
	-- 	Enum.FontWeight.Bold,
	-- 	Enum.FontStyle.Normal
	-- )
	-- textBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
	-- textBox.PlaceholderText = "Name"
	-- textBox.Text = ""
	-- textBox.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	-- textBox.TextScaled = true
	-- textBox.TextSize = 14
	-- textBox.TextWrapped = true
	-- textBox.AnchorPoint = Vector2.new(0.5, 0.5)
	-- textBox.BackgroundTransparency = 1
	-- textBox.Position = UDim2.fromScale(0.5, 0.5)
	-- textBox.Size = UDim2.fromScale(1, 1)

	-- local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	-- uITextSizeConstraint.Name = "UITextSizeConstraint"
	-- uITextSizeConstraint.MaxTextSize = 25
	-- uITextSizeConstraint.Parent = textBox

	-- textBox.Parent = name
	local name = rowWithTextBox("Name", "NameBox", 1)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.fromScale(0.5, 0)
	name.Parent = topOptions

	local enabled = Instance.new("Frame")
	enabled.Name = "Enabled"
	enabled.AnchorPoint = Vector2.new(0.5, 1)
	enabled.BackgroundTransparency = 1
	enabled.LayoutOrder = 1
	enabled.Position = UDim2.fromScale(0.5, 1)
	enabled.Size = UDim2.fromOffset(30, 30)

	local checkbox = checkboxFrame()
	checkbox.Parent = enabled

	enabled.Parent = topOptions

	local textBox1 = Instance.new("TextLabel")
	textBox1.Name = "TextBox"
	textBox1.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textBox1.Text = "Preview Enabled"
	textBox1.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textBox1.TextScaled = true
	textBox1.TextSize = 14
	textBox1.TextWrapped = true
	textBox1.Active = true
	textBox1.AnchorPoint = Vector2.new(0.5, 0.5)
	textBox1.BackgroundTransparency = 1
	textBox1.Position = UDim2.fromScale(0.5, 0.5)
	textBox1.Selectable = true
	textBox1.Size = UDim2.new(1, 0, 0, 30)

	local uITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint1.Name = "UITextSizeConstraint"
	uITextSizeConstraint1.MaxTextSize = 25
	uITextSizeConstraint1.Parent = textBox1

	textBox1.Parent = topOptions

	topOptions.Parent = options

	local label = Instance.new("Frame")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Position = UDim2.fromScale(0.5, 1)
	label.Size = UDim2.new(1, 0, 0, 60)

	local textBox2 = Instance.new("TextLabel")
	textBox2.Name = "TextBox"
	textBox2.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textBox2.Text = "Desired Angles"
	textBox2.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	textBox2.TextScaled = true
	textBox2.TextSize = 14
	textBox2.TextWrapped = true
	textBox2.Active = true
	textBox2.AnchorPoint = Vector2.new(0.5, 0.5)
	textBox2.BackgroundTransparency = 1
	textBox2.Position = UDim2.fromScale(0.5, 0.5)
	textBox2.Selectable = true
	textBox2.Size = UDim2.fromScale(1, 1)

	local uITextSizeConstraint2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint2.Name = "UITextSizeConstraint"
	uITextSizeConstraint2.MaxTextSize = 25
	uITextSizeConstraint2.Parent = textBox2

	textBox2.Parent = label

	label.Parent = options

	angleRows(1).Parent = options
end