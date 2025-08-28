--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)
local chassisHandler = require(root.Plugin.chassisHandler)
local utils = require(root.Plugin.utils)

--[[
	faders.tween
	Creates the controls for the fader
]]
return function(
	scope: types.Scope,
	props: {
		key: number,
		tween: types.faderTweenDataState,
		dataSize: Fusion.Value<Vector2>,
		firstScope: types.Scope,
		updateCurrentConfiguration: () -> (),
		colors: Fusion.Value<{ chassisHandler.color }>,
		fader: types.faderSectionState,
		playing: Fusion.Value<boolean>,
	}
): Fusion.Child
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
			if newType == "Wait" then
				props.tween.goal = nil
				props.tween.color = nil
				props.tween.easingStyle = nil
				props.tween.easingDirection = nil
			elseif newType == "Simple" then
				props.tween.goal = if props.tween.goal ~= nil then props.tween.goal else props.firstScope:Value(0)
				props.tween.color = if props.tween.color ~= nil then props.tween.color else props.firstScope:Value(4)
				props.tween.easingStyle = nil
				props.tween.easingDirection = nil
			elseif newType == "Advanced" then
				props.tween.goal = if props.tween.goal ~= nil then props.tween.goal else props.firstScope:Value(0)
				props.tween.color = if props.tween.color ~= nil then props.tween.color else props.firstScope:Value(4)
				props.tween.easingStyle = if props.tween.easingStyle ~= nil
					then props.tween.easingStyle
					else props.firstScope:Value(Enum.EasingStyle.Linear)
				props.tween.easingDirection = if props.tween.easingDirection ~= nil
					then props.tween.easingDirection
					else props.firstScope:Value(Enum.EasingDirection.InOut)
			end
			props.tween.type:set(newType :: "Simple" | "Advanced" | "Wait")
			props.updateCurrentConfiguration()
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
				props.tween.time:set(tonumber(scope.peek(currentTime)) or 0)
				currentTime:set(tostring(scope.peek(currentTime)))
				props.updateCurrentConfiguration()
			end,
		},
	}

	local controls = scope:Computed(function(use, scope: typeof(scope))
		local controls: { Fusion.Child } = baseControls
		local currentType = use(props.tween.type)

		if currentType == "Simple" or currentType == "Advanced" then
			if props.tween.color ~= nil then
				local colorDropdown = scope:dropdown {
					Size = controlSize,
					BackgroundColor3 = currentTheme.colors.crust,
					CornerRadius = cornerRadius,
					Border = 1,
					Text = scope:Computed(function(use)
						local colorId = use(props.tween.color)
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
						local colorId = use(props.tween.color)
						return if colorId == 0
							then currentTheme.colors.text
							else utils.getColorByName(use(props.colors)[colorId].name, currentTheme.colors.text)
					end),
					OnOptionSelected = function(colorId: number)
						props.tween.color:set(colorId - 1)
						props.updateCurrentConfiguration()
					end,
				}
				local colorDropdownFrame = colorDropdown[2] :: Frame
				colorDropdownFrame.LayoutOrder = 4
				table.insert(controls, colorDropdown)
			end
			if props.tween.goal ~= nil then
				local currentText = scope:Value(tostring(scope.peek(props.tween.goal)))
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
							props.tween.goal:set(tonumber(scope.peek(currentText)) or 0)
							currentText:set(tostring(scope.peek(props.tween.goal)))
							props.updateCurrentConfiguration()
						end,
					}
				)
			end
			if currentType == "Advanced" then
				if props.tween.easingStyle ~= nil then
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
							return use(props.tween.easingStyle).Name
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
							props.tween.easingStyle:set(newEasingStyle :: Enum.EasingStyle)
							props.updateCurrentConfiguration()
						end,
					}
					local easingStyleDropdownFrame = easingStyleDropdown[2] :: Frame
					easingStyleDropdownFrame.LayoutOrder = 9
					table.insert(controls, easingStyleDropdown)
				end
				if props.tween.easingDirection ~= nil then
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
							return use(props.tween.easingDirection).Name
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
							props.tween.easingDirection:set(newEasingDirection :: Enum.EasingDirection)
							props.updateCurrentConfiguration()
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
