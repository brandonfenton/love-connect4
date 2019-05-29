local moonshine = require 'moonshine'
function enum(x) for k,v in pairs(x) do print(k,v) end end	

function love.load()
	--love.window.setFullscreen(true) --not for now
	vhsFont = love.graphics.newFont("fonts/vcr.ttf", 36)
	rrFont = love.graphics.newFont("fonts/rr.ttf", 36)
	shd1 = love.graphics.newShader [[
	        extern number time;
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
		        {
		   	    return vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 0.5);
		        }
		]]

	shd2 = love.graphics.newShader [[
	        extern number time;
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
		        {
			    return vec4(1-(1.0+sin(time))/2.0, 1-abs(cos(time)), 1-abs(sin(time)), 1.0);
		        }
		]]
	
	
	--Set up moonshine effects
	--ms1 = moonshine(moonshine.effects.glow) 
	--ms1.glow.min_luma = 0
	--ms1.glow.strength = 15
	
	ms1 = moonshine(moonshine.effects.glow).chain(moonshine.effects.chromasep)
	ms1.glow.min_luma = 0
	ms1.glow.strength = 15
	ms1.chromasep.angle = math.pi/4
	ms1.chromasep.radius=3
	
	--Set up audio
	one = love.audio.newSource("audio/one.wav","stream")
	two = love.audio.newSource("audio/two.wav","stream")
	one:setVolume(0.5)
	two:setVolume(0.5)
	
	bounce = love.audio.newSource("audio/bounce.ogg","stream")
	mood = love.audio.newSource("audio/rg.ogg","stream")
	mood:setFilter({type = 'lowpass', highgain=0})
	--repos = love.audio.newSource("audio/repos.ogg","static")

	love.audio.setEffect('myEffect', {type = 'echo', delay = 2})
	love.audio.setEffect('eff2', {type = 'reverb', decaytime = 1})
	--repos:setEffect('myEffect')
	mood:setEffect('eff2')
	bounce:setEffect('myEffect')
	mood:setLooping(true)
	mood:play()

	--Create world and board
	world = love.physics.newWorld(0,200,true)
	world:setCallbacks(beginContact, endContact, preSolve, postSolve)
	blocks = {}
		
	static = {}
		static.b = love.physics.newBody(world,400,575,"static")
		static.s = love.physics.newRectangleShape(525,50)
		static.f = love.physics.newFixture(static.b, static.s)
		static.f:setUserData("Board")
	
	--Values related to board stuff and game play
	xmin, xmax, ymin, ymax = 137.5, 662.5, 550, 100
	blkSize = 75
	p1 = true
end


local t=0
function love.update(dt)
	world:update(dt)
	t = t + dt
	 
	if t < 10 then
		mood:setFilter({type = 'lowpass', highgain= 1 - math.cos(math.pi * t/20)})
	end
	shd1:send("time",t)
	shd2:send("time",t)

	

	--toggle fullscreen
	--if love.keyboard.isDown("f") then
	--	newFs = not love.window.getFullscreen()
	--	love.window.setFullscreen(newFs)
	--	print(love.window.getMode())
	--end

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	for i, block in pairs(blocks) do
		if block.static == true then
			block.b.setType("static")
		end
	end

end



function love.draw()
	love.graphics.setFont(vhsFont)
	ms1(function()
		love.graphics.setColor(0,0,0)
		love.graphics.polygon("fill", static.b:getWorldPoints(static.s:getPoints()))
		--love.graphics.setShader()
		for i, block in pairs(blocks) do
			if block.p1 == true then love.graphics.setShader(shd1)
			elseif block.p1 == false then love.graphics.setShader(shd2)
			end
			
			love.graphics.polygon("fill", block.b:getWorldPoints(block.s:getPoints()))
		end

		love.graphics.setShader()

		drawGrid()
		
		love.graphics.setColor(1,0,1)
		love.graphics.print("P1",50,50)
		love.graphics.print("P2",700,50)

	     end)
end

function love.mousepressed(x,y, button, istouch)

	for i, block in pairs(blocks) do
		bCoords = {block.b:getWorldPoints(block.s:getPoints())}
		if button == 1 and block.static == false and
		x >= bCoords[1] and x <=bCoords[3] and
		y >= bCoords[2] and y <=bCoords[6] then
			block.drag = true
			--repos:play()
		end
	end
	
end

function love.mousemoved(x,y,dx,dy)
	for i, block in pairs(blocks) do
		if block.drag == true then
			block.b:setPosition(x,y)
			block.b:setLinearVelocity(0,0)
			block.b:setGravityScale(0)
			block.b:setType("")

		end
	end
end

function love.mousereleased(x, y, button)
	for i, block in pairs(blocks) do
		if button == 1 and block.drag == true then 
			block.drag = false
			loc = math.floor((x-175)/75)
			if loc < 0 then loc = 0 end
			if loc > 6 then loc = 6 end
			block.b:setPosition(175 + 75*loc,y)
			block.b:setLinearVelocity(0,100)
			block.b:setGravityScale(1)
		end
	end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "1" then
		createBlock(175, 100)
	elseif key == "2" then
		createBlock(250, 100)
	elseif key =="3" then
		createBlock(325, 100)
	elseif key =="4" then
		createBlock(400, 100)
	elseif key =="5" then
		createBlock(475, 100)
	elseif key == "6" then
		createBlock(550, 100)
	elseif key == "7" then
		createBlock(625, 100)
	elseif key == "escape" then
		love.event.quit()
	end
end
text = ""
function beginContact(a, b, coll)
	local uData = {}
	uData.a = a:getUserData()
	uData.b = b:getUserData()
	
	x = (coll:getNormal())
	
	if uData.a == "Block" and uData.b == "Board" then
		bounce:play()
	elseif uData.a == "Board" and uData.b =="Block" then
		bounce:play()
	elseif uData.a =="Block" and uData.b == "Block" and
	x == 0 then
		bounce:play()
	end
end
 
function endContact(a, b, coll)

end
 
function preSolve(a, b, coll)
	 
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
	 
end

function drawLine(x1, y1, x2, y2)
	love.graphics.setPointSize(5)
	
	local x, y = x2 - x1, y2 - y1
	local len = math.sqrt(x^2 + y^2)
	local stepx, stepy = 4*x / len, 4*y / len
	x = x1
	y = y1
	
	for i = 1, len do
	love.graphics.points(x, y)
	x = x + stepx
	y = y + stepy
	end
end


function drawGrid()
	love.graphics.setColor(0,0,1)
	line = love.graphics.line
	
	for vline = xmin, xmax, blkSize do
		line(vline, ymin, vline, ymax)
	end
	love.graphics.setColor(0,0,1)
	for hline = ymin, ymax, -blkSize do
		line(xmin, hline, xmax, hline)
	end
	
end

function createBlock(x,y)
	local block = {}
		block.b = love.physics.newBody(world,x,y,"dynamic")
		block.b:setMass(10)
		block.b:setFixedRotation(true)
		block.s = love.physics.newRectangleShape(74.5,74.5)
		block.f = love.physics.newFixture(block.b, block.s)
		block.f:setRestitution(0)
		block.f:setUserData("Block")
		block.drag = false --is dragging active?
		block.p1 = p1
	table.insert(blocks, block)
	if p1 == true then
		one:play()
	else 
		two:play()
	end

	p1 = not p1
end
