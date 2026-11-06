--# selene: allow(unused_variable)
-- Redon Tech Emergency Vehicle Creator, MIT License

local ConfigurationTypes = require("./handler/EVHEvent/loader/modules/configurationTypes")
local Fusion = require("../Packages/fusion")
local RedonUI = require("../Packages/redon-ui")
local utils = require("./lib/utils")

-- Code Types

export type Scope = Fusion.Scope<typeof(Fusion) & typeof(RedonUI.Components) & typeof(RedonUI.Util) & typeof(utils)>

export type mode = "menu" | "main" | "viewport"

export type menuPanels = "Home" | "Vehicle" | "Settings" | "Help" | "Credits" | "Permission Needed"

export type mainPanels = "Vehicle Setup" | "ELS Setup"
export type vehicleSetupPages = "Functions" | "Sirens" | "Light Settings"
export type elsSetupPages = "Flashers" | "Faders" | "Rotators"
export type pages = vehicleSetupPages | elsSetupPages

export type returnTo = "menu" | "customizer" | "vehicleSetup"

-- Settings Types

export type theme = "Auto" | "Latte" | "Frappe" | "Macchiato" | "Mocha"

export type keybinds = "Q-Y" | "1-6" | "NumPad 1-6"

export type saveBackupMode = "Encrypted" | "Unencrypted" | "None"

-- ELS Types

export type elsColor = ConfigurationTypes.elsColor
export type flasherColumn = ConfigurationTypes.flasherColumn
export type flasherSection = ConfigurationTypes.flasherSection
export type faderData = ConfigurationTypes.faderData
export type faderSection = ConfigurationTypes.faderSection
export type rotatorData = ConfigurationTypes.rotatorData
export type rotatorSection = ConfigurationTypes.rotatorSection
export type pattern = ConfigurationTypes.pattern
export type StandardActivationModes = ConfigurationTypes.StandardActivationModes
export type OverrideActivationModes = ConfigurationTypes.OverrideActivationModes
export type AGEventActivationModes = ConfigurationTypes.AGEventActivationModes
export type activation = ConfigurationTypes.activation
export type elsFunction = ConfigurationTypes.elsFunction
export type ModifierParentSoundBehavior = ConfigurationTypes.ModifierParentSoundBehavior
export type ModifierBehavior = ConfigurationTypes.ModifierBehavior
export type modifier = ConfigurationTypes.modifier
export type SirenBehavior = ConfigurationTypes.SirenBehavior
export type siren = ConfigurationTypes.siren

export type selectedPattern = { functionId: number, patternId: number }

return nil
