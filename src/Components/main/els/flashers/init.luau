--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent
local CollectionService = game:GetService("CollectionService")

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local popup = require(root.Plugin.Components.popup)
local chassisHandler = require(root.Plugin.chassisHandler)
local assets = require(root.Plugin.assets)
local log = require(root.Plugin.log)
local settings = require(root.Plugin.settings)
local utils = require(root.Plugin.utils)

local sectionsComponent = require(script.sections)
local components = {
	sectionsComponent = sectionsComponent,
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
	Flashers
	Creates the flashers screen for the main app
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local PREVIEW_TEMPLATE_TAG = "EVCPreviewLightTemplate"
	local currentTheme = RedonUI.theme.theme:now()
	local scope = baseScope:innerScope(components)
	local firstScope = scope:innerScope()

	local currentConfiguration: chassisHandler.chassisConfiguration? = nil
	local colors: Fusion.Value<{ chassisHandler.color }> = scope:Value(chassisHandler.defaults.colors)
	local currentColor = scope:Value(1)
	local drawing = scope:Value(0) -- -1 = remove, 0 = none, 1 = add
	local playing = scope:Value(false)
	local function temporarlyPause()
		local wasPlaying = scope.peek(playing)
		playing:set(false)
		return function()
			playing:set(wasPlaying)
		end
	end
	local locked = scope:Value(false)
	local holdingShift = scope:Value(false) -- This is used to skip certain popups
	local sections: Fusion.Value<{ types.flasherSectionState }> = scope:Value({})
	local previewPartsByLightName = {} :: { [string]: { BasePart } }
	local previewPartStates = {} :: { [BasePart]: any }

	local function clearTemplatePreviewClones()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) ~= "Instance" then
			return
		end

		for _, tagged in CollectionService:GetTagged(PREVIEW_TEMPLATE_TAG) do
			if tagged:IsDescendantOf(currentVehicle) then
				tagged:Destroy()
			end
		end
	end

	local function applyTemplatePreviewClones()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) ~= "Instance" then
			return
		end

		local lightTemplate = currentVehicle:FindFirstChild("lightTemplate", true)
		if lightTemplate == nil then
			return
		end

		local activeLightNames = {}
		for _, section in scope.peek(sections) do
			for _, column in scope.peek(section.columns) do
				activeLightNames[scope.peek(column.lightName)] = true
			end
		end

		if next(activeLightNames) == nil then
			return
		end

		for _, lightPart in currentVehicle:GetDescendants() do
			if
				lightPart:IsA("BasePart")
				and lightPart.Parent ~= nil
				and lightPart.Parent.Name == "_LIGHTS"
				and activeLightNames[lightPart.Name] == true
			then
				for _, child in lightTemplate:GetChildren() do
					local clone = child:Clone()
					CollectionService:AddTag(clone, PREVIEW_TEMPLATE_TAG)
					clone.Parent = lightPart
				end
			end
		end
	end

	local function clearPreview()
		for part, state in previewPartStates do
			if part.Parent == nil then
				continue
			end

			part.Transparency = state.transparency
			part.Color = state.color

			for _, lightData in state.lights do
				if lightData.light.Parent ~= nil then
					lightData.light.Enabled = lightData.enabled
					lightData.light.Color = lightData.color
				end
			end

			for _, lightoData in state.colorableLightos do
				if lightoData.lighto.Parent ~= nil then
					lightoData.lighto.Enabled = lightoData.enabled
				end

				for _, imageData in lightoData.images do
					if imageData.image.Parent ~= nil then
						local image = imageData.image :: any
						image.ImageColor3 = imageData.imageColor3
						image.ImageTransparency = imageData.imageTransparency
					end
				end
			end

			for _, nonColorableLightos in state.nonColorableLightos do
				for _, lightoData in nonColorableLightos do
					if lightoData.lighto.Parent ~= nil then
						lightoData.lighto.Enabled = lightoData.enabled
					end

					for _, imageData in lightoData.images do
						if imageData.image.Parent ~= nil then
							local image = imageData.image :: any
							image.ImageColor3 = imageData.imageColor3
							image.ImageTransparency = imageData.imageTransparency
						end
					end
				end
			end

			for _, particleEmitterData in state.particleEmitters do
				if particleEmitterData.particleEmitter.Parent ~= nil then
					particleEmitterData.particleEmitter.Enabled = particleEmitterData.enabled
				end
			end
		end

		clearTemplatePreviewClones()
	end

	local function rePreviewParts()
		clearPreview()
		previewPartsByLightName = {}
		previewPartStates = {}

		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) ~= "Instance" then
			return
		end

		if currentConfiguration == nil then
			return
		end

    if scope.peek(settings.values.previewVehicle) == false then
      return
    end

		applyTemplatePreviewClones()

		local colorNames = {}
		for _, colorData in currentConfiguration.lightSettings.colors do
			table.insert(colorNames, colorData.name)
		end

		for _, lightPart in currentVehicle:GetDescendants() do
			if lightPart:IsA("BasePart") and lightPart.Parent ~= nil and lightPart.Parent.Name == "_LIGHTS" then
				if previewPartsByLightName[lightPart.Name] == nil then
					previewPartsByLightName[lightPart.Name] = {}
				end
				table.insert(previewPartsByLightName[lightPart.Name], lightPart)

				if previewPartStates[lightPart] == nil then
					local newState = {
						transparency = lightPart.Transparency,
						color = lightPart.Color,
						lights = {},
						colorableLightos = {},
						nonColorableLightos = {},
						particleEmitters = {},
					}

					for _, descendant in lightPart:GetDescendants() do
						if descendant:IsA("Light") then
							table.insert(newState.lights, {
								light = descendant,
								enabled = descendant.Enabled,
								color = descendant.Color,
							})
						elseif descendant:IsA("ParticleEmitter") then
							table.insert(newState.particleEmitters, {
								particleEmitter = descendant,
								enabled = descendant.Enabled,
							})
						elseif descendant:IsA("LayerCollector") then
							local images = {}
							for _, image in descendant:GetDescendants() do
								if image:IsA("ImageLabel") or image:IsA("ImageButton") then
									table.insert(images, {
										image = image,
										imageColor3 = image.ImageColor3,
										imageTransparency = image.ImageTransparency,
									})
								end
							end

							if table.find(colorNames, descendant.Name) == nil then
								table.insert(newState.colorableLightos, {
									lighto = descendant,
									enabled = descendant.Enabled,
									images = images,
								})
							else
								if newState.nonColorableLightos[descendant.Name] == nil then
									newState.nonColorableLightos[descendant.Name] = {}
								end
								table.insert(newState.nonColorableLightos[descendant.Name], {
									lighto = descendant,
									enabled = descendant.Enabled,
									images = images,
								})
							end
						end
					end

					previewPartStates[lightPart] = newState
				end
			end
		end
	end

	local function applyPreview()
		if currentConfiguration == nil then
			return
		end

    if scope.peek(settings.values.previewVehicle) == false then
      return
    end

		local currentSections = scope.peek(sections)
		local activeLights = {} :: { [string]: types.elsColor }
		for _, section in currentSections do
			local currentRow = scope.peek(section.currentRow)
			for _, column in scope.peek(section.columns) do
				local rows = scope.peek(column.rows)
				activeLights[scope.peek(column.lightName)] = rows[currentRow] or 0
			end
		end

		local lightSettings = currentConfiguration.lightSettings.configuration
		local availableColors = scope.peek(colors)
		for lightName, parts in previewPartsByLightName do
			local colorId = activeLights[lightName] or 0
			local colorData = availableColors[colorId]
			local enabled = colorId ~= 0 and colorData ~= nil

			for _, part in parts do
				if part.Parent == nil then
					continue
				end

				if lightSettings.shouldChangeNeons == true then
					part.Transparency = if enabled then lightSettings.partTransparency else 1
					if enabled then
						part.Color = colorData.partColor
					end
				end

				local partState = previewPartStates[part]
				if partState == nil then
					continue
				end

				if lightSettings.shouldChangeLights == true then
					for _, lightData in partState.lights do
						if lightData.light.Parent ~= nil then
							lightData.light.Enabled = enabled
							if enabled then
								lightData.light.Color = colorData.lightColor
							end
						end
					end
				end

				if lightSettings.shouldChangeLightos == true then
					for _, lightoData in partState.colorableLightos do
						if lightoData.lighto.Parent ~= nil then
							lightoData.lighto.Enabled = enabled
						end

						if enabled then
							for _, imageData in lightoData.images do
								if imageData.image.Parent ~= nil then
									imageData.image.ImageColor3 = colorData.lightoColor
								end
							end
						end
					end

					for colorName, nonColorableLightos in partState.nonColorableLightos do
						local shouldEnable = enabled and colorName == colorData.name
						for _, lightoData in nonColorableLightos do
							if lightoData.lighto.Parent ~= nil then
								lightoData.lighto.Enabled = shouldEnable
							end
						end
					end
				end

				if lightSettings.shouldChangeParticleEmitters == true then
					for _, particleEmitterData in partState.particleEmitters do
						if particleEmitterData.particleEmitter.Parent ~= nil then
							particleEmitterData.particleEmitter.Enabled = enabled
						end
					end
				end
			end
		end
	end

	local function updateCurrentConfiguration()
		local currentPattern = scope.peek(props.CurrentPattern)
		if currentPattern ~= nil then
			local assembledSections = {}
			for i, section in scope.peek(sections) do
				local assembledSection: types.flasherSection = {
					waitTime = scope.peek(section.waitTime),
					rowCount = scope.peek(section.rowCount),
					columns = {},
				}
				for columnId, columnData in scope.peek(section.columns) do
					local assembledColumn = {} :: { lightName: string, rows: { types.elsColor } }
					assembledColumn.lightName = scope.peek(columnData.lightName)
					assembledColumn.rows = {}
					for _, color in scope.peek(columnData.rows) do
						table.insert(assembledColumn.rows, scope.peek(color))
					end
					assembledSection.columns[columnId] = assembledColumn
				end

				table.insert(assembledSections, i, assembledSection)
			end

			if utils.compareTables(currentPattern.pattern.flashers, assembledSections) == true then
				return
			end

			currentPattern.pattern.flashers = assembledSections
			props.UnsavedChanges:set(true)
		end
	end

	local function promptReset()
		popup:addPopup(scope, {
			title = "Reset Flashers",
			description = "Are you sure you want to reset all flashers?\n<b>All data will be lost.</b>",
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
						sections:set({})
						locked:set(false)
						drawing:set(0)
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

			local flashers = currentPattern.pattern.flashers
			local newSections = {} :: { types.flasherSectionState }
			for i, section in flashers do
				local newColumns = {}
				for columnId, columnData in section.columns do
					local rows = {}
					for _, color in columnData.rows do
						table.insert(rows, color)
					end
					newColumns[columnId] = {
						lightName = firstScope:Value(columnData.lightName),
						rows = firstScope:Value(rows),
					}
				end
				table.insert(newSections, i, {
					waitTime = firstScope:Value(section.waitTime),
					rowCount = firstScope:Value(section.rowCount),
					currentRow = firstScope:Value(1),
					columns = firstScope:Value(newColumns),
				})
			end
			log.debug(newSections)
			sections:set(newSections)
			rePreviewParts()
		end
	end)

	scope:Observer(props.CurrentVehicle):onChange(function()
		rePreviewParts()
		if scope.peek(playing) == true then
			applyPreview()
		end
	end)

	local function addSection(atPoint: number?)
		local unpause = temporarlyPause()
		local currentSections = scope.peek(sections)
		if atPoint == nil then
			atPoint = #currentSections + 1
		end
		table.insert(currentSections, atPoint :: number, {
			waitTime = firstScope:Value(0.05),
			rowCount = firstScope:Value(10),
			currentRow = firstScope:Value(1),
			columns = firstScope:Value({
				{
					lightName = firstScope:Value("Light 1"),
					rows = firstScope:Value({
						0,
						0,
						0,
						0,
						0,
						0,
						0,
						0,
						0,
						0,
					}),
				},
			}),
		})
		sections:set(currentSections)
		updateCurrentConfiguration()
		unpause()
	end

	-- player
	local threads: { { activeThread: thread, sections: { number } } } = {}
	scope:Observer(playing):onChange(function()
		local isPlaying = scope.peek(playing)
		local currentSections = scope.peek(sections)
		if isPlaying == true then
			log.debug("Playing")
			rePreviewParts()
			applyPreview()
			for sectionId, section in currentSections do
				local waitTime = scope.peek(section.waitTime)
				if threads[waitTime] == nil then
					threads[waitTime] = {
						activeThread = task.spawn(function()
							while task.wait(waitTime) do
								for _, sectionId in pairs(threads[waitTime].sections) do
									local section = currentSections[sectionId]
									local nextRow = scope.peek(section.currentRow) + 1
									if nextRow > scope.peek(section.rowCount) then
										nextRow = 1
									end
									section.currentRow:set(nextRow)
								end
								applyPreview()
							end
						end),
						sections = {},
					}
				end

				table.insert(threads[waitTime].sections, sectionId)
			end
		else
			log.debug("Stopping")
			for i, thread in threads do
				coroutine.close(thread.activeThread)
				threads[i] = nil
			end
			clearPreview()
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
		if currentPage ~= "Flashers" then
			playing:set(false)
			clearPreview()
		end
	end)

	table.insert(scope, function()
		clearPreview()
	end)

	local colorKeybinds = scope:Computed(function(use)
		local setting = use(settings.values.colorKeybinds)
		if setting == "1-6" then
			return {
				Enum.KeyCode.One,
				Enum.KeyCode.Two,
				Enum.KeyCode.Three,
				Enum.KeyCode.Four,
				Enum.KeyCode.Five,
				Enum.KeyCode.Six,
			}
		elseif setting == "NumPad 1-6" then
			return {
				Enum.KeyCode.KeypadOne,
				Enum.KeyCode.KeypadTwo,
				Enum.KeyCode.KeypadThree,
				Enum.KeyCode.KeypadFour,
				Enum.KeyCode.KeypadFive,
				Enum.KeyCode.KeypadSix,
			}
		else
			return {
				Enum.KeyCode.Q,
				Enum.KeyCode.W,
				Enum.KeyCode.E,
				Enum.KeyCode.R,
				Enum.KeyCode.T,
				Enum.KeyCode.Y,
			}
		end
	end)
	local playHovered = scope:Value(false)
	local lockedHovered = scope:Value(false)
	local size = scope:Value(Vector2.one)
	local sectionsTotalSpace = scope:Value(Vector2.one)
	local headerSize = scope:Value(Vector2.one)
	return scope:base {
		Name = "Flashers",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Spring(
			scope:Computed(function(use)
				local currentPage = use(props.CurrentPage)
				if currentPage == "Flashers" then
					return UDim2.fromScale(0.5, 0.0462962963)
				end
				return UDim2.fromScale(-1, 0.0462962963)
			end),
			20,
			0.75
		),
		Size = UDim2.fromScale(1, 0.9537037037),
		BackgroundTransparency = 1,

		[Fusion.OnEvent "InputBegan"] = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				drawing:set(1)
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				drawing:set(-1)
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.P then
					playing:set(not scope.peek(playing))
				elseif input.KeyCode == Enum.KeyCode.LeftShift then
					holdingShift:set(true)
				else
					local color = table.find(scope.peek(colorKeybinds), input.KeyCode)
					if color ~= nil then
						currentColor:set(color)
					end
				end
			end
		end :: unknown,

		[Fusion.OnEvent "InputEnded"] = function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
			then
				drawing:set(0)
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
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
								HorizontalAlignment = scope:Computed(function(use)
									return use(headerSize).X > use(size).X and Enum.HorizontalAlignment.Left
										or Enum.HorizontalAlignment.Center
								end),
								VerticalAlignment = Enum.VerticalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								[Fusion.Out "AbsoluteContentSize"] = headerSize :: unknown,
							},

							scope:ForPairs(
								colors,
								function(_, scope: typeof(scope), key: number, value: chassisHandler.color)
									local color = utils.getColorByName(value.name, value.lightoColor)
									return key,
										scope:textButton {
											Size = UDim2.fromScale(0.078125, 0.8333333333),
											Text = value.name,
											TextScaled = true,
											MaxTextSize = 35,
											CornerRadius = UDim.new(0.2, 0),
											Border = 2,
											Reactive = true,
											BackgroundColor3 = scope:Computed(function(use)
												return if use(currentColor) == key
													then color
													else currentTheme.colors.mantle
											end),
											TextColor3 = scope:Computed(function(use)
												return if use(currentColor) == key
													then currentTheme.colors.mantle
													else color
											end),
											LayoutOrder = key,

											[Fusion.OnEvent "Activated"] = function()
												currentColor:set(key)
											end,
										}
								end
							),

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
								LayoutOrder = 101,
								Image = scope:Computed(function(use)
									local hovering = use(lockedHovered)
									return if use(locked)
										then if hovering
											then assets.images.redonUI.lockClosedFilled
											else assets.images.redonUI.lockClosed
										else if hovering
											then assets.images.redonUI.lockOpenFilled
											else assets.images.redonUI.lockOpen
								end),
								BackgroundColor3 = currentTheme.colors.mantle,
								ImageColor3 = currentTheme.colors.text,
								MouseEnter = function()
									lockedHovered:set(true)
								end,
								MouseLeave = function()
									lockedHovered:set(false)
								end,
								[Fusion.OnEvent "Activated"] = function()
									locked:set(not scope.peek(locked))
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

							scope:sectionsComponent {
								colors = colors,
								currentColor = currentColor,
								playing = playing,
								drawing = drawing,
								size = size,
								temporarlyPause = temporarlyPause,
								locked = locked,
								holdingShift = holdingShift,
								sections = sections,
								updateCurrentConfiguration = updateCurrentConfiguration,
								addSection = addSection,
							},
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
							return #use(sections) == 0
						end),

						[Fusion.OnEvent "Activated"] = function()
							addSection()
						end,
					},
				},
			},
		},
	}
end
