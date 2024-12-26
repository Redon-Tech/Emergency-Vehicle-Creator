--# selene: allow(unused_variable)
-- Redon Tech Emnergency Vehicle Creator, MIT License

local root = script.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local utils = require(script.Parent.utils)

-- Code Types

export type Scope = Fusion.Scope<typeof(Fusion) & typeof(RedonUI.Components) & typeof(RedonUI.Util) & typeof(utils)>

export type mode = "menu" | "app" | "viewport"

export type menuPanels = "Home" | "Vehicle" | "Settings" | "Help" | "Credits"

-- Settings Types

export type theme = "Auto" | "Latte" | "Frappe" | "Macchiato" | "Mocha"

export type keybinds = "Q-Y" | "1-6" | "NumPad 1-6"

export type saveBackupMode = "Encrypted" | "Unencrypted" | "None"

return nil
