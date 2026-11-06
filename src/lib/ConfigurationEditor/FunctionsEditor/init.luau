-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../../log")
local types = require("../../types")
local Fusion = require("../../../Packages/fusion")

local FlashersEditor = require("@self/FlashersEditor")
local FadersEditor = require("@self/FadersEditor")
local RotatorsEditor = require("@self/RotatorsEditor")

export type StandardActivationState = {
	type: Fusion.Value<"Standard">,
	mode: Fusion.Value<types.StandardActivationModes>,
	pattern: Fusion.Value<number>,
	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>,
}

export type DefaultActivationState = {
	type: Fusion.Value<"Default">,
	pattern: Fusion.Value<number>,
}

export type OverrideActivationState = {
	type: Fusion.Value<"Override">,
	mode: Fusion.Value<types.OverrideActivationModes>,
	siren: Fusion.Value<string?>,
	dependentFunction: Fusion.Value<string>,
	dependentPattern: Fusion.Value<number>,
}

export type AGEventActivationState = {
	type: Fusion.Value<"AG-Event">,
	mode: Fusion.Value<types.AGEventActivationModes>,
}

export type ActivationState =
	StandardActivationState
	| DefaultActivationState
	| OverrideActivationState
	| AGEventActivationState

export type PatternState = {
	flashers: FlashersEditor.FlashersState,
	faders: FadersEditor.FadersState,
	rotators: RotatorsEditor.RotatorsState,
}

export type FunctionState = {
	weight: Fusion.Value<number>,
	name: Fusion.Value<string>,
	activations: Fusion.Value<{ ActivationState }>,
	patterns: Fusion.Value<{ PatternState }>,
}

export type FunctionsState = Fusion.Value<{ FunctionState }>

local FunctionsEditor = {}

local function activationTypeToState(scope: types.Scope, activation: types.activation): ActivationState
	if activation.type == "Standard" then
		local keybinds = {}
		for _, keybind in ipairs(activation.keybinds) do
			table.insert(keybinds, scope:Value(keybind))
		end

		return {
			type = scope:Value<<"Standard">>("Standard"),
			mode = scope:Value(activation.mode),
			pattern = scope:Value(activation.pattern),
			keybinds = scope:Value(keybinds),
		}
	elseif activation.type == "Default" then
		return {
			type = scope:Value<<"Default">>("Default"),
			pattern = scope:Value(activation.pattern),
		}
	elseif activation.type == "Override" then
		return {
			type = scope:Value<<"Override">>("Override"),
			mode = scope:Value(activation.mode),
			siren = scope:Value(activation.siren),
			dependentFunction = scope:Value(activation.dependentFunction),
			dependentPattern = scope:Value(activation.dependentPattern),
		}
	elseif activation.type == "AG-Event" then
		return {
			type = scope:Value<<"AG-Event">>("AG-Event"),
			mode = scope:Value(activation.mode),
		}
	end

	error(`Unknown activation type: {activation.type}`)
end

local function patternToState(scope: types.Scope, pattern: types.pattern): PatternState
	return {
		flashers = FlashersEditor.toState(scope, pattern.flashers),
		faders = FadersEditor.toState(scope, pattern.faders),
		rotators = RotatorsEditor.toState(scope, pattern.rotators),
	}
end

local function patternsToState(scope: types.Scope, patterns: { types.pattern }): Fusion.Value<{ PatternState }>
	local patternStates = {} :: { PatternState }
	for _, pattern in ipairs(patterns) do
		table.insert(patternStates, patternToState(scope, pattern))
	end

	return scope:Value(patternStates)
end

local function functionTypeToState(scope: types.Scope, configuration: types.elsFunction): FunctionState
	local activations = {} :: { ActivationState }

	for _, activation in ipairs(configuration.activations) do
		table.insert(activations, activationTypeToState(scope, activation))
	end

	return {
		weight = scope:Value(configuration.weight),
		name = scope:Value(configuration.name),
		activations = scope:Value(activations),
		patterns = patternsToState(scope, configuration.patterns),
	}
end

function FunctionsEditor.toState(scope: types.Scope, configuration: { types.elsFunction }): FunctionsState
	local functions = {}

	for _, func in ipairs(configuration) do
		table.insert(functions, functionTypeToState(scope, func))
	end

	return scope:Value(functions)
