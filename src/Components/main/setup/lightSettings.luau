--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)
local chassisHandler = require(root.Plugin.chassisHandler)
-- local log = require(root.Plugin.log)
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

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
}

local colorKeyToIndex = {
	"name",
	"partColor",
	"lightColor",
	"lightoColor",
}

type lightSettingsState = {
	colors: Fusion.Value<{ chassisHandler.color }>,
	optimizations: {
		shouldChangeNeons: Fusion.Value<boolean>,
		shouldChangeLights: Fusion.Value<boolean>,
		shouldChangeLightos: Fusion.Value<boolean>,
	},
	lightGroups: Fusion.Value<{ { name: Fusion.Value<string>, lights: Fusion.Value<{ string }> } }>,
}

local mainSettings = {
	{
		name = "Optimizations",
		data = {
			{ index = "shouldChangeNeons", name = "Enable Neon Lights" },
			{ index = "shouldChangeLights", name = "Enable Light Emitters" },
			{ index = "shouldChangeLightos", name = "Enable Lightos" },
		},
	},
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Light Settings
	Creates the light settings page for the main app
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()

	local currentContent: Fusion.Value<"settings" | "colors" | "light groups"> = scope:Value("settings" :: any)
	local currentConfiguration = nil
	local lightSettings: Fusion.Value<lightSettingsState?> = scope:Value(nil)
	local lightParts: Fusion.Value<{ string }> = scope:Value({})
	local holdingShift = false

	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				local newLightSettings = {}

				local newColors = {}
				for colorId, color in currentConfiguration.lightSettings.colors do
					local colorState = {
						name = color.name,
						partColor = color.partColor,
						lightColor = color.lightColor,
						lightoColor = color.lightoColor,
					}
					table.insert(newColors, colorId, colorState)
				end
				newLightSettings.colors = scope:Value(newColors)

				newLightSettings.optimizations = {
					shouldChangeNeons = scope:Value(currentConfiguration.lightSettings.optimizations.shouldChangeNeons),
					shouldChangeLights = scope:Value(
						currentConfiguration.lightSettings.optimizations.shouldChangeLights
					),
					shouldChangeLightos = scope:Value(
						currentConfiguration.lightSettings.optimizations.shouldChangeLightos
					),
				}

				local newLightGroups = {}
				for groupName, group in currentConfiguration.lightSettings.lightGroups do
					local newLightGroup = {
						name = scope:Value(group.name),
						lights = scope:Value(group.lights),
					}
					newLightGroups[groupName] = newLightGroup
				end
				newLightSettings.lightGroups = scope:Value(newLightGroups)

				lightParts:set(chassisHandler.getLights(currentConfiguration, currentVehicle))
				lightSettings:set(newLightSettings)
			end
		end
	end)

	local function updateCurrentConfiguration()
		local currentLightSettings = scope.peek(lightSettings)
		if currentConfiguration ~= nil and currentLightSettings ~= nil then
			local assembledLightSettings = {
				colors = {},
				optimizations = {
					shouldChangeNeons = scope.peek(currentLightSettings.optimizations.shouldChangeNeons),
					shouldChangeLights = scope.peek(currentLightSettings.optimizations.shouldChangeLights),
					shouldChangeLightos = scope.peek(currentLightSettings.optimizations.shouldChangeLightos),
				},
				lightGroups = {},
			}

			for colorId, color in scope.peek(currentLightSettings.colors) do
				table.insert(assembledLightSettings.colors, colorId, {
					name = scope.peek(color.name),
					partColor = scope.peek(color.partColor),
					lightColor = scope.peek(color.lightColor),
					lightoColor = scope.peek(color.lightoColor),
				})
			end

			for groupName, group in scope.peek(currentLightSettings.lightGroups) do
				assembledLightSettings.lightGroups[groupName] = {
					name = scope.peek(group.name),
					lights = scope.peek(group.lights),
				}
			end

			currentConfiguration.lightSettings = assembledLightSettings
			props.UnsavedChanges:set(true)
		end
	end

	local actualTableSize = scope:Value(Vector2.one)
	local topbarSize = scope:Value(Vector2.one)
	local topbarPosition = scope:Value(Vector2.one)
	local buttonData = {
		position = scope:Value(Vector2.one),
		size = scope:Value(Vector2.one),
	}

	-- 1820, 895
	local content = {
		scope:base {
			Size = UDim2.fromScale(1, 0.0558659218),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.0145251397),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			[Fusion.Out "AbsoluteSize"] = topbarSize :: unknown,
			[Fusion.Out "AbsolutePosition"] = topbarPosition,

			[Fusion.Children] = {
				scope:base {
					CornerRadius = UDim.new(0.5, 0),
					BackgroundColor3 = currentTheme.colors.blue,
					Size = scope:Spring(
						scope:Computed(function(use)
							return UDim2.new(0, use(buttonData.size).X, 0.2, 0)
						end),
						SPRING_SPEED,
						SPRING_DAMPING
					),
					Position = scope:Spring(
						scope:Computed(function(use)
							return UDim2.new(0, use(buttonData.position).X - use(topbarPosition).X, 0.9, 0)
						end),
						SPRING_SPEED,
						SPRING_DAMPING
					),
				},

				scope:base {
					ClassName = "ScrollingFrame",
					Name = "Buttons",
					Size = UDim2.fromScale(1, 1),
					Position = UDim2.fromScale(0, 0.9),
					AnchorPoint = Vector2.new(0, 1),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.X,
					ScrollBarThickness = 0,

					[Fusion.Children] = Fusion.Child {
						scope:New("UIListLayout") {
							FillDirection = Enum.FillDirection.Horizontal,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = scope:Computed(function(use)
								return UDim.new(0, 0.015625 * use(topbarSize).X)
							end),
						},

						scope:ForPairs(
							{ "Settings", "Colors", "Light Groups" },
							function(_, scope: typeof(scope), key, value)
								local desiredButtonPosition = scope:Value(UDim2.fromOffset(0, 0))
								local animatedButtonPosition = scope:Spring(desiredButtonPosition, 30, 1)
								local isHovered = scope:Value(false)
								local loweredValue = value:lower()
								local data = {
									position = scope:Value(Vector2.one),
									size = scope:Value(Vector2.one),
								}
								return key,
									scope:base {
										Size = UDim2.new(0, 0, 1, -2),
										AutomaticSize = Enum.AutomaticSize.X,
										LayoutOrder = key,
										BackgroundTransparency = 1,
										[Fusion.Out "AbsolutePosition"] = data.position :: unknown,
										[Fusion.Out "AbsoluteSize"] = data.size,
										MaxSize = Vector2.new(185, 100),

										[Fusion.OnChange "AbsoluteSize"] = function(size)
											if scope.peek(currentContent) == loweredValue then
												buttonData.size:set(size)
											end
										end,

										[Fusion.OnChange "AbsolutePosition"] = function(position)
											if scope.peek(currentContent) == loweredValue then
												buttonData.position:set(position)
											end
										end,

										[Fusion.Children] = {
											scope:textLabel {
												Size = UDim2.fromScale(0, 1),
												ClassName = "TextButton",
												Position = animatedButtonPosition,
												Text = value,
												TextScaled = true,
												AutomaticSize = Enum.AutomaticSize.X,
												TextColor3 = scope:Computed(function(use)
													return if use(currentContent) == loweredValue
														then currentTheme.colors.blue
														else currentTheme.colors.text
												end),
												FontFace = scope:Computed(function(use)
													return if use(currentContent) == loweredValue
														then currentTheme.font[Enum.FontWeight.Bold]
														else currentTheme.font[Enum.FontWeight.Medium]
												end),
												BackgroundTransparency = 1,
												MaxTextSize = 25,

												[Fusion.OnEvent "MouseEnter"] = function()
													desiredButtonPosition:set(UDim2.fromOffset(0, -3))
													isHovered:set(true)
												end,

												[Fusion.OnEvent "MouseLeave"] = function()
													desiredButtonPosition:set(UDim2.fromOffset(0, 0))
													isHovered:set(false)
												end,

												[Fusion.OnEvent "MouseButton1Down"] = function()
													desiredButtonPosition:set(UDim2.fromOffset(0, 3))
												end,

												[Fusion.OnEvent "MouseButton1Up"] = function()
													if scope.peek(isHovered) == true then
														desiredButtonPosition:set(UDim2.fromOffset(0, -3))
													else
														desiredButtonPosition:set(UDim2.fromOffset(0, 0))
													end
												end,

												[Fusion.OnEvent "Activated"] = function()
													currentContent:set(loweredValue :: any)
													buttonData.position:set(scope.peek(data.position))
													buttonData.size:set(scope.peek(data.size))
												end,
											},
										},
									}
							end
						),
					},
				},
			},
		},

		scope:base {
			ClassName = "ScrollingFrame",
			Size = UDim2.fromScale(1, 0.9162011173), -- 1820, 820
			AnchorPoint = Vector2.new(0.5, 1),
			Position = scope:Spring(
				scope:Computed(function(use)
					local activeContent = use(currentContent)
					if activeContent == "settings" then
						return UDim2.fromScale(0.5, 1)
					else
						return UDim2.fromScale(-1, 1)
					end
				end),
				SPRING_SPEED,
				SPRING_DAMPING
			),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = currentTheme.colors.text,
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			[Fusion.Out "AbsoluteSize"] = actualTableSize :: unknown,

			[Fusion.Children] = Fusion.Child {
				scope:New("UIListLayout") {
					SortOrder = Enum.SortOrder.LayoutOrder,
				},

				scope:ForPairs(mainSettings, function(_, scope: typeof(scope), key, value)
					return key,
						scope:base {
							Size = UDim2.fromScale(1, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundTransparency = 1,
							LayoutOrder = key,

							[Fusion.Children] = Fusion.Child {
								scope:New("UIListLayout") {
									SortOrder = Enum.SortOrder.LayoutOrder,
								},

								scope:textLabel {
									Size = scope:Computed(function(use)
										return UDim2.new(1, 0, 0, 0.0914634146 * use(actualTableSize).Y)
									end),
									BackgroundColor3 = currentTheme.colors.crust,
									BackgroundTransparency = if key % 2 == 0 then 1 else 0,
									Text = value.name,
									FontWeight = Enum.FontWeight.Bold,
									TextXAlignment = Enum.TextXAlignment.Left,
									TextScaled = true,
									MaxTextSize = 30,
									LayoutOrder = 0,

									[Fusion.Children] = {
										scope:New("UIPadding") {
											PaddingLeft = UDim.new(0.0082417582, 0),
										},
									},
								},

								scope:ForPairs(
									value.data,
									function(
										_,
										scope: typeof(scope),
										key: number,
										value: { index: string, name: string }
									)
										local isHovered = scope:Value(false)
										local isPushed = scope:Value(false)
										return key,
											scope:base {
												Size = scope:Computed(function(use)
													return UDim2.new(1, 0, 0, 0.0914634146 * use(actualTableSize).Y)
												end),
												BackgroundColor3 = currentTheme.colors.crust,
												BackgroundTransparency = if key % 2 == 0 then 0 else 1,
												LayoutOrder = key,

												[Fusion.Children] = {
													scope:New("UIPadding") {
														PaddingLeft = UDim.new(0.0164835164, 0),
														PaddingRight = UDim.new(0.0164835164, 0),
													},

													scope:baseButton {
														Size = UDim2.fromScale(1, 1),
														BackgroundTransparency = 1,
														ZIndex = 2,

														MouseEnter = function()
															isHovered:set(true)
														end,
														MouseLeave = function()
															isHovered:set(false)
														end,
														MouseButton1Down = function()
															isPushed:set(true)
														end,
														MouseButton1Up = function()
															isPushed:set(false)
														end,

														[Fusion.OnEvent "Activated"] = function()
															local currentLightSettings = scope.peek(lightSettings)
															if currentLightSettings then
																local currentOptimization =
																	currentLightSettings.optimizations[value.index]
																if currentOptimization then
																	currentOptimization:set(
																		not scope.peek(currentOptimization)
																	)
																end
															end
															updateCurrentConfiguration()
														end :: unknown,
													},

													scope:textButton {
														Size = UDim2.fromScale(0.5, 1),
														Text = value.name,
														FontWeight = Enum.FontWeight.Regular,
														TextXAlignment = Enum.TextXAlignment.Left,
														TextScaled = true,
														MaxTextSize = 30,
														BackgroundTransparency = 1,
														TextLabelSize = UDim2.fromScale(1, 1),
														AnimateSize = false,
														TriggerHover = isHovered,
														TriggerPush = isPushed,
													},

													scope:checkBox {
														Size = UDim2.fromScale(0.0274725275, 0.6666666667),
														AnchorPoint = Vector2.new(1, 0.5),
														Position = UDim2.fromScale(1, 0.5),
														BackgroundColor3 = currentTheme.colors.crust,
														CornerRadius = scope:Computed(function(use)
															return UDim.new(0, 0.0121951220 * use(actualTableSize).Y)
														end),
														Border = 1,
														BorderColor3 = currentTheme.colors.white,
														SelectedColor3 = currentTheme.colors.blue,
														SelectedCheckColor3 = currentTheme.colors.crust,
														Enabled = scope:Computed(function(use)
															local currentLightSettings = use(lightSettings)
															return currentLightSettings
																and use(currentLightSettings.optimizations[value.index])
														end),
														TriggerHover = isHovered,
														TriggerPush = isPushed,
													},
												},
											}
									end
								),
							},
						}
				end),
			},
		},

		scope:base {
			ClassName = "ScrollingFrame",
			Size = UDim2.fromScale(1, 0.9162011173), -- 1820, 820
			AnchorPoint = Vector2.new(0.5, 1),
			Position = scope:Spring(
				scope:Computed(function(use)
					local activeContent = use(currentContent)
					if activeContent == "colors" then
						return UDim2.fromScale(0.5, 1)
					elseif activeContent == "settings" then
						return UDim2.fromScale(1.5, 1)
					else
						return UDim2.fromScale(-1, 1)
					end
				end),
				SPRING_SPEED,
				SPRING_DAMPING
			),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = currentTheme.colors.text,
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),

			[Fusion.Children] = Fusion.Child {
				scope:New("UIListLayout") {
					SortOrder = Enum.SortOrder.LayoutOrder,
				},

				scope:base {
					Size = UDim2.fromScale(1, 0.0609756098),
					BackgroundTransparency = 1,
					LayoutOrder = 0,

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
							{ "Name", "Part Color", "Light Color", "Lighto Color" },
							function(_, scope: typeof(scope), key: number, value: string)
								return key,
									scope:textLabel {
										Size = UDim2.fromScale(0.1373626374, 1),
										Text = value,
										FontWeight = Enum.FontWeight.Medium,
										TextXAlignment = Enum.TextXAlignment.Center,
										TextScaled = true,
										MaxTextSize = 25,
										BackgroundTransparency = 1,
										LayoutOrder = key,
									}
							end
						),
					},
				},

				scope:Computed(function(use, scope: typeof(scope))
					local currentLightSettings = use(lightSettings)
					if currentLightSettings ~= nil then
						return scope:ForPairs(
							currentLightSettings.colors,
							function(_, scope: typeof(scope), key: number, colorData)
								local rowSize = scope:Value(75)
								local function onOptionChange(option, value)
									local changedIndex = colorKeyToIndex[option]
									local currentColors = scope.peek(currentLightSettings.colors)
									currentColors[key][changedIndex] = value
									currentLightSettings.colors:set(currentColors)
									updateCurrentConfiguration()
								end
								local name = scope:Value(colorData.name)
								local partColor = scope:Value(colorData.partColor)
								local lightColor = scope:Value(colorData.lightColor)
								local lightoColor = scope:Value(colorData.lightoColor)

								local childrenProps = {
									rowSize = rowSize,
									actualTableSize = actualTableSize,

									options = {
										{
											type = "string",
											layoutOrder = 1,
											value = name,
											disabled = key < 7,
											focusLost = function()
												onOptionChange(1, scope.peek(name))
											end,
										},
										{
											type = "color",
											layoutOrder = 2,
											value = partColor,
											label = "Part Color",
											colorChanged = function()
												onOptionChange(2, scope.peek(partColor))
											end,
										},
										{
											type = "color",
											layoutOrder = 3,
											value = lightColor,
											label = "Light Color",
											colorChanged = function()
												onOptionChange(3, scope.peek(lightColor))
											end,
										},
										{
											type = "color",
											layoutOrder = 4,
											value = lightoColor,
											label = "Lighto Color",
											colorChanged = function()
												onOptionChange(4, scope.peek(lightoColor))
											end,
										},
									} :: { createChildren.option },
								}

								if key > 6 then
									childrenProps.onDelete = function()
										popup:addPopup(scope, {
											title = "Remove Color",
											description = `Are you sure you want to delete color <b>{scope.peek(
												colorData.name
											)}</b>?\n<b>All data will be lost.</b>`,
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
														local currentColors = scope.peek(currentLightSettings.colors)
														table.remove(currentColors, key)
														currentLightSettings.colors:set(currentColors)
														updateCurrentConfiguration()
													end,
													keybind = Enum.KeyCode.Return,
												},
											},
										})
									end
								end

								return key,
									scope:base {
										Size = scope:Computed(function(use)
											return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(actualTableSize).Y)
										end),
										BackgroundColor3 = currentTheme.colors.crust,
										BackgroundTransparency = if key % 2 == 0 then 1 else 0,
										LayoutOrder = key,

										[Fusion.Children] = {
											createChildren(scope, childrenProps),
										},
									}
							end
						)
					end

					return {} :: any
				end),

				scope:base {
					Size = UDim2.fromScale(1, 0.0914634146),
					BackgroundTransparency = 1,
					LayoutOrder = 4000,

					[Fusion.Children] = {
						scope:textButton {
							Size = UDim2.fromScale(1, 0.6666666667),
							MaxSize = Vector2.new(175, 50),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							BackgroundColor3 = currentTheme.colors.crust,
							CornerRadius = UDim.new(0, 5),
							Border = 1,
							Text = "Add Color",
							TextScaled = true,
							MaxTextSize = 30,
							FontWeight = Enum.FontWeight.Medium,
							TextXAlignment = Enum.TextXAlignment.Center,
							Reactive = true,

							[Fusion.OnEvent "Activated"] = function()
								local currentLightSettings = scope.peek(lightSettings)
								if currentLightSettings then
									local currentColors = scope.peek(currentLightSettings.colors)
									table.insert(currentColors, {
										name = "New Color",
										partColor = Color3.new(1, 1, 1),
										lightColor = Color3.new(1, 1, 1),
										lightoColor = Color3.new(1, 1, 1),
									})
									currentLightSettings.colors:set(currentColors)
									updateCurrentConfiguration()
								end
							end,
						},
					},
				},
			},
		},

		scope:base {
			ClassName = "ScrollingFrame",
			Size = UDim2.fromScale(1, 0.9162011173), -- 1820, 820
			AnchorPoint = Vector2.new(0.5, 1),
			Position = scope:Spring(
				scope:Computed(function(use)
					local activeContent = use(currentContent)
					if activeContent == "light groups" then
						return UDim2.fromScale(0.5, 1)
					else
						return UDim2.fromScale(1.5, 1)
					end
				end),
				SPRING_SPEED,
				SPRING_DAMPING
			),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = currentTheme.colors.text,
			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),

			[Fusion.Children] = Fusion.Child {
				scope:New("UIListLayout") {
					SortOrder = Enum.SortOrder.LayoutOrder,
				},

				scope:Computed(function(use, scope: typeof(scope))
					local currentLightSettings = use(lightSettings)
					local lastLight = 0
					if currentLightSettings ~= nil then
						return scope:ForPairs(
							currentLightSettings.lightGroups,
							function(_, scope: typeof(scope), key: number, value)
								local isOpen = scope:Value(false)
								local name = scope:Value(scope.peek(value.name))
								local size = scope:Value(Vector2.one)

								local function lightClicked(lightKey: number, lightName: string)
									local currentLightParts = scope.peek(lightParts)
									local currentLights = scope.peek(value.lights)
									local lightIndex = table.find(currentLights, lightName)
									if lightIndex ~= nil then
										table.remove(currentLights, lightIndex)
									else
										table.insert(currentLights, lightName)
									end

									if holdingShift == true then
										local adding = false
										if lightIndex == nil then
											adding = true
										end

										for i, v in currentLightParts do
											if
												(lightKey < lastLight and i > lightKey and i <= lastLight)
												or (lightKey > lastLight and i < lightKey and i >= lastLight)
											then
												if adding == true then
													table.insert(currentLights, v)
												else
													local index = table.find(currentLights, v)
													if index ~= nil then
														table.remove(currentLights, index)
													end
												end
											end
										end
									end

									lastLight = lightKey
									value.lights:set(currentLights)
								end

								local isTrashHovered = scope:Value(false)
								return key,
									scope:base {
										Size = UDim2.fromScale(1, 0),
										AutomaticSize = Enum.AutomaticSize.Y,
										BackgroundColor3 = currentTheme.colors.crust,
										BackgroundTransparency = if key % 2 == 0 then 1 else 0,
										LayoutOrder = key,

										[Fusion.Children] = {
											scope:baseButton {
												Size = scope:Computed(function(use)
													return UDim2.new(1, 0, 0, 0.0914634146 * use(actualTableSize).Y)
												end),
												BackgroundTransparency = 1,

												[Fusion.OnEvent "Activated"] = function()
													isOpen:set(not scope.peek(isOpen))
												end :: unknown,

												[Fusion.Children] = {
													scope:textBox {
														Size = UDim2.fromScale(0.1373626374, 0.6666666667),
														Position = UDim2.fromScale(0.0082417582, 0.5),
														AnchorPoint = Vector2.new(0, 0.5),
														BackgroundColor3 = currentTheme.colors.crust,
														CornerRadius = UDim.new(0, 5),
														Border = 1,
														TextScaled = true,
														MaxTextSize = 20,
														FontWeight = Enum.FontWeight.Regular,
														MaxSize = Vector2.new(300, 50),
														PaddingBottom = UDim.new(0.2, 0),
														PaddingTop = UDim.new(0.2, 0),
														PaddingLeft = UDim.new(0.04, 0),
														PaddingRight = UDim.new(0.04, 0),

														Text = name,
														[Fusion.Out "Text"] = name :: unknown,
														TextXAlignment = Enum.TextXAlignment.Left,
														[Fusion.OnEvent "FocusLost"] = function()
															local currentLightSettings = scope.peek(lightSettings)
															if currentLightSettings ~= nil then
																local currentLightGroups =
																	scope.peek(currentLightSettings.lightGroups)
																currentLightGroups[key].name:set(scope.peek(name))
																currentLightSettings.lightGroups:set(currentLightGroups)
															end
															updateCurrentConfiguration()
														end,
													},

													scope:New("ImageLabel") {
														Name = "Arrow",
														AnchorPoint = Vector2.new(1, 0.5),
														Position = UDim2.fromScale(0.9615384615, 0.5),
														Size = UDim2.fromScale(0.0219780220, 0.2933333333),
														BackgroundTransparency = 1,
														Image = assets.images.redonUI.arrow,
														ImageColor3 = currentTheme.colors.text,
														Rotation = scope:Spring(
															scope:Computed(function(use)
																return use(isOpen) and 180 or 0
															end),
															SPRING_SPEED,
															SPRING_DAMPING
														),
														ScaleType = Enum.ScaleType.Fit,
													},

													scope:iconButton {
														Size = UDim2.fromScale(0.0219780220, 0.7666666667),
														Position = UDim2.fromScale(0.9917582418, 0.5),
														AnchorPoint = Vector2.new(1, 0.5),
														BackgroundTransparency = 1,
														Image = scope:Computed(function(use)
															return if use(isTrashHovered)
																then assets.images.redonUI.trashFilled
																else assets.images.redonUI.trash
														end),
														Reactive = true,
														ScaleType = Enum.ScaleType.Fit,
														LayoutOrder = 3,

														MouseEnter = function()
															isTrashHovered:set(true)
														end,

														MouseLeave = function()
															isTrashHovered:set(false)
														end,

														[Fusion.OnEvent "Activated"] = function()
															popup:addPopup(scope, {
																title = "Remove Light Group",
																description = `Are you sure you want to delete light group <b>{scope.peek(
																	value.name
																)}</b>?\n<b>All data will be lost.</b>`,
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
																			local currentLightSettings =
																				scope.peek(lightSettings)
																			if currentLightSettings then
																				local currentLightGroups = scope.peek(
																					currentLightSettings.lightGroups
																				)
																				table.remove(currentLightGroups, key)
																				currentLightSettings.lightGroups:set(
																					currentLightGroups
																				)
																				updateCurrentConfiguration()
																			end
																		end,
																		keybind = Enum.KeyCode.Return,
																	},
																},
															})
														end,
													},
												},
											},

											scope:base {
												ClassName = "ScrollingFrame",
												Size = scope:Spring(
													scope:Computed(function(use)
														return if use(isOpen)
															then UDim2.new(
																1,
																0,
																0,
																0.2743902439 * use(actualTableSize).Y
															)
															else UDim2.fromScale(1, 0)
													end),
													20,
													0.75
												),
												Position = scope:Computed(function(use)
													return UDim2.new(0, 0, 0, 0.0914634146 * use(actualTableSize).Y)
												end),
												BackgroundTransparency = 1,
												ScrollBarThickness = 3,
												ScrollBarImageColor3 = currentTheme.colors.text,
												TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
												BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
												AutomaticCanvasSize = scope:Computed(function(use)
													return if use(isOpen)
														then Enum.AutomaticSize.Y
														else Enum.AutomaticSize.None
												end),
												CanvasSize = UDim2.new(),
												Visible = scope:Computed(function(use)
													return if use(size).Y < 1 then false else true
												end),
												[Fusion.Out "AbsoluteSize"] = size :: unknown,

												[Fusion.Children] = Fusion.Child {
													scope:New("UIGridLayout") {
														CellSize = scope:Computed(function(use)
															local currentSize = use(size)
															return UDim2.fromOffset(
																0.0824175824 * currentSize.X,
																0.2 * currentSize.Y
															)
														end),
														SortOrder = Enum.SortOrder.LayoutOrder,
														HorizontalAlignment = Enum.HorizontalAlignment.Left,
														VerticalAlignment = Enum.VerticalAlignment.Top,
														FillDirection = Enum.FillDirection.Horizontal,
														CellPadding = scope:Computed(function(use)
															local currentSize = use(size)
															return UDim2.fromOffset(
																0.0082417582 * currentSize.X,
																0.0666666667 * currentSize.Y
															)
														end),
													},

													scope:New("UIPadding") {
														PaddingLeft = UDim.new(0.0082417582, 0),
														PaddingTop = UDim.new(0, 5),
														PaddingBottom = UDim.new(0, 5),
													},

													scope:ForPairs(
														lightParts,
														function(_, scope: typeof(scope), lightKey, lightName)
															return lightKey,
																scope:textButton {
																	BackgroundColor3 = currentTheme.colors.crust,
																	Border = 1,
																	CornerRadius = UDim.new(0.2222222222, 0),
																	Text = lightName,
																	TextScaled = true,
																	MaxTextSize = 20,
																	FontWeight = Enum.FontWeight.Regular,
																	TextXAlignment = Enum.TextXAlignment.Left,
																	Reactive = true,
																	LayoutOrder = lightKey,

																	[Fusion.OnEvent "Activated"] = function()
																		lightClicked(lightKey, lightName)
																		updateCurrentConfiguration()
																	end :: unknown,

																	[Fusion.Children] = {
																		scope:checkBox {
																			Size = UDim2.fromScale(0.2, 0.6666666667),
																			AnchorPoint = Vector2.new(1, 0.5),
																			Position = UDim2.fromScale(
																				0.9333333333,
																				0.5
																			),
																			BackgroundColor3 = currentTheme.colors.crust,
																			CornerRadius = scope:Computed(function(use)
																				return UDim.new(
																					0,
																					0.0091463415
																						* use(actualTableSize).Y
																				)
																			end),
																			Border = 1,
																			BorderColor3 = currentTheme.colors.white,
																			SelectedColor3 = currentTheme.colors.blue,
																			SelectedCheckColor3 = currentTheme.colors.crust,
																			Enabled = scope:Computed(function(use)
																				local currentLights = use(value.lights)
																				return table.find(
																					currentLights,
																					lightName
																				) ~= nil
																			end),

																			[Fusion.OnEvent "Activated"] = function()
																				lightClicked(lightKey, lightName)
																				updateCurrentConfiguration()
																			end,
																			-- TriggerHover = isHovered,
																			-- TriggerPush = isPushed,
																		},
																	},
																}
														end
													),
												},
											},
										},
									}
							end
						)
					end

					return {} :: any
				end),

				scope:base {
					Size = UDim2.fromScale(1, 0.0914634146),
					BackgroundTransparency = 1,
					LayoutOrder = 4000,

					[Fusion.Children] = {
						scope:textButton {
							Size = UDim2.fromScale(1, 0.6666666667),
							MaxSize = Vector2.new(175, 50),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							BackgroundColor3 = currentTheme.colors.crust,
							CornerRadius = UDim.new(0, 5),
							Border = 1,
							Text = "Add Light Group",
							TextScaled = true,
							MaxTextSize = 30,
							FontWeight = Enum.FontWeight.Medium,
							TextXAlignment = Enum.TextXAlignment.Center,
							Reactive = true,

							[Fusion.OnEvent "Activated"] = function()
								local currentLightSettings = scope.peek(lightSettings)
								if currentLightSettings then
									local currentLightGroups = scope.peek(currentLightSettings.lightGroups)
									table.insert(currentLightGroups, {
										name = scope:Value("Group"),
										lights = scope:Value({}),
									})
									currentLightSettings.lightGroups:set(currentLightGroups)
									updateCurrentConfiguration()
								end
								updateCurrentConfiguration()
							end,
						},
					},
				},
			},
		},
	}

	return scope:base {
		Name = "Light Settings",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Spring(
			scope:Computed(function(use)
				local currentPage = use(props.CurrentPage)
				if currentPage == "Light Settings" then
					return UDim2.fromScale(0.5, 0.0462962963)
				end
				return UDim2.fromScale(1.5, 0.0462962963)
			end),
			20,
			0.75
		),
		Size = UDim2.fromScale(1, 0.9537037037),
		BackgroundColor3 = currentTheme.colors.base,

		[Fusion.OnEvent "InputBegan"] = function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.LeftShift then
					holdingShift = true
				end
			end
		end :: unknown,

		[Fusion.OnEvent "InputEnded"] = function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.LeftShift then
					holdingShift = false
				end
			end
		end :: unknown,

		[Fusion.Children] = {
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
				Text = "Light Settings",
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
