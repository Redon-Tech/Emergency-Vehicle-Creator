--!strict

export type vehicle = {
	configuration: chassisConfiguration,
	lights: lights,
	lightConnectedGroups: { [string]: { string } }, -- light: { group }
	connections: { RBXScriptConnection },
	uuid: string,
}

export type lights = {
	[string]: {
		isLightGroup: boolean,
		runningFunction: number?,
		possibleFunctions: { number },
		parts: { BasePart },
		currentState: number,
		returnToZero: boolean?,
	},
}

-- Configuration Types

export type color = {
	name: string,
	partColor: Color3,
	lightColor: Color3,
	lightoColor: Color3,
}

export type lightSettings = {
	colors: { color },
	optimizations: {
		shouldChangeNeons: boolean,
		shouldChangeLights: boolean,
		shouldChangeLightos: boolean,
	},
	lightGroups: {
		{
			name: string,
			lights: { string },
		}
	},
}

export type chassisConfiguration = {
	lightSettings: lightSettings,
	functions: { elsFunction },
}

-- ELS Types

export type elsColor = number

export type flasherSection = {
	waitTime: number,
	rowCount: number,
	columns: { [number]: { lightName: string, rows: { elsColor } } },
	currentRow: number?,
}

export type faderSection = {
	lightName: string,
	data: {
		{
			type: "Simple" | "Advanced" | "Wait",
			time: number,

			-- Non-Wait Specific
			goal: number?,
			color: elsColor?,

			-- Advanced Specific
			easingStyle: Enum.EasingStyle?,
			easingDirection: Enum.EasingDirection?,
		}
	},
	currentTween: number?,
	currentPercentage: number?,
	currentValue: number?,
	previousGoal: number?,
}

export type rotatorSection = {
	lightName: string,
	data: {
		{
			type: "Angle" | "Infinite" | "Wait",
			-- Non-Wait Specific
			color: number?,
			velocity: number?,

			-- Angle Specific
			angle: number?,

			-- Wait Specific
			time: number?,
		}
	},
	currentAngle: number?,
	currentPercentage: number?,
	currentValue: number?,
	previousGoal: number?,
}

export type pattern = {
	flashers: { flasherSection },
	faders: { faderSection },
	rotators: { rotatorSection },
	vehicle: Instance,
	functionId: number,
}

export type selectedPattern = {
	functionId: number,
	patternId: number,
	pattern: pattern,
}

export type activation = {
	type: "Standard" | "Override" | "Conditional",
	mode: "Cycle" | "Set Pattern" | "Siren Override" | "Park" | "Brake" | "Reverse",

	-- Standard Specific
	pattern: number?,

	-- Standard Specific
	keybinds: { Enum.KeyCode }?,

	-- Siren Override Specific/Siren Condition
	siren: number?,

	-- Override Specific/Function Condition
	dependentFunction: string?,
	dependentPattern: number?,

	-- Conditional Specific
	conditionMode: ("Always Active" | "Keybind" | "Function" | "Siren")?,
	conditions: {
		{
			type: "Function",
			mode: "Is" | "Is Not",

			-- Function Specific
			dependentFunction: string,
			dependentPattern: number,
		}
	}?,
}

export type elsFunction = {
	weight: number,
	name: string,
	activations: { activation },
	patterns: { pattern },
}

-- Siren Types

export type modifier = {
	name: string,
	modifiedSirenName: string,
	parentSoundBehavior: "Play Parent Sound" | "Plays Simultaneously",
	behavoir: "Play Automatically" | "Require Parent Replay",
	delay: number,
}

export type siren = {
	name: string,
	type: "Siren" | "Hold",
	behavoir: "Overrides Other Sounds" | "Plays Simultaneously",
	keybinds: { Enum.KeyCode },
	modifiers: { modifier },
} | {
	name: string,
	type: "Modifier",
	keybinds: { Enum.KeyCode },
}

return {}
