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

local VERSION = "3.0.0-alpha.1"
local IS_DEV = true
if IS_DEV then
	game:GetService("LogService"):ClearOutput()
end

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
-- Setup Logging
local log = require(script.log)
log.verbosity = if IS_DEV then log.level.debug else log.level.error

-- Setup Version
local version = require(script.version)
version.currentVersion = VERSION
version.currentVer = version:parseVersion(VERSION)
version:checkVersion()
local versionDisplay = VERSION
if isRBXM then
	if version.currentVer.build == nil then
		versionDisplay ..= "+local"
	else
		versionDisplay ..= ".local"
	end
end

-- Main Requirements
local pluginSettings = require(script.settings)
local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(script.types)

-- Setup Scope
local utils = require(script.utils)
local menu = require(script.Components.menu)
local viewport = require(script.Components.viewport)
local main = require(script.Components.main)
local popup = require(script.Components.popup)
local colorPicker = require(script.Components.base.colorPicker)
local scope = Fusion.scoped(Fusion, RedonUI.Util, RedonUI.Components, utils, {
	menu = menu,
	viewport = viewport,
	mainWidget = main,
	popup = popup,
})

table.insert(scope, function()
	log.debug("Cleaning vehicle cache")
	local cache = require(script.vehicle).cache
	for i, v in pairs(cache) do
		v.vehicle:Destroy()
		v.customization:Destroy()
		cache[i] = nil
	end
end)

pluginSettings:setup(scope)
if scope.peek(pluginSettings.values.debugMode) then
	log.verbosity = log.level.debug
end

-- Values
local enabled = scope:Value(isRBXM and IS_DEV)
local mode = scope:Value("menu" :: types.mode)
local currentVehicle: Fusion.Value<Model | string?> = scope:Value(nil)
local possibleVehicle: Fusion.Value<Model?> = scope:Value(nil)
local returnTo = scope:Value("menu" :: types.returnTo)
local theme = scope.peek(pluginSettings.values.theme)

-- UI Initialization
local activeScope: Fusion.Scope<typeof(scope)>? = nil
local function initUI()
	local themeToUse = nil
	if theme == "Auto" then
		if settings().Studio.Theme.Name == "Dark" then
			themeToUse = "Mocha"
		else
			themeToUse = "Latte"
		end
	else
		themeToUse = theme
	end

	activeScope = scope:innerScope()
	RedonUI.theme.theme:is(RedonUI.theme[themeToUse:lower()]):during(function()
		if activeScope == nil then
			return {}
		end
		colorPicker(scope, { id = "evcColorPicker", initialColor = Color3.fromRGB(255, 255, 255) })
		local popupFrame, isPopupShown = activeScope.popup:container(scope)
		local menuWidget = activeScope:menu {
			Name = name,
			Version = versionDisplay,

			Enabled = enabled,
			Mode = mode :: any, -- ROBLOX FIX YOUR DAMN TYPE SOLVER k thx love u bye
			CurrentVehicle = currentVehicle,
			PossibleVehicle = possibleVehicle,
			ReturnTo = returnTo :: any,
		} :: DockWidgetPluginGui -- idk man, I am tired
		local mainWidget = activeScope:mainWidget {
			Name = name,
			Version = versionDisplay,

			Enabled = enabled,
			Mode = mode :: any,
			CurrentVehicle = currentVehicle,
			PossibleVehicle = possibleVehicle,
			ReturnTo = returnTo :: any,
			PopupShown = isPopupShown,

			[Fusion.Children] = {
				popupFrame,
			},
		} :: DockWidgetPluginGui
		local viewportGui = activeScope:viewport {
			Name = name,
			Version = versionDisplay,

			Enabled = enabled,
			Mode = mode :: any, -- ROBLOX FIX YOUR DAMN TYPE SOLVER k thx love u bye
			CurrentVehicle = currentVehicle,
			ReturnTo = returnTo :: any,
		}
		viewportGui.Parent = game:GetService("CoreGui")

		menuWidget:BindToClose(function()
			enabled:set(false)
		end)

		mainWidget:BindToClose(function()
			enabled:set(false)
		end)

		return {
			menuWidget,
			viewportGui,
		} :: { Instance }
	end)
end
initUI()

-- Theme Handling
settings().Studio.ThemeChanged:Connect(function()
	if activeScope and theme == "Auto" then
		activeScope:doCleanup()
		activeScope = nil
		initUI()
	end
end)

scope:Observer(pluginSettings.values.theme):onChange(function()
	if activeScope then
		theme = scope.peek(pluginSettings.values.theme)
		activeScope:doCleanup()
		activeScope = nil
		initUI()
	end
end)

-- Button Handling
button:SetActive(scope.peek(enabled)) -- If the plugin is reloaded, the button state should be reset
scope:Observer(enabled):onChange(function()
	button:SetActive(Fusion.peek(enabled))
end)

table.insert(
	scope,
	button.Click:Connect(function()
		enabled:set(not Fusion.peek(enabled))
	end)
)

--[[

	Cleanup

]]

plugin.Unloading:Connect(function()
	scope:doCleanup()
end)
