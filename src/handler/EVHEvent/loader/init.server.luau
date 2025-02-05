-- Redon Tech Emergency Vehicle Creator, MIT License

-- version format: minor.{if rc then 1 else 0}patch
local version = 0
local versionInstance = Instance.new("NumberValue")
versionInstance.Name = "version"
versionInstance.Value = version
versionInstance.Parent = script

local types = require(script.modules.types)
-- Trigger the start of handshaking
local initiator = script.EVHClient
local newContainer = Instance.new("Folder")
newContainer.Name = `EmergencyVehicleHandler_{version}`
newContainer.Parent = workspace
versionInstance.Parent = newContainer
initiator.Parent = newContainer
script.modules.Parent = newContainer
initiator.Enabled = true

local Players = game:GetService("Players")
local HTTPService = game:GetService("HttpService")
local JointsService = game:GetService("JointsService")

local EVHEvent = script.Parent
local initialized = false
local car: Model
local driveSeat: VehicleSeat
local uuid: string

local functions: { types.elsFunction } = {}
local keybindsToFunction: {
	{
		keybind: Enum.KeyCode,
		functionId: number,
		mode: "Cycle" | "Set Pattern",
		patternId: number?,
	}
} =
	{}
local sirens: { types.siren } = {}

local function setupRotator(rotator: BasePart)
	local motorPart = Instance.new("Part")
	motorPart.Name = `motor{rotator.Name}`
	motorPart.Size = Vector3.new(0.1, 0.1, 0.1)
	motorPart.CFrame = rotator.CFrame
	motorPart.Transparency = 1
	local weld = Instance.new("Weld")
	weld.Part0 = driveSeat
	weld.Part1 = motorPart
	weld.C0 = driveSeat.CFrame:Inverse() * driveSeat.CFrame
	weld.C1 = motorPart.CFrame:Inverse() * driveSeat.CFrame
	weld.Parent = driveSeat

	local inverse: Instance? = rotator:FindFirstChild("inverse")
	if inverse ~= nil and inverse:IsA("BasePart") == false then
		inverse = nil
	end

	local Center = if inverse ~= nil then CFrame.new((inverse :: BasePart).Position) else CFrame.new(rotator.Position)
	local XYZ = if inverse ~= nil
		then CFrame.Angles((inverse :: BasePart).CFrame:ToEulerAnglesXYZ())
		else CFrame.Angles(rotator.CFrame:ToEulerAnglesXYZ())
	local motor = Instance.new("Weld")
	motor.Name = "Weld"
	motor.Part0 = motorPart
	motor.Part1 = rotator
	motor.C0 = (motorPart.CFrame:Inverse() * Center) * XYZ
	motor.C1 = (rotator.CFrame:Inverse() * Center) * XYZ
	motor:SetAttribute("C1", motor.C1)
	motor.Parent = rotator

	for _, v in rotator:GetChildren() do
		if v:IsA("WeldConstraint") and v.Part1 == driveSeat then
			v:Destroy()
		end
	end

	for _, v in driveSeat:GetChildren() do
		if v:IsA("Weld") and v.Part1 == rotator then
			v:Destroy()
		end
	end

	for _, v in JointsService:GetDescendants() do
		if v:IsA("Weld") and v.Part1 == rotator then
			v:Destroy()
		end
	end

	motorPart.Parent = driveSeat
end

