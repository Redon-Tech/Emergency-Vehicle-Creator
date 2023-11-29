local settingsConverter = {converters = {}}
local pluginRoot = script.Parent.Parent.Parent

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

settingsConverter.converters["2_0_0"] = function(settings: ModuleScript, pluginSettings: v2_0_0): ModuleScript
	local newSettings: v2_1_0 = {
		LightbarName = pluginSettings.LightbarName,
		AdditionalLightbarLocations = {},
		SirenName = pluginSettings.SirenName,
		Sirens = pluginSettings.Sirens,
		Keybinds = pluginSettings.Keybinds,
		DefaultFunctionState = {},
		Overrides = {},
		Colors = pluginSettings.Colors,
		Light = pluginSettings.Light,
		PluginVersion = "2.1.0",
	}

	local newSettingsModule = pluginRoot.src.ExportTemplates.Settings:Clone()
	local source = newSettingsModule.Source
	source = source:gsub("LightbarName = \"Lightbar\"", "LightbarName = \"" .. newSettings.LightbarName .. "\"")
	source = source:gsub("SirenName = \"middle\"", "SirenName = \"" .. newSettings.SirenName .. "\"")
	local sirensString = "Sirens = {\n"
	for key, siren in pairs(newSettings.Sirens) do
		sirensString ..= "\t[Enum.KeyCode." .. key.Name .. "] = {\n"
		sirensString ..= "\t\t_Type = \"" .. siren._Type .. "\",\n"
		sirensString ..= "\t\tName = \"" .. siren.Name .. "\",\n"
		sirensString ..= "\t\tOverrideOtherSounds = " .. tostring(siren.OverrideOtherSounds) .. ",\n"
		sirensString ..= "\t\tModifiers = {\n"
		if siren.Modifiers then
			for modifierName, modifier in pairs(siren.Modifiers) do
				sirensString ..= "\t\t\t" .. modifierName .. " = {\n"
				sirensString ..= "\t\t\t\tName = \"" .. modifier.Name .. "\",\n"
				sirensString ..= "\t\t\t\tPlayNonModified = " .. tostring(modifier.PlayNonModified) .. ",\n"
				sirensString ..= "\t\t\t\tPlayOnModifierChange = " .. tostring(modifier.PlayOnModifierChange) .. ",\n"
				sirensString ..= "\t\t\t\tDelay = " .. tostring(modifier.Delay) .. ",\n"
				sirensString ..= "\t\t\t},\n"
			end
		end
		sirensString ..= "\t\t}\n"
		sirensString ..= "\t},\n"
	end
end

function settingsConverter.updateSettings(settings: ModuleScript)
	local pluginSettings = require(settings)

	-- Uhhhhhh idk how I am gonna make this
end

return settingsConverter