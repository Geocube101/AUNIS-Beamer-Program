--[=[ Beamer Entry Point ]=]--

--Append path to package loader
if string.find(package.path, ';/home/beamer/%?.lua') == nil then
	package.path = package.path..';/home/beamer/?.lua'
end

require('shell').execute('cls')

--Setup
local loaded = {}
for pname, _ in pairs(package.loaded) do
	loaded[pname] = true
end

--local version = require('updater')
local version = require('updater')
local functions = require('functions')
local beamerapi = require('beamer')
local displayapi = require('display')
local winman = require('masterdisplay')
local windowapi = require('windowmanager')
local event = require('event')
local computer = require('computer')
local thread = require('thread')
local component = require('component')
local shell = require('shell')
local kvpreader = require('KeyValuePairFileReader')

local beamerbuttons = {}
local beamercontrolfile = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/beamercontrol')
local beamercontrol = beamercontrolfile:read()
local statuscodes = {'Obstructed', 'Incoming', 'NULL', 'Closed', 'No Beamer', 'Mode Mismatch', 'Ok', 'Obstructed Target', 'Not Linked', 'No Crystal', 'Beamer Disabled', 'Target Beamer Disabled', 'Both Transmitting', 'Both Receiving', 'Beamer Disabled (Logic)', 'Target Beamer Disabled (Logic)'}
local yoffset = 0
local beamerredraw = 0
local selectedbeamer
local updateselected = false
local gatestate = component.getPrimary('stargate').getGateStatus() == 'open'

local togglestate = windowapi.Button(122, 15, 30, 4, 0x000000, 0x787878, 0x787878, 'Toggle State', function(b, p)
	if selectedbeamer == nil then
		return
	elseif beamercontrol[selectedbeamer][1] == 'automatic' then
		return
	end
	
	local beamer = component.proxy(selectedbeamer)
	local state = not beamer.isActive()
	
	beamer.setActive(state)
end)
local togglecontrol = windowapi.Button(122, 9, 30, 4, 0x000000, 0x787878, 0x787878, 'Toggle Control State', function(b, p)
	if selectedbeamer == nil then
		return
	end
	
	local cstate = beamercontrol[selectedbeamer][1]
	local beamer = beamerapi.getBeamer(selectedbeamer)
	cstate = (cstate == 'automatic' and 'manual' or 'automatic')
	beamercontrol[selectedbeamer][1] = cstate
	displayapi.setForegrounds(0xeeeeee)
	displayapi.setBackgrounds(0x000000)
	displayapi.fill(83, 41, 43, 1, ' ')
	displayapi.set(84, 41, 'Control: '..cstate:gsub("^%l", string.upper))
	
	if cstate == 'manual' then
		local newfg = (beamer.state and 0xff0000 or 0x00ff00)
		togglestate.fg = newfg
		togglestate.bd = newfg
		togglestate:draw()
	else
		togglestate.fg = 0x787878
		togglestate.bd = 0x787878
		togglestate:draw()
	end
end)

--Cleanup
local function cleanup()
	for pname, _ in pairs(package.loaded) do
		if loaded[pname] ~= true then
			package.loaded[pname] = nil
		end
	end
end

