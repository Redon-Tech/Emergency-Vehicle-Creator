-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)

local widget = require(script.Parent.base.widget)
local topbar = require(script.topbar)
local components = {
	widget = widget,
	topbar = topbar,
}

local functions = require(script.functions)
local sirens = require(script.sirens)

type props = {
	Name: string,
	Version: string,

	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentVehicle: Fusion.Value<Model | string?>,

	ReturnTo: Fusion.Value<types.returnTo>,
}

--[[
	Main
	Creates the main app for the plugin
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local scope = Fusion.innerScope(baseScope, components)
	local currentTheme = RedonUI.theme.theme:now()

	local currentPanel = scope:Value("Vehicle Setup")
	local currentPage = scope:Value(nil)
	local unsavedChanges = scope:Value(false)

	local AbsoluteSize = scope:Value(Vector2.one)
	return scope:widget {
		pluginGuiId = `{props.Name}_Main`,
		InitialDockState = Enum.InitialDockState.Float,
		InitialEnabled = false,
		FloatingYSize = 648,
		FloatingXSize = 1152,
		InitialEnabledShouldOverrideRestore = true,
		[Fusion.Out "AbsoluteSize"] = AbsoluteSize,

		Title = scope:Computed(function(use)
			return `EVC {use(currentPanel)} ({use(props.Version)}) {if use(unsavedChanges)
				then "Unsaved Changes"
				else ""} 1152x648`
		end),

		Enabled = scope:Computed(function(use)
			local enable = use(props.Enabled) == true and use(props.Mode) == "main"
			if enable and scope.peek(props.CurrentVehicle) ~= nil then
				currentPanel:set("Vehicle Setup")
				currentPage:set("Functions")
			elseif enable then
				currentPanel:set("ELS Setup")
				currentPage:set("Flashers")
			end
			return enable
		end),

		[Fusion.Children] = {
			scope:base {
				Name = "Main",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = currentTheme.colors.base,

				[Fusion.Children] = {
					scope:topbar {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						ReturnTo = props.ReturnTo,
						Mode = props.Mode,
					},

					functions(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
					}),

					sirens(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
					}),
				},
			},

			scope:textLabel {
				Name = "Version",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 5, 1, -5),
				Size = UDim2.fromOffset(240, 12),
				BackgroundTransparency = 1,

				Text = props.Version,
				TextSize = 9,
				FontWeight = Enum.FontWeight.Regular,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				TextTransparency = 0.5,
			},

			props[Fusion.Children],
		},
	}
end
