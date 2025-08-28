--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)
local log = require(root.Plugin.log)
local utils = require(root.Plugin.utils)

--[=[
	flashers.sections
	Creates the sections for the flashers editor
]=]
return function(
	scope: types.Scope,
	props: {
		columnKey: number,
		columnData: any,
		sectionKey: number,
		currentlyHovering: Fusion.Value<number>,
		columnPositions: Fusion.Value<{ [number]: { scope: any, value: Fusion.Value<Vector2> } }>,
		drawing: Fusion.Value<number>,
		size: Fusion.Value<Vector2>,
		updateCurrentConfiguration: () -> (),
		locked: Fusion.Value<boolean>,
		currentColor: Fusion.Value<number>,
		colors: Fusion.Value<{ chassisHandler.color }>,
		lockedTo: Fusion.Value<{ section: number, column: number }?>,
	}
)
	local currentTheme = RedonUI.theme.theme:now()

	return scope:base {
		Name = props.columnKey,
		Size = scope:Computed(function(use)
			return UDim2.new(0, 0.0401069519 * use(props.size).X, 1, 0)
		end),
		BackgroundTransparency = 1,
		LayoutOrder = props.columnKey,

		[Fusion.OnEvent "MouseEnter"] = function()
			props.currentlyHovering:set(props.columnKey)
		end :: unknown,

		[Fusion.OnChange "AbsolutePosition"] = function(newPosition: Vector2)
			local currentColumnPositions = scope.peek(props.columnPositions)
			if currentColumnPositions[props.columnKey] == nil then
				return
			end
			currentColumnPositions[props.columnKey].value:set(newPosition)
		end,

		[Fusion.Children] = Fusion.Child {
			scope:New("UIListLayout") {
				Padding = UDim.new(0.0114285714, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			scope:ForPairs(props.columnData.rows, function(use, scope: typeof(scope), rowKey: number, rowColor: number)
				local function update()
					if scope.peek(props.drawing) == 0 then
						return
					end
					local isLocked = scope.peek(props.locked)
					log.debug(isLocked)
					if isLocked == true then
						local lockedTo = scope.peek(props.lockedTo)
						log.debug(props.lockedTo)
						if lockedTo ~= nil then
							if lockedTo.section ~= props.sectionKey or lockedTo.column ~= props.columnKey then
								return
							end
						else
							props.lockedTo:set({
								section = props.sectionKey,
								column = props.columnKey,
							})
						end
					end

					local currentRows = scope.peek(props.columnData.rows)
					if scope.peek(props.drawing) == 1 then
						currentRows[rowKey] = scope.peek(props.currentColor)
					elseif scope.peek(props.drawing) == -1 then
						currentRows[rowKey] = 0
					end
					props.columnData.rows:set(currentRows)
					props.updateCurrentConfiguration()
				end

				local color = use(props.colors)[rowColor]
				return rowKey,
					scope:base {
						Name = rowKey,
						Size = UDim2.fromScale(1, 0.0447761194),
						BackgroundColor3 = if rowColor == 0
							then currentTheme.colors.base
							else utils.getColorByName(color.name, color.lightoColor),
						CornerRadius = UDim.new(0.1666666667, 0),
						LayoutOrder = rowKey,

						[Fusion.OnEvent "MouseEnter"] = function()
							props.currentlyHovering:set(props.columnKey)
							update()
						end :: unknown,
						[Fusion.OnEvent "InputBegan"] = function(input: InputObject)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								props.drawing:set(1)
							elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
								props.drawing:set(-1)
							end
							update()
						end,
					}
			end),

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
