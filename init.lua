hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
	hs.notify.new({title="Hammerspoon", informativeText="Hello World"}):send()
end)

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "H", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	f.x = f.x - 10
	win:setFrame(f)
end)

configFilePath = 'storedWindows.csv'
scriptName = 'WindowKeeper'
function displayMessage(message)
	hs.notify.new({title=scriptName, informativeText=message}):send()
end
 
function storeWindows()
	filter = hs.window.filter.new():setDefaultFilter()
	windows = filter:getWindows()
	file = io.open(configFilePath, 'w')
	io.output(file)
	io.write('id, screen, title, x, y, w, h\n')
	for k, v in pairs(windows) do
		screen = v:screen():id()
		topLeft = v:topLeft()
		x = topLeft['x']
		y = topLeft['y']
		size = v:size()
		w = size['w']
		h = size['h']
		io.write(table.concat({v:id(), screen, v:title(), x, y, w, h}, ', ') .. '\n')
	end
	io.close(file)
	displayMessage("Windows stored")
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "S", storeWindows)

function getLines(filename)
    local lines = {}
    for line in io.lines(filename) do
        lines[#lines+1] = line
    end
    return lines
end

log = hs.logger.new(scriptName)

function getWindow(windows, id)
	for i,window in ipairs(windows) do
		if window:id() == id then
			return window
		end
	end
	return nil
end

function restoreWindows()
	lines = getLines(configFilePath)
	linesWithoutFirstLine = {}
	for i = 2, #lines do
		linesWithoutFirstLine[#linesWithoutFirstLine+1] = lines[i]
	end
	filter = hs.window.filter.new():setDefaultFilter()
	windows = filter:getWindows()
 	for k, line in pairs(linesWithoutFirstLine) do
		id, screenId, title, x, y, w, h = line:match("(.-), (.-), (.-), (.-), (.-), (.-), (%d+)")
		id = tonumber(id)
		screenId = tonumber(screenId)
		x = tonumber(x)
		y = tonumber(y)
		w = tonumber(w)
		window = getWindow(windows, id)
		screen = hs.screen.find(screenId)
		if window == nil then
			log.w('window is nil')
			goto continue
		end
		if screen == nil then
			log.w('screen is nil')
			goto continue
		end
		frame = window:frame()
		frame.x = x
		frame.y = y
		frame.w = w
		frame.h = h
		window:setFrame(frame)
		window:moveToScreen(screen)
		log.w('window restored')
		::continue::
	end
	displayMessage("Windows restored")
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", restoreWindows)