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
local TweenService = game:GetService("TweenService")

local faderComponent = require(script.fader)
local components = {
	faderComponent = faderComponent,
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
	Faders
	Creates the faders screen for the main app
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local scope = baseScope:innerScope(components)
	local currentTheme = RedonUI.theme.theme:now()
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
	local faders: Fusion.Value<{ types.faderSectionState }> = scope:Value({})

	local function updateCurrentConfiguration()
		local currentPattern = scope.peek(props.CurrentPattern)
		if currentPattern ~= nil then
			local assembledFaders: { types.faderSection } = {}
			for faderId, fader in scope.peek(faders) do
				local assembledTweens: { types.faderData } = {}
				for tweenId, tween in scope.peek(fader.data) do
					table.insert(assembledTweens, tweenId, {
						type = scope.peek(tween.type) :: any,
						time = scope.peek(tween.time),
						goal = if tween.goal then scope.peek(tween.goal) else nil,
						color = if tween.color then scope.peek(tween.color) else nil,
						easingStyle = if tween.easingStyle then scope.peek(tween.easingStyle) else nil,
						easingDirection = if tween.easingDirection then scope.peek(tween.easingDirection) else nil,
					})
				end
				table.insert(assembledFaders, faderId, {
					lightName = scope.peek(fader.lightName),
					data = assembledTweens,
				})
			end

			if utils.compareTables(currentPattern.pattern.faders, assembledFaders) == true then
				return
			end

			currentPattern.pattern.faders = assembledFaders
			props.UnsavedChanges:set(true)
		end
	end

	local function promptReset()
		popup:addPopup(scope, {
			title = "Reset Faders",
			description = "Are you sure you want to reset all faders?\n<b>All data will be lost.</b>",
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
						faders:set({})
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

			local newFaders = {}
			for faderId, fader in currentPattern.pattern.faders do
				local newFader = {
					lightName = firstScope:Value(fader.lightName),
					currentPercentage = firstScope:Value(0),
					currentTween = firstScope:Value(1),
					currentValue = firstScope:Value(0),
					previousGoal = 1,
					data = firstScope:Value({}),
				}
				local newData = {}
				for tweenId, tween in fader.data do
					if tween.type == "Simple" then
						table.insert(newData, tweenId, {
							type = firstScope:Value(tween.type),
							time = firstScope:Value(tween.time),
							goal = tween.goal and firstScope:Value(tween.goal) or nil,
							color = tween.color and scope:Value(tween.color) or nil,
						})
					elseif tween.type == "Advanced" then
						table.insert(newData, tweenId, {
							type = firstScope:Value(tween.type),
							time = firstScope:Value(tween.time),
							goal = tween.goal and firstScope:Value(tween.goal) or nil,
							color = tween.color and firstScope:Value(tween.color) or nil,
							easingStyle = tween.easingStyle and firstScope:Value(tween.easingStyle) or nil,
							easingDirection = tween.easingDirection and firstScope:Value(tween.easingDirection) or nil,
						})
					elseif tween.type == "Wait" then
						table.insert(newData, tweenId, {
							type = firstScope:Value(tween.type),
							time = firstScope:Value(tween.time),
						})
					end
				end
				newFader.data:set(newData)
				table.insert(newFaders, faderId, newFader)
			end
			log.debug(faders)
			faders:set(newFaders)
		end
	end)

	local function addFader(atPoint: number?)
		local unpause = temporarlyPause()
		local currentFaders = scope.peek(faders)
		if atPoint == nil then
			atPoint = #currentFaders + 1
		end
		table.insert(currentFaders, atPoint :: number, {
			lightName = firstScope:Value("Fader " .. atPoint :: number),
			data = firstScope:Value({
				{
					type = firstScope:Value("Simple" :: any), -- me when luau types
					time = firstScope:Value(0.5),
					goal = firstScope:Value(0),
					color = firstScope:Value(4),
				},
				{
					type = firstScope:Value("Simple" :: any), -- me when luau types
					time = firstScope:Value(0.5),
					goal = firstScope:Value(1),
					color = firstScope:Value(4),
				},
			}),
			currentTween = firstScope:Value(1),
			currentPercentage = firstScope:Value(0),
			currentValue = firstScope:Value(0),
		})

		faders:set(currentFaders)
		updateCurrentConfiguration()
		unpause()
	end

	-- player
	local connection: RBXScriptConnection? = nil
	scope:Observer(playing):onChange(function()
		local isPlaying = scope.peek(playing)
		local currentFaders = scope.peek(faders)
		if isPlaying == true then
			log.debug("Playing")
			for _, data in currentFaders do
				if data.previousGoal == nil then
					data.previousGoal = 1
					data.currentValue:set(1)
				end
			end
			connection = RunService.Heartbeat:Connect(function(deltaTime: number)
				for _, data in currentFaders do
					local currentTweens = scope.peek(data.data)
					local tweenId = scope.peek(data.currentTween)
					local currentPercentage = scope.peek(data.currentPercentage)
					if currentPercentage >= 1 then
						if currentTweens[tweenId] ~= nil and scope.peek(currentTweens[tweenId].type) ~= "Wait" then
							data.previousGoal = scope.peek(currentTweens[tweenId].goal)
						end
						tweenId += 1
						currentPercentage = 0
					end
					if tweenId > #currentTweens then
						if currentTweens[tweenId] ~= nil and scope.peek(currentTweens[tweenId].type) ~= "Wait" then
							data.previousGoal = scope.peek(currentTweens[tweenId].goal)
						end
						tweenId = 1
						currentPercentage = 0
					end
					data.currentTween:set(tweenId) -- Fusion wont push this change if its the same value
					local currentTween = currentTweens[tweenId]
					currentPercentage += deltaTime / scope.peek(currentTween.time)
					data.currentPercentage:set(currentPercentage)
					if scope.peek(currentTween.type) ~= "Wait" then
						local previousGoal = data.previousGoal or 1
						local goal: number = scope.peek(currentTweens[tweenId].goal) or 0
						-- log.debug(tweenId, scope.peek(currentTween.time), goal, previousGoal)

						data.currentValue:set(
							(goal - previousGoal)
									* TweenService:GetValue(
										currentPercentage,
										scope.peek(currentTween.easingStyle) or Enum.EasingStyle.Linear,
										scope.peek(currentTween.easingDirection) or Enum.EasingDirection.InOut
									)
								+ previousGoal
						)
						-- else
						-- log.debug(tweenId, scope.peek(currentTween.time))
					end
				end
			end)
		else
			log.debug("Stopping")
			if connection ~= nil then
				connection:Disconnect()
				connection = nil
			end

			-- Reset the faders to ensure they stay in sync
			for _, data in currentFaders do
				data.currentTween:set(1)
				data.currentPercentage:set(0)
				data.currentValue:set(1)
				data.previousGoal = 1
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
		if currentPage ~= "Faders" then
			playing:set(false)
		end
	end)

	local playHovered = scope:Value(false)
	local size = scope:Value(Vector2.one)
	local sectionsTotalSpace = scope:Value(Vector2.one)
	return scope:base {
		Name = "Faders",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Spring(
			scope:Computed(function(use)
				local currentPage = use(props.CurrentPage)
				if currentPage == "Faders" then
					return UDim2.fromScale(0.5, 0.0462962963)
				elseif currentPage == "Rotators" then
					return UDim2.fromScale(-1, 0.0462962963)
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

							scope:ForPairs(faders, function(_, scope: typeof(scope), key: number, fader)
								return key,
									scope:faderComponent {
										key = key,
										fader = fader,
										size = size,
										temporarlyPause = temporarlyPause,
										faders = faders,
										updateCurrentConfiguration = updateCurrentConfiguration,
										holdingShift = holdingShift,
										playing = playing,
										colors = colors,
										addFader = addFader,
										firstScope = firstScope,
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
							return #use(faders) == 0
						end),

						[Fusion.OnEvent "Activated"] = function()
							addFader()
						end,
					},
				},
			},
		},
	}
end