local function load()
	car = EVHEvent.Parent :: Model
	local possibleDriveSeat = car:WaitForChild("DriveSeat")
	if possibleDriveSeat:IsA("VehicleSeat") == false then
		return
	end
	driveSeat = possibleDriveSeat :: VehicleSeat
	uuid = HTTPService:GenerateGUID(false)
	car:SetAttribute("uuid", uuid)
	car:SetAttribute("version", version)

	local configuration = script.Parent.configuration
	local functionsModule = configuration:WaitForChild("functions")
	local sirensModule = configuration:WaitForChild("sirens")
	local lightSettingsModule = configuration:WaitForChild("lightSettings")
	if
		functionsModule:IsA("ModuleScript") == false
		or sirensModule:IsA("ModuleScript") == false
		or lightSettingsModule:IsA("ModuleScript") == false
	then
		return
	end

	functions = (require :: any)(functionsModule) :: { types.elsFunction }
	sirens = (require :: any)(sirensModule) :: { types.siren }
	local lightSettings = (require :: any)(lightSettingsModule) :: types.lightSettings

	local lightTemplate = car:FindFirstChild("lightTemplate")
	if lightTemplate ~= nil then
		if lightTemplate:IsA("BasePart") == false then
			lightTemplate = nil
		end
	end
	local possibleLights = {}
	local possibleRotators = {}
	for functionId, currentFunction in functions do
		currentFunction.name = currentFunction.name:gsub("[^%a%d]", "")
		car:SetAttribute(currentFunction.name, 0)
		car:GetAttributeChangedSignal(currentFunction.name):Connect(function()
			local currentPatternId = car:GetAttribute(currentFunction.name)
			if currentPatternId == nil or typeof(currentPatternId) ~= "number" then
				car:SetAttribute(currentFunction.name, 0)
				return
			end

			if currentPatternId > #currentFunction.patterns then
				car:SetAttribute(currentFunction.name, 0)
				return
			end
		end)

		for _, activation in currentFunction.activations do
			if activation.type == "Standard" then
				if activation.keybinds then
					for _, keybind in activation.keybinds do
						table.insert(keybindsToFunction, {
							keybind = keybind,
							functionId = functionId,
							mode = activation.mode :: "Cycle" | "Set Pattern",
							patternId = activation.pattern,
						})
					end
				end
			elseif
				activation.type == "Override"
				and activation.dependentFunction ~= nil
				and activation.dependentFunction ~= ""
				and activation.dependentPattern ~= nil
			then
				car:GetAttributeChangedSignal(activation.dependentFunction):Connect(function()
					local dependentValue = car:GetAttribute(activation.dependentFunction)
					if dependentValue == nil or typeof(dependentValue) ~= "number" then
						return
					end
					if dependentValue >= activation.dependentPattern then
						car:SetAttribute(
							currentFunction.name,
							if car:GetAttribute(`shouldOverride{currentFunction.name}`) == true then 1 else 0
						)
					end
				end)
			end
		end

		for _, pattern in currentFunction.patterns do
			for _, flasher in pattern.flashers do
				for _, columns in flasher.columns do
					if table.find(possibleLights, columns.lightName) == nil then
						table.insert(possibleLights, columns.lightName)
					end
				end
			end

			for _, fader in pattern.faders do
				if table.find(possibleLights, fader.lightName) == nil then
					table.insert(possibleLights, fader.lightName)
				end
			end

			for _, rotator in pattern.rotators do
				if table.find(possibleLights, rotator.lightName) == nil then
					table.insert(possibleLights, rotator.lightName)
				end
				if table.find(possibleRotators, rotator.lightName) == nil then
					table.insert(possibleRotators, rotator.lightName)
				end
			end
		end
	end
	for _, lightGroup in lightSettings.lightGroups do
		local isRotator = if table.find(possibleRotators, lightGroup.name) ~= nil then true else false
		for _, lightName in lightGroup.lights do
			if table.find(possibleLights, lightName) == nil then
				table.insert(possibleLights, lightName)
			end
			if isRotator then
				if table.find(possibleRotators, lightName) == nil then
					table.insert(possibleRotators, lightName)
				end
			end
		end
	end

	for _, light in car:GetDescendants() do
		if light:IsA("BasePart") then
			if table.find(possibleLights, light.Name) ~= nil then
				light:AddTag(`{uuid}_LIGHT`)
				if lightTemplate ~= nil then
					light.Material = (lightTemplate :: BasePart).Material
					for _, child in lightTemplate:GetChildren() do
						local newChild = child:Clone()
						newChild.Parent = light
					end
				end
			end
			if table.find(possibleRotators, light.Name) ~= nil then
				setupRotator(light)
			end
		end
	end

	car:AddTag("EVHVehicle")
	initialized = true
