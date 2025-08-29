--!strict
--!optimize 2
--!native
-- Redon Tech Emergency Vehicle Creator, MIT License

local types = require(script.Parent.Parent.types)

type flashers = {
	runningPatterns: { types.pattern },
	flash: (vehicle: Instance, functionId: number, lightName: string, color: types.elsColor) -> (),
	processPattern: (pattern: types.pattern) -> (),
}
local flashers = {
	runningPatterns = {},
} :: flashers

function flashers.processPattern(pattern: types.pattern)
	for _, flasherSection in pairs(pattern.flashers) do
		local nextRow = math.floor(((pattern.patternTime / flasherSection.waitTime) % flasherSection.rowCount) + 1)
		if nextRow ~= flasherSection.currentRow then
			for _, column in pairs(flasherSection.columns) do
				flashers.flash(pattern.vehicle, pattern.functionId, column.lightName, column.rows[nextRow])
			end
			flasherSection.currentRow = nextRow
		end
	end
end

return flashers
