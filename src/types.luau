--# selene: allow(unused_variable)
-- Redon Tech Emergency Vehicle Creator, MIT License

local root = script.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local utils = require(script.Parent.utils)

-- Code Types

export type Scope = Fusion.Scope<typeof(Fusion) & typeof(RedonUI.Components) & typeof(RedonUI.Util) & typeof(utils)>

export type mode = "menu" | "main" | "viewport"

export type menuPanels = "Home" | "Vehicle" | "Settings" | "Help" | "Credits"

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

return nil
