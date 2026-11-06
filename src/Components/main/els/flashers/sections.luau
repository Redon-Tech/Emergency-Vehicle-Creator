--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local Editor = require("../../../../lib/ConfigurationEditor/FunctionsEditor/FlashersEditor")
local types = require("../../../../types")
local popup = require("../../../popup")
local ChassisHandler = require("../../../../lib/ChassisHandler")
local assets = require("../../../../assets")
local log = require("../../../../log")

local columnHeader = require("./columnHeader")
local column = require("./column")
local components = {
	columnHeader = columnHeader,
	column = column,
}

local SPRING_SPEED = 25
local SPRING_DAMPING = 1
type FlasherSection = Editor.FlasherSectionState & { currentRow: Fusion.Value<number> }

--[=[
	flashers.sections
	Creates the sections for the flashers editor
]=]
return function(
	baseScope: types.Scope,
	props: {
		colors: Fusion.UsedAs<{ ChassisHandler.color }>,
		currentColor: Fusion.Value<number>,
		playing: Fusion.Value<boolean>,
		drawing: Fusion.Value<number>,
		size: Fusion.Value<Vector2>,
		temporarlyPause: () -> () -> (),
		locked: Fusion.Value<boolean>,
		holdingShift: Fusion.Value<boolean>,
		sections: Fusion.UsedAs<{ FlasherSection }>,
		CurrentPattern: Fusion.Value<types.selectedPattern?>,
		addSection: (atPoint: number) -> (),
	}
)
	local scope = baseScope:innerScope(components)
	local currentTheme = RedonUI.theme.theme:now()
	local lockedTo: Fusion.Value<{ section: number, column: number }?> = scope:Value(nil)

	scope:Observer(props.locked):onChange(function()
		if scope.peek(props.locked) == false then
			lockedTo:set(nil)
		end
	end)

	return scope:ForPairs(props.sections, function(_, scope: typeof(scope), key: number, value: FlasherSection)
		local selected = scope.peek(props.CurrentPattern)
		assert(selected ~= nil, "No selected pattern")
		local position = scope:Value(Vector2.one)
		local contentSize = scope:Value(Vector2.one)
		local canvasSize = scope:Value(Vector2.one)
		local canvasPosition = scope:Value(Vector2.zero)
		local currentlyHovering = scope:Value(1)
		local positionsScope = scope:innerScope()
		local columnPositions: Fusion.Value<{ [number]: { scope: typeof(positionsScope), value: Fusion.Value<Vector2> } }> =
			scope:Value({})
		local function addPosition(position: number)
			local tempScope = positionsScope:innerScope()
			local tempValue = tempScope:Value(Vector2.one)
			local previousPositions = scope.peek(columnPositions)
			local previousScope = if previousPositions[position] ~= nil then previousPositions[position].scope else nil
			previousPositions[position] = {
				scope = tempScope,
				value = tempValue,
			}
			columnPositions:set(previousPositions)
			if previousScope ~= nil then
				previousScope:doCleanup()
			end
		end
		for i = 1, #scope.peek(value.columns) do
			addPosition(i)
		end
		local hoverPosition = scope:Computed(function(use)
			local positionData = use(columnPositions)[use(currentlyHovering)]
			return if positionData ~= nil
				then math.clamp(
					use(positionData.value).X - use(position).X - 0.0133689840 * use(props.size).X,
					0,
					use(contentSize).X
				)
				else 0
		end)

		scope:Observer(value.rowCount):onChange(function()
			local currentRowCount = scope.peek(value.rowCount)
			if scope.peek(value.currentRow) > currentRowCount then
				value.currentRow:set(1)
			end
		end)

		local nameTemplate: { pattern: string, originalPosition: number }? = nil

		local function propagateNameChange(
			columnData: Editor.FlasherColumnState,
			columnKey: number,
			originalName: string
		)
			local newName = scope.peek(columnData.lightName)
			local prefix = newName:gsub("%d+$", "")
			local number = tonumber(newName:match("%d+$"))
			if number == nil then
				return
			end
			local originalPrefix = originalName:gsub("%d+$", "")
			if
				nameTemplate == nil
				or nameTemplate.originalPosition <= columnKey
				or nameTemplate.pattern == originalPrefix
			then
				nameTemplate = { pattern = prefix, originalPosition = columnKey }
			end
			for columnId, column in scope.peek(value.columns) do
				local columnPrefix = scope.peek(column.lightName):gsub("%d+$", "")
				if columnId <= columnKey or columnPrefix ~= originalPrefix then
					continue
				end
				if
					nameTemplate ~= nil
					and nameTemplate.originalPosition > columnKey
					and columnId >= nameTemplate.originalPosition
				then
					continue
				end
				do
					ConfigurationEditor.updateFlasherColumnLightName(
						selected.functionId,
						selected.patternId,
						key,
						columnId,
						prefix .. (number + columnId - columnKey)
					)
				end
			end
		end

		local waitTimeText = scope:Value(tostring(scope.peek(value.waitTime)))
		return key,
			scope:base {
				Name = key,
				BackgroundColor3 = currentTheme.colors.mantle,
				Size = UDim2.fromScale(0, 0.9259259259),
				CornerRadius = scope:Computed(function(use)
					return UDim.new(0, 0.0171428571 * use(props.size).Y) -- I shouldn't have to do this
				end),
				LayoutOrder = key,
				AutomaticSize = Enum.AutomaticSize.X,
				[Fusion.Out "AbsolutePosition"] = position :: unknown,

				[Fusion.Children] = Fusion.Child {
					scope:New("UIPadding") {
						PaddingTop = UDim.new(0.0285714286, 0),
						PaddingBottom = UDim.new(0.0285714286, 0),
						PaddingLeft = scope:Computed(function(use)
							return UDim.new(0, 0.0133689840 * use(props.size).X)
						end),
						PaddingRight = scope:Computed(function(use)
							return UDim.new(0, 0.0133689840 * use(props.size).X)
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
									return UDim.new(0, 0.0080213904 * use(props.size).X)
								end),
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
							},

							scope:iconButton {
								Size = scope:Computed(function(use)
									return UDim2.new(0, 0.0267379679 * use(props.size).X, 1, 0)
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
													local unpause = props.temporarlyPause()
													popup:removePopup(newPopup)
													ConfigurationEditor.removeFlasherSection(
														selected.functionId,
														selected.patternId,
														key
													)

													unpause()
												end,
												keybind = Enum.KeyCode.Return,
											},
										},
									})
								end,
							},

							scope:textBox {
								Size = scope:Computed(function(use)
									return UDim2.new(0, 0.0534759358 * use(props.size).X, 1, 0)
								end),
								LayoutOrder = 2,
								CornerRadius = UDim.new(0.2, 0),
								Border = 1,
								Text = waitTimeText,
								[Fusion.Out "Text"] = waitTimeText :: unknown,
								BackgroundColor3 = currentTheme.colors.mantle,
								[Fusion.OnEvent "FocusLost"] = function()
									local unpause = props.temporarlyPause()
									ConfigurationEditor.updateFlasherSectionWaitTime(
										selected.functionId,
										selected.patternId,
										key,
										math.max(0, tonumber(scope.peek(waitTimeText)) or 0.05)
									)
									waitTimeText:set(tostring(scope.peek(value.waitTime)))

									unpause()
									unpause()
								end,
							},

							scope:iconButton {
								Size = scope:Computed(function(use)
									return UDim2.new(0, 0.0267379679 * use(props.size).X, 1, 0)
								end),
								LayoutOrder = 3,
								CornerRadius = UDim.new(0.2, 0),
								Border = 2,
								Reactive = true,
								Image = assets.images.redonUI.add,
								BackgroundColor3 = currentTheme.colors.mantle,
								ImageColor3 = currentTheme.colors.text,

								[Fusion.OnEvent "Activated"] = function()
									props.addSection(key + 1)
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

						[Fusion.Children] = scope:ForPairs(
							value.columns,
							function(use, scope: typeof(scope), columnKey: number, columnData)
								return columnKey,
									scope:columnHeader {
										use = use,
										columnKey = columnKey,
										columnData = columnData,
										columnPositions = columnPositions,
										colors = props.colors,
										playing = props.playing,
										size = props.size,
										position = position,
										section = value,
										sectionKey = key,
										CurrentPattern = props.CurrentPattern,

										propagateNameChange = propagateNameChange,
									}
							end
						),
					},

					scope:base {
						Size = scope:Computed(function(use)
							return UDim2.new(
								0,
								use(contentSize).X - (0.0106951872 * use(props.size).X),
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
							return UDim2.new(0, 0.0401069519 * use(props.size).X, 0.04, 0)
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
									if #scope.peek(value.columns) == 1 then
										log.warn("Cannot remove last column")
										return
									end
									local deleting = scope.peek(currentlyHovering)

									local function remove()
										currentlyHovering:set(
											if deleting == 1
												then 1
												else math.clamp(deleting, 1, #scope.peek(value.columns) - 1)
										)
										ConfigurationEditor.removeFlasherColumn(
											selected.functionId,
											selected.patternId,
											key,
											deleting
										)
									end

									if scope.peek(props.holdingShift) then
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
									local currentColumns = scope.peek(value.columns)
									local rows = {}
									for _ = 1, scope.peek(value.rowCount) do
										table.insert(rows, 0)
									end

									local lightName = `Light {adding + 1}`
									local addingNumber = tonumber(
										scope.peek(currentColumns[adding].lightName):match("%d+$")
									) or adding
									local pattern = scope.peek(currentColumns[adding].lightName):gsub("%d+$", "")
									lightName = pattern .. addingNumber + 1

									local originalName = scope.peek(currentColumns[adding].lightName)
									addPosition(#currentColumns + 1)
									ConfigurationEditor.addFlasherColumn(
										selected.functionId,
										selected.patternId,
										key,
										{ lightName = lightName, rows = rows },
										adding + 1
									)
									propagateNameChange(scope.peek(value.columns)[adding + 1], adding + 1, originalName)

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
									return UDim.new(0, 0.0053475936 * use(props.size).X)
								end),
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								[Fusion.Out "AbsoluteContentSize"] = contentSize :: unknown,
							},

							scope:ForPairs(
								value.columns,
								function(_, scope: typeof(scope), columnKey: number, columnData)
									return columnKey,
										scope:column {
											columnKey = columnKey,
											columnData = columnData,
											sectionKey = key,
											currentlyHovering = currentlyHovering,
											columnPositions = columnPositions,
											drawing = props.drawing,
											size = props.size,
											CurrentPattern = props.CurrentPattern,

											locked = props.locked,
											currentColor = props.currentColor,
											colors = props.colors,
											lockedTo = lockedTo,
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
							return if use(value.currentRow) == 1 and use(canvasPosition) == Vector2.zero
								then false
								else true
						end),

						[Fusion.Children] = {
							scope:base {
								BackgroundTransparency = 1,
								Size = scope:Computed(function(use)
									return UDim2.fromOffset(10, use(canvasSize).Y)
								end),
							},

							scope:base {
								Name = "indicator",
								Size = scope:Computed(function(use)
									return UDim2.new(
										0,
										use(contentSize).X + (0.0053475936 * use(props.size).X),
										0.0597014925,
										0
									)
								end),
								Position = scope:Computed(function(use)
									local currentRow = use(value.currentRow) - 1
									return UDim2.fromScale(
										0.5,
										(currentRow * 0.0447761194) + (currentRow * 0.0114285714) - 0.0074626866
									)
								end),
								AnchorPoint = Vector2.new(0.5, 0),
								BackgroundColor3 = scope:Computed(function(use)
									return if use(props.playing) == true
										then currentTheme.colors.lavender
										else currentTheme.colors.crust
								end),
								BackgroundTransparency = scope:Computed(function(use)
									return if use(props.playing) == true then 0.5 else 0
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
									return UDim2.fromOffset(10, use(canvasSize).Y)
								end),
							},

							scope:base {
								Name = "controls",
								Size = scope:Computed(function(use)
									return UDim2.new(0, 0.0401069519 * use(props.size).X, 1, 0)
								end),
								Position = scope:Spring(
									scope:Computed(function(use)
										return UDim2.fromOffset(use(hoverPosition), 0)
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
											table.create(use(value.rowCount), true),
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
											if scope.peek(value.rowCount) == 1 then
												log.warn("Cannot remove last row")
												return
											end
											local deleting = scope.peek(value.rowCount)

											local function remove()
												ConfigurationEditor.removeSectionRow(
													selected.functionId,
													selected.patternId,
													key,
													deleting
												)
											end

											if scope.peek(props.holdingShift) then
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
											local count = if scope.peek(props.holdingShift) then 5 else 1
											for _ = 1, count do
												ConfigurationEditor.addSectionRow(
													selected.functionId,
													selected.patternId,
													key
												)
											end
										end,
									},
								},
							},
						},
					},
				},
			}
	end)
end
