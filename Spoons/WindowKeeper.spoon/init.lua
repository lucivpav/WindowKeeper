scriptName = 'WindowKeeper'
local obj = {}
obj.__index = obj
obj.name = scriptName

spaces = require("hs._asm.undocumented.spaces")

log = hs.logger.new(scriptName, 'info')

function displayMessage(message)
	hs.notify.new({title=scriptName, informativeText=message}):send()
end

function getNumberOfScreens()
	return #hs.screen.allScreens()
end

function getScreenIds()
	local screenIds = {}
	for _, screen in pairs(hs.screen.allScreens()) do
		screenIds[#screenIds+1] = screen:id()
	end
	return screenIds
end

configFilePath = 'Spoons/' .. scriptName .. '.spoon/storedWindows.csv'
separator = ', '
escapedSeparator = '; '
nScreens = getNumberOfScreens()
screenIds = getScreenIds()
storeEverySeconds = 30
automaticStoreRestore = true

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

function valueInTable(table, value)
	for _, tableValue in pairs(table) do
		if tableValue == value then
			return true
		end
	end
	return false
end

function getNewScreenIds()
	local newScreenIds = {}
	for _, screenId in pairs(getScreenIds()) do
		if not valueInTable(screenIds, screenId) then
			newScreenIds[#newScreenIds+1] = screenId
		end
	end
	return newScreenIds
end

function parseLine(line)
	local id, screenId, title, x, y, w, h = line:match("(.-), (.-), (.-), (.-), (.-), (.-), (%d+)")
	local id = tonumber(id)
	local screenId = tonumber(screenId)
	local x = tonumber(x)
	local y = tonumber(y)
	local w = tonumber(w)
	return id, screenId, title, x, y, w, h
end

function getConfigLinesWithoutFirstLine()
	local lines = getLines(configFilePath)
	local linesWithoutFirstLine = {}
	for i = 2, #lines do
		linesWithoutFirstLine[#linesWithoutFirstLine+1] = lines[i]
	end
	return linesWithoutFirstLine
end

function isRestoreWindowsMeaningful()
	local lines = getConfigLinesWithoutFirstLine()
	for _, newScreenId in pairs(getNewScreenIds()) do
		for _, line in pairs(lines) do
			local _, screenId = parseLine(line)
			if screenId == newScreenId then
				return true
			end
		end
	end
	return false
end

function restoreWindows()
	windows = getWindowsOnAllSpaces()
 	for k, line in pairs(getConfigLinesWithoutFirstLine()) do
		id, screenId, title, x, y, w, h = parseLine(line)
		window = getWindow(windows, id)
		screen = hs.screen.find(screenId)
		if window == nil then
			log.w('window is nil, window id: ' .. id)
			goto continue
		end
		if screen == nil then
			log.w('screen is nil, window id: ' .. id)
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

function restoreWindowsManually()
	f, error = io.open(configFilePath, "r")
	if f == nil then
		displayMessage("Nothing to restore")
	else
		restoreWindows()
	end
end

function restoreWindowsAutomatically()
	f, error = io.open(configFilePath, "r")
	if f == nil then
		return
	end

	if not isRestoreWindowsMeaningful() then
		return
	end

	restoreWindows()
end

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", restoreWindowsManually)

function screenCallback()
	currentNumberOfScreens = getNumberOfScreens()
	if nScreens < currentNumberOfScreens then
		-- monitor(s) connected
		restoreWindowsAutomatically()
		storeTimer:start()
	end

	if nScreens > currentNumberOfScreens then
		-- monitor(s) disconnected
		-- already too late to store windows here
		storeTimer:stop()
	end

	nScreens = currentNumberOfScreens
	screenIds = getScreenIds()
	log.i("Screen change detected (" .. nScreens .. ' screen(s) connected)')
end

if automaticStoreRestore then
	screenWatcher = hs.screen.watcher.new(screenCallback)
	screenWatcher:start()

	storeTimer = hs.timer.new(storeEverySeconds, storeWindows)
	if nScreens > 1 then
		storeTimer:start()
	end
end

return obj