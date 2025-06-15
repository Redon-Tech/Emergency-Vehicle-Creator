--!strict
--#selene: allow(global_usage)
-- Redon Tech Emergency Vehicle Creator, MIT License

--[=[
	Ensures only one EVH is running at a time
	and that the running EVH is the latest version

    Edgecase: A newer verstion is inserted after handshake is done.
	To handle this, we will check allow that newer version to run
	its vehicles by itself
]=]
return function(version: number): boolean
	local uuid = game:GetService("HttpService"):GenerateGUID(false)

	if _G.EVHHANDSHAKE == nil or (_G.EVHHANDSHAKE.status == "handshaking" and version > _G.EVHHANDSHAKE.version) then
		_G.EVHHANDSHAKE = {
			version = version,
			uuid = uuid,
			status = "handshaking",
		}
	else
		return false
	end

	task.wait(1)
	if _G.EVHHANDSHAKE.uuid == uuid then
		_G.EVHHANDSHAKE.status = "done"
		_G.RUNNINGEVH = { version }
		return true
	else
		return false
	end
end
