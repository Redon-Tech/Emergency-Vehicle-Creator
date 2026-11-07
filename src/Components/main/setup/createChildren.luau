--!strict
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local types = require("../../../types")

export type Column = { key: string, width: Fusion.UsedAs<UDim>?, rightAligned: boolean? }
export type Row = {
	LayoutOrder: number?,
	Heading: Fusion.UsedAs<string>?,
	Cells: { [string]: Fusion.Child? },
	Children: Fusion.Child?,
	Visible: Fusion.UsedAs<boolean>?,
	BackgroundColor3: Fusion.UsedAs<Color3>?,
	ChildrenHidden: Fusion.UsedAs<boolean>?,
}
export type TableProps = {
	Columns: { Column },
	Headers: { [string]: string }?,
	Rows: Fusion.UsedAs<{ [number]: Row }>,
	LayoutOrder: Fusion.UsedAs<number>?,
	Spacing: number?,
	RowSpacing: number?,
	Scale: Fusion.UsedAs<number>?,
	Padding: number?,
	RowPadding: number?,
	HeaderHeight: number?,
	HideWhenEmpty: boolean?,
	AutoWidth: boolean?,
}
export type FieldProps = {
	Label: Fusion.UsedAs<string>?,
	Content: Fusion.Child,
	LayoutOrder: Fusion.UsedAs<number>?,
	Visible: Fusion.UsedAs<boolean>?,
	Scale: Fusion.UsedAs<number>?,
}
export type DropdownProps<T> = {
	Selected: Fusion.UsedAs<T>,
	Options: Fusion.UsedAs<{ T }>,
	OnSelect: (T) -> (),
	Format: ((T) -> string)?,
	Height: number?,
	DropdownHeight: Fusion.UsedAs<number>?,
	LayoutOrder: Fusion.UsedAs<number>?,
	Visible: Fusion.UsedAs<boolean>?,
	Disabled: Fusion.UsedAs<boolean>?,
	Scale: Fusion.UsedAs<number>?,
}

local Layout = {}

local function list(scope: types.Scope, horizontal: boolean, spacing: Fusion.UsedAs<number>): Instance
	return scope:New("UIListLayout") {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = scope:Computed(function(use)
			return UDim.new(0, use(spacing))
		end),
	}
end

local function label(scope: types.Scope, text: Fusion.UsedAs<string>, height: Fusion.UsedAs<number>): Instance
	return scope:textLabel {
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, use(height))
		end),
		BackgroundTransparency = 1,
		Text = text,
		TextScaled = true,
		MaxTextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontWeight = Enum.FontWeight.Medium,
	}
end

function Layout.Field(scope: types.Scope, props: FieldProps): Instance
	local spacing = scope:Computed(function(use)
		return 5 * (use(props.Scale) or 1)
	end)
	local labelHeight = scope:Computed(function(use)
		return 25 * (use(props.Scale) or 1)
	end)
	return scope:New("Frame") {
		Name = "Field",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		[Fusion.Children] = Fusion.Child {
			list(scope, false, spacing),
			if props.Label ~= nil then label(scope, props.Label, labelHeight) else {},
			scope:New("Frame") {
				Name = "Content",
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				[Fusion.Children] = props.Content,
			},
		},
	}
end

