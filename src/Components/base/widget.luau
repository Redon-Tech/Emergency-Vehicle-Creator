-- Redon Tech Emnergency Vehicle Creator, MIT License
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
}

--[[
	Widget
	Creates a DockWidgetPluginGui
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local widget = plugin:CreateDockWidgetPluginGui(
		props.pluginGuiId,
		DockWidgetPluginGuiInfo.new(
			props.InitialDockState or Enum.InitialDockState.Right,
			props.InitialEnabled or false,
			props.InitialEnabledShouldOverrideRestore or false,
			props.FloatingXSize or 0,
			props.FloatingYSize or 0,
			props.MinWidth or 0,
			props.MinHeight or 0
		)
	)
	widget.Name = props.pluginGuiId
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	return scope:Hydrate(widget) {
		Title = props.Title,
		Enabled = props.Enabled,

		[Fusion.Children] = props[Fusion.Children],
	}
end
