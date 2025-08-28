--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local popup = require(root.Plugin.Components.popup)
local chassisHandler = require(root.Plugin.chassisHandler)
local assets = require(root.Plugin.assets)
local log = require(root.Plugin.log)
local settings = require(root.Plugin.settings)
local utils = require(root.Plugin.utils)

local angle = require(script.Parent.angle)
local components = {
	angle = angle,
}

--[[
	Rotators
	Creates the rotators screen for the main app
]]
return function(
	baseScope: types.Scope,
	props: {
		key: number,
		rotator: types.rotatorSectionState,
		playing: Fusion.Value<boolean>,
		holdingShift: Fusion.Value<boolean>,
		colors: Fusion.Value<{ chassisHandler.color }>,
		rotators: Fusion.Value<{ types.rotatorSectionState }>,
		temporarlyPause: () -> () -> (),
		updateCurrentConfiguration: () -> (),
		addRotator: (number) -> (),
		firstScope: types.Scope,
		size: Fusion.Value<Vector2>,
	}
): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()
	local scope = baseScope:innerScope(components)

	local dataSize = scope:Value(Vector2.one)
	local color = scope:Computed(function(use)
		if use(props.playing) == false then
			return Color3.new()
		end

		local currentAngles = use(props.rotator.data)
		local currentAngle = currentAngles[use(props.rotator.currentAngle)]
		if currentAngle == nil then
			log.warn("Somehow the current angle is nil", currentAngle, scope.peek(props.rotator.currentAngle))
			return Color3.new()
		end
		local colorId = use(currentAngle.color)
		if colorId == nil then
			return Color3.new()
		end
		local colorData = scope.peek(props.colors)[colorId]
		local finalColor = if colorData == nil
			then Color3.new()
			else if utils.bloomColors[colorData.name] ~= nil
				then utils.bloomColors[colorData.name]
				else colorData.lightoColor
		return finalColor
	end)
	return scope:base {
		Name = props.key,
		Size = UDim2.fromScale(0.1764705882, 0.9735449735),
		BackgroundColor3 = currentTheme.colors.mantle,
		CornerRadius = scope:Computed(function(use)
			return UDim.new(0, 0.0171428571 * use(props.size).Y) -- Once again, I shouldn't need to do this
		end),
		LayoutOrder = props.key,

		[Fusion.Children] = {
			scope:base {
				Size = UDim2.fromScale(1, 0.3260869565),
				CornerRadius = UDim.new(0.05, 0),
				BackgroundColor3 = currentTheme.colors.crust,

				[Fusion.Children] = {
					scope:New("ImageLabel") {
						Name = "Light",
						Size = UDim2.fromScale(1, 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Rotation = props.rotator.currentValue,
						BackgroundTransparency = 1,
						Image = assets.images.elsCreator.light,
						ImageColor3 = currentTheme.colors.text,
						ScaleType = Enum.ScaleType.Fit,
						ZIndex = 3,
					},

					scope:base {
						Size = UDim2.fromScale(1, 1),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Rotation = props.rotator.currentValue,
						BackgroundTransparency = 1,
						Visible = scope:Computed(function(use)
							return use(props.playing) == true and use(color) ~= Color3.new()
						end),

						[Fusion.Children] = Fusion.Child {
							scope:New("ImageLabel") {
								Name = "Beam",
								Size = UDim2.fromScale(1, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								BackgroundTransparency = 1,
								Image = assets.images.elsCreator.beam,
								ImageColor3 = scope:Computed(function(use)
									return if use(settings.values.fakeBloom) == false
										then use(color)
										else Color3.new(1, 1, 1)
								end),
								ScaleType = Enum.ScaleType.Fit,
								ZIndex = 2,

								[Fusion.Children] = {
									scope:New("UIGradient") {
										Offset = Vector2.new(0, 0.6),
										Rotation = 90,
										Transparency = NumberSequence.new({
											NumberSequenceKeypoint.new(0, 0),
											NumberSequenceKeypoint.new(0.4, 1),
											NumberSequenceKeypoint.new(1, 1),
										}),
									},
								},
							},

							scope:New("ImageLabel") {
								Name = "LightColor",
								Size = UDim2.fromScale(1, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								BackgroundTransparency = 1,
								Image = assets.images.elsCreator.lightColor,
								ImageColor3 = scope:Computed(function(use)
									return if use(settings.values.fakeBloom) == false
										then use(color)
										else Color3.new(1, 1, 1)
								end),
								ScaleType = Enum.ScaleType.Fit,
								ZIndex = 2,
							},

							scope:Computed(function(use, scope: typeof(scope))
								return if use(settings.values.fakeBloom) == true
									then {
										scope:New("ImageLabel") {
											Name = "Bloom1",
											Size = UDim2.fromScale(1.2, 1.2),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Position = UDim2.fromScale(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = assets.images.elsCreator.bloom1,
											ImageColor3 = color,
											ScaleType = Enum.ScaleType.Fit,
										},

										scope:New("ImageLabel") {
											Name = "Bloom2",
											Size = UDim2.fromScale(2, 2),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Position = UDim2.fromScale(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = assets.images.elsCreator.bloom2,
											ImageColor3 = color,
											ScaleType = Enum.ScaleType.Fit,
										},

										scope:New("ImageLabel") {
											Name = "Bloom3",
											Size = UDim2.fromScale(1, 1),
											AnchorPoint = Vector2.new(0.5, 0.5),
											Position = UDim2.fromScale(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = assets.images.elsCreator.bloom3,
											ImageColor3 = color,
											ScaleType = Enum.ScaleType.Fit,
										},
									}
									else {}
							end),
						},
					},
				},
			},

			scope:base {
				Name = "Header",
				Size = UDim2.fromScale(0.8484848485, 0.0574712644),
				Position = UDim2.fromScale(0.5, 0.3532608696),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,

				[Fusion.Children] = {
					scope:New("UIListLayout") {
						Padding = UDim.new(0.0535714286, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					scope:iconButton {
						Size = UDim2.fromScale(0.1785714286, 1),
						LayoutOrder = 1,
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Reactive = true,
						Image = assets.images.redonUI.remove,
						BackgroundColor3 = currentTheme.colors.crust,
						ImageColor3 = currentTheme.colors.text,

						[Fusion.OnEvent "Activated"] = function()
							local function remove()
								local unpause = props.temporarlyPause()
								local currentRotators = scope.peek(props.rotators)
								table.remove(currentRotators, props.key)
								props.rotators:set(currentRotators)
								props.updateCurrentConfiguration()
								unpause()
							end

							if props.holdingShift then
								remove()
								return
							end

							popup:addPopup(scope, {
								title = "Remove Rotator",
								description = `Are you sure you want to delete rotator <b>{props.key}</b>?\n<b>All data will be lost.</b>`,
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
											remove()
										end,
										keybind = Enum.KeyCode.Return,
									},
								},
							})
						end,
					},

					scope:textBox {
						Size = UDim2.fromScale(0.5357142857, 1),
						LayoutOrder = 2,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						BackgroundColor3 = currentTheme.colors.crust,
						Text = props.rotator.lightName,
						[Fusion.Out "Text"] = props.rotator.lightName :: unknown,
						[Fusion.OnEvent "FocusLost"] = function()
							props.updateCurrentConfiguration()
						end,
					},

					scope:iconButton {
						Size = UDim2.fromScale(0.1785714286, 1),
						LayoutOrder = 3,
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Reactive = true,
						Image = assets.images.redonUI.add,
						BackgroundColor3 = currentTheme.colors.crust,
						ImageColor3 = currentTheme.colors.text,

						[Fusion.OnEvent "Activated"] = function()
							props.addRotator(props.key + 1)
						end,
					},
				},
			},

			scope:base {
				ClassName = "ScrollingFrame",
				Name = "Data",
				Size = UDim2.fromScale(0.8484848485, 0.5380434783), -- 150, 495
				Position = UDim2.fromScale(0.5, 0.972826087),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = currentTheme.colors.text,
				TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				[Fusion.Out "AbsoluteSize"] = dataSize :: unknown,

				[Fusion.Children] = Fusion.Child {
					scope:New("UIListLayout") {
						Padding = UDim.new(0.0202020202, 0),
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					scope:New("UIPadding") {
						PaddingTop = UDim.new(0, 1),
						PaddingBottom = UDim.new(0, 15),
					},

					scope:ForPairs(props.rotator.data, function(_, scope: typeof(scope), key: number, angle)
						return key,
							scope:angle {
								key = key,
								angle = angle,
								rotator = props.rotator,
								playing = props.playing,
								colors = props.colors,
								updateCurrentConfiguration = props.updateCurrentConfiguration,
								firstScope = props.firstScope,
								dataSize = dataSize,
							}
					end),

					scope:base {
						Size = UDim2.fromScale(0.5357142857, 0.1010101010),
						BackgroundTransparency = 1,
						LayoutOrder = 4000,

						[Fusion.Children] = {
							scope:iconButton {
								Size = UDim2.fromScale(0.3333333333, 1),
								LayoutOrder = 1,
								CornerRadius = UDim.new(0.2, 0),
								Border = 1,
								Reactive = true,
								Image = assets.images.redonUI.remove,
								BackgroundColor3 = currentTheme.colors.crust,
								ImageColor3 = currentTheme.colors.text,

								[Fusion.OnEvent "Activated"] = function()
									if #scope.peek(props.rotator.data) == 1 then
										log.warn("Cannot remove the last angle")
										return
									end
									local deleting = #scope.peek(props.rotator.data)

									local function remove()
										local currentData = scope.peek(props.rotator.data)
										table.remove(currentData, deleting)
										props.rotator.data:set(currentData)
									end

									if props.holdingShift then
										remove()
										return
									end

									popup:addPopup(scope, {
										title = "Remove Rotator",
										description = `Are you sure you want to delete rotator <b>{deleting}</b>?\n<b>All data will be lost.</b>`,
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
													remove()
												end,
												keybind = Enum.KeyCode.Return,
											},
										},
									})
								end,
							},

							scope:iconButton {
								Size = UDim2.fromScale(0.3333333333, 1),
								Position = UDim2.fromScale(1, 0),
								AnchorPoint = Vector2.new(1, 0),
								LayoutOrder = 2,
								CornerRadius = UDim.new(0.2, 0),
								Border = 1,
								Reactive = true,
								Image = assets.images.redonUI.add,
								BackgroundColor3 = currentTheme.colors.crust,
								ImageColor3 = currentTheme.colors.text,

								[Fusion.OnEvent "Activated"] = function()
									local currentData = scope.peek(props.rotator.data)
									table.insert(currentData, {
										type = props.firstScope:Value("Wait" :: any), -- the day I dont need this I will be so glad
										time = props.firstScope:Value(0.5),
									})
									props.rotator.data:set(currentData)
								end,
							},
						},
					},
				},
			},
		},
	}
end
