--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local popup = require(root.Plugin.Components.popup)
local chassisHandler = require(root.Plugin.chassisHandler)
local assets = require(root.Plugin.assets)
local log = require(root.Plugin.log)
local settings = require(root.Plugin.settings)
local utils = require(root.Plugin.utils)
local RunService = game:GetService("RunService")

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
}

type rotatorSectionState = {
	lightName: Fusion.Value<string>,
	currentPercentage: Fusion.Value<number>,
	currentAngle: Fusion.Value<number>,
	currentValue: Fusion.Value<number>,
	previousGoal: number?,
	data: Fusion.Value<
		{
			{
				type: Fusion.Value<"Angle" | "Infinite" | "Wait">,
				-- Non-Wait Specific
				velocity: Fusion.Value<number>?,
				color: Fusion.Value<types.elsColor>?,

				-- Angle Specific
				angle: Fusion.Value<number>?,

				-- Wait Specific
				time: Fusion.Value<number>?,
			}
		}
	>,
}

local bloomColors = {
	Blue = Color3.fromRGB(17, 99, 207),
	Red = Color3.fromRGB(255, 61, 61),
	Yello = Color3.fromRGB(255, 230, 43),
	White = Color3.fromRGB(255, 255, 255),
	Green = Color3.fromRGB(94, 225, 110),
	Purple = Color3.fromRGB(246, 114, 255),
}

