-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../../../log")
local types = require("../../../types")
local UIState = require("../../UIState")
local Fusion = require("../../../../Packages/fusion")

export type SimpleFaderState = {
	type: Fusion.Value<"Simple">,
	time: Fusion.Value<number>,
	goal: Fusion.Value<number>,
	color: Fusion.Value<number>,
}

export type AdvancedFaderState = {
	type: Fusion.Value<"Advanced">,
	time: Fusion.Value<number>,
	goal: Fusion.Value<number>,
	color: Fusion.Value<number>,
	easingStyle: Fusion.Value<Enum.EasingStyle>,
	easingDirection: Fusion.Value<Enum.EasingDirection>,
}

export type WaitState = {
	type: Fusion.Value<"Wait">,
	time: Fusion.Value<number>,
}

export type FaderTweenState = SimpleFaderState | AdvancedFaderState | WaitState

export type FaderSectionState = {
	lightName: Fusion.Value<string>,
	data: Fusion.Value<{ FaderTweenState }>,
}

export type FadersState = Fusion.Value<{ FaderSectionState }>

local FadersEditor = {}

local function faderStepToState(scope: types.Scope, data: types.faderData): FaderTweenState
	if data.type == "Simple" then
		return {
			type = scope:Value<<"Simple">>("Simple"),
			time = scope:Value(data.time),
			goal = scope:Value(data.goal),
			color = scope:Value(data.color),
		}
	elseif data.type == "Advanced" then
		return {
			type = scope:Value<<"Advanced">>("Advanced"),
			time = scope:Value(data.time),
			goal = scope:Value(data.goal),
			color = scope:Value(data.color),
			easingStyle = scope:Value(data.easingStyle),
			easingDirection = scope:Value(data.easingDirection),
		}
	elseif data.type == "Wait" then
		return {
			type = scope:Value<<"Wait">>("Wait"),
			time = scope:Value(data.time),
		}
	else
		error("Unknown fader data type: " .. tostring(data.type))
	end
end

local function faderSectionToState(scope: types.Scope, section: types.faderSection): FaderSectionState
	local data = {}
	for _, tween in ipairs(section.data) do
		table.insert(data, faderStepToState(scope, tween))
	end

	return {
		lightName = scope:Value(section.lightName),
		data = scope:Value(data),
	}
end

function FadersEditor.toState(scope: types.Scope, faders: { types.faderSection }): FadersState
	local faderSections = {}
	for _, section in ipairs(faders) do
		table.insert(faderSections, faderSectionToState(scope, section))
	end

	return scope:Value(faderSections)
end

function FadersEditor.fromState(scope: types.Scope, fadersState: FadersState): { types.faderSection }
	local faders: { types.faderSection } = {}
	for _, faderSectionState in ipairs(scope.peek(fadersState)) do
		local data: { types.faderData } = {}
		for _, tweenState in ipairs(scope.peek(faderSectionState.data)) do
			local tweenType = scope.peek(tweenState.type)

			if tweenType == "Simple" then
				local tween = tweenState :: SimpleFaderState
				table.insert(data, {
					type = "Simple",
					time = scope.peek(tween.time),
					goal = scope.peek(tween.goal),
					color = scope.peek(tween.color),
				})
			elseif tweenType == "Advanced" then
				local tween = tweenState :: AdvancedFaderState
				table.insert(data, {
					type = "Advanced",
					time = scope.peek(tween.time),
					goal = scope.peek(tween.goal),
					color = scope.peek(tween.color),
					easingStyle = scope.peek(tween.easingStyle),
					easingDirection = scope.peek(tween.easingDirection),
				})
			elseif tweenType == "Wait" then
				table.insert(data, {
					type = "Wait",
					time = scope.peek(tweenState.time),
				})
			else
				error("Unknown fader data type: " .. tostring(tweenType))
			end
		end
		table.insert(faders, {
			lightName = scope.peek(faderSectionState.lightName),
			data = data,
		})
	end

	return faders
end

