local root = script.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)

local base = require(RedonUI.Components.base)
local components = {
	base = base,
}

type props = base.baseProps & {}

return function(scope: types.Scope) end
