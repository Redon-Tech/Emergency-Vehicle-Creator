-- Redon Tech Emergency Vehicle Creator, MIT License
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

--- Gets the location where a log was called from.
--- This is a workaround for the log showing this file as the source of the log
function log.getTraceback(): string
	local s, l = debug.info(3, "sl")
	return `{s}:{l}`
end

function log.info(...)
	if log.verbosity >= 1 then
		print(log.format.info, ...)
		if log.verbosity >= 4 then
			print(log.getTraceback())
		end
	end
end

function log.warn(...)
	if log.verbosity >= 2 then
		warn(log.format.warn, ...)
		if log.verbosity >= 4 then
			print(log.getTraceback())
		end
	end
end

--- Logs an error message and halts execution.
--- This function should be used for critical errors that require immediate attention.
function log.error(...)
	-- Errors should always be sent, if this is called it expects execution to halt
	error(`{log.format.error}{...}`, 2)
end

function log.debug(...)
	if log.verbosity >= 4 then
		print(log.format.debug, ...)
		if log.verbosity >= 4 then
			print(log.getTraceback())
		end
	end
end

return log
