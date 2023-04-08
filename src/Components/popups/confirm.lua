--[[
Redon Tech 2023
EVC V2
--]]

local pluginRoot = script.Parent.Parent.Parent.Parent

return function(promptText: string, callback)
	local confirm = Instance.new("Frame")
	confirm.Name = "Confirm"
	confirm.AnchorPoint = Vector2.new(0.5, 0.5)
	confirm.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	confirm.Position = UDim2.fromScale(0.5, 0.5)
	confirm.Size = UDim2.fromScale(0.25, 0.25)
	confirm.ZIndex = 100001

	local uICorner = Instance.new("UICorner")
	uICorner.Name = "UICorner"
	uICorner.CornerRadius = UDim.new(0.025, 0)
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
	prompt.Size = UDim2.fromScale(1, 0.5)
	prompt.ZIndex = 100002

	local uITextSizeConstraint = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint.Name = "UITextSizeConstraint"
	uITextSizeConstraint.MaxTextSize = 30
	uITextSizeConstraint.Parent = prompt

	prompt.Parent = confirm

	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.AnchorPoint = Vector2.new(0.5, 1)
	buttons.BackgroundTransparency = 1
	buttons.Position = UDim2.fromScale(0.5, 1)
	buttons.Size = UDim2.fromScale(1, 0.5)
	buttons.ZIndex = 100002

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0.1, 0)
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uIListLayout.Parent = buttons

	local confirm1 = Instance.new("TextButton")
	confirm1.Name = "Confirm"
	confirm1.FontFace = Font.new(
		"rbxasset://fonts/families/Arial.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	confirm1.Text = "Confirm"
	confirm1.AutoButtonColor = false
	confirm1.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	confirm1.TextScaled = true
	confirm1.TextSize = 14
	confirm1.TextWrapped = true
	confirm1.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
	confirm1.Size = UDim2.fromScale(0.4, 0.37)
	confirm1.ZIndex = 100002

	local uICorner1 = Instance.new("UICorner")
	uICorner1.Name = "UICorner"
	uICorner1.CornerRadius = UDim.new(0.15, 0)
	uICorner1.Parent = confirm1

	local uITextSizeConstraint1 = Instance.new("UITextSizeConstraint")
	uITextSizeConstraint1.Name = "UITextSizeConstraint"
	uITextSizeConstraint1.MaxTextSize = 45
	uITextSizeConstraint1.Parent = confirm1

	confirm1.Parent = buttons

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

	connections[#connections+1] = confirm1.MouseButton1Click:Connect(function()
		for i,v in pairs(connections) do
			v:Disconnect()
		end
		confirm:Destroy()
		callback(true)
	end)

	connections[#connections+1] = confirm1.MouseEnter:Connect(function()
		confirm1.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
	end)
	connections[#connections+1] = confirm1.MouseLeave:Connect(function()
		confirm1.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
	end)

	connections[#connections+1] = cancel.MouseButton1Click:Connect(function()
		for i,v in pairs(connections) do
			v:Disconnect()
		end
		confirm:Destroy()
		callback(false)
	end)
	connections[#connections+1] = cancel.MouseEnter:Connect(function()
		cancel.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
		cancel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
	end)
	connections[#connections+1] = cancel.MouseLeave:Connect(function()
		cancel.BackgroundColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Button)
		cancel.TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	end)

	return confirm
end