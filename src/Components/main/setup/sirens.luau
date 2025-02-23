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

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
}

export type modifierState = {
	name: Fusion.Value<string>,
	modifiedSirenName: Fusion.Value<string>,
	parentSoundBehavior: Fusion.Value<"Play Parent Sound" | "Plays Simultaneously">,
	behavoir: Fusion.Value<"Play Automatically" | "Require Parent Replay">,
	delay: Fusion.Value<number>,
}

export type sirenState = {
	name: Fusion.Value<string>,
	type: Fusion.Value<"Siren" | "Hold">,
	behavoir: Fusion.Value<"Overrides Other Sounds" | "Plays Simultaneously">,
	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>,
	modifiers: Fusion.Value<{ Fusion.Value<modifierState> }>,
} | {
	name: Fusion.Value<string>,
	type: Fusion.Value<"Modifier">,
	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>,
}

local function decodeState(scope: types.Scope, state: Fusion.Value<any>): any
	local value = scope.peek(state)
	if typeof(value) == "table" then
		local newValue = {}
		for i, v in pairs(value) do
			newValue[i] = decodeState(scope, v)
		end
		return newValue
	end
	return value
end

local function encodeState(scope: types.Scope, value: any): Fusion.Value<any>
	if typeof(value) == "table" then
		local newValue = {}
		for i, v in pairs(value) do
			newValue[i] = encodeState(scope, v)
		end
		return scope:Value(newValue)
	end
	return scope:Value(value)
end

