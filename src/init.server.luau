--# selene: allow(global_usage)
--[[
	 _____               _                     _______                 _
	|  __ \             | |                   |__   __|               | |
	| |__) |   ___    __| |   ___    _ __        | |      ___    ___  | |__
	|  _  /   / _ \  / _  |  / _ \  |  _ \       | |     / _ \  / __| |  _ \
	| | \ \  |  __/ | (_| | | (_) | | | | |      | |    |  __/ | (__  | | | |
	|_|  \_\  \___|  \__,_|  \___/  |_| |_|      |_|     \___|  \___| |_| |_|
	Emergency Vehicle Creator V3
	Plugin Loader
	MIT License
--]]

if not game:GetService("RunService"):IsEdit() then
	return
end

local VERSION = "3.0-alpha.1"

--[[

	Plugin Initialization

]]

--selene: allow(incorrect_standard_library_use)
local isRBXM = plugin.Name:find(".rbxm") ~= nil

local function getName(name: string): string
	if isRBXM == true then
		name ..= " (RBXM)"
	end
	return name
end

local name = getName("Emergency Vehicle Creator V3")
local description = "Easily create emergency vehicles with this plugin!"
local pluginIcon = "http://www.roblox.com/asset/?id=9953243250"
local buttonName = getName("EVC")

local button: PluginToolbarButton
-- TODO: Find a better way to make a global toolbar
if _G.RTPlugins and typeof(_G.RTPlugins) == "table" then
	if _G.RTPlugins.Buttons[name] then
		button = _G.RTPlugins.Buttons[name]
	else
		_G.RTPlugins.Buttons[name] = _G.RTPlugins.ToolBar:CreateButton(buttonName, description, pluginIcon)
		button = _G.RTPlugins.Buttons[name]
	end
else
	_G.RTPlugins = {
		ToolBar = plugin:CreateToolbar("Redon Tech Plugins"),
		Buttons = {},
	}

	_G.RTPlugins.Buttons[name] = _G.RTPlugins.ToolBar:CreateButton(buttonName, description, pluginIcon)
	button = _G.RTPlugins.Buttons[name]
end
button.ClickableWhenViewportHidden = true

--[[

	Run

]]

local root = script.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])

local menu = require(script.Components.menu)

local scope = Fusion.scoped(Fusion, RedonUI.Util, RedonUI.Components, {
	menu = menu,
})

local enabled = scope:Value(false)
local mode = scope:Value("menu")

local menuWidget = scope:menu {
	Name = name,
	Version = VERSION,

	Enabled = enabled,
	Mode = mode,
}

menuWidget:BindToClose(function()
	enabled:set(false)
end)

button:SetActive(scope.peek(enabled)) -- If the plugin is reloaded, the button state should be reset
scope:Observer(enabled):onChange(function()
	button:SetActive(Fusion.peek(enabled))
end)

button.Click:Connect(function()
	enabled:set(not Fusion.peek(enabled))
end)

--[[

	Cleanup

]]

plugin.Unloading:Connect(function()
	scope:doCleanup()
end)
