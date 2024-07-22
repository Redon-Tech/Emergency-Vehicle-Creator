--[[
	Redon Tech 2023-2024
	EVC V2

	MIT License
	Copyright (c) 2022-2024 Redon Tech
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

if script.Parent == nil then
	error("EVCPlugin_Client must be a child of Plugins inside a A-Chassis vehicle")
end

local Car = script.Parent:WaitForChild("Car")
if Car ~= nil and Car.ClassName == "ObjectValue" then
	Car = Car.Value
else
	error("Please ensure EVCPlugin_Client is a child of Plugins inside a **A-Chassis vehicle**")
end

local Event = Car:WaitForChild("EVCRemote")
local UserInputService = game:GetService("UserInputService")
local Values = script.Parent:WaitForChild("Values")

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

Values:WaitForChild("PBrake"):GetPropertyChangedSignal("Value"):Connect(function()
	Event:FireServer("DoOverride", "PBrake", Values.PBrake.Value)
end)

Values:WaitForChild("Brake"):GetPropertyChangedSignal("Value"):Connect(function()
	Event:FireServer("DoOverride", "Brake", Values.Brake.Value)
end)

Values:WaitForChild("Gear"):GetPropertyChangedSignal("Value"):Connect(function()
	Event:FireServer("DoOverride", "Gear", Values.Gear.Value)
end)

Event:FireServer("DoOverride", "PBrake", Values.PBrake.Value)
Event:FireServer("DoOverride", "Brake", Values.Brake.Value)
Event:FireServer("DoOverride", "Gear", Values.Gear.Value)

local function input(InputObj: InputObject, gameProcessedEvent: BoolValue)
	if
		not gameProcessedEvent
		and (
			InputObj.UserInputType == Enum.UserInputType.Keyboard
			or InputObj.UserInputType == Enum.UserInputType.Gamepad1
		)
	then
		Event:FireServer("Input", InputObj.UserInputState, InputObj.UserInputType, InputObj.KeyCode)
	end
end

UserInputService.InputBegan:Connect(input)
UserInputService.InputChanged:Connect(input)
UserInputService.InputEnded:Connect(input)
