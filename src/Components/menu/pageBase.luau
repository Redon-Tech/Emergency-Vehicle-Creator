-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)

type props = {
	Name: string,

	PrimaryColor: Fusion.UsedAs<"Primary" | "Alternate">?,
	RowSize: Fusion.UsedAs<UDim2>,
	Rows: Fusion.UsedAs<{ [number]: Fusion.Child | string }>,
	AutomaticSize: Fusion.UsedAs<Enum.AutomaticSize>?,

	CurrentPanel: Fusion.Value<types.menuPanels>,
}

--[[
	Page Base
	Creates a base page for the main menu
	the home page does not descend from this

	Creates:
		- Title
		- Content
		- GoBack
		- Version
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()
	return scope:base {
		Name = props.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		-- Visible = scope:Computed(function(use)
		-- 	return use(props.CurrentPanel) == use(props.Name)
		-- end),

		[Fusion.Children] = {
			scope:textLabel {
				Name = "Title",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 10),
				Size = UDim2.fromOffset(400, 48),

				Text = props.Name,
				FontWeight = Enum.FontWeight.Bold,
				TextScaled = true,

				TextYAlignment = Enum.TextYAlignment.Top,
			},

			scope:list {
				Name = "Content",
				Size = UDim2.fromOffset(400, 567),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -100),
				BackgroundColor3 = currentTheme.colors.base,
				AlternateColor3 = currentTheme.colors.mantle,
				RowSize = props.RowSize,
				Rows = props.Rows,
				PrimaryColor = props.PrimaryColor,
				AutomaticSize = props.AutomaticSize,
				CanvasGroup = false,
			},

			scope:textButton {
				Name = "GoBack",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -25),
				Size = UDim2.fromOffset(350, 50),
				BackgroundColor3 = currentTheme.colors.crust,
				Border = 3,
				CornerRadius = UDim.new(0, 15),
				Text = "Go Back",
				FontWeight = Enum.FontWeight.Medium,
				Shadow = true,
				ShadowColor3 = currentTheme.colors.crust,
				TextSize = 35,
				Reactive = true,

				[Fusion.OnEvent "Activated"] = function()
					props.CurrentPanel:set("Home")
				end,
			},
		},
	}
end
