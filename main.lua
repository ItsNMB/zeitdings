---> Zeitdings
-- check if already started
-- if not, start
-- store start time in file
-- if already started
-- show time since start
--
-- TODO: add reset button
-- TODO: add end button
-- TODO: add gauge

local state = "empty"

local filename = "today.txt"
local timeformat = "%H:%M" --" %d.%m.%y"

local startTime = nil
local endTime = nil

local errorData = {
	hasError = false,
	message = "",
}

local startDay = function()
	local time = os.date(timeformat)
	print("Start: " .. time)
	love.filesystem.write("start.txt", time)
	startTime = time
	state = "started"
end

local reEnter = function()
	local startToday, fail = love.filesystem.read("start.txt")
	if not startToday then
		errorData.hasError = true
		errorData.type = "read start.txt"
		errorData.message = fail
	else
		startTime = startToday
		state = "started"
	end

	if not love.filesystem.getInfo("end.txt") then
		state = "started"
	else
		local endToday, fail = love.filesystem.read("end.txt")
		if not endToday then
			errorData.hasError = true
			errorData.type = "read end.txt"
			errorData.message = fail
		else
			endTime = endToday
			state = "done"
		end
	end
end

local endDay = function()
	local time = os.date(timeformat)
	print("End: " .. time)
	love.filesystem.write("end.txt", time)
	endTime = time
	state = "done"
end

function love.load()
	print("LOADING...")
	-- if todays file does not exist, start
	if not love.filesystem.getInfo("start.txt") then
		print("NOT STARTED TODAY, STARTING NOW...")
		startDay()

	-- if todays file exists, re enter
	else
		print("RENTERING...")
		reEnter()
	end
end

function love.update(dt) end

function love.draw()
	if errorData.hasError then
		love.graphics.setColor(1, 0.1, 0.1)
		love.graphics.print(string.format("Error [%s]: %s", errorData.type, errorData.message, 10, 10))
	end

	love.graphics.setColor(1, 1, 1)
	if state == "started" then
		love.graphics.print("Started @ " .. tostring(startTime), 10, 20)
	elseif state == "done" then
		love.graphics.print("Done", 10, 20)
		love.graphics.print(string.format("Worked from %s to %s", startTime, endTime), 10, 30)
	else
		love.graphics.print("no state set, check errors...", 10, 210)
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "space" then
		if state == "started" then
			endDay()
		end
	end
end
