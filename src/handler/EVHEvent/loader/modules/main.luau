--!strict
--!optimize 2
--!native
--#selene: allow(global_usage)
-- Redon Tech Emergency Vehicle Creator, MIT License

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local handshake = require(script.Parent:WaitForChild("handshake"))
local initializeVehicle = require(script.Parent:WaitForChild("initializeVehicle"))
local types = require(script.Parent:WaitForChild("types"))
local els = script.Parent:WaitForChild("els")
local flashers = require(els:WaitForChild("flashers"))
local faders = require(els:WaitForChild("faders"))
local rotators = require(els:WaitForChild("rotators"))

local vehicles: { [Instance]: types.vehicle } = {}
local runningPatterns: { types.pattern } = {}
local lights: {
	[BasePart]: {
		lights: { Light },
		colorableLightos: { { lighto: LayerCollector, images: { ImageLabel } } },
		lightos: { [string]: { { lighto: LayerCollector, images: { ImageLabel } } } },
	},
} =
	{}
local version = 0
local isPrimary = false

flashers.runningPatterns = runningPatterns
faders.runningPatterns = runningPatterns
rotators.runningPatterns = runningPatterns

-- Light Handling

local function changeColor(vehicle: Instance, functionId: number, lightName: string, color: number)
	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end
	local lightData = vehicleData.lights[lightName]
	local colorData = vehicleData.configuration.lightSettings.colors[color]
	if colorData == nil then
		return
	end

	for _, part in lightData.parts do
		if part.Name ~= lightName then
			if vehicleData.lights[part.Name].runningFunction ~= functionId then
				continue
			end
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeNeons == true then
			part.Color = colorData.partColor
		end
		local lightInstances = lights[part]
		if lightInstances == nil then
			continue
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLights == true then
			for _, light in lightInstances.lights do
				light.Color = colorData.lightColor
			end
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLightos == true then
			for _, lighto in lightInstances.colorableLightos do
				for _, image in lighto.images do
					image.ImageColor3 = colorData.lightoColor
				end
			end

			for colorName, nonColorableLightos in lightInstances.lightos do
				if colorName == colorData.name then
					for _, lighto in nonColorableLightos do
						lighto.lighto.Enabled = true
					end
				else
					for _, lighto in nonColorableLightos do
						lighto.lighto.Enabled = false
					end
				end
			end
		end
	end
end

local function changeLight(vehicle: Instance, functionId: number, lightName: string, state: boolean)
	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end
	local lightData = vehicleData.lights[lightName]

	for _, part in lightData.parts do
		if part.Name ~= lightName then
			if vehicleData.lights[part.Name].runningFunction ~= functionId then
				continue
			end
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeNeons == true then
			part.Transparency = if state == true
				then vehicleData.configuration.lightSettings.configuration.partTransparency
				else 1
		end
		local lightInstances = lights[part]
		if lightInstances == nil then
			continue
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLights == true then
			for _, light in lightInstances.lights do
				light.Enabled = state
			end
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLightos == true then
			for _, lighto in lightInstances.colorableLightos do
				lighto.lighto.Enabled = state
			end

			if state == false then
				for _, nonColorableLightos in lightInstances.lightos do
					for _, lighto in nonColorableLightos do
						lighto.lighto.Enabled = false
					end
				end
			end
		end
	end
end

local function flashLight(vehicle: Instance, functionId: number, lightName: string, color: number)
	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end
	local lightData = vehicleData.lights[lightName]
	if lightData.runningFunction ~= functionId then
		return
	end

	if color == 0 and lightData.currentState ~= 0 then
		changeLight(vehicle, functionId, lightName, false)
	elseif color ~= 0 and lightData.currentState == 0 then
		changeLight(vehicle, functionId, lightName, true)
		changeColor(vehicle, functionId, lightName, color)
	elseif color ~= lightData.currentState then
		changeColor(vehicle, functionId, lightName, color)
	end
	lightData.currentState = color

	for _, part in lightData.parts do
		if part.Name ~= lightName then
			if vehicleData.lights[part.Name].currentState ~= color then
				flashLight(vehicle, functionId, part.Name, color)
			end
		end
	end
end

