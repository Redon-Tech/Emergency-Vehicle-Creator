--!strict
--!optimize 2
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require("./types")
local ConfigurationUpdater = require("./ConfigurationUpdater")

--- Initializes a vehicle by loading its configuration and lights.
return function(vehicle: Instance): types.vehicle?
	if vehicle:IsA("Model") == false then
		return
	end

	local EVHEvent = vehicle:WaitForChild("EVHEvent")

	local configuration = EVHEvent:WaitForChild("configuration")

	local functions = configuration:WaitForChild("functions")
	local lightSettings = configuration:WaitForChild("lightSettings")
	if functions:IsA("ModuleScript") == false or lightSettings:IsA("ModuleScript") == false then
		return
	end

	local currentConfiguration = {
		functions = (require :: any)(functions) :: { types.elsFunction },
		lightSettings = (require :: any)(lightSettings) :: types.lightSettings,
	}
	ConfigurationUpdater.update(currentConfiguration)

	local lights = {}
	local lightConnectedGroups = {}

	-- prepare config
	for _, currentFunction in currentConfiguration.functions do
		currentFunction.name = currentFunction.name:gsub("[^%a%d]", "")
		for _, pattern in currentFunction.patterns do
			pattern.patternTime = 0
			for _, flasher in pattern.flashers do
				for _, columns in flasher.columns do
					if lights[columns.lightName] == nil then
						lights[columns.lightName] = {
							isLightGroup = false,
							possibleFunctions = {},
							parts = {},
							currentState = 0,
						}
					end
				end
			end

			for _, fader in pattern.faders do
				if lights[fader.lightName] == nil then
					lights[fader.lightName] = {
						isLightGroup = false,
						possibleFunctions = {},
						parts = {},
						currentState = 0,
					}
				end

				local totalTime = 0
				for _, data in fader.data do
					if data.time == nil or data.type == nil then
						continue
					end
					local timing = data :: types.FaderTiming
					timing.timeStart = totalTime
					totalTime += data.time
					timing.timeEnd = totalTime
				end
				fader.totalTime = totalTime
			end

			for _, rotator in pattern.rotators do
				if lights[rotator.lightName] == nil then
					lights[rotator.lightName] = {
						isLightGroup = false,
						possibleFunctions = {},
						parts = {},
						currentState = 0,
					}
				end
			end
		end
	end

	-- get light connected groups
	for _, lightGroup in currentConfiguration.lightSettings.lightGroups do
		lights[lightGroup.name] = {
			isLightGroup = true,
			possibleFunctions = {},
			parts = {},
			currentState = 0,
		}
		for _, lightName in lightGroup.lights do
			if lightConnectedGroups[lightName] == nil then
				lightConnectedGroups[lightName] = {}
			end

			table.insert(lightConnectedGroups[lightName], lightGroup.name)

			if lights[lightName] == nil then
				lights[lightName] = {
					isLightGroup = false,
					possibleFunctions = {},
					parts = {},
					currentState = 0,
				}
			end
		end
	end

	return {
		configuration = currentConfiguration,
		lights = lights,
		lightConnectedGroups = lightConnectedGroups,
		connections = {},
		uuid = "",
	}
end
