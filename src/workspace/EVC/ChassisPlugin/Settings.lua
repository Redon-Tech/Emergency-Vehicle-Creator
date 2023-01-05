--[[
Redon Tech 2022
EVC
--]]

--------------------------------------------------------------------------------
-- Settings --
--------------------------------------------------------------------------------

return {
	-- The name of the lightbar in body
	LightbarLocation = "Lightbar",

	-- The name of the siren location inside the lightbar location
	SirenLocation = "middle",

	-- All the selectable sirens and there respected keybinds
	-- Modifier keys are planned for a future update
	Sirens = {
		[Enum.KeyCode.H] = {
			_Type = "Hold",
			Name = "Horn",
			OverrideOtherSounds = true,
			Modifier = {
				_Type = "Rumber",
				Name = "RHorn",
				Options = {
					PlayNonModified = true,
					PlayOnModifierChange = true,
					Delay = -0.05,
				}
			}
		},
		[Enum.KeyCode.R] = {
			_Type = "Siren",
			Name = "Wail",
			OverrideOtherSounds = true,
			Modifier = {
				_Type = "Rumber",
				Name = "RWail",
				Options = {
					PlayNonModified = false,
					PlayOnModifierChange = true,
					Delay = 0,
				}
			}
		},
		[Enum.KeyCode.T] = {
			_Type = "Siren",
			Name = "Yelp",
			OverrideOtherSounds = true,
			Modifier = {
				_Type = "Rumber",
				Name = "RYelp",
				Options = {
					PlayNonModified = true,
					PlayOnModifierChange = true,
					Delay = -0.05,
				}
			}
		},
		[Enum.KeyCode.Y] = {
			_Type = "Siren",
			Name = "Priority",
			OverrideOtherSounds = true,
			Modifier = nil
		},
		[Enum.KeyCode.LeftBracket] = {
			_Type = "Modifier",
			Name = "Rumbler",
			Enabled = false
		}
	},

	-- All the keybinds for any other functionality the system has
	-- Currently only the following functions are avaliable:
	--      - Lights: Changes the current stage
	--      - TrafficAdvisor: Changes the current traffic advisor direction
	Keybinds = {
		Lights = Enum.KeyCode.J,
		TrafficAdvisor = Enum.KeyCode.K
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
	Light = function(Light, Color, Colors)
		if Color == 0 then
			for i,v in pairs(Light:GetDescendants()) do
				if v:IsA("GuiObject") then
					v.Visible = false
				elseif v:IsA("Light") or v:IsA("SurfaceGui") then
					v.Enabled = false
				elseif v:IsA("PartticleEmitter") then
					v.Transparency = NumberSequence.new(1)
				end
			end
			Light.Transparency = 1
		else
			for i,v in pairs(Light:GetDescendants()) do
				if v:IsA("GuiObject") then
					v.Visible = true
					v.ImageColor3 = Colors[Color]
				elseif v:IsA("Light") or v:IsA("SurfaceGui") then
					v.Enabled = true
				elseif v:IsA("PartticleEmitter") then
					v.Transparency = NumberSequence.new(0)
					v.Color = ColorSequence.new(Colors[Color])
				end
			end
			Light.Transparency = 0
			Light.Color = Colors[Color]
		end
	end,






	-- DO NOT CHANGE
	-- THIS IS AUTOMATICALLY GENERATED
	PluginVersion = "1.1.0",
	-- THIS IS FOR THE CHASSIS PLUGIN AND SHOULD NOT MATH THE STUDIO PLUGIN
}