function Layout.Table(scope: types.Scope, props: TableProps): Instance
	local size = if props.AutoWidth then UDim2.new() else UDim2.fromScale(1, 0)
	local automaticSize = if props.AutoWidth then Enum.AutomaticSize.XY else Enum.AutomaticSize.Y
	local spacing = scope:Computed(function(use)
		return (props.Spacing or 15) * (use(props.Scale) or 1)
	end)
	local rowSpacing = scope:Computed(function(use)
		return (props.RowSpacing or 0) * (use(props.Scale) or 1)
	end)
	local labelHeight = scope:Computed(function(use)
		return (props.HeaderHeight or 50) * (use(props.Scale) or 1)
	end)
	local rowPadding = scope:Computed(function(use)
		return UDim.new(0, (props.RowPadding or 12.5) * (use(props.Scale) or 1))
	end)
	local padding = scope:Computed(function(use)
		return UDim.new(0, (props.Padding or 15) * (use(props.Scale) or 1))
	end)

	local function cells(cellScope: types.Scope, content: { [string]: Fusion.Child? }, header: boolean?): Instance
		local children: { Fusion.Child } = { list(cellScope, true, spacing) }
		for index, column in props.Columns do
			table.insert(
				children,
				cellScope:New("Frame") {
					Name = tostring(column.key),
					Size = cellScope:Computed(function(use)
						local width = column.width
						if width == nil then
							return UDim2.new()
						end
						local currentWidth: UDim = use(width)
						return UDim2.new(currentWidth.Scale, currentWidth.Offset * (use(props.Scale) or 1), 0, 0)
					end),
					AutomaticSize = scope:Computed(function(_)
						if column.width ~= nil or column.rightAligned then
							return Enum.AutomaticSize.Y
						else
							return Enum.AutomaticSize.XY
						end
					end),
					BackgroundTransparency = 1,
					LayoutOrder = index,
					[Fusion.Children] = Fusion.Child {
						if column.rightAligned
							then cellScope:New("UIFlexItem") { FlexMode = Enum.UIFlexMode.Fill }
							else {},
						if column.rightAligned
							then cellScope:New("UIListLayout") {
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Right,
								SortOrder = Enum.SortOrder.LayoutOrder,
							}
							else {},
						content[column.key] or {},
					},
				}
			)
		end
		return cellScope:New("Frame") {
			Name = if header then "Headers" else "Cells",
			Size = size,
			AutomaticSize = automaticSize,
			BackgroundTransparency = 1,
			LayoutOrder = if header then 0 else 1,
			[Fusion.Children] = Fusion.Child {
				children,
				if header then cellScope:New("UIPadding") { PaddingLeft = padding, PaddingRight = padding } else {},
			},
		}
	end

	local headers: Fusion.Child = {}
	if props.Headers ~= nil then
		local content: { [string]: Fusion.Child? } = {}
		for key, text in props.Headers do
			if text ~= nil then
				content[key] = label(scope, text, labelHeight)
			end
		end
		headers = cells(scope, content, true)
	end

	return scope:New("Frame") {
		Name = "Table",
		Size = size,
		AutomaticSize = automaticSize,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Visible = if props.HideWhenEmpty
			then scope:Computed(function(use)
				return next(use(props.Rows)) ~= nil
			end)
			else nil,
		[Fusion.Children] = Fusion.Child {
			list(scope, false, rowSpacing),
			headers,
			scope:New("Frame") {
				Name = "Rows",
				Size = size,
				AutomaticSize = automaticSize,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				[Fusion.Children] = Fusion.Child {
					list(scope, false, rowSpacing),
					scope:ForPairs(props.Rows, function(_, rowScope: types.Scope, index: number, row: Row)
						return index,
							rowScope:New("Frame") {
								Name = "Row",
								Size = size,
								AutomaticSize = automaticSize,
								BackgroundColor3 = row.BackgroundColor3,
								BackgroundTransparency = if row.BackgroundColor3 ~= nil then 0 else 1,
								LayoutOrder = row.LayoutOrder or index,
								Visible = row.Visible,
								[Fusion.Children] = Fusion.Child {
									list(
										rowScope,
										false,
										scope:Computed(function(use)
											return if use(row.ChildrenHidden) then 0 else use(spacing)
										end)
									),
									rowScope:New("UIPadding") {
										PaddingTop = rowPadding,
										PaddingBottom = rowPadding,
										PaddingLeft = padding,
										PaddingRight = padding,
									},
									if row.Heading ~= nil then label(rowScope, row.Heading, labelHeight) else {},
									cells(rowScope, row.Cells),
									if row.Children ~= nil
										then rowScope:New("Frame") {
											Name = "Children",
											Size = UDim2.fromScale(1, 0),
											AutomaticSize = Enum.AutomaticSize.Y,
											BackgroundTransparency = 1,
											LayoutOrder = 2,
											[Fusion.Children] = Fusion.Child {
												list(rowScope, false, spacing),
												row.Children or {},
											},
										}
										else {},
								},
							}
					end),
				},
			},
		},
	}
end

function Layout.Dropdown<T>(scope: types.Scope, props: DropdownProps<T>): Instance
	local theme = RedonUI.theme.theme:now()
	local function format(value: T): string
		return if props.Format ~= nil then props.Format(value) else tostring(value)
	end
	local selectedText = scope:Computed(function(use)
		return format(use(props.Selected))
	end)
	local options = scope:Computed(function(use)
		local result: { string } = {}
		for index, value in use(props.Options) do
			result[index] = format(value)
		end
		return result
	end)
	local controls = scope:dropdown {
		Name = "Dropdown",
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, (props.Height or 50) * (use(props.Scale) or 1))
		end),
		BackgroundColor3 = scope:Computed(function(use)
			return if use(props.Disabled) then theme.colors.base else theme.colors.crust
		end),
		BorderColor3 = scope:Computed(function(use)
			return if use(props.Disabled) then theme.colors.overlay0 else theme.colors.white
		end),
		Border = 1,
		CornerRadius = UDim.new(0, 5),
		TextColor3 = theme.colors.text,
		TextScaled = true,
		MaxTextSize = 20,
		FontWeight = Enum.FontWeight.Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnimateSize = false,
		Reactive = true,
		Interactable = scope:Computed(function(use)
			return not use(props.Disabled)
		end),
		Text = selectedText,
		Options = options,
		DropdownHeight = scope:Computed(function(use)
			return use(props.DropdownHeight) or 100
		end),
		RemoveForPadding = scope:Computed(function(use)
			return UDim2.fromOffset(0, 10 * (use(props.Scale) or 1))
		end),
		OnOptionSelected = function(index: number)
			local value = Fusion.peek(props.Options)[index]
			if value ~= nil then
				props.OnSelect(value)
			end
		end,
	}

	local trigger = controls[1] :: GuiObject
	local menu = controls[2] :: GuiObject
	trigger.LayoutOrder = 0
	menu.LayoutOrder = 1
	return scope:New("Frame") {
		Name = "DropdownField",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Visible = props.Visible,
		[Fusion.Children] = Fusion.Child {
			list(
				scope,
				false,
				scope:Computed(function(use)
					return 25 * (use(props.Scale) or 1)
				end)
			),
			controls,
		},
	}
end

return Layout
