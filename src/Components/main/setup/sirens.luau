--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local types = require("../../../types")
local ChassisHandler = require("../../../lib/ChassisHandler")
local ConfigurationEditor = require("../../../lib/ConfigurationEditor")
local SirensEditor = require("../../../lib/ConfigurationEditor/SirensEditor")
local popup = require("../../popup")
local createChildren = require("./createChildren")

type props = {
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
}

--[[
	Sirens
	Creates the sirens page for the main app
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()

	local newSirenName = scope:Value("")
	local actualTableSize = scope:Value(Vector2.one)

	local sirens = scope:Computed(function(use)
		local currentConfiguration = use(ConfigurationEditor.current)
		if currentConfiguration == nil then
			return {}
		end
		local currentSirens = use(currentConfiguration.sirens)
		if currentSirens == nil then
			return {}
		end
		return currentSirens
	end)

	-- 1820, 895
	local content = {
		scope:base {
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,

			[Fusion.Children] = {
				scope:New("UIListLayout") {
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
				scope:New("UIPadding") {
					PaddingTop = UDim.new(0.0145251397, 0),
				},

				scope:base {
					Size = UDim2.fromScale(1, 0.0558659218),
					BackgroundTransparency = 1,
					LayoutOrder = 0,

					[Fusion.Children] = {
						scope:New("UIListLayout") {
							Padding = UDim.new(0.0164835165, 0),
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
						},

						scope:textBox {
							Size = UDim2.fromScale(0.1648351648, 1),
							MaxSize = Vector2.new(300, 50),
							BackgroundColor3 = currentTheme.colors.crust,
							CornerRadius = UDim.new(0.2, 0),
							Border = 1,
							PlaceholderText = "New Siren Name",
							[Fusion.Out "Text"] = newSirenName,
							TextScaled = true,
							MaxTextSize = 30,
							FontWeight = Enum.FontWeight.Regular,
							TextXAlignment = Enum.TextXAlignment.Left,
							LayoutOrder = 1,
							PaddingBottom = UDim.new(0.2, 0),
							PaddingTop = UDim.new(0.2, 0),
							PaddingLeft = UDim.new(0.0333333333, 0),
							PaddingRight = UDim.new(0.0333333333, 0),
						},

						scope:textButton {
							Size = UDim2.fromScale(0.0961538462, 1),
							MaxSize = Vector2.new(175, 50),
							BackgroundColor3 = currentTheme.colors.crust,
							CornerRadius = UDim.new(0.2, 0),
							Border = 2,
							Text = "Add",
							TextScaled = true,
							MaxTextSize = 30,
							FontWeight = Enum.FontWeight.Bold,
							LayoutOrder = 2,
							Reactive = true,

							[Fusion.OnEvent "Activated"] = function()
								local newSirenName = scope.peek(newSirenName)
								if newSirenName == "" then
									newSirenName = "Wail"
								end

								local newSirenData: types.siren = {
									name = newSirenName,
									type = "Siren",
									behavoir = "Overrides Other Sounds",
									keybinds = {
										Enum.KeyCode.R,
										Enum.KeyCode.DPadRight,
									},
									modifiers = {},
								}

								ConfigurationEditor.addSiren(newSirenData)
							end,
						},

						scope:textButton {
							Size = UDim2.fromScale(0.0961538462, 1),
							MaxSize = Vector2.new(175, 50),
							BackgroundColor3 = currentTheme.colors.crust,
							CornerRadius = UDim.new(0.2, 0),
							Border = 2,
							Text = "Import",
							TextScaled = true,
							MaxTextSize = 30,
							FontWeight = Enum.FontWeight.Bold,
							LayoutOrder = 3,
							Reactive = true,
						},
					},
				},

				scope:base {
					Size = UDim2.fromScale(1, 0.0558659218),
					BackgroundTransparency = 1,
					LayoutOrder = 1,

					[Fusion.Children] = Fusion.Child {
						scope:New("UIListLayout") {
							Padding = UDim.new(0.0082417582, 0),
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
						},

						scope:New("UIPadding") {
							PaddingLeft = UDim.new(0.0082417582, 0),
						},

						scope:ForPairs(
							{ "Sound name", "Type", "Sound behavior", "Keyboard", "Gamepad" },
							function(_, scope: typeof(scope), key: number, value: string)
								return key,
									scope:textLabel {
										Size = UDim2.fromScale(0.1373626374, 1),
										Text = value,
										FontWeight = Enum.FontWeight.Medium,
										TextXAlignment = Enum.TextXAlignment.Left,
										TextScaled = true,
										MaxTextSize = 16,
										BackgroundTransparency = 1,
										LayoutOrder = key,
									}
							end
						),
					},
				},

				scope:list {
					Size = UDim2.fromScale(1, 0.8324022346), -- 895 -75-75 total 745
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 1),
					BackgroundColor3 = currentTheme.colors.mantle,
					AlternateColor3 = currentTheme.colors.crust,
					RowSize = UDim2.fromScale(1, 0), -- 1820, 75
					PrimaryColor = "Alternate" :: "Alternate",
					CornerRadius = UDim.new(0.0182926829, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 2,
					[Fusion.Out "AbsoluteSize"] = actualTableSize,
					Rows = scope:ForPairs(sirens, function(_, scope: typeof(scope), key: number, siren)
						local rowSize = scope:Value(75)
						local bg = scope:Spring(scope:Value(1), 10, 1)
						bg:setPosition(0)

						return key,
							scope:base {
								Size = scope:Computed(function(use)
									return UDim2.new(1, 0, 0, (use(rowSize) / 745) * use(actualTableSize).Y)
								end),
								BackgroundColor3 = currentTheme.colors.surface0,
								BackgroundTransparency = bg,

								[Fusion.Children] = createChildren(scope, {
									rowSize = rowSize,
									options = scope:Computed(function(use)
										local options: { createChildren.option } = {
											{
												type = "select",
												value = siren.name,
												layoutOrder = 1,
												options = scope:Computed(function(use)
													local currentVehicle = use(props.CurrentVehicle)
													if
														currentVehicle == nil
														or typeof(currentVehicle) ~= "Instance"
													then
														return {}
													end
													return ChassisHandler.getSirens(currentVehicle)
												end),
												selectionChanged = function(newValue)
													ConfigurationEditor.updateSirenName(key, newValue)
												end,
											},
											{
												type = "select",
												value = siren.type,
												layoutOrder = 2,
												options = { "Siren", "Hold", "Modifier" },
												selectionChanged = function(newValue)
													ConfigurationEditor.updateSirenType(key, newValue)
												end,
											},
										}

										if use(siren.type) ~= "Modifier" then
											local siren = siren :: SirensEditor.SirenHoldState
											table.insert(
												options,
												3,
												{
													type = "select",
													value = siren.behavoir,
													layoutOrder = 3,
													options = { "Overrides Other Sounds", "Plays Simultaneously" },
													selectionChanged = function(newValue)
														ConfigurationEditor.updateSirenBehavior(key, newValue)
													end,
												} :: createChildren.option
											)

											table.insert(options, {
												type = "button",
												text = "Add Modifier",
												layoutOrder = 4000,
												callback = function()
													ConfigurationEditor.addModifier(key)
												end,
											})
										else
											table.insert(
												options,
												3,
												{
													type = "spacer",
													layoutOrder = 3,
												} :: createChildren.option
											)
										end

										for i, keybind in use(siren.keybinds) do
											table.insert(
												options,
												i + 3,
												{
													type = if i == 2 then "controllerKeycode" else "keycode",
													value = keybind,
													layoutOrder = i + 3,
													focusLost = function(newValue)
														ConfigurationEditor.updateSirenKeybind(key, i, newValue)
													end,
												} :: createChildren.option
											)
										end

										return options
									end),
									childOptions = scope:Computed(function(use): { createChildren.childOption }?
										if use(siren.type) ~= "Modifier" then
											local siren = siren :: SirensEditor.SirenHoldState
											local options = {}

											for i, modifierState in use(siren.modifiers) do
												local modifier = scope.peek(modifierState)
												table.insert(options, i, {
													options = {
														{
															type = "select",
															value = modifier.name,
															layoutOrder = 1,
															options = scope:Computed(function(use)
																local currentConfiguration =
																	use(ConfigurationEditor.current)
																if currentConfiguration == nil then
																	return {}
																end
																use(currentConfiguration.lightSettings)
																return ConfigurationEditor.getAllModifiers()
															end),
															selectionChanged = function(newValue)
																ConfigurationEditor.updateModifierName(key, i, newValue)
															end,
															header = "Modifier",
														} :: createChildren.option,
														{
															type = "select",
															value = modifier.modifiedSirenName,
															layoutOrder = 2,
															options = scope:Computed(function(use)
																local currentVehicle = use(props.CurrentVehicle)
																if
																	currentVehicle == nil
																	or typeof(currentVehicle) ~= "Instance"
																then
																	return {}
																end
																return ChassisHandler.getSirens(currentVehicle)
															end),
															selectionChanged = function(newValue)
																ConfigurationEditor.updateModifierSirenName(
																	key,
																	i,
																	newValue
																)
															end,
															header = "Modified Siren Name",
														},
														{
															type = "select",
															value = modifier.parentSoundBehavior,
															layoutOrder = 3,
															options = {
																"Play Parent Sound",
																"Plays Simultaneously",
															},
															selectionChanged = function(newValue)
																ConfigurationEditor.updateModifierParentSoundBehavior(
																	key,
																	i,
																	newValue
																)
															end,
															header = "Modifier Behavior",
														},
														{
															type = "select",
															value = modifier.behavoir,
															layoutOrder = 4,
															options = {
																"Play Automatically",
																"Require Parent Replay",
															},
															selectionChanged = function(newValue)
																ConfigurationEditor.updateModifierBehavior(
																	key,
																	i,
																	newValue
																)
															end,
															header = "",
														},
														{
															type = "number",
															value = modifier.delay,
															layoutOrder = 5,
															focusLost = function(newValue)
																ConfigurationEditor.updateModifierDelay(
																	key,
																	i,
																	newValue
																)
															end,
															header = "Delay (Seconds)",
														},
													},
													onDelete = function()
														popup:addPopup(scope, {
															title = "Delete Modifier",
															description = "Are you sure you want to delete this modifier?\n<b>All data will be lost.</b>",
															actions = {
																{
																	text = "Cancel",
																	type = "primary",
																	key = 1,
																	callback = function(newPopup)
																		popup:removePopup(newPopup)
																	end,
																	keybind = Enum.KeyCode.Escape,
																},
																{
																	text = "Delete",
																	type = "danger",
																	key = 2,
																	callback = function(newPopup)
																		popup:removePopup(newPopup)
																		ConfigurationEditor.removeModifier(key, i)
																	end,
																	keybind = Enum.KeyCode.Return,
																},
															},
														})
													end,
												})
											end

											return options
										end

										return
									end),
									actualTableSize = actualTableSize,

									onDelete = function()
										popup:addPopup(scope, {
											title = "Delete Siren",
											description = "Are you sure you want to delete this siren?\n<b>All data will be lost.</b>",
											actions = {
												{
													text = "Cancel",
													type = "primary",
													key = 1,
													callback = function(newPopup)
														popup:removePopup(newPopup)
													end,
													keybind = Enum.KeyCode.Escape,
												},
												{
													text = "Delete",
													type = "danger",
													key = 2,
													callback = function(newPopup)
														popup:removePopup(newPopup)
														ConfigurationEditor.removeSiren(key)
													end,
													keybind = Enum.KeyCode.Return,
												},
											},
										})
									end,
									onDownload = function() end,
								}),
							}
					end),
				},
			},
		},
	}

	return scope:base {
		Name = "Sirens",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Spring(
			scope:Computed(function(use)
				local currentPage = use(props.CurrentPage)
				if currentPage == "Sirens" then
					return UDim2.fromScale(0.5, 0.0462962963)
				elseif currentPage == "Light Settings" then
					return UDim2.fromScale(-1, 0.0462962963)
				end
				return UDim2.fromScale(1.5, 0.0462962963)
			end),
			20,
			0.75
		),
		Size = UDim2.fromScale(1, 0.9537037037),
		BackgroundColor3 = currentTheme.colors.base,

		[Fusion.Children] = {
			scope:New("UIAspectRatioConstraint") {
				AspectRatio = 1.8640776699,
			},

			scope:New("UIPadding") {
				PaddingTop = UDim.new(0.0231481481, 0),
				PaddingBottom = UDim.new(0.0231481481, 0),
				PaddingLeft = UDim.new(0.0260416667, 0),
				PaddingRight = UDim.new(0.0260416667, 0),
			},

			scope:textLabel {
				Size = UDim2.fromScale(1, 0.0555555556),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Text = "Vehicle Sirens",
				FontWeight = Enum.FontWeight.Bold,
				TextScaled = true,
			},

			scope:base {
				Size = UDim2.fromScale(1, 0.9212962963),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundColor3 = currentTheme.colors.mantle,
				CornerRadius = UDim.new(0.0179640719, 0),
				ClipsDescendants = true,

				[Fusion.Children] = content,
			},
		},
	}
end
