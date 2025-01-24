--!strict
--!optimize 2
--!native
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require(script.Parent.Parent.types)
local TweenService = game:GetService("TweenService")

type faders = {
	runningPatterns: { types.pattern },
	setLightTransparency: (
		vehicle: Instance,
		functionId: number,
		lightName: string,
		color: number,
		transpareny: number
	) -> (),
	heartbeat: (deltaTime: number) -> (),
}
local faders = {
	runningPatterns = {},
} :: faders

function faders.heartbeat(deltaTime: number)
	for _, pattern in faders.runningPatterns do
		for _, data in pairs(pattern.faders) do
			local currentTweens = data.data
			local tweenId = data.currentTween or 1
			local currentPercentage = data.currentPercentage or 0
			if currentPercentage >= 1 then
				if currentTweens[tweenId] ~= nil and currentTweens[tweenId].type ~= "Wait" then
					data.previousGoal = currentTweens[tweenId].goal
				end
				tweenId += 1
				currentPercentage = 0
			end
			if tweenId > #currentTweens then
				if currentTweens[tweenId] ~= nil and currentTweens[tweenId].type ~= "Wait" then
					data.previousGoal = currentTweens[tweenId].goal
				end
				tweenId = 1
				currentPercentage = 0
			end
			data.currentTween = tweenId
			local currentTween = currentTweens[tweenId]
			currentPercentage += deltaTime / currentTween.time
			data.currentPercentage = currentPercentage
			if currentTween.type ~= "Wait" then
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
		end
	end
end

return faders
