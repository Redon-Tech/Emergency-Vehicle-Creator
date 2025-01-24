-- Redon Tech Emergency Vehicle Creator, MIT License
local InsertService = game:GetService("InsertService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local assets = require(script.Parent.assets)
local log = require(script.Parent.log)

export type option = {
	type: "select" | "single",
	default: string | boolean,
	canSelectMultiple: boolean?,
	canHaveNone: boolean?,
	icon: string?,
	iconOnly: boolean?,
	layoutOrder: number,
	choices: { string }?,
}
export type equipmentData = {
	default: boolean,
	hasLights: boolean,
	credit: string,
	icon: string?,
	layoutOrder: number,
	configuration: {
		[string]: option,
	},
}
type vehicleData = {
	customization: {
		[string]: { -- Location: data
			[string]: equipmentData, -- Equipment Name: data
		},
	},
}
export type vehicleFolder = {
	vehicle: Model,
	customization: Model,
	data: vehicleData,
}
type vehicle = {
	vehicles: {
		[string]: {
			icon: string,
			outfitter: string,
			credits: string,
			order: number,
			assetId: number,
		},
	},
	cache: { [string]: vehicleFolder },
	isValidVehicle: (self: vehicle, vehicle: Instance) -> false | "a" | "ag" | "mg" | "m",
	isVehicleCustomizable: (self: vehicle, vehicle: Instance) -> boolean,
	getOutfitting: (self: vehicle, vehicle: Instance) -> { model: Model, basePoint: BasePart }?,
	_setupVehicle: (self: vehicle, vehicleName: string, vehicleFolder: Folder) -> vehicleFolder?,
	getVehicle: (self: vehicle, vehicleName: string) -> vehicleFolder?,
	initVehicle: (self: vehicle, vehicleModel: Model) -> (),
	changeConfiguration: (
		self: vehicle,
		vehicleFolder: vehicleFolder,
		equipmentModel: Model,
		configuration: { [string]: boolean | { [string]: boolean } }
	) -> (),
	updateEquipmentLights: (self: vehicle, equipmentModel: Model, oldPrefix: string) -> (),
	changeEquipment: (
		self: vehicle,
		vehicleFolder: vehicleFolder,
		outfitting: Model,
		location: string,
		equipmentName: string?
	) -> boolean,
	cloneCustomizationBasePoint: (self: vehicle, vehicleFolder: vehicleFolder) -> BasePart?,
}
local vehicle = {
	vehicles = {
		["2020 FPIU"] = {
			icon = assets.images.vehicles.FPIU2020,
			outfitter = "RetiredSubaru",
			credits = "EonWare/LT_haywood",
			order = 1,
			assetId = 95348918634521,
		},
	},
	cache = {},
} :: vehicle

function vehicle.isValidVehicle(_, vehicleToCheck)
	if vehicleToCheck:IsA("Model") then
		local tune = vehicleToCheck:FindFirstChild("A-Chassis Tune")
		if tune then
			-- If plugins doesn't exist, it can not be used
			local plugins = tune:FindFirstChild("Plugins")
			if plugins == nil then
				return false
			end

			-- Detect AG chassis
			local loader = tune:FindFirstChild("AG-Chassis [Loader]")
			if loader then
				return "ag"
			end

			return "a"
		end

		-- Detect MG chassis
		tune = vehicleToCheck:FindFirstChild("MG-Chassis Tune")
		if tune then
			return "mg"
		end

		-- Detect NVNA Constraint Type: Motorcycle
		-- AKA Motorcycle Chassis
		tune = vehicleToCheck:FindFirstChild("Tuner")
		if tune then
			return "m"
		end
	end
	return false
end

function vehicle.isVehicleCustomizable(self, vehicleToCheck)
	if vehicleToCheck:GetAttribute("EVCHandled") == true and self:getOutfitting(vehicleToCheck) ~= nil then
		return true
	end
	return false
end

function vehicle.getOutfitting(_, vehicleToCheck)
	local carBody = vehicleToCheck:FindFirstChild("Body")
	if carBody == nil then
		return
	end
	local carOutfitting = carBody:FindFirstChild("Outfitting") :: Model?
	if carOutfitting == nil or carOutfitting:IsA("Model") == false then
		return
	end
	local carBasePoint = carOutfitting:FindFirstChild("BasePoint") :: BasePart?
	if carBasePoint == nil or carBasePoint:IsA("BasePart") == false then
		return
	end

	return {
		model = carOutfitting,
		basePoint = carBasePoint,
	}
end

-- This function is meant to only be called from this module
function vehicle._setupVehicle(self, vehicleName, vehicleFolder)
	if self.cache[vehicleName] ~= nil then
		return
	end

	-- Check and get the vehicle model
	local vehicleModel = vehicleFolder:FindFirstChild("Vehicle") :: Model?
	if vehicleModel == nil or vehicleModel:IsA("Model") == false then
		return
	end
	-- vehicleModel:MoveTo(Vector3.new(0, 0, 0))
	vehicleModel:SetAttribute("EVCHandled", true)
	vehicleModel:SetAttribute("EVCVehicleName", vehicleName)

	-- Check and get the customization model
	local customization = vehicleFolder:FindFirstChild("Customization") :: Model?
	if customization == nil or customization:IsA("Model") == false then
		return
	end
	-- customization:MoveTo(Vector3.new(0, 0, 0))
	local BasePoint = customization:FindFirstChild("BasePoint") :: BasePart?
	if BasePoint == nil or BasePoint:IsA("BasePart") == false then
		return
	end

	-- Check and get the EVC_Config module
	local EVC_Config = vehicleFolder:FindFirstChild("EVC_Config") :: ModuleScript?
	if EVC_Config == nil or EVC_Config:IsA("ModuleScript") == false then
		return
	end
	local data = (require :: any)(EVC_Config) :: vehicleData

	-- Update everything to ensure compliance
	for _, v in pairs(customization:GetDescendants()) do
		if v:IsA("Model") then
			-- Set the primary part
			for _, model in pairs(v:GetChildren()) do
				if model:IsA("Model") then
					local point = model:FindFirstChild("Point") :: BasePart?
					if point == nil or point:IsA("BasePart") == false then
						continue
					end
					point:SetAttribute("originalTransparency", point.Transparency)
					model.PrimaryPart = point
				end
			end
		end
	end

	for _, v in pairs(customization:GetChildren()) do
		if v:IsA("Model") then
			-- Remove spaces from model names
			local location = data.customization[v.Name]
			if location == nil then
				log.warn("Failed to find location data for", vehicleName, v.Name)
				continue
			end
			local attachment = BasePoint:FindFirstChild(v.Name)
			data.customization[v.Name] = nil
			v.Name = v.Name:gsub(" ", "_")
			data.customization[v.Name] = location
			log.debug("Updated location model name", vehicleName, v.Name)
			if attachment then
				attachment.Name = v.Name
			end

			-- Loop through the equipments configurations and set their choices
			-- and name
			for equipmentName, equipmentData in pairs(location) do
				if next(equipmentData.configuration) == nil then
					continue
				end
				local equipmentModel = v:FindFirstChild(equipmentName) :: Model?
				if equipmentModel == nil or equipmentModel:IsA("Model") == false then
					log.warn("Failed to find equipment model for", vehicleName, v.Name, equipmentName)
					continue
				end
				local options = equipmentModel:FindFirstChild("Options") :: Model?
				if options == nil or options:IsA("Model") == false then
					log.warn("Failed to find options model for", vehicleName, v.Name, equipmentName)
					continue
				end

				for configurationName, configurationData in pairs(equipmentData.configuration) do
					local configurationModel = options:FindFirstChild(configurationName)
					if configurationModel == nil then
						log.warn(
							"Failed to find configuration instance for",
							vehicleName,
							v.Name,
							equipmentName,
							configurationName
						)
						continue
					end
					configurationModel.Name = configurationName:gsub(" ", "_")
					equipmentData.configuration[configurationName] = nil
					equipmentData.configuration[configurationModel.Name] = configurationData

					if configurationData.type == "select" then
						configurationData.choices = {}
						for _, option in pairs(configurationModel:GetChildren()) do
							table.insert(configurationData.choices :: {}, option.Name)
						end
						table.sort(configurationData.choices :: { string })
					end
				end
			end
		end
	end
	log.debug(data)

	-- Freeze the data, so it can't be modified
	table.freeze(data)
	-- Create the vehicle data
	local vehicleData = {
		vehicle = vehicleModel,
		customization = customization,
		data = data,
	}
	self.cache[vehicleName] = vehicleData
	log.debug("Loaded vehicle", vehicleName)
	return vehicleData
end

function vehicle.getVehicle(self, vehicleName)
	log.debug("Loading vehicle", vehicleName)
	if self.cache[vehicleName] ~= nil then
		local vehicleData = self.cache[vehicleName]
		log.debug("Vehicle already loaded", vehicleName, vehicleData)
		return vehicleData
	end

	if self.vehicles[vehicleName] then
		local success, vehicleFolder = pcall(function()
			return InsertService:LoadAsset(self.vehicles[vehicleName].assetId)
		end)

		if success then
			vehicleFolder = vehicleFolder:FindFirstChildWhichIsA("Folder")
			if vehicleFolder == nil then
				log.warn("Failed to load vehicle", vehicleName, vehicleFolder)
				return
			end
			log.debug("Inserted", vehicleFolder, vehicleFolder:GetDescendants())
			vehicleFolder.Parent = script:FindFirstAncestorOfClass("Plugin")

			return self:_setupVehicle(vehicleName, vehicleFolder)
		end
		log.warn("Failed to load vehicle", vehicleName, vehicleFolder)
	end

	return
end

local function showModel(path: Instance)
	for _, v in pairs(path:GetDescendants()) do
		if v:IsA("BasePart") and (v.Parent and v.Parent.Name ~= "_LIGHTS") then
			local originalTransparency = v:GetAttribute("originalTransparency")
			if originalTransparency ~= nil and type(originalTransparency) == "number" then
				v.Transparency = originalTransparency
			else
				v.Transparency = 0
			end
		end
	end

	if path:IsA("BasePart") then
		local originalTransparency = path:GetAttribute("originalTransparency")
		if originalTransparency ~= nil and type(originalTransparency) == "number" then
			path.Transparency = originalTransparency
		else
			path.Transparency = 0
		end
	end
end

local function getOriginalConfiguration(
	vehicleFolder: vehicleFolder,
	basePoint: BasePart,
	equipmentModel: Model,
	configurationName: string
): Instance?
	local originalLocationName = equipmentModel:GetAttribute("EVCEquipmentName") :: string?
	if originalLocationName == nil or typeof(originalLocationName) ~= "string" then
		log.warn("Failed to get original location name", originalLocationName)
		return
	end
	local originalLocation = vehicleFolder.customization:FindFirstChild(originalLocationName) :: Model?
	if originalLocation == nil or originalLocation:IsA("Model") == false then
		log.warn("Failed to get original locatio", originalLocationName)
		return
	end
	local originalEquipmentName = equipmentModel.Name
	local originalEquipment = originalLocation:FindFirstChild(originalEquipmentName) :: Model?
	if originalEquipment == nil or originalEquipment:IsA("Model") == false then
		log.warn("Failed to get original equipment", originalLocationName)
		return
	end
	local customizationPrimaryPart = originalEquipment.PrimaryPart
	if customizationPrimaryPart == nil then
		return
	end
	local attachment = customizationPrimaryPart:FindFirstChildWhichIsA("Attachment")
	if attachment == nil then
		return
	end

	local newEquipment = originalEquipment:Clone()
	newEquipment:SetAttribute("EVCEquipmentName", originalLocationName)
	newEquipment:PivotTo(basePoint.CFrame * CFrame.new(-attachment.Position))
	newEquipment.Parent = equipmentModel.Parent

	local originalOptions = newEquipment:FindFirstChild("Options") :: Model?
	if originalOptions == nil or originalOptions:IsA("Model") == false then
		log.warn("Failed to get original options", originalLocationName)
		return
	end
	local originalConfiguration = originalOptions:FindFirstChild(configurationName)
	if originalConfiguration == nil then
		log.warn("Failed to get configuration", originalLocationName)
		return
	end

	local new = originalConfiguration:Clone()
	new.Parent = plugin
	newEquipment:Destroy()
	return new
end

function vehicle.changeConfiguration(_, vehicleFolder, equipmentModel, configuration)
	local options = equipmentModel:FindFirstChild("Options") :: Model?
	if options == nil or options:IsA("Model") == false then
		log.warn("Failed to find options", equipmentModel)
		return
	end
	if equipmentModel.Parent == nil then
		log.warn("Failed to find equipment parent", equipmentModel)
		return
	end
	local basePoint = equipmentModel.Parent:FindFirstChild("BasePoint") :: BasePart?
	if basePoint == nil or basePoint:IsA("BasePart") == false then
		log.warn("Failed to find base point", equipmentModel)
		return
	end

	for configurationName, configurationData in pairs(configuration) do
		local optionModel = options:FindFirstChild(configurationName)
		local originalConfiguration =
			getOriginalConfiguration(vehicleFolder, basePoint, equipmentModel, configurationName)
		if originalConfiguration == nil then
			log.warn("Failed to find original configuration", configurationName)
			continue
		end

		if configurationData == true then
			log.debug("Activate configuration", configurationName, configurationData)
			local model = optionModel or originalConfiguration
			showModel(model)
			model.Parent = options
			if model ~= originalConfiguration then
				originalConfiguration:Destroy()
			end
			equipmentModel:SetAttribute(configurationName, configurationData)
		elseif typeof(configurationData) == "table" and optionModel ~= nil then
			log.debug("Changing configuration", configurationName, configurationData, optionModel)
			optionModel:ClearAllChildren()
			local attribute = ""
			for name, value in configurationData do
				local model = originalConfiguration:FindFirstChild(name)
				if model ~= nil and value == true then
					showModel(model)
					model.Parent = optionModel
					attribute ..= `{name}+`
				end
			end
			originalConfiguration:Destroy()
			equipmentModel:SetAttribute(configurationName, attribute)
		elseif optionModel ~= nil then
			log.debug("Deleting configuration", configurationName, configurationData)
			optionModel:Destroy()
			originalConfiguration:Destroy()
			equipmentModel:SetAttribute(configurationName, configurationData)
		end
		vehicle:updateEquipmentLights(equipmentModel, equipmentModel:GetAttribute("LightPrefix") :: string)
	end
end

function vehicle.changeEquipment(self, vehicleFolder, outfitting, location, equipmentName)
	local basePoint = outfitting:FindFirstChild("BasePoint") :: BasePart?
	if basePoint == nil or basePoint:IsA("BasePart") == false then
		log.warn("Failed to find base point", outfitting)
		return false
	end

	local currentEquipment = outfitting:GetAttribute(location)
	if currentEquipment == equipmentName then
		log.warn("Equipment is already equipped", currentEquipment, equipmentName)
		return false
	end

	-- Clear the current customization
	if currentEquipment ~= nil and typeof(currentEquipment) == "string" and currentEquipment ~= "BasePoint" then
		local currentModel = outfitting:FindFirstChild(currentEquipment) :: Model?
		if currentModel == nil then
			log.warn("Failed to find current equipment", currentEquipment)
			return false
		end
		currentModel:Destroy()
		outfitting:SetAttribute(location, nil)
	end

	if equipmentName == nil then
		return true
	end
	local locationModel = vehicleFolder.customization:FindFirstChild(location) :: Model?
	if locationModel == nil or locationModel:IsA("Model") == false then
		log.warn("Failed to find local location model", location)
		return false
	end
	local newModel = locationModel:FindFirstChild(equipmentName) :: Model?
	if newModel == nil or newModel:IsA("Model") == false then
		log.warn("Failed to find new equipment model", equipmentName)
		return false
	end
	local customizationPrimaryPart = newModel.PrimaryPart
	if customizationPrimaryPart == nil then
		log.warn("Failed to find primary part", newModel)
		return false
	end
	local attachment = customizationPrimaryPart:FindFirstChildWhichIsA("Attachment")
	if attachment == nil then
		log.warn("Failed to find attachment", customizationPrimaryPart)
		return false
	end

	local newEquipment = newModel:Clone()
	newEquipment:SetAttribute("EVCEquipmentName", location)
	newEquipment:PivotTo(basePoint.CFrame * CFrame.new(-attachment.Position))
	newEquipment.Parent = outfitting
	outfitting:SetAttribute(location, equipmentName)
	showModel(newEquipment)

	local data = vehicleFolder.data.customization[location][equipmentName]
	if next(data.configuration) == nil then
		log.debug("No configuration found", location, equipmentName)
		return true
	end
	local defaultConfiguration: { [string]: boolean | { [string]: boolean } } = {}
	for optionName, option in pairs(data.configuration) do
		if option.type == "select" and option.choices then
			local default = {}
			for _, choice in option.choices do
				if choice == option.default then
					default[choice] = true
				else
					default[choice] = false
				end
			end
			defaultConfiguration[optionName] = default
		elseif typeof(option.default) == "boolean" then
			defaultConfiguration[optionName] = option.default :: boolean
		end
	end
	self:changeConfiguration(vehicleFolder, newEquipment, defaultConfiguration)
	return true
end

function vehicle.initVehicle(self, vehicleModel)
	if self.vehicles[vehicleModel.Name] then
		local vehicleFolder = self.getVehicle(self, vehicleModel.Name)
		if vehicleFolder == nil then
			log.warn("Failed to outfit vehicle, no vehicle found", vehicleModel.Name)
			return
		end

		local outfitting = self:getOutfitting(vehicleModel)
		if outfitting == nil then
			log.warn("Failed to outfit vehicle, no outfitting found", vehicleModel.Name)
			return
		end

		for locationName, locationData in pairs(vehicleFolder.data.customization) do
			for equipmentName, equipmentData in pairs(locationData) do
				if equipmentData.default == true then
					self:changeEquipment(vehicleFolder, outfitting.model, locationName, equipmentName)
				end
			end
		end
	end
end

function vehicle.cloneCustomizationBasePoint(_, vehicleFolder)
	local basePoint = vehicleFolder.customization:FindFirstChild("BasePoint") :: BasePart?
	if basePoint == nil or basePoint:IsA("BasePart") == false then
		return
	end

	local customizationBasePoint = basePoint:Clone()
	customizationBasePoint.Parent = workspace.CurrentCamera
	return customizationBasePoint
end

function vehicle.updateEquipmentLights(_, equipmentModel, oldPrefix)
	local lightPrefix = equipmentModel:GetAttribute("lightPrefix") :: string?
	if lightPrefix == nil or typeof(lightPrefix) ~= "string" then
		return
	end
	if oldPrefix == lightPrefix or oldPrefix == nil or typeof(oldPrefix) ~= "string" then
		oldPrefix = ""
	end

	for _, v in pairs(equipmentModel:GetDescendants()) do
		if v.Parent and v.Parent.Name == "_LIGHTS" then
			local names = v.Name:gsub(oldPrefix, ""):split("%d+$")
			if names[2] ~= nil then
				v.Name = lightPrefix .. names[1] .. names[1]
			else
				v.Name = lightPrefix .. names[1]
			end
		end
	end
end

return vehicle
