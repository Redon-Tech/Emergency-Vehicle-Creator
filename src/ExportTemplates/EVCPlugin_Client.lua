--[[
	Redon Tech 2023
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local Car = script.Parent.Car.Value
local Event = Car:WaitForChild("EVCRemote")
local UserInputService = game:GetService("UserInputService")
local Values = script.Parent.Values

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

Values.PBrake:GetPropertyChangedSignal("Value"):Connect(function()
	Event:FireServer("DoOverride", "PBrake", Values.PBrake.Value)
end)

Values.Brake:GetPropertyChangedSignal("Value"):Connect(function()
	Event:FireServer("DoOverride", "Brake", Values.Brake.Value)
end)

Values.Gear:GetPropertyChangedSignal("Value"):Connect(function()
	Event:FireServer("DoOverride", "Gear", Values.Gear.Value)
end)

local function input(InputObj: InputObject, gameProcessedEvent: BoolValue)
	if not gameProcessedEvent and InputObj.UserInputType == Enum.UserInputType.Keyboard then
		Event:FireServer("Input", InputObj.UserInputState, InputObj.UserInputType, InputObj.KeyCode)
	end
end

UserInputService.InputBegan:Connect(input)
UserInputService.InputChanged:Connect(input)
UserInputService.InputEnded:Connect(input)