--#selene: allow(shadowing)
-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)
local log = require(root.Plugin.log)
local colorPicker = require(root.Plugin.Components.base.colorPicker)

export type option = {
	type: "select",
	layoutOrder: number,
	options: Fusion.UsedAs<{ [any]: unknown }>,
	initialValue: any,
	OverrideXSize: number?,
	disabled: boolean?,
} | {
	type: "string",
	layoutOrder: number,
	initialValue: string,
	OverrideXSize: number?,
	disabled: boolean?,
} | {
	type: "keycode",
	layoutOrder: number,
	initialValue: Enum.KeyCode,
	OverrideXSize: number?,
	disabled: boolean?,
} | {
	type: "number",
	layoutOrder: number,
	initialValue: number,
	OverrideXSize: number?,
	disabled: boolean?,
} | {
	type: "button",
	layoutOrder: number,
	text: Fusion.UsedAs<string>,
	OverrideXSize: number?,
	callback: () -> (),
	disabled: boolean?,
} | {
	type: "color",
	layoutOrder: number,
	initialValue: Color3,
	OverrideXSize: number?,
	label: string,
	disabled: boolean?,
}

export type childOption = {
	options: { option },
	onOptionChange: ((key: number, newValue: any?) -> ())?,
	onEdit: (() -> ())?,
	onDownload: (() -> ())?,
	onDelete: (() -> ())?,
}

local function getSize(data: option): number
	return if data.OverrideXSize ~= nil
		then data.OverrideXSize
		elseif data.type == "number" then 50
		elseif data.type == "button" then 200
		else 250
end

