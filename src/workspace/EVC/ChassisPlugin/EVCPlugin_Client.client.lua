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

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

local function input(InputObj: InputObject, gameProcessedEvent: BoolValue)
	if not gameProcessedEvent and InputObj.UserInputType == Enum.UserInputType.Keyboard then
		Event:FireServer(InputObj.UserInputState, InputObj.UserInputType, InputObj.KeyCode)
	end
end

UserInputService.InputBegan:Connect(input)
UserInputService.InputChanged:Connect(input)
UserInputService.InputEnded:Connect(input)