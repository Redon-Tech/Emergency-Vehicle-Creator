--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)
local assets = require(root.Plugin.assets)
local utils = require(root.Plugin.utils)

--[[
	Rotators
	Creates the rotators screen for the main app
]]
return function(
	scope: types.Scope,
	props: {
		key: number,
		angle: types.rotatorDataState,
		rotator: types.rotatorSectionState,
		playing: Fusion.Value<boolean>,
		colors: Fusion.Value<{ chassisHandler.color }>,
		updateCurrentConfiguration: () -> (),
		firstScope: types.Scope,
		dataSize: Fusion.Value<Vector2>,
	}
): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()

	local controlSize = scope:Computed(function(use)
		return UDim2.new(1, 0, 0, 0.1010101010 * use(props.dataSize).Y)
	end)
	local cornerRadius = scope:Computed(function(use)
		return UDim.new(0, 0.0202020202 * use(props.dataSize).Y)
	end)
	local baseDropdown = scope:dropdown {
		Size = controlSize,
		BackgroundColor3 = currentTheme.colors.crust,
		CornerRadius = cornerRadius,
		Border = 1,
		Text = props.angle.type :: any,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		DropdownHeight = 150,
		Options = {
			"Angle",
			"Infinite",
			"Wait",
		},
		OnOptionSelected = function(_, newType)
			if newType == "Wait" then
				props.angle.color = nil
				props.angle.angle = nil
				props.angle.velocity = nil
				props.angle.time = if props.angle.time ~= nil then props.angle.time else props.firstScope:Value(0.1)
			elseif newType == "Infinite" then
				props.angle.angle = nil
				props.angle.time = nil
				props.angle.color = if props.angle.color ~= nil then props.angle.color else props.firstScope:Value(1)
				props.angle.velocity = if props.angle.velocity ~= nil
					then props.angle.velocity
					else props.firstScope:Value(0.1)
			elseif newType == "Angle" then
				props.angle.time = nil
				props.angle.angle = if props.angle.angle ~= nil then props.angle.angle else props.firstScope:Value(90)
				props.angle.color = if props.angle.color ~= nil then props.angle.color else props.firstScope:Value(1)
				props.angle.velocity = if props.angle.velocity ~= nil
					then props.angle.velocity
					else props.firstScope:Value(0.1)
			end

			props.angle.type:set(newType :: "Angle" | "Infinite" | "Wait")
			props.updateCurrentConfiguration()
		end,
	}
	local baseDropdownFrame = baseDropdown[2] :: Frame
	baseDropdownFrame.LayoutOrder = 2
	local baseControls: { Fusion.Child } = {
		baseDropdown,
	}

	local controls = scope:Computed(function(use, scope: typeof(scope))
		local controls: { Fusion.Child } = baseControls
		local currentType = use(props.angle.type)

		if currentType == "Angle" or currentType == "Infinite" then
			if props.angle.color ~= nil then
				local colorDropdown = scope:dropdown {
					Size = controlSize,
					BackgroundColor3 = currentTheme.colors.crust,
					CornerRadius = cornerRadius,
					Border = 1,
					Text = scope:Computed(function(use)
						local colorId = use(props.angle.color)
						return if colorId == 0 then "None" else use(props.colors)[colorId].name
					end),
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 3,
					DropdownHeight = 150,
					Options = scope:Computed(function(use)
						local newColors: { string } = {}
						for colorId, color in pairs(use(props.colors)) do
							table.insert(newColors, colorId, color.name)
						end
						table.insert(newColors, 1, "None")
						return newColors
					end),
					OptionOverrides = scope:Computed(function(use)
						local textColors = {}
						for colorId, color in pairs(use(props.colors)) do
							textColors[colorId] = {
								TextColor3 = utils.getColorByName(color.name, currentTheme.colors.text),
							}
						end
						table.insert(textColors, 1, {
							TextColor3 = currentTheme.colors.text,
						})
						return textColors :: any
					end),
					TextColor3 = scope:Computed(function(use)
						local colorId = use(props.angle.color)
						return if colorId == 0
							then currentTheme.colors.text
							else utils.getColorByName(use(props.colors)[colorId].name, currentTheme.colors.text)
					end),
					OnOptionSelected = function(colorId: number)
						props.angle.color:set(colorId - 1)
						props.updateCurrentConfiguration()
					end,
				}
				local colorDropdownFrame = colorDropdown[2] :: Frame
				colorDropdownFrame.LayoutOrder = 4
				table.insert(controls, colorDropdown)
			end
			if props.angle.velocity ~= nil then
				local currentText = scope:Value(tostring(scope.peek(props.angle.velocity)))
				table.insert(
					controls,
					scope:textBox {
						Size = controlSize,
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						Text = currentText,
						[Fusion.Out "Text"] = currentText :: unknown,
						PlaceholderText = "Velocity",
						PlaceholderColor3 = currentTheme.colors.subtext0,
						LayoutOrder = 7,
						[Fusion.OnEvent "FocusLost"] = function()
							props.angle.velocity:set(tonumber(scope.peek(currentText)) or 0)
							currentText:set(tostring(scope.peek(props.angle.velocity)))
							props.updateCurrentConfiguration()
						end,
					}
				)
			end
		elseif currentType == "Wait" then
			if props.angle.time ~= nil then
				local currentText = scope:Value(tostring(scope.peek(props.angle.time)))
				table.insert(
					controls,
					scope:textBox {
						Size = controlSize,
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						Text = currentText,
						[Fusion.Out "Text"] = currentText :: unknown,
						PlaceholderText = "Wait Time",
						PlaceholderColor3 = currentTheme.colors.subtext0,
						LayoutOrder = 7,
						[Fusion.OnEvent "FocusLost"] = function()
							props.angle.time:set(tonumber(scope.peek(currentText)) or 0)
							currentText:set(tostring(scope.peek(props.angle.time)))
							props.updateCurrentConfiguration()
						end,
					}
				)
			end
		end

		if currentType == "Angle" then
			if props.angle.angle ~= nil then
				local currentText = scope:Value(tostring(scope.peek(props.angle.angle)))
				table.insert(
					controls,
					scope:textBox {
						Size = controlSize,
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						Text = currentText,
						[Fusion.Out "Text"] = currentText :: unknown,
						PlaceholderText = "Angle",
						PlaceholderColor3 = currentTheme.colors.subtext0,
						LayoutOrder = 6,
						[Fusion.OnEvent "FocusLost"] = function()
							props.angle.angle:set(tonumber(scope.peek(currentText)) or 0)
							currentText:set(tostring(scope.peek(props.angle.angle)))
							props.updateCurrentConfiguration()
						end,
					}
				)
			end
		end

		return controls
	end)

	return scope:base {
		Name = props.key,
		Size = UDim2.fromScale(0.5357142857, 0),
		BackgroundTransparency = 1,
		LayoutOrder = props.key,
		AutomaticSize = Enum.AutomaticSize.Y,

		[Fusion.Children] = {
			scope:base {
				ClassName = "ImageLabel",
				Size = UDim2.fromScale(0.1333333333, 1),
				Position = UDim2.fromScale(-0.0666666667, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Image = assets.images.elsCreator.box,
				ResampleMode = Enum.ResamplerMode.Pixelated,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 18, 33),

				[Fusion.Children] = {
					scope:New("UIGradient") {
						Name = "UIGradient",
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, currentTheme.colors.blue),
							ColorSequenceKeypoint.new(0.001, currentTheme.colors.text),
							ColorSequenceKeypoint.new(1, currentTheme.colors.text),
						}),
						Offset = scope:Computed(function(use)
							local percent = 0
							if use(props.playing) == true then
								if use(props.rotator.currentAngle) == props.key then
									if use(props.angle.type) == "Infinite" then
										percent = 1
									else
										percent = use(props.rotator.currentPercentage)
									end
								elseif use(props.rotator.currentAngle) > props.key then
									percent = 1
								end
							end
							return Vector2.new(0, percent)
						end),
						Rotation = 90,
					},
				},
			},

			scope:base {
				Name = "Controls",
				Size = UDim2.fromScale(1, 0),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,

				[Fusion.Children] = Fusion.Child {
					scope:New("UIListLayout") {
						Padding = scope:Computed(function(use)
							return UDim.new(0, 0.0202020202 * use(props.dataSize).Y)
						end),
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					controls,
				},
			},
		},
	}
end