local function setLightTransparency(
	vehicle: Instance,
	functionId: number,
	lightName: string,
	color: number,
	transpareny: number
)
	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end
	local lightData = vehicleData.lights[lightName]
	local colorData = vehicleData.configuration.lightSettings.colors[color]
	if colorData == nil then
		return
	end
	if lightData.runningFunction ~= functionId and lightData.returnToZero ~= true then
		return
	end

	if color ~= lightData.currentState then
		changeColor(vehicle, functionId, lightName, color)
	end

	for _, part in lightData.parts do
		if part.Name ~= lightName then
			if vehicleData.lights[part.Name].runningFunction ~= functionId and lightData.returnToZero ~= true then
				continue
			end
			if vehicleData.lights[part.Name].currentState ~= color then
				changeColor(vehicle, functionId, part.Name, color)
			end
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeNeons == true then
			part.Transparency = transpareny
		end
		local lightInstances = lights[part]
		if lightInstances == nil then
			continue
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLights == true then
			for _, light in lightInstances.lights do
				light.Enabled = true
				light.Brightness = (light:GetAttribute("defaultBrightness") :: number) * (1 - transpareny)
			end
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLightos == true then
			for _, lighto in lightInstances.colorableLightos do
				lighto.lighto.Enabled = true
				for _, image in lighto.images do
					image.ImageTransparency = transpareny
				end
			end

			for colorName, nonColorableLightos in lightInstances.lightos do
				if colorName == colorData.name then
					for _, lighto in nonColorableLightos do
						lighto.lighto.Enabled = true
						for _, image in lighto.images do
							image.ImageTransparency = transpareny
						end
					end
				else
					for _, lighto in nonColorableLightos do
						lighto.lighto.Enabled = false
					end
				end
			end
		end
	end

	lightData.currentState = color
end

local function resetLightTransparency(vehicle: Instance, lightName: string)
	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end
	local lightData = vehicleData.lights[lightName]
	if lightData.returnToZero ~= true then
		return
	end

	for _, part in lightData.parts do
		if part.Name ~= lightName then
			if lightData.returnToZero ~= true then
				continue
			end
			local otherLightData = vehicleData.lights[part.Name]
			changeLight(vehicle, otherLightData.runningFunction :: any, lightName, false)
			otherLightData.currentState = 0
		end
		local lightInstances = lights[part]
		if lightInstances == nil then
			continue
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLights == true then
			for _, light in lightInstances.lights do
				light.Brightness = light:GetAttribute("defaultBrightness") :: number
			end
		end
		if vehicleData.configuration.lightSettings.configuration.shouldChangeLightos == true then
			for _, lighto in lightInstances.colorableLightos do
				for _, image in lighto.images do
					image.ImageTransparency = image:GetAttribute("defaultImageTransparency") :: number
				end
			end

			for _, nonColorableLightos in lightInstances.lightos do
				for _, lighto in nonColorableLightos do
					for _, image in lighto.images do
						image.ImageTransparency = image:GetAttribute("defaultImageTransparency") :: number
					end
				end
			end
		end
	end
	changeLight(vehicle, lightData.runningFunction :: any, lightName, false)
	lightData.currentState = 0
end

flashers.flash = flashLight
rotators.flash = flashLight
faders.setLightTransparency = setLightTransparency
faders.resetLightTransparency = resetLightTransparency

local function setRotation(vehicle: Instance, functionId: number, lightName: string, rad: number)
	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end
	local lightData = vehicleData.lights[lightName]
	if lightData.runningFunction ~= functionId and lightData.returnToZero ~= true then
		return
	end

	for _, part in lightData.parts do
		if part.Name ~= lightName then
			if vehicleData.lights[part.Name].runningFunction ~= functionId and lightData.returnToZero ~= true then
				continue
			end
		end
		local weld = part:FindFirstChild("Weld")
		if weld ~= nil and weld:IsA("Weld") then
			weld.C1 = (weld:GetAttribute("C1") :: CFrame) * CFrame.Angles(0, 0, rad)
			weld:SetAttribute("rad", rad)
		end
	end
end

rotators.setRotation = setRotation

-- Vehicle Handling

local function updateRotatorRad(vehicleData: types.vehicle, rotator: types.rotatorSection)
	if #vehicleData.lights[rotator.lightName].parts ~= 0 then
		local light = vehicleData.lights[rotator.lightName].parts[1]
		local weld = light:FindFirstChild("Weld")
		if weld ~= nil then
			local rad = weld:GetAttribute("rad")
			if rad ~= nil and typeof(rad) == "number" then
				rad = rad % (math.pi * 2)
				rotator.currentValue = rad
				rotator.previousGoal = rad
			end
		end
	end
end

