-- Redon Tech Emergency Vehicle Creator, MIT License
local V0_02 = { version = 0.02 }

function V0_02.update(data: any)
	local lightSettings = data.lightSettings
	local optimizations = lightSettings.optimizations
	if optimizations == nil then
		return
	end

	lightSettings.configuration = {
		shouldChangeNeons = optimizations.shouldChangeNeons,
		shouldChangeLights = optimizations.shouldChangeLights,
		shouldChangeLightos = optimizations.shouldChangeLightos,
		partTransparency = 0.011,
	}
	lightSettings.optimizations = nil
end

return V0_02
