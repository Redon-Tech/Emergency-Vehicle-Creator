-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent
local plugin = root:FindFirstAncestorWhichIsA("Plugin")

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)

type props = {
	CurrentPanel: Fusion.Value<types.menuPanels>,
}

local function checkPermission()
	local success = pcall(function()
		local tempScript = Instance.new("Script")
		tempScript.Name = "ScriptInjection Test, you can safely delete this"
		tempScript.Parent = workspace
		tempScript:Destroy()
	end)
	return success
end

--[[
	Script Injection Required
	Creates the popup asking for script injection
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()

	local hasAlreadyAsked = scope:Value(false)
	local success, data = pcall(function()
		return plugin:GetSetting("RT_EVC_ScriptInjection")
	end)
	if success and data == true then
		hasAlreadyAsked:set(true)
		if checkPermission() then
			props.CurrentPanel:set("Home")
		else
			props.CurrentPanel:set("Permission Needed")
		end
	else
		props.CurrentPanel:set("Permission Needed")
	end

	return scope:base {
		Name = "Permission Needed",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		[Fusion.Children] = {
			scope:textLabel {
				Name = "Title",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 10),
				Size = UDim2.fromOffset(400, 48),

				Text = "Permission Needed",
				FontWeight = Enum.FontWeight.Bold,
				TextScaled = true,

				TextYAlignment = Enum.TextYAlignment.Top,
			},

			scope:textLabel {
				Name = "Content",
				Size = UDim2.fromOffset(400, 567),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -100),
				Text = scope:Computed(function(use)
					local mainContent = [[
Emergency Vehicle Creator relies heavily on script injection to work properly.
This sounds scary, but it's a common practice in Roblox Studio plugins.

Why we need it:
- To insert vehicles from the vehicle creator
- To create and update the Emergency Vehicle Handler for your vehicles
- To allow for downloading files all across the plugin
                    ]]

					return if use(hasAlreadyAsked)
						then mainContent .. [[


You have already requested script injection.
This means that you have not given permission to the plugin.
Please use manage plugins to enable the permission then click the button below.
]]
						else mainContent .. [[


Please click the button below to request script injection.
This will open a dialog asking for permission to inject scripts.
]]
				end),
				FontWeight = Enum.FontWeight.Medium,
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,

				[Fusion.Children] = {
					scope:New("UIPadding") {
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 5),
					},
				},
			},

			scope:textButton {
				Name = "Request",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -25),
				Size = UDim2.fromOffset(350, 50),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Gradient = ColorSequence.new(currentTheme.colors.sky, currentTheme.colors.sapphire),
				Border = 3,
				CornerRadius = UDim.new(0, 15),
				Text = scope:Computed(function(use)
					return if use(hasAlreadyAsked) then "Check Again" else "Request Script Injection"
				end),
				FontWeight = Enum.FontWeight.Medium,
				TextSize = 30,
				TextColor3 = currentTheme.colors.mantle,
				Reactive = true,
				ButtonGlow = true,
				ButtonGlowColor3 = if currentTheme.colors.white == Color3.new(1, 1, 1)
					then currentTheme.colors.text
					else currentTheme.colors.base,
				Shadow = true,
				ShadowColor3 = currentTheme.colors.sky,

				[Fusion.OnEvent "Activated"] = function()
					local permission = checkPermission()
					plugin:SetSetting("RT_EVC_ScriptInjection", permission)
					hasAlreadyAsked:set(true)
					if permission then
						props.CurrentPanel:set("Home")
					end
				end,
			},
		},
	}
end
