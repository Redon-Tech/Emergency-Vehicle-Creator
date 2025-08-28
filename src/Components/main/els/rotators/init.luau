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
local utils = require(root.Plugin.utils)
local RunService = game:GetService("RunService")

local rotator = require(script.rotator)
local components = {
	rotator = rotator,
}

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
}

--[[
	Rotators
	Creates the rotators screen for the main app
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()
	local scope = baseScope:innerScope(components)
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
	local holdingShift = scope:Value(false) -- This is used to skip certain popups
	local rotators: Fusion.Value<{ types.rotatorSectionState }> = scope:Value({})

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
					holdingShift:set(true)
				end
			end
		end :: unknown,

		[Fusion.OnEvent "InputEnded"] = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.LeftShift then
					holdingShift:set(false)
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

							scope:ForPairs(rotators, function(_, scope: typeof(scope), key: number, rotator)
								return key,
									scope:rotator {
										key = key,
										rotator = rotator,
										playing = playing,
										holdingShift = holdingShift,
										colors = colors,
										rotators = rotators,
										temporarlyPause = temporarlyPause,
										updateCurrentConfiguration = updateCurrentConfiguration,
										addRotator = addRotator,
										firstScope = firstScope,
										size = size,
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
