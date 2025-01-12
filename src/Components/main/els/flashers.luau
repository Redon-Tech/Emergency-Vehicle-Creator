--#selene: allow(shadowing)
-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local popup = require(root.Plugin.Components.popup)
local chassisHandler = require(root.Plugin.chassisHandler)
local assets = require(root.Plugin.assets)

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.pattern?>,
}

type section = {
	waitTime: number,
	rowCount: number,
}

-- local function createSection(scope: types.Scope, key: number, value: section) end

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
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

	local currentConfiguration = nil
	local colors: Fusion.Value<{ chassisHandler.color }> = scope:Value({})
	local currentColor: Fusion.Value<number> = scope:Value(1)
	local playing = scope:Value(false)
	local locked = scope:Value(false)
	-- sections without the columns
	local sections: Fusion.Value<{ section }> = scope:Value({})
	-- array of sections with the columns
	local columns: { Fusion.Value<{ [number]: { lightName: string, color: Fusion.UsedAs<Color3>, rows: Fusion.Value<{ types.elsColor }> } }> } =
		{}

	scope:Observer(props.CurrentPattern):onChange(function()
		local currentPattern = scope.peek(props.CurrentPattern)
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if currentPattern ~= nil and typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				colors:set(currentConfiguration.lightSettings.colors)
			end

			local flashers = currentPattern.flashers
			local newSections = {}
			local newColumns = {}
			for i, section in flashers do
				local columns = {}
				for columnId, columnData in section.columns do
					local rows = {}
					for _, color in columnData.rows do
						table.insert(rows, color)
					end
					columns[columnId] =
						{ lightName = columnData.lightName, color = currentTheme.colors.base, rows = scope:Value(rows) }
				end
				table.insert(newColumns, i, scope:Value(columns))
				table.insert(newSections, i, {
					waitTime = section.waitTime,
					rowCount = section.rowCount,
				})
			end
			sections:set(newSections)
			columns = newColumns
		end
	end)

	-- TODO
	-- local function updateCurrentConfiguration()
	-- 	if currentConfiguration ~= nil then
	-- 		local assembledSections = {}
	-- 		for i, section in scope.peek(sections) do
	-- 			local assembledSection = {} :: types.flasherSection
	-- 			assembledSection.waitTime = section.waitTime
	-- 			assembledSection.rowCount = section.rowCount
	-- 			local columns = scope.peek(columns[i])
	-- 			for columnId, columnData in columns do
	-- 				local assembledColumn = {} :: { lightName: string, rows: { types.elsColor } }
	-- 				assembledColumn.lightName = columnData.lightName
	-- 				assembledColumn.rows = {}
	-- 				for _, color in scope.peek(columnData.rows) do
	-- 					table.insert(assembledColumn.rows, color)
	-- 				end
	-- 				assembledSection.columns[columnId] = assembledColumn
	-- 			end

	-- 			table.insert(assembledSections, i, assembledSection)
	-- 		end
	-- 		local currentPattern = scope.peek(props.CurrentPattern)
	-- 	end
	-- end

	local function addSection(atPoint: number?)
		local currentSections = scope.peek(sections)
		if atPoint == nil then
			atPoint = #currentSections + 1
		end
		table.insert(currentSections, atPoint :: number, {
			waitTime = 0,
			rowCount = 10,
		})
		table.insert(
			columns,
			atPoint :: number,
			scope:Value({
				{
					lightName = "",
					color = currentTheme.colors.base,
					rows = scope:Value({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
				},
			})
		)
		sections:set(currentSections)
	end

	local playHovered = scope:Value(false)
	local lockedHovered = scope:Value(false)
	local size = scope:Value(Vector2.one)
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

					scope:ForPairs(colors, function(_, scope: typeof(scope), key: number, value: chassisHandler.color)
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
									return if use(currentColor) == key then color else currentTheme.colors.mantle
								end),
								TextColor3 = scope:Computed(function(use)
									return if use(currentColor) == key then currentTheme.colors.mantle else color
								end),
								LayoutOrder = key,
							}
					end),

					scope:iconButton {
						Size = UDim2.fromScale(0.0260416667, 0.8333333333),
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Reactive = true,
						LayoutOrder = 100,
						Image = scope:Computed(function(use)
							local playing = use(playing)
							return if playing
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

				[Fusion.Children] = Fusion.Child {
					scope:New("UIListLayout") {
						Padding = UDim.new(0.0130208333, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					scope:ForPairs(sections, function(_, scope: typeof(scope), key: number, value: section)
						local position = scope:Value(Vector2.one)
						local contentSize = scope:Value(Vector2.one)
						local canvasSize = scope:Value(Vector2.one)
						local canvasPosition = scope:Value(Vector2.zero)
						local columnPositions: { Fusion.Value<Vector2> } = {
							[1] = scope:Value(Vector2.one),
						}
						local currentlyHovering = scope:Value(1)
						local hoverPosition = scope:Computed(function(use)
							return use(columnPositions[use(currentlyHovering)]).X
								- use(position).X
								- 0.0133689840 * use(size).X
						end)
						local rowCount = scope:Value(value.rowCount)
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
													local currentSections = scope.peek(sections)
													table.remove(currentSections, key)
													table.remove(columns, key)
													sections:set(currentSections)
												end,
											},

											scope:textBox {
												Size = scope:Computed(function(use)
													return UDim2.new(0, 0.0534759358 * use(size).X, 1, 0)
												end),
												LayoutOrder = 2,
												CornerRadius = UDim.new(0.2, 0),
												Border = 1,
												Text = tostring(value.waitTime),
												BackgroundColor3 = currentTheme.colors.mantle,
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
										Position = UDim2.fromScale(0, 0.0857142857),
										AutomaticSize = Enum.AutomaticSize.X,
										BackgroundTransparency = 1,

										[Fusion.Children] = Fusion.Child {
											scope:New("UIListLayout") {
												Padding = scope:Computed(function(use)
													return UDim.new(0, 0.0053475936 * use(size).X)
												end),
												FillDirection = Enum.FillDirection.Horizontal,
												HorizontalAlignment = Enum.HorizontalAlignment.Center,
												SortOrder = Enum.SortOrder.LayoutOrder,
											},

											scope:ForPairs(
												columns[key],
												function(_, scope: typeof(scope), columnKey: number, value)
													return columnKey,
														scope:base {
															Name = columnKey,
															Size = scope:Computed(function(use)
																return UDim2.new(0, 0.0401069519 * use(size).X, 1, 0)
															end),
															BackgroundColor3 = value.color,
															CornerRadius = UDim.new(0.1666666667, 0),
															LayoutOrder = columnKey,
														}
												end
											),
										},
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
													local currentColumns = scope.peek(columns[key])
													local rows = {}
													for _ = 1, scope.peek(rowCount) do
														table.insert(rows, 0)
													end
													table.insert(currentColumns, scope.peek(currentlyHovering) + 1, {
														lightName = "",
														color = currentTheme.colors.base,
														rows = scope:Value(rows),
													})
													columns[key]:set(currentColumns)
												end,
											},
										},
									},

									scope:base {
										ClassName = "ScrollingFrame",
										Name = "Columns",
										Size = UDim2.fromScale(1, 0.8285714286),
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
													columnPositions[columnKey] = scope:Value(Vector2.one)
													return columnKey,
														scope:base {
															Name = columnKey,
															Size = scope:Computed(function(use)
																return UDim2.new(0, 0.0401069519 * use(size).X, 1, 0)
															end),
															BackgroundTransparency = 1,
															LayoutOrder = columnKey,

															[Fusion.OnEvent "MouseEnter"] = function()
																currentlyHovering:set(columnKey)
															end :: unknown,

															[Fusion.Out "AbsolutePosition"] = columnPositions[columnKey],

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
																		value: number
																	)
																		local color = use(colors)[value]
																		return rowKey,
																			scope:base {
																				Name = rowKey,
																				Size = UDim2.fromScale(1, 0.0447761194),
																				BackgroundColor3 = if value == 0
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
																					currentlyHovering:set(columnKey)
																				end :: unknown,
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
										Name = "ColumnExtras",
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
															currentRowCount += 1

															for _, column in currentColumns do
																local currentRows = scope.peek(column.rows)
																table.insert(currentRows, 0)
																column.rows:set(currentRows)
															end

															rowCount:set(currentRowCount)
															columns[key]:set(currentColumns)
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
				Size = UDim2.fromScale(0.15625, 0.0970873786),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = currentTheme.colors.mantle,
				CornerRadius = UDim.new(0.2, 0),
				Text = "Add Section",
				TextScaled = true,
				MaxTextSize = 35,
				TextColor3 = currentTheme.colors.text,
				Border = 2,
				Reactive = true,
				Visible = scope:Computed(function(use)
					return #use(sections) == 0
				end),

				[Fusion.OnEvent "Activated"] = function()
					addSection()
				end,
			},
		},
	}
end
