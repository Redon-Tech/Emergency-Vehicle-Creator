--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local types = require("../../../types")
local LightSettingsEditor = require("../../../lib/ConfigurationEditor/LightSettingsEditor")
local ChassisHandler = require("../../../lib/ChassisHandler")
local log = require("../../../log")

local mainSettings = require("@self/mainSettings")
local colors = require("@self/colors")
local lightGroups = require("@self/lightGroups")
local components = {
	mainSettings = mainSettings,
	colors = colors,
	lightGroups = lightGroups,
}

type props = {
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Light Settings
	Creates the light settings page for the main app
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local scope = baseScope:innerScope(components)
	local currentTheme = RedonUI.theme.theme:now()
	local firstScope = scope:innerScope()

	local currentContent: Fusion.Value<"settings" | "colors" | "light groups"> = scope:Value("settings" :: any)
	local currentConfiguration = nil
	local lightParts: Fusion.Value<{ string }> = scope:Value({})

	scope:Observer(props.CurrentVehicle):onBind(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = ChassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				lightParts:set(ChassisHandler.getLights(currentConfiguration, currentVehicle))
			end
		end
	end)

	local function removeColorReferences(removedId: number)
		if currentConfiguration == nil then
			return
		end
		LightSettingsEditor.removeColorReferences(currentConfiguration.functions, removedId)
	end

	scope:Observer(props.CurrentPage):onChange(function()
		if scope.peek(props.CurrentPage) ~= "Light Settings" then
			return
		end
		log.debug("Recomputing light parts")
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if currentVehicle ~= nil and typeof(currentVehicle) == "Instance" then
			currentConfiguration = ChassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				lightParts:set(ChassisHandler.getLights(currentConfiguration, currentVehicle))
			end
		end
	end)

	local actualTableSize = scope:Value(Vector2.one)
	local topbarSize = scope:Value(Vector2.one)
	local topbarPosition = scope:Value(Vector2.one)
	local buttonData = {
		position = scope:Value(Vector2.one),
		size = scope:Value(Vector2.one),
	}

	-- 1820, 895
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

				[Fusion.Children] = {
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

					scope:mainSettings {
						actualTableSize = actualTableSize,
						currentContent = currentContent,
					},

					scope:colors {
						removeColorReferences = removeColorReferences,
						actualTableSize = actualTableSize,
						currentContent = currentContent,
					},

					scope:lightGroups {
						firstScope = firstScope,
						actualTableSize = actualTableSize,
						currentContent = currentContent,
						lightParts = lightParts,
					},
				},
			},
		},
	}
end
