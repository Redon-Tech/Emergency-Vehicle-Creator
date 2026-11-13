-- Redon Tech Emergency Vehicle Creator, MIT License
local typed = require("../../../Packages/typed")

local finite = typed.number()
local nonnegative = typed.number({ min = 0 })
local integer = typed.refine(nonnegative)(function(value, result)
	return if value % 1 == 0 then result.ok() else result.err("Expected a nonnegative integer")
end)
local text = typed.string()
local boolean = typed.boolean()

local function union(schemas: { [any]: typed.AnySchema }): typed.AnySchema
	local combined: typed.AnySchema? = nil
	for _, schema in schemas do
		combined = if combined then typed.union(combined, schema) else schema
	end
	assert(combined, "A union requires at least one schema")
	return combined
end

local function literals(values: { string }): typed.AnySchema
	local schemas = {}
	for _, value in values do
		table.insert(schemas, typed.literal(value))
	end
	return union(schemas)
end

local function enum(enumType: Enum): typed.AnySchema
	return typed.refine(typed.is<<EnumItem>>("EnumItem"))(function(value, result)
		return if value.EnumType == enumType
			then result.ok()
			else result.err("Expected an item from " .. tostring(enumType))
	end)
end

local function denseArray(schema: typed.AnySchema): typed.AnySchema
	return typed.refine(typed.iterable(integer, schema))(function(value, result)
		local count = 0
		for index in value do
			if index < 1 then
				return result.err("Array indexes must start at one")
			end
			count += 1
		end
		return if count == #value then result.ok() else result.err("Array indexes must be consecutive")
	end)
end

local keybinds = denseArray(enum(Enum.KeyCode))
local faderData = union({
	Simple = typed.table(
		{ type = literals({ "Simple" }), time = nonnegative, goal = finite, color = integer },
		{ strict = true }
	),
	Advanced = typed.table({
		type = literals({ "Advanced" }),
		time = nonnegative,
		goal = finite,
		color = integer,
		easingStyle = enum(Enum.EasingStyle),
		easingDirection = enum(Enum.EasingDirection),
	}, { strict = true }),
	Wait = typed.table({ type = literals({ "Wait" }), time = nonnegative }, { strict = true }),
})
local rotatorData = union({
	Angle = typed.table(
		{ type = literals({ "Angle" }), color = integer, velocity = finite, angle = finite },
		{ strict = true }
	),
	Infinite = typed.table({ type = literals({ "Infinite" }), color = integer, velocity = finite }, { strict = true }),
	Wait = typed.table({ type = literals({ "Wait" }), time = nonnegative }, { strict = true }),
})
local flasherColumn = typed.table({ lightName = text, rows = denseArray(integer) }, { strict = true })
local flasherFields = typed.table({
	waitTime = nonnegative,
	rowCount = integer,
	columns = denseArray(flasherColumn),
}, { strict = true })
local flasherSection = typed.refine(flasherFields)(function(value, result)
	for _, column in value.columns do
		if #column.rows ~= value.rowCount then
			return result.err("Column row count must match its section")
		end
	end
	return result.ok()
end)
local faderSection = typed.table({ lightName = text, data = denseArray(faderData) }, { strict = true })
local rotatorSection = typed.table({ lightName = text, data = denseArray(rotatorData) }, { strict = true })
local pattern = typed.table(
	{ flashers = denseArray(flasherSection), faders = denseArray(faderSection), rotators = denseArray(rotatorSection) },
	{ strict = true }
)
local activation = union({
	Standard = typed.table({
		type = literals({ "Standard" }),
		mode = literals({ "Cycle", "Set Pattern" }),
		pattern = integer,
		keybinds = keybinds,
	}, { strict = true }),
	Default = typed.table({ type = literals({ "Default" }), pattern = integer }, { strict = true }),
	Override = typed.table({
		type = literals({ "Override" }),
		mode = literals({ "Siren Override", "Park", "Brake", "Reverse" }),
		dependentFunction = text,
		dependentPattern = integer,
		siren = typed.optional(text),
	}, { strict = true }),
	["AG-Event"] = typed.table({
		type = literals({ "AG-Event" }),
		mode = literals({ "Stages", "Traffic Advisor", "Scene", "Ally Left", "Ally Right", "Rear Scene" }),
	}, { strict = true }),
	Conditional = typed.table({
		type = literals({ "Conditional" }),
		mode = literals({ "Always Active", "Keybind", "Function", "Siren" }),
		conditions = denseArray(typed.table({
			type = literals({ "Function" }),
			mode = literals({ "Is", "Is Not" }),
			dependentFunction = text,
			dependentPattern = integer,
		}, { strict = true })),
	}, { strict = true }),
})
local func = typed.table(
	{ weight = finite, name = text, activations = denseArray(activation), patterns = denseArray(pattern) },
	{ strict = true }
)
local modifier = typed.table({
	name = text,
	modifiedSirenName = text,
	parentSoundBehavior = literals({ "Play Parent Sound", "Plays Simultaneously" }),
	behavoir = literals({ "Play Automatically", "Require Parent Replay" }),
	delay = nonnegative,
}, { strict = true })
local hold = typed.table({
	name = text,
	type = literals({ "Siren", "Hold" }),
	behavoir = literals({ "Overrides Other Sounds", "Plays Simultaneously" }),
	keybinds = keybinds,
	modifiers = denseArray(modifier),
}, { strict = true })
local siren = union({
	Siren = hold,
	Hold = hold,
	Modifier = typed.table({ name = text, type = literals({ "Modifier" }), keybinds = keybinds }, { strict = true }),
})
local colorValue = typed.is<<Color3>>("Color3")
local color = typed.table(
	{ name = text, partColor = colorValue, lightColor = colorValue, lightoColor = colorValue },
	{ strict = true }
)
local lightGroup = typed.table({ name = text, lights = denseArray(text) }, { strict = true })
local lightSettings = typed.table({
	version = finite,
	colors = denseArray(color),
	lightGroups = denseArray(lightGroup),
	configuration = typed.table({
		shouldChangeNeons = boolean,
		shouldChangeLights = boolean,
		shouldChangeLightos = boolean,
		shouldChangeParticleEmitters = boolean,
		partTransparency = finite,
	}, { strict = true }),
}, { strict = true })

return {
	pattern = pattern,
	activation = activation,
	["function"] = func,
	siren = siren,
	color = color,
	lightGroup = lightGroup,
	lightSettings = lightSettings,
	configuration = typed.table(
		{ lightSettings = lightSettings, functions = denseArray(func), sirens = denseArray(siren) },
		{ strict = true }
	),
}
