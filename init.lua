function displayMessage(message)
	hs.notify.new({title=scriptName, informativeText=message}):send()
end

function getNumberOfScreens()
	return #hs.screen.allScreens()
end

configFilePath = 'storedWindows.csv'
scriptName = 'WindowKeeper'
separator = ', '
escapedSeparator = '; '
nScreens = getNumberOfScreens()
storeEverySeconds = 30
automaticStoreRestore = true

log = hs.logger.new(scriptName, 'info')

function storeWindows()
	filter = hs.window.filter.new():setDefaultFilter()
	windows = filter:getWindows()
	file = io.open(configFilePath, 'w')
	io.output(file)
	io.write(table.concat({'id', 'screen' ,'title', 'x', 'y', 'w', 'h'}, separator) .. '\n')
	for k, v in pairs(windows) do
		screen = v:screen():id()
		topLeft = v:topLeft()
		x = topLeft['x']
		y = topLeft['y']
		size = v:size()
		w = size['w']
		h = size['h']
		title = v:title():gsub('%' .. separator, escapedSeparator)
		io.write(table.concat({v:id(), screen, title, x, y, w, h}, separator) .. '\n')
	end
	io.close(file)
	log.i("Windows stored")
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "S", storeWindows)

function getLines(filename)
    local lines = {}
    for line in io.lines(filename) do
        lines[#lines+1] = line
    end
    return lines
end


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
		::continue::
	end
	displayMessage("Windows restored")
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", restoreWindows)

function screenCallback()
	currentNumberOfScreens = getNumberOfScreens()
	if nScreens < currentNumberOfScreens then
		-- monitor(s) connected
		restoreWindows()
		storeTimer:start()
	end

	if nScreens > currentNumberOfScreens then
		-- monitor(s) disconnected
		-- already too late to store windows here
		storeTimer:stop()
	end

	nScreens = currentNumberOfScreens
	log.i("Screen change detected")
end

if automaticStoreRestore then
	screenWatcher = hs.screen.watcher.new(screenCallback)
	screenWatcher:start()

	storeTimer = hs.timer.new(storeEverySeconds, storeWindows)
	storeTimer:start()
end