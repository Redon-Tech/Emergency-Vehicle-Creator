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

local function testFunctionName(name: string, functions: { string }, currentDepth: number): string
	local actualName = if currentDepth == 0 then name else `{name} ({currentDepth})`
	local index = table.find(functions, actualName)
	if index ~= nil then
		return testFunctionName(name, functions, currentDepth + 1)
	end
	return actualName
end

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	currentContent: Fusion.Value<"functions" | "activation" | "patterns">,
	CurrentVehicle: Fusion.Value<Model | string?>,
	functions: Fusion.Value<{ { name: string, weight: number } }>,
	actualTableSize: Fusion.Value<Vector2>,
	patterns: Fusion.Value<{ types.pattern }>,
	selectedFunction: Fusion.Value<number?>,
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Functions Page
	Creates the functions page for the functions page
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

	local newFunctionName = scope:Value("")
	return scope:base {
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = scope:Spring(
			scope:Computed(function(use)
				local activeContent = use(props.currentContent)
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
							local currentFunctions = scope.peek(props.functions)
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
							props.functions:set(currentFunctions)
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
				[Fusion.Out "AbsoluteSize"] = props.actualTableSize,
				Rows = scope:ForPairs(
					props.functions,
					function(_, scope: typeof(scope), key: number, value: { name: string, weight: number })
						local rowSize = scope:Value(75)
						local bg = scope:Spring(scope:Value(1), 10, 1)
						bg:setPosition(0)

						local weight = scope:Value(value.weight)
						local name = scope:Value(value.name)
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
											value = weight,
											focusLost = function()
												if currentConfiguration == nil then
													return
												end
												local newValue = scope.peek(weight)
												local currentFunctions = scope.peek(props.functions)
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
													props.functions:set(currentFunctions)
													props.UnsavedChanges:set(true)
													return
												end

												local currentFunction = currentFunctions[key]
												local currentData = currentConfiguration.functions[key]
												-- Clear old
												table.remove(currentFunctions, key)
												table.remove(currentConfiguration.functions, key)

												-- Insert new
												scope.insertAtNumberOrEnd(currentFunctions, newValue, currentFunction)
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

												props.functions:set(currentFunctions)
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
												local currentFunctions = scope.peek(props.functions)
												currentFunctions[key].name = newValue
												currentConfiguration.functions[key].name = newValue
												props.functions:set(currentFunctions)
												props.UnsavedChanges:set(true)
											end,
											layoutOrder = 2,
										},
									} :: { createChildren.option },

									onEdit = function()
										if currentConfiguration == nil then
											return
										end
										props.currentContent:set("patterns")
										props.selectedFunction:set(key)
										props.patterns:set(currentConfiguration.functions[key].patterns)
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
														local currentFunctions = scope.peek(props.functions)
														table.remove(currentFunctions, key)
														table.remove(currentConfiguration.functions, key)
														props.functions:set(currentFunctions)
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
	}
end
