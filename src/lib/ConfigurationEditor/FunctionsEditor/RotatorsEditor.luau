-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require("../../../log")
local types = require("../../../types")
local Fusion = require("../../../../Packages/fusion")

export type AngleRotatorState = {
	type: Fusion.Value<"Angle">,
	velocity: Fusion.Value<number>,
	color: Fusion.Value<number>,
	angle: Fusion.Value<number>,
}

export type InfiniteRotatorState = {
	type: Fusion.Value<"Infinite">,
	velocity: Fusion.Value<number>,
	color: Fusion.Value<number>,
}

export type WaitState = {
	type: Fusion.Value<"Wait">,
	time: Fusion.Value<number>,
}

export type RotatorDataState = AngleRotatorState | InfiniteRotatorState | WaitState

export type RotatorSectionState = {
	lightName: Fusion.Value<string>,
	data: Fusion.Value<{ RotatorDataState }>,
}

export type RotatorsState = Fusion.Value<{ RotatorSectionState }>

local RotatorsEditor = {}

local function rotatorDataToState(scope: types.Scope, data: types.rotatorData): RotatorDataState
	if data.type == "Angle" then
		return {
			type = scope:Value<<"Angle">>("Angle"),
			velocity = scope:Value(data.velocity),
			color = scope:Value(data.color),
			angle = scope:Value(data.angle),
		}
	elseif data.type == "Infinite" then
		return {
			type = scope:Value<<"Infinite">>("Infinite"),
			velocity = scope:Value(data.velocity),
			color = scope:Value(data.color),
		}
	elseif data.type == "Wait" then
		return {
			type = scope:Value<<"Wait">>("Wait"),
			time = scope:Value(data.time),
		}
	else
		error("Unknown rotator data type: " .. tostring(data.type))
	end
end

local function rotatorSectionToState(scope: types.Scope, section: types.rotatorSection): RotatorSectionState
	local data = {}
	for _, rotator in ipairs(section.data) do
		table.insert(data, rotatorDataToState(scope, rotator))
	end

	return {
		lightName = scope:Value(section.lightName),
		data = scope:Value(data),
	}
end

function RotatorsEditor.toState(scope: types.Scope, rotators: { types.rotatorSection }): RotatorsState
	local rotatorSections = {}
	for _, section in ipairs(rotators) do
		table.insert(rotatorSections, rotatorSectionToState(scope, section))
	end

	return scope:Value(rotatorSections)
end

function RotatorsEditor.fromState(scope: types.Scope, rotatorsState: RotatorsState): { types.rotatorSection }
	local rotators: { types.rotatorSection } = {}
	for _, rotatorSectionState in ipairs(scope.peek(rotatorsState)) do
		local data: { types.rotatorData } = {}
		for _, rotatorDataState in ipairs(scope.peek(rotatorSectionState.data)) do
			local rotatorType = scope.peek(rotatorDataState.type)
			if rotatorType == "Angle" then
				local rotator = rotatorDataState :: AngleRotatorState
				table.insert(data, {
					type = "Angle",
					velocity = scope.peek(rotator.velocity),
					color = scope.peek(rotator.color),
					angle = scope.peek(rotator.angle),
				})
			elseif rotatorType == "Infinite" then
				local rotator = rotatorDataState :: InfiniteRotatorState
				table.insert(data, {
					type = "Infinite",
					velocity = scope.peek(rotator.velocity),
					color = scope.peek(rotator.color),
				})
			elseif rotatorType == "Wait" then
				local rotator = rotatorDataState :: WaitState
				table.insert(data, {
					type = "Wait",
					time = scope.peek(rotator.time),
				})
			else
				error("Unknown rotator data type: " .. tostring(rotatorType))
			end
		end
		table.insert(rotators, {
			lightName = scope.peek(rotatorSectionState.lightName),
			data = data,
		})
	end

	return rotators
end