--[[
	Rotators
	Creates the rotators screen for the main app
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()
	local function getColorByName(name: string, default: Color3): Color3
		if name == "Purple" then
			name = "Mauve"
		end
		local color = currentTheme.colors[name:lower()]
		if color == nil then
			return default
		end
		return color
	end
	local firstScope = scope:innerScope()

	local currentConfiguration: chassisHandler.chassisConfiguration? = nil
	local colors: Fusion.Value<{ chassisHandler.color }> = scope:Value(chassisHandler.defaults.colors)
	local playing = scope:Value(false)
	local function temporarlyPause()
		local wasPlaying = scope.peek(playing)
		playing:set(false)
		return function()
			playing:set(wasPlaying)
		end
	end
	local holdingShift = false -- This is used to skip certain popups
	local rotators: Fusion.Value<{ rotatorSectionState }> = scope:Value({})

	local function updateCurrentConfiguration()
		local currentPattern = scope.peek(props.CurrentPattern)
		if currentPattern ~= nil then
			local assembledRotators: { types.rotatorSection } = {}
			for _, rotator in scope.peek(rotators) do
				local assembledData: { types.rotatorData } = {}
				for _, angle in scope.peek(rotator.data) do
					if scope.peek(angle.type) == "Angle" then
						table.insert(assembledData, {
							type = "Angle",
							color = scope.peek(angle.color),
							angle = scope.peek(angle.angle),
							velocity = scope.peek(angle.velocity),
						})
					elseif scope.peek(angle.type) == "Infinite" then
						table.insert(assembledData, {
							type = "Infinite",
							color = scope.peek(angle.color),
							velocity = scope.peek(angle.velocity),
						})
					elseif scope.peek(angle.type) == "Wait" then
						table.insert(assembledData, {
							type = "Wait",
							time = scope.peek(angle.time),
						})
					end
				end
				table.insert(assembledRotators, {
					lightName = scope.peek(rotator.lightName),
					data = assembledData,
				})
			end

			if utils.compareTables(currentPattern.pattern.rotators, assembledRotators) == true then
				return
			end

			currentPattern.pattern.rotators = assembledRotators
			props.UnsavedChanges:set(true)
		end
	end

	local function promptReset()
		popup:addPopup(scope, {
			title = "Reset Rotators",
			description = "Are you sure you want to reset all rotators?\n<b>All data will be lost.</b>",
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
					text = "Reset",
					type = "danger",
					key = 2,
					callback = function(newPopup)
						popup:removePopup(newPopup)
						playing:set(false)
						rotators:set({})
						updateCurrentConfiguration()
					end,
				},
			},
		})
	end

	scope:Observer(props.CurrentPattern):onChange(function()
		local currentPattern = scope.peek(props.CurrentPattern)
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if currentPattern ~= nil then
			playing:set(false)
			if typeof(currentVehicle) == "Instance" then
				currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
				if currentConfiguration ~= nil then
					colors:set(currentConfiguration.lightSettings.colors)
				else
					colors:set(chassisHandler.defaults.colors)
				end
			end

			local newRotators = {}
			for i, rotator in currentPattern.pattern.rotators do
				local data = {}
				for angleId, angle in rotator.data do
					if angle.type == "Angle" then
						table.insert(data, angleId, {
							type = firstScope:Value(angle.type :: any),
							color = angle.color and firstScope:Value(angle.color) or nil,
							angle = angle.angle and firstScope:Value(angle.angle) or nil,
							velocity = angle.velocity and firstScope:Value(angle.velocity) or nil,
						})
					elseif angle.type == "Infinite" then
						table.insert(data, angleId, {
							type = firstScope:Value(angle.type :: any),
							color = angle.color and firstScope:Value(angle.color) or nil,
							velocity = angle.velocity and firstScope:Value(angle.velocity) or nil,
						})
					elseif angle.type == "Wait" then
						table.insert(data, angleId, {
							type = firstScope:Value(angle.type :: any),
							time = angle.time and firstScope:Value(angle.time) or nil,
						})
					end
				end
				local newRotator = {
					lightName = firstScope:Value(rotator.lightName),
					currentPercentage = firstScope:Value(0),
					currentAngle = firstScope:Value(1),
					currentValue = firstScope:Value(0),
					previousGoal = 0,
					data = firstScope:Value(data),
				}
				table.insert(newRotators, i, newRotator)
			end
			log.debug(newRotators)
			rotators:set(newRotators)
		end
	end)

	local function addRotator(atPoint: number?)
		local unpause = temporarlyPause()
		local currentRotators = scope.peek(rotators)
		if atPoint == nil then
			atPoint = #currentRotators + 1
		end
		table.insert(currentRotators, atPoint :: number, {
			lightName = firstScope:Value("Rotator " .. atPoint :: number),
			data = firstScope:Value({
				{
					type = firstScope:Value("Angle" :: any), -- me when luau types
					color = firstScope:Value(1),
					angle = firstScope:Value(90),
					velocity = firstScope:Value(0.1),
				},
				{
					type = firstScope:Value("Angle" :: any), -- me when luau types
					color = firstScope:Value(1),
					angle = firstScope:Value(-90),
					velocity = firstScope:Value(0.1),
				},
			}),
			currentAngle = firstScope:Value(1),
			currentPercentage = firstScope:Value(0),
			currentValue = firstScope:Value(0),
		})

		rotators:set(currentRotators)
		updateCurrentConfiguration()
		unpause()
	end

	-- player
	local connection: RBXScriptConnection? = nil
	scope:Observer(playing):onChange(function()
		local isPlaying = scope.peek(playing)
		local currentRotators = scope.peek(rotators)
		if isPlaying == true then
			log.debug("Playing")
			for _, data in currentRotators do
				if data.previousGoal == nil then
					data.previousGoal = 0
				end
			end

			connection = RunService.Heartbeat:Connect(function(deltaTime: number)
				for _, data in currentRotators do
					local currentAngles = scope.peek(data.data)
					local angleId = scope.peek(data.currentAngle)
					local currentPercentage = scope.peek(data.currentPercentage)
					if angleId > #currentAngles then
						angleId = 1
						currentPercentage = 0
					end

					data.currentAngle:set(angleId) -- Fusion wont push this change if its the same value
					local currentAngle = currentAngles[angleId]
					if scope.peek(currentAngle.type) == "Angle" then
						local currentRotation = math.rad(scope.peek(data.currentValue))
						local goal = math.rad(scope.peek(currentAngle.angle))
						local velocity: number = math.abs(scope.peek(currentAngle.velocity))

						local difference = goal - currentRotation
						-- log.debug(angleId, currentRotation, math.clamp(difference, -velocity, velocity))
						if math.abs(difference) == 0 then
							data.currentAngle:set(if angleId ~= #currentAngles then angleId + 1 else 1)
							data.previousGoal = goal
							currentPercentage = 0
						else
							currentRotation += math.clamp(difference, -velocity, velocity)
							currentPercentage = 1 - ((goal - currentRotation) / (goal - data.previousGoal :: number))

							data.currentValue:set(math.deg(currentRotation))
						end
					elseif scope.peek(currentAngle.type) == "Infinite" then
						local currentRotation = math.rad(scope.peek(data.currentValue))
						local velocity: number = scope.peek(currentAngle.velocity)
						-- log.debug(angleId, scope.peek(currentAngle.color))

						currentRotation += (velocity * 60) * deltaTime
						data.currentValue:set(math.deg(currentRotation) % 360)
					else
						-- log.debug(angleId, scope.peek(currentAngle.time))
						currentPercentage += deltaTime / scope.peek(currentAngle.time)
						if currentPercentage >= 1 then
							data.currentAngle:set(if angleId ~= #currentAngles then angleId + 1 else 1)
							currentPercentage = 0
						end
					end
					data.currentPercentage:set(currentPercentage)
				end
			end)
		else
			log.debug("Stopping")
			if connection ~= nil then
				connection:Disconnect()
				connection = nil
			end

			-- Reset the faders to ensure they stay in sync
			for _, data in currentRotators do
				data.currentAngle:set(1)
				data.currentPercentage:set(0)
				data.currentValue:set(0)
				data.previousGoal = 0
			end
		end
	end)

	scope:Observer(props.Enabled):onChange(function()
		local enabled = scope.peek(props.Enabled)
		if enabled == false then
			playing:set(false)
		end
	end)

	scope:Observer(props.CurrentPage):onBind(function()
		local currentPage = scope.peek(props.CurrentPage)
		if currentPage ~= "Rotators" then
			playing:set(false)
		end
	end)

	local playHovered = scope:Value(false)
	local size = scope:Value(Vector2.one)
	local sectionsTotalSpace = scope:Value(Vector2.one)
	return scope:base {
		Name = "Rotators",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Spring(
			scope:Computed(function(use)
				local currentPage = use(props.CurrentPage)
				if currentPage == "Rotators" then
					return UDim2.fromScale(0.5, 0.0462962963)
				end
				return UDim2.fromScale(1.5, 0.0462962963)
			end),
			20,
			0.75
		),
		Size = UDim2.fromScale(1, 0.9537037037),
		BackgroundTransparency = 1,

		[Fusion.OnEvent "InputBegan"] = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.P then
					playing:set(not scope.peek(playing))
				elseif input.KeyCode == Enum.KeyCode.LeftShift then
					holdingShift = true
				end
			end
		end :: unknown,

		[Fusion.OnEvent "InputEnded"] = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.LeftShift then
					holdingShift = false
				end
			end
		end :: unknown,

		[Fusion.Children] = {
			scope:base {
				Name = "Header",
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 0.0582524272),
				BackgroundColor3 = currentTheme.colors.mantle,

				[Fusion.Children] = {
					scope:base {
						ClassName = "ScrollingFrame",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						CanvasSize = UDim2.new(),
						ScrollBarThickness = 3,
						ScrollBarImageColor3 = currentTheme.colors.text,
						TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
						BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
						AutomaticCanvasSize = Enum.AutomaticSize.X,
						ClipsDescendants = false,

						[Fusion.Children] = Fusion.Child {
							scope:New("UIAspectRatioConstraint") {
								AspectRatio = 32,
							},

							scope:New "UIListLayout" {
								Padding = UDim.new(0.0078125, 0),
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
							},

							scope:iconButton {
								Size = UDim2.fromScale(0.0260416667, 0.8333333333),
								CornerRadius = UDim.new(0.2, 0),
								Border = 2,
								Reactive = true,
								LayoutOrder = 100,
								Image = scope:Computed(function(use)
									local isPlaying = use(playing)
									return if isPlaying
										then assets.images.redonUI.pause
										else if use(playHovered)
											then assets.images.redonUI.playFilled
											else assets.images.redonUI.play
								end),
								BackgroundColor3 = currentTheme.colors.mantle,
								ImageColor3 = currentTheme.colors.text,
								MouseEnter = function()
									playHovered:set(true)
								end,
								MouseLeave = function()
									playHovered:set(false)
								end,
								[Fusion.OnEvent "Activated"] = function()
									playing:set(not scope.peek(playing))
								end,
							},

							scope:iconButton {
								Size = UDim2.fromScale(0.0260416667, 0.8333333333),
								CornerRadius = UDim.new(0.2, 0),
								Border = 2,
								Reactive = true,
								LayoutOrder = 102,
								Image = assets.images.redonUI.refresh,
								BackgroundColor3 = currentTheme.colors.mantle,
								ImageColor3 = currentTheme.colors.text,
								[Fusion.OnEvent "Activated"] = function()
									promptReset()
								end,
							},
						},
					},
				},
			},

			scope:base {
				Size = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundTransparency = 1,
				ClipsDescendants = true,

				[Fusion.Children] = {
					scope:New("UIAspectRatioConstraint") {
						AspectRatio = 1.9793814433,
					},

					scope:base {
						ClassName = "ScrollingFrame",
						Name = "Content",
						Size = UDim2.fromScale(0.9739583333, 0.9174757282), -- 1870, 945
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.fromScale(0.5, 1),
						BackgroundTransparency = 1,
						CanvasSize = UDim2.new(),
						AutomaticCanvasSize = Enum.AutomaticSize.X,
						ScrollBarThickness = 3,
						ScrollBarImageColor3 = currentTheme.colors.text,
						TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
						BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
						[Fusion.Out "AbsoluteSize"] = size :: unknown,
						ClipsDescendants = false,

						[Fusion.Children] = Fusion.Child {
							scope:New("UIListLayout") {
								Padding = UDim.new(0.0130208333, 0),
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = scope:Computed(function(use)
									return if use(sectionsTotalSpace).X > use(size).X
										then Enum.HorizontalAlignment.Left
										else Enum.HorizontalAlignment.Center
								end),
								VerticalAlignment = Enum.VerticalAlignment.Top,
								SortOrder = Enum.SortOrder.LayoutOrder,
								[Fusion.Out "AbsoluteContentSize"] = sectionsTotalSpace :: unknown,
							},

							scope:ForPairs(rotators, function(_, scope: typeof(scope), key: number, value)
								local dataSize = scope:Value(Vector2.one)
								local color = scope:Computed(function(use)
									if use(playing) == false then
										return Color3.new()
									end

									local currentAngles = use(value.data)
									local currentAngle = currentAngles[use(value.currentAngle)]
									if currentAngle == nil then
										log.warn(
											"Somehow the current angle is nil",
											currentAngle,
											scope.peek(value.currentAngle)
										)
										return Color3.new()
									end
									local colorId = use(currentAngle.color)
									if colorId == nil then
										return Color3.new()
									end
									local colorData = scope.peek(colors)[colorId]
									local finalColor = if colorData == nil
										then Color3.new()
										else if bloomColors[colorData.name] ~= nil
											then bloomColors[colorData.name]
											else colorData.lightoColor
									return finalColor
								end)
								return key,
									scope:base {
										Name = key,
										Size = UDim2.fromScale(0.1764705882, 0.9735449735),
										BackgroundColor3 = currentTheme.colors.mantle,
										CornerRadius = scope:Computed(function(use)
											return UDim.new(0, 0.0171428571 * use(size).Y) -- Once again, I shouldn't need to do this
										end),
										LayoutOrder = key,

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
														Rotation = value.currentValue,
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
														Rotation = value.currentValue,
														BackgroundTransparency = 1,
														Visible = scope:Computed(function(use)
															return use(playing) == true and use(color) ~= Color3.new()
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
																	return if use(settings.values.fakeBloom)
																			== false
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
																	return if use(settings.values.fakeBloom)
																			== false
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
																local unpause = temporarlyPause()
																local currentRotators = scope.peek(rotators)
																table.remove(currentRotators, key)
																rotators:set(currentRotators)
																updateCurrentConfiguration()
																unpause()
															end

															if holdingShift then
																remove()
																return
															end

															popup:addPopup(scope, {
																title = "Remove Rotator",
																description = `Are you sure you want to delete rotator <b>{key}</b>?\n<b>All data will be lost.</b>`,
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
														Text = value.lightName,
														[Fusion.Out "Text"] = value.lightName :: unknown,
														[Fusion.OnEvent "FocusLost"] = function()
															updateCurrentConfiguration()
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
															addRotator(key + 1)
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

													scope:ForPairs(
														value.data,
														function(_, scope: typeof(scope), key: number, angle)
															local controlSize = scope:Computed(function(use)
																return UDim2.new(
																	1,
																	0,
																	0,
																	0.1010101010 * use(dataSize).Y
																)
															end)
															local cornerRadius = scope:Computed(function(use)
																return UDim.new(0, 0.0202020202 * use(dataSize).Y)
															end)
															local baseDropdown = scope:dropdown {
																Size = controlSize,
																BackgroundColor3 = currentTheme.colors.crust,
																CornerRadius = cornerRadius,
																Border = 1,
																Text = angle.type :: any,
																TextXAlignment = Enum.TextXAlignment.Left,
																LayoutOrder = 1,
																DropdownHeight = 150,
																Options = {
																	"Angle",
																	"Infinite",
																	"Wait",
																},
																OnOptionSelected = function(_, newType)
																	if newType == "Wait" then
																		angle.color = nil
																		angle.angle = nil
																		angle.velocity = nil
																		angle.time = if angle.time ~= nil
																			then angle.time
																			else firstScope:Value(0.1)
																	elseif newType == "Infinite" then
																		angle.angle = nil
																		angle.time = nil
																		angle.color = if angle.color ~= nil
																			then angle.color
																			else firstScope:Value(1)
																		angle.velocity = if angle.velocity ~= nil
																			then angle.velocity
																			else firstScope:Value(0.1)
																	elseif newType == "Angle" then
																		angle.time = nil
																		angle.angle = if angle.angle ~= nil
																			then angle.angle
																			else firstScope:Value(90)
																		angle.color = if angle.color ~= nil
																			then angle.color
																			else firstScope:Value(1)
																		angle.velocity = if angle.velocity ~= nil
																			then angle.velocity
																			else firstScope:Value(0.1)
																	end

																	angle.type:set(
																		newType :: "Angle" | "Infinite" | "Wait"
																	)
																	updateCurrentConfiguration()
																end,
															}
															local baseDropdownFrame = baseDropdown[2] :: Frame
															baseDropdownFrame.LayoutOrder = 2
															local baseControls: { Fusion.Child } = {
																baseDropdown,
															}

															local controls = scope:Computed(
																function(use, scope: typeof(scope))
																	local controls: { Fusion.Child } = baseControls
																	local currentType = use(angle.type)

																	if
																		currentType == "Angle"
																		or currentType == "Infinite"
																	then
																		if angle.color ~= nil then
																			local colorDropdown = scope:dropdown {
																				Size = controlSize,
																				BackgroundColor3 = currentTheme.colors.crust,
																				CornerRadius = cornerRadius,
																				Border = 1,
																				Text = scope:Computed(function(use)
																					local colorId = use(angle.color)
																					return if colorId == 0
																						then "None"
																						else use(colors)[colorId].name
																				end),
																				TextXAlignment = Enum.TextXAlignment.Left,
																				LayoutOrder = 3,
																				DropdownHeight = 150,
																				Options = scope:Computed(function(use)
																					local newColors: { string } = {}
																					for colorId, color in
																						pairs(use(colors))
																					do
																						table.insert(
																							newColors,
																							colorId,
																							color.name
																						)
																					end
																					table.insert(newColors, 1, "None")
																					return newColors
																				end),
																				OptionOverrides = scope:Computed(
																					function(use)
																						local textColors = {}
																						for colorId, color in
																							pairs(use(colors))
																						do
																							textColors[colorId] = {
																								TextColor3 = getColorByName(
																									color.name,
																									currentTheme.colors.text
																								),
																							}
																						end
																						table.insert(textColors, 1, {
																							TextColor3 = currentTheme.colors.text,
																						})
																						return textColors :: any
																					end
																				),
																				TextColor3 = scope:Computed(
																					function(use)
																						local colorId = use(angle.color)
																						return if colorId == 0
																							then currentTheme.colors.text
																							else getColorByName(
																								use(colors)[colorId].name,
																								currentTheme.colors.text
																							)
																					end
																				),
																				OnOptionSelected = function(
																					colorId: number
																				)
																					angle.color:set(colorId - 1)
																					updateCurrentConfiguration()
																				end,
																			}
																			local colorDropdownFrame =
																				colorDropdown[2] :: Frame
																			colorDropdownFrame.LayoutOrder = 4
																			table.insert(controls, colorDropdown)
																		end
																		if angle.velocity ~= nil then
																			local currentText = scope:Value(
																				tostring(scope.peek(angle.velocity))
																			)
																			table.insert(
																				controls,
																				scope:textBox {
																					Size = controlSize,
																					BackgroundColor3 = currentTheme.colors.crust,
																					CornerRadius = UDim.new(0.2, 0),
																					Border = 1,
																					Text = currentText,
																					[Fusion.Out "Text"] = currentText :: unknown,
																					PlaceholderText = "Velocity",
																					PlaceholderColor3 = currentTheme.colors.subtext0,
																					LayoutOrder = 7,
																					[Fusion.OnEvent "FocusLost"] = function()
																						angle.velocity:set(
																							tonumber(
																								scope.peek(currentText)
																							)
																								or 0
																						)
																						currentText:set(
																							tostring(
																								scope.peek(
																									angle.velocity
																								)
																							)
																						)
																						updateCurrentConfiguration()
																					end,
																				}
																			)
																		end
																	elseif currentType == "Wait" then
																		if angle.time ~= nil then
																			local currentText = scope:Value(
																				tostring(scope.peek(angle.time))
																			)
																			table.insert(
																				controls,
																				scope:textBox {
																					Size = controlSize,
																					BackgroundColor3 = currentTheme.colors.crust,
																					CornerRadius = UDim.new(0.2, 0),
																					Border = 1,
																					Text = currentText,
																					[Fusion.Out "Text"] = currentText :: unknown,
																					PlaceholderText = "Wait Time",
																					PlaceholderColor3 = currentTheme.colors.subtext0,
																					LayoutOrder = 7,
																					[Fusion.OnEvent "FocusLost"] = function()
																						angle.time:set(
																							tonumber(
																								scope.peek(currentText)
																							)
																								or 0
																						)
																						currentText:set(
																							tostring(
																								scope.peek(angle.time)
																							)
																						)
																						updateCurrentConfiguration()
																					end,
																				}
																			)
																		end
																	end

																	if currentType == "Angle" then
																		if angle.angle ~= nil then
																			local currentText = scope:Value(
																				tostring(scope.peek(angle.angle))
																			)
																			table.insert(
																				controls,
																				scope:textBox {
																					Size = controlSize,
																					BackgroundColor3 = currentTheme.colors.crust,
																					CornerRadius = UDim.new(0.2, 0),
																					Border = 1,
																					Text = currentText,
																					[Fusion.Out "Text"] = currentText :: unknown,
																					PlaceholderText = "Angle",
																					PlaceholderColor3 = currentTheme.colors.subtext0,
																					LayoutOrder = 6,
																					[Fusion.OnEvent "FocusLost"] = function()
																						angle.angle:set(
																							tonumber(
																								scope.peek(currentText)
																							)
																								or 0
																						)
																						currentText:set(
																							tostring(
																								scope.peek(angle.angle)
																							)
																						)
																						updateCurrentConfiguration()
																					end,
																				}
																			)
																		end
																	end

																	return controls
																end
															)

															return key,
																scope:base {
																	Name = key,
																	Size = UDim2.fromScale(0.5357142857, 0),
																	BackgroundTransparency = 1,
																	LayoutOrder = key,
																	AutomaticSize = Enum.AutomaticSize.Y,

																	[Fusion.Children] = {
																		scope:base {
																			ClassName = "ImageLabel",
																			Size = UDim2.fromScale(0.1333333333, 1),
																			Position = UDim2.fromScale(
																				-0.0666666667,
																				0
																			),
																			AnchorPoint = Vector2.new(1, 0),
																			BackgroundTransparency = 1,
																			Image = assets.images.elsCreator.box,
																			ResampleMode = Enum.ResamplerMode.Pixelated,
																			ScaleType = Enum.ScaleType.Slice,
																			SliceCenter = Rect.new(2, 2, 18, 33),

																			[Fusion.Children] = {
																				scope:New("UIGradient") {
																					Name = "UIGradient",
																					Color = ColorSequence.new({
																						ColorSequenceKeypoint.new(
																							0,
																							currentTheme.colors.blue
																						),
																						ColorSequenceKeypoint.new(
																							0.001,
																							currentTheme.colors.text
																						),
																						ColorSequenceKeypoint.new(
																							1,
																							currentTheme.colors.text
																						),
																					}),
																					Offset = scope:Computed(
																						function(use)
																							local percent = 0
																							if use(playing) == true then
																								if
																									use(
																										value.currentAngle
																									)
																									== key
																								then
																									if
																										use(angle.type)
																										== "Infinite"
																									then
																										percent = 1
																									else
																										percent = use(
																											value.currentPercentage
																										)
																									end
																								elseif
																									use(
																										value.currentAngle
																									)
																									> key
																								then
																									percent = 1
																								end
																							end
																							return Vector2.new(
																								0,
																								percent
																							)
																						end
																					),
																					Rotation = 90,
																				},
																			},
																		},

																		scope:base {
																			Name = "Controls",
																			Size = UDim2.fromScale(1, 0),
																			Position = UDim2.fromScale(0, 0),
																			BackgroundTransparency = 1,
																			AutomaticSize = Enum.AutomaticSize.Y,

																			[Fusion.Children] = Fusion.Child {
																				scope:New("UIListLayout") {
																					Padding = scope:Computed(
																						function(use)
																							return UDim.new(
																								0,
																								0.0202020202
																									* use(dataSize).Y
																							)
																						end
																					),
																					FillDirection = Enum.FillDirection.Vertical,
																					HorizontalAlignment = Enum.HorizontalAlignment.Center,
																					VerticalAlignment = Enum.VerticalAlignment.Top,
																					SortOrder = Enum.SortOrder.LayoutOrder,
																				},

																				controls,
																			},
																		},
																	},
																}
														end
													),

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
																	if #scope.peek(value.data) == 1 then
																		log.warn("Cannot remove the last angle")
																		return
																	end
																	local deleting = #scope.peek(value.data)

																	local function remove()
																		local currentData = scope.peek(value.data)
																		table.remove(currentData, deleting)
																		value.data:set(currentData)
																	end

																	if holdingShift then
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
																	local currentData = scope.peek(value.data)
																	table.insert(currentData, {
																		type = firstScope:Value("Wait" :: any), -- the day I dont need this I will be so glad
																		time = firstScope:Value(0.5),
																	})
																	value.data:set(currentData)
																end,
															},
														},
													},
												},
											},
										},
									}
							end),
						},
					},

					scope:textButton {
						Size = UDim2.fromScale(0.1822916667, 0.0776699029),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundColor3 = Color3.new(1, 1, 1),
						Gradient = ColorSequence.new(currentTheme.colors.sky, currentTheme.colors.sapphire),
						CornerRadius = UDim.new(0.2, 0),
						Text = "Add Section",
						TextScaled = true,
						MaxTextSize = 40,
						TextColor3 = currentTheme.colors.mantle,
						Border = 2,
						Reactive = true,
						ButtonGlow = true,
						ButtonGlowColor3 = if currentTheme.colors.white == Color3.new(1, 1, 1)
							then currentTheme.colors.text
							else currentTheme.colors.base,
						Shadow = true,
						ShadowColor3 = currentTheme.colors.sky,
						Visible = scope:Computed(function(use)
							return #use(rotators) == 0
						end),

						[Fusion.OnEvent "Activated"] = function()
							addRotator()
						end,
					},
				},
			},
		},
	}
end
