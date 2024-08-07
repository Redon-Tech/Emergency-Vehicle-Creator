--[[
	Redon Tech 2023-2024
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local settingsConverter = { converters = {} }
local pluginRoot = script.Parent.Parent.Parent

--------------------------------------------------------------------------------
-- Types --
--------------------------------------------------------------------------------
type v2_0_0 = {
	LightbarName: string,
	SirenName: string,
	Sirens: {
		EnumItem: {
			_Type: string,
			Name: string,
			OverrideOtherSounds: boolean,
			Modifiers: {
				String: {
					Name: string,
					PlayNonModified: boolean,
					PlayOnModifierChange: boolean,
					Delay: number,
				},
			}?,
		},
	},
	Keybinds: { EnumItem: string },
	ParkMode: boolean,
	Colors: { number: Color3 },
	Light: (Instance, number, { number: Color3 }) -> nil,
	PluginVersion: string,
}

type v2_1_0 = {
	LightbarName: string,
	AdditionalLightbarLocations: { string: { [number]: string } },
	SirenName: string,
	Sirens: {
		EnumItem: {
			_Type: string,
			Name: string,
			OverrideOtherSounds: boolean,
			Modifiers: {
				String: {
					Name: string,
					PlayNonModified: boolean,
					PlayOnModifierChange: boolean,
					Delay: number,
				},
			}?,
		},
	},
	Keybinds: { EnumItem: string },
	DefaultFunctionState: { string: number },
	Overrides: { string: { string: string | boolean } },
	Colors: { number: Color3 },
	Light: (Instance, number, { number: Color3 }) -> nil,
	PluginVersion: string,
}

--------------------------------------------------------------------------------
-- Module Functions --
--------------------------------------------------------------------------------

settingsConverter.converters["2_0_0"] = function(settings: ModuleScript, pluginSettings: v2_0_0): ModuleScript
	local newSettingsModule = pluginRoot.src.ExportTemplates.BlankSettings:Clone()
	local originalSource = settings.Source
	local source = newSettingsModule.Source
	source = source:gsub("LightbarName = nil,", `LightbarName = \"{pluginSettings.LightbarName}\",`, 1)
	source = source:gsub("SirenName = nil,", `SirenName = \"{pluginSettings.SirenName}\",`, 1)
	source = source:gsub("Sirens = nil,", "Sirens = {" .. originalSource:split("Sirens = {")[2]:split("--")[1], 1)
	source = source:gsub("Keybinds = nil,", "Keybinds = {" .. originalSource:split("Keybinds = {")[2]:split("--")[1], 1)
	source = source:gsub("Colors = nil,", "Colors = {" .. originalSource:split("Colors = {")[2]:split("--")[1], 1)
	source =
		source:gsub("Light = nil,", "Light = function" .. originalSource:split("Light = function")[2]:split("--")[1], 1)

	source = source:gsub(
		"AdditionalLightbarLocations = nil,",
		"AdditionalLightbarLocations = {\n\t\tBody = {\n\t\t},\n\t\tMisc = {\n\t\t}\n\t},",
		1
	)
	source = source:gsub("DefaultFunctionState = nil,", "DefaultFunctionState = {\n\t},", 1)
	source = source:gsub(
		"Overrides = nil,",
		'Overrides = {\n\t\tSirens = {\n\t\t},\n\t\tChassis = {\n\t\t\tParkBrake = "ParkBrakeOverride",\n\t\t\tBrake = false,\n\t\t\tReverse = false,\n\t\t}\n\t},',
		1
	)
	source = source:gsub(
		"SecondaryKeybinds = nil,",
		"SecondaryKeybinds = {\n\t\t[Enum.KeyCode.DPadDown] = Enum.KeyCode.J,\n\t},",
		1
	)

	newSettingsModule.Source = source
	return newSettingsModule
end

settingsConverter.converters["2_1_0"] = function(settings: ModuleScript, pluginSettings: v2_1_0): ModuleScript
	local newSettingsModule = pluginRoot.src.ExportTemplates.BlankSettings:Clone()
	local originalSource = settings.Source
	local source = newSettingsModule.Source

	source = source:gsub("LightbarName = nil,", `LightbarName = \"{pluginSettings.LightbarName}\",`, 1)
	source = source:gsub(
		"AdditionalLightbarLocations = nil,",
		"AdditionalLightbarLocations = {" .. originalSource:split("AdditionalLightbarLocations = {")[2]:split("--")[1],
		1
	)
	source = source:gsub("SirenName = nil,", `SirenName = \"{pluginSettings.SirenName}\",`, 1)
	source = source:gsub("Sirens = nil,", "Sirens = {" .. originalSource:split("Sirens = {")[2]:split("--")[1], 1)
	source = source:gsub("Keybinds = nil,", "Keybinds = {" .. originalSource:split("Keybinds = {")[2]:split("--")[1], 1)
	source = source:gsub(
		"DefaultFunctionState = nil,",
		"DefaultFunctionState = {" .. originalSource:split("DefaultFunctionState = {")[2]:split("--")[1],
		1
	)
	source =
		source:gsub("Overrides = nil,", "Overrides = {" .. originalSource:split("Overrides = {")[2]:split("--")[1], 1)
	source = source:gsub("Colors = nil,", "Colors = {" .. originalSource:split("Colors = {")[2]:split("--")[1], 1)
	source =
		source:gsub("Light = nil,", "Light = function" .. originalSource:split("Light = function")[2]:split("--")[1], 1)

	source = source:gsub(
		"SecondaryKeybinds = nil,",
		"SecondaryKeybinds = {\n\t\t[Enum.KeyCode.DPadDown] = Enum.KeyCode.J,\n\t},"
	)

	newSettingsModule.Source = source
	return newSettingsModule
end

settingsConverter.converters["2_1_1"] = function(settings: ModuleScript, pluginSettings: v2_1_0): ModuleScript
	local newSettingsModule = pluginRoot.src.ExportTemplates.BlankSettings:Clone()
	local originalSource = settings.Source
	local source = newSettingsModule.Source

	source = source:gsub("LightbarName = nil,", `LightbarName = \"{pluginSettings.LightbarName}\",`, 1)
	source = source:gsub(
		"AdditionalLightbarLocations = nil,",
		"AdditionalLightbarLocations = {" .. originalSource:split("AdditionalLightbarLocations = {")[2]:split("--")[1],
		1
	)
	source = source:gsub("SirenName = nil,", `SirenName = \"{pluginSettings.SirenName}\",`, 1)
	source = source:gsub("Sirens = nil,", "Sirens = {" .. originalSource:split("Sirens = {")[2]:split("--")[1], 1)
	source = source:gsub("Keybinds = nil,", "Keybinds = {" .. originalSource:split("Keybinds = {")[2]:split("--")[1], 1)
	source = source:gsub(
		"DefaultFunctionState = nil,",
		"DefaultFunctionState = {" .. originalSource:split("DefaultFunctionState = {")[2]:split("--")[1],
		1
	)
	source =
		source:gsub("Overrides = nil,", "Overrides = {" .. originalSource:split("Overrides = {")[2]:split("--")[1], 1)
	source = source:gsub("Colors = nil,", "Colors = {" .. originalSource:split("Colors = {")[2]:split("--")[1], 1)
	source =
		source:gsub("Light = nil,", "Light = function" .. originalSource:split("Light = function")[2]:split("--")[1], 1)

	source = source:gsub(
		"SecondaryKeybinds = nil,",
		"SecondaryKeybinds = {" .. originalSource:split("SecondaryKeybinds = {")[2]:split("--")[1],
		1
	)

	newSettingsModule.Source = source
	return newSettingsModule
end

settingsConverter.converters["2_2_0"] = function(settings: ModuleScript, pluginSettings: v2_1_0): ModuleScript
	local newSettingsModule = pluginRoot.src.ExportTemplates.BlankSettings:Clone()
	local originalSource = settings.Source
	local source = newSettingsModule.Source

	source = source:gsub("LightbarName = nil,", `LightbarName = \"{pluginSettings.LightbarName}\",`, 1)
	source = source:gsub(
		"AdditionalLightbarLocations = nil,",
		"AdditionalLightbarLocations = {" .. originalSource:split("AdditionalLightbarLocations = {")[2]:split("--")[1],
		1
	)
	source = source:gsub("SirenName = nil,", `SirenName = \"{pluginSettings.SirenName}\",`, 1)
	source = source:gsub("Sirens = nil,", "Sirens = {" .. originalSource:split("Sirens = {")[2]:split("--")[1], 1)
	source = source:gsub("Keybinds = nil,", "Keybinds = {" .. originalSource:split("Keybinds = {")[2]:split("--")[1], 1)
	source = source:gsub(
		"DefaultFunctionState = nil,",
		"DefaultFunctionState = {" .. originalSource:split("DefaultFunctionState = {")[2]:split("--")[1],
		1
	)
	source =
		source:gsub("Overrides = nil,", "Overrides = {" .. originalSource:split("Overrides = {")[2]:split("--")[1], 1)
	source = source:gsub("Colors = nil,", "Colors = {" .. originalSource:split("Colors = {")[2]:split("--")[1], 1)
	source =
		source:gsub("Light = nil,", "Light = function" .. originalSource:split("Light = function")[2]:split("--")[1], 1)

	source = source:gsub(
		"SecondaryKeybinds = nil,",
		"SecondaryKeybinds = {" .. originalSource:split("SecondaryKeybinds = {")[2]:split("--")[1],
		1
	)

	newSettingsModule.Source = source
	return newSettingsModule
end

settingsConverter.converters["2_2_1"] = function(settings: ModuleScript, pluginSettings: v2_1_0): ModuleScript
	local newSettingsModule = pluginRoot.src.ExportTemplates.BlankSettings:Clone()
	local originalSource = settings.Source
	local source = newSettingsModule.Source

	source = originalSource
	source = source:gsub('PluginVersion = "2.2.1",', `PluginVersion = "2.2.2",`, 1)

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
