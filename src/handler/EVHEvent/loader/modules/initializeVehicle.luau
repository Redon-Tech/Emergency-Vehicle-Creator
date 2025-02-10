--!strict
--!optimize 2
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require(script.Parent:WaitForChild("types"))

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
	local lights = {}
	local lightConnectedGroups = {}

	-- setup backwards compatibility
	local oldLightConfiguration = (currentConfiguration.lightSettings :: any).optimizations
	if oldLightConfiguration ~= nil then
		currentConfiguration.lightSettings.configuration = {
			shouldChangeNeons = oldLightConfiguration.shouldChangeNeons,
			shouldChangeLights = oldLightConfiguration.shouldChangeLights,
			shouldChangeLightos = oldLightConfiguration.shouldChangeLightos,
			partTransparency = 0.011,
		};
		(currentConfiguration.lightSettings :: any).optimizations = nil
	end

	-- get lights
	for functionIndex, currentFunction in currentConfiguration.functions do
		if currentFunction.patterns == nil or currentFunction.name == nil or currentFunction.weight == nil then
			table.remove(currentConfiguration.functions, functionIndex)
			continue
		end
		-- also since we are here, format the name properly
		currentFunction.name = currentFunction.name:gsub("[^%a%d]", "")

		for _, pattern in currentFunction.patterns do
			if pattern.flashers == nil and pattern.faders == nil and pattern.rotators == nil then
				pattern.flashers = {}
				pattern.faders = {}
				pattern.rotators = {}
			end
			for _, flasher in pattern.flashers do
				if flasher.columns == nil then
					flasher.columns = {}
				end
				for _, columns in flasher.columns do
					if columns.lightName == nil then
						columns.lightName = "corruptedLightName"
					end
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
				if fader.lightName == nil then
					fader.lightName = "corruptedLightName"
				end
				if lights[fader.lightName] == nil then
					lights[fader.lightName] = {
						isLightGroup = false,
						possibleFunctions = {},
						parts = {},
						currentState = 0,
					}
				end
			end

			for _, rotator in pattern.rotators do
				if rotator.lightName == nil then
					rotator.lightName = "corruptedLightName"
				end
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
		if lightGroup.name == nil or lightGroup.lights == nil then
			continue
		end
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
