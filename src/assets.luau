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
			ionic = "rbxassetid://71776903426004",
		},
		redonUI = {
			check = "rbxassetid://109702476150696",
			arrow = "rbxassetid://110726366161984",
			create = "rbxassetid://139549363450320",
			createFilled = "rbxassetid://126924702377763",
			add = "rbxassetid://131875989308596",
			remove = "rbxassetid://139585109490603",
			trash = "rbxassetid://84339644678815",
			trashFilled = "rbxassetid://107030343619370",
			download = "rbxassetid://108720050020650",
			downloadFilled = "rbxassetid://107900022917876",
		},
		vehicles = {
			FPIU2020 = "rbxassetid://138806014801248",
		},
	},
	sounds = {},
}
table.freeze(assets)

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
	local startTime = os.clock()
	game:GetService("ContentProvider")
		:PreloadAsync(assetUrls, function(assetId: unknown, assetFetchStatus: Enum.AssetFetchStatus)
			log.debug("Preloaded asset", assetId, assetFetchStatus)
		end)
	log.debug(`Preloaded assets in {os.clock() - startTime}`)
end)

return assets
