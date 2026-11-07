--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../../Packages/fusion")
local RedonUI = require("../../../../../Packages/redon-ui")
local types = require("../../../../types")
local ConfigurationEditor = require("../../../../lib/ConfigurationEditor")
local popup = require("../../../popup")
local createChildren = require("../createChildren")
local controls = require("../controls")

type props = {
	currentContent: Fusion.Value<"settings" | "colors" | "light groups">,
}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Colors
	Creates the main colors panel for the light settings page
]]
return function(scope: types.Scope, props: props)
	local currentTheme = RedonUI.theme.theme:now()
	local viewportSize = scope:Value(Vector2.new(1820, 895))
	local scale = scope:Computed(function(use)
		return use(viewportSize).X / 1820
	end)

	local colors = scope:Computed(function(use)
		local configuration = use(ConfigurationEditor.current)
		if configuration == nil then
			return {}
		end
		return use(configuration.lightSettings.colors)
	end)

	local rows = scope:ForPairs(colors, function(_, scope: types.Scope, key, colorData): (number, createChildren.Row)
		return key,
			{
				BackgroundColor3 = if key % 2 == 0 then currentTheme.colors.mantle else currentTheme.colors.crust,
				Cells = {
					name = controls.textInput(scope, {
						Scale = scale,
						Value = colorData.name,
						Disabled = key < 7,
						OnChange = function(value)
							ConfigurationEditor.updateColorName(key, value)
						end,
					}),
					partColor = controls.colorInput(scope, {
						Scale = scale,
						Value = colorData.partColor,
						OnChange = function(value)
							ConfigurationEditor.updateColor(key, "partColor", value)
						end,
					}),
					lightColor = controls.colorInput(scope, {
						Scale = scale,
						Value = colorData.lightColor,
						OnChange = function(value)
							ConfigurationEditor.updateColor(key, "lightColor", value)
						end,
					}),
					lightoColor = controls.colorInput(scope, {
						Scale = scale,
						Value = colorData.lightoColor,
						OnChange = function(value)
							ConfigurationEditor.updateColor(key, "lightoColor", value)
						end,
					}),
					actions = if key > 6
						then controls.actions(scope, {
							Scale = scale,
							OnDelete = function()
								popup:addPopup(scope, {
									title = "Remove Color",
									description = `Are you sure you want to delete color <b>{scope.peek(colorData.name)}</b>?\n<b>All data will be lost.</b>`,
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
												ConfigurationEditor.removeColor(key)
											end,
											keybind = Enum.KeyCode.Return,
										},
									},
								})
							end,
						})
						else {},
				},
			}
	end)

	return scope:base {
		ClassName = "ScrollingFrame",
		Size = UDim2.fromScale(1, 0.9162011173), -- 1820, 820
		AnchorPoint = Vector2.new(0.5, 1),
		Position = scope:Spring(
			scope:Computed(function(use)
				local activeContent = use(props.currentContent)
				if activeContent == "colors" then
					return UDim2.fromScale(0.5, 1)
				elseif activeContent == "settings" then
					return UDim2.fromScale(1.5, 1)
				else
					return UDim2.fromScale(-1, 1)
				end
			end),
			SPRING_SPEED,
			SPRING_DAMPING
		),
		BackgroundTransparency = 1,
		[Fusion.Out "AbsoluteSize"] = viewportSize :: unknown,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = currentTheme.colors.text,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),

		[Fusion.Children] = Fusion.Child {
			scope:New("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			createChildren.Table(scope, {
				Scale = scale,
				Columns = {
					{ key = "name", width = UDim.new(0, 250) },
					{ key = "partColor", width = UDim.new(0, 250) },
					{ key = "lightColor", width = UDim.new(0, 250) },
					{ key = "lightoColor", width = UDim.new(0, 250) },
					{ key = "actions", rightAligned = true },
				},
				Headers = {
					name = "Name",
					partColor = "Part Color",
					lightColor = "Light Color",
					lightoColor = "Lighto Color",
				},
				RowSpacing = 0,
				Rows = rows,
			}),

			scope:base {
				Size = UDim2.fromScale(1, 0.0914634146),
				BackgroundTransparency = 1,
				LayoutOrder = 4000,

				[Fusion.Children] = {
					scope:textButton {
						Size = UDim2.fromScale(1, 0.6666666667),
						MaxSize = Vector2.new(175, 50),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0, 5),
						Border = 1,
						Text = "Add Color",
						TextScaled = true,
						MaxTextSize = 30,
						FontWeight = Enum.FontWeight.Medium,
						TextXAlignment = Enum.TextXAlignment.Center,
						Reactive = true,

						[Fusion.OnEvent "Activated"] = function()
							ConfigurationEditor.addColor({
								name = "New Color",
								partColor = Color3.new(1, 1, 1),
								lightColor = Color3.new(1, 1, 1),
								lightoColor = Color3.new(1, 1, 1),
							})
						end,
					},
				},
			},
		},
	}
end
