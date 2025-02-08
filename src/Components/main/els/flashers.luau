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

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
}

type section = {
	waitTime: number,
	rowCount: number,
	nameTemplate: {
		pattern: string,
		originalPosition: number,
		originalNumber: number,
	}?,
	currentRow: Fusion.Value<number>,
}

local bloomColors = {
	Blue = Color3.fromRGB(17, 99, 207),
	Red = Color3.fromRGB(255, 61, 61),
	Yello = Color3.fromRGB(255, 230, 43),
	White = Color3.fromRGB(255, 255, 255),
	Green = Color3.fromRGB(94, 225, 110),
	Purple = Color3.fromRGB(246, 114, 255),
}

local SPRING_SPEED = 25
local SPRING_DAMPING = 1
--[[
	Flashers
	Creates the flashers screen for the main app
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
	local colors: Fusion.Value<{ chassisHandler.color }> = scope:Value(chassisHandler.defaults.colors)
	local currentColor = scope:Value(1)
	local drawing = 0 -- -1 = remove, 0 = none, 1 = add
	local playing = scope:Value(false)
	local locked = scope:Value(false)
	local lockedTo: { section: number, column: number }? = nil
	local holdingShift = false -- This is used to skip certain popups
	-- sections without the columns
	local sections: Fusion.Value<{ section }> = scope:Value({})
	-- array of sections with the columns
	local columns: { Fusion.Value<{ [number]: { currentName: Fusion.Value<string>?, lightName: Fusion.Value<string>, rows: Fusion.Value<{ types.elsColor }> } }> } =
		{}

	local function updateCurrentConfiguration()
		local currentPattern = scope.peek(props.CurrentPattern)
		if currentPattern ~= nil then
			local assembledSections = {}
			for i, section in scope.peek(sections) do
				local assembledSection: types.flasherSection = {
					waitTime = section.waitTime,
					rowCount = section.rowCount,
					columns = {},
				}
				local columns = scope.peek(columns[i])
				for columnId, columnData in columns do
					local assembledColumn = {} :: { lightName: string, rows: { types.elsColor } }
					assembledColumn.lightName = scope.peek(columnData.lightName)
					assembledColumn.rows = {}
					for _, color in scope.peek(columnData.rows) do
						table.insert(assembledColumn.rows, color)
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
						columns = {}
						locked:set(false)
						lockedTo = nil
						drawing = 0
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
			if typeof(currentVehicle) == "Instance" then
				currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
				if currentConfiguration ~= nil then
					colors:set(currentConfiguration.lightSettings.colors)
				else
					colors:set(chassisHandler.defaults.colors)
				end
			end

			local flashers = currentPattern.pattern.flashers
			local newSections = {}
			local newColumns = {}
			for i, section in flashers do
				local columns = {}
				for columnId, columnData in section.columns do
					local rows = {}
					for _, color in columnData.rows do
						table.insert(rows, color)
					end
					columns[columnId] = {
						lightName = scope:Value(columnData.lightName),
						-- color = scope:Value(currentTheme.colors.base),
						rows = scope:Value(rows),
					}
				end
				table.insert(newColumns, i, scope:Value(columns))
				table.insert(newSections, i, {
					waitTime = section.waitTime,
					rowCount = section.rowCount,
					currentRow = scope:Value(1),
				})
			end
			log.debug(newColumns)
			columns = newColumns
			log.debug(newSections)
			sections:set(newSections)
		end
	end)

	local function addSection(atPoint: number?)
		local currentSections = scope.peek(sections)
		if atPoint == nil then
			atPoint = #currentSections + 1
		end
		table.insert(currentSections, atPoint :: number, {
			waitTime = 0.05,
			rowCount = 10,
			currentRow = scope:Value(1),
		})
		table.insert(
			columns,
			atPoint :: number,
			scope:Value({
				{
					lightName = scope:Value("Light 1"),
					-- color = scope:Value(currentTheme.colors.base),
					rows = scope:Value({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
				},
			})
		)
		sections:set(currentSections)
		updateCurrentConfiguration()
	end

	-- player
	local threads: { { activeThread: thread, sections: { number } } } = {}
	scope:Observer(playing):onChange(function()
		local isPlaying = scope.peek(playing)
		local currentSections = scope.peek(sections)
		if isPlaying == true then
			log.debug("Playing")
			for sectionId, section in currentSections do
				if threads[section.waitTime] == nil then
					threads[section.waitTime] = {
						activeThread = task.spawn(function()
							while task.wait(section.waitTime) do
								for _, sectionId in pairs(threads[section.waitTime].sections) do
									local section = currentSections[sectionId]
									local nextRow = scope.peek(section.currentRow) + 1
									if nextRow > section.rowCount then
										nextRow = 1
									end
									section.currentRow:set(nextRow)
								end
							end
						end),
						sections = {},
					}
				end

				table.insert(threads[section.waitTime].sections, sectionId)
			end
		else
			log.debug("Stopping")
			for i, thread in threads do
				coroutine.close(thread.activeThread)
				threads[i] = nil
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
		if currentPage ~= "Flashers" then
			playing:set(false)
		end
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
				drawing = 1
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				drawing = -1
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.P then
					playing:set(not scope.peek(playing))
				elseif input.KeyCode == Enum.KeyCode.LeftShift then
					holdingShift = true
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
				drawing = 0
			elseif input.UserInputType == Enum.UserInputType.Keyboard then
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
									local color = getColorByName(value.name, value.lightoColor)
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

							scope:ForPairs(sections, function(_, scope: typeof(scope), key: number, value: section)
								log.debug("Creating section", key, value)
								local position = scope:Value(Vector2.one)
								local contentSize = scope:Value(Vector2.one)
								local canvasSize = scope:Value(Vector2.one)
								local canvasPosition = scope:Value(Vector2.zero)
								local currentlyHovering = scope:Value(1)
								local positionsScope = scope:innerScope()
								local columnPositions: Fusion.Value<{ Fusion.Value<Vector2> }> = scope:Value({
									[1] = positionsScope:Value(Vector2.one),
								})
								local hoverPosition = scope:Computed(function(use)
									return math.clamp(
										use(use(columnPositions)[use(currentlyHovering)]).X
											- use(position).X
											- 0.0133689840 * use(size).X,
										0,
										use(contentSize).X
									)
								end)
								local rowCount = scope:Value(value.rowCount)
								local waitTime = scope:Value(tostring(value.waitTime))

								scope:Observer(rowCount):onChange(function()
									if scope.peek(playing) == true then
										return
									end
									local currentRowCount = scope.peek(rowCount)
									if scope.peek(value.currentRow) > currentRowCount then
										value.currentRow:set(1)
									end
								end)

								local function propagateNameChange(
									columnData: {
										currentName: Fusion.Value<string>?,
										lightName: Fusion.Value<string>,
										rows: Fusion.Value<{ types.elsColor }>,
									},
									columnKey: number
								)
									if columnData.currentName == nil then
										return
									end
									local newName = scope.peek(columnData.lightName)
									local pattern = scope.peek(newName):gsub("%d+$", "")
									local originalNumber = tonumber(newName:match("%d+$"))
									if originalNumber == nil then
										return
									end
									local originalPattern = scope.peek(columnData.currentName):gsub("%d+$", "")

									if
										value.nameTemplate == nil
										or value.nameTemplate.originalPosition <= columnKey
										or value.nameTemplate.pattern == originalPattern
									then
										value.nameTemplate = {
											pattern = pattern,
											originalPosition = columnKey,
											originalNumber = originalNumber,
										}
									end

									for columnId, column in pairs(scope.peek(columns[key])) do
										if columnId < columnKey then
											continue
										end
										local name = scope.peek(column.lightName)
										if value.nameTemplate ~= nil then
											log.debug(
												value.nameTemplate.originalPosition,
												columnKey,
												columnId,
												originalPattern,
												columnData.currentName
											)
											if
												value.nameTemplate.originalPosition > columnKey
												and (
													columnId >= value.nameTemplate.originalPosition
													or not name:match(originalPattern)
												)
											then
												log.debug("Position or match not met")
												continue
											elseif not name:match(originalPattern) then
												log.debug("Not matching")
												continue
											end
										end
										log.debug("Setting name", pattern, originalNumber, columnId, columnKey)
										column.lightName:set(pattern .. originalNumber + columnId - columnKey)

										if column.currentName ~= nil then
											column.currentName:set(scope.peek(column.lightName))
										end
									end
									columnData.currentName:set(newName)
								end

								return key,
									scope:base {
										Name = key,
										BackgroundColor3 = currentTheme.colors.mantle,
										Size = UDim2.fromScale(0, 0.9259259259),
										CornerRadius = scope:Computed(function(use)
											return UDim.new(0, 0.0171428571 * use(size).Y) -- I shouldn't have to do this
										end),
										LayoutOrder = key,
										AutomaticSize = Enum.AutomaticSize.X,
										[Fusion.Out "AbsolutePosition"] = position :: unknown,

										[Fusion.Children] = Fusion.Child {
											scope:New("UIPadding") {
												PaddingTop = UDim.new(0.0285714286, 0),
												PaddingBottom = UDim.new(0.0285714286, 0),
												PaddingLeft = scope:Computed(function(use)
													return UDim.new(0, 0.0133689840 * use(size).X)
												end),
												PaddingRight = scope:Computed(function(use)
													return UDim.new(0, 0.0133689840 * use(size).X)
												end),
											},

											scope:base {
												Name = "Controls",
												Size = UDim2.fromScale(1, 0.0571428571),
												AutomaticSize = Enum.AutomaticSize.X,
												BackgroundTransparency = 1,

												[Fusion.Children] = {
													scope:New("UIListLayout") {
														Padding = scope:Computed(function(use)
															return UDim.new(0, 0.0080213904 * use(size).X)
														end),
														FillDirection = Enum.FillDirection.Horizontal,
														HorizontalAlignment = Enum.HorizontalAlignment.Center,
														SortOrder = Enum.SortOrder.LayoutOrder,
													},

													scope:iconButton {
														Size = scope:Computed(function(use)
															return UDim2.new(0, 0.0267379679 * use(size).X, 1, 0)
														end),
														LayoutOrder = 1,
														CornerRadius = UDim.new(0.2, 0),
														Border = 2,
														Reactive = true,
														Image = assets.images.redonUI.remove,
														BackgroundColor3 = currentTheme.colors.mantle,
														ImageColor3 = currentTheme.colors.text,

														[Fusion.OnEvent "Activated"] = function()
															popup:addPopup(scope, {
																title = "Remove Section",
																description = `Are you sure you want to delete section <b>{key}</b>?\n<b>All data will be lost.</b>`,
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
																			local currentSections = scope.peek(sections)
																			table.remove(currentSections, key)
																			table.remove(columns, key)
																			sections:set(currentSections)
																			updateCurrentConfiguration()
																		end,
																		keybind = Enum.KeyCode.Return,
																	},
																},
															})
														end,
													},

													scope:textBox {
														Size = scope:Computed(function(use)
															return UDim2.new(0, 0.0534759358 * use(size).X, 1, 0)
														end),
														LayoutOrder = 2,
														CornerRadius = UDim.new(0.2, 0),
														Border = 1,
														Text = waitTime,
														BackgroundColor3 = currentTheme.colors.mantle,
														[Fusion.OnChange "Text"] = function(text: string)
															playing:set(false)
															local currentSections = scope.peek(sections)
															local currentSection = currentSections[key]
															currentSection.waitTime = tonumber(text) or 0.05
															sections:set(currentSections)
															updateCurrentConfiguration()
														end,
														[Fusion.OnEvent "FocusLost"] = function()
															local currentSections = scope.peek(sections)
															local currentSection = currentSections[key]
															waitTime:set(tostring(currentSection.waitTime))
														end,
													},

													scope:iconButton {
														Size = scope:Computed(function(use)
															return UDim2.new(0, 0.0267379679 * use(size).X, 1, 0)
														end),
														LayoutOrder = 3,
														CornerRadius = UDim.new(0.2, 0),
														Border = 2,
														Reactive = true,
														Image = assets.images.redonUI.add,
														BackgroundColor3 = currentTheme.colors.mantle,
														ImageColor3 = currentTheme.colors.text,

														[Fusion.OnEvent "Activated"] = function()
															addSection(key + 1)
														end,
													},
												},
											},

											scope:base {
												Name = "Headers",
												Size = UDim2.fromScale(1, 0.0342857143),
												Position = UDim2.fromScale(0.5, 0.0857142857),
												AnchorPoint = Vector2.new(0.5, 0),
												-- AutomaticSize = Enum.AutomaticSize.X,
												BackgroundTransparency = 1,
												ZIndex = 3,

												-- [Fusion.Children] = Fusion.Child {
												-- 	scope:New("UIListLayout") {
												-- 		Padding = scope:Computed(function(use)
												-- 			return UDim.new(0, 0.0053475936 * use(size).X)
												-- 		end),
												-- 		FillDirection = Enum.FillDirection.Horizontal,
												-- 		HorizontalAlignment = Enum.HorizontalAlignment.Center,
												-- 		SortOrder = Enum.SortOrder.LayoutOrder,
												-- 	},

												-- },

												[Fusion.Children] = scope:ForPairs(
													columns[key],
													function(use, scope: typeof(scope), columnKey: number, columnData)
														local currentColumnPositions = use(columnPositions)
														if currentColumnPositions[columnKey] == nil then
															currentColumnPositions[columnKey] =
																positionsScope:Value(Vector2.zero)
														end
														local color = scope:Computed(function(use)
															if use(playing) == false then
																return currentTheme.colors.base
															end
															local currentRow = use(value.currentRow)
															local colorData = scope.peek(colors)[scope.peek(
																columnData.rows
															)[currentRow]]
															return if colorData == nil
																then currentTheme.colors.base
																else if bloomColors[colorData.name]
																		~= nil
																	then bloomColors[colorData.name]
																	else colorData.lightoColor
														end)
														local baseProps = {
															Name = columnKey,
															Size = scope:Computed(function(use)
																return UDim2.new(0, 0.0401069519 * use(size).X, 1, 0)
															end),
															CornerRadius = UDim.new(0.1666666667, 0),
															Position = scope:Computed(function(use)
																return UDim2.new(
																	0,
																	use(currentColumnPositions[columnKey]).X
																		- use(position).X
																		- 0.0133689840 * use(size).X,
																	0,
																	0
																)
															end),
															-- LayoutOrder = columnKey,
															ZIndex = 2,
														}
														local descendants, children = {}, {}
														if use(settings.values.fakeBloom) then
															local visible = scope:Computed(function(use)
																return use(color) ~= currentTheme.colors.base
															end)
															baseProps.BackgroundColor3 =
																currentTheme.colors.base :: Fusion.UsedAs<Color3>

															children = {
																scope:base {
																	Size = UDim2.fromScale(1, 1),
																	BackgroundColor3 = Color3.new(1, 1, 1),
																	CornerRadius = UDim.new(0.1666666667, 0),
																	ZIndex = 2,
																	Visible = visible,
																},
															}
															descendants = {
																scope:base {
																	ClassName = "ImageLabel",
																	Name = `{columnKey}Light`,
																	AnchorPoint = Vector2.new(0, 0.5),
																	BackgroundTransparency = 1,
																	Image = assets.images.elsCreator.bloom,
																	ImageColor3 = color,
																	-- Position = UDim2.fromScale(0.5, 0.5),
																	ScaleType = Enum.ScaleType.Slice,
																	Size = scope:Computed(function(use)
																		return UDim2.new(
																			0,
																			(0.0401069519 * use(size).X) + 25,
																			1,
																			25
																		)
																	end),
																	Position = scope:Computed(function(use)
																		return UDim2.new(
																			0,
																			use(currentColumnPositions[columnKey]).X
																				- use(position).X
																				- 0.0133689840 * use(size).X
																				- 12.5,
																			0.5,
																			0
																		)
																	end),
																	SliceCenter = Rect.new(256, 256, 256, 256),
																	Visible = visible,
																},

																scope:base {
																	ClassName = "ImageLabel",
																	Name = `{columnKey}Light1`,
																	AnchorPoint = Vector2.new(0, 0.5),
																	BackgroundTransparency = 1,
																	Image = assets.images.elsCreator.bloom,
																	ImageColor3 = color,
																	ImageTransparency = 0.2,
																	-- Position = UDim2.fromScale(0.5, 0.5),
																	ScaleType = Enum.ScaleType.Slice,
																	Size = scope:Computed(function(use)
																		return UDim2.new(
																			0,
																			(0.0401069519 * use(size).X) + 150,
																			1,
																			150
																		)
																	end),
																	Position = scope:Computed(function(use)
																		return UDim2.new(
																			0,
																			use(currentColumnPositions[columnKey]).X
																				- use(position).X
																				- 0.0133689840 * use(size).X
																				- 75,
																			0.5,
																			0
																		)
																	end),
																	SliceCenter = Rect.new(256, 256, 256, 256),
																	Visible = visible,
																},

																scope:base {
																	ClassName = "ImageLabel",
																	Name = `{columnKey}Light2`,
																	AnchorPoint = Vector2.new(0, 0.5),
																	BackgroundTransparency = 1,
																	Image = assets.images.elsCreator.bloom,
																	ImageColor3 = color,
																	ImageTransparency = 0.5,
																	-- Position = UDim2.fromScale(0.5, 0.5),
																	ScaleType = Enum.ScaleType.Slice,
																	Size = scope:Computed(function(use)
																		return UDim2.new(
																			0,
																			(0.0401069519 * use(size).X) + 200,
																			1,
																			200
																		)
																	end),
																	Position = scope:Computed(function(use)
																		return UDim2.new(
																			0,
																			use(currentColumnPositions[columnKey]).X
																				- use(position).X
																				- 0.0133689840 * use(size).X
																				- 100,
																			0.5,
																			0
																		)
																	end),
																	SliceCenter = Rect.new(256, 256, 256, 256),
																	Visible = visible,
																},
															}
														else
															baseProps.BackgroundColor3 = color
														end
														columnData.currentName =
															scope:Value(scope.peek(columnData.lightName))
														table.insert(
															children,
															1,
															scope:textBox {
																BackgroundTransparency = 1,
																Visible = scope:Computed(function(use)
																	return use(playing) == false
																end),
																Size = UDim2.fromScale(1, 1),
																Text = columnData.lightName,
																[Fusion.Out "Text"] = columnData.lightName :: unknown,

																[Fusion.OnEvent "FocusLost"] = function(
																	enterPressed: boolean
																)
																	if enterPressed == false then
																		updateCurrentConfiguration()
																		return
																	end
																	propagateNameChange(columnData, columnKey)
																	updateCurrentConfiguration()
																end,
															}
														)
														baseProps[Fusion.Children] = children

														table.insert(descendants, 1, scope:base(baseProps))
														return columnKey, descendants
													end
												),
											},

											scope:base {
												Size = scope:Computed(function(use)
													return UDim2.new(
														0,
														use(contentSize).X - (0.0106951872 * use(size).X),
														0.0114285714,
														0
													)
												end),
												AnchorPoint = Vector2.new(0.5, 0),
												Position = UDim2.fromScale(0.5, 0.1428571429),
												BackgroundColor3 = currentTheme.colors.base,
												CornerRadius = UDim.new(1, 0),
											},

											scope:base {
												Name = "controls",
												Size = scope:Computed(function(use)
													return UDim2.new(0, 0.0401069519 * use(size).X, 0.04, 0)
												end),
												Position = scope:Spring(
													scope:Computed(function(use)
														return UDim2.new(0, use(hoverPosition), 0.1291428571, 0) -- 0.1285714286
													end),
													SPRING_SPEED,
													SPRING_DAMPING
												),
												BackgroundColor3 = currentTheme.colors.mantle,

												[Fusion.Children] = {
													scope:New("UIListLayout") {
														Padding = UDim.new(0.1333333333, 0),
														FillDirection = Enum.FillDirection.Horizontal,
														HorizontalAlignment = Enum.HorizontalAlignment.Center,
														VerticalAlignment = Enum.VerticalAlignment.Center,
														SortOrder = Enum.SortOrder.LayoutOrder,
													},

													scope:iconButton {
														Size = UDim2.fromScale(0.4, 0.8571428571),
														BackgroundColor3 = currentTheme.colors.crust,
														CornerRadius = UDim.new(0.1666666667, 0),
														Image = assets.images.redonUI.remove,
														Border = 1,
														Reactive = true,

														[Fusion.OnEvent "Activated"] = function()
															if #scope.peek(columns[key]) == 1 then
																log.warn("Cannot remove last column")
																return
															end
															local deleting = scope.peek(currentlyHovering)

															local function remove()
																currentlyHovering:set(
																	math.clamp(
																		deleting,
																		if deleting == 1 then 2 else 1,
																		#scope.peek(columns[key]) - 1
																	)
																)
																local currentColumns = scope.peek(columns[key])
																table.remove(currentColumns, deleting)
																columns[key]:set(currentColumns)
																updateCurrentConfiguration()
															end

															if holdingShift then
																remove()
																return
															end

															popup:addPopup(scope, {
																title = "Remove Column",
																description = `Are you sure you want to delete column <b>{deleting}</b>?\n<b>All data will be lost.</b>`,
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
														Size = UDim2.fromScale(0.4, 0.8571428571),
														LayoutOrder = 2,
														BackgroundColor3 = currentTheme.colors.crust,
														CornerRadius = UDim.new(0.1666666667, 0),
														Image = assets.images.redonUI.add,
														Border = 1,
														Reactive = true,

														[Fusion.OnEvent "Activated"] = function()
															local adding = scope.peek(currentlyHovering)
															local currentColumns = scope.peek(columns[key])
															local rows = {}
															for _ = 1, scope.peek(rowCount) do
																table.insert(rows, 0)
															end

															local lightName = `Light {adding + 1}`
															local addingNumber = tonumber(
																scope
																	.peek(currentColumns[adding].lightName)
																	:match("%d+$")
															) or adding
															local pattern = scope
																.peek(currentColumns[adding].lightName)
																:gsub("%d+$", "")
															lightName = pattern .. addingNumber + 1

															table.insert(currentColumns, adding + 1, {
																lightName = scope:Value(lightName),
																color = scope:Value(currentTheme.colors.base),
																rows = scope:Value(rows),
															})
															columns[key]:set(currentColumns)
															propagateNameChange(currentColumns[adding + 1], adding + 1)
															updateCurrentConfiguration()
															task.delay(1 / 16, function()
																currentlyHovering:set(adding + 1)
															end)
														end,
													},
												},
											},

											scope:base {
												ClassName = "ScrollingFrame",
												Name = "Columns",
												Size = UDim2.fromScale(1, 0.8285714286),
												AutomaticSize = Enum.AutomaticSize.X,
												Position = UDim2.fromScale(0, 0.1771428571),
												BackgroundTransparency = 1,
												CanvasSize = UDim2.new(),
												ScrollBarThickness = 3,
												ScrollBarImageColor3 = currentTheme.colors.text,
												TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
												BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
												AutomaticCanvasSize = Enum.AutomaticSize.Y,
												[Fusion.Out "CanvasPosition"] = canvasPosition :: unknown,
												[Fusion.Out "AbsoluteCanvasSize"] = canvasSize :: unknown,
												ZIndex = 2,

												[Fusion.Children] = Fusion.Child {
													scope:New("UIListLayout") {
														Padding = scope:Computed(function(use)
															return UDim.new(0, 0.0053475936 * use(size).X)
														end),
														FillDirection = Enum.FillDirection.Horizontal,
														HorizontalAlignment = Enum.HorizontalAlignment.Center,
														SortOrder = Enum.SortOrder.LayoutOrder,
														[Fusion.Out "AbsoluteContentSize"] = contentSize :: unknown,
													},

													scope:ForPairs(
														columns[key],
														function(_, scope: typeof(scope), columnKey: number, value)
															-- columnPositions[columnKey] = scope:Value(Vector2.zero)
															return columnKey,
																scope:base {
																	Name = columnKey,
																	Size = scope:Computed(function(use)
																		return UDim2.new(
																			0,
																			0.0401069519 * use(size).X,
																			1,
																			0
																		)
																	end),
																	BackgroundTransparency = 1,
																	LayoutOrder = columnKey,

																	[Fusion.OnEvent "MouseEnter"] = function()
																		currentlyHovering:set(columnKey)
																	end :: unknown,

																	-- [Fusion.Out "AbsolutePosition"] = columnPositions[columnKey],
																	[Fusion.OnChange "AbsolutePosition"] = function(
																		newPosition: Vector2
																	)
																		local currentColumnPositions =
																			scope.peek(columnPositions)
																		currentColumnPositions[columnKey]:set(
																			newPosition
																		)
																	end,

																	[Fusion.Children] = Fusion.Child {
																		scope:New("UIListLayout") {
																			Padding = UDim.new(0.0114285714, 0),
																			SortOrder = Enum.SortOrder.LayoutOrder,
																		},

																		scope:ForPairs(
																			value.rows,
																			function(
																				use,
																				scope: typeof(scope),
																				rowKey: number,
																				rowColor: number
																			)
																				local function update()
																					if drawing == 0 then
																						return
																					end
																					local isLocked = scope.peek(locked)
																					log.debug(isLocked)
																					if isLocked == true then
																						log.debug(lockedTo)
																						if lockedTo ~= nil then
																							if
																								lockedTo.section
																									~= key
																								or lockedTo.column
																									~= columnKey
																							then
																								return
																							end
																						else
																							lockedTo = {
																								section = key,
																								column = columnKey,
																							}
																						end
																					end

																					local currentRows =
																						scope.peek(value.rows)
																					if drawing == 1 then
																						currentRows[rowKey] =
																							scope.peek(currentColor)
																					elseif drawing == -1 then
																						currentRows[rowKey] = 0
																					end
																					value.rows:set(currentRows)
																					updateCurrentConfiguration()
																				end

																				local color = use(colors)[rowColor]
																				return rowKey,
																					scope:base {
																						Name = rowKey,
																						Size = UDim2.fromScale(
																							1,
																							0.0447761194
																						),
																						BackgroundColor3 = if rowColor
																								== 0
																							then currentTheme.colors.base
																							else getColorByName(
																								color.name,
																								color.lightoColor
																							),
																						CornerRadius = UDim.new(
																							0.1666666667,
																							0
																						),
																						LayoutOrder = rowKey,

																						[Fusion.OnEvent "MouseEnter"] = function()
																							currentlyHovering:set(
																								columnKey
																							)
																							update()
																						end :: unknown,
																						[Fusion.OnEvent "InputBegan"] = function(
																							input: InputObject
																						)
																							if
																								input.UserInputType
																								== Enum.UserInputType.MouseButton1
																							then
																								drawing = 1
																							elseif
																								input.UserInputType
																								== Enum.UserInputType.MouseButton2
																							then
																								drawing = -1
																							end
																							update()
																						end,
																					}
																			end
																		),

																		scope:base {
																			Size = UDim2.fromScale(1, 0.0447761194),
																			BackgroundTransparency = 1,
																			LayoutOrder = 4000,
																		},
																		scope:base {
																			Size = UDim2.fromScale(1, 0.0447761194),
																			BackgroundTransparency = 1,
																			LayoutOrder = 4000,
																		},
																	},
																}
														end
													),
												},
											},

											scope:base {
												ClassName = "ScrollingFrame",
												Name = "ColumnIndicators",
												Size = UDim2.fromScale(1.05, 0.8285714286),
												Position = UDim2.fromScale(0.5, 0.1771428571),
												AnchorPoint = Vector2.new(0.5, 0),
												BackgroundTransparency = 1,
												AutomaticCanvasSize = Enum.AutomaticSize.Y,
												CanvasPosition = canvasPosition,
												ScrollingEnabled = false,
												ScrollBarThickness = 0,
												ClipsDescendants = scope:Computed(function(use)
													return if use(value.currentRow) == 1
															and use(canvasPosition) == Vector2.zero
														then false
														else true
												end),

												[Fusion.Children] = {
													scope:base {
														BackgroundTransparency = 1,
														Size = scope:Computed(function(use)
															return UDim2.new(0, 10, 0, use(canvasSize).Y)
														end),
													},

													scope:base {
														Name = "indicator",
														Size = scope:Computed(function(use)
															return UDim2.new(
																0,
																use(contentSize).X + (0.0053475936 * use(size).X),
																0.0597014925,
																0
															)
														end),
														Position = scope:Computed(function(use)
															local currentRow = use(value.currentRow) - 1
															return UDim2.fromScale(
																0.5,
																(currentRow * 0.0447761194)
																	+ (currentRow * 0.0114285714)
																	- 0.0074626866
															)
														end),
														AnchorPoint = Vector2.new(0.5, 0),
														BackgroundColor3 = scope:Computed(function(use)
															return if use(playing) == true
																then currentTheme.colors.lavender
																else currentTheme.colors.crust
														end),
														BackgroundTransparency = scope:Computed(function(use)
															return if use(playing) == true then 0.5 else 0
														end),
														CornerRadius = UDim.new(0.175, 0),
													},
												},
											},

											scope:base {
												ClassName = "ScrollingFrame",
												Name = "ColumnControls",
												Size = UDim2.fromScale(1, 0.8285714286),
												Position = UDim2.fromScale(0, 0.1771428571),
												BackgroundTransparency = 1,
												AutomaticCanvasSize = Enum.AutomaticSize.Y,
												CanvasPosition = canvasPosition,
												ScrollingEnabled = false,
												ScrollBarThickness = 0,

												[Fusion.Children] = {
													scope:base {
														BackgroundTransparency = 1,
														Size = scope:Computed(function(use)
															return UDim2.new(0, 10, 0, use(canvasSize).Y)
														end),
													},

													scope:base {
														Name = "controls",
														Size = scope:Computed(function(use)
															return UDim2.new(0, 0.0401069519 * use(size).X, 1, 0)
														end),
														Position = scope:Spring(
															scope:Computed(function(use)
																return UDim2.new(0, use(hoverPosition), 0, 0)
															end),
															SPRING_SPEED,
															SPRING_DAMPING
														),
														BackgroundTransparency = 1,

														[Fusion.Children] = Fusion.Child {
															scope:New("UIListLayout") {
																Padding = UDim.new(0.0114285714, 0),
																HorizontalAlignment = Enum.HorizontalAlignment.Center,
																SortOrder = Enum.SortOrder.LayoutOrder,
															},

															scope:Computed(function(use, scope: typeof(scope))
																return scope:ForPairs(
																	table.create(use(rowCount), true),
																	function(_, scope: typeof(scope), key: number, _)
																		return key,
																			scope:base {
																				Name = key,
																				Size = UDim2.fromScale(1, 0.0447761194),
																				BackgroundTransparency = 1,
																				LayoutOrder = key,
																			}
																	end
																)
															end),

															scope:iconButton {
																Size = UDim2.fromScale(0.4, 0.0447761194),
																LayoutOrder = 4000,
																BackgroundColor3 = currentTheme.colors.crust,
																CornerRadius = UDim.new(0.1666666667, 0),
																Image = assets.images.redonUI.remove,
																Border = 1,
																Reactive = true,

																[Fusion.OnEvent "Activated"] = function()
																	if scope.peek(rowCount) == 1 then
																		log.warn("Cannot remove last row")
																		return
																	end
																	local deleting = scope.peek(rowCount)

																	local function remove()
																		local currentColumns = scope.peek(columns[key])
																		local currentSection = scope.peek(sections)[key]
																		rowCount:set(deleting - 1)
																		currentSection.rowCount = deleting - 1

																		for _, column in currentColumns do
																			local currentRows = scope.peek(column.rows)
																			table.remove(currentRows)
																			column.rows:set(currentRows)
																		end

																		updateCurrentConfiguration()
																	end

																	if holdingShift then
																		remove()
																		return
																	end

																	popup:addPopup(scope, {
																		title = "Remove Column",
																		description = `Are you sure you want to delete row <b>{deleting}</b>?\n<b>All data will be lost.</b>`,
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
																Size = UDim2.fromScale(0.4, 0.0447761194),
																LayoutOrder = 4001,
																BackgroundColor3 = currentTheme.colors.crust,
																CornerRadius = UDim.new(0.1666666667, 0),
																Image = assets.images.redonUI.add,
																Border = 1,
																Reactive = true,

																[Fusion.OnEvent "Activated"] = function()
																	local currentColumns = scope.peek(columns[key])
																	local currentRowCount = scope.peek(rowCount)
																	local currentSection = scope.peek(sections)[key]
																	currentRowCount += 1
																	rowCount:set(currentRowCount)
																	currentSection.rowCount = currentRowCount

																	for _, column in currentColumns do
																		local currentRows = scope.peek(column.rows)
																		while #currentRows < currentRowCount do
																			table.insert(currentRows, 0)
																		end
																		column.rows:set(currentRows)
																	end

																	updateCurrentConfiguration()
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
