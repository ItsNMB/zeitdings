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

local serpent = require("serpent")

local state = "empty"
-- local timeformat = "%H:%M" --" %d.%m.%y"

local time = {
	start = "",
	finish = "",
	diff = "",
}

local errorData = {
	hasError = false,
	message = "",
}

local startDay = function()
	local now = os.date("*t")
	love.filesystem.write("start.txt", serpent.dump(now))
	startTime = now
	state = "started"
end

local reEnter = function()
	local resultStart, fail = love.filesystem.read("start.txt")
	if not resultStart then
		errorData.hasError = true
		errorData.type = "read start.txt"
		errorData.message = fail
	else
		time.start = resultStart
		state = "started"
	end

	if not love.filesystem.getInfo("finish.txt") then
		state = "started"
	else
		local resultFinish, fail = love.filesystem.read("finish.txt")
		if not resultFinish then
			errorData.hasError = true
			errorData.type = "read finish.txt"
			errorData.message = fail
		else
			time.finish = resultFinish
			state = "done"
		end
	end
end

local endDay = function()
	local time = os.date(timeformat)
	love.filesystem.write("finish.txt", time)
	endTime = time
	state = "done"
end

function love.load()
	-- if todays file does not exist, start
	if not love.filesystem.getInfo("start.txt") then
		startDay()

	-- if todays file exists, re-enter
	else
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
		duration = os.difftime(os.time(), os.time(time.start))
		love.graphics.print("Done", 10, 20)
		love.graphics.print(
			string.format("Worked for %s, from %s to %s", tostring(duration), startTime, endTime),
			10,
			40
		)
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
