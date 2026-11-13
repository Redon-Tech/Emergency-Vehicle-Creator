--!strict
-- Redon Tech Emergency Vehicle Creator, MIT License

export type color = {
	name: string,
	partColor: Color3,
	lightColor: Color3,
	lightoColor: Color3,
}

export type lightGroup = { name: string, lights: { string } }

export type lightSettings = {
	version: number,
	colors: { color },
	configuration: {
		shouldChangeNeons: boolean,
		shouldChangeLights: boolean,
		shouldChangeLightos: boolean,
		shouldChangeParticleEmitters: boolean,
		partTransparency: number,
	},
	lightGroups: { lightGroup },
}

export type chassisConfiguration = {
	lightSettings: lightSettings,
	functions: { elsFunction },
	sirens: { siren },
}

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

export type simpleFaderData = { type: "Simple", time: number, goal: number, color: elsColor }
export type advancedFaderData = {
	type: "Advanced",
	time: number,
	goal: number,
	color: elsColor,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection,
}
export type waitFaderData = { type: "Wait", time: number }
export type faderData = simpleFaderData | advancedFaderData | waitFaderData

export type faderSectionData<Data> = {
	lightName: string,
	data: { Data },
}

export type faderSection = faderSectionData<faderData>

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

export type patternData<Flasher, Fader, Rotator> = {
	flashers: { Flasher },
	faders: { Fader },
	rotators: { Rotator },
}

export type pattern = patternData<flasherSection, faderSection, rotatorSection>

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
	| {
		type: "AG-Event",
		mode: AGEventActivationModes,
	}

export type functionData<Pattern> = {
	weight: number,
	name: string,
	activations: { activation },
	patterns: { Pattern },
}

export type elsFunction = functionData<pattern>

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

export type sirenHold = {
	name: string,
	type: "Siren" | "Hold",
	behavoir: SirenBehavior,
	keybinds: { Enum.KeyCode },
	modifiers: { modifier },
}
export type sirenModifier = { name: string, type: "Modifier", keybinds: { Enum.KeyCode } }
export type siren = sirenHold | sirenModifier

return {}
