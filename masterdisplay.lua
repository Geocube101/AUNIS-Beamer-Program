--[=[ Master Window Renderer ]=]--

local disp = require('display')
disp.begin()
disp.clear(0x000000)

--Window border
disp.setForegrounds(0x332480)
disp.fill(1, 1, 1, 50, '█')
disp.fill(160, 1, 1, 50, '█')
disp.fill(2, 1, 158, 1, '▀')
disp.fill(2, 50, 158, 1, '▄')
disp.fill(3, 2, 1, 48, '│')
disp.fill(158, 2, 1, 48, '│')
disp.fill(3, 2, 155, 1, '─')
disp.fill(3, 49, 155, 1, '─')

disp.set(3, 2, '┌')
disp.set(158, 2, '┐')
disp.set(3, 49, '└')
disp.set(158, 49, '┘')

--Beamer list
disp.setForegrounds(0xeeeeee)
disp.fill(10, 5, 50, 1, '─')
disp.fill(10, 46, 50, 1, '─')
disp.fill(10, 5, 1, 42, '│')
disp.fill(60, 5, 1, 42, '│')

disp.set(10, 5, '┌')
disp.set(60, 5, '┐')
disp.set(10, 46, '└')
disp.set(60, 46, '┘')

disp.fill(12, 40, 47, 1, '▀')

--Beamer master
disp.setForegrounds(0x444444)
disp.setBackgrounds(0x787878)
disp.fill(85, 7, 30, 15, ' ')
disp.fill(85, 7, 30, 1, '▀')
disp.fill(85, 21, 30, 1, '▄')
disp.fill(85, 7, 1, 15, '█')
disp.fill(114, 7, 1, 15, '█')

disp.setForegrounds(0x666666)
disp.setBackgrounds(0x555555)
disp.fill(93, 11, 14, 7, ' ')
disp.fill(93, 11, 14, 1, '▀')
disp.fill(93, 17, 14, 1, '▄')
disp.fill(93, 11, 1, 7, '█')
disp.fill(106, 11, 1, 7, '█')

--Beamer connections
disp.setBackgrounds(0x000000)
disp.setForegrounds(0xaaaaaa)
disp.fill(82, 6, 1, 17, '│')
disp.fill(83, 5, 7, 1, '─')
disp.fill(83, 23, 7, 1, '─')
disp.set(82, 5, '┌')
disp.set(82, 23, '└')

disp.set(82, 8, '╡')
disp.set(82, 16, '╡')
disp.set(82, 17, '╡')
disp.set(82, 13, '┤')

disp.fill(65, 8, 17, 1, '═')
disp.fill(72, 13, 10, 1, '─')
disp.fill(76, 16, 6, 1, '═')
disp.fill(68, 17, 14, 1, '═')

disp.set(65, 8, '╔')
disp.set(72, 13, '┌')
disp.set(76, 16, '╔')
disp.set(68, 17, '╔')

disp.fill(65, 9, 1, 31, '║')
disp.fill(76, 17, 1, 16, '║')
disp.fill(68, 18, 1, 9, '║')
disp.fill(72, 14, 1, 28, '│')

disp.fill(76, 33, 4, 1, '═')
disp.fill(66, 39, 14, 1, '═')
disp.fill(73, 41, 7, 1, '─')
disp.fill(69, 27, 69, 1, '═')

disp.fill(119, 21, 37, 1, '─')
disp.fill(137, 22, 1, 5, '║')
disp.fill(119, 17, 1, 4, '│')
disp.fill(155, 17, 1, 4, '│')

disp.set(76, 33, '╚')
disp.set(65, 39, '╚')
disp.set(72, 41, '└')
disp.set(68, 27, '╚')

disp.set(72, 17, '╪')
disp.set(72, 27, '╪')
disp.set(76, 27, '╬')
disp.set(76, 17, '╬')
disp.set(72, 39, '╪')

disp.set(137, 21, '╥')
disp.set(137, 27, '╝')
disp.set(119, 21, '└')
disp.set(155, 21, '┘')

--Beamer status display
disp.setForegrounds(0x332480)
disp.fill(80, 30, 76, 1, '▀')
disp.fill(80, 47, 76, 1, '▄')
disp.fill(80, 30, 1, 18, '█')
disp.fill(155, 30, 1, 18, '█')

disp.fill(82, 31, 71, 1, '─')
disp.fill(82, 46, 71, 1, '─')
disp.fill(82, 31, 1, 15, '│')
disp.fill(153, 31, 1, 15, '│')

disp.set(82, 31, '┌')
disp.set(153, 31, '┐')
disp.set(82, 46, '└')
disp.set(153, 46, '┘')

--Text
disp.setBackgrounds(0x000000)
disp.setForegrounds(0xeeeeee)

disp.set(103, 33, '--[=[ Beamer Statistics ]=]--')
disp.set(84, 35, 'Address:')
disp.set(84, 37, 'Mode:')
disp.set(84, 39, 'Role:')
disp.set(84, 41, 'Control:')
disp.set(84, 43, 'Buffer:')
disp.set(84, 45, 'Transfer: ')
disp.set(22, 41, '--[=[ Beamer Status ]=]--')
disp.set(13, 43, 'Address:')
disp.set(13, 44, 'Code:')