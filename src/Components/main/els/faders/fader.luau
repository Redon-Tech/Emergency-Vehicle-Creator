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

local tween = require(script.Parent.tween)
local components = {
	tween = tween,
}

--[[
	faders.fader
	Creates the fader section in the faders screen
]]
return function(
	baseScope: types.Scope,
	props: {
		key: number,
		fader: types.faderSectionState,
		size: Fusion.Value<Vector2>,
		temporarlyPause: () -> () -> (),
		faders: Fusion.Value<{ types.faderSectionState }>,
		updateCurrentConfiguration: () -> (),
		holdingShift: Fusion.Value<boolean>,
		playing: Fusion.Value<boolean>,
		colors: Fusion.Value<{ chassisHandler.color }>,
		addFader: (atPoint: number) -> (),
		firstScope: types.Scope,
	}
): Fusion.Child
	local scope = baseScope:innerScope(components)
	local currentTheme = RedonUI.theme.theme:now()
	local dataSize = scope:Value(Vector2.one)

	return scope:base {
		Name = props.key,
		Size = UDim2.fromScale(0.1764705882, 0.9735449735),
		BackgroundColor3 = currentTheme.colors.mantle,
		CornerRadius = scope:Computed(function(use)
			return UDim.new(0, 0.0171428571 * use(props.size).Y) -- Once again, I shouldn't need to do this
		end),
		LayoutOrder = props.key,

		[Fusion.Children] = {
			scope:New("UIPadding") {
				PaddingTop = UDim.new(0.0271739130, 0),
				PaddingBottom = UDim.new(0.0271739130, 0),
				PaddingLeft = UDim.new(0.0757575758, 0),
				PaddingRight = UDim.new(0.0757575758, 0),
			},

			scope:base {
				Name = "Header",
				Size = UDim2.fromScale(1, 0.0574712644),
				BackgroundTransparency = 1,
				ZIndex = 2,

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
								local currentFaders = scope.peek(props.faders)
								table.remove(currentFaders, props.key)
								props.faders:set(currentFaders)
								props.updateCurrentConfiguration()
								unpause()
							end

							if props.holdingShift then
								remove()
								return
							end

							popup:addPopup(scope, {
								title = "Remove Fader",
								description = `Are you sure you want to delete fader <b>{props.key}</b>?\n<b>All data will be lost.</b>`,
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

					scope:base {
						Size = UDim2.fromScale(0.5357142857, 1),
						LayoutOrder = 2,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						BackgroundColor3 = currentTheme.colors.crust,
						BackgroundTransparency = scope:Computed(function(use)
							return if use(props.playing) == true then 1 else 0
						end),
						ZIndex = 2,
						[Fusion.Children] = Fusion.Child {
							scope:textBox {
								Size = UDim2.fromScale(1, 1),
								BackgroundTransparency = 1,
								Text = props.fader.lightName,
								[Fusion.Out "Text"] = props.fader.lightName :: unknown,
								Visible = scope:Computed(function(use)
									return use(props.playing) == false
								end),

								[Fusion.OnEvent "FocusLost"] = function()
									props.updateCurrentConfiguration()
								end,
							},

							scope:Computed(function(use, scope: typeof(scope))
								local knownColor = scope:Value(Color3.new(1, 1, 1))
								local color = scope:Computed(function(use)
									if use(props.playing) == false then
										return Color3.new(1, 1, 1)
									end

									local currentTweens = use(props.fader.data)
									local currentTween = currentTweens[use(props.fader.currentTween)]
									if currentTween == nil then
										log.warn(
											"Somehow the current tween is nil",
											currentTweens,
											scope.peek(props.fader.currentTween)
										)
										return Color3.new(1, 1, 1)
									end
									local colorId = use(currentTween.color)
									if colorId == nil then
										return scope.peek(knownColor)
									end
									local colorData = scope.peek(props.colors)[colorId]
									local finalColor = if colorData == nil
										then Color3.new(1, 1, 1)
										else if utils.bloomColors[colorData.name] ~= nil
											then utils.bloomColors[colorData.name]
											else colorData.lightoColor
									knownColor:set(finalColor)
									return finalColor
								end)
								local visible = scope:Computed(function(use)
									return use(props.playing) == true
								end)

								if use(settings.values.fakeBloom) then
									return {
										scope:base {
											Size = UDim2.fromScale(1, 1),
											BackgroundColor3 = Color3.new(1, 1, 1),
											BackgroundTransparency = props.fader.currentValue,
											CornerRadius = UDim.new(0.2, 0),
											ZIndex = 2,
											Visible = visible,
										},

										scope:base {
											ClassName = "ImageLabel",
											Name = "Light",
											AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = assets.images.elsCreator.bloom,
											ImageColor3 = color,
											ImageTransparency = props.fader.currentValue,
											Position = UDim2.fromScale(0.5, 0.5),
											ScaleType = Enum.ScaleType.Slice,
											Size = UDim2.new(1, 25, 1, 25),
											SliceCenter = Rect.new(256, 256, 256, 256),
											Visible = visible,
										},

										scope:base {
											ClassName = "ImageLabel",
											Name = "Light1",
											AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = assets.images.elsCreator.bloom,
											ImageColor3 = color,
											ImageTransparency = scope:Computed(function(use)
												return -0.2 * (1 - use(props.fader.currentValue)) + 1
											end),
											Position = UDim2.fromScale(0.5, 0.5),
											ScaleType = Enum.ScaleType.Slice,
											Size = UDim2.new(1, 150, 1, 150),
											SliceCenter = Rect.new(256, 256, 256, 256),
											Visible = visible,
										},

										scope:base {
											ClassName = "ImageLabel",
											Name = "Light2",
											AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = assets.images.elsCreator.bloom,
											ImageColor3 = color,
											ImageTransparency = scope:Computed(function(use)
												return -0.5 * (1 - use(props.fader.currentValue)) + 1
											end),
											Position = UDim2.fromScale(0.5, 0.5),
											ScaleType = Enum.ScaleType.Slice,
											Size = UDim2.new(1, 200, 1, 200),
											SliceCenter = Rect.new(256, 256, 256, 256),
											Visible = visible,
										},
									}
								end

								return {
									scope:base {
										Size = UDim2.fromScale(1, 1),
										BackgroundColor3 = color,
										BackgroundTransparency = props.fader.currentValue,
										CornerRadius = UDim.new(0.2, 0),
										ZIndex = 2,
										Visible = visible,
									},
								}
							end),
						},
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
							props.addFader(props.key + 1)
						end,
					},
				},
			},

			scope:base {
				ClassName = "ScrollingFrame",
				Name = "Data",
				Size = UDim2.fromScale(1, 0.9137931034), -- 150, 795
				Position = UDim2.fromScale(0.5, 1),
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
						Padding = UDim.new(0.0125786164, 0),
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					scope:New("UIPadding") {
						PaddingTop = UDim.new(0, 1),
						PaddingBottom = UDim.new(0, 1),
					},

					scope:ForPairs(props.fader.data, function(_, scope: typeof(scope), key: number, tween)
						return key,
							scope:tween {
								key = key,
								tween = tween,
								dataSize = dataSize,
								firstScope = props.firstScope,
								updateCurrentConfiguration = props.updateCurrentConfiguration,
								colors = props.colors,
								fader = props.fader,
								playing = props.playing,
							}
					end),

					scope:base {
						Size = UDim2.fromScale(0.5357142857, 0.0628930818),
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
									if #scope.peek(props.fader.data) == 1 then
										log.warn("Cannot remove the last tween")
										return
									end
									local deleting = #scope.peek(props.fader.data)

									local function remove()
										local currentData = scope.peek(props.fader.data)
										table.remove(currentData, deleting)
										props.fader.data:set(currentData)
									end

									if props.holdingShift then
										remove()
										return
									end

									popup:addPopup(scope, {
										title = "Remove Tween",
										description = `Are you sure you want to delete tween <b>{deleting}</b>?\n<b>All data will be lost.</b>`,
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
									local currentData = scope.peek(props.fader.data)
									table.insert(
										currentData,
										{
											type = props.firstScope:Value("Wait"),
											time = props.firstScope:Value(0.5),
										} :: any
									)
									props.fader.data:set(currentData)
								end,
							},
						},
					},
				},
			},
		},
	}
end