--Update selected beamer stats
local function updatebeamer(addr)
	local beamer = beamerapi.getBeamer(addr)
	
	if beamer == nil then
		return
	end
	
	local percent
	if beamer.type == 'items' or beamer.type == 'none' then
		percent = '?'
	else
		percent = tostring(functions.round(beamer.current / beamer.max * 100))
	end
	
	displayapi.setForegrounds(0xeeeeee)
	displayapi.setBackgrounds(0x000000)
	displayapi.fill(83, 32, 43, 12, ' ')
	displayapi.fill(12, 42, 47, 4, ' ')
	displayapi.set(90, 33, '--[=[ Beamer Statistics ]=]--')
	displayapi.set(84, 35, 'Address: '..addr:sub(0, 30)..'...')
	displayapi.set(13, 43, 'Address: '..addr)
	displayapi.set(13, 44, 'Code: '..tostring(beamer.status_code)..' >> '..statuscodes[beamer.status_code + 1])
	displayapi.set(84, 37, 'Mode: '..(beamer.type:gsub("^%l", string.upper)))
	displayapi.set(84, 39, 'Role: '..(beamer.mode:gsub("^%l", string.upper)))
	displayapi.set(84, 41, 'Control: '..beamercontrol[addr][1]:gsub("^%l", string.upper))
	displayapi.set(84, 43, 'Buffer: '..(beamer.type ~= 'items' and beamer.type ~= 'none' and (tostring(beamer.current)..' / '..tostring(beamer.max)) or (beamer.type == 'none' and 'NULL' or 'ItemsList'))..' ('..percent..'%)')
			
	if beamer.type == 'power' then
		displayapi.setBackgrounds(0xff5555)
	elseif beamer.type == 'fluid' then
		displayapi.setBackgrounds(0x5555ff)
	elseif beamer.type == 'items' then
		displayapi.setBackgrounds(0x55ff55)
	else
		displayapi.setBackgrounds(0x555555)
	end
	
	displayapi.setForegrounds(0x666666)
	displayapi.fill(93, 11, 14, 7, ' ')
	displayapi.fill(93, 11, 14, 1, '▀')
	displayapi.fill(93, 17, 14, 1, '▄')
	displayapi.fill(93, 11, 1, 7, '█')
	displayapi.fill(106, 11, 1, 7, '█')
	
	togglecontrol.fg = 0x332480
	togglecontrol.bd = 0x332480
	togglecontrol:draw()
	
	if gatestate == true then
		if beamercontrol[addr][1] == 'manual' then
			local newfg = (beamer.state and 0xff0000 or 0x00ff00)
			togglestate.fg = newfg
			togglestate.bd = newfg
			togglestate:draw()
		end
	else
		togglestate.fg = 0x787878
		togglestate.bd = 0x787878
		togglestate:draw()
	end
end

--Clear selected beamer
local function clearselectedbeamer()
	displayapi.setForegrounds(0xeeeeee)
	displayapi.setBackgrounds(0x000000)
	displayapi.fill(83, 32, 43, 12, ' ')
	displayapi.fill(12, 42, 47, 4, ' ')
	displayapi.set(90, 33, '--[=[ Beamer Statistics ]=]--')
	displayapi.set(84, 35, 'Address:')
	displayapi.set(84, 37, 'Mode:')
	displayapi.set(84, 39, 'Role:')
	displayapi.set(84, 41, 'Control:')
	displayapi.set(84, 43, 'Buffer:')
	displayapi.set(22, 41, '--[=[ Beamer Status ]=]--')
	displayapi.set(13, 43, 'Address:')
	displayapi.set(13, 44, 'Code:')
	togglecontrol.fg = 0x787878
	togglecontrol.bd = 0x787878
	togglestate.fg = 0x787878
	togglestate.bd = 0x787878
	togglecontrol:draw()
	togglestate:draw()
	selectedbeamer = nil
end

