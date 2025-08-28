--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)

local mainSettings = {
	{
		name = "Enabled Effects",
		data = {
			{ index = "shouldChangeNeons", name = "Enable Neon Lights", type = "boolean" },
			{ index = "shouldChangeLights", name = "Enable Light Emitters", type = "boolean" },
			{ index = "shouldChangeLightos", name = "Enable Lightos", type = "boolean" },
			{ index = "shouldChangeParticleEmitters", name = "Enable Particle Emitters", type = "boolean" },
		},
	},
	{
		name = "Light Configuration",
		data = {
			{ index = "partTransparency", name = "Part Transparency", type = "number" },
		},
	},
}

type props = {
	actualTableSize: Fusion.Value<Vector2>,
	currentContent: Fusion.Value<"settings" | "colors" | "light groups">,
	lightSettings: Fusion.Value<chassisHandler.lightSettingsState?>,
	updateCurrentConfiguration: () -> (),
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Main Settings
	Creates the main settings panel for the light settings page
]]
return function(scope: types.Scope, props: props)
	local currentTheme = RedonUI.theme.theme:now()

	return scope:base {
		ClassName = "ScrollingFrame",
		Size = UDim2.fromScale(1, 0.9162011173), -- 1820, 820
		AnchorPoint = Vector2.new(0.5, 1),
		Position = scope:Spring(
			scope:Computed(function(use)
				local activeContent = use(props.currentContent)
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
		[Fusion.Out "AbsoluteSize"] = props.actualTableSize :: unknown,

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
									return UDim2.new(1, 0, 0, 0.0914634146 * use(props.actualTableSize).Y)
								end),
								BackgroundColor3 = currentTheme.colors.crust,
								-- BackgroundTransparency = if key % 2 == 0 then 1 else 0,
								BackgroundTransparency = 0,
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
									value: { index: string, name: string, type: string }
								)
									if value.type == "boolean" then
										local isHovered = scope:Value(false)
										local isPushed = scope:Value(false)
										return key,
											scope:base {
												Size = scope:Computed(function(use)
													return UDim2.new(
														1,
														0,
														0,
														0.0914634146 * use(props.actualTableSize).Y
													)
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
															local currentLightSettings = scope.peek(props.lightSettings)
															if currentLightSettings then
																local currentOptimization =
																	currentLightSettings.configuration[value.index]
																if currentOptimization then
																	currentOptimization:set(
																		not scope.peek(currentOptimization)
																	)
																end
															end
															props.updateCurrentConfiguration()
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
															return UDim.new(
																0,
																0.0121951220 * use(props.actualTableSize).Y
															)
														end),
														Border = 1,
														BorderColor3 = currentTheme.colors.white,
														SelectedColor3 = currentTheme.colors.blue,
														SelectedCheckColor3 = currentTheme.colors.crust,
														Enabled = scope:Computed(function(use)
															local currentLightSettings = use(props.lightSettings)
															return currentLightSettings
																and use(currentLightSettings.configuration[value.index])
														end),
														TriggerHover = isHovered,
														TriggerPush = isPushed,
													},
												},
											}
									else
										local currentLightSettings = scope.peek(props.lightSettings)
										local text = scope:Value(
											currentLightSettings
													and tostring(currentLightSettings.configuration[value.index])
												or "0.011"
										)

										return key,
											scope:base {
												Size = scope:Computed(function(use)
													return UDim2.new(
														1,
														0,
														0,
														0.0914634146 * use(props.actualTableSize).Y
													)
												end),
												BackgroundColor3 = currentTheme.colors.crust,
												BackgroundTransparency = if key % 2 == 0 then 0 else 1,
												LayoutOrder = key,

												[Fusion.Children] = {
													scope:New("UIPadding") {
														PaddingLeft = UDim.new(0.0164835164, 0),
														PaddingRight = UDim.new(0.0164835164, 0),
													},

													scope:textLabel {
														Size = UDim2.fromScale(0.5, 1),
														Text = value.name,
														FontWeight = Enum.FontWeight.Regular,
														TextXAlignment = Enum.TextXAlignment.Left,
														TextScaled = true,
														MaxTextSize = 30,
														BackgroundTransparency = 1,
													},

													scope:textBox {
														Size = UDim2.fromScale(0.0274725275, 0.6666666667),
														AnchorPoint = Vector2.new(1, 0.5),
														Position = UDim2.fromScale(1, 0.5),
														BackgroundColor3 = currentTheme.colors.crust,
														CornerRadius = scope:Computed(function(use)
															return UDim.new(
																0,
																0.0121951220 * use(props.actualTableSize).Y
															)
														end),
														Border = 1,
														Text = text,
														[Fusion.Out "Text"] = text :: unknown,

														[Fusion.OnEvent "FocusLost"] = function()
															local currentLightSettings = scope.peek(props.lightSettings)
															if currentLightSettings then
																local currentConfiguration =
																	currentLightSettings.configuration[value.index]
																if currentConfiguration then
																	local newValue = tonumber(scope.peek(text))
																	if newValue then
																		currentConfiguration:set(newValue)
																	end
																end
															end
															props.updateCurrentConfiguration()
														end,
													},
												},
											}
									end
								end
							),
						},
					}
			end),
		},
	}
end
