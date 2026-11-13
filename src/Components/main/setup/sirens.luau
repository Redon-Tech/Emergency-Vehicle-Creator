--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local SaveLibrary = require("../../../lib/SaveLibrary")
local savePopup = require("../savePopup")
local types = require("../../../types")
local ChassisHandler = require("../../../lib/ChassisHandler")
local ConfigurationEditor = require("../../../lib/ConfigurationEditor")
local SirensEditor = require("../../../lib/ConfigurationEditor/SirensEditor")
local popup = require("../../popup")
local createChildren = require("./createChildren")
local controls = require("./controls")

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
	local sirensLoadMenu: Instance? = nil
	local viewportSize = scope:Value(Vector2.new(1820, 895))
	local scale = scope:Computed(function(use)
		return use(viewportSize).X / 1820
	end)

	local newSirenName = scope:Value("")

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

	local soundNames = scope:Computed(function(use): { string }
		local vehicle = use(props.CurrentVehicle)
		if typeof(vehicle) ~= "Instance" then
			return {}
		end
		return ChassisHandler.getSirens(vehicle)
	end)

	local modifierNames = scope:Computed(function(use): { string }
		local configuration = use(ConfigurationEditor.current)
		if configuration == nil then
			return {}
		end
		-- The editor helper uses peek, so track its input states here.
		for _, siren in use(configuration.sirens) do
			use(siren.type)
			use(siren.name)
		end
		return ConfigurationEditor.getAllModifiers()
	end)

	local rows = scope:ForPairs(sirens, function(use, scope: types.Scope, key, siren): (number, createChildren.Row)
		local sirensSaveMenu: Instance? = nil
		local keybinds: { [string]: Fusion.Child? } = {}
		local currentKeybinds = use(siren.keybinds)
		for index, keybind in currentKeybinds do
			local columnKey = tostring(index)
			keybinds[columnKey] = controls.keybindInput(scope, {
				Scale = scale,
				Value = keybind,
				Gamepad = index == 2,
				OnChange = function(value)
					ConfigurationEditor.updateSirenKeybind(key, index, value)
				end,
			})
		end

		local cells: { [string]: Fusion.Child? } = {
			type = createChildren.Dropdown<<"Siren" | "Hold" | "Modifier">>(scope, {
				Scale = scale,
				Selected = siren.type :: Fusion.StateObject<"Siren" | "Hold" | "Modifier">,
				Options = { "Siren", "Hold", "Modifier" } :: { "Siren" | "Hold" | "Modifier" },
				Height = 50,
				OnSelect = function(value: "Siren" | "Hold" | "Modifier")
					ConfigurationEditor.updateSirenType(key, value)
				end,
			}),
			keyboard = keybinds["1"],
			gamepad = keybinds["2"],
			actions = controls.actions(scope, {
				Save = scope:textButton {
					Text = "Save",
					Size = scope:Computed(function(use)
						return UDim2.fromOffset(90 * use(scale), 50 * use(scale))
					end),
					LayoutOrder = 2,
					BackgroundColor3 = currentTheme.colors.crust,
					CornerRadius = UDim.new(0, 5),
					Border = 1,
					TextScaled = true,
					MaxTextSize = 30,
					FontWeight = Enum.FontWeight.Medium,
					TextXAlignment = Enum.TextXAlignment.Center,
					Reactive = true,
					Shadow = true,
					ShadowColor3 = currentTheme.colors.mantle,
					ButtonGlow = true,
					ButtonGlowColor3 = currentTheme.colors.mantle,
					[Fusion.OnEvent "Activated"] = function()
						local menu: Instance = sirensSaveMenu
							or savePopup(scope, {
								Title = "Siren",
								Collection = SaveLibrary.sirens,
								LoadAdds = true,
								GetValue = function(): types.siren?
									local configuration = ConfigurationEditor.toConfiguration()
									return if configuration then configuration.sirens[key] else nil
								end,
								OnLoad = function(value: types.siren)
									ConfigurationEditor.addSiren(value)
								end,
							})
						sirensSaveMenu = menu
						popup:customPopup(scope, menu)
					end,
				},
				Scale = scale,
				OnDelete = function()
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
			}),
		}

		local children: Fusion.Child? = nil
		if use(siren.type) ~= "Modifier" then
			local siren = siren :: SirensEditor.SirenHoldState

			cells.name = createChildren.Dropdown(scope, {
				Scale = scale,
				Selected = siren.name,
				Options = soundNames,
				Height = 50,
				OnSelect = function(name)
					ConfigurationEditor.updateSirenName(key, name)
				end,
			})
			cells.behavior = createChildren.Dropdown<<types.SirenBehavior>>(scope, {
				Scale = scale,
				Selected = siren.behavoir,
				Options = { "Overrides Other Sounds", "Plays Simultaneously" } :: { types.SirenBehavior },
				Height = 50,
				OnSelect = function(value: types.SirenBehavior)
					ConfigurationEditor.updateSirenBehavior(key, value)
				end,
			})
			cells.modifiers = controls.button(scope, {
				Scale = scale,
				Value = "Add Modifiers",
				OnChange = function()
					ConfigurationEditor.addModifier(key)
				end,
			})
			children = {
				createChildren.Table(scope, {
					Scale = scale,
					Padding = 0,
					RowPadding = 8.5,
					HeaderHeight = 25,
					HideWhenEmpty = true,
					LayoutOrder = 1,
					Columns = {
						{ key = "name", width = UDim.new(0, 250) },
						{ key = "sound", width = UDim.new(0, 250) },
						{ key = "parentBehavior", width = UDim.new(0, 250) },
						{ key = "behavior", width = UDim.new(0, 250) },
						{ key = "delay", width = UDim.new(0, 75) },
						{ key = "actions", rightAligned = true },
					},
					Headers = {
						name = "Modifier",
						sound = "Modified siren name",
						parentBehavior = "Parent sound behavior",
						behavior = "Replay behavior",
						delay = "Delay",
					},
					Rows = scope:ForPairs(
						siren.modifiers,
						function(_, scope: types.Scope, i, modifier): (number, createChildren.Row)
							return i,
								{
									Cells = {
										name = createChildren.Dropdown(scope, {
											Scale = scale,
											Selected = modifier.name,
											Options = modifierNames,
											Height = 45,
											OnSelect = function(value)
												ConfigurationEditor.updateModifierName(key, i, value)
											end,
										}),
										sound = createChildren.Dropdown(scope, {
											Scale = scale,
											Selected = modifier.modifiedSirenName,
											Options = soundNames,
											Height = 45,
											OnSelect = function(value)
												ConfigurationEditor.updateModifierSirenName(key, i, value)
											end,
										}),
										parentBehavior = createChildren.Dropdown<<types.ModifierParentSoundBehavior>>(
											scope,
											{
												Scale = scale,
												Selected = modifier.parentSoundBehavior,
												Options = { "Play Parent Sound", "Plays Simultaneously" } :: { types.ModifierParentSoundBehavior },
												Height = 45,
												OnSelect = function(value: types.ModifierParentSoundBehavior)
													ConfigurationEditor.updateModifierParentSoundBehavior(key, i, value)
												end,
											}
										),
										behavior = createChildren.Dropdown<<types.ModifierBehavior>>(scope, {
											Scale = scale,
											Selected = modifier.behavoir,
											Options = { "Play Automatically", "Require Parent Replay" } :: { types.ModifierBehavior },
											Height = 45,
											OnSelect = function(value: types.ModifierBehavior)
												ConfigurationEditor.updateModifierBehavior(key, i, value)
											end,
										}),
										delay = controls.numberInput(scope, {
											Scale = scale,
											Value = modifier.delay,
											Height = 45,
											OnChange = function(value)
												ConfigurationEditor.updateModifierDelay(key, i, value)
											end,
										}),
										actions = controls.actions(scope, {
											Scale = scale,
											Height = 45,
											OnDelete = function()
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
										}),
									},
								}
						end
					),
				}),
			}
		else
			cells.name = controls.textInput(scope, {
				Scale = scale,
				Value = siren.name,
				Height = 50,
				OnChange = function(name)
					ConfigurationEditor.updateSirenName(key, name)
				end,
			})
		end

		if #currentKeybinds > 2 then
			local extraBindings: { Fusion.Child } = {}
			for index = 3, #currentKeybinds do
				table.insert(
					extraBindings,
					createChildren.Field(scope, {
						Scale = scale,
						Label = `Keybind {index}`,
						LayoutOrder = index,
						Content = keybinds[tostring(index)] or {},
					})
				)
			end
			children = { children or {}, extraBindings }
		end

		return key,
			{
				BackgroundColor3 = if key % 2 == 0 then currentTheme.colors.mantle else currentTheme.colors.crust,
				Cells = cells,
				Children = children,
				ChildrenHidden = scope:Computed(function(use)
					return if use(siren.type) ~= "Modifier" then #use(siren.modifiers) == 0 else true
				end),
			}
	end)

	-- 1820, 895
	local content = {
		scope:base {
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			[Fusion.Out "AbsoluteSize"] = viewportSize :: unknown,

			[Fusion.Children] = {
				scope:New("UIListLayout") {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = scope:Computed(function(use)
						return UDim.new(0, 15 * use(scale))
					end),
				},
				scope:New("UIPadding") {
					PaddingTop = UDim.new(0.0145251397, 0),
				},

				scope:base {
					Size = UDim2.fromScale(1, 0.0558659218),
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					ZIndex = 2,

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
							LayoutOrder = 3,
							Text = "Load",
							BackgroundColor3 = currentTheme.colors.crust,
							CornerRadius = UDim.new(0.2, 0),
							Border = 2,
							TextScaled = true,
							MaxTextSize = 30,
							FontWeight = Enum.FontWeight.Bold,
							TextXAlignment = Enum.TextXAlignment.Center,
							Reactive = true,
							MaxSize = Vector2.new(175, 50),
							[Fusion.OnEvent "Activated"] = function()
								local menu: Instance = sirensLoadMenu
									or savePopup(scope, {
										Title = "Siren",
										Collection = SaveLibrary.sirens,
										LoadAdds = true,
										OnLoad = function(value: types.siren)
											ConfigurationEditor.addSiren(value)
										end,
									})
								sirensLoadMenu = menu
								popup:customPopup(scope, menu)
							end,
						},
					},
				},

				scope:base {
					ClassName = "ScrollingFrame",
					ZIndex = 1,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = currentTheme.colors.text,
					TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
					BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					ClipsDescendants = true,

					Size = UDim2.fromScale(1, 0.8882681564),
					BackgroundColor3 = currentTheme.colors.mantle,
					CornerRadius = UDim.new(0.0182926829, 0),
					LayoutOrder = 1,
					[Fusion.Children] = Fusion.Child {
						scope:New("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder },
						createChildren.Table(scope, {
							Scale = scale,
							Headers = {
								name = "Sound name",
								type = "Type",
								behavior = "Sound behavior",
								keyboard = "Keyboard",
								gamepad = "Gamepad",
							},
							Columns = {
								{ key = "name", width = UDim.new(0, 250) },
								{ key = "type", width = UDim.new(0, 250) },
								{ key = "behavior", width = UDim.new(0, 250) },
								{ key = "keyboard", width = UDim.new(0, 250) },
								{ key = "gamepad", width = UDim.new(0, 250) },
								{ key = "modifiers", width = UDim.new(0, 250) },
								{ key = "actions", rightAligned = true },
							},
							RowSpacing = 0,
							Rows = rows,
						}),
					},
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
