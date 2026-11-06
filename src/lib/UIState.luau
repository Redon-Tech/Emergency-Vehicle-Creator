-- Redon Tech Emergency Vehicle Creator, MIT License
local Fusion = require("../../Packages/fusion")
local types = require("../types")

local UIState = {}

function UIState.init(scope: types.Scope, initiallyEnabled: boolean)
	UIState.enabled = scope:Value(initiallyEnabled)
	UIState.mode = scope:Value("menu" :: types.mode)
	UIState.currentVehicle = scope:Value(nil) :: Fusion.Value<Model | string?>
	UIState.possibleVehicle = scope:Value(nil) :: Fusion.Value<Model?>
	UIState.returnTo = scope:Value("menu" :: types.returnTo)
	UIState.menuPanel = scope:Value("Home" :: types.menuPanels)
	UIState.mainPanel = scope:Value("Vehicle Setup" :: types.mainPanels)
	UIState.mainPage = scope:Value(nil) :: Fusion.Value<types.pages?>
	UIState.currentPattern = scope:Value(nil) :: Fusion.Value<types.selectedPattern?>
	UIState.unsavedChanges = scope:Value(false)
	UIState.popupShown = scope:Value(false)
end

return UIState
