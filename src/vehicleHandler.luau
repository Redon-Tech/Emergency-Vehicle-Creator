local vehicleHandler = {}

function vehicleHandler:IsValidVehicle(vehicle: Instance): false | "a" | "ag" | "mg" | "m"
	if vehicle:IsA("Model") then
		local tune = vehicle:FindFirstChild("A-Chassis Tune")
		if tune then
			-- If plugins doesn't exist, it can not be used
			local plugins = tune:FindFirstChild("Plugins")
			if plugins == nil then
				return false
			end

			-- Detect AG chassis
			local loader = plugins:FindFirstChild("AG-Chassis [Loader]")
			if loader then
				return "ag"
			end

			return "a"
		end

		-- Detect MG chassis
		tune = vehicle:FindFirstChild("MG-Chassis Tune")
		if tune then
			return "mg"
		end

		-- Detect NVNA Constraint Type: Motorcycle
		-- AKA Motorcycle Chassis
		tune = vehicle:FindFirstChild("Tuner")
		if tune then
			return "m"
		end
	end
	return false
end

return vehicleHandler
