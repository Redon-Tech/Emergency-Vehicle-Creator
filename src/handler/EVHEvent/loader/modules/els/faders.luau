--!strict
--!optimize 2
--!native
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require(script.Parent.Parent.types)
local TweenService = game:GetService("TweenService")

type faders = {
	runningPatterns: { types.pattern },
	returnToZero: { { vehicle: Instance, section: types.faderSection } },
	setLightTransparency: (
		vehicle: Instance,
		functionId: number,
		lightName: string,
		color: number,
		transpareny: number
	) -> (),
	resetLightTransparency: (vehicle: Instance, lightName: string) -> (),
	processPattern: (pattern: types.pattern) -> (),
	processReturnToZero: (deltaTime: number) -> (),
}
local faders = {
	runningPatterns = {},
	returnToZero = {},
} :: faders

function faders.processPattern(pattern: types.pattern)
	for _, data in pairs(pattern.faders) do
		local currentTweens = data.data
		local tweenId = data.currentTween or 1
		if tweenId > #currentTweens then
			if currentTweens[tweenId] ~= nil and currentTweens[tweenId].type ~= "Wait" then
				data.previousGoal = currentTweens[tweenId].goal
			end
			tweenId = 1
		end
		local currentTween = currentTweens[tweenId]
		local currentPercentage = (
			math.min(pattern.patternTime % data.totalTime, currentTween.timeEnd) - currentTween.timeStart
		) / currentTween.time

		if currentTween.type ~= "Wait" and currentPercentage >= 0 then
			local previousGoal = data.previousGoal or 1
			local goal: number = currentTweens[tweenId].goal or 0

			data.currentValue = (goal - previousGoal)
					* TweenService:GetValue(
						currentPercentage,
						currentTween.easingStyle or Enum.EasingStyle.Linear,
						currentTween.easingDirection or Enum.EasingDirection.InOut
					)
				+ previousGoal

			faders.setLightTransparency(
				pattern.vehicle,
				pattern.functionId,
				data.lightName,
				currentTween.color or 0,
				data.currentValue or 0
			)
		end

		if currentPercentage >= 1 or currentPercentage <= 0 then
			if currentTweens[tweenId] ~= nil and currentTweens[tweenId].type ~= "Wait" then
				data.previousGoal = currentTweens[tweenId].goal
			end
			tweenId += 1
		end
		data.currentTween = tweenId
	end
end

function faders.processReturnToZero(deltaTime: number)
	for i, data in pairs(faders.returnToZero) do
		local lastTween = data.section.data[data.section.currentTween or 1]
		local currentPercentage = data.section.currentPercentage or 0

		if currentPercentage >= 1 then
			table.remove(faders.returnToZero, i)
			data.section.currentPercentage = 0
			data.section.previousGoal = 1
			data.section.currentValue = 1
			faders.resetLightTransparency(data.vehicle, data.section.lightName)
			continue
		end

		currentPercentage += deltaTime / lastTween.time
		data.section.currentPercentage = currentPercentage

		local previousGoal = data.section.previousGoal or 0
		data.section.currentValue = 1
				* TweenService:GetValue(
					currentPercentage,
					lastTween.easingStyle or Enum.EasingStyle.Linear,
					lastTween.easingDirection or Enum.EasingDirection.InOut
				)
			+ previousGoal

		faders.setLightTransparency(
			data.vehicle,
			nil :: any,
			data.section.lightName,
			lastTween.color or 0,
			data.section.currentValue or 0
		)
	end
end

return faders
