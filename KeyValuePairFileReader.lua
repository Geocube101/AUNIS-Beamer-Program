--[=[ KeyValuePair File Reader ]=]--

local functions = require('functions')

local KVPFile = {['path']=nil, ['stream']=nil, ['pairs']={}}

function KVPFile:open(path, createfile)
	local kvp = functions.copy(KVPFile)
	createfile = createfile or true
	
	path = path or self.path
	path = path..'.kvp'
	
	kvp.stream = io.open(path, 'r')
	kvp.path = path
	
	if kvp.stream == nil then
		if createfile == false then
			error('[FileNotFoundError]: Failed to locate file: \''..path..'\'')
		else
			local cstream = io.open(path, 'w')
			cstream:write('')
			cstream:close()
			kvp.stream = io.open(path, 'r')
		end
	end
	
	return kvp
end
function KVPFile:read()
	local data = self.stream:read('*all')
	local ptable = {}
	
	if data ~= nil then
		local lines = functions.split(data, '\n')
		for _, line in ipairs(lines) do
			local pair = functions.split(line, '=', 1)
			if type(pair[2]) == 'string' then
				ptable[pair[1]] = functions.split(pair[2], ';')
			end
		end
	end
	
	self.pairs = functions.copy(ptable)
	
	return ptable
end
function KVPFile:close(save)
	save = save or true
	self.stream:close()
	self.stream = nil

	if save == true then
		local fstring = ''
	
		local function writeable(val)
			if type(val) ~= 'table' then
				return tostring(val)
			end
			local str = ''
			for k, v in ipairs(val) do
				str = str..writeable(v)..';'
			end
			return str:sub(1, #str-1)
		end
		
		for key, value in pairs(self.pairs) do
			fstring = fstring..tostring(key)..'='..writeable(value)..'\n'
		end
		
		local stream = io.open(self.path, 'w')
		stream:write(fstring)
		stream:close()
	end
end
function KVPFile:write(pair_table)
	if type(pair_table) == 'table' then
		self.pairs = pair_table
	end
end

return KVPFile