end

-- Wait until we are in the car
if EVHEvent.Parent == nil or EVHEvent.Parent:IsA("Model") == false then
	local connection
	connection = EVHEvent.AncestryChanged:Connect(function(child: Instance, parent: Instance?)
		if child == EVHEvent and parent ~= nil and parent:IsA("Model") then
			connection:Disconnect()
			EVHEvent:Destroy()
			load()
		end
	end)
else
	load()
end

script.Parent.OnServerEvent:Connect(function(player: Player, type: string, ...)
	if initialized == false then
		return
	end
	if driveSeat.Occupant == nil or player ~= Players:GetPlayerFromCharacter(driveSeat.Occupant.Parent) then
		return
	end

	if type == "Input" then
		local UserInputState: Enum.UserInputState, UserInputType: Enum.UserInputType, KeyCode: Enum.KeyCode = ...
		if UserInputState == nil or UserInputType == nil or KeyCode == nil then
			return
		end
		if
			typeof(UserInputState) ~= "EnumItem"
			or typeof(UserInputType) ~= "EnumItem"
			or typeof(KeyCode) ~= "EnumItem"
		then
			return
		end

		if UserInputState == Enum.UserInputState.Begin then
			for _, data in keybindsToFunction do
				if data.keybind == KeyCode then
					local currentFunction = functions[data.functionId]
					if data.mode == "Cycle" then
						local currentValue = car:GetAttribute(currentFunction.name)
						if currentValue == nil or typeof(currentValue) ~= "number" then
							continue
						end
						car:SetAttribute(currentFunction.name, currentValue + 1)
					elseif data.mode == "Set Pattern" then
						car:SetAttribute(currentFunction.name, data.patternId or 0)
					end
				end
			end
		end
	elseif type == "Values" then
		local Value: string, State: unknown = ...
		if Value == "PBrake" and typeof(State) == "boolean" then
			for _, currentFunction in functions do
				for _, activation in currentFunction.activations do
					if activation.type == "Override" and activation.mode == "Park" then
						if activation.dependentFunction ~= nil and activation.dependentFunction ~= "" then
							if car:GetAttribute(activation.dependentFunction) >= activation.dependentPattern then
								car:SetAttribute(currentFunction.name, if State then 1 else 0)
							end
							car:SetAttribute(`shouldOverride{currentFunction.name}`, State)
						else
							car:SetAttribute(currentFunction.name, if State then 1 else 0)
						end
					end
				end
			end
		elseif Value == "Brake" and typeof(State) == "number" then
			for _, currentFunction in functions do
				for _, activation in currentFunction.activations do
					if activation.type == "Override" and activation.mode == "Brake" then
						if activation.dependentFunction ~= nil and activation.dependentFunction ~= "" then
							if car:GetAttribute(activation.dependentFunction) >= activation.dependentPattern then
								car:SetAttribute(currentFunction.name, if State > 0 then 1 else 0)
							end
							car:SetAttribute(`shouldOverride{currentFunction.name}`, State > 0)
						else
							car:SetAttribute(currentFunction.name, if State > 0 then 1 else 0)
						end
					end
				end
			end
		elseif Value == "Gear" and typeof(State) == "number" then
			for _, currentFunction in functions do
				for _, activation in currentFunction.activations do
					if activation.type == "Override" and activation.mode == "Reverse" then
						if activation.dependentFunction ~= nil and activation.dependentFunction ~= "" then
							if car:GetAttribute(activation.dependentFunction) >= activation.dependentPattern then
								car:SetAttribute(currentFunction.name, if State < 0 then 1 else 0)
							end
							car:SetAttribute(`shouldOverride{currentFunction.name}`, State < 0)
						else
							car:SetAttribute(currentFunction.name, if State < 0 then 1 else 0)
						end
					end
				end
			end
		end
	end
end)
