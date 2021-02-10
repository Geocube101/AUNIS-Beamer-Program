--[=[ Beamer API ]=]--

--Setup
local component = require('component')
local thread = require('thread')
local event = require('event')
local shell = require('shell')
local functions = require('functions')
local kvpreader = require('KeyValuePairFileReader')
local beamers = {}
local unassociated = {}
local events = {}
local state = false
local configfile = kvpreader:open(shell.getWorkingDirectory()..'/beamer/data/config')
local config = configfile:read()
local force_control = functions.trim(config.force_control[1]) == 'true'
local bsu_delay = tonumber(config.beamer_status_update_delay[1])

configfile:close()

--Event callback holder
local eventmanager = {
	['on']=function(eid, callback) events[eid] = callback end,
	['bind']=function(eid, callback) events[eid] = callback end,
	['ubind']=function(eid) if events[eid] ~= nil then events[eid] = nil end end
}

local status_codes = {
	['obstructed']=0,
	['incoming']=1,
	['closed']=3,
	['no_beamer']=4,
	['mode_mismatch']=5,
	['ok']=6,
	['obstructed_target']=7,
	['not_linked']=8,
	['no_crystal']=9,
	['beamer_disabled']=10,
	['beamer_disabled_target']=11,
	['two_transmitters']=12,
	['two_receivers']=13,
	['beamer_disabled_by_logic']=14,
	['beamer_disabled_by_logic_target']=15
}

--Event callback caller
local function call(eid, ...)
	if events[eid] ~= nil then
		local args = {...}
		local function exec()
			events[eid](table.unpack(args))
		end
		thread.create(exec)
	end
end

--Update connected beamer stats
local function updatebeamer(addr)
	local beamer = component.proxy(addr)
	local bstate = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['status']=beamer.getBeamerStatus(), ['status_code']=status_codes[beamer.getBeamerStatus()], ['amount_transferred']=beamers[addr].amount_transferred, ['material']=beamers[addr].material, ['transfer_additional']=0}
	local oldstate = beamers[addr]
	local changed = false
	
	if beamer.getBeamerRedstoneMode() ~= 'ignored' and force_control == false then
		unassociated[addr] = beamer.getBeamerRedstoneMode()
		beamers[addr] = nil
		call('beamer_delete', addr)
		return
	end
	
	if oldstate.state ~= bstate.state then
		call('state_change', addr, beamer, bstate.state)
		changed = true
	end
	if oldstate.type ~= bstate.type then
		call('type_change', addr, beamer, bstate.type)
		changed = true
	end
	if oldstate.current ~= bstate.current then
		call('buffer_change', addr, beamer, bstate.current)
		changed = true
	end
	if oldstate.max ~= bstate.max then
		call('max_buffer_change', addr, beamer, bstate.max)
		changed = true
	end
	if oldstate.mode ~= bstate.mode then
		call('mode_change', addr, beamer, bstate.mode)
		changed = true
	end
	if oldstate.status ~= bstate.status then
		call('status_change', addr, beamer, bstate.status, bstate.status_code)
		changed = true
	end
	
	beamers[addr] = bstate
	if changed == true then
		call('beamer_update', addr, beamer, bstate)
	end
end

--Update beamer transfer
local function onbeamertransfer(eid, addr, _, t)
	for mat, amount in pairs(t) do
		beamers[addr].material = mat
		beamers[addr].amount_transferred = beamers[addr].amount_transferred + amount
		beamers[addr].transfer_additional = amount
		call('transfer_change', addr, mat, amount)
		break
	end
end

--Check unassociated beamers rs control
local function checkunassociatedbeamers()
	for addr, rsc in pairs(unassociated) do
		local beamer = component.proxy(addr)
		if beamer.getBeamerRedstoneMode() == 'ignored' then
			unassociated[addr] = nil
			beamers[addr] = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['status']=beamer.getBeamerStatus(), ['status_code']=status_codes[beamer.getBeamerStatus()], ['amount_transferred']=0, ['material']=nil, ['transfer_additional']=0}
			call('beamer_add', addr)
		end
	end
end

--Add beamer to list
local function addbeamer(eid, addr, ct)
	if ct == 'beamer' then
		local beamer = component.proxy(addr)
		if force_control == true then
			beamer.setActive(false)
			beamer.setBeamerRedstoneMode('ignored')
			beamers[addr] = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['status']=beamer.getBeamerStatus(), ['status_code']=status_codes[beamer.getBeamerStatus()], ['amount_transferred']=0, ['material']=nil, ['transfer_additional']=0}
			call('beamer_add', addr)
		elseif beamer.getBeamerRedstoneMode() == 'ignored' then
			beamer.setActive(false)
			beamers[addr] = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['status']=beamer.getBeamerStatus(), ['status_code']=status_codes[beamer.getBeamerStatus()], ['amount_transferred']=0, ['material']=nil, ['transfer_additional']=0}
			call('beamer_add', addr)
		else
			unassociated[addr] = beamer.getBeamerRedstoneMode()
		end
	end
end

--Remove beamer from list
local function delbeamer(eid, addr, ct)
	if ct == 'beamer' and beamers[addr] ~= nil then
		beamers[addr] = nil
		call('beamer_delete', addr)
	end
end

--Master loop
local function mainloop()
	event.listen('component_added', addbeamer)
	event.listen('component_removed', delbeamer)
	
	while state == true do
		for addr, _ in pairs(beamers) do
			updatebeamer(addr)
		end
		if force_control == false then
			checkunassociatedbeamers()
		end
		os.sleep(bsu_delay)
	end
	
	event.ignore('component_added', addbeamer)
	event.ignore('component_removed', delbeamer)
	event.ignore('beamer_transfers', onbeamertransfer)
	call('kill')
end

--Start beamer manager api
local function begin(callback)
	if state == false then
		callback = callback or function() end

		for addr, ct in component.list() do
			if ct == 'beamer' then
				local beamer = component.proxy(addr)
				if force_control == true then
					beamer.setActive(false)
					beamer.setBeamerRedstoneMode('ignored')
					beamers[addr] = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['amount_transferred']=0, ['material']=nil}
				elseif beamer.getBeamerRedstoneMode() == 'ignored' then
					beamer.setActive(false)
					beamers[addr] = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['amount_transferred']=0, ['material']=nil}
				else
					unassociated[addr] = beamer.getBeamerRedstoneMode()
				end
			end
		end
		
		setmetatable(beamers, {__len=function(t) local count = 0 for _, _ in pairs(t) do count = count + 1 end return count end})
		
		callback(beamers)
		state = true
		thread.create(mainloop)
		event.listen('beamer_transfers', onbeamertransfer)
	end
	
	return eventmanager
end

--Return functions
return {
	['begin']=begin,
	['getState']=function() return state end,
	['kill']=function() state = false end,
	['getBeamerAddresses']=function() local addresses = {} for addr, _ in pairs(beamers) do addresses[#addresses+1] = addr end return addresses end,
	['getBeamers']=function() return beamers end,
	['getBeamer']=function(address) return beamers[address] end,
	['setBeamerAmountTransferred']=function(address, amount) if beamers[address] ~= nil and amount >= 0 then beamers[address].amount_transferred = amount end end
}