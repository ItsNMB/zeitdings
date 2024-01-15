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
		amount = 0,
		maxAmount = 1,
	},
	restartButton = {
		x = 0.25,
		y = 0.75,
		width = 0.5,
		height = 0.1,
		text = "Restart day",
		color = { 0.9, 0.2, 0.2 },
		textColor = { 1, 1, 1 },
		textWidth = 60,
		textHeight = 4,
		amount = 0,
		maxAmount = 3,
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
		local ok, today = serpent.load(resultToday)
		if ok then
			time = today
			if time.start == "x" then
				startDay()
			else
				state = "started"
			end
			if time.finish == "x" then
			else
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
	ui.finishButton.amount = 0
	local now = os.date("*t")
	time.finish = now
	time.diff = os.difftime(os.time(time.finish), os.time(time.start))
	writeTodaysFile()
	state = "done"
end

local restartDay = function()
	love.filesystem.write(todaysFile .. ".bak", serpent.dump(time))
	time = {
		start = "x",
		finish = "x",
		diff = "x",
	}
	love.filesystem.write(todaysFile, serpent.dump(time))
	state = "empty"
	startDay()
end
--======================================================================================================================--

function love.load()
	love.window.setTitle("Zeitdings")
	love.window.setMode(360, 640)

	love.graphics.setBackgroundColor(0, 0, 0)
	love.graphics.setFont(love.graphics.newFont(18))

	if not love.filesystem.getInfo(todaysFile) then
		writeTodaysFile()
		startDay()
	else
		reEnter()
	end
end

function love.update(dt)
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local touches = love.touch.getTouches()

	for i, id in ipairs(touches) do
		local x, y = love.touch.getPosition(id)
		if state == "started" then
			if
				x > width * ui.finishButton.x
				and x < width * ui.finishButton.x + width * ui.finishButton.width
				and y > height * ui.finishButton.y
				and y < height * ui.finishButton.y + height * ui.finishButton.height
			then
				ui.finishButton.amount = ui.finishButton.amount + dt
				if ui.finishButton.amount > ui.finishButton.maxAmount then
					endDay()
				end
			else
				ui.finishButton.amount = 0
			end
		elseif state == "done" then
			if
				x > width * ui.restartButton.x
				and x < width * ui.restartButton.x + width * ui.restartButton.width
				and y > height * ui.restartButton.y
				and y < height * ui.restartButton.y + height * ui.restartButton.height
			then
				ui.restartButton.amount = ui.restartButton.amount + dt
				if ui.restartButton.amount > ui.restartButton.maxAmount then
					restartDay()
				end
			else
				ui.restartButton.amount = 0
			end
		end
	end
end

function love.draw()
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()

	if ui.finishButton.amount > 0 then
		love.graphics.setColor(0.1, 0.1, 0.1)
		love.graphics.circle(
			"fill",
			width / 2,
			height / 2,
			width / 2 * (ui.finishButton.amount / ui.finishButton.maxAmount)
		)
	end
	if ui.restartButton.amount > 0 then
		love.graphics.setColor(0.2, 0.1, 0.1)
		love.graphics.circle(
			"fill",
			width / 2,
			height / 2,
			width / 2 * (ui.restartButton.amount / ui.restartButton.maxAmount)
		)
	end

	if errorData.hasError then
		love.graphics.setColor(1, 0.2, 0.2)
		love.graphics.print(string.format("Error [%s]: %s", errorData.type, errorData.message, 10, 40))
	end

	love.graphics.setColor(1, 1, 1)
	if state == "started" then
		love.graphics.print(string.format("Started @ %d:%d", time.start.hour, time.start.min), 10, 40)
		-- time left
	elseif state == "done" then
		love.graphics.print(
			string.format(
				"Done!\nWorked for %dh %dm, from %d:%d to %d:%d",
				time.diff / 3600,
				(time.diff % 3600) / 60,
				time.start.hour,
				time.start.min,
				time.finish.hour,
				time.finish.min
			),
			10,
			40
		)
	else
		love.graphics.print("no state set, check errors...", 10, 30)
	end

	if state == "started" then
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
	elseif state == "done" then
		love.graphics.setColor(ui.restartButton.color)
		love.graphics.rectangle(
			"fill",
			width * ui.restartButton.x,
			height * ui.restartButton.y,
			width * ui.restartButton.width,
			height * ui.restartButton.height,
			6
		)
		love.graphics.setColor(ui.restartButton.textColor)
		love.graphics.print(
			ui.restartButton.text,
			(width * ui.restartButton.x) + (width * ui.restartButton.width / 2) - (ui.restartButton.textWidth / 2),
			(height * ui.restartButton.y) + (height * ui.restartButton.height / 2) - (ui.restartButton.textHeight * 2)
		)
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "space" then
		if state == "started" then
			endDay()
		end
	elseif key == "r" then
		if state == "done" then
			restartDay()
		end
	end
end