--[[
	Sirens
	Creates the sirens page for the main app
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()
	local firstScope = scope:innerScope()

	local currentConfiguration = nil
	local sirens: Fusion.Value<{ sirenState }> = scope:Value({})
	local modifiers: Fusion.Value<{ string }> = scope:Value({})

	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				-- sirens:set(currentConfiguration.sirens)
				local newSirens = {}
				for sirenKey, sirenData in currentConfiguration.sirens do
					local newSiren = {} :: sirenState
					for key, value in pairs(sirenData) do
						newSiren[key] = encodeState(firstScope, value)
					end
					table.insert(newSirens, sirenKey, newSiren)
				end
				log.debug(newSirens)
				sirens:set(newSirens)
			end
		end
	end)
	local function updateModifiers()
		local currentSirens = scope.peek(sirens)
		local currentModifiers = {}
		for _, siren in currentSirens do
			if scope.peek(siren.type) == "Modifier" then
				table.insert(currentModifiers, scope.peek(siren.name))
			end
		end
		modifiers:set(currentModifiers)
	end
	scope:Observer(sirens):onChange(updateModifiers)

	local function updateCurrentConfiguration()
		if currentConfiguration ~= nil then
			local assembledSirens: { types.siren } = {}
			for _, siren in scope.peek(sirens) do
				local newSiren = {} :: types.siren
				for key, stateValue in pairs(siren) do
					newSiren[key] = decodeState(firstScope, stateValue)
				end
				table.insert(assembledSirens, newSiren)
			end
			log.debug(assembledSirens)
			if currentConfiguration.sirens ~= assembledSirens then
				props.UnsavedChanges:set(true)
			end
			currentConfiguration.sirens = assembledSirens
		end
	end

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
								for i, siren in currentSirens do
									sirensByName[i] = scope.peek(siren.name)
								end
								newSirenName = testFunctionName(newSirenName, sirensByName, 0)

								local newSirenData = {
									name = firstScope:Value(newSirenName),
									type = firstScope:Value("Siren" :: any),
									behavoir = firstScope:Value("Overrides Other Sounds" :: any),
									keybinds = firstScope:Value({
										firstScope:Value(Enum.KeyCode.R),
										firstScope:Value(Enum.KeyCode.DPadRight),
									}),
									modifiers = firstScope:Value({}),
								}
								table.insert(currentSirens, newSirenData)
								sirens:set(currentSirens)
								updateCurrentConfiguration()
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
					Rows = scope:ForPairs(sirens, function(_, scope: typeof(scope), key: number, value: sirenState)
						local rowSize = scope:Value(75)
						local bg = scope:Spring(scope:Value(1), 10, 1)
						bg:setPosition(0)

						local sirenType = scope:Value(scope.peek(value.type))
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
												value = value.name,
												layoutOrder = 1,
												focusLost = function()
													updateCurrentConfiguration()
													if scope.peek(value.type) == "Modifier" then
														updateModifiers()
													end
												end,
											},
											{
												type = "select",
												value = sirenType,
												layoutOrder = 2,
												options = { "Siren", "Hold", "Modifier" },
												selectionChanged = function()
													if currentConfiguration == nil then
														return
													end
													local newType = scope.peek(sirenType)
													local value = value :: any
													if newType == "Modifier" then
														value.modifiers = nil
														value.behavoir = nil
													else
														value.modifiers = value.modifiers or firstScope:Value({})
														value.behavoir = value.behavoir
															or firstScope:Value("Overrides Other Sounds")
													end
													value.type:set(newType)
													updateCurrentConfiguration()
													if newType == "Modifier" then
														updateModifiers()
													end
												end,
											},
										}

										if use(value.type) ~= "Modifier" then
											table.insert(options, {
												type = "select",
												value = (value :: any).behavoir,
												layoutOrder = 3,
												options = { "Overrides Other Sounds", "Plays Simultaneously" },
												selectionChanged = updateCurrentConfiguration,
											})

											table.insert(options, {
												type = "button",
												text = "Add Modifier",
												layoutOrder = 4000,
												callback = function()
													if
														currentConfiguration == nil
														or scope.peek(value.type) == "Modifier"
													then
														return
													end
													local value = value :: any
													log.debug(value)

													local currentModifiers = scope.peek(modifiers)
													local currentSirenModifiers =
														scope.peek(value.modifiers) :: { Fusion.Value<modifierState> }
													table.insert(
														currentSirenModifiers,
														firstScope:Value({
															name = firstScope:Value(
																currentModifiers[1] or "New Modifier"
															),
															modifiedSirenName = firstScope:Value(
																scope.peek(value.name)
																	.. (currentModifiers[1] or "Unknown")
															),
															parentSoundBehavior = firstScope:Value(
																"Play Parent Sound" :: any
															),
															behavoir = firstScope:Value("Play Automatically" :: any),
															delay = firstScope:Value(0),
														})
													)
													value.modifiers:set(currentSirenModifiers)
													updateCurrentConfiguration()
												end,
											})
										end

										for i, keybind in use(value.keybinds) do
											table.insert(options, {
												type = "keycode",
												value = keybind,
												layoutOrder = i + 3,
												focusLost = updateCurrentConfiguration,
											})
										end

										return options
									end),
									childOptions = scope:Computed(function(use): { createChildren.childOption }?
										if use(value.type) ~= "Modifier" then
											local options = {}

											for i, modifierState: Fusion.Value<modifierState> in
												use((value :: any).modifiers)
											do
												local modifier = scope.peek(modifierState)
												table.insert(options, i, {
													options = {
														{
															type = "select",
															value = modifier.name,
															layoutOrder = 1,
															options = modifiers,
															selectionChanged = updateCurrentConfiguration,
														} :: createChildren.option,
														{
															type = "string",
															value = modifier.modifiedSirenName,
															layoutOrder = 2,
															focusLost = updateCurrentConfiguration,
														},
														{
															type = "select",
															value = modifier.parentSoundBehavior,
															layoutOrder = 3,
															options = {
																"Play Parent Sound",
																"Plays Simultaneously",
															},
															selectionChanged = updateCurrentConfiguration,
														},
														{
															type = "select",
															value = modifier.behavoir,
															layoutOrder = 4,
															options = {
																"Play Automatically",
																"Require Parent Replay",
															},
															selectionChanged = updateCurrentConfiguration,
														},
														{
															type = "number",
															value = modifier.delay,
															layoutOrder = 5,
															focusLost = updateCurrentConfiguration,
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
																	keybind = Enum.KeyCode.Escape,
																},
																{
																	text = "Delete",
																	type = "danger",
																	key = 2,
																	callback = function(newPopup)
																		popup:removePopup(newPopup)
																		local value = value :: any
																		local currentSirenModifiers = scope.peek(
																			value.modifiers
																		) :: {
																			Fusion.Value<
																				modifierState
																			>
																		}
																		table.remove(currentSirenModifiers, i)
																		value.modifiers:set(currentSirenModifiers)
																		updateCurrentConfiguration()
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
													keybind = Enum.KeyCode.Escape,
												},
												{
													text = "Delete",
													type = "danger",
													key = 2,
													callback = function(newPopup)
														popup:removePopup(newPopup)
														local currentSirens = scope.peek(sirens)
														table.remove(currentSirens, key)
														sirens:set(currentSirens)
														updateCurrentConfiguration()
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
