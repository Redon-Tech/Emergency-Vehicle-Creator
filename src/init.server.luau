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
