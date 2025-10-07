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
	processReturnToZero: () -> (),
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
		local currentAngle = currentAngles[angleId]
		if currentAngle.type == "Angle" then
			if currentAngle.color ~= 0 then
				rotators.flash(pattern.vehicle, pattern.functionId, data.lightName, currentAngle.color or 0)
			end
			local currentRotation = data.currentValue or 0
			local goal = math.rad(currentAngle.angle or 90)
			local velocity: number = math.abs(currentAngle.velocity or 0.1)

			local difference = goal - currentRotation
			if math.abs(difference) == 0 then
				data.currentAngle = if angleId ~= #currentAngles then angleId + 1 else 1
				data.previousGoal = goal
				currentPercentage = 0
			else
				currentRotation += math.clamp(difference, -velocity, velocity)
				currentPercentage = 1 - ((goal - currentRotation) / (goal - (data.previousGoal or 0) :: number))

				data.currentValue = currentRotation
				rotators.setRotation(pattern.vehicle, pattern.functionId, data.lightName, currentRotation)
			end
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
			if currentPercentage >= 1 then
				data.currentAngle = if angleId ~= #currentAngles then angleId + 1 else 1
				currentPercentage = 0
			end
		end
		data.currentPercentage = currentPercentage
	end
end

function rotators.processReturnToZero()
	for i, data in rotators.returnToZero do
		-- data.section.currentLightState = 0
		local lastAngle = data.section.data[data.section.currentAngle or 1]
		local currentRotation = (data.section.currentValue or 0) % (math.pi * 2)
		local velocity: number = math.abs(lastAngle.velocity or 0.1)

		local difference = -currentRotation
		if math.abs(difference) == 0 then
			data.section.currentAngle = 1
			data.section.previousGoal = 0
			data.section.currentPercentage = 0
			table.remove(rotators.returnToZero, i)
		else
			currentRotation += math.clamp(difference, -velocity, velocity)
			data.section.currentPercentage = 1 - (-currentRotation / (-(data.section.previousGoal or 0) :: number))

			data.section.currentValue = currentRotation
			rotators.setRotation(data.vehicle, nil :: any, data.section.lightName, currentRotation)
		end
	end
end

return rotators
