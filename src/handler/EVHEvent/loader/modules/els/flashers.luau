--!strict
--!optimize 2
--!native
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require(script.Parent.Parent.types)

type flashers = {
	runningPatterns: { types.pattern },
	addPattern: (pattern: types.pattern) -> (),
	removePattern: (pattern: types.pattern) -> (),
	flash: (vehicle: Instance, functionId: number, lightName: string, color: types.elsColor) -> (),
}
local flashers = {
	runningPatterns = {},
} :: flashers
local threads: { { activeThread: thread, running: { { functionId: number, vehicle: Instance, section: types.flasherSection } } } } =
	{}

function flashers.addPattern(pattern: types.pattern)
	for _, flasherSection in pairs(pattern.flashers) do
		if threads[flasherSection.waitTime] == nil then
			threads[flasherSection.waitTime] = {
				activeThread = task.spawn(function()
					while task.wait(flasherSection.waitTime) do
						for _, runningData in pairs(threads[flasherSection.waitTime].running) do
							for _, columns in pairs(runningData.section.columns) do
								flashers.flash(
									runningData.vehicle,
									runningData.functionId,
									columns.lightName,
									columns.rows[runningData.section.currentRow :: number]
								)
							end

							local nextRow = (runningData.section.currentRow :: number) + 1
							if nextRow > runningData.section.rowCount then
								nextRow = 1
							end
							runningData.section.currentRow = nextRow
						end
					end
				end),
				running = {},
			}
		end

		flasherSection.currentRow = 1
		table.insert(threads[flasherSection.waitTime].running, {
			vehicle = pattern.vehicle,
			functionId = pattern.functionId,
			section = flasherSection,
		})
	end
end

function flashers.removePattern(pattern: types.pattern)
	for _, flasherSection in pairs(pattern.flashers) do
		if threads[flasherSection.waitTime] == nil then
			continue
		end

		for i, runningData in pairs(threads[flasherSection.waitTime].running) do
			if runningData.functionId == pattern.functionId then
				table.remove(threads[flasherSection.waitTime].running, i)
			end
		end

		if #threads[flasherSection.waitTime].running == 0 then
			coroutine.close(threads[flasherSection.waitTime].activeThread)
			threads[flasherSection.waitTime] = nil
		end
	end
end

return flashers
