--[[
Redon Tech 2023-2024
EVC V2
--]]

local pluginRoot = script.Parent.Parent.Parent.Parent

return function(promptText: string, directoryString: string, callback)
	local confirm = Instance.new("Frame")
	confirm.Name = "Confirm"
	confirm.AnchorPoint = Vector2.new(0.5, 0.5)
	confirm.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	confirm.Position = UDim2.fromScale(0.5, 0.5)
	confirm.Size = UDim2.fromScale(0.25, 0.25)
	confirm.ZIndex = 100001

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0.05, 0)
	uICorner.Parent = confirm

	local prompt = Instance.new("TextLabel")
	prompt.Name = "Prompt"
	prompt.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	prompt.RichText = true
	prompt.Text = promptText
	prompt.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	prompt.TextScaled = true
	prompt.TextSize = 30
	prompt.TextWrapped = true
	prompt.AnchorPoint = Vector2.new(0.5, 0)
	prompt.BackgroundTransparency = 1
	prompt.Position = UDim2.fromScale(0.5, 0)
	prompt.Size = UDim2.fromScale(1, 0.4)
	prompt.ZIndex = 100002

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 30
	uITextSizeConstraint.Parent = prompt

	prompt.Parent = confirm

	local directory = Instance.new("TextBox")
	directory.Name = "Directory"
	directory.FontFace = Font.new("rbxasset://fonts/families/Arial.json")
	directory.Text = directoryString
	directory.ClearTextOnFocus = false
	directory.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	directory.TextScaled = true
	directory.TextSize = 30
	directory.TextWrapped = true
	directory.AnchorPoint = Vector2.new(0.5, 0.5)
	directory.BackgroundTransparency = 1
	directory.Position = UDim2.fromScale(0.5, 0.5)
	directory.Size = UDim2.fromScale(1, 0.25)
	directory.ZIndex = 100002

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 30
	uITextSizeConstraint.Parent = directory

	directory.Parent = confirm

	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.AnchorPoint = Vector2.new(0.5, 1)
	buttons.BackgroundTransparency = 1
	buttons.Position = UDim2.fromScale(0.5, 1)
	buttons.Size = UDim2.fromScale(1, 0.4)
	buttons.ZIndex = 100002

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0.1, 0)
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.Parent = buttons

	local selectFile = Instance.new("TextButton")
	selectFile.Name = "SelectFile"
	selectFile.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	selectFile.Text = "Select File"
	selectFile.AutoButtonColor = false
	selectFile.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	selectFile.TextScaled = true
	selectFile.TextSize = 14
	selectFile.TextWrapped = true
	selectFile.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
	selectFile.Size = UDim2.fromScale(0.4, 0.37)
	selectFile.ZIndex = 100002

	local uICorner1 = Instance.new("UICorner")
	uICorner1.Name = "UICorner"
	uICorner1.CornerRadius = UDim.new(0.15, 0)
	uICorner1.Parent = selectFile

	local uITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint1.Name = "UITextSizeConstraint"
	uITextSizeConstraint1.MaxTextSize = 45
	uITextSizeConstraint1.Parent = selectFile

	selectFile.Parent = buttons

	local cancel = Instance.new("TextButton")
	cancel.Name = "Cancel"
	cancel.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	cancel.Text = "Cancel"
	cancel.AutoButtonColor = false
	cancel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	cancel.TextScaled = true
	cancel.TextSize = 14
	cancel.TextWrapped = true
	cancel.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	cancel.Size = UDim2.fromScale(0.4, 0.37)
	cancel.ZIndex = 100002

	local uICorner2 = Instance.new("UICorner")
	uICorner2.Name = "UICorner"
	uICorner2.CornerRadius = UDim.new(0.15, 0)
	uICorner2.Parent = cancel

	local uITextSizeConstraint2 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint2.Name = "UITextSizeConstraint"
	uITextSizeConstraint2.MaxTextSize = 45
	uITextSizeConstraint2.Parent = cancel

	cancel.Parent = buttons

	buttons.Parent = confirm

	local connections = {}

	connections[#connections+1] = pluginRoot:WaitForChild("Container").Value.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Return then
			callback(true)
			confirm:Destroy()
			for i,v in pairs(connections) do
				v:Disconnect()
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			callback(false)
			confirm:Destroy()
			for i,v in pairs(connections) do
				v:Disconnect()
			end
		end
	end)

	connections[#connections+1] = selectFile.MouseButton1Click:Connect(function()
		for i,v in pairs(connections) do
			v:Disconnect()
		end
		callback(true)
		confirm:Destroy()
	end)

	connections[#connections+1] = selectFile.MouseEnter:Connect(function()
		selectFile.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
	end)
	connections[#connections+1] = selectFile.MouseLeave:Connect(function()
		selectFile.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
	end)

	connections[#connections+1] = cancel.MouseButton1Click:Connect(function()
		for i,v in pairs(connections) do
			v:Disconnect()
		end
		callback(false)
		confirm:Destroy()
	end)
	connections[#connections+1] = cancel.MouseEnter:Connect(function()
		cancel.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
	end)
	connections[#connections+1] = cancel.MouseLeave:Connect(function()
		cancel.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
	end)

	connections[#connections+1] = directory:GetPropertyChangedSignal("Text"):Connect(function()
		directory.Text = directoryString
	end)

	return confirm
end