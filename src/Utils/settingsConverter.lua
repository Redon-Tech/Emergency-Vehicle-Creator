--[[
	Redon Tech 2023
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local settingsConverter = {converters = {}}
local pluginRoot = script.Parent.Parent.Parent

--------------------------------------------------------------------------------
-- Types --
--------------------------------------------------------------------------------
type v2_0_0 = {
	LightbarName: string,
	SirenName: string,
	Sirens: {EnumItem:{
		_Type: string,
		Name: string,
		OverrideOtherSounds: boolean,
		Modifiers: {String: {
			Name: string,
			PlayNonModified: boolean,
			PlayOnModifierChange: boolean,
			Delay: number,
		}}?
	}},
	Keybinds: {EnumItem:string},
	ParkMode: boolean,
	Colors: {number:Color3},
	Light: (Instance, number, {number:Color3}) -> nil,
	PluginVersion: string,
}

type v2_1_0 = {
	LightbarName: string,
	AdditionalLightbarLocations: {string:{[number]:string}},
	SirenName: string,
	Sirens: {EnumItem:{
		_Type: string,
		Name: string,
		OverrideOtherSounds: boolean,
		Modifiers: {String: {
			Name: string,
			PlayNonModified: boolean,
			PlayOnModifierChange: boolean,
			Delay: number,
		}}?
	}},
	Keybinds: {EnumItem:string},
	DefaultFunctionState: {string:number},
	Overrides: {string:{string:string|boolean}},
	Colors: {number:Color3},
	Light: (Instance, number, {number:Color3}) -> nil,
	PluginVersion: string,
}

--------------------------------------------------------------------------------
-- Module Functions --
--------------------------------------------------------------------------------

settingsConverter.converters["2_0_0"] = function(settings: ModuleScript, pluginSettings: v2_0_0): ModuleScript
	local newSettingsModule = pluginRoot.src.ExportTemplates.BlankSettings:Clone()
	local originalSource = settings.Source
	local source = newSettingsModule.Source
	source = source:gsub("LightbarName = nil,", `LightbarName = \"{pluginSettings.LightbarName}\",`)
	source = source:gsub("SirenName = nil,", `SirenName = \"{pluginSettings.SirenName}\",`)
	source = source:gsub("Sirens = nil,", "Sirens = {".. originalSource:split("Sirens = {")[2]:split("--")[1])
	source = source:gsub("Keybinds = nil,", "Keybinds = {".. originalSource:split("Keybinds = {")[2]:split("--")[1])
	source = source:gsub("Colors = nil,", "Colors = {".. originalSource:split("Colors = {")[2]:split("--")[1])
	source = source:gsub("Light = nil,", "Light = function".. originalSource:split("Light = function")[2]:split("--")[1])

	source = source:gsub("AdditionalLightbarLocations = nil,", "AdditionalLightbarLocations = {\n\t\tBody = {\n\t\t},\n\t\tMisc = {\n\t\t}\n\t},")
	source = source:gsub("DefaultFunctionState = nil,", "DefaultFunctionState = {\n\t},")
	source = source:gsub("Overrides = nil,", "Overrides = {\n\t\tSirens = {\n\t\t},\n\t\tChassis = {\n\t\t\tParkBrake = \"ParkBrakeOverride\",\n\t\t\tBrake = false,\n\t\t\tReverse = false,\n\t\t}\n\t},")

	newSettingsModule.Source = source
	return newSettingsModule
end

function settingsConverter.convert(settings: ModuleScript)
	local pluginSettings = require(settings)
	local formattedVersion = pluginSettings.PluginVersion:gsub("%.", "_")
	print(formattedVersion, settingsConverter.converters[formattedVersion])

	if settingsConverter.converters[formattedVersion] then
		return settingsConverter.converters[formattedVersion](settings, pluginSettings)
	end

	return
end

return settingsConverter