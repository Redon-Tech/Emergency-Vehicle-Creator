--#selene: allow(shadowing)
-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local popup = require(root.Plugin.Components.popup)
local chassisHandler = require(root.Plugin.chassisHandler)

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
}

--[[
	Flashers
	Creates the flashers screen for the main app
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()

	local currentConfiguration = nil
	local colors: Fusion.Value<{ chassisHandler.color }> = scope:Value({})
	local currentColor: Fusion.Value<number> = scope:Value(1)

	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				colors:set(currentConfiguration.lightSettings.colors)
			end
		end
	end)

	return scope:base {
		Name = "Flashers",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = currentTheme.colors.mantle,
		ClipsDescendants = true,

		[Fusion.Children] = {
			scope:base {
				ClassName = "ScrollingFrame",
				Name = "Header",
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 0.0555555556),
				BackgroundColor3 = currentTheme.colors.mantle,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.X,

				[Fusion.Children] = Fusion.Child {
					scope:New "UIListLayout" {
						Padding = UDim.new(0.0078125, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					scope:ForPairs(colors, function(_, scope: typeof(scope), key: number, value: chassisHandler.color)
						local colorName = if value.name == "Purple" then "Mauve" else value.name
						local color = if currentTheme.colors[colorName] ~= nil
							then currentTheme.colors[colorName]
							else value.lightColor
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
									return if use(currentColor) == key then currentTheme.colors.base else color
								end),
								TextColor3 = scope:Computed(function(use)
									return if use(currentColor) == key then currentTheme.colors.mantle else color
								end),
								LayoutOrder = key,
							}
					end),
				},
			},
		},
	}
end
