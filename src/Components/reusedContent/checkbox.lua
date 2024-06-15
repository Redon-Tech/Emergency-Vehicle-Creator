--[[
Redon Tech 2023-2024
EVC V2
--]]

return function()
	local checkbox = Instance.new("Frame")
	checkbox.Name = "Checkbox"
	checkbox.AnchorPoint = Vector2.new(0.5, 0.5)
	checkbox.BackgroundTransparency = 1
	checkbox.Position = UDim2.fromScale(0.5, 0.5)
	checkbox.Size = UDim2.fromScale(1, 1)

	local border = Instance.new("ImageLabel")
	border.Name = "Border"
	border.Image = "rbxassetid://3008645364"
	border.ImageColor3 = Color3.fromRGB(37, 37, 37)
	border.ImageRectSize = Vector2.new(10, 10)
	border.ScaleType = Enum.ScaleType.Slice
	border.SliceCenter = Rect.new(4, 4, 5, 5)
	border.BackgroundTransparency = 1
	border.Size = UDim2.fromScale(1, 1)

	local border1 = Instance.new("ImageLabel")
	border1.Name = "Border"
	border1.Image = "rbxassetid://3008790403"
	border1.ImageColor3 = Color3.fromRGB(26, 26, 26)
	border1.ImageRectSize = Vector2.new(10, 10)
	border1.ScaleType = Enum.ScaleType.Slice
	border1.SliceCenter = Rect.new(4, 4, 5, 5)
	border1.BackgroundTransparency = 1
	border1.Size = UDim2.fromScale(1, 1)
	border1.Parent = border

	border.Parent = checkbox

	local checkmark = Instance.new("ImageLabel")
	checkmark.Name = "Checkmark"
	checkmark.Image = "rbxassetid://2773796198"
	checkmark.ImageColor3 = Color3.fromRGB(0, 162, 255)
	checkmark.BackgroundTransparency = 1
	checkmark.Position = UDim2.fromOffset(3, 3)
	checkmark.Visible = false
	checkmark.Size = UDim2.new(1, -6, 1, -6)
	checkmark.Parent = checkbox

	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Text = ""
	button.BackgroundTransparency = 1
	button.Size = UDim2.fromScale(1, 1)
	button.Parent = checkbox

	return checkbox
end