local function updateLightRunningFunction(vehicle: Instance, lightName: string, functionId: number, adding: boolean)
	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end

	local lightData = vehicleData.lights[lightName]

	if lightData.isLightGroup == true then
		for childLightName, light in vehicleData.lightConnectedGroups do
			if table.find(light, lightName) then
				updateLightRunningFunction(vehicle, childLightName, functionId, adding)
			end
		end
	end

	if adding == false then
		local positionInPossible = table.find(lightData.possibleFunctions, functionId)
		if positionInPossible then
			table.remove(lightData.possibleFunctions, positionInPossible)
		end

		if lightData.runningFunction == functionId then
			lightData.runningFunction = nil

			local highestFunction = nil
			local highestWeight = 0
			for _, possibleFunction in lightData.possibleFunctions do
				local possibleFunctionData = vehicleData.configuration.functions[possibleFunction]
				if possibleFunctionData.weight > highestWeight then
					highestFunction = possibleFunction
					highestWeight = possibleFunctionData.weight
				end
			end
			lightData.runningFunction = highestFunction
			if highestFunction ~= nil then
				table.remove(lightData.possibleFunctions, table.find(lightData.possibleFunctions, highestFunction))
				vehicleData.lights[lightName].returnToZero = true
				for _, pattern in vehicleData.configuration.functions[highestFunction].patterns do
					for _, rotator in pattern.rotators do
						updateRotatorRad(vehicleData, rotator)
						vehicleData.lights[rotator.lightName].returnToZero = false
					end
				end
			end
		end

		if lightData.runningFunction == nil and #lightData.possibleFunctions == 0 then
			flashLight(vehicle, nil :: any, lightName, 0)
			vehicleData.lights[lightName].returnToZero = true
		end
	elseif adding == true then
		if lightData.runningFunction == nil then
			lightData.runningFunction = functionId
		else
			local currentFunction = vehicleData.configuration.functions[functionId]
			local currentWeight = currentFunction.weight
			local runningFunction = vehicleData.configuration.functions[lightData.runningFunction]
			local runningWeight = runningFunction.weight

			if currentWeight > runningWeight then
				table.insert(lightData.possibleFunctions, lightData.runningFunction)
				lightData.runningFunction = functionId
			else
				table.insert(lightData.possibleFunctions, functionId)
			end
		end
	end
end

local function vehicleFunctionUpdate(vehicle: Instance, functionName: string, functionId: number)
	local patternId = vehicle:GetAttribute(functionName)
	if patternId == nil or typeof(patternId) ~= "number" then
		return
	end

	local vehicleData = vehicles[vehicle]
	if vehicleData == nil then
		return
	end
	local currentFunction = vehicleData.configuration.functions[functionId]

	for i, pattern: types.pattern in currentFunction.patterns do
		if i == patternId then
			continue
		end
		local runningId = table.find(runningPatterns, pattern)
		if runningId then
			flashers.removePattern(pattern)
			table.remove(runningPatterns, runningId)
		end

		for _, flasher in pattern.flashers do
			for _, columns in flasher.columns do
				updateLightRunningFunction(vehicle, columns.lightName, functionId, false)
			end
		end

		for _, fader in pattern.faders do
			updateLightRunningFunction(vehicle, fader.lightName, functionId, false)
			table.insert(faders.returnToZero, { vehicle = vehicle, section = fader })
		end

		for _, rotator in pattern.rotators do
			updateLightRunningFunction(vehicle, rotator.lightName, functionId, false)
			table.insert(rotators.returnToZero, { vehicle = vehicle, section = rotator })
		end
	end

	if patternId ~= 0 then
		local pattern = currentFunction.patterns[patternId]
		for _, flasher in pattern.flashers do
			for _, columns in flasher.columns do
				updateLightRunningFunction(vehicle, columns.lightName, functionId, true)
			end
		end

		for _, fader in pattern.faders do
			updateLightRunningFunction(vehicle, fader.lightName, functionId, true)
			vehicleData.lights[fader.lightName].returnToZero = false
		end

		for _, rotator in pattern.rotators do
			updateLightRunningFunction(vehicle, rotator.lightName, functionId, true)
			updateRotatorRad(vehicleData, rotator)
			vehicleData.lights[rotator.lightName].returnToZero = false
		end
		table.insert(runningPatterns, pattern)
		flashers.addPattern(pattern)
	end
end

