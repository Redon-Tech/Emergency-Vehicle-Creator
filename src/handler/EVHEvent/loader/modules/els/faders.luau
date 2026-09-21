--!strict
--!optimize 2
--!native
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require(script.Parent.Parent.types)
local TweenService = game:GetService("TweenService")

type faders = {
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
	returnToZero = {},
} :: faders

function faders.processPattern(pattern: types.pattern)
	for _, data in pairs(pattern.faders) do
		local currentTweens = data.data
		if #currentTweens == 0 then
			continue
		end
		local cycleTime = if data.totalTime > 0 then pattern.patternTime % data.totalTime else 0
		local tweenId = #currentTweens
		local previousGoal = 1
		if data.totalTime > 0 and pattern.patternTime >= data.totalTime then
			for i = #currentTweens, 1, -1 do
				if currentTweens[i].type ~= "Wait" then
					previousGoal = currentTweens[i].goal or 0
					break
				end
			end
		end
		for i, tween in currentTweens do
			if cycleTime < tween.timeEnd then
				tweenId = i
				break
			end
			if tween.type ~= "Wait" then
				previousGoal = tween.goal or 0
			end
		end
		data.previousGoal = previousGoal
		local currentTween = currentTweens[tweenId]
		local currentPercentage = if currentTween.time <= 0
			then if cycleTime >= currentTween.timeStart then 1 else -1
			else (math.min(cycleTime, currentTween.timeEnd) - currentTween.timeStart) / currentTween.time

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

		if currentPercentage >= 1 then
			if currentTweens[tweenId] ~= nil and currentTweens[tweenId].type ~= "Wait" then
				data.previousGoal = currentTweens[tweenId].goal
			end
			tweenId += 1
		end
		data.currentTween = tweenId
	end
end

function faders.processReturnToZero(deltaTime: number)
	for i = #faders.returnToZero, 1, -1 do
		local data = faders.returnToZero[i]
		if #data.section.data == 0 then
			table.remove(faders.returnToZero, i)
			continue
		end
		local lastTweenId = data.section.currentTween or 1
		if lastTweenId > #data.section.data then
			lastTweenId = #data.section.data
		end
		local lastTween = data.section.data[lastTweenId]
		local currentPercentage = data.section.currentPercentage or 0

		if currentPercentage >= 0.98 then
			table.remove(faders.returnToZero, i)
			data.section.currentPercentage = 0
			data.section.previousGoal = 1
			data.section.currentValue = 1
			faders.resetLightTransparency(data.vehicle, data.section.lightName)
			continue
		end

		currentPercentage = if lastTween.time <= 0 then 1 else math.min(1, currentPercentage + deltaTime / lastTween.time)
		data.section.currentPercentage = currentPercentage

		local previousGoal = data.section.previousGoal or 0
		-- BUG: The return fade adds previousGoal to the easing value instead of interpolating from currentValue to 1.
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
