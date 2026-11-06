--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local types = require("../../../types")
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
				scope:base {
					Size = UDim2.fromScale(1, 0.0558659218),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.0145251397),
					BackgroundTransparency = 1,

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

				scope:list {
					Size = UDim2.fromScale(1, 0.9162011173), -- 895 -75 total 820
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.fromScale(0.5, 1),
					BackgroundColor3 = currentTheme.colors.mantle,
					AlternateColor3 = currentTheme.colors.crust,
					RowSize = UDim2.fromScale(1, 0), -- 1820, 75
					PrimaryColor = "Alternate" :: "Alternate",
					CornerRadius = UDim.new(0.0182926829, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Fusion.Out "AbsoluteSize"] = actualTableSize,
					Rows = scope:ForPairs(sirens, function(_, scope: typeof(scope), key: number, siren)
						local rowSize = scope:Value(75)
						local bg = scope:Spring(scope:Value(1), 10, 1)
						bg:setPosition(0)

						return key,
							scope:base {
								Size = scope:Computed(function(use)
									return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(actualTableSize).Y)
								end),
								BackgroundColor3 = currentTheme.colors.surface0,
								BackgroundTransparency = bg,

								[Fusion.Children] = createChildren(scope, {
									rowSize = rowSize,
									options = scope:Computed(function(use)
										local options: { createChildren.option } = {
											{
												type = "string",
												value = siren.name,
												layoutOrder = 1,
												focusLost = function(newValue)
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
											table.insert(options, {
												type = "select",
												value = siren.behavoir,
												layoutOrder = 3,
												options = { "Overrides Other Sounds", "Plays Simultaneously" },
												selectionChanged = function(newValue)
													ConfigurationEditor.updateSirenBehavior(key, newValue)
												end,
											})

											table.insert(options, {
												type = "button",
												text = "Add Modifier",
												layoutOrder = 4000,
												callback = function()
													ConfigurationEditor.addModifier(key)
												end,
											})
										end

										for i, keybind in use(siren.keybinds) do
											table.insert(options, {
												type = "keycode",
												value = keybind,
												layoutOrder = i + 3,
												focusLost = function(newValue)
													ConfigurationEditor.updateSirenKeybind(key, i, newValue)
												end,
											})
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
														} :: createChildren.option,
														{
															type = "string",
															value = modifier.modifiedSirenName,
															layoutOrder = 2,
															focusLost = function(newValue)
																ConfigurationEditor.updateModifierSirenName(
																	key,
																	i,
																	newValue
																)
															end,
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
