--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local types = require("../../../../types")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local FunctionsEditor = require("../../../../lib/ConfigurationEditor/FunctionsEditor")
local popup = require("../../../popup")
local createChildren = require("../createChildren")
local controls = require("../controls")
local VehicleHandler = require("../../../../lib/VehicleHandler")

type ActivationType = "Standard" | "Default" | "Override" | "AG-Event"

local function addButton(
	scope: types.Scope,
	currentTheme: typeof(RedonUI.theme.mocha),
	buttonText: Fusion.UsedAs<string>,
	onPress: () -> ()
): Fusion.Child
	return scope:base {
		Size = UDim2.fromScale(1, 0.0914634146),
		BackgroundTransparency = 1,
		LayoutOrder = 1000,

		[Fusion.Children] = {
			scope:textButton {
				Size = UDim2.fromScale(1, 0.6666666667),
				MaxSize = Vector2.new(175, 50),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = currentTheme.colors.crust,
				CornerRadius = UDim.new(0, 5),
				Border = 1,
				Text = buttonText,
				TextScaled = true,
				MaxTextSize = 30,
				FontWeight = Enum.FontWeight.Medium,
				TextXAlignment = Enum.TextXAlignment.Center,
				Reactive = true,

				[Fusion.OnEvent "Activated"] = function()
					onPress()
				end,
			},
		},
	}
end

