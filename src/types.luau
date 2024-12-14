--# selene: allow(unused_variable)
local root = script.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])

export type Scope = Fusion.Scope<typeof(Fusion) & typeof(RedonUI.Components) & typeof(RedonUI.Util)>

export type mode = "menu" | "app" | "viewport"

export type menuPanels = "Home" | "Vehicle" | "Settings" | "Help" | "Credits"

return nil
