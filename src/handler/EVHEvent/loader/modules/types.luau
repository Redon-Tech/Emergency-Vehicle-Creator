--!strict

local ConfigurationTypes = require("./configurationTypes")

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

export type color = ConfigurationTypes.color
export type lightSettings = ConfigurationTypes.lightSettings

-- The handler initializes ELS separately from siren playback.
export type chassisConfiguration = {
	lightSettings: lightSettings,
	functions: { elsFunction },
}

export type elsColor = ConfigurationTypes.elsColor
export type flasherSection = ConfigurationTypes.flasherSection & { currentRow: number? }
export type FaderTiming = { timeStart: number, timeEnd: number }
export type faderData =
	(ConfigurationTypes.simpleFaderData & FaderTiming)
	| (ConfigurationTypes.advancedFaderData & FaderTiming)
	| (ConfigurationTypes.waitFaderData & FaderTiming)
export type faderSection = ConfigurationTypes.faderSectionData<faderData> & {
	currentTween: number?,
	currentPercentage: number?,
	currentValue: number?,
	previousGoal: number?,
	returnStartValue: number?,
	totalTime: number,
}
export type rotatorSection = ConfigurationTypes.rotatorSection & {
	currentAngle: number?,
	currentPercentage: number?,
	currentValue: number?,
	previousGoal: number?,
	currentLightState: number?,
}
export type pattern = ConfigurationTypes.patternData<flasherSection, faderSection, rotatorSection> & {
	vehicle: Instance,
	functionId: number,
	patternTime: number,
}
export type selectedPattern = { functionId: number, patternId: number, pattern: pattern }
export type activation = ConfigurationTypes.activation
export type elsFunction = ConfigurationTypes.functionData<pattern>
export type modifier = ConfigurationTypes.modifier
export type siren =
	(ConfigurationTypes.sirenHold & { enabled: boolean? })
	| (ConfigurationTypes.sirenModifier & { enabled: boolean? })

return {}
