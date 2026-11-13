-- Redon Tech Emergency Vehicle Creator, MIT License
local types = require("../../types")

export type ImportReport = {
	imported: { string },
	failures: { { name: string, message: string } },
	cancelled: boolean,
}

export type Collection<T> = {
	list: (self: Collection<T>) -> ({ string }?, string?),
	load: (self: Collection<T>, name: string) -> (T?, string?),
	save: (self: Collection<T>, name: string, data: T, options: { overwrite: boolean? }?) -> (boolean, string?),
	rename: (self: Collection<T>, oldName: string, newName: string) -> (boolean, string?),
	delete: (self: Collection<T>, name: string) -> (boolean, string?),
	importFile: (self: Collection<T>) -> (ImportReport?, string?),
	exportFile: (self: Collection<T>, name: string) -> (boolean, string?),
}

export type SaveLibrary = {
	init: (plugin: Plugin) -> ImportReport,
	patterns: Collection<types.pattern>,
	functions: Collection<types.elsFunction>,
	activations: Collection<types.activation>,
	sirens: Collection<types.siren>,
	modifiers: Collection<types.modifier>,
	flasherSections: Collection<types.flasherSection>,
	flasherColumns: Collection<types.flasherColumn>,
	faderSections: Collection<types.faderSection>,
	faderSteps: Collection<types.faderData>,
	rotatorSections: Collection<types.rotatorSection>,
	rotatorSteps: Collection<types.rotatorData>,
	lightSettings: Collection<types.lightSettings>,
	colors: Collection<types.color>,
	lightGroups: Collection<types.lightGroup>,
	configurations: Collection<types.chassisConfiguration>,
}

return {}
