-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../../log")
local types = require("../../types")
local ChassisHandler = require("../ChassisHandler")
local FunctionsEditor = require("./FunctionsEditor")
local FadersEditor = require("./FunctionsEditor/FadersEditor")
local RotatorsEditor = require("./FunctionsEditor/RotatorsEditor")
local UIState = require("../UIState")
local Fusion = require("../../../Packages/fusion")

export type ColorState = {
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

function LightSettingsEditor.removeColorReferences(
	scope: types.Scope,
	functions: FunctionsEditor.FunctionsState,
	removedId: number
)
	local function remap(color: number): number
		return if color == removedId then 0 elseif color > removedId then color - 1 else color
	end
	for _, func in scope.peek(functions) do
		for _, pattern in scope.peek(func.patterns) do
			for _, section in scope.peek(pattern.flashers) do
				for _, column in scope.peek(section.columns) do
					local rows = table.clone(scope.peek(column.rows))
					for row, color in rows do
						rows[row] = remap(color)
					end
					column.rows:set(rows)
					UIState.unsavedChanges:set(true)
				end
			end
			for _, section in scope.peek(pattern.faders) do
				for _, step in scope.peek(section.data) do
					if scope.peek(step.type) ~= "Wait" then
						local color = (step :: FadersEditor.SimpleFaderState).color
						color:set(remap(scope.peek(color)))
						UIState.unsavedChanges:set(true)
					end
				end
			end
			for _, section in scope.peek(pattern.rotators) do
				for _, step in scope.peek(section.data) do
					if scope.peek(step.type) ~= "Wait" then
						local color = (step :: RotatorsEditor.AngleRotatorState).color
						color:set(remap(scope.peek(color)))
						UIState.unsavedChanges:set(true)
					end
				end
			end
		end
	end
end

function LightSettingsEditor.createActions(
	getContext: () -> (types.Scope, LightSettingsState, FunctionsEditor.FunctionsState)
)
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
		UIState.unsavedChanges:set(true)
	end

	function actions.removeColor(index: number)
		local scope, state, functions = getContext()
		local colors = scope.peek(state.colors)
		if colors[index] == nil then
			return
		end
		LightSettingsEditor.removeColorReferences(scope, functions, index)
		table.remove(colors, index)
		state.colors:set(colors)
		UIState.unsavedChanges:set(true)
	end

	function actions.updateColor(index: number, colorType: "partColor" | "lightColor" | "lightoColor", value: Color3)
		local scope, state = getContext()

		local colors = scope.peek(state.colors)
		local colorState = colors[index]
		if colorState then
			colorState[colorType]:set(value)
			UIState.unsavedChanges:set(true)
		end
	end

	function actions.updateColorName(index: number, name: string)
		local scope, state = getContext()

		local colors = scope.peek(state.colors)
		local colorState = colors[index]
		if colorState then
			colorState.name:set(name)
			UIState.unsavedChanges:set(true)
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
		UIState.unsavedChanges:set(true)
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
		UIState.unsavedChanges:set(true)
	end

	function actions.removeLightGroup(index: number)
		local scope, state = getContext()

		local lightGroups = scope.peek(state.lightGroups)
		table.remove(lightGroups, index)
		state.lightGroups:set(lightGroups)
		UIState.unsavedChanges:set(true)
	end

	function actions.setLightGroupLights(groupIndex: number, lights: { string })
		local scope, state = getContext()

		local lightGroups = scope.peek(state.lightGroups)
		local groupState = lightGroups[groupIndex]
		if groupState then
			groupState.lights:set(lights)
			UIState.unsavedChanges:set(true)
		end
	end

	function actions.updateLightGroupName(groupIndex: number, name: string)
		local scope, state = getContext()

		local lightGroups = scope.peek(state.lightGroups)
		local groupState = lightGroups[groupIndex]
		if groupState then
			groupState.name:set(name)
			UIState.unsavedChanges:set(true)
		end
	end

	return actions
end

return LightSettingsEditor
