-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../../log")
local types = require("../../types")
local Fusion = require("../../../Packages/fusion")
local utils = require("../utils")

export type ModifierState = {
	name: Fusion.Value<string>,
	modifiedSirenName: Fusion.Value<string>,
	parentSoundBehavior: Fusion.Value<types.ModifierParentSoundBehavior>,
	behavoir: Fusion.Value<types.ModifierBehavior>,
	delay: Fusion.Value<number>,
}

export type SirenHoldState = {
	name: Fusion.Value<string>,
	type: Fusion.Value<"Siren" | "Hold">,
	behavoir: Fusion.Value<types.SirenBehavior>,
	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>,
	modifiers: Fusion.Value<{ ModifierState }>,
}

export type SirenModifierState = {
	name: Fusion.Value<string>,
	type: Fusion.Value<"Modifier">,
	keybinds: Fusion.Value<{ Fusion.Value<Enum.KeyCode> }>,
}

type SirenState = SirenHoldState | SirenModifierState

export type SirensState = Fusion.Value<{ SirenState }>

local SirensEditor = {}

local function sirenTypeToState(scope: types.Scope, siren: types.siren): SirenState?
	local keybinds = {}
	for _, keybind in ipairs(siren.keybinds) do
		table.insert(keybinds, scope:Value(keybind))
	end

	if siren.type == "Siren" or siren.type == "Hold" then
		local modifiers = {}
		for _, modifier in ipairs(siren.modifiers) do
			table.insert(modifiers, {
				name = scope:Value(modifier.name),
				modifiedSirenName = scope:Value(modifier.modifiedSirenName),
				parentSoundBehavior = scope:Value(modifier.parentSoundBehavior),
				behavoir = scope:Value(modifier.behavoir),
				delay = scope:Value(modifier.delay),
			})
		end

		return {
			name = scope:Value(siren.name),
			type = scope:Value(siren.type),
			behavoir = scope:Value(siren.behavoir),
			keybinds = scope:Value(keybinds),
			modifiers = scope:Value(modifiers),
		}
	elseif siren.type == "Modifier" then
		return {
			name = scope:Value(siren.name),
			type = scope:Value<<"Modifier">>(siren.type),
			keybinds = scope:Value(keybinds),
		}
	else
		log.warn("Unknown siren type:", siren.type)
	end
	return nil
end

function SirensEditor.toState(scope: types.Scope, configuration: { types.siren }): SirensState
	local sirens = {} :: { SirenState }

	for _, siren in ipairs(configuration) do
		local sirenState = sirenTypeToState(scope, siren)
		if sirenState then
			table.insert(sirens, sirenState)
		end
	end

	return scope:Value(sirens)
end

function SirensEditor.toConfiguration(scope: types.Scope, state: SirensState): { types.siren }
	local sirens = {} :: { types.siren }

	for _, sirenState in ipairs(scope.peek(state)) do
		local siren = {
			name = scope.peek(sirenState.name),
			type = scope.peek(sirenState.type),
			keybinds = scope.peek(sirenState.keybinds),
		}

		if siren.type == "Siren" or siren.type == "Hold" then
			siren.behavoir = scope.peek((sirenState :: SirenHoldState).behavoir)
			siren.modifiers = {}

			for _, modifierState in ipairs(scope.peek((sirenState :: SirenHoldState).modifiers)) do
				table.insert(siren.modifiers, {
					name = scope.peek(modifierState.name),
					modifiedSirenName = scope.peek(modifierState.modifiedSirenName),
					parentSoundBehavior = scope.peek(modifierState.parentSoundBehavior),
					behavoir = scope.peek(modifierState.behavoir),
					delay = scope.peek(modifierState.delay),
				})
			end
		end

		table.insert(sirens, siren)
	end

	return sirens
end

