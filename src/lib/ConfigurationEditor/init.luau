-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../log")
local types = require("../types")
local ChassisHandler = require("./ChassisHandler")
local Fusion = require("../../Packages/fusion")

local LightSettingsEditor = require("@self/LightSettingsEditor")
local SirensEditor = require("@self/SirensEditor")

type PatternState = {
	flashers: Fusion.Value<{ types.flasherSectionState }>,
	faders: Fusion.Value<{ types.faderSectionState }>,
	rotators: Fusion.Value<{ types.rotatorSectionState }>,
}

type FunctionState = {
	weight: Fusion.Value<number>,
	name: Fusion.Value<string>,
	activations: Fusion.Value<{ types.activationState }>,
	patterns: Fusion.Value<{ PatternState }>,
}

type ConfigurationState = {
	lightSettings: LightSettingsEditor.LightSettingsState,
	functions: Fusion.Value<{ FunctionState }>,
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
		functions = ConfigurationEditor.scope:Value({}),
		sirens = SirensEditor.toState(ConfigurationEditor.scope, configuration.sirens),
	})
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
	return scope, current.lightSettings
end)

local SirensEditorActions = SirensEditor.createActions(function()
	local scope, current = getContext()
	return scope, current.sirens
end)

local actions = {}

for _, editorActions in { LightSettingsEditorActions :: { [any]: unknown }, SirensEditorActions } do
	for actionName, action in editorActions do
		assert(actions[actionName] == nil, `Duplicate action name: {actionName}`)

		actions[actionName] = action
	end
end

return (
	setmetatable(ConfigurationEditor, {
		__index = actions,
	}) :: any
) :: typeof(ConfigurationEditor) & typeof(LightSettingsEditorActions) & typeof(SirensEditorActions)
