-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local types = require(root.Plugin.types)

local widget = require(script.Parent.base.widget)
local components = {
	widget = widget,
}

local home = require(script.home)
local help = require(script.help)
local credits = require(script.credits)
local panels = {
	home = home,
	help = help,
	credits = credits,
}

type props = {
	Name: string,
	Version: string,

	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.UsedAs<types.mode>,
}

--[[
	Menu
	Creates the main menu for the plugin
]]
return function(baseScope: types.Scope, props: props): DockWidgetPluginGui
	local scope = Fusion.innerScope(baseScope, components)

	local currentPanel = scope:Value("Home")

	return scope:widget {
		pluginGuiId = `{props.Name}_Menu`,
		InitialDockState = Enum.InitialDockState.Float,
		InitialEnabled = false,
		MinHeight = 450,
		MinWidth = 240,
		FloatingYSize = 450,
		FloatingXSize = 240,
		InitialEnabledShouldOverrideRestore = true,

		Title = scope:Computed(function(use)
			return `EVC {use(currentPanel)} ({use(props.Version)})`
		end),

		Enabled = scope:Computed(function(use)
			return use(props.Enabled) and use(props.Mode) == "menu"
		end),

		[Fusion.Children] = {
			scope:base {
				Name = "Main",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor = "base",

				[Fusion.Children] = {
					scope:New("Frame") {
						Name = "Container",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromOffset(400, 750),
						BackgroundTransparency = 1,

						[Fusion.Children] = {
							scope:New("UIScale") { Scale = 0.6 },

							-- selene: allow(shadowing)
							scope:ForValues(panels, function(_, scope: typeof(scope), panel)
								return panel(scope, {
									CurrentPanel = currentPanel,
									Version = props.Version,
								})
							end),
						},
					},
				},
			},
		},
	}
end
