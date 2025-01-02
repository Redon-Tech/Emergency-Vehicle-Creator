-- Redon Tech Emnergency Vehicle Creator, MIT License
local log = {
	level = {
		info = 1,
		warn = 2,
		error = 3,
		-- 4 and above is developer only
		debug = 4,
	},
	format = {
		info = "[EVC INFO]:",
		warn = "[EVC WARNING]:",
		error = "[EVC ERROR]:",
		debug = "[EVC DEBUG]:",
	},
	verbosity = 1,
}

function log.info(...)
	if log.verbosity >= 1 then
		print(log.format.info, debug.info(2, "sl"), "\n               ", ...)
	end
end

function log.warn(...)
	if log.verbosity >= 2 then
		warn(log.format.warn, debug.info(2, "sl"), "\n               ", ...)
	end
end

function log.error(...)
	-- Errors should always be sent, if this is called it expects execution to halt
	error(`{log.format.error}{...}`, 2)
end

function log.debug(...)
	if log.verbosity >= 4 then
		print(log.format.debug, debug.info(2, "sl"), "\n               ", ...)
	end
end

return log
