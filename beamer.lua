--[=[ Beamer API ]=]--

--Setup
local component = require('component')
local thread = require('thread')
local event = require('event')
local beamers = {}
local events = {}
local state = false

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
	local bstate = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['status']=beamer.getBeamerStatus(), ['status_code']=status_codes[beamer.getBeamerStatus()]}
	local oldstate = beamers[addr]
	local changed = false
	
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

--Add beamer to list
local function addbeamer(eid, addr, ct)
	if ct == 'beamer' then
		local beamer = component.proxy(addr)
		beamer.setActive(false)
		beamers[addr] = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole(), ['status']=beamer.getBeamerStatus(), ['status_code']=status_codes[beamer.getBeamerStatus()]}
		call('beamer_add', addr)
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
		os.sleep(0.001)
	end
	
	event.ignore('component_added', addbeamer)
	event.ignore('component_removed', delbeamer)
	call('kill')
end

--Start beamer manager api
local function begin(callback)
	if state == false then
		callback = callback or function() end

		for addr, ct in component.list() do
			if ct == 'beamer' then
				local beamer = component.proxy(addr)
				beamer.setActive(false)
				beamers[addr] = {['state']=beamer.isActive(), ['type']=beamer.getBeamerMode(), ['current']=beamer.getBufferStored(), ['max']=beamer.getBufferCapacity(), ['mode']=beamer.getBeamerRole()}
			end
		end
		
		setmetatable(beamers, {__len=function(t) local count = 0 for _, _ in pairs(t) do count = count + 1 end return count end})
		
		callback(beamers)
		state = true
		thread.create(mainloop)
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
	['getBeamer']=function(address) return beamers[address] end
}