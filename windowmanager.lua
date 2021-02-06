--[=[ Window Manager ]=]--

local functions = require('functions')
local displayapi = require('display')
local unicode = require('unicode')
local thread = require('thread')
local event = require('event')
local buttons = {}

displayapi.begin()

local function Button(x, y, w, h, bg, fg, bd, text, callback)
	w = w or 25
	h = h or 10
	bg = bg or 0x000000
	fg = fg or 0xffffff
	bd = bd or 0xffffff
	text = text or 'Button'
	callback = callback or function() end
	
	local button = {['x']=x, ['y']=y, ['w']=w, ['h']=h, ['bg']=bg, ['fg']=fg, ['bd']=bd, ['text']=text, ['callback']=callback, ['state']=true}
	
	function button:draw(miny, maxy)
		miny = miny or self.y - 1
		maxy = maxy or self.y + self.h + 1
		displayapi.setBackgrounds(self.bg)
		displayapi.setForegrounds(self.bd)
		
		if self.y < maxy and self.y > miny then
			displayapi.fill(self.x, self.y, self.w, 1, '▀')
			displayapi.set(self.x, self.y, '█')
			displayapi.set(self.x + self.w, self.y, '█')
		end
		if self.y + self.h > miny and self.y + self.h < maxy then
			displayapi.fill(self.x, self.y + self.h, self.w, 1, '▄')
			displayapi.set(self.x, self.y + self.h, '█')
			displayapi.set(self.x + self.w, self.y + self.h, '█')
		end
		
		for y=self.y + 1, self.y + self.h - 1 do
			if y < maxy and y > miny then
				displayapi.set(self.x, y, '█')
				displayapi.set(self.x + self.w, y, '█')
			end
		end
		
		local tx = functions.round((self.x + self.w / 2) - (unicode.len(text) / 2))
		local ty = functions.round(self.y + self.h / 2)
		if ty < maxy and ty > miny then
			displayapi.setForegrounds(self.fg)
			displayapi.set(tx, ty, self.text)
		end
	end
	function button:click(x, y, bnum, player)
		if x > self.x and x < self.x + self.w and y > self.y and y < self.y + self.h then
			bnum = bnum or 1
			thread.create(function() self.callback(bnum, player) end)
			return true
		else
			return false
		end
	end
	
	return button
end

return {
	['Button']=Button
}