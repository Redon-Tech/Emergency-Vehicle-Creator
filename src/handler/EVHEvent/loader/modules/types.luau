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
	version: number,
	colors: { color },
	configuration: {
		shouldChangeNeons: boolean,
		shouldChangeLights: boolean,
		shouldChangeLightos: boolean,
		partTransparency: number,
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
	currentLightState: number?,
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
	type: "Standard",
	mode: "Cycle" | "Set Pattern",
	pattern: number,
	keybinds: { Enum.KeyCode },
} | {
	type: "Default",
	pattern: number,
} | {
	type: "Override",
	mode: "Siren Override" | "Park" | "Brake" | "Reverse",
	siren: string?,
	dependentFunction: string,
	dependentPattern: number,
} | {
	type: "Conditional",
	mode: "Always Active" | "Keybind" | "Function" | "Siren",
	conditions: {
		{
			type: "Function",
			mode: "Is" | "Is Not",
			dependentFunction: string,
			dependentPattern: number,
		}
	},
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
	enabled: boolean?,
	behavoir: "Overrides Other Sounds" | "Plays Simultaneously",
	keybinds: { Enum.KeyCode },
	modifiers: { modifier },
} | {
	name: string,
	type: "Modifier",
	enabled: boolean?,
	keybinds: { Enum.KeyCode },
}

return {}
