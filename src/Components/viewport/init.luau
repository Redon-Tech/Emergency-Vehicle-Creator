--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent
local plugin = root:FindFirstAncestorWhichIsA("Plugin")
local mouse = plugin:GetMouse()
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local vehicle = require(root.Plugin.vehicle)
local chassisHandler = require(root.Plugin.chassisHandler)
local log = require(root.Plugin.log)

local billboards = require(script.billboards)
local main = require(script.main)
local components = {
	billboards = billboards,
	main = main,
}

type props = {
	Name: string,
	Version: string,

	Enabled: Fusion.Value<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	ReturnTo: Fusion.Value<types.returnTo>,
}

--[[
	Viewport
	Creates the viewport for vehicle customization and placement
]]
return function(baseScope: types.Scope, props: props)
	local scope = Fusion.innerScope(baseScope, components)
	local currentTheme = RedonUI.theme.theme:now()

	-- Placing Vehicle Handling
	local placingVehicle: Fusion.Value<vehicle.vehicleFolder?> = scope:Value(nil)
	local heightOffset = 0

	local worldModel = scope:New("WorldModel") {
		[Fusion.Children] = {
			scope:Computed(function(use)
				local currentlyPlacing = use(placingVehicle)
				if currentlyPlacing ~= nil then
					local veh = currentlyPlacing.vehicle:Clone()
					veh.PrimaryPart = veh:FindFirstChildWhichIsA("VehicleSeat")
					return scope:Hydrate(veh) {} :: Instance?
				end
				return nil
			end),
		},
	} :: WorldModel

	-- Customizing Vehicle Handling
	local currentVehicleFolder: Fusion.Value<vehicle.vehicleFolder?> = scope:Value(nil)
	local basePoint: Instance? = nil
	local outfitting: Fusion.Value<Model?> = scope:Value(nil)
	local attachments: Fusion.Value<{ Attachment }> = scope:Value({})
	local lightParts: Fusion.Value<{ BasePart }> = scope:Value({})
	local connections: { RBXScriptConnection } = {}
	local currentLocation: Fusion.Value<string?> = scope:Value(nil)
	local currentEquipment = scope:Value("")
	local currentlyConfiguring: Fusion.Value<string?> = scope:Value(nil)
	local currentOptionData: Fusion.Value<{ [string]: boolean | { [string]: boolean } }> = scope:Value({})

	local function cleanupCustomization()
		currentVehicleFolder:set(nil)
		if basePoint ~= nil then
			basePoint:Destroy()
			basePoint = nil
		end
		outfitting:set(nil)
		attachments:set({})
		lightParts:set({})
		currentLocation:set(nil)
		currentlyConfiguring:set(nil)
		for i, connection in pairs(connections) do
			connection:Disconnect()
			connections[i] = nil
		end
		plugin:Deactivate() -- Return the user to the default selection tool
		log.debug("Cleaned up customization")
	end
	table.insert(scope, cleanupCustomization)

	scope:Observer(currentLocation):onChange(function()
		local location = scope.peek(currentLocation)
		local outfittingModel = scope.peek(outfitting)
		if location == nil or outfittingModel == nil then
			currentEquipment:set("")
		else
			local newState = outfittingModel:GetAttribute(location)
			currentEquipment:set(if typeof(newState) == "string" then newState else "")
		end
	end)

	scope:Observer(currentlyConfiguring):onChange(function()
		local vehicleFolder = scope.peek(currentVehicleFolder)
		local outfittingModel = scope.peek(outfitting)
		local location = scope.peek(currentLocation)
		local equipment = scope.peek(currentEquipment)
		local configuring = scope.peek(currentlyConfiguring)
		if
			equipment == ""
			or location == nil
			or configuring == nil
			or outfittingModel == nil
			or vehicleFolder == nil
		then
			currentOptionData:set({})
		else
			local equipmentModel = outfittingModel:FindFirstChild(equipment)
			if equipmentModel == nil then
				currentOptionData:set({})
				return
			end

			local data: { [string]: boolean | { [string]: boolean } } = {}
			for configurationName, configurationData in
				pairs(vehicleFolder.data.customization[location][equipment].configuration)
			do
				local value = equipmentModel:GetAttribute(configurationName)
				if configurationData.type == "single" then
					if value == nil or typeof(value) ~= "boolean" then
						value = false
					end
					data[configurationName] = value :: boolean
				elseif configurationData.type == "select" and configurationData.choices ~= nil then
					local enabled = {}
					if value ~= nil and typeof(value) == "string" then
						enabled = value:split("+")
					end

					for _, optionName in pairs(configurationData.choices) do
						if data[configurationName] == nil then
							data[configurationName] = {}
						end
						if table.find(enabled, optionName) then
							(data[configurationName] :: { [string]: boolean })[optionName] = true
						else
							(data[configurationName] :: { [string]: boolean })[optionName] = false
						end
					end
				end
			end
			currentOptionData:set(data)
		end
	end)

	-- Shared
	local function recomputeLightParts()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if currentVehicle == nil or typeof(currentVehicle) ~= "Instance" then
			lightParts:set({})
			return
		end

		local carOutfitting = vehicle:getOutfitting(currentVehicle)
		if carOutfitting == nil then
			lightParts:set({})
			return
		end

		local newLightParts = {}
		for _, lightPart in pairs(carOutfitting.model:GetDescendants()) do
			if lightPart:IsA("BasePart") and lightPart.Parent ~= nil and lightPart.Parent.Name == "_LIGHTS" then
				table.insert(newLightParts, lightPart)
			end
		end
		log.debug("Recomputed light parts", newLightParts)
		lightParts:set(newLightParts)
	end

	local function modeChange()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if scope.peek(props.Mode) == "viewport" and typeof(currentVehicle) == "string" then
			local vehicleFolder = vehicle:getVehicle(currentVehicle)
			if vehicleFolder ~= nil then
				placingVehicle:set(vehicleFolder)
				local vehicleCFrame, vehicleSize = vehicleFolder.vehicle:GetBoundingBox()
				heightOffset = vehicleSize.Y / 2
				worldModel.WorldPivot = vehicleCFrame
			end
		elseif scope.peek(props.Mode) == "viewport" and currentVehicle ~= nil then
			local vehicleName = currentVehicle:GetAttribute("EVCVehicleName")
			if vehicleName ~= nil and typeof(vehicleName) == "string" and vehicle.vehicles[vehicleName] ~= nil then
				local vehicleFolder = vehicle:getVehicle(vehicleName)
				if vehicleFolder == nil then
					log.warn("Failed to open vehicle customization, no vehicle found", vehicleName)
					return
				end
				local newBasePoint = vehicle:cloneCustomizationBasePoint(vehicleFolder)
				if newBasePoint == nil then
					log.warn("Failed to open vehicle customization, no basepoint found", vehicleName)
					return
				end
				local carOutfitting = vehicle:getOutfitting(currentVehicle)
				if carOutfitting == nil then
					return
				end

				basePoint = newBasePoint
				outfitting:set(carOutfitting.model)

				local newAttachments = {}
				for _, attachment in pairs(newBasePoint:GetChildren()) do
					if attachment:IsA("Attachment") then
						table.insert(newAttachments, attachment)
					end
				end
				attachments:set(newAttachments)

				newBasePoint.CFrame = carOutfitting.basePoint.CFrame
				table.insert(
					connections,
					carOutfitting.basePoint:GetPropertyChangedSignal("CFrame"):Connect(function()
						newBasePoint.CFrame = carOutfitting.basePoint.CFrame
					end)
				)
				table.insert(
					connections,
					currentVehicle:GetPropertyChangedSignal("Parent"):Connect(function()
						if currentVehicle:IsDescendantOf(workspace) == false then
							cleanupCustomization()
							props.CurrentVehicle:set(nil)
							props.Mode:set("menu")
						end
					end)
				)

				-- We want to update the value last
				-- to ensure proper cascading of changes
				currentVehicleFolder:set(vehicleFolder)
				recomputeLightParts()
			end
		elseif scope.peek(props.Mode) == "viewport" then
			props.Mode:set("menu")
			log.warn("Got sent to viewport mode without a vehicle")
		end
	end
	scope:Observer(props.Mode):onChange(modeChange)
	scope:Observer(props.CurrentVehicle):onChange(modeChange)

	local viewportSize = scope:Value(Vector2.one)
	return scope:New("ScreenGui") {
		Name = "EVC",
		Enabled = scope:Computed(function(use)
			return use(props.Enabled) and use(props.Mode) == "viewport"
		end),
		DisplayOrder = 100,
		ResetOnSpawn = false,
		[Fusion.Out "AbsoluteSize"] = viewportSize,

		[Fusion.Children] = Fusion.Child {
			scope:textLabel {
				Size = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = currentTheme.colors.mantle,
				BackgroundTransparency = 0.5,
				Text = "Please wait while the vehicle is loaded..",
				Visible = scope:Computed(function(use)
					return use(currentVehicleFolder) == nil and use(placingVehicle) == nil
				end),
			},

			scope:billboards {
				attachments = attachments,
				viewportSize = viewportSize,
				currentLocation = currentLocation,
				currentlyConfiguring = currentlyConfiguring,
				lightParts = lightParts,
			},

			scope:main {
				attachments = attachments,
				viewportSize = viewportSize,
				currentLocation = currentLocation,

				outfitting = outfitting,
				CurrentVehicle = props.CurrentVehicle,
				Mode = props.Mode,
				currentVehicleFolder = currentVehicleFolder,
				currentEquipment = currentEquipment,

				currentlyConfiguring = currentlyConfiguring,
				currentOptionData = currentOptionData,

				cleanupCustomization = cleanupCustomization,
				recomputeLightParts = recomputeLightParts,
				ReturnTo = props.ReturnTo,
			},

			scope:base {
				ClassName = "TextButton",
				Name = "Placement",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				Visible = scope:Computed(function(use)
					return use(placingVehicle) ~= nil
				end),

				[Fusion.OnEvent "MouseMoved"] = function()
					worldModel:MoveTo(mouse.Hit.Position + Vector3.new(0, heightOffset, 0))
				end :: unknown,

				[Fusion.OnEvent "Activated"] = function()
					local currentlyPlacing = scope.peek(placingVehicle)
					local currentVehicle = scope.peek(props.CurrentVehicle)
					if currentlyPlacing == nil or currentVehicle == nil then
						return
					end

					local newVehicle = currentlyPlacing.vehicle:Clone()
					newVehicle.Name = scope.peek(currentVehicle)
					newVehicle.Parent = workspace
					newVehicle:PivotTo(worldModel:GetPivot())
					vehicle:initVehicle(newVehicle)
					chassisHandler:installPlugin(newVehicle)
					props.CurrentVehicle:set(newVehicle)
					currentVehicleFolder:set(currentlyPlacing)
					placingVehicle:set(nil)
					ChangeHistoryService:SetWaypoint("Setup Vehicle")
				end,

				[Fusion.Children] = {
					scope:New("ViewportFrame") {
						Size = UDim2.fromScale(1, 1),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						CurrentCamera = workspace.CurrentCamera,
						ImageTransparency = 0.5,

						[Fusion.Children] = {
							worldModel,
						},
					},

					scope:textButton {
						Name = "Cancel",
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0.0092592593),
						Size = UDim2.fromScale(0.078125, 0.0462962963),
						BackgroundColor3 = currentTheme.colors.crust,
						Border = 2,
						BorderColor3 = currentTheme.colors.text,
						CornerRadius = UDim.new(0.2, 0),
						Text = "Cancel",
						TextScaled = true,
						FontWeight = Enum.FontWeight.Bold,
						Reactive = true,
						MaxTextSize = 35,

						[Fusion.OnEvent "Activated"] = function()
							placingVehicle:set(nil)
							props.CurrentVehicle:set(nil)
							props.Mode:set("menu")
						end :: unknown,
					},
				},
			},

			scope:textLabel {
				Name = "EVCActive",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 5, 1, -5),
				Size = UDim2.fromOffset(400, 18),
				BackgroundTransparency = 1,
				TextTransparency = 0.5,

				Text = "Emergency Vehicle Creator Active",
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
			},

			scope:textLabel {
				Name = "Version",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.new(1, -5, 1, -5),
				Size = UDim2.fromOffset(400, 18),
				BackgroundTransparency = 1,
				TextTransparency = 0.5,

				Text = props.Version,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Right,
			},
		},
	}
end
