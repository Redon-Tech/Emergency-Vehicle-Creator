--#selene: allow(shadowing)
-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local popup = require(root.Plugin.Components.popup)
local chassisHandler = require(root.Plugin.chassisHandler)
local assets = require(root.Plugin.assets)
local log = require(root.Plugin.log)
local settings = require(root.Plugin.settings)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
}

type faderSectionState = {
	lightName: Fusion.Value<string>,
	currentPercentage: Fusion.Value<number>,
	currentTween: Fusion.Value<number>,
	currentValue: Fusion.Value<number>,
	previousGoal: number?,
	data: Fusion.Value<
		{
			{
				type: Fusion.Value<"Simple" | "Advanced" | "Wait">,
				time: Fusion.Value<number>,

				-- Non-Wait Specific
				goal: Fusion.Value<number>?,
				color: Fusion.Value<types.elsColor>?,

				-- Advanced Specific
				easingStyle: Fusion.Value<Enum.EasingStyle>?,
				easingDirection: Fusion.Value<Enum.EasingDirection>?,
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
	Faders
	Creates the faders screen for the main app
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

	local currentConfiguration: chassisHandler.chassisConfiguration? = nil
	local colors: Fusion.Value<{ chassisHandler.color }> = scope:Value({})
	local playing = scope:Value(false)
	local holdingShift = false -- This is used to skip certain popups
	local faders: Fusion.Value<{ faderSectionState }> = scope:Value({})

	local function updateCurrentConfiguration()
		local currentPattern = scope.peek(props.CurrentPattern)
		if currentConfiguration ~= nil and currentPattern ~= nil then
			local assembledFaders = {}
			for faderId, fader in scope.peek(faders) do
				local assembledTweens = {}
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

			if currentPattern.pattern.faders == assembledFaders then
				return
			end

			currentPattern.pattern.faders = assembledFaders
			currentConfiguration.functions[currentPattern.functionId].patterns[currentPattern.patternId] =
				currentPattern.pattern
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
		if currentPattern ~= nil and typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				colors:set(currentConfiguration.lightSettings.colors)
			end

			local newFaders = {}
			for faderId, fader in currentPattern.pattern.faders do
				local newFader = {
					lightName = scope:Value(fader.lightName),
					currentPercentage = scope:Value(0),
					currentTween = scope:Value(1),
					currentValue = scope:Value(0),
					previousGoal = 1,
					data = scope:Value({}),
				}
				local newData = {}
				for tweenId, tween in fader.data do
					table.insert(newData, tweenId, {
						type = scope:Value(tween.type),
						time = scope:Value(tween.time),
						goal = if tween.goal then scope:Value(tween.goal) else nil,
						color = if tween.color then scope:Value(tween.color) else nil,
						easingStyle = if tween.easingStyle then scope:Value(tween.easingStyle) else nil,
						easingDirection = if tween.easingDirection then scope:Value(tween.easingDirection) else nil,
					})
				end
				newFader.data:set(newData)
				table.insert(newFaders, faderId, newFader)
			end
			faders:set(newFaders)

			updateCurrentConfiguration()
		end
	end)

	local function addFader(atPoint: number?)
		local currentFaders = scope.peek(faders)
		if atPoint == nil then
			atPoint = #currentFaders + 1
		end
		table.insert(currentFaders, atPoint :: number, {
			lightName = scope:Value("Fader " .. atPoint :: number),
			data = scope:Value({
				{
					type = scope:Value("Simple" :: any), -- me when luau types
					time = scope:Value(0.5),
					goal = scope:Value(0),
					color = scope:Value(4),
				},
				{
					type = scope:Value("Simple" :: any), -- me when luau types
					time = scope:Value(0.5),
					goal = scope:Value(1),
					color = scope:Value(4),
				},
			}),
			currentTween = scope:Value(1),
			currentPercentage = scope:Value(0),
			currentValue = scope:Value(0),
		})

		faders:set(currentFaders)
		updateCurrentConfiguration()
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
				ClassName = "ScrollingFrame",
				Name = "Header",
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 0.0582524272),
				BackgroundColor3 = currentTheme.colors.mantle,
				CanvasSize = UDim2.new(),
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = currentTheme.colors.text,
				TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				ClipsDescendants = false,

				[Fusion.Children] = Fusion.Child {
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

					scope:ForPairs(faders, function(_, scope: typeof(scope), key: number, value)
						local dataSize = scope:Value(Vector2.one)
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
														playing:set(false)
														local currentFaders = scope.peek(faders)
														table.remove(currentFaders, key)
														faders:set(currentFaders)
														updateCurrentConfiguration()
													end

													if holdingShift then
														remove()
														return
													end

													popup:addPopup(scope, {
														title = "Remove Fader",
														description = `Are you sure you want to delete fader <b>{key}</b>?\n<b>All data will be lost.</b>`,
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
													return if use(playing) == true then 1 else 0
												end),
												ZIndex = 2,
												[Fusion.Children] = Fusion.Child {
													scope:textBox {
														Size = UDim2.fromScale(1, 1),
														BackgroundTransparency = 1,
														Text = value.lightName,
														[Fusion.Out "Text"] = value.lightName,
														Visible = scope:Computed(function(use)
															return use(playing) == false
														end),
													},

													scope:Computed(function(use, scope: typeof(scope))
														local knownColor = scope:Value(Color3.new(1, 1, 1))
														local color = scope:Computed(function(use)
															if use(playing) == false then
																return Color3.new(1, 1, 1)
															end

															local currentTweens = use(value.data)
															local currentTween = currentTweens[use(value.currentTween)]
															if currentTween == nil then
																log.warn(
																	"Somehow the current tween is nil",
																	currentTweens,
																	scope.peek(value.currentTween)
																)
																return Color3.new(1, 1, 1)
															end
															local colorId = use(currentTween.color)
															if colorId == nil then
																return scope.peek(knownColor)
															end
															local colorData = scope.peek(colors)[colorId]
															local finalColor = if colorData == nil
																then Color3.new(1, 1, 1)
																else if bloomColors[colorData.name] ~= nil
																	then bloomColors[colorData.name]
																	else colorData.lightoColor
															knownColor:set(finalColor)
															return finalColor
														end)
														local visible = scope:Computed(function(use)
															return use(playing) == true
														end)

														if use(settings.values.fakeBloom) then
															return {
																scope:base {
																	Size = UDim2.fromScale(1, 1),
																	BackgroundColor3 = Color3.new(1, 1, 1),
																	BackgroundTransparency = value.currentValue,
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
																	ImageTransparency = value.currentValue,
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
																		return -0.2 * (1 - use(value.currentValue)) + 1
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
																		return -0.5 * (1 - use(value.currentValue)) + 1
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
																BackgroundTransparency = value.currentValue,
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
													playing:set(false)
													addFader(key + 1)
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

											scope:ForPairs(
												value.data,
												function(_, scope: typeof(scope), key: number, tween)
													local controlSize = scope:Computed(function(use)
														return UDim2.new(1, 0, 0, 0.0628930818 * use(dataSize).Y)
													end)
													local cornerRadius = scope:Computed(function(use)
														return UDim.new(0, 0.0125786164 * use(dataSize).Y)
													end)
													local baseDropdown = scope:dropdown {
														Size = controlSize,
														BackgroundColor3 = currentTheme.colors.crust,
														CornerRadius = cornerRadius,
														Border = 1,
														Text = tween.type :: any,
														TextXAlignment = Enum.TextXAlignment.Left,
														LayoutOrder = 1,
														DropdownHeight = 150,
														Options = {
															"Simple",
															"Advanced",
															"Wait",
														},
														OnOptionSelected = function(_, newType)
															if newType == "Wait" then
																tween.goal = nil
																tween.color = nil
																tween.easingStyle = nil
																tween.easingDirection = nil
															elseif newType == "Simple" then
																tween.goal = if tween.goal ~= nil
																	then tween.goal
																	else scope:Value(0)
																tween.color = if tween.color ~= nil
																	then tween.color
																	else scope:Value(4)
																tween.easingStyle = nil
																tween.easingDirection = nil
															elseif newType == "Advanced" then
																tween.goal = if tween.goal ~= nil
																	then tween.goal
																	else scope:Value(0)
																tween.color = if tween.color ~= nil
																	then tween.color
																	else scope:Value(4)
																tween.easingStyle = if tween.easingStyle ~= nil
																	then tween.easingStyle
																	else scope:Value(Enum.EasingStyle.Linear)
																tween.easingDirection = if tween.easingDirection
																		~= nil
																	then tween.easingDirection
																	else scope:Value(Enum.EasingDirection.InOut)
															end
															tween.type:set(newType :: "Simple" | "Advanced" | "Wait")
															updateCurrentConfiguration()
														end,
													}
													local baseDropdownFrame = baseDropdown[2] :: Frame
													baseDropdownFrame.LayoutOrder = 2
													local currentTime = scope:Value(tostring(scope.peek(tween.time)))
													local baseControls: { Fusion.Child } = {
														baseDropdown,
														scope:textBox {
															Size = controlSize,
															BackgroundColor3 = currentTheme.colors.crust,
															CornerRadius = UDim.new(0.2, 0),
															Border = 1,
															Text = currentTime,
															[Fusion.Out "Text"] = currentTime :: unknown,
															PlaceholderText = scope:Computed(function(use)
																return if use(tween.type) == "Wait"
																	then "Wait Time"
																	else "Time"
															end),
															PlaceholderColor3 = currentTheme.colors.subtext0,
															LayoutOrder = 7,
															[Fusion.OnEvent "FocusLost"] = function()
																tween.time:set(tonumber(scope.peek(currentTime)) or 0)
																currentTime:set(tostring(scope.peek(currentTime)))
																updateCurrentConfiguration()
															end,
														},
													}

													local controls = scope:Computed(function(use, scope: typeof(scope))
														local controls: { Fusion.Child } = baseControls
														local currentType = use(tween.type)

														if currentType == "Simple" or currentType == "Advanced" then
															if tween.color ~= nil then
																local colorDropdown = scope:dropdown {
																	Size = controlSize,
																	BackgroundColor3 = currentTheme.colors.crust,
																	CornerRadius = cornerRadius,
																	Border = 1,
																	Text = scope:Computed(function(use)
																		return use(colors)[use(tween.color)].name
																	end),
																	TextXAlignment = Enum.TextXAlignment.Left,
																	LayoutOrder = 3,
																	DropdownHeight = 150,
																	Options = scope:Computed(function(use)
																		local newColors: { string } = {}
																		for colorId, color in pairs(use(colors)) do
																			table.insert(newColors, colorId, color.name)
																		end
																		return newColors
																	end),
																	OptionOverrides = scope:Computed(function(use)
																		local textColors = {}
																		for colorId, color in pairs(use(colors)) do
																			textColors[colorId] = {
																				TextColor3 = getColorByName(
																					color.name,
																					currentTheme.colors.text
																				),
																			}
																		end
																		return textColors :: any
																	end),
																	TextColor3 = scope:Computed(function(use)
																		return getColorByName(
																			use(colors)[use(tween.color)].name,
																			currentTheme.colors.text
																		)
																	end),
																	OnOptionSelected = function(colorId)
																		tween.color:set(colorId)
																		updateCurrentConfiguration()
																	end,
																}
																local colorDropdownFrame = colorDropdown[2] :: Frame
																colorDropdownFrame.LayoutOrder = 4
																table.insert(controls, colorDropdown)
															end
															if tween.goal ~= nil then
																local currentText =
																	scope:Value(tostring(scope.peek(tween.goal)))
																table.insert(
																	controls,
																	scope:textBox {
																		Size = controlSize,
																		BackgroundColor3 = currentTheme.colors.crust,
																		CornerRadius = UDim.new(0.2, 0),
																		Border = 1,
																		Text = currentText,
																		[Fusion.Out "Text"] = currentText :: unknown,
																		PlaceholderText = "Goal",
																		PlaceholderColor3 = currentTheme.colors.subtext0,
																		LayoutOrder = 6,
																		[Fusion.OnEvent "FocusLost"] = function()
																			tween.goal:set(
																				tonumber(scope.peek(currentText)) or 0
																			)
																			currentText:set(
																				tostring(scope.peek(tween.goal))
																			)
																			updateCurrentConfiguration()
																		end,
																	}
																)
															end
															if currentType == "Advanced" then
																if tween.easingStyle ~= nil then
																	local options = {}
																	for _, easingStyle: Enum.EasingStyle in
																		pairs(Enum.EasingStyle:GetEnumItems())
																	do
																		table.insert(options, easingStyle.Name)
																	end
																	local easingStyleDropdown = scope:dropdown {
																		Size = controlSize,
																		BackgroundColor3 = currentTheme.colors.crust,
																		CornerRadius = cornerRadius,
																		Border = 1,
																		Text = scope:Computed(function(use)
																			return use(tween.easingStyle).Name
																		end),
																		TextXAlignment = Enum.TextXAlignment.Left,
																		LayoutOrder = 8,
																		DropdownHeight = 150,
																		Options = options,
																		OnOptionSelected = function(_, newValue)
																			local success, newEasingStyle = pcall(
																				function()
																					return (Enum.EasingStyle :: any)[newValue]
																				end
																			)
																			if not success then
																				return
																			end
																			tween.easingStyle:set(
																				newEasingStyle :: Enum.EasingStyle
																			)
																			updateCurrentConfiguration()
																		end,
																	}
																	local easingStyleDropdownFrame =
																		easingStyleDropdown[2] :: Frame
																	easingStyleDropdownFrame.LayoutOrder = 9
																	table.insert(controls, easingStyleDropdown)
																end
																if tween.easingDirection ~= nil then
																	local options = {}
																	for _, easingStyle: Enum.EasingDirection in
																		pairs(Enum.EasingDirection:GetEnumItems())
																	do
																		table.insert(options, easingStyle.Name)
																	end
																	local easingStyleDropdown = scope:dropdown {
																		Size = controlSize,
																		BackgroundColor3 = currentTheme.colors.crust,
																		CornerRadius = cornerRadius,
																		Border = 1,
																		Text = scope:Computed(function(use)
																			return use(tween.easingDirection).Name
																		end),
																		TextXAlignment = Enum.TextXAlignment.Left,
																		LayoutOrder = 10,
																		DropdownHeight = 150,
																		Options = options,
																		OnOptionSelected = function(_, newValue)
																			local success, newEasingDirection = pcall(
																				function()
																					return (Enum.EasingDirection :: any)[newValue]
																				end
																			)
																			if not success then
																				return
																			end
																			tween.easingDirection:set(
																				newEasingDirection :: Enum.EasingDirection
																			)
																			updateCurrentConfiguration()
																		end,
																	}
																	local easingStyleDropdownFrame =
																		easingStyleDropdown[2] :: Frame
																	easingStyleDropdownFrame.LayoutOrder = 11
																	table.insert(controls, easingStyleDropdown)
																end
															end
														end

														return controls
													end)

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
																	Position = UDim2.fromScale(-0.0666666667, 0),
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
																			Offset = scope:Computed(function(use)
																				local percent = 0
																				if use(playing) == true then
																					if
																						use(value.currentTween)
																						== key
																					then
																						percent =
																							use(value.currentPercentage)
																					elseif
																						use(value.currentTween)
																						> key
																					then
																						percent = 1
																					end
																				end
																				return Vector2.new(0, percent)
																			end),
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
																			Padding = scope:Computed(function(use)
																				return UDim.new(
																					0,
																					0.0125786164 * use(dataSize).Y
																				)
																			end),
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
															if #scope.peek(value.data) == 1 then
																log.warn("Cannot remove the last tween")
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
															local currentData = scope.peek(value.data)
															table.insert(currentData, {
																type = scope:Value("Wait" :: any), -- the day I dont need this I will be so glad
																time = scope:Value(0.5),
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
					return #use(faders) == 0
				end),

				[Fusion.OnEvent "Activated"] = function()
					addFader()
				end,
			},
		},
	}
end
