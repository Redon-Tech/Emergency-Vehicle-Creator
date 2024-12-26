-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)
local RedonUI = require(root.Packages["redon-ui"])

local pageBase = require(script.Parent.pageBase)
local components = {
	pageBase = pageBase,
}

type props = {
	CurrentPanel: Fusion.Value<types.menuPanels>,
	Version: string,
}

local credits: { { name: string, type: "icon" | "text", description: string?, icon: string?, contrastIcon: string?, content: string? } } =
	{
		{
			type = "icon",
			name = "Parker (parker02311)",
			description = "Owner & Project Maintainer\nBasically created the whole thing",
			icon = assets.images.credits.parker,
		},
		{
			type = "icon",
			name = "Alex (MiataVxbe)",
			description = "Contributor & Admin\nHelped with vehicles and equipment",
			icon = assets.images.credits.alex,
		},
		{
			type = "icon",
			name = "RetiredSubaru",
			description = "Contributor\nHelped with vehicles and equipment",
			icon = assets.images.credits.subaru,
		},
		{
			type = "icon",
			name = "Fusion",
			description = "Elttob & Contributors\nUI Library used to create plugin",
			icon = assets.images.credits.fusion,
			contrastIcon = assets.images.credits.fusionContrast,
		},
		{
			type = "icon",
			name = "ionicons",
			description = "Ionic & Contributors\nIcons used in the plugin",
			icon = assets.images.credits.ionic,
			contrastIcon = assets.images.credits.ionic,
		},
		{
			type = "text",
			name = "Inspirations & Misc",
			content = [[Slither (Litten's Games) - UI Inspiration
Siren Tool (Dawnstar) - Original Inspiration
EasyLS (EasyLS Studios) - Driving Improvement (v3 wouldn't exist without it)]],
		},
		{
			type = "text",
			name = "Testers",
			content = [[There will be a list of testers here whenever we get to that part of development 👍]],
		},
	}

--[[
	Credits
	Creates a credits page for the main menu
]]
return function(baseScope: types.Scope, props: props)
	local scope = Fusion.innerScope(baseScope, components)
	local currentTheme = RedonUI.theme.theme:now()

	-- Components to put inside the list
	local extraComponents = {}

	for key, value in pairs(credits) do
		extraComponents[key + 1] = scope:base {
			Name = tostring(key),
			Size = UDim2.fromOffset(400, 100),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,

			[Fusion.Children] = Fusion.Child {
				scope:New("UIPadding") {
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				},

				scope:textLabel {
					Size = scope:Computed(function()
						if value.type == "icon" then
							return UDim2.new(1, -100, 1, 0)
						else
							return UDim2.fromScale(1, 1)
						end
					end),
					AutomaticSize = Enum.AutomaticSize.Y,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					BackgroundTransparency = 1,

					Text = `<font weight="medium" size="30">{value.name}</font>\n{if value.type == "icon"
						then value.description
						else value.content}`,

					RichText = true,
					TextSize = 20,
					TextWrapped = true,
					FontWeight = Enum.FontWeight.Regular,

					TextYAlignment = Enum.TextYAlignment.Top,
					TextXAlignment = scope:Computed(function()
						if value.type == "icon" then
							return Enum.TextXAlignment.Right
						else
							return Enum.TextXAlignment.Left
						end
					end),
				},

				scope:Computed(function()
					return if value.type == "icon"
						then scope:base {
							Name = "Icon",
							Size = UDim2.fromOffset(80, 80),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromScale(0, 0.5),
							BackgroundTransparency = 1,

							CornerRadius = UDim.new(0, 15),

							Border = scope:Computed(function()
								return if value.contrastIcon == nil then 2 else 0
							end),
							BorderColor = "text",
							Shadow = scope:Computed(function()
								return if value.contrastIcon == nil then true else false
							end),
							ShadowColor = "text",

							[Fusion.Children] = {
								scope:base {
									ClassName = "ImageLabel",
									Name = "ActualImage",
									Size = UDim2.fromScale(1, 1),
									AnchorPoint = Vector2.new(0.5, 0.5),
									Position = UDim2.fromScale(0.5, 0.5),
									BackgroundTransparency = 1,

									Image = scope:Computed(function()
										if currentTheme.colors.white == Color3.new() and value.contrastIcon ~= nil then
											return value.contrastIcon
										else
											return value.icon or ""
										end
									end),
									ScaleType = Enum.ScaleType.Crop,

									CornerRadius = UDim.new(0, 15),
								},
							},
						}
						else nil
				end),
			},
		}
	end

	return scope:pageBase {
		Name = "Credits",
		PrimaryColor = "Primary",
		RowSize = UDim2.fromOffset(400, 0),
		AutomaticSize = Enum.AutomaticSize.Y,

		CurrentPanel = props.CurrentPanel,
		Version = props.Version,

		Rows = extraComponents,
	}
end
