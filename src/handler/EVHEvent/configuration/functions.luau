-- Redon Tech Emergency Vehicle Creator, MIT License

--DO NOT MODIFY BELOW
--SUPPORT WILL BE VOIDED IF MODIFIED

return {
	{
		activations = {
			{
				mode = "Cycle",
				type = "Standard",
				pattern = 0,
				keybinds = {
					Enum.KeyCode.J,
					Enum.KeyCode.DPadLeft,
				},
			},
		},
		patterns = {
			{
				faders = {},
				flashers = {},
				rotators = {},
			},
		},
		name = "Stages",
		weight = 1,
	},
	{
		name = "Traffic Advisor",
		patterns = {
			{
				faders = {},
				flashers = {},
				rotators = {},
			},
		},
		activations = {
			{
				type = "Standard",
				mode = "Cycle",
				pattern = 0,
				keybinds = {
					Enum.KeyCode.K,
					Enum.KeyCode.DPadRight,
				},
			},
		},
		weight = 2,
	},
}
