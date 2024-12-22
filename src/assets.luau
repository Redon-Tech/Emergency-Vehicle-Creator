local log = require(script.Parent.log)

local assets = {
	images = {
		home = {
			settings = "rbxassetid://135865113316058",
			help = "rbxassetid://123835351185186",
			credits = "rbxassetid://95086716451211",
		},
		credits = {
			parker = "rbxassetid://87969994357844",
			alex = "rbxassetid://120135029938880",
			subaru = "rbxassetid://118384213214792",
			fusion = "rbxassetid://106848335032671",
			fusionContrast = "rbxassetid://92779493029740",
		},
	},
	sounds = {},
}

local getAssetUrls
function getAssetUrls(currentTable: { [any]: string | { [any]: any } }, currentUrls: { string })
	for _, value in pairs(currentTable) do
		if typeof(value) == "string" then
			table.insert(currentUrls, value)
		elseif typeof(value) == "table" then
			getAssetUrls(value, currentUrls)
		end
	end

	return currentUrls
end

local assetUrls = getAssetUrls(assets, {})
log.debug("Preloading assets", assetUrls)
task.spawn(function()
	game:GetService("ContentProvider"):PreloadAsync(assetUrls)
	log.debug("Preloaded assets")
end)

return assets
