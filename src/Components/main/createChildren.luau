--#selene: allow(shadowing)
-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)
local log = require(root.Plugin.log)

export type option = {
	layoutOrder: number,
	options: { [any]: unknown }?,
	value: Fusion.UsedAs<any>,
	OverrideXSize: number?,
}

--[[
	createChildren
	A function that will create the required children for a list in the main app
]]
return function(
	scope: types.Scope,
	props: {
		options: { option },
		buttons: { text: string, onClick: () -> () }?,
		childOptions: { { option } }?,

		hasEditButton: boolean?,
		hasDownloadButton: boolean?,
		hasDeleteButton: boolean?,

		onOptionChange: ((key: number, newValue: any?) -> ())?,
		onEdit: (() -> ())?,
		onDownload: (() -> ())?,
		onDelete: (() -> ())?,

		rowSize: Fusion.Value<number>,
	}
): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()
	local isTrashHovered = scope:Value(false)
	local isDownloadHovered = scope:Value(false)
	local maxOptionsSize = 1820 - 15
	if props.hasEditButton then
		maxOptionsSize = maxOptionsSize - 200 - 15
	end
	if props.hasDeleteButton then
		maxOptionsSize = maxOptionsSize - 40 - 15
	end
	if props.hasDownloadButton then
		maxOptionsSize = maxOptionsSize - 36 - 15
	end
	local maxButtonSize = 1820 - maxOptionsSize
	local rows = { {} }
	local rowMeta = { { total = 0 } }
	local currentRow = 1
	local currentRowSize = maxOptionsSize
	for key, data in props.options do
		local size = if tonumber(scope.peek(data.value)) ~= nil
			then 50
			elseif data.OverrideXSize ~= nil then data.OverrideXSize
			else 250
		if currentRowSize < size then
			currentRow = currentRow + 1
			currentRowSize = maxOptionsSize
			props.rowSize:set(scope.peek(props.rowSize) + 75)
			rows[currentRow] = {}
			rowMeta[currentRow] = { total = 0 }
		end
		currentRowSize -= size + 15
		rows[currentRow][key] = data
		rowMeta[currentRow].total += size + 15
		rowMeta[currentRow][key] = rowMeta[currentRow].total
	end

	local dropdownFrames = scope:Value({})
	local function createDropdown(scope: typeof(scope), props: any)
		local dropdown = scope:dropdown(props)
		local currentDropdowns = scope.peek(dropdownFrames)
		table.insert(currentDropdowns, dropdown[2])
		dropdownFrames:set(currentDropdowns)
		return dropdown[1]
	end

	return {
		scope:base {
			Size = UDim2.fromScale(maxOptionsSize / 1820, 1), -- 1345
			Position = UDim2.fromScale(0.0082417582, 0),
			-- AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Name = "Options",

			[Fusion.Children] = Fusion.Child {
				scope:New("UIListLayout") {
					-- Padding = UDim.new(15 / maxOptionsSize, 0),
					-- FillDirection = Enum.FillDirection.Horizontal,
					Padding = scope:Computed(function(use)
						return UDim.new(15 / use(props.rowSize), 0)
					end),
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},

				scope:ForPairs(rows, function(_, scope: typeof(scope), rowKey: number, value: { option })
					return rowKey,
						scope:base {
							Size = scope:Computed(function(use)
								return UDim2.fromScale(1, 75 / use(props.rowSize))
							end),
							BackgroundTransparency = 1,
							LayoutOrder = rowKey,
							[Fusion.Children] = Fusion.Child {
								scope:New("UIListLayout") {
									Padding = UDim.new(15 / maxOptionsSize, 0),
									FillDirection = Enum.FillDirection.Horizontal,
									HorizontalAlignment = Enum.HorizontalAlignment.Left,
									VerticalAlignment = Enum.VerticalAlignment.Center,
									SortOrder = Enum.SortOrder.LayoutOrder,
								},

								scope:ForPairs(value, function(use, scope: typeof(scope), key: number, data: option)
									local value = use(data.value)
									local isNumber = tonumber(value) ~= nil
									local isKeycode = if isNumber == false
										then typeof(value) == "EnumItem" and (value :: EnumItem).EnumType == Enum.KeyCode
										else false
									if isKeycode then
										value = (value :: Enum.KeyCode).Name
									end
									local size = if isNumber
										then 50
										elseif data.OverrideXSize ~= nil then data.OverrideXSize
										else 250

									local newValue = scope:Value(value)
									local baseProps = {
										Size = UDim2.fromScale(size / maxOptionsSize, 50 / use(props.rowSize)),
										BackgroundColor3 = currentTheme.colors.crust,
										CornerRadius = UDim.new(0, 5),
										Border = 1,
										TextScaled = true,
										MaxTextSize = 20,
										FontWeight = Enum.FontWeight.Regular,
										LayoutOrder = data.layoutOrder,
									}
									local absoluteSize = scope:Value(Vector2.one)
									return key,
										if data.options == nil
											then scope:textBox(scope.CombineProperties(baseProps, {
												MaxSize = Vector2.new(300, 50),
												Text = tostring(value),
												[Fusion.Out "Text"] = newValue :: unknown,
												TextXAlignment = if size == 50
													then Enum.TextXAlignment.Center
													else Enum.TextXAlignment.Left,
												PaddingBottom = UDim.new(0.2, 0),
												PaddingTop = UDim.new(0.2, 0),
												PaddingLeft = UDim.new(10 / size, 0),
												PaddingRight = UDim.new(10 / size, 0),
												[Fusion.OnEvent "FocusLost"] = function()
													if isKeycode then
														local success, result = pcall(function()
															return (Enum.KeyCode :: any)[scope.peek(newValue)]
														end)
														if success then
															newValue:set(result)
														else
															log.warn("Unable to serialize keycode", result)
															return
														end
													end
													if isNumber then
														newValue:set(tonumber(scope.peek(newValue)))
													end

													if props.onOptionChange then
														props.onOptionChange(data.layoutOrder, scope.peek(newValue))
													end
												end,
											}))
											else createDropdown(
												scope,
												scope.CombineProperties(baseProps, {
													DropdownHeight = 100,
													Options = data.options,
													Text = use(newValue),
													TextXAlignment = Enum.TextXAlignment.Left,
													Position = UDim2.fromScale(
														(rowMeta[rowKey][key] - size - 15) / maxOptionsSize,
														0
													),
													[Fusion.Out "AbsoluteSize"] = absoluteSize,
													DropdownYOffset = UDim.new(0, use(absoluteSize).Y + 25),
													RemoveForPadding = UDim2.fromOffset(0, 10),

													OnOptionSelected = function(_, v)
														newValue:set(v)
														if props.onOptionChange then
															props.onOptionChange(data.layoutOrder, v)
														end
													end,
												})
											)
								end),
							},
						}
				end),
			},
		},
		scope:base {
			Size = UDim2.fromScale(maxOptionsSize / 1820, 1), -- 1345
			Position = UDim2.fromScale(0.0082417582, 0),
			-- AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Name = "Dropdowns",

			[Fusion.Children] = dropdownFrames,
		},
		scope:base {
			Size = UDim2.fromScale(maxButtonSize / 1820, 1),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.9917582418, 0.5),
			BackgroundTransparency = 1,
			Name = "Buttons",

			[Fusion.Children] = Fusion.Child {
				scope:New("UIListLayout") {
					Padding = UDim.new(15 / maxButtonSize, 0),
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},

				if props.hasEditButton
					then scope:textButton {
						Size = UDim2.fromScale(200 / maxButtonSize, 0.6666666667),
						MaxSize = Vector2.new(200, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						Shadow = true,
						ShadowColor3 = currentTheme.colors.mantle,
						ButtonGlow = true,
						ButtonGlowColor3 = currentTheme.colors.mantle,
						CornerRadius = UDim.new(0, 5),
						Border = 1,
						Text = "Edit",
						TextScaled = true,
						MaxTextSize = 30,
						FontWeight = Enum.FontWeight.Medium,
						TextXAlignment = Enum.TextXAlignment.Center,
						Reactive = true,
						LayoutOrder = 1,

						[Fusion.OnEvent "Activated"] = function()
							if props.onEdit then
								props.onEdit()
							end
						end,
					}
					else {},
				if props.hasDeleteButton
					then scope:iconButton {
						Size = UDim2.fromScale(40 / maxButtonSize, 0.7666666667),
						BackgroundTransparency = 1,
						Image = scope:Computed(function(use)
							return if use(isTrashHovered)
								then assets.images.redonUI.trashFilled
								else assets.images.redonUI.trash
						end),
						Reactive = true,
						ScaleType = Enum.ScaleType.Fit,
						LayoutOrder = 3,

						MouseEnter = function()
							isTrashHovered:set(true)
						end,

						MouseLeave = function()
							isTrashHovered:set(false)
						end,

						[Fusion.OnEvent "Activated"] = function()
							if props.onDelete then
								props.onDelete()
							end
						end,
					}
					else {},
				if props.hasDownloadButton
					then scope:iconButton {
						Size = UDim2.fromScale(36 / maxButtonSize, 0.7666666667),
						BackgroundTransparency = 1,
						Image = scope:Computed(function(use)
							return if use(isDownloadHovered)
								then assets.images.redonUI.downloadFilled
								else assets.images.redonUI.download
						end),
						Reactive = true,
						ScaleType = Enum.ScaleType.Fit,
						LayoutOrder = 2,

						MouseEnter = function()
							isDownloadHovered:set(true)
						end,

						MouseLeave = function()
							isDownloadHovered:set(false)
						end,

						[Fusion.OnEvent "Activated"] = function()
							if props.onDownload then
								props.onDownload()
							end
						end,
					}
					else {},
			},
		},
	}
end