function RotatorsEditor.createActions(
	getContext: (functionId: number, patternIndex: number) -> (types.Scope, RotatorsState)
)
	local actions = {}

	function actions.addRotatorSection(
		functionId: number,
		patternIndex: number,
		section: types.rotatorSection,
		atPoint: number?
	)
		local scope, state = getContext(functionId, patternIndex)

		local currentSections = scope.peek(state)
		table.insert(currentSections, atPoint or #currentSections + 1, rotatorSectionToState(scope, section))
		state:set(currentSections)
	end

	function actions.removeRotatorSection(functionId: number, patternIndex: number, index: number)
		local scope, state = getContext(functionId, patternIndex)

		local currentSections = scope.peek(state)
		table.remove(currentSections, index)
		state:set(currentSections)
	end

	local function getRotatorSectionState(functionId: number, patternIndex: number, index: number): RotatorSectionState
		local scope, state = getContext(functionId, patternIndex)

		local currentSections = scope.peek(state)
		local sectionState = currentSections[index]
		if sectionState == nil then
			error(`No rotator section found at index {index} for functionId {functionId}`)
		end

		return sectionState
	end

	function actions.updateRotatorSectionLightName(
		functionId: number,
		patternIndex: number,
		index: number,
		newLightName: string
	)
		local sectionState = getRotatorSectionState(functionId, patternIndex, index)

		sectionState.lightName:set(newLightName)
	end

	--[[
        Rotator Step Actions
    ]]

	function actions.addRotatorStep(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		step: types.rotatorData
	)
		local scope, state = getContext(functionId, patternIndex)

		local currentSections = scope.peek(state)
		local sectionState = currentSections[sectionIndex]
		if sectionState == nil then
			log.warn(`No rotator section found at index {sectionIndex} for functionId {functionId}`)
			return
		end

		local currentSteps = scope.peek(sectionState.data)
		table.insert(currentSteps, rotatorDataToState(scope, step))
		sectionState.data:set(currentSteps)
	end

	function actions.removeRotatorStep(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number
	)
		local scope, state = getContext(functionId, patternIndex)

		local currentSections = scope.peek(state)
		local sectionState = currentSections[sectionIndex]
		if sectionState == nil then
			log.warn(`No rotator section found at index {sectionIndex} for functionId {functionId}`)
			return
		end

		local currentSteps = scope.peek(sectionState.data)
		table.remove(currentSteps, stepIndex)
		sectionState.data:set(currentSteps)
	end

	local function getRotatorStepState(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number
	): RotatorDataState
		local scope, state = getContext(functionId, patternIndex)

		local currentSections = scope.peek(state)
		local sectionState = currentSections[sectionIndex]
		if sectionState == nil then
			error(`No rotator section found at index {sectionIndex} for functionId {functionId}`)
		end

		local currentSteps = scope.peek(sectionState.data)
		local stepState = currentSteps[stepIndex]
		if stepState == nil then
			error(
				`No rotator step found at index {stepIndex} for sectionIndex {sectionIndex} and functionId {functionId}`
			)
		end

		return stepState
	end

	function actions.updateRotatorStepType(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newType: "Angle" | "Infinite" | "Wait"
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getRotatorStepState(functionId, patternIndex, sectionIndex, stepIndex)
		if scope.peek(stepState.type) == newType then
			return
		end

		local newStepState: RotatorDataState
		if newType == "Angle" then
			local velocity = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: AngleRotatorState).velocity)
				else 0.1
			local color = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: AngleRotatorState).color)
				else 1
			newStepState = {
				type = scope:Value<<"Angle">>("Angle"),
				velocity = scope:Value(velocity),
				color = scope:Value(color),
				angle = scope:Value(0),
			}
		elseif newType == "Infinite" then
			local velocity = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: AngleRotatorState).velocity)
				else 0.1
			local color = if scope.peek(stepState.type) ~= "Wait"
				then scope.peek((stepState :: AngleRotatorState).color)
				else 1
			newStepState = {
				type = scope:Value<<"Infinite">>("Infinite"),
				velocity = scope:Value(velocity),
				color = scope:Value(color),
			}
		elseif newType == "Wait" then
			newStepState = {
				type = scope:Value<<"Wait">>("Wait"),
				time = scope:Value(0.1),
			}
		else
			log.warn("Unknown rotator step type: " .. tostring(newType))
			return
		end

		local sectionState = getRotatorSectionState(functionId, patternIndex, sectionIndex)
		local currentSteps = scope.peek(sectionState.data)
		currentSteps[stepIndex] = newStepState
		sectionState.data:set(currentSteps)
	end

	--[[
        Shared Angle/Infinite Step Update Actions
    ]]

	function actions.updateRotatorStepVelocity(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newVelocity: number
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getRotatorStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) == "Wait" then
			return
		end

		(stepState :: AngleRotatorState).velocity:set(newVelocity)
	end

	function actions.updateRotatorStepColor(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newColor: number
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getRotatorStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) == "Wait" then
			return
		end

		(stepState :: AngleRotatorState).color:set(newColor)
	end

	--[[
        Angle Step Update Actions
    ]]

	function actions.updateRotatorStepAngle(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newAngle: number
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getRotatorStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) ~= "Angle" then
			return
		end

		(stepState :: AngleRotatorState).angle:set(newAngle)
	end

	--[[
        Wait Step Update Actions
    ]]

	function actions.updateRotatorStepWaitTime(
		functionId: number,
		patternIndex: number,
		sectionIndex: number,
		stepIndex: number,
		newTime: number
	)
		local scope = getContext(functionId, patternIndex)
		local stepState = getRotatorStepState(functionId, patternIndex, sectionIndex, stepIndex)

		if scope.peek(stepState.type) ~= "Wait" then
			return
		end

		(stepState :: WaitState).time:set(newTime)
	end

	return actions
end

return RotatorsEditor
