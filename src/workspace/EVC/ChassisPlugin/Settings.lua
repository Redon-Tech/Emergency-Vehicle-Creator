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

	-- The airhorn name inside the siren location
	AirhornLocation = "Horn",

	-- All the selectable sirens and there respected keybinds
	-- Modifier keys are planned for a future update
	Sirens = {
		[Enum.KeyCode.R] = "Wail",
		[Enum.KeyCode.T] = "Yelp",
		[Enum.KeyCode.Y] = "Priority"
	},

	-- All the keybinds for any other functionality the system has
	-- Currently only the following functions are avaliable:
	--      - Lights: Changes the current stage
	--      - TrafficAdvisor: Changes the current traffic advisor direction
	Keybinds = {
		Lights = Enum.KeyCode.J,
		TrafficAdvisor = Enum.KeyCode.K
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
			Light.Transparency = 1
			Light.Color = Colors[Color]
		end
	end,
}