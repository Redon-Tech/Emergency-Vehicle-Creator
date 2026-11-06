-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../log")
local types = require("../types")
local ChassisHandler = require("./ChassisHandler")
local UIState = require("./UIState")
local Fusion = require("../../Packages/fusion")

local LightSettingsEditor = require("@self/LightSettingsEditor")
local SirensEditor = require("@self/SirensEditor")
local FunctionsEditor = require("@self/FunctionsEditor")
local FadersEditor = require("@self/FunctionsEditor/FadersEditor")
local RotatorsEditor = require("@self/FunctionsEditor/RotatorsEditor")
local FlashersEditor = require("@self/FunctionsEditor/FlashersEditor")

type ConfigurationState = {
	lightSettings: LightSettingsEditor.LightSettingsState,
	functions: FunctionsEditor.FunctionsState,
	sirens: SirensEditor.SirensState,
}

local ConfigurationEditor = {}
ConfigurationEditor.scope = nil :: types.Scope?

function ConfigurationEditor.init(baseScope: types.Scope)
	local scope = baseScope:innerScope()
	ConfigurationEditor.scope = scope
	ConfigurationEditor.baseScope = baseScope
	ConfigurationEditor.current = baseScope:Value(nil) :: Fusion.Value<ConfigurationState?>
end

function ConfigurationEditor.load(configuration: ChassisHandler.chassisConfiguration)
	if ConfigurationEditor.scope == nil then
		log.warn("ConfigurationEditor.load() called without initialized scope")
		return
	end
	if Fusion.peek(ConfigurationEditor.current) ~= nil then
		log.warn("ConfigurationEditor.load() called while already loaded")
		return
	end
	log.debug("ConfigurationEditor.load with", configuration)

	ConfigurationEditor.current:set({
		lightSettings = LightSettingsEditor.toState(ConfigurationEditor.scope, configuration.lightSettings),
		functions = FunctionsEditor.toState(ConfigurationEditor.scope, configuration.functions),
		sirens = SirensEditor.toState(ConfigurationEditor.scope, configuration.sirens),
	})
	UIState.unsavedChanges:set(false)
end

function ConfigurationEditor.toConfiguration(): ChassisHandler.chassisConfiguration?
	local scope = ConfigurationEditor.scope
	local current = Fusion.peek(ConfigurationEditor.current)
	if scope == nil or current == nil then
		log.warn("Cannot export without a loaded configuration")
		return
	end

	return {
		lightSettings = LightSettingsEditor.toConfiguration(scope, current.lightSettings),
		functions = FunctionsEditor.fromState(scope, current.functions),
		sirens = SirensEditor.toConfiguration(scope, current.sirens),
	}
end

function ConfigurationEditor.unload()
	if Fusion.peek(ConfigurationEditor.current) == nil then
		log.warn("ConfigurationEditor.unload() called while not loaded")
		return
	end
	if ConfigurationEditor.scope == nil then
		log.warn("ConfigurationEditor.unload() called without initialized scope")
		return
	end
	log.debug("ConfigurationEditor.unload")

	ConfigurationEditor.current:set(nil)
	ConfigurationEditor.scope:doCleanup()
	ConfigurationEditor.scope = ConfigurationEditor.baseScope:innerScope()
end

--[[
	Setup Actions
]]

local function getContext()
	local current = Fusion.peek(ConfigurationEditor.current)
	assert(
		ConfigurationEditor.scope ~= nil and current ~= nil,
		"ConfigurationEditor getContext() called while not loaded"
	)

	return ConfigurationEditor.scope, current
end

local LightSettingsEditorActions = LightSettingsEditor.createActions(function()
	local scope, current = getContext()
	return scope, current.lightSettings, current.functions
end)

local SirensEditorActions = SirensEditor.createActions(function()
	local scope, current = getContext()
	return scope, current.sirens
end)

local FunctionsEditorActions = FunctionsEditor.createActions(function()
	local scope, current = getContext()
	return scope, current.functions
end)

local function getPatternContext(functionId: number, patternIndex: number)
	local scope, current = getContext()
	local functionState = scope.peek(current.functions)[functionId]
	assert(functionState ~= nil, `No function found at index {functionId}`)
	local patternState = scope.peek(functionState.patterns)[patternIndex]
	assert(patternState ~= nil, `No pattern found at index {patternIndex}`)
	return scope, patternState
end

local FlashersEditorActions = FlashersEditor.createActions(function(functionId: number, patternIndex: number)
	local scope, pattern = getPatternContext(functionId, patternIndex)
	return scope, pattern.flashers
end)

local FadersEditorActions = FadersEditor.createActions(function(functionId: number, patternIndex: number)
	local scope, pattern = getPatternContext(functionId, patternIndex)
	return scope, pattern.faders
end)

local RotatorsEditorActions = RotatorsEditor.createActions(function(functionId: number, patternIndex: number)
	local scope, pattern = getPatternContext(functionId, patternIndex)
	return scope, pattern.rotators
end)

local actions: { [string]: any } = {}

local actionGroups: { { [string]: any } } = {
	LightSettingsEditorActions,
	SirensEditorActions,
	FunctionsEditorActions,
	FlashersEditorActions,
	FadersEditorActions,
	RotatorsEditorActions,
}
for _, editorActions in actionGroups do
	for actionName, action in editorActions do
		assert(actions[actionName] == nil, `Duplicate action name: {actionName}`)

		actions[actionName] = action
	end
end

return (
	setmetatable(ConfigurationEditor, {
		__index = actions,
	}) :: any
) :: typeof(ConfigurationEditor) & typeof(LightSettingsEditorActions) & typeof(SirensEditorActions) & typeof(FunctionsEditorActions) & typeof(FlashersEditorActions) & typeof(FadersEditorActions) & typeof(RotatorsEditorActions)
