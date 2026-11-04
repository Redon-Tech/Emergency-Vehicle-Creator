-- Redon Tech Emergency Vehicle Creator, MIT License
local plugin = script:FindFirstAncestorOfClass("Plugin") :: Plugin

local types = require("../../types")
local color_picker = require("../../vendor/color_picker")
local picker

type props = {
	id: string,
	initialColor: Color3,
}

--[[
	Color Picker
	Creates a color_picker hydrated component
]]
return function(scope: types.Scope, props: props): Color3?
	if picker == nil then
		picker = color_picker.new(props.id, plugin)
		table.insert(scope, picker)
		return
	end

	return picker:Prompt(props.initialColor)
end
