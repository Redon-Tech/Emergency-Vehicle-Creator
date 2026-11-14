-- Redon Tech Emergency Vehicle Creator, MIT License
local V0_05 = { version = 0.05 }

function V0_05.update(data: any)
	if data.lightSettings.configuration.shouldChangeParticleEmitters == nil then
		data.lightSettings.configuration.shouldChangeParticleEmitters = false
	end
end

return V0_05
