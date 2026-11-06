--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local types = require("../../../types")
local ConfigurationEditor = require("../../../lib/ConfigurationEditor")

local functionsPage = require("@self/functionsPage")
local activationsPage = require("@self/activationsPage")
local components = {
	functionsPage = functionsPage,
	activationsPage = activationsPage,
}

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
	ReturnTo: Fusion.Value<types.returnTo>,
}

--[[
	Functions
	Creates the functions page for the main app
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local scope = baseScope:innerScope(components)
	local currentTheme = RedonUI.theme.theme:now()
	local firstScope = scope:innerScope()

	local currentContent: Fusion.Value<"functions" | "activation" | "patterns"> = scope:Value("functions" :: any)
	local selectedFunction: Fusion.Value<number?> = scope:Value(nil)

	scope:Observer(props.CurrentVehicle):onBind(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			local currentConfiguration = scope.peek(ConfigurationEditor.current)
			if currentConfiguration ~= nil then
				currentContent:set("functions")
			end
		end
	end)

	local actualTableSize = scope:Value(Vector2.one)

	-- 1820, 895
	return scope:base {
		Name = "Functions",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = scope:Spring(
			scope:Computed(function(use)
				local currentPage = use(props.CurrentPage)
				if currentPage == "Functions" then
					return UDim2.fromScale(0.5, 0.0462962963)
				end
				return UDim2.fromScale(-1, 0.0462962963)
			end),
			20,
			0.75
		),
		Size = UDim2.fromScale(1, 0.9537037037),
		BackgroundColor3 = currentTheme.colors.base,

		[Fusion.Children] = {
			scope:New("UIAspectRatioConstraint") {
				AspectRatio = 1.8640776699,
			},

			scope:New("UIPadding") {
				PaddingTop = UDim.new(0.0231481481, 0),
				PaddingBottom = UDim.new(0.0231481481, 0),
				PaddingLeft = UDim.new(0.0260416667, 0),
				PaddingRight = UDim.new(0.0260416667, 0),
			},

			scope:textLabel {
				Size = UDim2.fromScale(1, 0.0555555556),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Text = scope:Computed(function(use)
					local selected = use(selectedFunction)
					local currentConfiguration = scope.peek(ConfigurationEditor.current)

					return if selected ~= nil and currentConfiguration ~= nil
						then `Editing Function {scope.peek(scope.peek(currentConfiguration.functions)[selected].name)}`
						else "Select A Function"
				end),
				FontWeight = scope:Computed(function(use)
					return if use(selectedFunction) ~= nil then Enum.FontWeight.Bold else Enum.FontWeight.Medium
				end),
				TextScaled = true,
			},

			scope:base {
				Size = UDim2.fromScale(1, 0.9212962963),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundColor3 = currentTheme.colors.mantle,
				CornerRadius = UDim.new(0.0179640719, 0),
				ClipsDescendants = true,

				[Fusion.Children] = {
					scope:functionsPage {
						UnsavedChanges = props.UnsavedChanges,
						CurrentVehicle = props.CurrentVehicle,
						currentContent = currentContent,
						actualTableSize = actualTableSize,
						selectedFunction = selectedFunction,
					},

					scope:activationsPage {
						UnsavedChanges = props.UnsavedChanges,
						CurrentPanel = props.CurrentPanel,
						CurrentPage = props.CurrentPage,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = props.CurrentPattern,
						ReturnTo = props.ReturnTo,
						firstScope = firstScope,
						currentContent = currentContent,
						actualTableSize = actualTableSize,
						selectedFunction = selectedFunction,
					},
				},
			},
		},
	}
end
