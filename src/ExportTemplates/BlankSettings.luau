--[[
	Redon Tech 2023-2024
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Settings --
--------------------------------------------------------------------------------

return {
	-- The name of the lightbar in body
	LightbarName = nil,

	-- The location of the lightbar models
	-- For models inside Body add the name of the model
	-- For models inside Misc add the name of the model
	-- For example:
	--[[
		Misc = {
			"Lights",
		}
	--]]
	AdditionalLightbarLocations = nil,

	-- The name of the siren location the lightbar location
	SirenName = nil,

	-- All the selectable sirens and there respected keybinds
	Sirens = nil,

	-- All the keybinds for any other functionality the system has
	-- To setup this up, set the keycode equal to the stage you want it to increment
	-- So for example:
	-- [Enum.KeyCode.LeftBracket] = "Ally",
	Keybinds = nil,

	-- Secondary keybinds
	-- These keybinds are mapped to other keybinds
	-- This can be used for Xbox controller support
	-- So for example:
	-- [Enum.KeyCode.DPadDown] = Enum.KeyCode.J,
	SecondaryKeybinds = nil,

	-- Default function state
	-- To setup this up, set the function name equal to the state you want it to start at
	-- If this is not set it will default to 0
	-- So for example:
	-- ["CruiseLights"] = 1,
	DefaultFunctionState = nil,

	-- **A-Chassis Only**
	-- Overrides for the chassis plugin
	-- This allows you to control functions without the use of keybinds
	--  or external scripts
	--
	-- Sirens overrides can be done like this
	-- ["Yelp"] = {"YelpOverride", "Stages"},
	-- ["Priority"] = "PriorityOverride"
	--
	-- Chassis overrides can be done like this
	-- ParkBrake = {"PBrakeOverride", "Stages"},
	-- Brake = false,
	-- Reverse = "ReverseOverride",
	--
	-- The second value is used to disallow the override
	--  if the second value is not active
	Overrides = nil,

	-- The colors to be used in the "Light" function
	-- These colors are a Color3
	Colors = nil,

	-- Do not change below unless you know what you are doing
	Light = nil,

	-- DO NOT CHANGE
	-- THIS IS AUTOMATICALLY GENERATED
	PluginVersion = "2.1.1",
	-- THIS IS FOR THE CHASSIS PLUGIN AND WILL NOT ALWAYS MATCH THE STUDIO PLUGIN
}