function SirensEditor.createActions(getContext: () -> (types.Scope, SirensState))
	local actions = {}

	local function getAllSirenNames(): { string }
		local scope, sirensState = getContext()
		local names = {}

		for _, sirenState in ipairs(scope.peek(sirensState)) do
			table.insert(names, scope.peek(sirenState.name))
		end

		return names
	end

	function actions.addSiren(siren: types.siren): SirenState?
		(siren :: { name: string }).name = utils.getUniqueString(siren.name, getAllSirenNames())

		local scope, sirensState = getContext()

		local newSirenState = sirenTypeToState(scope, siren)
		if not newSirenState then
			log.warn("addSiren: Failed to convert siren to state:", siren)
			return
		end

		local currentSirens = scope.peek(sirensState)
		table.insert(currentSirens, newSirenState)
		sirensState:set(currentSirens)
		return newSirenState
	end

	function actions.removeSiren(index: number)
		local scope, sirensState = getContext()

		local currentSirens = scope.peek(sirensState)
		table.remove(currentSirens, index)
		sirensState:set(currentSirens)
	end

	--- Gets all sirens of type "Modifier" from the given SirensState.
	function actions.getAllModifiers(): { string }
		local scope, sirensState = getContext()
		local modifiers = {} :: { string }

		for _, sirenState in ipairs(scope.peek(sirensState)) do
			if scope.peek(sirenState.type) == "Modifier" then
				table.insert(modifiers, scope.peek(sirenState.name))
			end
		end

		return modifiers
	end

	--[[
        All Type Actions
    ]]

	function actions.updateSirenName(index: number, newName: string)
		local scope, sirensState = getContext()

		local siren = scope.peek(sirensState)[index]
		if not siren then
			log.warn("updateSirenName: Invalid siren index:", index)
			return
		end

		(siren.name :: Fusion.Value<string>):set(newName)
	end

	function actions.updateSirenType(index: number, newType: "Siren" | "Hold" | "Modifier")
		local scope, sirensState = getContext()

		local siren = scope.peek(sirensState)[index]
		if not siren then
			log.warn("updateSirenType: Invalid siren index:", index)
			return
		end

		local currentType = scope.peek(siren.type)
		if currentType == newType then
			return
		elseif newType == "Modifier" and (currentType == "Siren" or currentType == "Hold") then
			local newSirenState: SirenModifierState = {
				name = siren.name,
				type = scope:Value<<"Modifier">>("Modifier"),
				keybinds = siren.keybinds,
			}
			local currentSirens = scope.peek(sirensState)
			currentSirens[index] = newSirenState
			sirensState:set(currentSirens)
		elseif currentType == "Modifier" and (newType == "Siren" or newType == "Hold") then
			local newSirenState: SirenHoldState = {
				name = siren.name,
				type = scope:Value<<"Siren" | "Hold">>(newType),
				behavoir = scope:Value<<"Overrides Other Sounds">>("Overrides Other Sounds"),
				keybinds = siren.keybinds,
				modifiers = scope:Value({}),
			}
			local currentSirens = scope.peek(sirensState)
			currentSirens[index] = newSirenState
			sirensState:set(currentSirens)
		else
			(siren :: SirenHoldState).type:set(newType :: any)
		end
	end

	function actions.updateSirenKeybind(index: number, keybindIndex: number, newKeybind: Enum.KeyCode)
		local scope, sirensState = getContext()

		local siren = scope.peek(sirensState)[index]
		if not siren then
			log.warn("updateSirenKeybind: Invalid siren index:", index)
			return
		end

		local keybinds = scope.peek(siren.keybinds)
		keybinds[keybindIndex]:set(newKeybind)
	end

	--[[
        Siren/Hold Behavior
    ]]

	local function getSirenHoldState(index: number): SirenHoldState
		local scope, sirensState = getContext()

		local siren = scope.peek(sirensState)[index]
		if not siren then
			log.error("getSirenHoldState: Invalid siren index:", index)
		end

		if scope.peek(siren.type) == "Modifier" then
			log.error("getSirenHoldState: Cannot get a Siren/Hold state from a Modifier type siren")
		end

		return siren :: SirenHoldState
	end

	function actions.updateSirenBehavior(index: number, newBehavior: types.SirenBehavior)
		local siren = getSirenHoldState(index)

		siren.behavoir:set(newBehavior)
	end

	--[[
        Modifiers
    ]]

	function actions.addModifier(sirenIndex: number)
		local scope = getContext()
		local siren = getSirenHoldState(sirenIndex)

		local allModifiers = actions.getAllModifiers()
		local modifierToUse = allModifiers[1]
		if modifierToUse == nil then
			local newModifier = actions.addSiren({
				name = "New Modifier",
				type = "Modifier",
				keybinds = { Enum.KeyCode.None, Enum.KeyCode.None },
			})
			if newModifier ~= nil then
				modifierToUse = scope.peek(newModifier.name)
			end
		end
		if not modifierToUse then
			log.warn("addModifier: Failed to create or retrieve a Modifier siren")
			return
		end

		local newModifierState: ModifierState = {
			name = scope:Value(scope.peek(modifierToUse)),
			modifiedSirenName = scope:Value(`{scope.peek(modifierToUse)}{scope.peek(siren.name)}`),
			parentSoundBehavior = scope:Value<<"Play Parent Sound">>("Play Parent Sound"),
			behavoir = scope:Value<<"Play Automatically">>("Play Automatically"),
			delay = scope:Value(0),
		}

		local modifiers = scope.peek(siren.modifiers)
		table.insert(modifiers, newModifierState)
		siren.modifiers:set(modifiers)
	end

	function actions.removeModifier(sirenIndex: number, modifierIndex: number)
		local scope = getContext()
		local siren = getSirenHoldState(sirenIndex)

		local modifiers = scope.peek(siren.modifiers)
		table.remove(modifiers, modifierIndex)
		siren.modifiers:set(modifiers)
	end

	-- Helper function to get a modifier state given a siren index and modifier index
	local function getModifier(sirenIndex: number, modifierIndex: number): ModifierState
		local scope = getContext()
		local siren = getSirenHoldState(sirenIndex)

		local modifier = scope.peek(siren.modifiers)[modifierIndex]
		if not modifier then
			log.error("getModifier: Invalid modifier index:", modifierIndex)
		end
		return modifier
	end

	function actions.updateModifierName(sirenIndex: number, modifierIndex: number, newName: string)
		local modifier = getModifier(sirenIndex, modifierIndex)
		modifier.name:set(newName)
	end

	function actions.updateModifierSirenName(sirenIndex: number, modifierIndex: number, newModifiedSirenName: string)
		local modifier = getModifier(sirenIndex, modifierIndex)
		modifier.modifiedSirenName:set(newModifiedSirenName)
	end

	function actions.updateModifierParentSoundBehavior(
		sirenIndex: number,
		modifierIndex: number,
		newBehavior: types.ModifierParentSoundBehavior
	)
		local modifier = getModifier(sirenIndex, modifierIndex)
		modifier.parentSoundBehavior:set(newBehavior)
	end

	function actions.updateModifierBehavior(
		sirenIndex: number,
		modifierIndex: number,
		newBehavior: types.ModifierBehavior
	)
		local modifier = getModifier(sirenIndex, modifierIndex)
		modifier.behavoir:set(newBehavior)
	end

	function actions.updateModifierDelay(sirenIndex: number, modifierIndex: number, newDelay: number)
		local modifier = getModifier(sirenIndex, modifierIndex)
		modifier.delay:set(newDelay)
	end

	return actions
end

return SirensEditor