--[[
	createChildren
	A function that will create the required children for a list in the main app
]]
local function createChildren(
	scope: types.Scope,
	props: {
		options: Fusion.UsedAs<{ option }>,

		onOptionChange: ((key: number, newValue: any?) -> ())?,
		onEdit: (() -> ())?,
		onDownload: (() -> ())?,
		onDelete: (() -> ())?,

		baseSize: number,
		rowSize: Fusion.Value<number>,
	}
)
	local currentTheme = RedonUI.theme.theme:now()
	local isTrashHovered = scope:Value(false)
	local isDownloadHovered = scope:Value(false)
	local maxOptionsSize = 1820 - 15
	if props.onEdit ~= nil then
		maxOptionsSize = maxOptionsSize - 200 - 15
	end
	if props.onDelete ~= nil then
		maxOptionsSize = maxOptionsSize - 40 - 15
	end
	if props.onDownload ~= nil then
		maxOptionsSize = maxOptionsSize - 36 - 15
	end
	if props.baseSize < 70 then
		maxOptionsSize = maxOptionsSize - 35
	end
	local maxButtonSize = 1820 - maxOptionsSize
	local rows = { {} }
	local rowMeta = { { total = 0 } }
	local currentRow = 1
	local currentRowSize = maxOptionsSize
	for key, data in scope.peek(props.options) do
		local size = getSize(data)
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
			Position = UDim2.fromScale(if props.baseSize < 70 then 0.0274725274725 else 0.0082417582, 0),
			BackgroundTransparency = 1,
			Name = "Options",

			[Fusion.Children] = Fusion.Child {
				scope:New("UIListLayout") {
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
								return UDim2.fromScale(1, props.baseSize / use(props.rowSize))
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
									local size = getSize(data)

									local baseProps = {
										Size = UDim2.fromScale(
											size / maxOptionsSize,
											(if props.baseSize < 70 then 45 else 50) / use(props.rowSize)
										),
										BackgroundColor3 = currentTheme.colors.crust,
										CornerRadius = UDim.new(0, 5),
										Border = 1,
										TextScaled = true,
										MaxTextSize = 20,
										FontWeight = Enum.FontWeight.Regular,
										LayoutOrder = data.layoutOrder,
									}
									if data.disabled == true then
										baseProps.Interactable = false
										baseProps.BackgroundColor3 = currentTheme.colors.base
										baseProps.BorderColor3 = currentTheme.colors.overlay0
									end
									local textBaseProps = {
										MaxSize = Vector2.new(300, 50),
										PaddingBottom = UDim.new(0.2, 0),
										PaddingTop = UDim.new(0.2, 0),
										PaddingLeft = UDim.new(10 / size, 0),
										PaddingRight = UDim.new(10 / size, 0),
									}
									if data.type == "string" then
										local value = scope:Value(data.initialValue)
										return key,
											scope:textBox(scope.CombineProperties(baseProps, textBaseProps, {
												Text = data.initialValue,
												[Fusion.Out "Text"] = value :: unknown,
												TextXAlignment = Enum.TextXAlignment.Left,
												[Fusion.OnEvent "FocusLost"] = function()
													if props.onOptionChange then
														props.onOptionChange(data.layoutOrder, scope.peek(value))
													end
												end,
											}))
									elseif data.type == "keycode" then
										local value = scope:Value(data.initialValue)
										return key,
											scope:textBox(scope.CombineProperties(baseProps, textBaseProps, {
												Text = data.initialValue.Name,
												[Fusion.Out "Text"] = value :: unknown,
												TextXAlignment = Enum.TextXAlignment.Left,
												[Fusion.OnEvent "FocusLost"] = function()
													local actualValue = scope.peek(value)
													local success, result = pcall(function()
														return (Enum.KeyCode :: any)[actualValue]
													end)
													if success then
														actualValue = result
													else
														log.warn("Unable to serialize keycode", result)
														return
													end

													if props.onOptionChange then
														props.onOptionChange(data.layoutOrder, actualValue)
													end
												end,
											}))
									elseif data.type == "number" then
										local value = scope:Value(data.initialValue)
										return key,
											scope:textBox(scope.CombineProperties(baseProps, textBaseProps, {
												Text = data.initialValue,
												[Fusion.Out "Text"] = value :: unknown,
												TextXAlignment = Enum.TextXAlignment.Center,
												[Fusion.OnEvent "FocusLost"] = function()
													if props.onOptionChange then
														props.onOptionChange(
															data.layoutOrder,
															tonumber(scope.peek(value))
														)
													end
												end,
											}))
									elseif data.type == "color" then
										local value = scope:Value(data.initialValue)
										local isHovered = scope:Value(false)
										return key,
											scope:textButton(scope.CombineProperties(baseProps, {
												MaxSize = Vector2.new(300, 50),
												TextLabelSize = UDim2.fromScale(1, 1),
												Text = scope:Computed(function(use)
													local currentValue = use(value)
													return ("%d, %d, %d"):format(
														currentValue.R * 255,
														currentValue.G * 255,
														currentValue.B * 255
													)
												end),
												TextXAlignment = Enum.TextXAlignment.Left,
												[Fusion.OnEvent "Activated"] = function()
													local newColor = colorPicker(scope, {
														id = "evcColorPicker",
														initialColor = scope.peek(value),
													})
													if newColor then
														value:set(newColor)
														if props.onOptionChange then
															props.onOptionChange(data.layoutOrder, newColor)
														end
													end
												end,
												Reactive = true,

												MouseEnter = function()
													isHovered:set(true)
												end,
												MouseLeave = function()
													isHovered:set(false)
												end,

												[Fusion.Children] = {
													scope:New("UIPadding") {
														PaddingTop = UDim.new(0.2, 0),
														PaddingBottom = UDim.new(0.2, 0),
														PaddingLeft = UDim.new(10 / size, 0),
														PaddingRight = UDim.new(10 / size, 0),
													},

													scope:base {
														Size = UDim2.fromScale(0.1304347826, 1),
														Position = UDim2.fromScale(1, 0.5),
														AnchorPoint = Vector2.new(1, 0.5),
														CornerRadius = UDim.new(1, 0),
														BackgroundColor3 = value,

														[Fusion.Children] = {
															scope:New("UIAspectRatioConstraint") {
																AspectRatio = 1,
															},
														},
													},
												},
											}))
									elseif data.type == "button" then
										return key,
											scope:textButton(scope.CombineProperties(baseProps, {
												MaxSize = Vector2.new(300, 50),
												Text = data.text,
												TextXAlignment = Enum.TextXAlignment.Center,
												[Fusion.OnEvent "Activated"] = function()
													data.callback()
												end,
												Reactive = true,
											}))
									elseif data.type == "select" then
										local value = scope:Value(data.initialValue)
										local absoluteSize = scope:Value(Vector2.one)
										return key,
											createDropdown(
												scope,
												scope.CombineProperties(baseProps, {
													DropdownHeight = 100,
													Options = data.options,
													Text = value,
													TextXAlignment = Enum.TextXAlignment.Left,
													Position = UDim2.fromScale(
														(
															rowMeta[rowKey][key]
															- size
															- (if props.baseSize < 70 then -25 else 15)
														) / maxOptionsSize,
														0
													),
													[Fusion.Out "AbsoluteSize"] = absoluteSize,
													DropdownYOffset = UDim.new(0, use(absoluteSize).Y + 25),
													RemoveForPadding = UDim2.fromOffset(0, 10),

													OnOptionSelected = function(_, v)
														value:set(v)
														if props.onOptionChange then
															props.onOptionChange(data.layoutOrder, v)
														end
													end,
												})
											)
									end
									return key, {} :: any
								end),
							},
						}
				end),
			},
		},
		scope:base {
			Size = UDim2.fromScale(maxOptionsSize / 1820, 1), -- 1345
			Position = UDim2.fromScale(0.0082417582, 0),
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

				if props.onEdit ~= nil
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
				if props.onDelete ~= nil
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
				if props.onDownload ~= nil
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

return function(
	scope: types.Scope,
	props: {
		options: Fusion.UsedAs<{ option }>,
		childOptions: Fusion.UsedAs<{ childOption }>?,

		onOptionChange: ((key: number, newValue: any?) -> ())?,
		onEdit: (() -> ())?,
		onDownload: (() -> ())?,
		onDelete: (() -> ())?,

		baseSize: number?,
		actualTableSize: Fusion.Value<Vector2>?,
		rowSize: Fusion.Value<number>,
	}
): Fusion.Child
	if props.childOptions == nil or props.actualTableSize == nil then
		local baseSize = props.baseSize or 75
		return createChildren(scope, {
			options = props.options,
			onOptionChange = props.onOptionChange,
			onEdit = props.onEdit,
			onDownload = props.onDownload,
			onDelete = props.onDelete,
			baseSize = baseSize,
			rowSize = props.rowSize,
		})
	end

	local childOptions = scope:Computed(function(use)
		local currentOptions = use(props.childOptions)
		local firstOption: childOption = {
			options = props.options,
			onOptionChange = props.onOptionChange,
			onEdit = props.onEdit,
			onDownload = props.onDownload,
			onDelete = props.onDelete,
		}
		table.insert(currentOptions, 1, firstOption)
		return currentOptions
	end)
	local allRowSize = {}

	return Fusion.Child {
		scope:New("UIListLayout") {
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		scope:ForPairs(childOptions, function(_, scope: typeof(scope), key: number, value: childOption)
			local thisRowSize = scope:Value(if key == 1 then 75 else 62)
			scope:Observer(thisRowSize):onChange(function()
				local this = scope.peek(thisRowSize)
				allRowSize[key] = this
				local total = 0
				for _, v in ipairs(allRowSize) do
					total += v
				end
				props.rowSize:set(total)
			end)
			return key,
				scope:base {
					Size = UDim2.fromScale(1, 0),
					BackgroundTransparency = 1,
					LayoutOrder = key,
					AutomaticSize = Enum.AutomaticSize.Y,
					ZIndex = key,

					[Fusion.Children] = {
						scope:base {
							Size = scope:Computed(function(use)
								return UDim2.new(1, 0, 0, (use(thisRowSize) / 820) * use(props.actualTableSize).Y)
							end),
							BackgroundTransparency = 1,

							[Fusion.Children] = createChildren(scope, {
								options = value.options,

								onOptionChange = value.onOptionChange,
								onEdit = value.onEdit,
								onDownload = value.onDownload,
								onDelete = value.onDelete,

								baseSize = scope.peek(thisRowSize),
								rowSize = thisRowSize,
							}),
						},
					},
				}
		end),
	}
end
