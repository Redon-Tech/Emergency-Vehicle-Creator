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

local VERSION = "3.0.0-rc.10"
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

-- Setup Logging
local log = require("@self/log")
log.verbosity = if IS_DEV then log.level.debug else log.level.error

-- Setup Version
local VersionHelper = require("@self/lib/VersionHelper")
VersionHelper.currentVersion = VERSION
VersionHelper.currentVer = VersionHelper.parseVersion(VERSION)
VersionHelper:checkVersion()
local versionDisplay = VERSION
if isRBXM then
	versionDisplay ..= "+local"
end

-- Main Requirements
local SettingsHandler = require("@self/lib/SettingsHandler")
local UIState = require("@self/lib/UIState")
local ChassisHandler = require("@self/lib/ChassisHandler")
local ConfigurationEditor = require("@self/lib/ConfigurationEditor")
local SaveLibrary = require("@self/lib/SaveLibrary")
local Fusion = require("./Packages/fusion")
local RedonUI = require("./Packages/redon-ui")

-- Setup Scope
local utils = require("@self/lib/utils")
local menu = require("@self/Components/menu")
local viewport = require("@self/Components/viewport")
local main = require("@self/Components/main")
local popup = require("@self/Components/popup")
local colorPicker = require("@self/Components/base/colorPicker")
local scope = Fusion.scoped(Fusion, RedonUI.Util, RedonUI.Components, utils, {
	menu = menu,
	viewport = viewport,
	mainWidget = main,
	popup = popup,
})

table.insert(scope, function()
	log.debug("Cleaning vehicle cache")
	local cache = require("@self/lib/VehicleHandler").cache
	for i, v in pairs(cache) do
		v.vehicle:Destroy()
		v.customization:Destroy()
		cache[i] = nil
	end
end)

SettingsHandler:setup(scope)
if scope.peek(SettingsHandler.values.debugMode) == true then
	log.verbosity = log.level.debug
end

UIState.init(scope, isRBXM and IS_DEV)
ConfigurationEditor.init(scope)
local migrationReport = SaveLibrary.init(plugin)
for _, failure in migrationReport.failures do
	log.warn("Could not migrate save", failure.name, failure.message)
end

-- Shared UI state
local enabled = UIState.enabled
local mode = UIState.mode
local currentVehicle = UIState.currentVehicle
local possibleVehicle = UIState.possibleVehicle
local returnTo = UIState.returnTo

-- Vehicle state outlives UI scopes, including theme changes.
scope:Observer(currentVehicle):onBind(function()
	UIState.currentPattern:set(nil)
	if scope.peek(ConfigurationEditor.current) ~= nil then
		ConfigurationEditor.unload()
	end
	local vehicle = scope.peek(currentVehicle)
	if typeof(vehicle) == "Instance" then
		local configuration = ChassisHandler:getConfiguration(vehicle)
		if configuration ~= nil then
			ConfigurationEditor.load(configuration)
		else
			log.warn("No vehicle configuration found for current vehicle")
		end
	elseif vehicle == nil then
		ConfigurationEditor.load(ChassisHandler.defaults)
	end
end)

local mainEnabled = scope:Computed(function(use)
	return use(enabled) and use(mode) == "main"
end)
scope:Observer(mainEnabled):onChange(function()
	if not scope.peek(mainEnabled) then
		return
	end
	if scope.peek(currentVehicle) ~= nil then
		UIState.mainPanel:set("Vehicle Setup")
		UIState.mainPage:set("Functions")
	elseif scope.peek(possibleVehicle) == nil then
		UIState.currentPattern:set({ functionId = 1, patternId = 1 })
		UIState.mainPanel:set("ELS Setup")
		UIState.mainPage:set("Flashers")
	end
end)

local theme = scope.peek(SettingsHandler.values.theme)

-- UI Initialization
colorPicker(scope, { id = "evcColorPicker", initialColor = Color3.fromRGB(255, 255, 255) })
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
		local popupFrame, isPopupShown = activeScope.popup:container(scope)
		local menuWidget = activeScope:menu {
			Name = name,
			Version = versionDisplay,

			Enabled = enabled,
			Mode = mode,
			CurrentVehicle = currentVehicle,
			PossibleVehicle = possibleVehicle,
			ReturnTo = returnTo,
		} :: DockWidgetPluginGui
		local mainWidget = activeScope:mainWidget {
			Name = name,
			Version = versionDisplay,

			Enabled = enabled,
			Mode = mode,
			CurrentVehicle = currentVehicle,
			PossibleVehicle = possibleVehicle,
			ReturnTo = returnTo,
			PopupShown = isPopupShown,

			[Fusion.Children] = {
				popupFrame,
			},
		} :: DockWidgetPluginGui
		local viewportGui = activeScope:viewport {
			Name = name,
			Version = versionDisplay,

			Enabled = enabled,
			Mode = mode,
			CurrentVehicle = currentVehicle,
			ReturnTo = returnTo,
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

scope:Observer(SettingsHandler.values.theme):onChange(function()
	if activeScope then
		theme = scope.peek(SettingsHandler.values.theme)
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
