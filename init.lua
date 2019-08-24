spaces = require("hs._asm.undocumented.spaces")
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

function getSpaceIds()
	spacesLayout = spaces.layout()
	spaceIdsTable = {}
	for screen, spacesArray in pairs(spacesLayout) do
		--log.i(#spacesArray)
		for k, spaceId in pairs(spacesArray) do
			--log.i(spaceId)
			spaceIdsTable[spaceId] = true
		end
	end
	spaceIdsList = {}
	for spaceId, _ in pairs(spaceIdsTable) do
		table.insert(spaceIdsList, spaceId)
	end
	return spaceIdsList
end

function getWindowsOnAllSpaces()
	windows = {}
	for _, spaceId in pairs(getSpaceIds()) do
		for _, window in pairs(spaces.allWindowsForSpace(spaceId)) do
			windows[#windows+1] = window
		end
	end
	return windows
end

function storeWindows()
	windows = getWindowsOnAllSpaces()
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
		title = v:title():gsub('%\n', '') -- remove newlines
		io.write(table.concat({v:id(), screen, title, x, y, w, h}, separator) .. '\n')
	end
	io.close(file)
	log.i("Windows stored")
end

function manuallyStoreWindows()
	storeWindows()
	displayMessage("Windows stored")
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "S", manuallyStoreWindows)

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
	windows = getWindowsOnAllSpaces()
 	for k, line in pairs(linesWithoutFirstLine) do
		id, screenId, title, x, y, w, h = line:match("(.-), (.-), (.-), (.-), (.-), (.-), (%d+)")
		log.i('parsed window id:' .. id)
		id = tonumber(id)
		screenId = tonumber(screenId)
		x = tonumber(x)
		y = tonumber(y)
		w = tonumber(w)
		window = getWindow(windows, id)
		screen = hs.screen.find(screenId)
		if window == nil then
			log.w('window is nil, id: ' .. id)
			goto continue
		end
		if screen == nil then
			log.w('screen is nil, id: ' .. id)
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