local function addLight(vehicleData: types.vehicle, light: Instance)
	if light:IsA("BasePart") then
		table.insert(vehicleData.lights[light.Name].parts, light)
		if vehicleData.lightConnectedGroups[light.Name] ~= nil then
			for _, group in vehicleData.lightConnectedGroups[light.Name] do
				table.insert(vehicleData.lights[group].parts, light)
			end
		end
		light.Transparency = 1

		local newLights = {}
		local colorableLightos = {}
		local lightos = {}
		local colorNames = {}
		for _, color in vehicleData.configuration.lightSettings.colors do
			table.insert(colorNames, color.name)
		end
		for _, lighto in light:GetDescendants() do
			if lighto:IsA("Light") then
				lighto.Enabled = false
				lighto:SetAttribute("defaultBrightness", lighto.Brightness)
				table.insert(newLights, lighto)
			elseif lighto:IsA("LayerCollector") then
				lighto.Enabled = false

				local images = {}
				for _, image in lighto:GetDescendants() do
					if image:IsA("ImageLabel") or image:IsA("ImageButton") then
						image:SetAttribute("defaultImageTransparency", image.ImageTransparency)
						table.insert(images, image :: ImageLabel)
					end
				end

				if table.find(colorNames, lighto.Name) == nil then
					table.insert(colorableLightos, { lighto = lighto, images = images })
				else
					if lightos[lighto.Name] == nil then
						lightos[lighto.Name] = {}
					end
					table.insert(lightos[lighto.Name], { lighto = lighto, images = images })
				end
			end
		end

		lights[light] = {
			lights = newLights,
			colorableLightos = colorableLightos,
			lightos = lightos,
		}
	end
end

local function removeLight(vehicleData: types.vehicle, light: Instance)
	if light:IsA("BasePart") then
		table.remove(vehicleData.lights[light.Name].parts, table.find(vehicleData.lights[light.Name].parts, light))
		if vehicleData.lightConnectedGroups[light.Name] ~= nil then
			for _, group in vehicleData.lightConnectedGroups[light.Name] do
				table.remove(vehicleData.lights[group].parts, table.find(vehicleData.lights[group].parts, light))
			end
		end
		lights[light] = nil
	end
end

local function vehicleAdded(vehicle: Instance)
	if vehicles[vehicle] then
		return
	end

	if
		(isPrimary == true and vehicle:GetAttribute("version") <= version)
		or (isPrimary == false and vehicle:GetAttribute("version") == version)
	then
		local uuid = vehicle:GetAttribute("uuid")
		if uuid == nil or typeof(uuid) ~= "string" then
			return
		end

		local vehicleData = initializeVehicle(vehicle)
		if vehicleData then
			vehicleData.uuid = uuid

			table.insert(
				vehicleData.connections,
				CollectionService:GetInstanceAddedSignal(`{uuid}_LIGHT`):Connect(function(light: Instance)
					addLight(vehicleData, light)
				end)
			)
			for _, light in CollectionService:GetTagged(`{uuid}_LIGHT`) do
				addLight(vehicleData, light)
			end

			table.insert(
				vehicleData.connections,
				CollectionService:GetInstanceRemovedSignal(`{uuid}_LIGHT`):Connect(function(light: Instance)
					removeLight(vehicleData, light)
				end)
			)
			for functionId, functionData in vehicleData.configuration.functions do
				for _, pattern in functionData.patterns do
					pattern.vehicle = vehicle
					pattern.functionId = functionId
				end

				table.insert(
					vehicleData.connections,
					vehicle:GetAttributeChangedSignal(functionData.name):Connect(function()
						vehicleFunctionUpdate(vehicle, functionData.name, functionId)
					end)
				)
			end

			vehicles[vehicle] = vehicleData

			-- Check for existing function values
			for functionId, functionData in vehicleData.configuration.functions do
				vehicleFunctionUpdate(vehicle, functionData.name, functionId)
			end
		end
	end
end

local function setup()
	CollectionService:GetInstanceAddedSignal("EVHVehicle"):Connect(vehicleAdded)
	for _, vehicle in CollectionService:GetTagged("EVHVehicle") do
		vehicleAdded(vehicle)
	end

	RunService.RenderStepped:Connect(function(deltaTime: number)
		faders.heartbeat(deltaTime)
		rotators.heartbeat(deltaTime)
	end)
end

return function(actualVersion: number)
	version = actualVersion
	if handshake(version) == true then
		isPrimary = true
	else
		if _G.EVHHANDSHAKE.version < version then
			if table.find(_G.RUNNINGEVH, version) then
				script.Parent.Parent:Destroy()
				return
			end

			_G.RUNNINGEVH[version] = true
			isPrimary = false
		else
			script.Parent.Parent:Destroy()
			return
		end
	end

	setup()
end
