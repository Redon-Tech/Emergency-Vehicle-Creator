-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require("../types")

type callbacks = {
	InputBegan: { (input: InputObject) -> () },
	InputChanged: { (input: InputObject) -> () },
	InputEnded: { (input: InputObject) -> () },
}

local UserInputHelper = {}

UserInputHelper.callbacks = {
	InputBegan = {},
	InputChanged = {},
	InputEnded = {},
} :: callbacks

function UserInputHelper.CallInputBegan(input: InputObject)
	for _, callback in ipairs(UserInputHelper.callbacks.InputBegan) do
		callback(input)
	end
end

function UserInputHelper.CallInputChanged(input: InputObject)
	for _, callback in ipairs(UserInputHelper.callbacks.InputChanged) do
		callback(input)
	end
end

function UserInputHelper.CallInputEnded(input: InputObject)
	for _, callback in ipairs(UserInputHelper.callbacks.InputEnded) do
		callback(input)
	end
end

function UserInputHelper.InputBegan(scope: types.Scope, callback: (input: InputObject) -> ())
	table.insert(UserInputHelper.callbacks.InputBegan, callback)
	table.insert(scope, function()
		table.remove(UserInputHelper.callbacks.InputBegan, table.find(UserInputHelper.callbacks.InputBegan, callback))
	end)
end

function UserInputHelper.InputChanged(scope: types.Scope, callback: (input: InputObject) -> ())
	table.insert(UserInputHelper.callbacks.InputChanged, callback)
	table.insert(scope, function()
		table.remove(
			UserInputHelper.callbacks.InputChanged,
			table.find(UserInputHelper.callbacks.InputChanged, callback)
		)
	end)
end

function UserInputHelper.InputEnded(scope: types.Scope, callback: (input: InputObject) -> ())
	table.insert(UserInputHelper.callbacks.InputEnded, callback)
	table.insert(scope, function()
		table.remove(UserInputHelper.callbacks.InputEnded, table.find(UserInputHelper.callbacks.InputEnded, callback))
	end)
end

return UserInputHelper
