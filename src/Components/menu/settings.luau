-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local types = require(root.Plugin.types)
local settings = require(root.Plugin.settings)

local pageBase = require(script.Parent.pageBase)
local components = {
	pageBase = pageBase,
}

type props = {
	CurrentPanel: Fusion.Value<types.menuPanels>,
	Version: string,
}

--[[
	Settings
	Creates a settings page for the main menu
]]
return function(baseScope: types.Scope, props: props): DockWidgetPluginGui
	local scope = Fusion.innerScope(baseScope, components)

	-- Components to put inside the list
	local extraComponents = {}

	for key, valueData in pairs(settings.valueData) do
		local setting = settings.values[valueData.key] :: Fusion.Value<any>
		extraComponents[key + 1] = scope:base {
			Name = key,
			Size = UDim2.fromOffset(400, 100),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,

			[Fusion.Children] = {
				scope:New("UIPadding") {
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				},

				scope:textLabel {
					Size = scope:Computed(function()
						if valueData.type == "boolean" then
							return UDim2.new(1, -52, 1, 0)
						else
							return UDim2.new(1, -160, 1, 0)
						end
					end),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,

					Text = `<font weight="medium" size="30">{valueData.title}</font>\n{valueData.description}`,

					RichText = true,
					TextSize = 20,
					TextWrapped = true,
					FontWeight = Enum.FontWeight.Regular,

					TextYAlignment = Enum.TextYAlignment.Top,
					TextXAlignment = Enum.TextXAlignment.Left,
				},

				scope:Computed(function()
					if valueData.type == "boolean" then
						return scope:checkBox {
							Size = UDim2.fromOffset(42, 42),
							Position = UDim2.fromScale(1, 0.5),
							AnchorPoint = Vector2.new(1, 0.5),
							BackgroundColor = "crust",
							CornerRadius = UDim.new(0, 10),
							Border = 1,
							BorderColor = "white",
							SelectedColor = "blue",
							SelectedCheckColor = "crust",
							Reactive = true,

							Enabled = setting,

							[Fusion.OnEvent "Activated"] = function()
								setting:set(not scope.peek(setting))
							end,
						}
					else
						return scope:dropdown {
							Size = UDim2.fromOffset(150, 42),
							Position = UDim2.new(1, 0, 0, 29),
							AnchorPoint = Vector2.new(1, 0),
							BackgroundColor = "crust",
							CornerRadius = UDim.new(0, 10),
							Border = 1,
							BorderColor = "white",
							DropdownHeight = 150,
							Reactive = true,
							DropdownYOffset = 34,

							Options = valueData.type,
							Text = setting,

							OnOptionSelected = function(_, value)
								setting:set(value)
							end,
						}
					end
				end),
			},
		}
	end

	return scope:pageBase {
		Name = "Settings",
		PrimaryColor = "Primary",
		RowSize = UDim2.fromOffset(400, 0),
		AutomaticSize = Enum.AutomaticSize.Y,

		CurrentPanel = props.CurrentPanel,
		Version = props.Version,

		Rows = extraComponents,
	}
end
