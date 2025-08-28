-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent
local plugin = root:FindFirstAncestorWhichIsA("Plugin") :: Plugin

local Fusion = require(root.Packages.fusion)
local types = require(root.Plugin.types)

type props = {
	pluginGuiId: string,
	InitialDockState: Enum.InitialDockState?,
	InitialEnabled: boolean?,
	InitialEnabledShouldOverrideRestore: boolean?,
	FloatingXSize: number?,
	FloatingYSize: number?,
	MinWidth: number?,
	MinHeight: number?,

	Title: Fusion.UsedAs<string>,
	Enabled: Fusion.UsedAs<boolean>,
	[Fusion.SpecialKey]: unknown,
}

--[[
	Widget
	Creates a DockWidgetPluginGui
]]
return function(scope: types.Scope, props: props)
	local pluginGuiId = scope.EatValue(props, "pluginGuiId") :: string
	local InitialDockState = scope.EatValue(props, "InitialDockState") :: Enum.InitialDockState?
	local InitialEnabled = scope.EatValue(props, "InitialEnabled") :: boolean?
	local InitialEnabledShouldOverrideRestore = scope.EatValue(props, "InitialEnabledShouldOverrideRestore") :: boolean?
	local FloatingXSize = scope.EatValue(props, "FloatingXSize") :: number?
	local FloatingYSize = scope.EatValue(props, "FloatingYSize") :: number?
	local MinWidth = scope.EatValue(props, "MinWidth") :: number?
	local MinHeight = scope.EatValue(props, "MinHeight") :: number?
	local widget = plugin:CreateDockWidgetPluginGui(
		pluginGuiId,
		DockWidgetPluginGuiInfo.new(
			InitialDockState or Enum.InitialDockState.Right,
			InitialEnabled or false,
			InitialEnabledShouldOverrideRestore or false,
			FloatingXSize or 0,
			FloatingYSize or 0,
			MinWidth or 0,
			MinHeight or 0
		)
	)
	widget.Name = pluginGuiId
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	return scope:Hydrate(widget)(scope.CombineProperties({
		Title = props.Title,
		Enabled = props.Enabled,

		[Fusion.Children] = props[Fusion.Children],
	}, props))
end
