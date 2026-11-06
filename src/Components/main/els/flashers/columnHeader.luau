--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local Editor = require("../../../../lib/ConfigurationEditor/FunctionsEditor/FlashersEditor")
local types = require("../../../../types")
local ChassisHandler = require("../../../../lib/ChassisHandler")
local assets = require("../../../../assets")
local SettingsHandler = require("../../../../lib/SettingsHandler")

type FlasherSection = Editor.FlasherSectionState & { currentRow: Fusion.Value<number> }

--[=[
	flashers.columnHeader
	Creates the header for a column
]=]
return function(
	scope: types.Scope,
	props: {
		use: Fusion.Use,
		columnKey: number,
		sectionKey: number,
		columnData: Editor.FlasherColumnState,
		columnPositions: Fusion.Value<{ [number]: { scope: any, value: Fusion.Value<Vector2> } }>,
		colors: Fusion.UsedAs<{ ChassisHandler.color }>,
		playing: Fusion.Value<boolean>,
		size: Fusion.Value<Vector2>,
		position: Fusion.Value<Vector2>,
		section: FlasherSection,
		CurrentPattern: Fusion.Value<types.selectedPattern?>,
		propagateNameChange: (columnData: Editor.FlasherColumnState, columnKey: number, originalName: string) -> (),
	}
)
	local selected = scope.peek(props.CurrentPattern)
	assert(selected ~= nil, "No selected pattern")
	local currentTheme = RedonUI.theme.theme:now()

	local currentColumnPositions = props.use(props.columnPositions)
	if currentColumnPositions[props.columnKey] == nil then
		return {}
	end
	local color = scope:Computed(function(use)
		if use(props.playing) == false then
			return currentTheme.colors.base
		end
		local currentRow = use(props.section.currentRow)
		local colorData = use(props.colors)[use(props.columnData.rows)[currentRow]]
		return if colorData == nil
			then currentTheme.colors.base
			else if scope.bloomColors[colorData.name] ~= nil
				then scope.bloomColors[colorData.name]
				else colorData.lightoColor
	end)
	local baseProps = {
		Name = props.columnKey,
		Size = scope:Computed(function(use)
			return UDim2.new(0, 0.0401069519 * use(props.size).X, 1, 0)
		end),
		CornerRadius = UDim.new(0.1666666667, 0),
		Position = scope:Computed(function(use)
			return UDim2.new(
				0,
				use(currentColumnPositions[props.columnKey].value).X
					- use(props.position).X
					- 0.0133689840 * use(props.size).X,
				0,
				0
			)
		end),
		ZIndex = 2,
	}
	local descendants, children = {}, {}
	if props.use(SettingsHandler.values.fakeBloom) then
		local visible = scope:Computed(function(use)
			return use(color) ~= currentTheme.colors.base
		end)
		baseProps.BackgroundColor3 = currentTheme.colors.base :: Fusion.UsedAs<Color3>

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
				Name = `{props.columnKey}Light`,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Image = assets.images.elsCreator.bloom,
				ImageColor3 = color,
				ScaleType = Enum.ScaleType.Slice,
				Size = scope:Computed(function(use)
					return UDim2.new(0, (0.0401069519 * use(props.size).X) + 25, 1, 25)
				end),
				Position = scope:Computed(function(use)
					return UDim2.new(
						0,
						use(currentColumnPositions[props.columnKey].value).X
							- use(props.position).X
							- 0.0133689840 * use(props.size).X
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
				Name = `{props.columnKey}Light1`,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Image = assets.images.elsCreator.bloom,
				ImageColor3 = color,
				ImageTransparency = 0.2,
				ScaleType = Enum.ScaleType.Slice,
				Size = scope:Computed(function(use)
					return UDim2.new(0, (0.0401069519 * use(props.size).X) + 150, 1, 150)
				end),
				Position = scope:Computed(function(use)
					return UDim2.new(
						0,
						use(currentColumnPositions[props.columnKey].value).X
							- use(props.position).X
							- 0.0133689840 * use(props.size).X
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
				Name = `{props.columnKey}Light2`,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Image = assets.images.elsCreator.bloom,
				ImageColor3 = color,
				ImageTransparency = 0.5,
				ScaleType = Enum.ScaleType.Slice,
				Size = scope:Computed(function(use)
					return UDim2.new(0, (0.0401069519 * use(props.size).X) + 200, 1, 200)
				end),
				Position = scope:Computed(function(use)
					return UDim2.new(
						0,
						use(currentColumnPositions[props.columnKey].value).X
							- use(props.position).X
							- 0.0133689840 * use(props.size).X
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
	local currentName = scope:Value(scope.peek(props.columnData.lightName))
	table.insert(
		children,
		1,
		scope:textBox {
			BackgroundTransparency = 1,
			Visible = scope:Computed(function(use)
				return use(props.playing) == false
			end),
			Size = UDim2.fromScale(1, 1),
			Text = props.columnData.lightName,
			[Fusion.Out "Text"] = currentName :: unknown,

			[Fusion.OnEvent "FocusLost"] = function(enterPressed: boolean)
				local originalName = scope.peek(props.columnData.lightName)
				ConfigurationEditor.updateFlasherColumnLightName(
					selected.functionId,
					selected.patternId,
					props.sectionKey,
					props.columnKey,
					scope.peek(currentName)
				)
				if enterPressed then
					props.propagateNameChange(props.columnData, props.columnKey, originalName)
				end
			end,
		}
	)
	baseProps[Fusion.Children] = children

	table.insert(descendants, 1, scope:base(baseProps))
	return descendants
end
