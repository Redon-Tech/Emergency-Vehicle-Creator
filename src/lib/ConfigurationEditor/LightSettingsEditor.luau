-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../../log")
local types = require("../../types")
local ChassisHandler = require("../ChassisHandler")
local Fusion = require("../../../Packages/fusion")

type ColorState = {
	name: Fusion.Value<string>,
	partColor: Fusion.Value<Color3>,
	lightColor: Fusion.Value<Color3>,
	lightoColor: Fusion.Value<Color3>,
}

export type LightSettingsState = {
	colors: Fusion.Value<{ ColorState }>,
	configuration: {
		shouldChangeNeons: Fusion.Value<boolean>,
		shouldChangeLights: Fusion.Value<boolean>,
		shouldChangeLightos: Fusion.Value<boolean>,
		shouldChangeParticleEmitters: Fusion.Value<boolean>,
		partTransparency: Fusion.Value<number>,
	},
	lightGroups: Fusion.Value<{
		{
			name: Fusion.Value<string>,
			lights: Fusion.Value<{ string }>,
		}
	}>,
}

export type LightSettingConfigurationKeys =
	"shouldChangeNeons"
	| "shouldChangeLights"
	| "shouldChangeLightos"
	| "shouldChangeParticleEmitters"
	| "partTransparency"

local LightSettingsEditor = {}

function LightSettingsEditor.toState(
	scope: types.Scope,
	configuration: ChassisHandler.lightSettings
): LightSettingsState
	log.debug("LightSettingsEditor.toState called with configuration", configuration)
	LightSettingsEditor.version = configuration.version

	local colors = {}
	for _, color in ipairs(configuration.colors) do
		table.insert(colors, {
			name = scope:Value(color.name),
			partColor = scope:Value(color.partColor),
			lightColor = scope:Value(color.lightColor),
			lightoColor = scope:Value(color.lightoColor),
		})
	end

	local lightGroups = {}
	for _, group in ipairs(configuration.lightGroups) do
		table.insert(lightGroups, {
			name = scope:Value(group.name),
			lights = scope:Value(group.lights),
		})
	end

	return {
		colors = scope:Value(colors),
		configuration = {
			shouldChangeNeons = scope:Value(configuration.configuration.shouldChangeNeons),
			shouldChangeLights = scope:Value(configuration.configuration.shouldChangeLights),
			shouldChangeLightos = scope:Value(configuration.configuration.shouldChangeLightos),
			shouldChangeParticleEmitters = scope:Value(configuration.configuration.shouldChangeParticleEmitters),
			partTransparency = scope:Value(configuration.configuration.partTransparency),
		},
		lightGroups = scope:Value(lightGroups),
	}
end

function LightSettingsEditor.toConfiguration(
	scope: types.Scope,
	state: LightSettingsState
): ChassisHandler.lightSettings
	log.debug("LightSettingsEditor.toConfiguration called with state", state)
	local colors = {}
	for _, colorState in ipairs(scope.peek(state.colors)) do
		table.insert(colors, {
			name = scope.peek(colorState.name),
			partColor = scope.peek(colorState.partColor),
			lightColor = scope.peek(colorState.lightColor),
			lightoColor = scope.peek(colorState.lightoColor),
		})
	end

	local lightGroups = {}
	for _, groupState in ipairs(scope.peek(state.lightGroups)) do
		table.insert(lightGroups, {
			name = scope.peek(groupState.name),
			lights = scope.peek(groupState.lights),
		})
	end

	return {
		version = LightSettingsEditor.version,
		colors = colors,
		configuration = {
			shouldChangeNeons = scope.peek(state.configuration.shouldChangeNeons),
			shouldChangeLights = scope.peek(state.configuration.shouldChangeLights),
			shouldChangeLightos = scope.peek(state.configuration.shouldChangeLightos),
			shouldChangeParticleEmitters = scope.peek(state.configuration.shouldChangeParticleEmitters),
			partTransparency = scope.peek(state.configuration.partTransparency),
		},
		lightGroups = lightGroups,
	}
end

function LightSettingsEditor.createActions(getContext: () -> (types.Scope, LightSettingsState))
	local actions = {}

	--[[
		Colors
	]]

	function actions.addColor(color: ChassisHandler.color)
		local scope, state = getContext()

		local colors = scope.peek(state.colors)
		table.insert(colors, {
			name = scope:Value(color.name),
			partColor = scope:Value(color.partColor),
			lightColor = scope:Value(color.lightColor),
			lightoColor = scope:Value(color.lightoColor),
		})
		state.colors:set(colors)
	end

	function actions.removeColor(index: number)
		local scope, state = getContext()

		local colors = scope.peek(state.colors)
		table.remove(colors, index)
		state.colors:set(colors)
	end

	function actions.updateColor(index: number, colorType: "partColor" | "lightColor" | "lightoColor", value: Color3)
		local scope, state = getContext()

		local colors = scope.peek(state.colors)
		local colorState = colors[index]
		if colorState then
			colorState[colorType]:set(value)
		end
	end

	function actions.updateColorName(index: number, name: string)
		local scope, state = getContext()

		local colors = scope.peek(state.colors)
		local colorState = colors[index]
		if colorState then
			colorState.name:set(name)
		end
	end

	--[[
		Configuration
	]]

	function actions.getConfiguration(key: LightSettingConfigurationKeys): unknown
		local scope, state = getContext()
		return scope.peek(state.configuration[key])
	end

	function actions.updateConfiguration(key: LightSettingConfigurationKeys, value: unknown)
		local _, state = getContext()

		state.configuration[key]:set(value)
	end

	--[[
		Light Groups
	]]

	function actions.addLightGroup(group: { name: string, lights: { string } })
		local scope, state = getContext()

		local lightGroups = scope.peek(state.lightGroups)
		table.insert(lightGroups, {
			name = scope:Value(group.name),
			lights = scope:Value(group.lights),
		})
		state.lightGroups:set(lightGroups)
	end

	function actions.removeLightGroup(index: number)
		local scope, state = getContext()

		local lightGroups = scope.peek(state.lightGroups)
		table.remove(lightGroups, index)
		state.lightGroups:set(lightGroups)
	end

	function actions.setLightGroupLights(groupIndex: number, lights: { string })
		local scope, state = getContext()

		local lightGroups = scope.peek(state.lightGroups)
		local groupState = lightGroups[groupIndex]
		if groupState then
			groupState.lights:set(lights)
		end
	end

	function actions.updateLightGroupName(groupIndex: number, name: string)
		local scope, state = getContext()

		local lightGroups = scope.peek(state.lightGroups)
		local groupState = lightGroups[groupIndex]
		if groupState then
			groupState.name:set(name)
		end
	end

	return actions
end

return LightSettingsEditor
