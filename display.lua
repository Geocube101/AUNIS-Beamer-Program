--[=[ Display API ]=]--

--Setup
local component = require('component')
local thread = require('thread')
local term = require('term')
local functions = require('functions')
local gpus = {}
local screens = {}
local monitors = {}
local events = {}
local state = false

--Event callback holder
local eventmanager = {
	['on']=function(eid, callback) events[eid] = callback end,
	['bind']=function(eid, callback) events[eid] = callback end,
	['ubind']=function(eid) if events[eid] ~= nil then events[eid] = nil end end
}

--Print to all screens
local function lprint(...)
	local data = {...}
	if state == false then
		print(table.unpack(data))
	else
		local str = ''
		for _, obj in ipairs(data) do
			str = str..' '..tostring(obj)
		end
		for _, mon in ipairs(monitors) do
			mon.gpu.set(1, mon.line, str)
			mon.line = mon.line + 1
		end
	end
end

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

--Master loop
local function mainloop()
	while state == true do
		os.sleep(0)
	end
	
	for _, mon in ipairs(monitors) do
		local mw, mh = mon.gpu.getResolution()
		mon.gpu.setBackground(mon.initial[2])
		mon.gpu.setForeground(mon.initial[1])
		mon.gpu.fill(1, 1, mw, mh, ' ')
		mon.line = 1
	end
	
	call('kill')
end

--Start display manager api
local function begin(callback)
	if state == false then
		callback = callback or function() end
		
		for addr, ct in component.list() do
			if ct == 'gpu' and component.proxy(addr).maxDepth() == 8 then
				gpus[addr] = component.proxy(addr)
			elseif ct == 'screen' and component.proxy(addr).isOn() == true then
				screens[#screens + 1] = addr
			end
		end
		setmetatable(gpus, {__len=function(t) local count = 0 for _, _ in pairs(t) do count = count + 1 end return count end})
		
		local mcount
		if #gpus > #screens then
			mcount = #screens
		else
			mcount = #gpus
		end
		
		for addr, gpu in pairs(gpus) do
			if #monitors < mcount then
				monitors[#monitors + 1] = {['gpu']=gpu, ['screen']=component.proxy(screens[#monitors + 1]), ['initial']={gpu.getForeground(), gpu.getBackground()}, ['line']=1}
				gpu.bind(screens[#monitors])
			end
		end
		
		state = true
		thread.create(mainloop)
		callback(monitors)
	end
	
	return eventmanager
end

--Return functions
return {
	['begin']=begin,
	['kill']=function() state = false end,
	
	['setForegrounds']=function(color) for _, gpu in pairs(gpus) do gpu.setForeground(color) end end,
	['setBackgrounds']=function(color) for _, gpu in pairs(gpus) do gpu.setBackground(color) end end,
	
	['getForegrounds']=function() local colors = {} for addr, gpu in pairs(gpus) do colors[addr] = gpu.getForeground() end return colors end,
	['getBackgrounds']=function() local colors = {} for addr, gpu in pairs(gpus) do colors[addr] = gpu.getBackground() end return colors end,
	
	['setForeground']=function(address, color) if gpus[address] ~= nil then gpus[address].setForeground(color) end return gpus[address] ~= nil end,
	['setBackground']=function(address, color) if gpus[address] ~= nil then gpus[address].setBackground(color) end return gpus[address] ~= nil end,
	
	['getForeground']=function(address, color) if gpus[address] ~= nil then return gpus[address].getForeground() end end,
	['getBackground']=function(address, color) if gpus[address] ~= nil then return gpus[address].getBackground() end end,
	
	['getGraphicCards']=function() return gpus end,
	['getGraphicCard']=function(address) return gpus[address] end,
	['getScreens']=function() local s = {} for _, addr in ipairs(screens) do s[addr] = component.proxy(addr) end return s end,
	['getScreen']=function(address) local s = {} for _, addr in ipairs(screens) do s[addr] = component.proxy(addr) end return s[address] end,
	
	['fill']=function(x, y, w, h, chr) for _, mon in ipairs(monitors) do mon.gpu.fill(x, y, w, h, chr) end end,
	['set']=function(x, y, str) for _, mon in ipairs(monitors) do mon.gpu.set(x, y, str) end end,
	['clear']=function(color) for _, mon in ipairs(monitors) do color = color or mon.initial[2] mon.gpu.setBackground(color) local mw, mh = mon.gpu.getResolution() mon.gpu.fill(1, 1, mw, mh, ' ') mon.initial[2] = color end end,
	
	['print']=lprint,
	['getState']=function() return state end
}
