--!strict
--!optimize 2
--!native
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require(script.Parent.Parent.types)

type rotators = {
	returnToZero: { { vehicle: Instance, section: types.rotatorSection } },
	flash: (vehicle: Instance, functionId: number, lightName: string, color: types.elsColor) -> (),
	setRotation: (vehicle: Instance, functionId: number, lightName: string, rad: number) -> (),
	processPattern: (pattern: types.pattern, deltaTime: number) -> (),
	processReturnToZero: (deltaTime: number) -> (),
}
local rotators = {
	returnToZero = {},
} :: rotators

function rotators.processPattern(pattern: types.pattern, deltaTime: number)
	for _, data in pairs(pattern.rotators) do
		local currentAngles = data.data
		local angleId = data.currentAngle or 1
		local currentPercentage = data.currentPercentage or 0
		if angleId > #currentAngles then
			angleId = 1
			currentPercentage = 0
		end

		data.currentAngle = angleId
		-- BUG: An empty rotator data list indexes nil and aborts the shared render callback.
		local currentAngle = currentAngles[angleId]
		if currentAngle.type == "Angle" then
			if currentAngle.color ~= 0 then
				rotators.flash(pattern.vehicle, pattern.functionId, data.lightName, currentAngle.color or 0)
			end
			local currentRotation = data.currentValue or 0
			local goal = math.rad(currentAngle.angle or 90)
			local velocity = math.abs(currentAngle.velocity or 0.1)
			local step = velocity * 60 * deltaTime
			local difference = goal - currentRotation

			if math.abs(difference) <= step then
				currentRotation = goal
				data.currentAngle = if angleId ~= #currentAngles then angleId + 1 else 1
				data.previousGoal = goal
				currentPercentage = 0
			else
				currentRotation += math.clamp(difference, -step, step)
				local totalDistance = goal - (data.previousGoal or 0)
				currentPercentage = if totalDistance == 0 then 0 else 1 - ((goal - currentRotation) / totalDistance)
			end
			data.currentValue = currentRotation
			rotators.setRotation(pattern.vehicle, pattern.functionId, data.lightName, currentRotation)
		elseif currentAngle.type == "Infinite" then
			if currentAngle.color ~= 0 then
				rotators.flash(pattern.vehicle, pattern.functionId, data.lightName, currentAngle.color or 0)
			end
			local currentRotation = data.currentValue or 0
			local velocity: number = currentAngle.velocity or 0.1

			currentRotation += (velocity * 60) * deltaTime
			data.currentValue = currentRotation % (math.pi * 2)
			rotators.setRotation(pattern.vehicle, pattern.functionId, data.lightName, currentRotation)
		else
			currentPercentage += deltaTime / (currentAngle.time or 0.1)
			if currentPercentage >= 0.98 then
				data.currentAngle = if angleId ~= #currentAngles then angleId + 1 else 1
				currentPercentage = 0
			end
		end
		data.currentPercentage = currentPercentage
	end
end

function rotators.processReturnToZero(deltaTime: number)
	for i, data in rotators.returnToZero do
		print(data.section.lightName)
		local lastAngle = data.section.data[data.section.currentAngle or 1]
		local startRotation = (data.section.currentValue or 0) % (math.pi * 2)
		local currentRotation = (data.section.currentValue or 0) % (math.pi * 2)
		local velocity: number = math.abs(lastAngle.velocity or 0.1)
		local step = velocity * 60 * deltaTime
		local difference = -currentRotation

		if math.abs(difference) <= step then
			currentRotation = 0
			data.section.currentAngle = 1
			data.section.previousGoal = 0
			data.section.currentPercentage = 0
			table.remove(rotators.returnToZero, i)
		else
			currentRotation += math.clamp(difference, -step, step)
			data.section.currentPercentage = if startRotation == 0
				then 1
				else math.clamp(1 - currentRotation / startRotation, 0, 1)
		end
		data.section.currentValue = currentRotation
		rotators.setRotation(data.vehicle, nil :: any, data.section.lightName, currentRotation)
	end
end

return rotators
