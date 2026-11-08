--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local types = require("../../../../types")
local ChassisHandler = require("../../../../lib/ChassisHandler")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local Editor = require("../../../../lib/ConfigurationEditor/FunctionsEditor/RotatorsEditor")
local assets = require("../../../../assets")

type RotatorSection = Editor.RotatorSectionState & {
	currentAngle: Fusion.Value<number>,
	currentPercentage: Fusion.Value<number>,
	currentValue: Fusion.Value<number>,
	previousGoal: number,
}

--[[
	Rotators
	Creates the rotators screen for the main app
]]
return function(
	scope: types.Scope,
	props: {
		key: number,
		sectionKey: number,
		angle: Editor.RotatorDataState,
		rotator: RotatorSection,
		playing: Fusion.Value<boolean>,
		colors: Fusion.UsedAs<{ ChassisHandler.color }>,
		onEdited: () -> (),
		CurrentPattern: Fusion.Value<types.selectedPattern?>,
		dataSize: Fusion.Value<Vector2>,
	}
): Fusion.Child
	local selected = scope.peek(props.CurrentPattern)
	assert(selected ~= nil, "No selected pattern")
	local currentTheme = RedonUI.theme.theme:now()

	local controlSize = scope:Computed(function(use)
		return UDim2.new(1, 0, 0, 0.1010101010 * use(props.dataSize).Y)
	end)
	local headerSize = scope:Computed(function(use)
		return UDim2.new(1, 0, 0, 0.0404040404 * use(props.dataSize).Y)
	end)
	local cornerRadius = scope:Computed(function(use)
		return UDim.new(0, 0.0202020202 * use(props.dataSize).Y)
	end)
	local function label(text: Fusion.UsedAs<string>, layoutOrder: Fusion.UsedAs<number>): Fusion.Child
		return scope:textLabel {
			Size = headerSize,
			BackgroundTransparency = 1,
			Text = text,
			TextScaled = true,
			MaxTextSize = 20,
			TextColor3 = currentTheme.colors.subtext0,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = layoutOrder,
		}
	end
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
			ConfigurationEditor.updateRotatorStepType(
				selected.functionId,
				selected.patternId,
				props.sectionKey,
				props.key,
				newType :: "Angle" | "Infinite" | "Wait"
			)
			props.onEdited()
		end,
	}
	local baseDropdownFrame = baseDropdown[2] :: Frame
	baseDropdownFrame.LayoutOrder = 2
	local baseControls: { Fusion.Child } = {
		label("Type", 1),
		baseDropdown,
	}

	local controls = scope:Computed(function(use, scope: typeof(scope))
		local controls: { Fusion.Child } = table.clone(baseControls)
		local currentType = use(props.angle.type)

		if currentType == "Angle" or currentType == "Infinite" then
			if (props.angle :: Editor.AngleRotatorState | Editor.InfiniteRotatorState).color ~= nil then
				local colorDropdown = scope:dropdown {
					Size = controlSize,
					BackgroundColor3 = currentTheme.colors.crust,
					CornerRadius = cornerRadius,
					Border = 1,
					Text = scope:Computed(function(use)
						local colorId =
							use((props.angle :: Editor.AngleRotatorState | Editor.InfiniteRotatorState).color)
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
								TextColor3 = scope.getColorByName(color.name, currentTheme.colors.text),
							}
						end
						table.insert(textColors, 1, {
							TextColor3 = currentTheme.colors.text,
						})
						return textColors :: any
					end),
					TextColor3 = scope:Computed(function(use)
						local colorId =
							use((props.angle :: Editor.AngleRotatorState | Editor.InfiniteRotatorState).color)
						return if colorId == 0
							then currentTheme.colors.text
							else scope.getColorByName(use(props.colors)[colorId].name, currentTheme.colors.text)
					end),
					OnOptionSelected = function(colorId: number)
						ConfigurationEditor.updateRotatorStepColor(
							selected.functionId,
							selected.patternId,
							props.sectionKey,
							props.key,
							colorId - 1
						)
						props.onEdited()
					end,
				}
				local colorDropdownFrame = colorDropdown[2] :: Frame
				colorDropdownFrame.LayoutOrder = 4
				table.insert(controls, label("Color", 3))
				table.insert(controls, colorDropdown)
			end
			if (props.angle :: Editor.AngleRotatorState | Editor.InfiniteRotatorState).velocity ~= nil then
				local currentText = scope:Value(
					tostring(
						scope.peek((props.angle :: Editor.AngleRotatorState | Editor.InfiniteRotatorState).velocity)
					)
				)
				table.insert(controls, label("Velocity", 7))
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
							ConfigurationEditor.updateRotatorStepVelocity(
								selected.functionId,
								selected.patternId,
								props.sectionKey,
								props.key,
								tonumber(scope.peek(currentText)) or 0
							)
							currentText:set(
								tostring(
									scope.peek(
										(props.angle :: Editor.AngleRotatorState | Editor.InfiniteRotatorState).velocity
									)
								)
							)
							props.onEdited()
						end,
					}
				)
			end
		elseif currentType == "Wait" then
			if (props.angle :: Editor.WaitState).time ~= nil then
				local currentText = scope:Value(tostring(scope.peek((props.angle :: Editor.WaitState).time)))
				table.insert(controls, label("Wait Time", 7))
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
							ConfigurationEditor.updateRotatorStepWaitTime(
								selected.functionId,
								selected.patternId,
								props.sectionKey,
								props.key,
								tonumber(scope.peek(currentText)) or 0
							)
							currentText:set(tostring(scope.peek((props.angle :: Editor.WaitState).time)))
							props.onEdited()
						end,
					}
				)
			end
		end

		if currentType == "Angle" then
			if (props.angle :: Editor.AngleRotatorState).angle ~= nil then
				local currentText = scope:Value(tostring(scope.peek((props.angle :: Editor.AngleRotatorState).angle)))
				table.insert(controls, label("Angle", 6))
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
							ConfigurationEditor.updateRotatorStepAngle(
								selected.functionId,
								selected.patternId,
								props.sectionKey,
								props.key,
								tonumber(scope.peek(currentText)) or 0
							)
							currentText:set(tostring(scope.peek((props.angle :: Editor.AngleRotatorState).angle)))
							props.onEdited()
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