end

function FunctionsEditor.fromState(scope: types.Scope, state: FunctionsState): { types.elsFunction }
	local functions = {}

	for _, funcState in ipairs(scope.peek(state)) do
		local activations = {}

		for _, activationState in ipairs(scope.peek(funcState.activations)) do
			local activation: types.activation

			if scope.peek(activationState.type) == "Standard" then
				local keybinds = {}
				for _, keybind in ipairs(scope.peek((activationState :: StandardActivationState).keybinds)) do
					table.insert(keybinds, scope.peek(keybind))
				end

				activation = {
					type = "Standard",
					mode = scope.peek<<types.StandardActivationModes>>(
						(activationState :: StandardActivationState).mode
					),
					pattern = scope.peek((activationState :: StandardActivationState).pattern),
					keybinds = keybinds,
				}
			elseif scope.peek(activationState.type) == "Default" then
				activation = {
					type = "Default",
					pattern = scope.peek((activationState :: DefaultActivationState).pattern),
				}
			elseif scope.peek(activationState.type) == "Override" then
				activation = {
					type = "Override",
					mode = scope.peek<<types.OverrideActivationModes>>(
						(activationState :: OverrideActivationState).mode
					),
					siren = scope.peek((activationState :: OverrideActivationState).siren),
					dependentFunction = scope.peek((activationState :: OverrideActivationState).dependentFunction),
					dependentPattern = scope.peek((activationState :: OverrideActivationState).dependentPattern),
				}
			elseif scope.peek(activationState.type) == "AG-Event" then
				activation = {
					type = "AG-Event",
					mode = scope.peek<<types.AGEventActivationModes>>((activationState :: AGEventActivationState).mode),
				}
			else
				log.error(`Unknown activation type: {scope.peek(activationState.type)}`)
			end

			table.insert(activations, activation)
		end

		local patterns: { types.pattern } = {}
		for _, patternState in ipairs(scope.peek(funcState.patterns)) do
			table.insert(patterns, {
				flashers = FlashersEditor.fromState(scope, patternState.flashers),
				faders = FadersEditor.fromState(scope, patternState.faders),
				rotators = RotatorsEditor.fromState(scope, patternState.rotators),
			})
		end

		table.insert(functions, {
			weight = scope.peek(funcState.weight),
			name = scope.peek(funcState.name),
			activations = activations,
			patterns = patterns,
		})
	end

	return functions
end

local function getFunctionNames(scope: types.Scope, state: FunctionsState): { string }
	local names = {}

	for _, funcState in ipairs(scope.peek(state)) do
		table.insert(names, scope.peek(funcState.name))
	end

	return names
end

