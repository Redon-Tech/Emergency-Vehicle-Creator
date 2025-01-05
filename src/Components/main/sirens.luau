--#selene: allow(shadowing)
-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

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

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
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

	local currentConfiguration = nil
	local sirens: Fusion.Value<{ types.siren }> = scope:Value({})
	local modifiers: Fusion.Value<{ string }> = scope:Value({})

	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				sirens:set(currentConfiguration.sirens)
			end
		end
	end)
	scope:Observer(sirens):onChange(function()
		local currentSirens = scope.peek(sirens)
		local currentModifiers = {}
		for _, siren in currentSirens do
			if siren.type == "Modifier" then
				table.insert(currentModifiers, siren.name)
			end
		end
		modifiers:set(currentModifiers)
	end)

	local newSirenName = scope:Value("")
	local actualTableSize = scope:Value(Vector2.one)

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
								log.debug(currentConfiguration)
								if currentConfiguration == nil then
									return
								end
								local newSirenName = scope.peek(newSirenName)
								if newSirenName == "" then
									newSirenName = "Wail"
								end
								local currentSirens = scope.peek(sirens)
								local sirensByName = {}
								for i, func in currentSirens do
									sirensByName[i] = func.name
								end
								newSirenName = testFunctionName(newSirenName, sirensByName, 0)

								local newSirenData = scope.deepCopy(chassisHandler.defaults.sirens);
								(newSirenData :: { name: string }).name = newSirenName
								table.insert(currentSirens, newSirenData)
								currentConfiguration.sirens = currentSirens
								sirens:set(currentSirens)
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
					Rows = scope:ForPairs(sirens, function(_, scope: typeof(scope), key: number, value: types.siren)
						local rowSize = scope:Value(75)
						local bg = scope:Spring(scope:Value(1), 10, 1)
						bg:setPosition(0)

						local childrenOptions: Fusion.UsedAs<{ createChildren.childOption }>? = nil
						local options: { createChildren.option } = {
							{ type = "string", initialValue = value.name, layoutOrder = 1 },
							{
								type = "select",
								initialValue = value.type,
								layoutOrder = 2,
								options = { "Siren", "Hold", "Modifier" },
							},
						}

						if value.type ~= "Modifier" then
							table.insert(options, {
								type = "select",
								initialValue = value.behavoir,
								layoutOrder = 3,
								options = { "Overrides Other Sounds", "Plays Simultaneously" },
							})
						end

						for i, keybind in value.keybinds :: { Enum.KeyCode } do
							table.insert(options, { type = "keycode", initialValue = keybind, layoutOrder = i + 3 })
						end

						-- table.insert(options, {
						-- 	type = "button",
						-- 	text = "Add Keybind",
						-- 	layoutOrder = #options + 1,
						-- 	callback = function()
						-- 		if currentConfiguration == nil then
						-- 			return
						-- 		end

						-- 		local currentSirens = scope.peek(sirens)
						-- 		value.keybinds[#value.keybinds + 1] = Enum.KeyCode.Unknown
						-- 		currentSirens[key] = value
						-- 		currentConfiguration.sirens[key] = value
						-- 		sirens:set(currentSirens)
						-- 		props.UnsavedChanges:set(true)
						-- 	end,
						-- })
						if value.type ~= "Modifier" then
							local valueModifiers = scope:Value(value.modifiers)
							childrenOptions = scope:ForPairs(
								valueModifiers,
								function(
									_,
									_,
									i: number,
									modifier: types.modifier
								): (number, createChildren.childOption)
									return i,
										{
											options = {
												{
													type = "select",
													initialValue = modifier.name,
													layoutOrder = 1,
													options = modifiers,
												},
												{
													type = "string",
													initialValue = modifier.modifiedSirenName,
													layoutOrder = 2,
												},
												{
													type = "select",
													initialValue = modifier.parentSoundBehavior,
													layoutOrder = 3,
													options = { "Play Parent Sound", "Plays Simultaneously" },
												},
												{
													type = "select",
													initialValue = modifier.behavoir,
													layoutOrder = 4,
													options = { "Play Automatically", "Require Parent Replay" },
												},
												{
													type = "number",
													initialValue = modifier.delay,
													layoutOrder = 5,
												},
											},
											onDelete = function()
												if currentConfiguration == nil then
													return
												end

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
														},
														{
															text = "Delete",
															type = "danger",
															key = 2,
															callback = function(newPopup)
																popup:removePopup(newPopup)
																local currentSirens = scope.peek(sirens)
																table.remove(value.modifiers, i)
																currentSirens[key] = value
																currentConfiguration.sirens[key] = value
																sirens:set(currentSirens)
																valueModifiers:set(value.modifiers)
																props.UnsavedChanges:set(true)
															end,
														},
													},
												})
											end,
											onOptionChange = function(editing: number, newValue: any?)
												if currentConfiguration == nil then
													return
												end
												local currentSirens = scope.peek(sirens)

												if editing == 1 and typeof(newValue) == "string" then
													local currentModifiers = scope.peek(modifiers)
													if table.find(currentModifiers, newValue) == nil then
														return
													end

													value.modifiers[i].name = newValue
												elseif editing == 2 and typeof(newValue) == "string" then
													value.modifiers[i].modifiedSirenName = newValue
												elseif editing == 3 and typeof(newValue) == "string" then
													value.modifiers[i].parentSoundBehavior =
														newValue :: "Play Parent Sound" | "Plays Simultaneously"
												elseif editing == 4 and typeof(newValue) == "string" then
													value.modifiers[i].behavoir =
														newValue :: "Play Automatically" | "Require Parent Replay"
												elseif editing == 5 and typeof(newValue) == "number" then
													value.modifiers[i].delay = newValue
												else
													return
												end

												currentSirens[key] = value
												currentConfiguration.sirens[key] = value
												sirens:set(currentSirens)
												valueModifiers:set(value.modifiers)
												props.UnsavedChanges:set(true)
											end,
										}
								end
							)

							table.insert(options, {
								type = "button",
								text = "Add Modifier",
								layoutOrder = #options + 1,
								callback = function()
									if currentConfiguration == nil then
										return
									end

									local currentSirens = scope.peek(sirens)
									local currentModifiers = scope.peek(modifiers)
									value.modifiers[#value.modifiers + 1] = {
										name = currentModifiers[1] or "New Modifier",
										modifiedSirenName = value.name .. (currentModifiers[1] or "Unknown"),
										parentSoundBehavior = "Play Parent Sound",
										behavoir = "Play Automatically",
										delay = 0,
									}
									currentSirens[key] = value
									currentConfiguration.sirens[key] = value
									sirens:set(currentSirens)
									valueModifiers:set(value.modifiers)
									props.UnsavedChanges:set(true)
								end,
							})
						end

						return key,
							scope:base {
								Size = scope:Computed(function(use)
									return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(actualTableSize).Y)
								end),
								BackgroundColor3 = currentTheme.colors.surface0,
								BackgroundTransparency = bg,

								[Fusion.Children] = createChildren(scope, {
									rowSize = rowSize,
									options = options,
									childOptions = childrenOptions,
									actualTableSize = actualTableSize,

									onOptionChange = function(editing: number, newValue: any?)
										if currentConfiguration == nil then
											return
										end
										local currentSirens = scope.peek(sirens)

										if editing == 1 and typeof(newValue) == "string" then
											(value :: { name: string }).name = newValue
										elseif editing == 2 and typeof(newValue) == "string" then
											-- (value :: { type: "Siren" | "Hold" | "Modifier" }).type =
											-- 	newValue :: "Siren" | "Hold" | "Modifier"
											if newValue == "Modifier" and value.type ~= "Modifier" then
												value = scope.deepCopy(chassisHandler.defaults.modifier)
												value.name = "New Modifier"
											else
												(value :: { type: "Siren" | "Hold" | "Modifier" }).type =
													newValue :: "Siren" | "Hold" | "Modifier"
											end
										elseif
											editing == 3
											and typeof(newValue) == "string"
											and value.type ~= "Modifier"
										then
											value.behavoir =
												newValue :: "Overrides Other Sounds" | "Plays Simultaneously"
										elseif typeof(newValue) == "EnumItem" then
											if newValue.EnumType == Enum.KeyCode then
												value.keybinds[editing - 3] = newValue :: Enum.KeyCode
											else
												return
											end
										else
											return
										end

										currentSirens[key] = value
										currentConfiguration.sirens[key] = value
										sirens:set(currentSirens)
										props.UnsavedChanges:set(true)
									end,
									onDelete = function()
										if currentConfiguration == nil then
											return
										end

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
												},
												{
													text = "Delete",
													type = "danger",
													key = 2,
													callback = function(newPopup)
														popup:removePopup(newPopup)
														local currentSirens = scope.peek(sirens)
														table.remove(currentSirens, key)
														table.remove(currentConfiguration.sirens, key)
														sirens:set(currentSirens)
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
