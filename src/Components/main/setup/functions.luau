--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)
local log = require(root.Plugin.log)
local popup = require(root.Plugin.Components.popup)
local createChildren = require(script.Parent.createChildren)

local function testFunctionName(name: string, functions: { string }, currentDepth: number): string
	local actualName = if currentDepth == 0 then name else `{name} ({currentDepth})`
	local index = table.find(functions, actualName)
	if index ~= nil then
		return testFunctionName(name, functions, currentDepth + 1)
	end
	return actualName
end

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
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
	ReturnTo: Fusion.Value<types.returnTo>,
}

-- type standardActivation = {
-- 	type: Fusion.Value<"Standard">,
-- 	mode: Fusion.Value<"Cycle" | "Set Pattern">,
-- 	pattern: Fusion.Value<number>,
-- 	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>,
-- }
-- type defaultActivation = {
-- 	type: Fusion.Value<"Default">,
-- 	pattern: Fusion.Value<number>,
-- }
-- type overrideActivation = {
-- 	type: Fusion.Value<"Override">,
-- 	mode: Fusion.Value<"Siren Override" | "Park" | "Brake" | "Reverse">,
-- 	siren: Fusion.Value<string?>,
-- 	dependentFunction: Fusion.Value<string>,
-- 	dependentPattern: Fusion.Value<number>,
-- }
-- type conditionalActivation = {
-- 	type: Fusion.Value<"Conditional">,
-- 	mode: Fusion.Value<"Always Active" | "Keybind" | "Function" | "Siren">,
-- 	conditions: Fusion.Value<{
-- 		{
-- 			type: Fusion.Value<"Function">,
-- 			mode: Fusion.Value<"Is" | "Is Not">,
-- 			dependentFunction: Fusion.Value<string>,
-- 			dependentPattern: Fusion.Value<number>,
-- 		}
-- 	}>,
-- }
-- type activationState = standardActivation | defaultActivation | overrideActivation | conditionalActivation
type activationState = {
	type: Fusion.Value<"Standard" | "Default" | "Override">,
	mode: Fusion.Value<
		"Cycle"
		| "Set Pattern"
		| "Siren Override"
		| "Park"
		| "Brake"
		| "Reverse"
		| "Always Active"
		| "Keybind"
		| "Function"
		| "Siren"
	>?,
	pattern: Fusion.Value<number>?,
	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>?,
	siren: Fusion.Value<string?>?,
	dependentFunction: Fusion.Value<string>?,
	dependentPattern: Fusion.Value<number>?,
	conditions: Fusion.Value<{
		{
			type: Fusion.Value<"Function">,
			mode: Fusion.Value<"Is" | "Is Not">,
			dependentFunction: Fusion.Value<string>,
			dependentPattern: Fusion.Value<number>,
		}
	}>?,
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Functions
	Creates the functions page for the main app
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()

	local currentContent: Fusion.Value<"functions" | "activation" | "patterns"> = scope:Value("functions" :: any)
	local currentConfiguration = nil
	local functions: Fusion.Value<{ { name: string, weight: number } }> = scope:Value({})
	local patterns: Fusion.Value<{ types.pattern }> = scope:Value({})
	local activations: Fusion.Value<{ activationState }> = scope:Value({})
	local selectedFunction: Fusion.Value<number?> = scope:Value(nil)

	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				local newFunctions = {}
				for i, func in currentConfiguration.functions do
					newFunctions[i] = { name = func.name, weight = func.weight }
				end
				functions:set(newFunctions)
				currentContent:set("functions")
			end
		end
	end)

	scope:Observer(selectedFunction):onChange(function()
		local currentFunction = scope.peek(selectedFunction)
		if currentConfiguration ~= nil and currentFunction ~= nil then
			local newActivations: { activationState } = {}
			for activationKey, activationData in pairs(currentConfiguration.functions[currentFunction].activations) do
				local newActivation = {} :: activationState
				for key, value in pairs(activationData) do
					if typeof(value) == "table" then
						local newTable = {}
						for i, v in pairs(value) do
							newTable[i] = scope:Value(v)
						end
						newActivation[key] = newTable
					else
						newActivation[key] = scope:Value(value)
					end
				end
				if activationData.type == "Override" and activationData.siren == nil then
					newActivation.siren = scope:Value(nil)
				end

				table.insert(newActivations, activationKey, newActivation)
			end
			activations:set(newActivations)
		else
			activations:set({})
		end
	end)

	local function updateActivationsConfiguration()
		local currentFunction = scope.peek(selectedFunction)
		if currentConfiguration ~= nil and currentFunction ~= nil then
			local assembledActivations: { types.activation } = {}
			for _, activation in scope.peek(activations) do
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

	local newFunctionName = scope:Value("")
	local contentChooserXSize = 0.1098901099
	local actualTableSize = scope:Value(Vector2.one)

	-- 1820, 895
	local content = {
		scope:base {
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = scope:Spring(
				scope:Computed(function(use)
					local activeContent = use(currentContent)
					if activeContent == "functions" then
						return UDim2.fromScale(0.5, 0.5)
					else
						return UDim2.fromScale(-1, 0.5)
					end
				end),
				SPRING_SPEED,
				SPRING_DAMPING
			),
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
							PlaceholderText = "New Function Name",
							[Fusion.Out "Text"] = newFunctionName,
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
								log.debug(currentConfiguration)
								if currentConfiguration == nil then
									return
								end
								local newFunctionName = scope.peek(newFunctionName)
								if newFunctionName == "" then
									newFunctionName = "New Function"
								end
								local currentFunctions = scope.peek(functions)
								local functionsByName = {}
								for i, func in currentFunctions do
									functionsByName[i] = func.name
								end
								newFunctionName = testFunctionName(newFunctionName, functionsByName, 0)

								local newFunctionData = scope.deepCopy(chassisHandler.defaults.functions)
								newFunctionData.name = newFunctionName
								newFunctionData.weight = #currentConfiguration.functions + 1
								table.insert(currentConfiguration.functions, newFunctionData)

								table.insert(
									currentFunctions,
									{ name = newFunctionData.name, weight = newFunctionData.weight }
								)
								log.debug(currentConfiguration.functions, currentFunctions)
								functions:set(currentFunctions)
								props.UnsavedChanges:set(true)
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
					Rows = scope:ForPairs(
						functions,
						function(_, scope: typeof(scope), key: number, value: { name: string, weight: number })
							local rowSize = scope:Value(75)
							local bg = scope:Spring(scope:Value(1), 10, 1)
							bg:setPosition(0)

							local weight = scope:Value(value.weight)
							local name = scope:Value(value.name)
							return key,
								scope:base {
									Size = scope:Computed(function(use)
										return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(actualTableSize).Y)
									end),
									BackgroundColor3 = currentTheme.colors.surface0,
									BackgroundTransparency = bg,

									[Fusion.Children] = createChildren(scope, {
										rowSize = rowSize,
										options = {
											{
												type = "number",
												value = weight,
												focusLost = function()
													if currentConfiguration == nil then
														return
													end
													local newValue = scope.peek(weight)
													local currentFunctions = scope.peek(functions)
													if currentFunctions[newValue] ~= nil then
														local currentFunction = currentFunctions[key]
														local otherFunction = currentFunctions[newValue]
														if currentFunction == otherFunction then
															log.warn("Attempted to swap function with itself")
															return
														end
														-- update the weights first
														currentFunctions[key].weight = newValue
														currentConfiguration.functions[key].weight = newValue
														currentFunctions[newValue].weight = key
														currentConfiguration.functions[newValue].weight = key

														-- now swap the functions
														scope.arraySwap(currentFunctions, key, newValue)
														scope.arraySwap(currentConfiguration.functions, key, newValue)
														functions:set(currentFunctions)
														props.UnsavedChanges:set(true)
														return
													end

													local currentFunction = currentFunctions[key]
													local currentData = currentConfiguration.functions[key]
													-- Clear old
													table.remove(currentFunctions, key)
													table.remove(currentConfiguration.functions, key)

													-- Insert new
													scope.insertAtNumberOrEnd(
														currentFunctions,
														newValue,
														currentFunction
													)
													scope.insertAtNumberOrEnd(
														currentConfiguration.functions,
														newValue,
														currentData
													)

													-- Update weights
													for i, func in currentFunctions do
														func.weight = i
														currentConfiguration.functions[i].weight = i
													end

													functions:set(currentFunctions)
													props.UnsavedChanges:set(true)
												end,
												layoutOrder = 1,
											},
											{
												type = "string",
												value = name,
												focusLost = function()
													if currentConfiguration == nil then
														return
													end
													local newValue = scope.peek(name)
													local currentFunctions = scope.peek(functions)
													currentFunctions[key].name = newValue
													currentConfiguration.functions[key].name = newValue
													functions:set(currentFunctions)
													props.UnsavedChanges:set(true)
												end,
												layoutOrder = 2,
											},
										} :: { createChildren.option },

										onEdit = function()
											if currentConfiguration == nil then
												return
											end
											currentContent:set("patterns")
											selectedFunction:set(key)
											patterns:set(currentConfiguration.functions[key].patterns)
										end,
										onDelete = function()
											if currentConfiguration == nil then
												return
											end

											popup:addPopup(scope, {
												title = "Delete Function",
												description = "Are you sure you want to delete this function?\n<b>All data will be lost.</b>",
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
															local currentFunctions = scope.peek(functions)
															table.remove(currentFunctions, key)
															table.remove(currentConfiguration.functions, key)
															functions:set(currentFunctions)
															props.UnsavedChanges:set(true)
														end,
													},
												},
											})
										end,
										onDownload = function() end,
									}),
								}
						end
					),
				},
			},
		},

		scope:base {
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = scope:Spring(
				scope:Computed(function(use)
					local activeContent = use(currentContent)
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
								currentContent:set("functions")
								selectedFunction:set(nil)
							end :: unknown,
						},

						scope:base {
							CornerRadius = UDim.new(0.5, 0),
							BackgroundColor3 = currentTheme.colors.blue,
							Size = UDim2.fromScale(contentChooserXSize, 0.2),
							AnchorPoint = Vector2.new(0.5, 0),
							Position = scope:Spring(
								scope:Computed(function(use)
									local currentContent = use(currentContent)
									if currentContent == "functions" then
										return UDim2.new(1, 0, 0, 0)
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
													return use(currentContent) == loweredValue
															and currentTheme.colors.blue
														or currentTheme.colors.text
												end),
												Text = value,
												TextScaled = true,
												MaxTextSize = 30,
												FontWeight = scope:Computed(function(use)
													return use(currentContent) == loweredValue and Enum.FontWeight.Bold
														or Enum.FontWeight.Regular
												end),
												LayoutOrder = key,
												Reactive = true,
												AnimateSize = false,

												[Fusion.OnEvent "Activated"] = function()
													currentContent:set(loweredValue :: "activation" | "patterns")
												end,
											}
									end
								),
							},
						},
					},
				},

				scope:list {
					Size = UDim2.fromScale(1, 0.9162011173), -- 895 -75 total 820
					AnchorPoint = Vector2.new(0.5, 1),
					Position = scope:Spring(
						scope:Computed(function(use)
							local activeContent = use(currentContent)
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
					Rows = scope:ForPairs(patterns, function(_, scope: typeof(scope), key: number, _: types.pattern)
						local rowSize = scope:Value(75)
						local bg = scope:Spring(scope:Value(1), 10, 1)
						bg:setPosition(0)

						local index = scope:Value(key)
						return key,
							scope:base {
								Size = scope:Computed(function(use)
									return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(actualTableSize).Y)
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
												local selectedFunction = scope.peek(selectedFunction)
												if currentConfiguration == nil or selectedFunction == nil then
													return
												end
												local newValue = scope.peek(index)
												local currentPatterns = scope.peek(patterns)
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
													patterns:set(currentPatterns)
													props.UnsavedChanges:set(true)
													return
												end

												local currentPattern = currentPatterns[key]
												table.remove(currentPatterns, key)
												scope.insertAtNumberOrEnd(currentPatterns, newValue, currentPattern)
												currentConfiguration.functions[selectedFunction].patterns =
													currentPatterns
												patterns:set(currentPatterns)
												props.UnsavedChanges:set(true)
											end,
											layoutOrder = 1,
										},
									} :: { createChildren.option },

									onEdit = function()
										local selectedFunction = scope.peek(selectedFunction)
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
										local selectedFunction = scope.peek(selectedFunction)
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
														local currentPatterns = scope.peek(patterns)
														table.remove(currentPatterns, key)
														patterns:set(currentPatterns)
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
						local currentPatterns = scope.peek(patterns)
						table.insert(currentPatterns, scope.deepCopy(chassisHandler.defaults.functions.patterns[1]))
						patterns:set(currentPatterns)
						props.UnsavedChanges:set(true)
					end),
				},

				scope:list {
					Size = UDim2.fromScale(1, 0.9162011173), -- 895 -75 total 820
					AnchorPoint = Vector2.new(0.5, 1),
					Position = scope:Spring(
						scope:Computed(function(use)
							local activeContent = use(currentContent)
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
						activations,
						function(_, innerScope: typeof(scope), key: number, value: activationState)
							local rowSize = innerScope:Value(75)
							local activationType = innerScope:Value(innerScope.peek(value.type))
							return key,
								innerScope:base {
									Size = innerScope:Computed(function(use)
										return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(actualTableSize).Y)
									end),
									BackgroundTransparency = 1,

									[Fusion.Children] = createChildren(innerScope, {
										rowSize = rowSize,
										options = innerScope:Computed(function(use)
											local controls: { createChildren.option } = {
												{
													type = "select",
													value = activationType,
													layoutOrder = 1,
													options = { "Standard", "Override", "Default" },
													selectionChanged = function()
														if currentConfiguration == nil then
															return
														end
														local newType = innerScope.peek(activationType)
														if newType == "Standard" then
															value.mode = value.mode or scope:Value("Cycle") :: any
															value.pattern = value.pattern or scope:Value(0)
															value.keybinds = value.keybinds
																or scope:Value({
																	scope:Value(Enum.KeyCode.J),
																	scope:Value(Enum.KeyCode.DPadLeft),
																})
															value.siren = nil
															value.dependentFunction = nil
															value.dependentPattern = nil
															value.conditions = nil
														elseif newType == "Override" then
															value.pattern = nil
															value.keybinds = nil
															value.mode = value.mode or scope:Value("Park") :: any
															value.siren = value.siren or scope:Value(nil)
															value.dependentFunction = value.dependentFunction
																or scope:Value("No Dependent Function")
															value.dependentPattern = value.dependentPattern
																or scope:Value(0)
														elseif newType == "Default" then
															value.pattern = value.pattern or scope:Value(0)
															value.mode = nil
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
													disabled = innerScope:Computed(function(use)
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
													visible = innerScope:Computed(function(use)
														return use(value.mode) == "Siren Override"
													end),
												})
												-- end

												table.insert(controls, {
													type = "select",
													value = value.dependentFunction,
													layoutOrder = 4,
													options = innerScope:Computed(function(use)
														local choices = { "No Dependent Function" }
														for _, func in use(functions) do
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
											end

											return controls
										end),

										onDelete = function()
											local selectedFunction = innerScope.peek(selectedFunction)
											if currentConfiguration == nil or selectedFunction == nil then
												return
											end

											popup:addPopup(innerScope, {
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
															local currentActivations = innerScope.peek(activations)
															table.remove(currentActivations, key)
															activations:set(currentActivations)
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
						local currentActivations = scope.peek(activations)
						local newActivation: activationState = {
							type = scope:Value("Standard") :: any,
							mode = scope:Value("Cycle") :: any,
							pattern = scope:Value(0),
							keybinds = scope:Value({ scope:Value(Enum.KeyCode.J), scope:Value(Enum.KeyCode.DPadLeft) }),
						}
						table.insert(currentActivations, newActivation)
						activations:set(currentActivations)
						props.UnsavedChanges:set(true)
					end),
				},
			},
		},
	}

	return scope:base {
		Name = "Functions",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Spring(
			scope:Computed(function(use)
				local currentPage = use(props.CurrentPage)
				if currentPage == "Functions" then
					return UDim2.fromScale(0.5, 0.0462962963)
				end
				return UDim2.fromScale(-1, 0.0462962963)
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
				Text = scope:Computed(function(use)
					local selected = use(selectedFunction)
					return if selected ~= nil
						then `Editing Function {scope.peek(functions)[selected].name}`
						else "Select A Function"
				end),
				FontWeight = scope:Computed(function(use)
					return if use(selectedFunction) ~= nil then Enum.FontWeight.Bold else Enum.FontWeight.Medium
				end),
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
