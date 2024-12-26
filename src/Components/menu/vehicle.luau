-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local types = require(root.Plugin.types)
local vehicle = require(root.Plugin.vehicle)
local assets = require(root.Plugin.assets)

local pageBase = require(script.Parent.pageBase)
local components = {
	pageBase = pageBase,
}

type props = {
	CurrentPanel: Fusion.Value<types.menuPanels>,
	Version: string,
	CurrentVehicle: Fusion.Value<Instance | string?>,
	Mode: Fusion.Value<types.mode>,
}

--[[
	Vehicle
	Creates a vehicle page for the main menu
]]
return function(baseScope: types.Scope, props: props)
	local scope = Fusion.innerScope(baseScope, components)

	-- Components to put inside the list
	local extraComponents = {}

	for key, value in pairs(vehicle.vehicles) do
		local isHovered = scope:Value(false)
		extraComponents[value.order] = scope:base {
			ClassName = "TextButton",
			Name = key,
			Size = UDim2.fromOffset(400, 100),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "",

			[Fusion.Children] = {
				scope:New("UIPadding") {
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				},

				scope:base {
					ClassName = "ImageLabel",
					Size = UDim2.fromOffset(80, 80),
					Position = UDim2.fromScale(0, 0.5),
					AnchorPoint = Vector2.new(0, 0.5),
					Image = value.icon,
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Crop,
				},

				scope:textLabel {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -52, 0, 0),
					Size = UDim2.new(1, -145, 1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,

					Text = `<font weight="medium" size="30">{key}</font>\n{value.credits}\n{value.outfitter}`,

					RichText = true,
					TextSize = 20,
					TextWrapped = true,
					FontWeight = Enum.FontWeight.Regular,

					TextYAlignment = Enum.TextYAlignment.Top,
					TextXAlignment = Enum.TextXAlignment.Left,
				},

				scope:iconButton {
					ClassName = "ImageLabel",
					Size = UDim2.fromOffset(60.9, 60.9),
					Position = UDim2.fromScale(1, 0.5),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Image = scope:Computed(function(use)
						return if use(isHovered)
							then assets.images.redonUI.createFilled
							else assets.images.redonUI.create
					end),
					ScaleType = Enum.ScaleType.Fit,
					Reactive = true,

					MouseEnter = function()
						isHovered:set(true)
					end,

					MouseLeave = function()
						isHovered:set(false)
					end,

					[Fusion.OnEvent "Activated"] = function()
						props.CurrentVehicle:set(key)
						props.Mode:set("viewport")
					end,
				},
			},
		}
	end

	return scope:pageBase {
		Name = "Vehicle",
		PrimaryColor = "Alternate",
		RowSize = UDim2.fromOffset(400, 0),
		AutomaticSize = Enum.AutomaticSize.Y,

		CurrentPanel = props.CurrentPanel,
		Version = props.Version,

		Rows = extraComponents,
	}
end
