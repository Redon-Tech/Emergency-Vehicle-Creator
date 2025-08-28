--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)
local popup = require(root.Plugin.Components.popup)
local createChildren = require(script.Parent.Parent.createChildren)

local colorKeyToIndex = {
	"name",
	"partColor",
	"lightColor",
	"lightoColor",
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
	Colors
	Creates the main colors panel for the light settings page
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
				local currentLightSettings = use(props.lightSettings)
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
								props.updateCurrentConfiguration()
							end
							local name = scope:Value(colorData.name)
							local partColor = scope:Value(colorData.partColor)
							local lightColor = scope:Value(colorData.lightColor)
							local lightoColor = scope:Value(colorData.lightoColor)

							local childrenProps = {
								rowSize = rowSize,
								actualTableSize = props.actualTableSize,

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
													props.updateCurrentConfiguration()
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
										return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(props.actualTableSize).Y)
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
							local currentLightSettings = scope.peek(props.lightSettings)
							if currentLightSettings then
								local currentColors = scope.peek(currentLightSettings.colors)
								table.insert(currentColors, {
									name = "New Color",
									partColor = Color3.new(1, 1, 1),
									lightColor = Color3.new(1, 1, 1),
									lightoColor = Color3.new(1, 1, 1),
								})
								currentLightSettings.colors:set(currentColors)
								props.updateCurrentConfiguration()
							end
						end,
					},
				},
			},
		},
	}
end
