--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local types = require("../../../types")
local popup = require("../../popup")
local Editor = require("../../../lib/ConfigurationEditor/FunctionsEditor/FadersEditor")
local FunctionsEditor = require("../../../lib/ConfigurationEditor/FunctionsEditor")
local ConfigurationEditor = require("../../../lib/ConfigurationEditor")
local ChassisHandler = require("../../../lib/ChassisHandler")
local assets = require("../../../assets")
local log = require("../../../log")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local faderComponent = require("@self/fader")
local components = {
	faderComponent = faderComponent,
}

type props = {
	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
}

type FaderSection = Editor.FaderSectionState & {
	currentTween: Fusion.Value<number>,
	currentPercentage: Fusion.Value<number>,
	currentValue: Fusion.Value<number>,
	previousGoal: number,
}

--[[
	Faders
	Creates the faders screen for the main app
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local scope = baseScope:innerScope(components)
	local currentTheme = RedonUI.theme.theme:now()

	local colors = scope:Computed(function(use)
		local configuration = use(ConfigurationEditor.current)
		local result: { ChassisHandler.color } = {}
		if configuration == nil then
			return result
		end
		for _, color in use(configuration.lightSettings.colors) do
			table.insert(result, {
				name = use(color.name),
				partColor = use(color.partColor),
				lightColor = use(color.lightColor),
				lightoColor = use(color.lightoColor),
			})
		end
		return result
	end)
	local playing = scope:Value(false)
	local function temporarlyPause()
		local wasPlaying = scope.peek(playing)
		playing:set(false)
		return function()
			playing:set(wasPlaying)
		end
	end
	local holdingShift = scope:Value(false) -- This is used to skip certain popups
	local pattern = scope:Computed(function(use): FunctionsEditor.PatternState?
		local selected = use(props.CurrentPattern)
		local configuration = use(ConfigurationEditor.current)
		if selected == nil or configuration == nil then
			return nil
		end
		local func = use(configuration.functions)[selected.functionId]
		if func == nil then
			return nil
		end
		return use(func.patterns)[selected.patternId]
	end)
	local source = scope:Computed(function(use)
		local current = use(pattern)
		return if current == nil then {} else use(current.faders)
	end)
	local faders = scope:ForPairs(source, function(_, previewScope: types.Scope, index: number, section)
		return index,
			{
				lightName = section.lightName,
				data = section.data,
				currentTween = previewScope:Value(1),
				currentPercentage = previewScope:Value(0),
				currentValue = previewScope:Value(1),
				previousGoal = 1,
			} :: FaderSection
	end)
	local function onEdited()
		playing:set(false)
	end
	scope:Observer(pattern):onChange(function()
		playing:set(false)
	end)

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
						local selected = scope.peek(props.CurrentPattern)
						if selected == nil then
							return
						end
						for index = #scope.peek(faders), 1, -1 do
							ConfigurationEditor.removeFaderSection(selected.functionId, selected.patternId, index)
						end
						onEdited()
					end,
				},
			},
		})
	end

	local function addFader(atPoint: number?)
		local selected = scope.peek(props.CurrentPattern)
		if selected == nil or scope.peek(pattern) == nil then
			return
		end
		local unpause = temporarlyPause()
		local index = atPoint or #scope.peek(faders) + 1
		ConfigurationEditor.addFaderSection(selected.functionId, selected.patternId, {
			lightName = `Fader {index}`,
			data = {
				{ type = "Simple", time = 0.5, goal = 0, color = 4 },
				{ type = "Simple", time = 0.5, goal = 1, color = 4 },
			},
		}, index)
		onEdited()
		unpause()
	end

	-- player
	local connection: RBXScriptConnection? = nil
	local function stopPlayback()
		if connection ~= nil then
			connection:Disconnect()
			connection = nil
		end
	end
	table.insert(scope, stopPlayback)

	scope:Observer(source):onChange(function()
		playing:set(false)
	end)

	scope:Observer(playing):onChange(function()
		stopPlayback()
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
					if #currentTweens == 0 then
						continue
					end
					local tweenId = scope.peek(data.currentTween)
					local currentPercentage = scope.peek(data.currentPercentage)
					if currentPercentage >= 1 then
						if currentTweens[tweenId] ~= nil and scope.peek(currentTweens[tweenId].type) ~= "Wait" then
							data.previousGoal = scope.peek(
								(currentTweens[tweenId] :: Editor.SimpleFaderState | Editor.AdvancedFaderState).goal
							)
						end
						tweenId += 1
						currentPercentage = 0
					end
					if tweenId > #currentTweens then
						if currentTweens[tweenId] ~= nil and scope.peek(currentTweens[tweenId].type) ~= "Wait" then
							data.previousGoal = scope.peek(
								(currentTweens[tweenId] :: Editor.SimpleFaderState | Editor.AdvancedFaderState).goal
							)
						end
						tweenId = 1
						currentPercentage = 0
					end
					data.currentTween:set(tweenId) -- Fusion wont push this change if its the same value
					local currentTween = currentTweens[tweenId]
					local duration = scope.peek(currentTween.time)
					currentPercentage = if duration <= 0
						then 1
						else math.min(1, currentPercentage + deltaTime / duration)
					data.currentPercentage:set(currentPercentage)
					if scope.peek(currentTween.type) ~= "Wait" then
						local previousGoal = data.previousGoal or 1
						local goal: number = scope.peek(
							(currentTweens[tweenId] :: Editor.SimpleFaderState | Editor.AdvancedFaderState).goal
						) or 0
						-- log.debug(tweenId, scope.peek(currentTween.time), goal, previousGoal)

						data.currentValue:set(
							(goal - previousGoal)
									* TweenService:GetValue(
										currentPercentage,
										if scope.peek(currentTween.type) == "Advanced"
											then scope.peek((currentTween :: Editor.AdvancedFaderState).easingStyle)
											else Enum.EasingStyle.Linear,
										if scope.peek(currentTween.type) == "Advanced"
											then scope.peek((currentTween :: Editor.AdvancedFaderState).easingDirection)
											else Enum.EasingDirection.InOut
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
			stopPlayback()

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
										onEdited = onEdited,
										holdingShift = holdingShift,
										playing = playing,
										colors = colors,
										addFader = addFader,
										CurrentPattern = props.CurrentPattern,
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
