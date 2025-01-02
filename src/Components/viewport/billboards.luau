local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local assets = require(root.Plugin.assets)
local types = require(root.Plugin.types)

return function(
	scope: types.Scope,
	props: {
		attachments: Fusion.UsedAs<{ Attachment }>,
		viewportSize: Fusion.UsedAs<Vector2>,
		currentLocation: Fusion.Value<string?>,
		currentlyConfiguring: Fusion.Value<string?>,
	}
)
	local currentTheme = RedonUI.theme.theme:now()
	--selene: allow(shadowing)
	return scope:Computed(function(use, scope: typeof(scope))
		return scope:ForValues(use(props.attachments), function(_, scope: typeof(scope), value: Attachment)
			local children = {}
			local allAttachments = { value }
			for _, attachment in pairs(value:GetDescendants()) do
				if attachment:IsA("Attachment") then
					table.insert(allAttachments, attachment)
				end
			end
			for _, attachment in pairs(allAttachments) do
				table.insert(
					children,
					scope:New("BillboardGui") {
						Adornee = attachment,
						Size = scope:Computed(function(use)
							local base = use(props.viewportSize)
							return UDim2.fromScale(500 / base.X, 500 / base.Y)
						end),
						MaxDistance = 30,
						AlwaysOnTop = true,
						Name = value.Name,

						[Fusion.Children] = {
							scope:iconButton {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = currentTheme.colors.base,
								Border = 2,
								BorderColor3 = currentTheme.colors.text,
								CornerRadius = UDim.new(1, 0),
								Image = scope:Computed(function(use)
									if use(props.currentLocation) == value.Name then
										return assets.images.redonUI.remove
									end
									return assets.images.redonUI.add
								end),

								[Fusion.OnEvent "Activated"] = function()
									if scope.peek(props.currentLocation) == value.Name then
										props.currentLocation:set(nil)
									else
										props.currentLocation:set(value.Name)
									end
									props.currentlyConfiguring:set(nil)
								end :: unknown,

								[Fusion.Children] = {
									scope:New("UIAspectRatioConstraint") {},
								},
							},
						},
					}
				)
			end

			return children
		end)
	end)
end
