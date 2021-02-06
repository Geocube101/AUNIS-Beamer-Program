function copy(o, seen)
	seen = seen or {}
	if o == nil then return nil end
	if seen[o] then return seen[o] end

	local no
	if type(o) == 'table' then
		no = {}
		seen[o] = no

		for k, v in next, o, nil do
			no[copy(k, seen)] = copy(v, seen)
		end
		setmetatable(no, copy(getmetatable(o), seen))
	else -- number, string, boolean, etc
		no = o
	end
	return no
end
function deepcopy(tble)
	if type(tble) ~= 'table' then
		return tble
	end

	local master = {}
	
	for k, v in pairs(tble) do
		master[k] = deepcopy(v)
	end
	
	return master;
end
function getSubTable(array, start, stop)
	local out = {}
	stop = stop or #array
	local diff = 1 - start
	
	for i=start, stop do
		out[i + diff] = array[i]
	end
	return out
end
function has(t, el)
	if type(t) ~= 'table' then return nil end
	for k, v in ipairs(t) do
		if v == el then
			return true
		end
	end
	return false
end
function tprint(t, m, l)
	local indent = l or 0
	local top = m or indent + 1
	local str = ''

	for k, v in pairs(copy(t)) do
		for a=1,indent do
			str = str..'  '
		end
		
		local val = v
		
		if type(v) == 'table' then
			if indent >= top then
				val = v
			else
				val = '\n'..tprint(v, m, indent + 1)
			end
		end
		
		str = str..'['..tostring(k)..']='..tostring(val)..'\n'
	end
	
	if indent == 0 then
		print(str)
	else
		return str
	end
end
function teq(t1, t2)
	if type(t1) ~= 'table' then return nil end
	if type(t2) ~= 'table' then return false end

	for _, v1 in ipairs(t1) do
		for _, v2 in ipairs(t2) do
			local eq
			if type(v1) == 'table' then
				eq = teq(v1, v2)
			else
				eq = v1 == v2
			end
			if eq == false then
				return false
			end
		end
	end
	return true
end
function round(x)
	return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end
function split(str, delim, scount)
	local strings = {}
	local index = 0
	local token = ''
	
	for i=1,#str do
		local chr = str:sub(i, i)
		local maxed
		
		if (scount ~= nil and index < scount) or scount == nil then
			maxed = false
		elseif scount ~= nil and index >= scount then
			maxed = true
		end
		
		if chr == delim and maxed == false then
			index = index + 1
			strings[index] = token
			token = ''
		else
			token = token..chr
		end
	end
	
	strings[index + 1] = token
	
	return strings
end
function invert(t)
	local inverted = {}
	
	for k, v in pairs(t) do
		if tonumber(v) ~= nil then
			v = tonumber(v)
		end
		v = tostring(v)
		
		if inverted[v] == nil then
			inverted[v] = k
		elseif type(inverted[v]) == 'table' then
			inverted[v][#inverted[v] + 1] = k
		else
			inverted[v] = {inverted[v], k}
		end
	end
	
	return inverted
end
function trim(s)
	return s:match( "^%s*(.-)%s*$" )
end
function multiply(str, count)
	if type(str) ~= 'string' then
		error('Expected string, got '..type(str))
	else
		local output = ''
		for _=1,count do
			output = output..str
		end
		return output
	end
end

return {
	['copy']=copy,
	['deepcopy']=deepcopy,
	['getSubTable']=getSubTable,
	['has']=has,
	['tprint']=tprint,
	['teq']=teq,
	['round']=round,
	['split']=split,
	['invert']=invert,
	['trim']=trim,
	['multiply']=multiply
}