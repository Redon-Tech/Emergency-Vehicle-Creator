--[[
	Redon Tech 2023-2024
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Settings --
--------------------------------------------------------------------------------

return {
	-- The name of the lightbar in body
	LightbarName = "Lightbar",

	-- The location of the lightbar models
	-- For models inside Body add the name of the model
	-- For models inside Misc add the name of the model
	-- This will search all descendants (so make names unique)
	-- For example:
	--[[
		Misc = {
			"Lights",
		}
	--]]
	AdditionalLightbarLocations = {
		Body = {},
		Misc = {},
	},

	-- The name of the siren location the lightbar location
	SirenName = "middle",

	-- All the selectable sirens and there respected keybinds
	Sirens = {
		[Enum.KeyCode.H] = {
			_Type = "Hold",
			Name = "Horn",
			OverrideOtherSounds = true,
			Modifiers = nil,
		},
		[Enum.KeyCode.R] = {
			_Type = "Siren",
			Name = "Wail",
			OverrideOtherSounds = true,
			Modifiers = {
				Rumbler = {
					Name = "RWail",
					PlayNonModified = false,
					PlayOnModifierChange = true,
					Delay = 0,
				},
			},
		},
		[Enum.KeyCode.T] = {
			_Type = "Siren",
			Name = "Yelp",
			OverrideOtherSounds = true,
			Modifiers = {
				Rumbler = {
					Name = "RYelp",
					PlayNonModified = true,
					PlayOnModifierChange = true,
					Delay = -0.2,
				},
			},
		},
		[Enum.KeyCode.Y] = {
			_Type = "Siren",
			Name = "Priority",
			OverrideOtherSounds = true,
			Modifiers = nil,
		},

		[Enum.KeyCode.LeftBracket] = {
			_Type = "Modifier",
			Name = "Rumbler",
		},
	},

	-- All the keybinds for any other functionality the system has
	-- To setup this up, set the keycode equal to the stage you want it to increment
	-- So for example:
	-- [Enum.KeyCode.LeftBracket] = "Ally",
	Keybinds = {
		[Enum.KeyCode.J] = "Stages",
		[Enum.KeyCode.K] = "Traffic_Advisor",
	},

	-- Secondary keybinds
	-- These keybinds are mapped to other keybinds
	-- This can be used for Xbox controller support
	-- So for example:
	-- [Enum.KeyCode.DPadDown] = Enum.KeyCode.J,
	SecondaryKeybinds = {
		[Enum.KeyCode.DPadDown] = Enum.KeyCode.J,
	},

	-- Default function state
	-- To setup this up, set the function name equal to the state you want it to start at
	-- If this is not set it will default to 0
	-- So for example:
	-- ["CruiseLights"] = 1,
	DefaultFunctionState = {},

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
	-- For dependencies if you want to depend on being
	-- higher then a pattern you can do this
	-- {"ParkBrakeOverride", "Stages", 3},
	--
	-- The second value is used to disallow the override
	--  if the second value is not active
	Overrides = {
		Sirens = {},
		Chassis = {
			ParkBrake = { "ParkBrakeOverride", "Stages" },
			Brake = "BrakeOverride",
			Reverse = false,
		},
	},

	-- The colors to be used in the "Light" function
	-- These colors are a Color3
	Colors = {
		[1] = Color3.fromRGB(47, 71, 255),
		[2] = Color3.fromRGB(185, 58, 60),
		[3] = Color3.fromRGB(253, 194, 66),
		[4] = Color3.fromRGB(255, 255, 255),
		[5] = Color3.fromRGB(75, 255, 75),
		[6] = Color3.fromRGB(188, 12, 211),
	},

	-- Do not change below unless you know what you are doing
	Light = function(Light, Color, Colors)
		if Color == 0 then
			for i, v in pairs(Light:GetDescendants()) do
				if v:IsA("GuiObject") then
					v.Visible = false
				elseif v:IsA("Light") or v:IsA("SurfaceGui") then
					v.Enabled = false
				end
			end
			Light.Transparency = 1
		else
			for i, v in pairs(Light:GetDescendants()) do
				if v:IsA("GuiObject") then
					v.Visible = true
					v.ImageColor3 = Colors[Color]
				elseif v:IsA("Light") then
					v.Enabled = true
					v.Color = Colors[Color]
				elseif v:IsA("SurfaceGui") then
					v.Enabled = true
				end
			end
			Light.Transparency = 0
			Light.Color = Colors[Color]
		end
	end,

	-- DO NOT CHANGE
	-- THIS IS AUTOMATICALLY GENERATED
	PluginVersion = "2.1.1",
	-- THIS IS FOR THE CHASSIS PLUGIN AND WILL NOT ALWAYS MATCH THE STUDIO PLUGIN
}
