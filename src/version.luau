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
	isOutdated: (self: version) -> boolean,
}
local version = {
	currentVersion = "",
	latestVersion = nil,
} :: version

function version.parseVersion(_: version, versionString: string): versionParsed
	local parsedData = { string.match(versionString, "(%d+)%.(%d+)%.(%d+)%-?([%w%.]*)%+?(.*)$") }
	log.debug("Parsed Version", versionString, parsedData)
	return {
		major = tonumber(parsedData[1]),
		minor = tonumber(parsedData[2]),
		patch = tonumber(parsedData[3]),
		preRelease = parsedData[4],
		build = parsedData[5],
	}
end

function version.checkVersion(self: version)
	local latestVersion = HttpService:RequestAsync({
		Url = "https://api.github.com/repos/Redon-Tech/Emergency-Vehicle-Creator/releases/latest",
		Method = "GET",
	})

	if latestVersion.Success == true then
		local latestVersionData = HttpService:JSONDecode(latestVersion.Body)
		local ver = latestVersionData.tag_name
		if ver ~= nil and typeof(ver) == "string" then
			self.latestVersion = ver
			self.latestVer = self:parseVersion(ver)
		end
	else
		log.warn(
			"Version Check",
			"Failed to check for the latest version\nPlease manually check the latest version or fix permissions"
		)
	end
end

function version.isOutdated(self: version)
	if self.latestVer == nil or self.latestVersion == nil then
		log.debug("Skipping version check, no latest version found")
		return
	end

	if
		self.currentVer.major < self.latestVer.major
		or (self.currentVer.major == self.latestVer.major and self.currentVer.minor < self.latestVer.minor)
		or (
			self.currentVer.major == self.latestVer.major
			and self.currentVer.minor == self.latestVer.minor
			and self.currentVer.patch < self.latestVer.patch
		)
	then
		log.warn(
			"Version Check:",
			("You are using an outdated version of the plugin\n                    Current version: %s\n                    ↳  Latest version: %s"):format(
				self.currentVersion,
				self.latestVersion
			)
		)
		return true
	end

	return false
end

return version
