-- Redon Tech Emergency Vehicle Creator, MIT License
local HttpService = game:GetService("HttpService")
local log = require(script.Parent.log)

type versionParsed = {
	major: number,
	minor: number,
	patch: number,
	preRelease: string?,
	build: string?,
}
type version = {
	currentVersion: string,
	currentVer: versionParsed,
	latestVersion: string?,
	latestVer: versionParsed?,
	parseVersion: (self: version, versionString: string) -> versionParsed,
	checkVersion: (self: version) -> (),
	isOutdated: (self: version) -> (boolean, boolean?),
}
local version = {
	currentVersion = "",
	latestVersion = nil,
} :: version

--- Parses a version string into a table with major, minor, patch, pre-release, and build components.
function version.parseVersion(_: version, versionString: string): versionParsed
	local parsedData = { string.match(versionString, "(%d+)%.(%d+)%.(%d+)%-?([%w%.]*)%+?(.*)$") }
	log.debug("Parsed Version", versionString, parsedData)
	return {
		major = tonumber(parsedData[1]) or 0,
		minor = tonumber(parsedData[2]) or 0,
		patch = tonumber(parsedData[3]) or 0,
		preRelease = if parsedData[4] == "" then nil else parsedData[4],
		build = if parsedData[5] == "" then nil else parsedData[5],
	}
end

--- Initializes the version module with the current plugin version.
function version.checkVersion(self: version)
	local success, latestVersion = pcall(function()
		return HttpService:RequestAsync({
			Url = "https://api.github.com/repos/Redon-Tech/Emergency-Vehicle-Creator/releases/latest",
			Method = "GET",
		})
	end)

	if success == true and latestVersion.Success == true then
		local latestVersionData = HttpService:JSONDecode(latestVersion.Body)
		local ver = latestVersionData.tag_name
		if ver ~= nil and typeof(ver) == "string" then
			self.latestVersion = ver
			self.latestVer = self:parseVersion(ver)
		end
	else
		log.warn(
			"Version Check",
			"Failed to check for the latest version\n                    Please manually check the latest version or fix permissions",
			`\n                    {latestVersion}`
		)
	end
end

--- Checks if the current version is outdated compared to the latest version.
--- Returns true if the current version is older than the latest version, false otherwise.
function version.isOutdated(self: version)
	if self.latestVer == nil or self.latestVersion == nil then
		log.warn(
			"Version Check:",
			("The plugin was unable to check for the latest version of the plugin.\n                    Current version: %s\n                    ↳  Latest version: Unknown. Please ensure HTTP permissions are enabled on the plugin"):format(
				self.currentVersion
			)
		)
		return false, true
	end

	if
		self.currentVer.major < self.latestVer.major
		or (self.currentVer.major == self.latestVer.major and self.currentVer.minor < self.latestVer.minor)
		or (self.currentVer.major == self.latestVer.major and self.currentVer.minor == self.latestVer.minor and self.currentVer.patch < self.latestVer.patch)
		or (self.currentVer.preRelease ~= self.latestVer.preRelease)
	then
		log.warn(
			"Version Check:",
			("You are using an outdated version of the plugin\n                    Current version: %s\n                    ↳  Latest version: %s"):format(
				self.currentVersion,
				self.latestVersion
			)
		)
		return true, false
	end

	return false, false
end

return version
