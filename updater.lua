--[=[ Program Updater ]=]--

local component = require('component')
local shell = require('shell')
local kvpreader = require('KeyValuePairFileReader')
local vinfofile = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/versioninfo')
local vinfo = vinfofile:read()
local files = vinfo.files
local info = 'data/versioninfo.kvp'

vinfofile:close()

if component.isAvailable('internet') then
	print('Checking for updates')
	local url = vinfo.updateurl[1]:match( "^%s*(.-)%s*$" )
	local target = shell.getWorkingDirectory()..'/beamer/data/versioninfo.kvp'
	local res, err = shell.execute('wget -fq '..url..info..' '..target)
	
	if res == false then
		print('Failed to download version file: '..tostring(err))
	end
	
	local vinfofile = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/versioninfo')
	local newvinfo = vinfofile:read()
	
	vinfofile:close()
	
	if newvinfo.version[1]:match( "^%s*(.-)%s*$" ) ~= vinfo.version[1]:match( "^%s*(.-)%s*$" ) then
		print('Update found: '..vinfo.version[1]:match( "^%s*(.-)%s*$" )..' >> '..newvinfo.version[1]:match( "^%s*(.-)%s*$" ))
		print('Updating '..tostring(#files)..' files')
		for _, file in ipairs(files) do
			print('Downloading file: '..file)
			local res, err = shell.execute('wget -fq '..url..file..' '..shell.getWorkingDirectory()..'/beamer/'..file)
			if res == false then
				print('Failed to download file: '..tostring(err))
				return vinfo.version[1]:match( "^%s*(.-)%s*$" )
			end
		end
		print('Update complete')
	else
		print('No new version to download')
	end
else
	print('Failed to check for updates: No Internet Card Installed')
end

os.sleep(3)

local vinf = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/versioninfo')
local version = vinf:read().version[1]:match( "^%s*(.-)%s*$" )
vinf:close()
return version
