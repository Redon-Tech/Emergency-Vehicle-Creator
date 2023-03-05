local pluginupdate = {updates={}}

pluginupdate.updates[101] = function(IsAG, Car, Settings)
	Settings.Parent = script

	if IsAG then
		if Car.Body.ELS.PTRNS:FindFirstChild("EVCPlugin_AG") then
			Car.Body.ELS.PTRNS.EVCPlugin_AG:Destroy()
		end

		local Server = script.Parent.Parent.ChassisPlugin.EVCPlugin_AG:Clone()
		Server.Parent = Car.Body.ELS.PTRNS
		Server.Enabled = true
		Settings.Parent = Car.Body.ELS.PTRNS
	else
		if Car:FindFirstChild("A-Chassis Tune") then
			if Car["A-Chassis Tune"].Plugins:FindFirstChild("EVCPlugin_Client") then
				Car["A-Chassis Tune"].Plugins.EVCPlugin_Client:Destroy()
			end

			local Client = script.Parent.Parent.ChassisPlugin.EVCPlugin_Client:Clone()
			Client.Parent = Car["A-Chassis Tune"].Plugins
			Client.Enabled = true
			local RemoteEvent = Instance.new("RemoteEvent")
			RemoteEvent.Name = "EVCRemote"
			RemoteEvent.Parent = Client
			local Server = script.Parent.Parent.ChassisPlugin.EVCPlugin:Clone()
			Server.Parent = RemoteEvent
			Server.Enabled = false
			Settings.Parent = RemoteEvent
		end
	end
end

pluginupdate.UpdatePlugin = function(Car: Model, Settings: ModuleScript)
	local AG = false
	if Car:FindFirstChild("A-Chassis Tune") and Car["A-Chassis Tune"]:FindFirstChild("AG-Chassis [Loader]") then
		AG = true
	end

	local loadedSettings = require(Settings)
	local ver = loadedSettings.PluginVersion
	local numberstring = string.gsub(ver, "%.", "")
	print(ver, numberstring)

	for i,v in pairs(pluginupdate.updates) do
		print(tonumber(numberstring), i)
		if tonumber(numberstring) < i then
			v(AG, Car, Settings)
		end
	end

	local newSettings = string.gsub(Settings.Source, ver, require(script.Parent.Parent.ChassisPlugin.Settings).PluginVersion)
	Settings.Source = newSettings
end

return pluginupdate