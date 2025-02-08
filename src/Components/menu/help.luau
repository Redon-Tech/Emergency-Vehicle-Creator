-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)

local pageBase = require(script.Parent.pageBase)
local components = {
	pageBase = pageBase,
}

type props = {
	CurrentPanel: Fusion.Value<types.menuPanels>,
	Version: string,
}

local supportOptions = {
	[1] = {
		name = "YouTube Video",
		description = "This video provides a overview of the entire plugin.",
		link = "https://www.youtube.com/watch?v=NNoIUVLspzc&list=PL7OqW0xeBKZTbk4QMl-6v3V_x11pZBV0W",
	},
	[2] = {
		name = "Discord",
		description = "If you still need help please use our Discord.",
		link = "https://discord.gg/Eb384Xw",
	},
	[3] = {
		name = "Other Support",
		description = "Need to contact us about something else?",
		link = "parker02311@redon.tech",
	},
}

--[[
	Help
	Creates a help page for the main menu
]]
return function(baseScope: types.Scope, props: props)
	local scope = Fusion.innerScope(baseScope, components)
	local currentTheme = RedonUI.theme.theme:now()

	-- Components to put inside the list
	local extraComponents = {
		[1] = scope:textLabel {
			Size = UDim2.fromOffset(400, 10),
			BackgroundTransparency = 1,
			Text = "This plugin is complex but also simple at the same time. We understand that the plugin can be confusing so we have provided some resources to help!",
			TextWrapped = true,
			TextSize = 20,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextXAlignment = Enum.TextXAlignment.Center,
			FontWeight = Enum.FontWeight.Regular,

			[Fusion.Children] = {
				scope:New("UIPadding") {
					PaddingBottom = UDim.new(0, 10),
				},
			},
		},

		[#supportOptions + 2] = scope:textLabel {
			Size = UDim2.fromOffset(400, 20),
			BackgroundTransparency = 1,
			Text = "(To copy: Highlight the link, press Ctrl + C)",
			TextWrapped = true,
			TextSize = 20,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextXAlignment = Enum.TextXAlignment.Center,
			FontWeight = Enum.FontWeight.Regular,

			[Fusion.Children] = {
				scope:New("UIPadding") {
					PaddingTop = UDim.new(0, 10),
				},
			},
		},
	}

	for key, value in pairs(supportOptions) do
		local CursorPosition = scope:Value(-1)
		local SelectionStart = scope:Value(-1)
		extraComponents[key + 1] = scope:base {
			Name = tostring(key),
			Size = UDim2.fromOffset(400, 122),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,

			[Fusion.Children] = {
				scope:New("UIPadding") {
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
				},

				scope:textLabel {
					Name = "Title",
					Size = UDim2.fromOffset(380, 30),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 0),
					Text = value.name,
					TextSize = 30,
					TextXAlignment = Enum.TextXAlignment.Center,
					FontWeight = Enum.FontWeight.Medium,
				},

				scope:textLabel {
					Name = "Description",
					Size = UDim2.fromOffset(380, 0),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 31),
					AutomaticSize = Enum.AutomaticSize.Y,
					Text = value.description,
					TextSize = 20,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontWeight = Enum.FontWeight.Regular,

					[Fusion.Children] = {
						scope:New("UIPadding") {
							PaddingBottom = UDim.new(0, 53),
						},
					},
				},

				scope:textBox {
					Name = "Link",
					Size = UDim2.fromOffset(380, 42),
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, 0),
					Text = value.link,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontWeight = Enum.FontWeight.Regular,
					ClearTextOnFocus = false,
					TextEditable = false,
					CursorPosition = CursorPosition,
					SelectionStart = SelectionStart,
					BackgroundColor3 = currentTheme.colors.crust,
					Border = 1,
					CornerRadius = UDim.new(0, 10),
					MaxTextSize = 25,

					[Fusion.OnEvent "Focused"] = function()
						task.wait(0.1)
						SelectionStart:set(0)
						CursorPosition:set(#value.link + 1)
					end :: unknown,

					[Fusion.OnEvent "FocusLost"] = function()
						CursorPosition:set(-1)
						SelectionStart:set(-1)
					end,
				},
			},
		}
	end

	return scope:pageBase {
		Name = "Help",
		PrimaryColor = "Primary",
		RowSize = UDim2.fromOffset(400, 0),
		AutomaticSize = Enum.AutomaticSize.Y,

		CurrentPanel = props.CurrentPanel,
		Version = props.Version,

		Rows = extraComponents,
	}
end
