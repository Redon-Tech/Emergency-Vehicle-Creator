--# selene: allow(unused_variable)
-- Redon Tech Emergency Vehicle Creator, MIT License

local root = script.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local utils = require(script.Parent.utils)

-- Code Types

export type Scope = Fusion.Scope<typeof(Fusion) & typeof(RedonUI.Components) & typeof(RedonUI.Util) & typeof(utils)>

export type mode = "menu" | "main" | "viewport"

export type menuPanels = "Home" | "Vehicle" | "Settings" | "Help" | "Credits" | "Permission Needed"

export type mainPanels = "Vehicle Setup" | "ELS Setup"
export type vehicleSetupPages = "Functions" | "Sirens" | "Light Settings"
export type elsSetupPages = "Flashers" | "Faders" | "Rotators"
export type pages = vehicleSetupPages | elsSetupPages

export type returnTo = "menu" | "customizer" | "vehicleSetup"

-- Settings Types

export type theme = "Auto" | "Latte" | "Frappe" | "Macchiato" | "Mocha"

export type keybinds = "Q-Y" | "1-6" | "NumPad 1-6"

export type saveBackupMode = "Encrypted" | "Unencrypted" | "None"

-- ELS Types

export type elsColor = number

export type flasherSection = {
	waitTime: number,
	rowCount: number,
	columns: { [number]: { lightName: string, rows: { elsColor } } },
}

export type flasherColumnDataState = {
	currentName: Fusion.Value<string>?,
	lightName: Fusion.Value<string>,
	rows: Fusion.Value<{ elsColor }>,
}
export type flasherSectionState = {
	waitTime: Fusion.Value<number>,
	rowCount: Fusion.Value<number>,
	nameTemplate: {
		pattern: string,
		originalPosition: number,
		originalNumber: number,
	}?,
	columns: Fusion.Value<{ [number]: flasherColumnDataState }>,
	currentRow: Fusion.Value<number>,
}

export type faderData = {
	type: "Simple",
	time: number,
	goal: number,
	color: elsColor,
} | {
	type: "Advanced",
	time: number,
	goal: number,
	color: elsColor,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection,
} | {
	type: "Wait",
	time: number,
}

export type faderSection = {
	lightName: string,
	data: { faderData },
}

export type faderTweenDataState = {
	type: Fusion.Value<"Simple" | "Advanced" | "Wait">,
	time: Fusion.Value<number>,

	-- Non-Wait Specific
	goal: Fusion.Value<number>?,
	color: Fusion.Value<elsColor>?,

	-- Advanced Specific
	easingStyle: Fusion.Value<Enum.EasingStyle>?,
	easingDirection: Fusion.Value<Enum.EasingDirection>?,
}

export type faderSectionState = {
	lightName: Fusion.Value<string>,
	currentPercentage: Fusion.Value<number>,
	currentTween: Fusion.Value<number>,
	currentValue: Fusion.Value<number>,
	previousGoal: number?,
	data: Fusion.Value<{ faderTweenDataState }>,
}

export type rotatorData = {
	type: "Angle",
	color: elsColor,
	velocity: number,
	angle: number,
} | {
	type: "Infinite",
	color: elsColor,
	velocity: number,
} | {
	type: "Wait",
	time: number,
}

export type rotatorSection = {
	lightName: string,
	data: { rotatorData },
}

export type rotatorDataState = {
	type: Fusion.Value<"Angle" | "Infinite" | "Wait">,
	-- Non-Wait Specific
	velocity: Fusion.Value<number>?,
	color: Fusion.Value<elsColor>?,

	-- Angle Specific
	angle: Fusion.Value<number>?,

	-- Wait Specific
	time: Fusion.Value<number>?,
}

export type rotatorSectionState = {
	lightName: Fusion.Value<string>,
	currentPercentage: Fusion.Value<number>,
	currentAngle: Fusion.Value<number>,
	currentValue: Fusion.Value<number>,
	previousGoal: number?,
	data: Fusion.Value<{ rotatorDataState }>,
}

export type pattern = {
	flashers: { flasherSection },
	faders: { faderSection },
	rotators: { rotatorSection },
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
} | {
	type: "AG-Event",
	mode: "Stages" | "Traffic Advisor" | "Scene" | "Ally Left" | "Ally Right" | "Rear Scene",
}

export type activationState = {
	type: Fusion.Value<"Standard" | "Default" | "Override" | "AG-Event">,
	mode: Fusion.Value<
		"Cycle"
		| "Set Pattern"
		| "Siren Override"
		| "Park"
		| "Brake"
		| "Reverse"
		| "Always Active"
		| "Keybind"
		| "Function"
		| "Siren"
		| "Stages"
		| "Traffic Advisor"
		| "Scene"
		| "Ally Left"
		| "Ally Right"
		| "Rear Scene"
	>?,
	pattern: Fusion.Value<number>?,
	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>?,
	siren: Fusion.Value<string?>?,
	dependentFunction: Fusion.Value<string>?,
	dependentPattern: Fusion.Value<number>?,
	conditions: Fusion.Value<{
		{
			type: Fusion.Value<"Function">,
			mode: Fusion.Value<"Is" | "Is Not">,
			dependentFunction: Fusion.Value<string>,
			dependentPattern: Fusion.Value<number>,
		}
	}>?,
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

return nil
