--[[
Generated By: Emergency Vehicle Creator
For: Emergency Vehicle Creator Plugin

Redon Tech 2022
EVC
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local Settings, Lights

--------------------------------------------------------------------------------
-- Data --
--------------------------------------------------------------------------------

Settings = {
	-- The time between each light flash
	WaitTime = 0.1,
	-- The colors to be used in the "color" function
	-- These colors are a RGB
	Colors = {
		[1] = Color3.fromRGB(47, 71, 255),
		[2] = Color3.fromRGB(185, 58, 60),
		[3] = Color3.fromRGB(253, 194, 66),
		[4] = Color3.fromRGB(255, 255, 255),
		[5] = Color3.fromRGB(75, 255, 75),
		[6] = Color3.fromRGB(188, 12, 211),
	},
	-- Determins which lights can over ride each other
	-- For example lightbars should be 1 and traffic advisors 2
	-- This allows the traffic advisor to override the back of the lightbar
	-- If multiple are the same then the light will default to the first loaded
	Weight = 1,

	-- If for whatever reason you need to override the light function change nil to the new function
	-- You can find a template for the funciton in the settings under the plugin
	Light = nil,
}

--[[
	Example of how lights should look
	["LightName"] = {
		1,2,3,4,5,6,0,0,0,0,0,0, -- Refrenced to the color table above, **0 = Off**
	},
]]
Lights = {

}

--------------------------------------------------------------------------------
-- Return Value --
--------------------------------------------------------------------------------

return {
	Settings = Settings,
	Lights = Lights
}