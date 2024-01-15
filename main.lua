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

local ui = {
	finishButton = {
		x = 0.25,
		y = 0.75,
		width = 0.5,
		height = 0.1,
		text = "End day",
		color = { 0.2, 0.2, 0.9 },
		textColor = { 1, 1, 1 },
		textWidth = 50,
		textHeight = 4,
	},
}

local state = "empty"
local today = os.date("%d_%m_%y")
local todaysFile = os.date("%d_%m_%y.txt")
-- local timeformat = "%H:%M" --" %d.%m.%y"

local time = {
	start = "x",
	finish = "x",
	diff = "x",
}

local errorData = {
	hasError = false,
	message = "",
}

local function log(msg)
	print(string.format("[LOG]: %s", tostring(msg)))
end

local function writeTodaysFile()
	love.filesystem.write(todaysFile, serpent.dump(time))
end

local startDay = function()
	log("starting day")
	local now = os.date("*t")
	time.start = now
	writeTodaysFile()
	state = "started"
end

local reEnter = function()
	local resultToday, fail = love.filesystem.read(todaysFile)
	if not resultToday then
		errorData.hasError = true
		errorData.type = "read todays file"
		errorData.message = fail
	else
		log("read todays file")
		local ok, today = serpent.load(resultToday)
		if ok then
			log("loaded todays file")
			time = today
			if time.start == "x" then
				log("no start time found")
				startDay()
			else
				log("start time found")
				state = "started"
			end
			if time.finish == "x" then
				log("no finish time found")
			else
				log("finish time found")
				log(time.finish)
				state = "done"
			end
		else
			errorData.hasError = true
			errorData.type = "load todays time table"
			errorData.message = fail
		end
	end
end

local endDay = function()
	local now = os.date("*t")
	time.finish = now
	time.diff = os.difftime(os.time(time.finish), os.time(time.start))
	writeTodaysFile()
	state = "done"
end

--======================================================================================================================--

function love.load()
	log("loading...")
	if not love.filesystem.getInfo(todaysFile) then
		log("no file found, creating...")
		writeTodaysFile()
		startDay()
	else
		log("file found, reentering...")
		reEnter()
	end
end

function love.update(dt)
	local touches = love.touch.getTouches()

	for i, id in ipairs(touches) do
		local x, y = love.touch.getPosition(id)
		love.graphics.circle("fill", x, y, 20)
	end
end

function love.draw()
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()

	if errorData.hasError then
		love.graphics.setColor(1, 0.2, 0.2)
		love.graphics.print(string.format("Error [%s]: %s", errorData.type, errorData.message, 10, 10))
	end

	love.graphics.setColor(1, 1, 1)
	if state == "started" then
		love.graphics.print(string.format("Started @ %d:%d", time.start.hour, time.start.min), 10, 20)
		-- time left
	elseif state == "done" then
		love.graphics.print("Done!", 10, 20)
		love.graphics.print(
			string.format(
				"Worked for %ss, from %d:%d to %d:%d",
				time.diff,
				time.start.hour,
				time.start.min,
				time.finish.hour,
				time.finish.min
			),
			10,
			40
		)
	else
		love.graphics.print("no state set, check errors...", 10, 210)
	end

	love.graphics.print(serpent.block(time), 10, 170)

	love.graphics.print("Press [escape] to quit", 10, 70)
	love.graphics.print("Press [space] to end day", 10, 90)

	love.graphics.setColor(ui.finishButton.color)
	love.graphics.rectangle(
		"fill",
		width * ui.finishButton.x,
		height * ui.finishButton.y,
		width * ui.finishButton.width,
		height * ui.finishButton.height,
		6
	)
	love.graphics.setColor(ui.finishButton.textColor)
	love.graphics.print(
		ui.finishButton.text,
		(width * ui.finishButton.x) + (width * ui.finishButton.width / 2) - (ui.finishButton.textWidth / 2),
		(height * ui.finishButton.y) + (height * ui.finishButton.height / 2) - (ui.finishButton.textHeight * 2)
	)
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