function FadersEditor.createActions(
	getContext: (functionId: number, patternIndex: number) -> (types.Scope, FadersState)
)
	local actions = {}

	function actions.addFaderSection(
		functionId: number,
		patternIndex: number,
		section: types.faderSection,
		atPoint: number?
	)
		local scope, state = getContext(functionId, patternIndex)

		local faderSections = scope.peek(state)
		table.insert(faderSections, atPoint or #faderSections + 1, faderSectionToState(scope, section))
		state:set(faderSections)
		UIState.unsavedChanges:set(true)
	end

	function actions.removeFaderSection(functionId: number, patternIndex: number, sectionIndex: number)
		local scope, state = getContext(functionId, patternIndex)

		local faderSections = scope.peek(state)
		table.remove(faderSections, sectionIndex)
		state:set(faderSections)
		UIState.unsavedChanges:set(true)
	end

	local function getFaderSectionState(
		functionId: number,
		patternIndex: number,
		sectionIndex: number
	): FaderSectionState
		local scope, state = getContext(functionId, patternIndex)

		local faderSections = scope.peek(state)
		local sectionState = faderSections[sectionIndex]
		if sectionState == nil then
			error(
				`No fader section found at index {sectionIndex} for patternIndex {patternIndex} and functionId {functionId}`
			)
		end

		return sectionState
	end

	function actions.updateFaderSectionLightName(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		newLightName: string
	)
		local sectionState = getFaderSectionState(functionId, patternIndex, sectionIndex)

		sectionState.lightName:set(newLightName)
		UIState.unsavedChanges:set(true)
	end

	--[[
		Fader Step Actions
	]]

	function actions.addFaderStep(functionId: number, patternIndex: number, sectionIndex: number, step: types.faderData)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFaderSectionState(functionId, patternIndex, sectionIndex)

		local steps = scope.peek(sectionState.data)
		table.insert(steps, faderStepToState(scope, step))
		sectionState.data:set(steps)
		UIState.unsavedChanges:set(true)
	end

	function actions.removeFaderStep(functionId: number, patternIndex: number, sectionIndex: number, stepIndex: number)
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFaderSectionState(functionId, patternIndex, sectionIndex)

		local steps = scope.peek(sectionState.data)
		table.remove(steps, stepIndex)
		sectionState.data:set(steps)
		UIState.unsavedChanges:set(true)
	end

	local function getFaderStepState(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number
	): FaderTweenState
		local scope = getContext(functionId, patternIndex)
		local sectionState = getFaderSectionState(functionId, patternIndex, sectionIndex)

		local steps = scope.peek(sectionState.data)
		local stepState = steps[stepIndex]
		if stepState == nil then
			error(
				`No fader step found at index {stepIndex} for sectionIndex {sectionIndex}, patternIndex {patternIndex}, and functionId {functionId}`
			)
		end

		return stepState
	end

	function actions.updateFaderStepType(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newType: "Simple" | "Advanced" | "Wait"
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getFaderStepState(functionId, patternIndex, sectionIndex, stepIndex)
		if scope.peek(stepState.type) == newType then
			return
		end

		local newStepState: FaderTweenState
		if newType == "Simple" then
			local goal = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: SimpleFaderState).goal)
				else 0
			local color = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: SimpleFaderState).color)
				else 4
			newStepState = {
				type = scope:Value<<"Simple">>("Simple"),
				time = stepState.time,
				goal = scope:Value(goal),
				color = scope:Value(color),
			}
		elseif newType == "Advanced" then
			local goal = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: SimpleFaderState).goal)
				else 0
			local color = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: SimpleFaderState).color)
				else 4
			newStepState = {
				type = scope:Value<<"Advanced">>("Advanced"),
				time = stepState.time,
				goal = scope:Value(goal),
				color = scope:Value(color),
				easingStyle = scope:Value(Enum.EasingStyle.Linear),
				easingDirection = scope:Value(Enum.EasingDirection.In),
			}
		elseif newType == "Wait" then
			newStepState = {
				type = scope:Value<<"Wait">>("Wait"),
				time = stepState.time,
			}
		else
			log.warn("Unknown fader step type: " .. tostring(newType))
			return
		end

		local sectionState = getFaderSectionState(functionId, patternIndex, sectionIndex)
		local steps = scope.peek(sectionState.data)
		steps[stepIndex] = newStepState
		sectionState.data:set(steps)
		UIState.unsavedChanges:set(true)
	end

	function actions.updateFaderStepTime(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newTime: number
	)
		local stepState = getFaderStepState(functionId, patternIndex, sectionIndex, stepIndex);

		(stepState :: SimpleFaderState).time:set(newTime)
		UIState.unsavedChanges:set(true)
	end

	--[[
		Shared actions for Simple and Advanced fader steps
	]]

	function actions.updateFaderStepGoal(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newGoal: number
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getFaderStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) ~= "Simple" and scope.peek(stepState.type) ~= "Advanced" then
			return
		end

		(stepState :: SimpleFaderState).goal:set(newGoal)
		UIState.unsavedChanges:set(true)
	end

	function actions.updateFaderStepColor(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newColor: number
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getFaderStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) ~= "Simple" and scope.peek(stepState.type) ~= "Advanced" then
			return
		end

		(stepState :: SimpleFaderState).color:set(newColor)
		UIState.unsavedChanges:set(true)
	end

	--[[
		Actions specific to Advanced fader steps
	]]

	function actions.updateFaderStepEasingStyle(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newEasingStyle: Enum.EasingStyle
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getFaderStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) ~= "Advanced" then
			return
		end

		(stepState :: AdvancedFaderState).easingStyle:set(newEasingStyle)
		UIState.unsavedChanges:set(true)
	end

	function actions.updateFaderStepEasingDirection(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newEasingDirection: Enum.EasingDirection
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getFaderStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) ~= "Advanced" then
			return
		end

		(stepState :: AdvancedFaderState).easingDirection:set(newEasingDirection)
		UIState.unsavedChanges:set(true)
	end

	return actions
end

return FadersEditor
