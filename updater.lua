--[=[ Program Updater ]=]--

local component = require('component')
local shell = require('shell')
local kvpreader = require('KeyValuePairFileReader')
local vinfofile = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/versioninfo')
local vinfo = vinfofile:read()
local files = vinfo.files

vinfofile:close()

if component.isAvailable('internet') then
	local url = vinfo.updateurl[1]
	shell.execute('wget -fq '..url..'data/versioninfo.kvp '..shell.getWorkingDirectory()..'/beamer/data/versioninfo.kvp')
	
	local vinfofile = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/versioninfo')
	local newvinfo = vinfofile:read()
	
	vinfofile:close()
	
	if newvinfo.version[1] ~= vinfo.version[1] then
		print('Update found: '..vinfo.version[1]..' >> '..newvinfo.version[1])
		for _, file in ipairs(files) do
			shell.execute('wget -fq '..url..file..' '..shell.getWorkingDirectory()..'/beamer/'..file)
		end
		print('Update complete')
	end
end

local vinf = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/versioninfo')
local version = vinf:read().version[1]
vinf:close()
return version