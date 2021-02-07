--[=[ Program Uninstaller ]=]--

local component = require('component')
local shell = require('shell')
local fs = require('filesystem')
local target = shell.getWorkingDirectory()..'/beamer/'

io.write('--[=[ Beamer Program Uninstaller ]=]--\nUninstalling from \''..target..'\'\nUninstall Beamer Program? [Y/n] ')
if io.read() == 'Y' then
	print('Uninstalling Beamer Program')
	
	fs.remove(target)
	fs.remove(shell.getWorkingDirectory()..'/beamerprgm.lua')
		
	print('Uninstallation Complete')
	return true
else
	print('Uninstallation Cancelled')
	return false, 'cancelled'
end