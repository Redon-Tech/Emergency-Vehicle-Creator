--[[
Redon Tech 2022
EVC
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

Values.Park:GetPropertyChangedSignal("Value"):Connect(function()
	Event:FireServer("ParkMode", Values.Park.Value)
	-- I am doing this in school, I have no idea if this is the right value name
end)

local function input(InputObj: InputObject, gameProcessedEvent: BoolValue)
	if not gameProcessedEvent and InputObj.UserInputType == Enum.UserInputType.Keyboard then
		Event:FireServer("Input", InputObj.UserInputState, InputObj.UserInputType, InputObj.KeyCode)
	end
end

UserInputService.InputBegan:Connect(input)
UserInputService.InputChanged:Connect(input)
UserInputService.InputEnded:Connect(input)