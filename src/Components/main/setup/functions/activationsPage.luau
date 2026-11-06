--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local types = require("../../../../types")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local FunctionsEditor = require("../../../../lib/ConfigurationEditor/FunctionsEditor")
local popup = require("../../../popup")
local createChildren = require("../createChildren")
local VehicleHandler = require("../../../../lib/VehicleHandler")

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
	UnsavedChanges: Fusion.Value<boolean>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
	ReturnTo: Fusion.Value<types.returnTo>,
	firstScope: types.Scope,
	currentContent: Fusion.Value<"functions" | "activation" | "patterns">,
	actualTableSize: Fusion.Value<Vector2>,
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
		ClipsDescendants = true,

		[Fusion.Children] = {
			scope:base {
				Size = UDim2.fromScale(1, 0.0558659218),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0145251397),
				BackgroundTransparency = 1,
				ClipsDescendants = true,

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
			scope:list {
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
				AlternateColor3 = currentTheme.colors.crust,
				RowSize = UDim2.fromScale(1, 0), -- 1820, 75
				PrimaryColor = "Alternate" :: "Alternate",
				CornerRadius = UDim.new(0.0182926829, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Rows = scope:ForPairs(patterns, function(_, scope: typeof(scope), key: number)
					local rowSize = scope:Value(75)
					local bg = scope:Spring(scope:Value(1), 10, 1)
					bg:setPosition(0)

					local index = scope:Value(key)
					return key,
						scope:base {
							Size = scope:Computed(function(use)
								return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(props.actualTableSize).Y)
							end),
							BackgroundColor3 = currentTheme.colors.surface0,
							BackgroundTransparency = bg,

							[Fusion.Children] = createChildren(scope, {
								rowSize = rowSize,
								options = {
									{
										type = "number",
										value = index,
										focusLost = function(newIndex)
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
										layoutOrder = 1,
									},
								} :: { createChildren.option },

								onEdit = function()
									local selectedFunction = scope.peek(props.selectedFunction)
									if selectedFunction == nil then
										return
									end
									props.CurrentPattern:set({ functionId = selectedFunction, patternId = key })
									props.CurrentPage:set("Flashers")
									props.CurrentPanel:set("ELS Setup")
									props.ReturnTo:set("vehicleSetup")
								end,
								onDelete = function()
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
								onDownload = function() end,
							}),
						}
				end),
				[Fusion.Children] = addButton(scope, currentTheme, "Add Pattern", function()
					local selectedFunction = scope.peek(props.selectedFunction)
					if selectedFunction == nil then
						return
					end
					ConfigurationEditor.addPattern(selectedFunction, { flashers = {}, faders = {}, rotators = {} })
				end),
			},

			--TODO: This can be seperated into its own section
			scope:list {
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
				AlternateColor3 = currentTheme.colors.crust,
				RowSize = UDim2.fromScale(1, 0), -- 1820, 75
				PrimaryColor = "Alternate" :: "Alternate",
				CornerRadius = UDim.new(0.0182926829, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Rows = scope:ForPairs(
					currentActivations,
					function(_, scope: typeof(scope), key, value): (number, Fusion.Child)
						local selectedFunction = scope.peek(props.selectedFunction)
						if selectedFunction == nil then
							return key, {}
						end

						local rowSize = scope:Value(75)
						local activationType = scope:Value(scope.peek(value.type))
						return key,
							scope:base {
								Size = scope:Computed(function(use)
									return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(props.actualTableSize).Y)
								end),
								BackgroundTransparency = 1,

								[Fusion.Children] = createChildren(scope, {
									rowSize = rowSize,
									options = scope:Computed(function(use)
										local controls: { createChildren.option } = {
											{
												type = "select",
												value = activationType,
												layoutOrder = 1,
												options = scope:Computed(function(use)
													local defaultOptions = { "Standard", "Default", "Override" }
													local currentVehicle = use(props.CurrentVehicle)
													if
														currentVehicle ~= nil
														and typeof(currentVehicle) == "Instance"
													then
														local vehicleType =
															VehicleHandler:isValidVehicle(currentVehicle)
														if vehicleType == "ag" or vehicleType == "mg" then
															table.insert(defaultOptions, "AG-Event")
														end
													end
													return defaultOptions
												end),
												selectionChanged = function(newValue)
													ConfigurationEditor.updateActivationType(
														selectedFunction,
														key,
														newValue
													)
												end,
											},
										}

										local currentType = use(value.type)
										if currentType == "Standard" then
											local activation = value :: FunctionsEditor.StandardActivationState
											table.insert(controls, {
												type = "select",
												value = activation.mode,
												layoutOrder = 2,
												options = { "Cycle", "Set Pattern" },
												selectionChanged = function(newValue)
													ConfigurationEditor.updateStandardActivationMode(
														selectedFunction,
														key,
														newValue
													)
												end,
											})
											table.insert(controls, {
												type = "number",
												value = activation.pattern,
												layoutOrder = 3,
												disabled = scope:Computed(function(use)
													return if use(activation.mode) == "Cycle" then true else false
												end),
												focusLost = function(newValue)
													ConfigurationEditor.updateStandardActivationPattern(
														selectedFunction,
														key,
														newValue
													)
												end,
											})
											for i, keybind in use(activation.keybinds) do
												table.insert(controls, {
													type = "keycode",
													value = keybind,
													layoutOrder = i + 3,
													focusLost = function(newValue)
														ConfigurationEditor.updateStandardActivationKeybind(
															selectedFunction,
															key,
															i,
															newValue
														)
													end,
												})
											end
										elseif currentType == "Override" then
											local activation = value :: FunctionsEditor.OverrideActivationState
											table.insert(controls, {
												type = "select",
												value = activation.mode,
												layoutOrder = 2,
												options = { "Siren Override", "Park", "Brake", "Reverse" },
												selectionChanged = function(newValue)
													ConfigurationEditor.updateOverrideActivationMode(
														selectedFunction,
														key,
														newValue
													)
												end,
											})
											table.insert(controls, {
												type = "select",
												value = activation.siren,
												layoutOrder = 3,
												options = scope:Computed(function()
													local currentConfiguration = scope.peek(ConfigurationEditor.current)
													if currentConfiguration == nil then
														return {}
													end
													local sirens = scope.peek(currentConfiguration.sirens)
													if sirens == nil then
														return {}
													end

													local sirensByName = {}
													for _, siren in pairs(sirens) do
														table.insert(sirensByName, scope.peek(siren.name))
													end
													return sirensByName
												end),
												selectionChanged = function(newValue)
													ConfigurationEditor.updateOverrideActivationSiren(
														selectedFunction,
														key,
														newValue
													)
												end,
												visible = scope:Computed(function(use)
													return if use(activation.mode) == "Siren Override"
														then true
														else false
												end),
											})
											table.insert(controls, {
												type = "select",
												value = activation.dependentFunction,
												layoutOrder = 4,
												options = scope:Computed(function(use)
													local currentConfiguration = use(ConfigurationEditor.current)
													if currentConfiguration == nil then
														return {}
													end

													local choices = { "No Dependent Function" }
													for funcKey, func in use(use(currentConfiguration.functions)) do
														if funcKey == selectedFunction then
															continue
														end
														table.insert(
															choices,
															scope.peek(func.weight),
															scope.peek(func.name)
														)
													end
													return choices
												end),
												selectionChanged = function(newValue)
													ConfigurationEditor.updateOverrideActivationDependentFunction(
														selectedFunction,
														key,
														newValue
													)
												end,
											})
											table.insert(controls, {
												type = "number",
												value = activation.dependentPattern,
												layoutOrder = 5,
												focusLost = function(newValue)
													ConfigurationEditor.updateOverrideActivationDependentPattern(
														selectedFunction,
														key,
														newValue
													)
												end,
											})
										elseif currentType == "Default" then
											local activation = value :: FunctionsEditor.DefaultActivationState
											table.insert(controls, {
												type = "number",
												value = activation.pattern,
												layoutOrder = 2,
												focusLost = function(newValue)
													ConfigurationEditor.updateDefaultActivationPattern(
														selectedFunction,
														key,
														newValue
													)
												end,
											})
										elseif currentType == "AG-Event" then
											local activation = value :: FunctionsEditor.AGEventActivationState
											table.insert(controls, {
												type = "select",
												value = activation.mode,
												layoutOrder = 2,
												options = {
													"Stages",
													"Traffic Advisor",
													"Scene",
													"Ally Left",
													"Ally Right",
													"Rear Scene",
												},
												selectionChanged = function(newValue)
													ConfigurationEditor.updateAGEventActivationMode(
														selectedFunction,
														key,
														newValue
													)
												end,
											})
										end

										return controls
									end),

									onDelete = function()
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
									onDownload = function() end,
								}),
							}
					end
				),
				[Fusion.Children] = addButton(scope, currentTheme, "Add Activation", function()
					local currentFunction = scope.peek(props.selectedFunction)
					if currentFunction == nil then
						return
					end

					ConfigurationEditor.addActivation(currentFunction, {
						type = "Standard",
						mode = "Cycle",
						pattern = 0,
						keybinds = {
							Enum.KeyCode.J,
							Enum.KeyCode.DPadLeft,
						},
					})
				end),
			},
		},
	}
end
