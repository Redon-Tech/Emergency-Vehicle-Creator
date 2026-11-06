--# selene: allow(unused_variable)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../Packages/fusion")
local RedonUI = require("../Packages/redon-ui")
local utils = require("./lib/utils")

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

export type flasherColumn = {
	lightName: string,
	rows: { elsColor },
}

export type flasherSection = {
	waitTime: number,
	rowCount: number,
	columns: { [number]: flasherColumn },
}

export type faderData =
	{
		type: "Simple",
		time: number,
		goal: number,
		color: elsColor,
	}
	| {
		type: "Advanced",
		time: number,
		goal: number,
		color: elsColor,
		easingStyle: Enum.EasingStyle,
		easingDirection: Enum.EasingDirection,
	}
	| {
		type: "Wait",
		time: number,
	}

export type faderSection = {
	lightName: string,
	data: { faderData },
}

export type rotatorData =
	{
		type: "Angle",
		color: elsColor,
		velocity: number,
		angle: number,
	}
	| {
		type: "Infinite",
		color: elsColor,
		velocity: number,
	}
	| {
		type: "Wait",
		time: number,
	}

export type rotatorSection = {
	lightName: string,
	data: { rotatorData },
}

export type pattern = {
	flashers: { flasherSection },
	faders: { faderSection },
	rotators: { rotatorSection },
}

export type selectedPattern = {
	functionId: number,
	patternId: number,
}

export type StandardActivationModes = "Cycle" | "Set Pattern"
export type OverrideActivationModes = "Siren Override" | "Park" | "Brake" | "Reverse"
export type AGEventActivationModes = "Stages" | "Traffic Advisor" | "Scene" | "Ally Left" | "Ally Right" | "Rear Scene"

export type activation =
	{
		type: "Standard",
		mode: StandardActivationModes,
		pattern: number,
		keybinds: { Enum.KeyCode },
	}
	| {
		type: "Default",
		pattern: number,
	}
	| {
		type: "Override",
		mode: OverrideActivationModes,
		siren: string?,
		dependentFunction: string,
		dependentPattern: number,
	}
	| {
		type: "AG-Event",
		mode: AGEventActivationModes,
	}

export type elsFunction = {
	weight: number,
	name: string,
	activations: { activation },
	patterns: { pattern },
}

-- Siren Types

export type ModifierParentSoundBehavior = "Play Parent Sound" | "Plays Simultaneously"
export type ModifierBehavior = "Play Automatically" | "Require Parent Replay"

export type modifier = {
	name: string,
	modifiedSirenName: string,
	parentSoundBehavior: ModifierParentSoundBehavior,
	behavoir: ModifierBehavior,
	delay: number,
}

export type SirenBehavior = "Overrides Other Sounds" | "Plays Simultaneously"

export type siren =
	{
		name: string,
		type: "Siren" | "Hold",
		behavoir: SirenBehavior,
		keybinds: { Enum.KeyCode },
		modifiers: { modifier },
	}
	| {
		name: string,
		type: "Modifier",
		keybinds: { Enum.KeyCode },
	}

return nil
