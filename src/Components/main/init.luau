-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)
local log = require(root.Plugin.log)
local popup = require(root.Plugin.Components.popup)

local widget = require(script.Parent.base.widget)
local topbar = require(script.topbar)
local components = {
	widget = widget,
	topbar = topbar,
}

local functions = require(script.setup.functions)
local sirens = require(script.setup.sirens)
local lightSettings = require(script.setup.lightSettings)
local flashers = require(script.els.flashers)
local faders = require(script.els.faders)
local rotators = require(script.els.rotators)

type props = {
	Name: string,
	Version: string,

	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	PossibleVehicle: Fusion.Value<Model?>,

	ReturnTo: Fusion.Value<types.returnTo>,
	PopupShown: Fusion.Value<boolean>,
}

--[[
	Main
	Creates the main app for the plugin
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local scope = Fusion.innerScope(baseScope, components)
	local currentTheme = RedonUI.theme.theme:now()

	local currentPanel = scope:Value("Vehicle Setup")
	local currentPage = scope:Value(nil)
	local unsavedChanges = scope:Value(false)
	local currentPattern = scope:Value(nil)
	local installAutoLoader = game:FindFirstChild("Emergency Vehicle Handler - Auto Loader") == nil

	local function configurePossibleVehicle()
		if installAutoLoader then
			return
		end

		local currentPossibleVehicle = scope.peek(props.PossibleVehicle)
		if currentPossibleVehicle ~= nil then
			local currentConfiguration = chassisHandler:getConfiguration(currentPossibleVehicle)
			if currentConfiguration ~= nil then
				log.debug("Found vehicle configuration for possible vehicle")
				props.CurrentVehicle:set(currentPossibleVehicle)
				props.PossibleVehicle:set(nil)
				currentPanel:set("Vehicle Setup")
				currentPage:set("Functions")
			else
				local hasOldPlugin = chassisHandler:hasEVCChassisPluginInstalled(currentPossibleVehicle)
				popup:addPopup(scope, {
					title = "Install Emergency Vehicle Handler",
					description = if hasOldPlugin
						then "Would you like to automatically update your EVC Chassis Plugin to Emergency Vehicle Handler?\n\n<b>Backup your vehicle before upgrading, data loss may occur.</b>"
						else "Would you like to install Emergency Vehicle Handler?",
					actions = {
						{
							text = "Cancel",
							type = "danger",
							key = 1,
							callback = function(newPopup)
								props.PossibleVehicle:set(nil)
								popup:removePopup(newPopup)
								props.Mode:set("main")
							end,
						},
						{
							text = if hasOldPlugin then "Upgrade" else "Install",
							type = "primary",
							key = 2,
							callback = function(newPopup)
								local vehicle = scope.peek(props.PossibleVehicle)
								if vehicle ~= nil then
									local installed = chassisHandler:installPlugin(vehicle)
									if installed then
										props.CurrentVehicle:set(vehicle)
										props.PossibleVehicle:set(nil)
										popup:removePopup(newPopup)
									else
										log.warn("Failed to install plugin")
										props.PossibleVehicle:set(nil)
										popup:removePopup(newPopup)
										props.Mode:set("main")
									end
								end
							end,
						},
					},
				})
				currentPanel:set("Vehicle Setup")
				currentPage:set("Functions")
			end
		end
	end

	scope:Observer(props.PossibleVehicle):onBind(configurePossibleVehicle)

	if installAutoLoader then
		popup:addPopup(scope, {
			title = "Install EVH Auto Loader",
			description = "Would you like to install the Emergency Vehicle Handler Auto Loader?",
			actions = {
				{
					text = "Cancel",
					type = "danger",
					key = 1,
					callback = function(newPopup)
						popup:removePopup(newPopup)
						installAutoLoader = false
						configurePossibleVehicle()
					end,
				},
				{
					text = "Install",
					type = "primary",
					key = 2,
					callback = function(newPopup)
						popup:removePopup(newPopup)

						local file = script.Parent.Parent.loader:Clone()
						file.Parent = game:GetService("ServerScriptService")
						file.Name = "Emergency Vehicle Handler - Auto Loader"
						file.Disabled = false
						file.Sandboxed = false

						installAutoLoader = false
						configurePossibleVehicle()
					end,
				},
			},
		})
	end

	local AbsoluteSize = scope:Value(Vector2.one)
	return scope:widget {
		pluginGuiId = `{props.Name}_Main`,
		InitialDockState = Enum.InitialDockState.Float,
		InitialEnabled = false,
		FloatingYSize = 648,
		FloatingXSize = 1152,
		InitialEnabledShouldOverrideRestore = true,
		[Fusion.Out "AbsoluteSize"] = AbsoluteSize,

		Title = scope:Computed(function(use)
			return `EVC {use(currentPanel)} ({use(props.Version)}) {if use(unsavedChanges)
				then "Unsaved Changes*"
				else ""}`
		end),

		Enabled = scope:Computed(function(use)
			local enable = use(props.Enabled) == true and use(props.Mode) == "main"
			if enable and scope.peek(props.CurrentVehicle) ~= nil then
				currentPanel:set("Vehicle Setup")
				currentPage:set("Functions")
			elseif enable and scope.peek(props.PossibleVehicle) == nil then
				currentPattern:set({
					functionId = 0,
					patternId = 0,
					pattern = {
						flashers = {},
						faders = {},
						rotators = {},
					},
				})
				currentPanel:set("ELS Setup")
				currentPage:set("Flashers")
			end
			return enable
		end),

		[Fusion.Children] = {
			scope:base {
				Name = "Main",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = currentTheme.colors.base,
				Interactable = scope:Computed(function(use)
					return not use(props.PopupShown)
				end),

				[Fusion.Children] = Fusion.Child {
					scope:topbar {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						CurrentVehicle = props.CurrentVehicle,
						PossibleVehicle = props.PossibleVehicle,
						ReturnTo = props.ReturnTo,
						Mode = props.Mode,
						CurrentPattern = currentPattern,
					},

					functions(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						ReturnTo = props.ReturnTo,
					}),

					sirens(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
					}),

					lightSettings(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
					}),

					flashers(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						Enabled = props.Enabled,
					}),

					faders(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						Enabled = props.Enabled,
					}),

					rotators(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						Enabled = props.Enabled,
					}),
				},
			},

			scope:textLabel {
				Name = "Version",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 5, 1, -5),
				Size = UDim2.fromOffset(240, 12),
				BackgroundTransparency = 1,

				Text = props.Version,
				TextSize = 9,
				FontWeight = Enum.FontWeight.Regular,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				TextTransparency = 0.5,
			},

			props[Fusion.Children],
		},
	}
end
