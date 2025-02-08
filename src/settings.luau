-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent
local plugin = root:FindFirstAncestorWhichIsA("Plugin") :: Plugin

local types = require(script.Parent.types)
local log = require(script.Parent.log)
local Fusion = require(root.Packages.fusion)

type settings = {
	scope: types.Scope,
	values: {
		theme: Fusion.Value<types.theme>,
		fakeBloom: Fusion.Value<boolean>,
		colorKeybinds: Fusion.Value<types.keybinds>,
		debugMode: Fusion.Value<boolean>,
		saveBackupMode: Fusion.Value<types.saveBackupMode>,
	},
	valueData: { { type: { string } | "boolean", title: string, description: string, key: string } },
	setup: (self: settings, scope: types.Scope) -> (),
}
local settings = {
	valueData = {
		{
			title = "Theme",
			description = "The theme of the UI",
			type = { "Auto", "Latte", "Frappe", "Macchiato", "Mocha" },
			key = "theme",
		},
		{
			title = "Fake Bloom",
			description = "Toggle the fake bloom applied in the UI when playing a pattern",
			type = "boolean",
			key = "fakeBloom",
		},
		{
			title = "Color Keybinds",
			description = "Choose which keybinds you would like to use to change colors",
			type = { "Q-Y", "1-6", "NumPad 1-6" },
			key = "colorKeybinds",
		},
		{
			title = "Debug Mode",
			description = "If you are encountering an issue with the plugin, use this to help us solve your problem!",
			type = "boolean",
			key = "debugMode",
		},
		-- {
		-- 	title = "Save Backup Mode",
		-- 	description = "Enable or disable saving backups of your patterns in any open place.",
		-- 	type = { "Encrypted", "Unencrypted", "None" },
		-- 	key = "saveBackupMode",
		-- },
	},
} :: settings

local defaultValues = {
	theme = "Auto",
	fakeBloom = true,
	colorKeybinds = "Q-Y",
	debugMode = false,
	saveBackupMode = "Encrypted",
}

local function getSaveKey(key: string): string
	return `RedonTech_EVC_{key}`
end

function settings:setup(scope: types.Scope)
	self.scope = scope

	local valuesToLoad = { "theme", "fakeBloom", "colorKeybinds", "debugMode", "saveBackupMode" }

	self.values = {} :: any
	for _, key in pairs(valuesToLoad) do
		local savedValue = plugin:GetSetting(getSaveKey(key))

		if savedValue ~= nil then
			self.values[key] = scope:Value(savedValue)
		else
			self.values[key] = scope:Value(defaultValues[key])
		end
	end
	log.debug("Settings loaded", self.values)

	for key, value: Fusion.Value<any> in pairs(self.values) do
		scope:Observer(value):onChange(function()
			task.spawn(function()
				local newValue = scope.peek(value)
				plugin:SetSetting(getSaveKey(key), newValue)
				log.debug("Setting saved", getSaveKey(key), newValue)
			end)
		end)
	end
	log.debug("Observers set up")
end

return settings