function FunctionsEditor.createActions(getContext: () -> (types.Scope, FunctionsState))
	local actions = {}

	function actions.addFunction(func: types.elsFunction)
		local scope, state = getContext()

		func.name = scope.getUniqueString(func.name, getFunctionNames(scope, state))

		local currentFunctions = scope.peek(state)
		table.insert(currentFunctions, functionTypeToState(scope, func))
		state:set(currentFunctions)
	end

	function actions.removeFunction(index: number)
		local scope, state = getContext()

		local currentFunctions = scope.peek(state)
		table.remove(currentFunctions, index)
		for weight, func in ipairs(currentFunctions) do
			func.weight:set(weight)
		end
		state:set(currentFunctions)
	end

	function actions.updateFunctionWeight(fromIndex: number, toIndex: number)
		local scope, state = getContext()
		local currentFunctions = scope.peek(state)
		if currentFunctions[fromIndex] == nil or toIndex < 1 or toIndex % 1 ~= 0 then
			return
		end
		toIndex = math.min(toIndex, #currentFunctions)
		local reordered = table.clone(currentFunctions)
		local func = table.remove(reordered, fromIndex)
		if func == nil then
			log.warn("Cannot reorder missing function")
			return
		end
		table.insert(reordered, toIndex, func)
		for index, entry in ipairs(reordered) do
			entry.weight:set(index)
		end
		state:set(reordered)
	end

	function actions.updateFunctionName(index: number, newName: string)
		local scope, state = getContext()

		local currentFunctions = scope.peek(state)
		local func = currentFunctions[index]
		if func == nil then
			log.warn(`FunctionsEditor.renameFunction: No function at index {index}`)
			return
		end
		func.name:set(newName)
	end

	--[[
		Activations
	]]

	local function getFunction(functionIndex: number): FunctionState
		local scope, state = getContext()

		local currentFunctions = scope.peek(state)
		local func = currentFunctions[functionIndex]
		if func == nil then
			log.error(`FunctionsEditor.getFunction: No function at index {functionIndex}`)
		end
		return func
	end

	function actions.addActivation(functionIndex: number, activation: types.activation)
		local scope = getContext()

		local func = getFunction(functionIndex)

		local activations = scope.peek(func.activations)
		table.insert(activations, activationTypeToState(scope, activation))
		func.activations:set(activations)
	end

	function actions.removeActivation(functionIndex: number, activationIndex: number)
		local scope = getContext()

		local func = getFunction(functionIndex)

		local activations = scope.peek(func.activations)
		table.remove(activations, activationIndex)
		func.activations:set(activations)
	end

	local function getActivation(functionIndex: number, activationIndex: number): ActivationState
		local scope = getContext()
		local func = getFunction(functionIndex)

		local activation = scope.peek(func.activations)[activationIndex]
		if activation == nil then
			log.error(
				`FunctionsEditor.getActivation: No activation at index {activationIndex} for function {functionIndex}`
			)
		end
		return activation
	end

	function actions.updateActivationType(
		functionIndex: number,
		activationIndex: number,
		newType: "Standard" | "Default" | "Override" | "AG-Event"
	)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if newType == scope.peek(activation.type) then
			log.debug(`FunctionsEditor.updateActivationType: Activation type is already {newType}`)
			return
		end

		local newActivation: ActivationState
		if newType == "Standard" then
			local pattern = if scope.peek(activation.type) == "Default"
				then scope.peek((activation :: DefaultActivationState).pattern)
				else 0
			newActivation = {
				type = scope:Value<<"Standard">>("Standard"),
				mode = scope:Value<<"Cycle">>("Cycle"),
				pattern = scope:Value(pattern),
				keybinds = scope:Value({ scope:Value(Enum.KeyCode.None), scope:Value(Enum.KeyCode.None) }),
			}
		elseif newType == "Override" then
			newActivation = {
				type = scope:Value<<"Override">>("Override"),
				mode = scope:Value<<"Park">>("Park"),
				siren = scope:Value(nil),
				dependentFunction = scope:Value("No Dependent Function"),
				dependentPattern = scope:Value(0),
			}
		elseif newType == "Default" then
			local pattern = if scope.peek(activation.type) == "Standard"
				then scope.peek((activation :: StandardActivationState).pattern)
				else 0
			newActivation = {
				type = scope:Value<<"Default">>("Default"),
				pattern = scope:Value(pattern),
			}
		elseif newType == "AG-Event" then
			newActivation = {
				type = scope:Value<<"AG-Event">>("AG-Event"),
				mode = scope:Value<<"Stages">>("Stages"),
			}
		else
			log.warn(`FunctionsEditor.updateActivationType: Unknown activation type {newType}`)
			return
		end

		local func = getFunction(functionIndex)
		local activations = scope.peek(func.activations)
		activations[activationIndex] = newActivation
		func.activations:set(activations)
	end

	--[[
		Standard Activation
	]]

	function actions.updateStandardActivationMode(
		functionIndex: number,
		activationIndex: number,
		newMode: types.StandardActivationModes
	)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Standard" then
			log.warn(
				`FunctionsEditor.updateStandardActivationMode: Activation at index {activationIndex} for function {functionIndex} is not a Standard activation`
			)
			return
		end
		(activation :: StandardActivationState).mode:set(newMode)
	end

	function actions.updateStandardActivationPattern(functionIndex: number, activationIndex: number, newPattern: number)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Standard" then
			log.warn(
				`FunctionsEditor.updateStandardActivationPattern: Activation at index {activationIndex} for function {functionIndex} is not a Standard activation`
			)
			return
		end
		(activation :: StandardActivationState).pattern:set(newPattern)
	end

	function actions.updateStandardActivationKeybind(
		functionIndex: number,
		activationIndex: number,
		keybindIndex: number,
		newKeybind: Enum.KeyCode
	)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Standard" then
			log.warn(
				`FunctionsEditor.updateStandardActivationKeybind: Activation at index {activationIndex} for function {functionIndex} is not a Standard activation`
			)
			return
		end
		local keybinds = scope.peek((activation :: StandardActivationState).keybinds)
		keybinds[keybindIndex]:set(newKeybind)
	end

	--[[
		Default Activation
	]]

	function actions.updateDefaultActivationPattern(functionIndex: number, activationIndex: number, newPattern: number)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Default" then
			log.warn(
				`FunctionsEditor.updateDefaultActivationPattern: Activation at index {activationIndex} for function {functionIndex} is not a Default activation`
			)
			return
		end
		(activation :: DefaultActivationState).pattern:set(newPattern)
	end

	--[[
		Override Activation
	]]

	function actions.updateOverrideActivationMode(
		functionIndex: number,
		activationIndex: number,
		newMode: types.OverrideActivationModes
	)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Override" then
			log.warn(
				`FunctionsEditor.updateOverrideActivationMode: Activation at index {activationIndex} for function {functionIndex} is not an Override activation`
			)
			return
		end
		(activation :: OverrideActivationState).mode:set(newMode)
	end

	function actions.updateOverrideActivationSiren(functionIndex: number, activationIndex: number, newSiren: string?)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Override" then
			log.warn(
				`FunctionsEditor.updateOverrideActivationSiren: Activation at index {activationIndex} for function {functionIndex} is not an Override activation`
			)
			return
		end
		(activation :: OverrideActivationState).siren:set(newSiren)
	end

	function actions.updateOverrideActivationDependentFunction(
		functionIndex: number,
		activationIndex: number,
		newDependentFunction: string
	)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Override" then
			log.warn(
				`FunctionsEditor.updateOverrideActivationDependentFunction: Activation at index {activationIndex} for function {functionIndex} is not an Override activation`
			)
			return
		end
		(activation :: OverrideActivationState).dependentFunction:set(newDependentFunction)
	end

	function actions.updateOverrideActivationDependentPattern(
		functionIndex: number,
		activationIndex: number,
		newDependentPattern: number
	)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "Override" then
			log.warn(
				`FunctionsEditor.updateOverrideActivationDependentPattern: Activation at index {activationIndex} for function {functionIndex} is not an Override activation`
			)
			return
		end
		(activation :: OverrideActivationState).dependentPattern:set(newDependentPattern)
	end

	--[[
		AG-Event Activation
	]]

	function actions.updateAGEventActivationMode(
		functionIndex: number,
		activationIndex: number,
		newMode: types.AGEventActivationModes
	)
		local scope = getContext()
		local activation = getActivation(functionIndex, activationIndex)
		if scope.peek(activation.type) ~= "AG-Event" then
			log.warn(
				`FunctionsEditor.updateAGEventActivationMode: Activation at index {activationIndex} for function {functionIndex} is not an AG-Event activation`
			)
			return
		end
		(activation :: AGEventActivationState).mode:set(newMode)
	end

	--[[
		Patterns
	]]

	function actions.addPattern(functionId: number, pattern: types.pattern)
		local scope = getContext()
		local funcState = getFunction(functionId)

		local currentPatterns = scope.peek(funcState.patterns)
		table.insert(currentPatterns, patternToState(scope, pattern))
		funcState.patterns:set(currentPatterns)
	end

	function actions.removePattern(functionId: number, index: number)
		local scope = getContext()
		local funcState = getFunction(functionId)

		local currentPatterns = scope.peek(funcState.patterns)
		table.remove(currentPatterns, index)
		funcState.patterns:set(currentPatterns)
	end

	function actions.updatePatternPosition(functionId: number, fromIndex: number, toIndex: number)
		local scope = getContext()
		local funcState = getFunction(functionId)
		local currentPatterns = scope.peek(funcState.patterns)
		if currentPatterns[fromIndex] == nil or toIndex < 1 or toIndex % 1 ~= 0 then
			return
		end
		toIndex = math.min(toIndex, #currentPatterns)
		local reordered = table.clone(currentPatterns)
		local patternToMove = table.remove(reordered, fromIndex)
		if patternToMove == nil then
			log.warn("Cannot reorder missing pattern")
			return
		end
		table.insert(reordered, toIndex, patternToMove)
		funcState.patterns:set(reordered)
	end

	return actions
end

return FunctionsEditor
