--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)
local log = require(root.Plugin.log)
local popup = require(root.Plugin.Components.popup)
local createChildren = require(script.Parent.Parent.createChildren)
local vehicle = require(root.Plugin.vehicle)

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
	functions: Fusion.Value<{ { name: string, weight: number } }>,
	activations: Fusion.Value<{ types.activationState }>,
	actualTableSize: Fusion.Value<Vector2>,
	patterns: Fusion.Value<{ types.pattern }>,
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

	local currentConfiguration = nil
	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
		end
	end)

	local function updateActivationsConfiguration()
		local currentFunction = scope.peek(props.selectedFunction)
		if currentConfiguration ~= nil and currentFunction ~= nil then
			local assembledActivations: { types.activation } = {}
			for _, activation in scope.peek(props.activations) do
				local newActivation = {} :: types.activation
				for key, stateValue in pairs(activation) do
					local value = scope.peek(stateValue)
					if typeof(value) == "table" then
						local newTable = {}
						for i, v in pairs(value) do
							newTable[i] = scope.peek(v)
						end
						newActivation[key] = newTable
					else
						newActivation[key] = value
					end
				end
				table.insert(assembledActivations, newActivation)
			end
			log.debug(assembledActivations)
			if currentConfiguration.functions[currentFunction].activations ~= assembledActivations then
				props.UnsavedChanges:set(true)
			end
			currentConfiguration.functions[currentFunction].activations = assembledActivations
		end
	end

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
				Rows = scope:ForPairs(props.patterns, function(_, scope: typeof(scope), key: number, _: types.pattern)
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
										focusLost = function()
											local selectedFunction = scope.peek(props.selectedFunction)
											if currentConfiguration == nil or selectedFunction == nil then
												return
											end
											local newValue = scope.peek(index)
											local currentPatterns = scope.peek(props.patterns)
											if currentPatterns[newValue] ~= nil then
												local currentPattern = currentPatterns[key]
												local otherPattern = currentPatterns[newValue]
												if currentPattern == otherPattern then
													log.warn("Attempted to swap pattern with itself")
													return
												end
												scope.arraySwap(currentPatterns, key, newValue)
												currentConfiguration.functions[selectedFunction].patterns =
													currentPatterns
												props.patterns:set(currentPatterns)
												props.UnsavedChanges:set(true)
												return
											end

											local currentPattern = currentPatterns[key]
											table.remove(currentPatterns, key)
											scope.insertAtNumberOrEnd(currentPatterns, newValue, currentPattern)
											currentConfiguration.functions[selectedFunction].patterns = currentPatterns
											props.patterns:set(currentPatterns)
											props.UnsavedChanges:set(true)
										end,
										layoutOrder = 1,
									},
								} :: { createChildren.option },

								onEdit = function()
									local selectedFunction = scope.peek(props.selectedFunction)
									if currentConfiguration == nil or selectedFunction == nil then
										return
									end
									props.CurrentPattern:set({
										functionId = selectedFunction,
										patternId = key,
										pattern = currentConfiguration.functions[selectedFunction].patterns[key],
									})
									props.CurrentPage:set("Flashers")
									props.CurrentPanel:set("ELS Setup")
									props.ReturnTo:set("vehicleSetup")
								end,
								onDelete = function()
									local selectedFunction = scope.peek(props.selectedFunction)
									if currentConfiguration == nil or selectedFunction == nil then
										return
									end

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
													local currentPatterns = scope.peek(props.patterns)
													table.remove(currentPatterns, key)
													props.patterns:set(currentPatterns)
													currentConfiguration.functions[selectedFunction].patterns =
														currentPatterns
													props.UnsavedChanges:set(true)
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
					if currentConfiguration == nil then
						return
					end
					local currentPatterns = scope.peek(props.patterns)
					table.insert(currentPatterns, scope.deepCopy(chassisHandler.defaults.functions.patterns[1]))
					props.patterns:set(currentPatterns)
					props.UnsavedChanges:set(true)
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
					props.activations,
					function(_, scope: typeof(scope), key: number, value: types.activationState)
						local sirenVisible = scope:Computed(function(use)
							return use(value.mode) == "Siren Override"
						end)
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
														local vehicleType = vehicle:isValidVehicle(currentVehicle)
														if vehicleType == "ag" or vehicleType == "mg" then
															table.insert(defaultOptions, "AG-Event")
														end
													end
													return defaultOptions
												end),
												selectionChanged = function()
													if currentConfiguration == nil then
														return
													end
													local newType = scope.peek(activationType)
													if newType == "Standard" then
														value.mode = value.mode
															or props.firstScope:Value("Cycle") :: any
														if
															value.mode ~= nil
															and (
																scope.peek(value.mode) ~= "Cycle"
																or scope.peek(value.mode) ~= "Set Pattern"
															)
														then
															value.mode:set("Cycle")
														end
														value.pattern = value.pattern or props.firstScope:Value(0)
														value.keybinds = value.keybinds
															or props.firstScope:Value({
																props.firstScope:Value(Enum.KeyCode.J),
																props.firstScope:Value(Enum.KeyCode.DPadLeft),
															})
														value.siren = nil
														value.dependentFunction = nil
														value.dependentPattern = nil
														value.conditions = nil
													elseif newType == "Override" then
														value.pattern = nil
														value.keybinds = nil
														value.mode = value.mode or props.firstScope:Value("Park") :: any
														if
															value.mode ~= nil
															and (
																scope.peek(value.mode) == "Cycle"
																or scope.peek(value.mode) == "Set Pattern"
															)
														then
															value.mode:set("Park")
														end
														value.siren = value.siren or props.firstScope:Value(nil)
														value.dependentFunction = value.dependentFunction
															or props.firstScope:Value("No Dependent Function")
														value.dependentPattern = value.dependentPattern
															or props.firstScope:Value(0)
													elseif newType == "Default" then
														value.pattern = value.pattern or props.firstScope:Value(0)
														value.mode = nil
														value.siren = nil
														value.dependentFunction = nil
														value.dependentPattern = nil
														value.conditions = nil
														value.keybinds = nil
													elseif newType == "AG-Event" then
														value.pattern = nil
														value.mode = value.mode
															or props.firstScope:Value("Stages") :: any
														if
															value.mode ~= nil
															and (
																scope.peek(value.mode) ~= "Stages"
																or scope.peek(value.mode) ~= "Traffic Advisor"
																or scope.peek(value.mode) ~= "Scene"
																or scope.peek(value.mode) ~= "Ally Left"
																or scope.peek(value.mode) ~= "Ally Right"
																or scope.peek(value.mode) ~= "Rear Scene"
															)
														then
															value.mode:set("Stages")
														end
														value.siren = nil
														value.dependentFunction = nil
														value.dependentPattern = nil
														value.conditions = nil
														value.keybinds = nil
													end
													value.type:set(newType :: any)
													updateActivationsConfiguration()
												end,
											},
										}

										local currentType = use(value.type)
										if
											currentType == "Standard"
											and value.mode ~= nil
											and value.pattern ~= nil
											and value.keybinds ~= nil
										then
											table.insert(controls, {
												type = "select",
												value = value.mode,
												layoutOrder = 2,
												options = { "Cycle", "Set Pattern" },
												selectionChanged = updateActivationsConfiguration,
											})
											table.insert(controls, {
												type = "number",
												value = value.pattern,
												layoutOrder = 3,
												disabled = scope:Computed(function(use)
													return if use(value.mode) == "Cycle" then true else false
												end),
												focusLost = updateActivationsConfiguration,
											})
											for i, keybind in use(value.keybinds) do
												table.insert(controls, {
													type = "keycode",
													value = keybind,
													layoutOrder = i + 3,
													focusLost = updateActivationsConfiguration,
												})
											end
										elseif
											currentType == "Override"
											and value.mode ~= nil
											and value.siren ~= nil
											and value.dependentFunction ~= nil
											and value.dependentPattern ~= nil
										then
											table.insert(controls, {
												type = "select",
												value = value.mode,
												layoutOrder = 2,
												options = { "Siren Override", "Park", "Brake", "Reverse" },
												selectionChanged = function()
													if scope.peek(value.mode) == "Siren Override" then
														if scope.peek(value.siren) == nil then
															value.siren:set("Unknown Siren")
														end
													else
														value.siren:set(nil)
													end
													updateActivationsConfiguration()
												end,
											})
											-- if use(value.siren) ~= nil then
											table.insert(controls, {
												type = "select",
												value = value.siren,
												layoutOrder = 3,
												options = scope:Computed(function()
													if currentConfiguration == nil then
														return {}
													end

													local sirensByName = {}
													for _, siren in pairs(currentConfiguration.sirens) do
														table.insert(sirensByName, siren.name)
													end
													return sirensByName
												end),
												selectionChanged = updateActivationsConfiguration,
												visible = sirenVisible,
											})
											-- end

											table.insert(controls, {
												type = "select",
												value = value.dependentFunction,
												layoutOrder = 4,
												options = scope:Computed(function(use)
													local choices = { "No Dependent Function" }
													for _, func in use(props.functions) do
														table.insert(choices, func.weight, func.name)
													end
													return choices
												end),
												selectionChanged = updateActivationsConfiguration,
											})
											table.insert(controls, {
												type = "number",
												value = value.dependentPattern,
												layoutOrder = 5,
												focusLost = updateActivationsConfiguration,
											})
										elseif currentType == "Default" and value.pattern ~= nil then
											table.insert(controls, {
												type = "number",
												value = value.pattern,
												layoutOrder = 2,
												focusLost = updateActivationsConfiguration,
											})
										elseif currentType == "AG-Event" and value.mode ~= nil then
											table.insert(controls, {
												type = "select",
												value = value.mode,
												layoutOrder = 2,
												options = {
													"Stages",
													"Traffic Advisor",
													"Scene",
													"Ally Left",
													"Ally Right",
													"Rear Scene",
												},
												selectionChanged = updateActivationsConfiguration,
											})
										end

										return controls
									end),

									onDelete = function()
										local selectedFunction = scope.peek(props.selectedFunction)
										if currentConfiguration == nil or selectedFunction == nil then
											return
										end

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
														local currentActivations = scope.peek(props.activations)
														table.remove(currentActivations, key)
														props.activations:set(currentActivations)
														updateActivationsConfiguration()
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
					if currentConfiguration == nil then
						return
					end
					local currentActivations = scope.peek(props.activations)
					local newActivation: types.activationState = {
						type = props.firstScope:Value("Standard") :: any,
						mode = props.firstScope:Value("Cycle") :: any,
						pattern = props.firstScope:Value(0),
						keybinds = props.firstScope:Value({
							props.firstScope:Value(Enum.KeyCode.J),
							props.firstScope:Value(Enum.KeyCode.DPadLeft),
						}),
					}
					table.insert(currentActivations, newActivation)
					props.activations:set(currentActivations)
					props.UnsavedChanges:set(true)
				end),
			},
		},
	}
end
