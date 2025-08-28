--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)

local functionsPage = require(script.functionsPage)
local activationsPage = require(script.activationsPage)
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
	local currentConfiguration = nil
	local functions: Fusion.Value<{ { name: string, weight: number } }> = scope:Value({})
	local patterns: Fusion.Value<{ types.pattern }> = scope:Value({})
	local activations: Fusion.Value<{ types.activationState }> = scope:Value({})
	local selectedFunction: Fusion.Value<number?> = scope:Value(nil)

	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
			if currentConfiguration ~= nil then
				local newFunctions = {}
				for i, func in currentConfiguration.functions do
					newFunctions[i] = { name = func.name, weight = func.weight }
				end
				functions:set(newFunctions)
				currentContent:set("functions")
			end
		end
	end)

	scope:Observer(selectedFunction):onChange(function()
		local currentFunction = scope.peek(selectedFunction)
		if currentConfiguration ~= nil and currentFunction ~= nil then
			local newActivations: { types.activationState } = {}
			for activationKey, activationData in pairs(currentConfiguration.functions[currentFunction].activations) do
				local newActivation = {} :: types.activationState
				for key, value in pairs(activationData) do
					if typeof(value) == "table" then
						local newTable = {}
						for i, v in pairs(value) do
							newTable[i] = firstScope:Value(v)
						end
						newActivation[key] = newTable
					else
						newActivation[key] = firstScope:Value(value)
					end
				end
				if activationData.type == "Override" and activationData.siren == nil then
					newActivation.siren = firstScope:Value(nil)
				end

				table.insert(newActivations, activationKey, newActivation)
			end
			activations:set(newActivations)
		else
			activations:set({})
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
					return if selected ~= nil
						then `Editing Function {scope.peek(functions)[selected].name}`
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
						functions = functions,
						actualTableSize = actualTableSize,
						patterns = patterns,
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
						functions = functions,
						activations = activations,
						actualTableSize = actualTableSize,
						patterns = patterns,
						selectedFunction = selectedFunction,
					},
				},
			},
		},
	}
end
