--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local types = require("../../../../types")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local Editor = require("../../../../lib/ConfigurationEditor/FunctionsEditor/FadersEditor")
local assets = require("../../../../assets")
local ChassisHandler = require("../../../../lib/ChassisHandler")

type FaderSection = Editor.FaderSectionState & {
	currentTween: Fusion.Value<number>,
	currentPercentage: Fusion.Value<number>,
	currentValue: Fusion.Value<number>,
	previousGoal: number,
}

--[[
	faders.tween
	Creates the controls for the fader
]]
return function(
	scope: types.Scope,
	props: {
		key: number,
		sectionKey: number,
		tween: Editor.FaderTweenState,
		dataSize: Fusion.Value<Vector2>,
		CurrentPattern: Fusion.Value<types.selectedPattern?>,
		onEdited: () -> (),
		colors: Fusion.UsedAs<{ ChassisHandler.color }>,
		fader: FaderSection,
		playing: Fusion.Value<boolean>,
	}
): Fusion.Child
	local selected = scope.peek(props.CurrentPattern)
	assert(selected ~= nil, "No selected pattern")
	local currentTheme = RedonUI.theme.theme:now()

	local controlSize = scope:Computed(function(use)
		return UDim2.new(1, 0, 0, 0.0628930818 * use(props.dataSize).Y)
	end)
	local cornerRadius = scope:Computed(function(use)
		return UDim.new(0, 0.0125786164 * use(props.dataSize).Y)
	end)
	local baseDropdown = scope:dropdown {
		Size = controlSize,
		BackgroundColor3 = currentTheme.colors.crust,
		CornerRadius = cornerRadius,
		Border = 1,
		Text = props.tween.type :: any,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		DropdownHeight = 150,
		Options = {
			"Simple",
			"Advanced",
			"Wait",
		},
		OnOptionSelected = function(_, newType)
			ConfigurationEditor.updateFaderStepType(
				selected.functionId,
				selected.patternId,
				props.sectionKey,
				props.key,
				newType :: "Simple" | "Advanced" | "Wait"
			)
			props.onEdited()
		end,
	}
	local baseDropdownFrame = baseDropdown[2] :: Frame
	baseDropdownFrame.LayoutOrder = 2
	local currentTime = scope:Value(tostring(scope.peek(props.tween.time)))
	local baseControls: { Fusion.Child } = {
		baseDropdown,
		scope:textBox {
			Size = controlSize,
			BackgroundColor3 = currentTheme.colors.crust,
			CornerRadius = UDim.new(0.2, 0),
			Border = 1,
			Text = currentTime,
			[Fusion.Out "Text"] = currentTime :: unknown,
			PlaceholderText = scope:Computed(function(use)
				return if use(props.tween.type) == "Wait" then "Wait Time" else "Time"
			end),
			PlaceholderColor3 = currentTheme.colors.subtext0,
			LayoutOrder = 7,
			[Fusion.OnEvent "FocusLost"] = function()
				ConfigurationEditor.updateFaderStepTime(
					selected.functionId,
					selected.patternId,
					props.sectionKey,
					props.key,
					tonumber(scope.peek(currentTime)) or 0
				)
				currentTime:set(tostring(scope.peek(props.tween.time)))
				props.onEdited()
			end,
		},
	}

	local controls = scope:Computed(function(use, scope: typeof(scope))
		local controls: { Fusion.Child } = table.clone(baseControls)
		local currentType = use(props.tween.type)

		if currentType == "Simple" or currentType == "Advanced" then
			if (props.tween :: Editor.SimpleFaderState | Editor.AdvancedFaderState).color ~= nil then
				local colorDropdown = scope:dropdown {
					Size = controlSize,
					BackgroundColor3 = currentTheme.colors.crust,
					CornerRadius = cornerRadius,
					Border = 1,
					Text = scope:Computed(function(use)
						local colorId = use((props.tween :: Editor.SimpleFaderState | Editor.AdvancedFaderState).color)
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
						local colorId = use((props.tween :: Editor.SimpleFaderState | Editor.AdvancedFaderState).color)
						return if colorId == 0
							then currentTheme.colors.text
							else scope.getColorByName(use(props.colors)[colorId].name, currentTheme.colors.text)
					end),
					OnOptionSelected = function(colorId: number)
						ConfigurationEditor.updateFaderStepColor(
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
				table.insert(controls, colorDropdown)
			end
			if (props.tween :: Editor.SimpleFaderState | Editor.AdvancedFaderState).goal ~= nil then
				local currentText = scope:Value(
					tostring(scope.peek((props.tween :: Editor.SimpleFaderState | Editor.AdvancedFaderState).goal))
				)
				table.insert(
					controls,
					scope:textBox {
						Size = controlSize,
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						Text = currentText,
						[Fusion.Out "Text"] = currentText :: unknown,
						PlaceholderText = "Goal",
						PlaceholderColor3 = currentTheme.colors.subtext0,
						LayoutOrder = 6,
						[Fusion.OnEvent "FocusLost"] = function()
							ConfigurationEditor.updateFaderStepGoal(
								selected.functionId,
								selected.patternId,
								props.sectionKey,
								props.key,
								tonumber(scope.peek(currentText)) or 0
							)
							currentText:set(
								tostring(
									scope.peek(
										(props.tween :: Editor.SimpleFaderState | Editor.AdvancedFaderState).goal
									)
								)
							)
							props.onEdited()
						end,
					}
				)
			end
			if currentType == "Advanced" then
				if (props.tween :: Editor.AdvancedFaderState).easingStyle ~= nil then
					local options = {}
					for _, easingStyle: Enum.EasingStyle in pairs(Enum.EasingStyle:GetEnumItems()) do
						table.insert(options, easingStyle.Name)
					end
					local easingStyleDropdown = scope:dropdown {
						Size = controlSize,
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = cornerRadius,
						Border = 1,
						Text = scope:Computed(function(use)
							return use((props.tween :: Editor.AdvancedFaderState).easingStyle).Name
						end),
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 8,
						DropdownHeight = 150,
						Options = options,
						OnOptionSelected = function(_, newValue)
							local success, newEasingStyle = pcall(function()
								return (Enum.EasingStyle :: any)[newValue]
							end)
							if not success then
								return
							end
							ConfigurationEditor.updateFaderStepEasingStyle(
								selected.functionId,
								selected.patternId,
								props.sectionKey,
								props.key,
								newEasingStyle :: Enum.EasingStyle
							)
							props.onEdited()
						end,
					}
					local easingStyleDropdownFrame = easingStyleDropdown[2] :: Frame
					easingStyleDropdownFrame.LayoutOrder = 9
					table.insert(controls, easingStyleDropdown)
				end
				if (props.tween :: Editor.AdvancedFaderState).easingDirection ~= nil then
					local options = {}
					for _, easingStyle: Enum.EasingDirection in pairs(Enum.EasingDirection:GetEnumItems()) do
						table.insert(options, easingStyle.Name)
					end
					local easingStyleDropdown = scope:dropdown {
						Size = controlSize,
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = cornerRadius,
						Border = 1,
						Text = scope:Computed(function(use)
							return use((props.tween :: Editor.AdvancedFaderState).easingDirection).Name
						end),
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 10,
						DropdownHeight = 150,
						Options = options,
						OnOptionSelected = function(_, newValue)
							local success, newEasingDirection = pcall(function()
								return (Enum.EasingDirection :: any)[newValue]
							end)
							if not success then
								return
							end
							ConfigurationEditor.updateFaderStepEasingDirection(
								selected.functionId,
								selected.patternId,
								props.sectionKey,
								props.key,
								newEasingDirection :: Enum.EasingDirection
							)
							props.onEdited()
						end,
					}
					local easingStyleDropdownFrame = easingStyleDropdown[2] :: Frame
					easingStyleDropdownFrame.LayoutOrder = 11
					table.insert(controls, easingStyleDropdown)
				end
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
								if use(props.fader.currentTween) == props.key then
									percent = use(props.fader.currentPercentage)
								elseif use(props.fader.currentTween) > props.key then
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
							return UDim.new(0, 0.0125786164 * use(props.dataSize).Y)
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
