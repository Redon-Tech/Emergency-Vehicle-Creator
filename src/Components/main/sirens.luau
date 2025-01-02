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

	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				sirens:set(currentConfiguration.sirens)
			end
		end
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
									newSirenName = "New Siren"
								end
								local currentSirens = scope.peek(sirens)
								local sirensByName = {}
								for i, func in currentSirens do
									sirensByName[i] = func.name
								end
								newSirenName = testFunctionName(newSirenName, sirensByName, 0)

								local newSirenData = scope.deepCopy(chassisHandler.defaults.sirens)
								newSirenData.name = newSirenName
								table.insert(currentConfiguration.sirens, newSirenData)

								table.insert(currentSirens, newSirenData)
								log.debug(currentConfiguration.sirens, newSirenData)
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
					Rows = scope:ForPairs(sirens, function(use, scope: typeof(scope), key: number, value: types.siren)
						local rowSize = scope:Value(75)
						local bg = scope:Spring(scope:Value(1), 10, 1)
						bg:setPosition(0)

						local mode = scope:Value(value.type)
						local options: { createChildren.option } = {
							{ value = value.name, layoutOrder = 1 },
							{ value = mode, layoutOrder = 2, options = { "Siren", "Hold", "Modifier" } },
						}
						if use(mode) ~= "Modifier" then
							local behavoir = scope:Value(value.behavoir)
							table.insert(options, {
								value = behavoir,
								layoutOrder = 3,
								options = { "Overrides Other Sounds", "Plays Simultaneously" },
							})
						end
						for i, keybind in value.keybinds do
							table.insert(options, { value = keybind, layoutOrder = i + 3 })
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
									hasDeleteButton = true,
									hasDownloadButton = true,
									hasEditButton = false,

									onOptionChange = function(editing: number, newValue: any?) end,
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
													callback = function(popup)
														popup:Destroy()
													end,
												},
												{
													text = "Delete",
													type = "danger",
													key = 2,
													callback = function(popup)
														popup:Destroy()
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
								}),
							}
					end),
				},
			},
		},
	}

	return scope:base {
		Name = "Functions",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.0462962963),
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
