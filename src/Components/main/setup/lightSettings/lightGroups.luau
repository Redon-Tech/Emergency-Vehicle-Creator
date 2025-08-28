--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)
local chassisHandler = require(root.Plugin.chassisHandler)
local popup = require(root.Plugin.Components.popup)

type props = {
	firstScope: types.Scope,
	actualTableSize: Fusion.Value<Vector2>,
	currentContent: Fusion.Value<"settings" | "colors" | "light groups">,
	lightSettings: Fusion.Value<chassisHandler.lightSettingsState?>,
	lightParts: Fusion.Value<{ string }>,
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
	local holdingShift = false

	return scope:base {
		ClassName = "ScrollingFrame",
		Size = UDim2.fromScale(1, 0.9162011173), -- 1820, 820
		AnchorPoint = Vector2.new(0.5, 1),
		Position = scope:Spring(
			scope:Computed(function(use)
				local activeContent = use(props.currentContent)
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

		[Fusion.Children] = Fusion.Child {
			scope:New("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			scope:Computed(function(use, scope: typeof(scope))
				local currentLightSettings = use(props.lightSettings)
				local lastLight = 0
				if currentLightSettings ~= nil then
					return scope:ForPairs(
						currentLightSettings.lightGroups,
						function(_, scope: typeof(scope), key: number, value)
							local isOpen = scope:Value(false)
							local name = scope:Value(scope.peek(value.name))
							local size = scope:Value(Vector2.one)

							local function lightClicked(lightKey: number, lightName: string)
								local currentLightParts = scope.peek(props.lightParts)
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
												return UDim2.new(1, 0, 0, 0.0914634146 * use(props.actualTableSize).Y)
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
														local currentLightSettings = scope.peek(props.lightSettings)
														if currentLightSettings ~= nil then
															local currentLightGroups =
																scope.peek(currentLightSettings.lightGroups)
															currentLightGroups[key].name:set(scope.peek(name))
															currentLightSettings.lightGroups:set(currentLightGroups)
														end
														props.updateCurrentConfiguration()
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
																			scope.peek(props.lightSettings)
																		if currentLightSettings then
																			local currentLightGroups = scope.peek(
																				currentLightSettings.lightGroups
																			)
																			table.remove(currentLightGroups, key)
																			currentLightSettings.lightGroups:set(
																				currentLightGroups
																			)
																			props.updateCurrentConfiguration()
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
															0.2743902439 * use(props.actualTableSize).Y
														)
														else UDim2.fromScale(1, 0)
												end),
												20,
												0.75
											),
											Position = scope:Computed(function(use)
												return UDim2.fromOffset(0, 0.0914634146 * use(props.actualTableSize).Y)
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
													props.lightParts,
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
																	props.updateCurrentConfiguration()
																end :: unknown,

																[Fusion.Children] = {
																	scope:checkBox {
																		Size = UDim2.fromScale(0.2, 0.6666666667),
																		AnchorPoint = Vector2.new(1, 0.5),
																		Position = UDim2.fromScale(0.9333333333, 0.5),
																		BackgroundColor3 = currentTheme.colors.crust,
																		CornerRadius = scope:Computed(function(use)
																			return UDim.new(
																				0,
																				0.0091463415
																					* use(props.actualTableSize).Y
																			)
																		end),
																		Border = 1,
																		BorderColor3 = currentTheme.colors.white,
																		SelectedColor3 = currentTheme.colors.blue,
																		SelectedCheckColor3 = currentTheme.colors.crust,
																		Enabled = scope:Computed(function(use)
																			local currentLights = use(value.lights)
																			return table.find(currentLights, lightName)
																				~= nil
																		end),

																		[Fusion.OnEvent "Activated"] = function()
																			lightClicked(lightKey, lightName)
																			props.updateCurrentConfiguration()
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
							local currentLightSettings = scope.peek(props.lightSettings)
							if currentLightSettings then
								local currentLightGroups = scope.peek(currentLightSettings.lightGroups)
								table.insert(currentLightGroups, {
									name = props.firstScope:Value("Group"),
									lights = props.firstScope:Value({}),
								})
								currentLightSettings.lightGroups:set(currentLightGroups)
								props.updateCurrentConfiguration()
							end
							props.updateCurrentConfiguration()
						end,
					},
				},
			},
		},
	}
end