type props = {
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
	ReturnTo: Fusion.Value<types.returnTo>,
	firstScope: types.Scope,
	currentContent: Fusion.Value<"functions" | "activation" | "patterns">,
	selectedFunction: Fusion.Value<number?>,
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Activations Page
	Creates the activations page for the functions page
]]
return function(scope: types.Scope, props: props)
	local currentTheme = RedonUI.theme.theme:now()
	local viewportSize = scope:Value(Vector2.new(1820, 895))
	local scale = scope:Computed(function(use)
		return use(viewportSize).X / 1820
	end)

	local currentFunction = scope:Computed(function(use): FunctionsEditor.FunctionState?
		local currentConfiguration = use(ConfigurationEditor.current)
		if currentConfiguration == nil then
			return nil
		end
		local currentFunctions = use(currentConfiguration.functions)
		local selectedFunction = use(props.selectedFunction)
		if selectedFunction == nil then
			return nil
		end
		local currentFunction = use(currentFunctions)[selectedFunction]
		if currentFunction == nil then
			return nil
		end
		return currentFunction
	end)

	local patterns = scope:Computed(function(use)
		local currentFunction = use(currentFunction)
		if currentFunction == nil then
			return {}
		end

		local currentPatterns = use(currentFunction.patterns)
		if currentPatterns == nil then
			return {}
		end
		return currentPatterns
	end)

	local currentActivations = scope:Computed(function(use)
		local currentFunction = use(currentFunction)
		if currentFunction == nil then
			return {}
		end

		local currentActivations = use(currentFunction.activations)
		if currentActivations == nil then
			return {}
		end
		return currentActivations
	end)

	local activationTypes = scope:Computed(function(use): { ActivationType }
		local options: { ActivationType } = { "Standard", "Default", "Override" }
		local vehicle = use(props.CurrentVehicle)
		if typeof(vehicle) == "Instance" then
			local vehicleType = VehicleHandler:isValidVehicle(vehicle)
			if vehicleType == "ag" or vehicleType == "mg" then
				table.insert(options, "AG-Event")
			end
		end
		return options
	end)

	local sirenNames = scope:Computed(function(use): { string }
		local configuration = use(ConfigurationEditor.current)
		local names = {}
		if configuration ~= nil then
			for _, siren in use(configuration.sirens) do
				table.insert(names, use(siren.name))
			end
		end
		return names
	end)

	local dependentFunctions = scope:Computed(function(use): { string }
		local names = { "No Dependent Function" }
		local configuration = use(ConfigurationEditor.current)
		local selected = use(props.selectedFunction)
		if configuration ~= nil then
			for index, func in use(configuration.functions) do
				if index ~= selected then
					table.insert(names, use(func.name))
				end
			end
		end
		return names
	end)

	local patternRows = scope:ForPairs(
		patterns,
		function(_, scope: types.Scope, key: number): (number, createChildren.Row)
			local index = scope:Value(key)
			return key,
				{
					BackgroundColor3 = if key % 2 == 0 then currentTheme.colors.mantle else currentTheme.colors.crust,
					Cells = {
						index = controls.numberInput(scope, {
							Scale = scale,
							Value = index,
							OnChange = function(newIndex)
								local selectedFunction = scope.peek(props.selectedFunction)
								if selectedFunction == nil or newIndex < 1 or newIndex % 1 ~= 0 then
									index:set(key, true)
									return
								end
								newIndex = math.min(newIndex, #scope.peek(patterns))
								ConfigurationEditor.updatePatternPosition(selectedFunction, key, newIndex)
								local selected = scope.peek(props.CurrentPattern)
								if selected ~= nil and selected.functionId == selectedFunction then
									local patternId = selected.patternId
									if patternId == key then
										patternId = newIndex
									elseif key < patternId and patternId <= newIndex then
										patternId -= 1
									elseif newIndex <= patternId and patternId < key then
										patternId += 1
									end
									props.CurrentPattern:set({
										functionId = selectedFunction,
										patternId = patternId,
									})
								end
							end,
							TextXAlignment = Enum.TextXAlignment.Center,
						}),
						actions = controls.actions(scope, {
							Scale = scale,
							OnEdit = function()
								local selectedFunction = scope.peek(props.selectedFunction)
								if selectedFunction == nil then
									return
								end
								props.CurrentPattern:set({ functionId = selectedFunction, patternId = key })
								props.CurrentPage:set("Flashers")
								props.CurrentPanel:set("ELS Setup")
								props.ReturnTo:set("vehicleSetup")
							end,
							OnDelete = function()
								popup:addPopup(scope, {
									title = "Delete Pattern",
									description = "Are you sure you want to delete this pattern?\n<b>All data will be lost.</b>",
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
												local selectedFunction = scope.peek(props.selectedFunction)
												if selectedFunction == nil then
													return
												end
												ConfigurationEditor.removePattern(selectedFunction, key)
												local selected = scope.peek(props.CurrentPattern)
												if selected ~= nil and selected.functionId == selectedFunction then
													if selected.patternId == key then
														props.CurrentPattern:set(nil)
													elseif selected.patternId > key then
														props.CurrentPattern:set({
															functionId = selectedFunction,
															patternId = selected.patternId - 1,
														})
													end
												end
											end,
										},
									},
								})
							end,
							OnDownload = function() end,
						}),
					},
				}
		end
	)

	local activationRows = scope:ForPairs(
		currentActivations,
		function(use, scope: types.Scope, key, value): (number, createChildren.Row)
			local selectedFunction = use(props.selectedFunction)
			if selectedFunction == nil then
				return key, { Cells = {} }
			end

			local settings: { [string]: Fusion.Child? } = {}
			local columns: { createChildren.Column } = {}
			local function field(name: string, content: Fusion.Child, width: number, visible: Fusion.UsedAs<boolean>?)
				local fieldKey = tostring(#columns + 1)
				table.insert(columns, {
					key = fieldKey,
					width = scope:Computed(function(use)
						return if use(visible) == false then UDim.new(0, 0) else UDim.new(0, width)
					end),
				})
				settings[fieldKey] = createChildren.Field(scope, {
					Scale = scale,
					Label = name,
					Content = content,
					Visible = visible,
				})
			end

			local activationType = use(value.type)
			if activationType == "Standard" then
				local activation = value :: FunctionsEditor.StandardActivationState
				field(
					"Mode",
					createChildren.Dropdown<<types.StandardActivationModes>>(scope, {
						Scale = scale,
						Selected = activation.mode,
						Options = { "Cycle", "Set Pattern" } :: { types.StandardActivationModes },
						Height = 50,
						OnSelect = function(mode: types.StandardActivationModes)
							ConfigurationEditor.updateStandardActivationMode(selectedFunction, key, mode)
						end,
					}),
					250
				)
				field(
					"Pattern",
					controls.numberInput(scope, {
						Scale = scale,
						Value = activation.pattern,
						Disabled = scope:Computed(function(use)
							return use(activation.mode) == "Cycle"
						end),
						OnChange = function(pattern)
							ConfigurationEditor.updateStandardActivationPattern(selectedFunction, key, pattern)
						end,
					}),
					75
				)
				for keybindIndex, keybind in use(activation.keybinds) do
					field(
						if keybindIndex == 2 then "Gamepad" else "Keyboard",
						controls.keybindInput(scope, {
							Scale = scale,
							Value = keybind,
							Gamepad = keybindIndex == 2,
							OnChange = function(keycode)
								ConfigurationEditor.updateStandardActivationKeybind(
									selectedFunction,
									key,
									keybindIndex,
									keycode
								)
							end,
						}),
						250
					)
				end
			elseif activationType == "Override" then
				local activation = value :: FunctionsEditor.OverrideActivationState
				field(
					"Mode",
					createChildren.Dropdown<<types.OverrideActivationModes>>(scope, {
						Scale = scale,
						Selected = activation.mode,
						Options = { "Siren Override", "Park", "Brake", "Reverse" } :: { types.OverrideActivationModes },
						Height = 50,
						OnSelect = function(mode: types.OverrideActivationModes)
							ConfigurationEditor.updateOverrideActivationMode(selectedFunction, key, mode)
						end,
					}),
					250
				)
				field(
					"Siren",
					createChildren.Dropdown(scope, {
						Scale = scale,
						Selected = scope:Computed(function(use)
							return use(activation.siren) or "None"
						end),
						Options = sirenNames,
						Height = 50,
						OnSelect = function(name)
							ConfigurationEditor.updateOverrideActivationSiren(selectedFunction, key, name)
						end,
					}),
					250,
					scope:Computed(function(use)
						return use(activation.mode) == "Siren Override"
					end)
				)
				field(
					"Dependent function",
					createChildren.Dropdown(scope, {
						Scale = scale,
						Selected = activation.dependentFunction,
						Options = dependentFunctions,
						Height = 50,
						OnSelect = function(name)
							ConfigurationEditor.updateOverrideActivationDependentFunction(selectedFunction, key, name)
						end,
					}),
					250
				)
				field(
					"and Pattern",
					controls.numberInput(scope, {
						Scale = scale,
						Value = activation.dependentPattern,
						OnChange = function(pattern)
							ConfigurationEditor.updateOverrideActivationDependentPattern(selectedFunction, key, pattern)
						end,
						Disabled = scope:Computed(function(use)
							return use(activation.dependentFunction) == "No Dependent Function"
						end),
					}),
					100
				)
			elseif activationType == "Default" then
				local activation = value :: FunctionsEditor.DefaultActivationState
				field(
					"Pattern",
					controls.numberInput(scope, {
						Scale = scale,
						Value = activation.pattern,
						OnChange = function(pattern)
							ConfigurationEditor.updateDefaultActivationPattern(selectedFunction, key, pattern)
						end,
					}),
					75
				)
			elseif activationType == "AG-Event" then
				local activation = value :: FunctionsEditor.AGEventActivationState
				field(
					"Mode",
					createChildren.Dropdown<<types.AGEventActivationModes>>(scope, {
						Scale = scale,
						Selected = activation.mode,
						Options = { "Stages", "Traffic Advisor", "Scene", "Ally Left", "Ally Right", "Rear Scene" } :: { types.AGEventActivationModes },
						Height = 50,
						OnSelect = function(mode: types.AGEventActivationModes)
							ConfigurationEditor.updateAGEventActivationMode(selectedFunction, key, mode)
						end,
					}),
					250
				)
			end

			return key,
				{
					BackgroundColor3 = if key % 2 == 0 then currentTheme.colors.mantle else currentTheme.colors.crust,
					Cells = {
						type = createChildren.Field(scope, {
							Scale = scale,
							Label = "Type",
							Content = createChildren.Dropdown<<ActivationType>>(scope, {
								Scale = scale,
								Selected = value.type :: Fusion.StateObject<ActivationType>,
								Options = activationTypes,
								Height = 50,
								OnSelect = function(newType: ActivationType)
									ConfigurationEditor.updateActivationType(selectedFunction, key, newType)
								end,
							}),
						}),
						settings = createChildren.Table(scope, {
							AutoWidth = true,
							Scale = scale,
							Columns = columns,
							Padding = 0,
							RowPadding = 0,
							Rows = { { Cells = settings } },
						}),
						actions = createChildren.Field(scope, {
							Scale = scale,
							Label = "",
							Content = controls.actions(scope, {
								Scale = scale,
								OnDelete = function()
									popup:addPopup(scope, {
										title = "Delete Activation",
										description = "Are you sure you want to delete this activation?\n<b>All data will be lost.</b>",
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
													ConfigurationEditor.removeActivation(selectedFunction, key)
												end,
												keybind = Enum.KeyCode.Return,
											},
										},
									})
								end,
								OnDownload = function() end,
							}),
						}),
					},
				}
		end
	)

	local contentChooserXSize = 0.1098901099
	return scope:base {
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = scope:Spring(
			scope:Computed(function(use)
				local activeContent = use(props.currentContent)
				if activeContent ~= "functions" then
					return UDim2.fromScale(0.5, 0.5)
				else
					return UDim2.fromScale(1.5, 0.5)
				end
			end),
			SPRING_SPEED,
			SPRING_DAMPING
		),
		BackgroundTransparency = 1,
		[Fusion.Out "AbsoluteSize"] = viewportSize :: unknown,
		ClipsDescendants = true,

		[Fusion.Children] = {
			scope:base {
				Size = UDim2.fromScale(1, 0.0558659218),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0145251397),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				ZIndex = 2,

				[Fusion.Children] = {
					scope:textButton {
						TextLabelSize = UDim2.fromScale(1, 1),
						Size = UDim2.fromScale(0.2, 1),
						Position = UDim2.fromScale(0.0054945055, -0.12),
						TextScaled = true,
						Text = "<- Return To Functions",
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextColor3 = currentTheme.colors.text,
						FontWeight = Enum.FontWeight.Medium,
						MaxTextSize = 20,
						Reactive = true,
						AnimateSize = false,

						[Fusion.OnEvent "Activated"] = function()
							props.currentContent:set("functions")
							props.selectedFunction:set(nil)
						end :: unknown,
					},

					scope:base {
						CornerRadius = UDim.new(0.5, 0),
						BackgroundColor3 = currentTheme.colors.blue,
						Size = UDim2.fromScale(contentChooserXSize, 0.2),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = scope:Spring(
							scope:Computed(function(use)
								local currentContent = use(props.currentContent)
								if currentContent == "functions" then
									return UDim2.fromScale(1, 0)
								end
								if currentContent == "activation" then
									return UDim2.fromScale(0.5 + (contentChooserXSize / 2 + 0.0082417583), 0.9)
								else
									return UDim2.fromScale(0.5 - (contentChooserXSize / 2 + 0.0082417583), 0.9)
								end
							end),
							SPRING_SPEED,
							SPRING_DAMPING
						),
					},

					scope:base {
						Size = UDim2.fromScale(1, 1),
						Position = UDim2.fromScale(0, -0.12),
						BackgroundTransparency = 1,

						[Fusion.Children] = Fusion.Child {
							scope:New("UIListLayout") {
								Padding = UDim.new(0.0164835165, 0),
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
							},

							scope:ForPairs(
								{ "Patterns", "Activation" },
								function(_, scope: typeof(scope), key: number, value: string)
									local loweredValue = value:lower()
									return key,
										scope:textButton {
											Size = UDim2.fromScale(contentChooserXSize, 1),
											BackgroundTransparency = 1,
											TextColor3 = scope:Computed(function(use)
												return use(props.currentContent) == loweredValue
														and currentTheme.colors.blue
													or currentTheme.colors.text
											end),
											Text = value,
											TextScaled = true,
											MaxTextSize = 30,
											FontWeight = scope:Computed(function(use)
												return use(props.currentContent) == loweredValue
														and Enum.FontWeight.Bold
													or Enum.FontWeight.Regular
											end),
											LayoutOrder = key,
											Reactive = true,
											AnimateSize = false,

											[Fusion.OnEvent "Activated"] = function()
												props.currentContent:set(loweredValue :: "activation" | "patterns")
											end,
										}
								end
							),
						},
					},
				},
			},

			--TODO: This can be seperated into its own section
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

				Size = UDim2.fromScale(1, 0.9162011173), -- 895 -75 total 820
				AnchorPoint = Vector2.new(0.5, 1),
				Position = scope:Spring(
					scope:Computed(function(use)
						local activeContent = use(props.currentContent)
						if activeContent == "patterns" then
							return UDim2.fromScale(0.5, 1)
						elseif activeContent == "activation" then
							return UDim2.fromScale(-1, 1)
						else
							return UDim2.fromScale(1.5, 1)
						end
					end),
					SPRING_SPEED,
					SPRING_DAMPING
				),
				BackgroundColor3 = currentTheme.colors.mantle,
				CornerRadius = UDim.new(0.0182926829, 0),

				[Fusion.Children] = Fusion.Child {
					scope:New("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder },
					createChildren.Table(scope, {
						Scale = scale,
						Columns = {
							{ key = "index", width = UDim.new(0, 50) },
							{ key = "actions", rightAligned = true },
						},
						Headers = { index = "#" },
						RowSpacing = 0,
						Rows = patternRows,
					}),
					addButton(scope, currentTheme, "Add Pattern", function()
						local selectedFunction = scope.peek(props.selectedFunction)
						if selectedFunction == nil then
							return
						end
						ConfigurationEditor.addPattern(selectedFunction, { flashers = {}, faders = {}, rotators = {} })
					end),
				},
			},

			--TODO: This can be seperated into its own section
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

				Size = UDim2.fromScale(1, 0.9162011173), -- 895 -75 total 820
				AnchorPoint = Vector2.new(0.5, 1),
				Position = scope:Spring(
					scope:Computed(function(use)
						local activeContent = use(props.currentContent)
						if activeContent == "activation" then
							return UDim2.fromScale(0.5, 1)
						else
							return UDim2.fromScale(1.5, 1)
						end
					end),
					SPRING_SPEED,
					SPRING_DAMPING
				),
				BackgroundColor3 = currentTheme.colors.mantle,
				CornerRadius = UDim.new(0.0182926829, 0),

				[Fusion.Children] = Fusion.Child {
					scope:New("UIListLayout") { SortOrder = Enum.SortOrder.LayoutOrder },
					createChildren.Table(scope, {
						Scale = scale,
						Columns = {
							{ key = "type", width = UDim.new(0, 250) },
							{ key = "settings" },
							{ key = "actions", rightAligned = true },
						},
						RowSpacing = 0,
						Rows = activationRows,
					}),
					addButton(scope, currentTheme, "Add Activation", function()
						local selectedFunction = scope.peek(props.selectedFunction)
						if selectedFunction == nil then
							return
						end
						ConfigurationEditor.addActivation(selectedFunction, {
							type = "Standard",
							mode = "Cycle",
							pattern = 0,
							keybinds = { Enum.KeyCode.J, Enum.KeyCode.DPadLeft },
						})
					end),
				},
			},
		},
	}
end
