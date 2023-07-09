--[[
	Redon Tech 2023
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Settings --
--------------------------------------------------------------------------------

return {
	-- The name of the lightbar in body
	LightbarName = "Lightbar",

	-- The name of the siren location inside the lightbar location
	SirenName = "middle",

	-- All the selectable sirens and there respected keybinds
	-- Modifier keys are planned for a future update
	Sirens = {
		[Enum.KeyCode.H] = {
			_Type = "Hold",
			Name = "Horn",
			OverrideOtherSounds = true,
			Modifiers = nil
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
			}
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
			}
		},
		[Enum.KeyCode.Y] = {
			_Type = "Siren",
			Name = "Priority",
			OverrideOtherSounds = true,
			Modifiers = nil
		},

		[Enum.KeyCode.LeftBracket] = {
			_Type = "Modifier",
			Name = "Rumbler"
		},
	},

	-- All the keybinds for any other functionality the system has
	-- To setup this up, set the keycode equal to the stage you want it to increment
	-- So for example:
	-- [Enum.KeyCode.LeftBracket] = "Ally",
	Keybinds = {
		[Enum.KeyCode.J] = "Stages",
		[Enum.KeyCode.K] = "Traffic_Advisor"
	},

	-- Enable park mode
	-- Requires exporting a pattern to "Park" folder in the ModuleStore
	--		- Make sure to set the park modes weight to be higher then the normal patterns
	-- ParkMode is planned for a future update, and will not work at this time
	ParkMode = true,

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
	-- Light = function(Light, Color, Colors)
	-- 	if Color == 0 then
	-- 		for i,v in pairs(Light:GetDescendants()) do
	-- 			if v:IsA("GuiObject") then
	-- 				v.Visible = false
	-- 			elseif v:IsA("Light") or v:IsA("SurfaceGui") then
	-- 				v.Enabled = false
	-- 			elseif v:IsA("ParticleEmitter") then
	-- 				v.Transparency = NumberSequence.new(1)
	-- 			end
	-- 		end
	-- 		Light.Transparency = 1
	-- 	else
	-- 		for i,v in pairs(Light:GetDescendants()) do
	-- 			if v:IsA("GuiObject") then
	-- 				v.Visible = true
	-- 				v.ImageColor3 = Colors[Color]
	-- 			elseif v:IsA("Light") then
	-- 				v.Enabled = true
	-- 				v.Color = Colors[Color]
	-- 			elseif v:IsA("SurfaceGui") then
	-- 				v.Enabled = true
	-- 			elseif v:IsA("ParticleEmitter") then
	-- 				v.Transparency = NumberSequence.new(0)
	-- 				v.Color = ColorSequence.new(Colors[Color])
	-- 			end
	-- 		end
	-- 		Light.Transparency = 0
	-- 		Light.Color = Colors[Color]
	-- 	end
	-- end,
	Light = {
		BasePart = {
			Init = function(Light: BasePart)
				Light.Transparency = 1
			end,

			Flash = function(Light: BasePart, Color: Color3|number)
				if Color == 0 then
					Light.Transparency = 1
				else
					Light.Transparency = 0.011
					Light.Color = Color
				end
			end,
		},

		Light = {
			Init = function(Light: Light)
				Light.Enabled = true
			end,

			Flash = function(Light: Light, Color: Color3|number)
				if Color == 0 then
					Light.Enabled = false
				else
					Light.Enabled = true
					Light.Color = Color
				end
			end,
		},

		LayerCollector = {
			Init = function(Light: LayerCollector)
				Light.Enabled = true
			end,

			Flash = nil,
		},


		ImageLabel = {
			Init = function(Light: ImageLabel)
				Light.Visible = false
			end,

			Flash = function(Light: ImageLabel, Color: Color3|number)
				if Color == 0 then
					Light.Visible = false
				else
					Light.Visible = true
					Light.ImageColor3 = Color
				end
			end,
		},

		ParticleEmitter = {
			Init = function(Light: ParticleEmitter)
				Light.Transparency = NumberSequence.new(1)
			end,

			Flash = function(Light: ParticleEmitter, Color: Color3|number)
				if Color == 0 then
					Light.Transparency = NumberSequence.new(1)
				else
					Light.Transparency = NumberSequence.new(0)
					Light.Color = ColorSequence.new(Color)
				end
			end,
		},
	},






	-- DO NOT CHANGE
	-- THIS IS AUTOMATICALLY GENERATED
	PluginVersion = "2.1.0",
	-- THIS IS FOR THE CHASSIS PLUGIN AND SHOULD NOT MATH THE STUDIO PLUGIN
}