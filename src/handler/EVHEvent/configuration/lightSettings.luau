-- Redon Tech Emergency Vehicle Creator, MIT License

--DO NOT MODIFY BELOW
--SUPPORT WILL BE VOIDED IF MODIFIED

return {
	version = 0.07,
	colors = {
		{
			name = "Blue",
			partColor = Color3.fromRGB(110, 153, 202),
			lightColor = Color3.fromRGB(0, 0, 255),
			lightoColor = Color3.fromRGB(47, 71, 255),
		},
		{
			name = "Red",
			partColor = Color3.fromRGB(190, 104, 98),
			lightColor = Color3.fromRGB(255, 0, 0),
			lightoColor = Color3.fromRGB(185, 58, 60),
		},
		{
			name = "Yellow",
			partColor = Color3.fromRGB(226, 155, 64),
			lightColor = Color3.fromRGB(255, 200, 0),
			lightoColor = Color3.fromRGB(253, 194, 66),
		},
		{
			name = "White",
			partColor = Color3.fromRGB(255, 255, 255),
			lightColor = Color3.fromRGB(255, 255, 255),
			lightoColor = Color3.fromRGB(255, 255, 255),
		},
		{
			name = "Green",
			partColor = Color3.fromRGB(0, 255, 0),
			lightColor = Color3.fromRGB(0, 255, 0),
			lightoColor = Color3.fromRGB(75, 255, 75),
		},
		{
			name = "Purple",
			partColor = Color3.fromRGB(170, 0, 170),
			lightColor = Color3.fromRGB(200, 0, 200),
			lightoColor = Color3.fromRGB(188, 12, 211),
		},
	},
	configuration = {
		shouldChangeNeons = true,
		shouldChangeLights = true,
		shouldChangeLightos = true,
		shouldChangeParticleEmitters = false,
		partTransparency = 0.011,
	},
	lightGroups = {},
}