--Show buttons
local function updatebeamerbuttons(beamers)
	local y = 7 + yoffset
	local h = 4
	local draw = beamerredraw + 1
	beamerredraw = beamerredraw + 1
	displayapi.setBackgrounds(0x000000)
	displayapi.fill(11, 6, 48, 34, ' ')
	beamerbuttons = {}
	for addr, beamer in pairs(beamers) do
		if draw ~= beamerredraw then
			break
		end
		
		local bd = (beamer.state and 0x00ff00 or 0xff0000)
		local fd = (addr == selectedbeamer and 0xeeeeee or bd)
		local button = windowapi.Button(13, y, 44, h, 0x000000, fd, bd, addr, function()
			selectedbeamer = addr
		end)
		button:draw(5, 40)
		beamerbuttons[#beamerbuttons + 1] = button
		y = y + (h + 3)
	end
	beamerredraw = beamerredraw - 1
end

local function setupbeamers(beamers)
	updatebeamerbuttons(beamers)
	for addr, _ in pairs(beamers) do
		if beamercontrol[addr] == nil then
			beamercontrol[addr] = {'automatic'}
		end
	end
	for addr, _ in pairs(beamercontrol) do
		if beamers[addr] == nil then
			beamercontrol[addr] = nil
		end
	end
end

--Mainloop
local function mainloop()
	while displayapi.getState() == true do
		--Show memory
		local total = computer.totalMemory()
		local used = total - computer.freeMemory()
		local percent = tostring(functions.round(used / total * 100))
		displayapi.setForegrounds(0xeeeeee)
		displayapi.setBackgrounds(0x000000)
		displayapi.set(100, 3, 'Computer Memory: '..tostring(used)..' / '..tostring(total)..' ('..percent..'%)')
		
		pcall(function()
			--Update selected
			if selectedbeamer ~= nil and updateselected == true then
				updatebeamer(selectedbeamer)
				updatebeamerbuttons(beamerapi.getBeamers())
				updateselected = false
			end
		end)
		
		os.sleep(0.00001)
	end
end

--Button handler
local function onclick(eid, addr, x, y, b, p)
	function click()
		togglecontrol:click(x, y, b, p)
		togglestate:click(x, y, b, p)
		local clicked = false
		for _, button in ipairs(beamerbuttons) do
			if x > 10 and x < 60 and y > 5 and y < 46 then
				if button:click(x, y, b, p) == true then
					selectedbeamer = button.text
					updateselected = true
					button.fg = 0xeeeeee
					button:draw(5, 40)
					clicked = true
				elseif button.fg == 0xeeeeee then
					local fg = (beamerapi.getBeamer(button.text).state and 0x00ff00 or 0xff0000)
					button.fg = fg
					button:draw(5, 40)
				end
			end
		end
		if clicked == false and x > 10 and x < 60 and y > 5 and y < 46 then
			clearselectedbeamer()
		end
	end
	
	thread.create(click)
end

--Scroll handler
local function onscroll(eid, addr, x, y, dir, p)
	function scroll()
		if yoffset == 0 and dir == 1 then
			return
		else
			if x > 10 and x < 60 and y > 5 and y < 46 then
				yoffset = yoffset + dir
				thread.create(function() updatebeamerbuttons(beamerapi.getBeamers()) end)
			end
		end
	end
	
	thread.create(scroll)
end

--Beam controller
local function beamcontrolmaster(state)
	for addr, crtl in pairs(beamercontrol) do
		component.proxy(addr).setActive(false)
	end

	while gatestate == true and beamerapi.getState() == true do
		for addr, crtl in pairs(beamercontrol) do
			local control = crtl[1]
			local beamer = component.proxy(addr)

			if state == true and beamer.getBeamerRole() ~= 'transmit' then
				beamer.setBeamerRole('transmit')
			elseif state == false and beamer.getBeamerRole() ~= 'receive' then
				beamer.setBeamerRole('receive')
			end
			
			if control == 'automatic' and beamer.isActive() == false then
				beamer.setActive(true)
			end
		end
		os.sleep(0.001)
	end
end

--Stargate handler
local function onstargateopen(eid, addr, caller, initiator)
	gatestate = true
	thread.create(function() beamcontrolmaster(initiator) end)
end
local function onstargateclose(eid, addr, caller, reason)
	gatestate = false
	for addr, _ in pairs(beamerapi.getBeamers()) do
		local beamer = component.proxy(addr)
		beamer.setActive(false)
		beamer.setBeamerRole('disabled')
	end
end

--Event binder
local devm = displayapi.begin()
local bevm = beamerapi.begin(setupbeamers)

bevm.on('kill', function() displayapi.kill() end)
bevm.on('beamer_add', function() updatebeamerbuttons(beamerapi.getBeamers()) end)
bevm.on('beamer_delete', function(addr) updatebeamerbuttons(beamerapi.getBeamers()) if addr == selectedbeamer then clearselectedbeamer() end end)
bevm.on('beamer_update', function(addr) if addr == selectedbeamer then updateselected = true end updatebeamerbuttons(beamerapi.getBeamers()) end)
devm.on('kill', cleanup)

event.listen('touch', onclick)
event.listen('scroll', onscroll)
event.listen('stargate_wormhole_stabilized', onstargateopen)
event.listen('stargate_close', onstargateclose)

thread.create(mainloop)
togglecontrol:draw()
togglestate:draw()
displayapi.setForegrounds(0xeeeeee)
displayapi.setBackgrounds(0x000000)
displayapi.set(5, 48, 'Beamer Control Program (Version '..version..') by Geocube101')

if gatestate == true then
	local state, sender = component.getPrimary('stargate').getGateStatus()
	thread.create(function() beamcontrolmaster(sender) end)
end

--Wait loop
while displayapi.getState() == true and beamerapi.getState() == true do
	if event.pull(0.01, 'interrupted') ~= nil then
		break
	end
end

--Cleanup
event.ignore('touch', onclick)
event.ignore('scroll', onscroll)
event.ignore('stargate_wormhole_stabilized', onstargateopen)
event.ignore('stargate_close', onstargateclose)
beamercontrolfile:write(beamercontrol)
beamercontrolfile:close()
beamerapi.kill()
