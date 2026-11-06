--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local types = require("../../../../types")
local ChassisHandler = require("../../../../lib/ChassisHandler")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local popup = require("../../../popup")
local createChildren = require("../createChildren")

local function testFunctionName(name: string, functions: { string }, currentDepth: number): string
	local actualName = if currentDepth == 0 then name else `{name} ({currentDepth})`
	local sanitizedName = actualName:gsub("[^%a%d]", "")
	if sanitizedName == "" then
		return testFunctionName("New Function", functions, 0)
	end
	for _, existingName in functions do
		if existingName:gsub("[^%a%d]", "") == sanitizedName then
			return testFunctionName(name, functions, currentDepth + 1)
		end
	end
	return actualName
end

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	currentContent: Fusion.Value<"functions" | "activation" | "patterns">,
	CurrentVehicle: Fusion.Value<Model | string?>,
	actualTableSize: Fusion.Value<Vector2>,
	selectedFunction: Fusion.Value<number?>,
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Functions Page
	Creates the functions page for the functions page
]]
return function(scope: types.Scope, props: props)
	local currentTheme = RedonUI.theme.theme:now()

	local functions = scope:Computed(function(use)
		local currentConfiguration = use(ConfigurationEditor.current)
		if currentConfiguration == nil then
			return {}
		end
		local currentFunctions = use(currentConfiguration.functions)
		if currentFunctions == nil then
			return {}
		end
		return currentFunctions
	end)

	local newFunctionName = scope:Value("")
	return scope:base {
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = scope:Spring(
			scope:Computed(function(use)
				local activeContent = use(props.currentContent)
				if activeContent == "functions" then
					return UDim2.fromScale(0.5, 0.5)
				else
					return UDim2.fromScale(-1, 0.5)
				end
			end),
			SPRING_SPEED,
			SPRING_DAMPING
		),
		BackgroundTransparency = 1,

		[Fusion.Children] = {
			scope:base {
				Size = UDim2.fromScale(1, 0.0558659218),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0145251397),
				BackgroundTransparency = 1,

				[Fusion.Children] = {
					scope:New("UIListLayout") {
						Padding = UDim.new(0.0164835165, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					scope:textBox {
						Size = UDim2.fromScale(0.1648351648, 1),
						MaxSize = Vector2.new(300, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						PlaceholderText = "New Function Name",
						[Fusion.Out "Text"] = newFunctionName,
						TextScaled = true,
						MaxTextSize = 30,
						FontWeight = Enum.FontWeight.Regular,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 1,
						PaddingBottom = UDim.new(0.2, 0),
						PaddingTop = UDim.new(0.2, 0),
						PaddingLeft = UDim.new(0.0333333333, 0),
						PaddingRight = UDim.new(0.0333333333, 0),
					},

					scope:textButton {
						Size = UDim2.fromScale(0.0961538462, 1),
						MaxSize = Vector2.new(175, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Text = "Add",
						TextScaled = true,
						MaxTextSize = 30,
						FontWeight = Enum.FontWeight.Bold,
						LayoutOrder = 2,
						Reactive = true,

						[Fusion.OnEvent "Activated"] = function()
							local currentConfiguration = scope.peek(ConfigurationEditor.current)
							if currentConfiguration == nil then
								return
							end
							local newFunctionName = scope.peek(newFunctionName)
							if newFunctionName == "" then
								newFunctionName = "New Function"
							end

							local newFunctionData = scope.deepCopy(ChassisHandler.defaults.functions)
							newFunctionData.name = newFunctionName
							newFunctionData.weight = #scope.peek(currentConfiguration.functions) + 1

							ConfigurationEditor.addFunction(newFunctionData)
						end,
					},

					scope:textButton {
						Size = UDim2.fromScale(0.0961538462, 1),
						MaxSize = Vector2.new(175, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Text = "Import",
						TextScaled = true,
						MaxTextSize = 30,
						FontWeight = Enum.FontWeight.Bold,
						LayoutOrder = 3,
						Reactive = true,
					},
				},
			},

			scope:list {
				Size = UDim2.fromScale(1, 0.9162011173), -- 895 -75 total 820
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundColor3 = currentTheme.colors.mantle,
				AlternateColor3 = currentTheme.colors.crust,
				RowSize = UDim2.fromScale(1, 0), -- 1820, 75
				PrimaryColor = "Alternate" :: "Alternate",
				CornerRadius = UDim.new(0.0182926829, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Fusion.Out "AbsoluteSize"] = props.actualTableSize,
				Rows = scope:ForPairs(functions, function(_, scope: typeof(scope), key, value): (number, Fusion.Child)
					local rowSize = scope:Value(75)
					local bg = scope:Spring(scope:Value(1), 10, 1)
					bg:setPosition(0)

					return key,
						scope:base {
							Size = scope:Computed(function(use)
								return UDim2.new(1, 0, 0, (use(rowSize) / 820) * use(props.actualTableSize).Y)
							end),
							BackgroundColor3 = currentTheme.colors.surface0,
							BackgroundTransparency = bg,

							[Fusion.Children] = createChildren(scope, {
								rowSize = rowSize,
								options = {
									{
										type = "number",
										value = value.weight,
										focusLost = function(newValue)
											ConfigurationEditor.updateFunctionWeight(key, newValue)
										end,
										layoutOrder = 1,
									},
									{
										type = "string",
										value = value.name,
										focusLost = function(newValue)
											ConfigurationEditor.updateFunctionName(key, newValue)
										end,
										layoutOrder = 2,
									},
								} :: { createChildren.option },

								onEdit = function()
									props.currentContent:set("patterns")
									props.selectedFunction:set(key)
								end,
								onDelete = function()
									popup:addPopup(scope, {
										title = "Delete Function",
										description = "Are you sure you want to delete this function?\n<b>All data will be lost.</b>",
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
													ConfigurationEditor.removeFunction(key)
												end,
											},
										},
									})
								end,
								onDownload = function() end,
							}),
						}
				end),
			},
		},
	}
end
