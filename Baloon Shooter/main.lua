-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Hide status bar, so it won't keep covering our game objects
display.setStatusBar(display.HiddenStatusBar)

-- Load and start physics
local gravity 				= 0.0
local physics 				= require("physics")
physics.start()

-- Adding less gravity so that enemies fly down slowly
gravity     				= 0.30
physics.setGravity(0, gravity)

-- Layers (Groups).
local titleScreenGroup 		= display.newGroup()
local skyLayer    			= display.newGroup()
local warZone 				= display.newGroup()
local enemiesAttack 		= display.newGroup()

-- Variables for game
local gameOn 				= true
local scoreText
local scoreTextTitle
local score 				= 0

-- Variable for enemie plane removal
local toRemove 				= {}

-- Variables for player, enemy and environment
local sounds
local background
local player
local tLeft					= 0
local tRight				= 0
local halfPlayerWidth
local enemyPos
local lastStartPos
local lastEndPos
local EnemyWidth
local shootposX				= 0
local shootposY				= 0
local timeLastBullet, timeLastEnemy = 0, 0
local bulletInterval 		= 1000
local textureCache 			= {}

-- Keep the texture in cache memory
textureCache[1] 			= display.newImage("images/enemy.png");
textureCache[1].isVisible 	= false;
textureCache[2] 			= display.newImage("images/bullet.png");
textureCache[2].isVisible 	= false;
EnemyWidth 					= textureCache[1].contentWidth

-- Adjust the volume
audio.setMaxVolume( 0.050, { channel=1 } )

-- Pre-load our sounds
sounds =
{
	pew 					= audio.loadSound("sound/pew.wav"),
	boom 					= audio.loadSound("sound/boom.wav"),
	gameOver 				= audio.loadSound("sound/gameOver.wav")
}

function main()
	score 					= 0
    showTitleScreen();
end

function showTitleScreen()


	--background
			menuBackground 	 	= display.newImageRect( "images/intro.jpg",display.contentWidth,display.contentHeight)
			menuBackground.x 	= display.contentWidth/2
			menuBackground.y 	= display.contentHeight/2

	--play button
			playBtn 			= display.newImage("images/start.png")
			playBtn.x 			= display.contentWidth/2;
			playBtn.y 			= display.contentHeight/2 + 150
			playBtn.name 		= "loadGame"

	--inserting
			titleScreenGroup:insert(menuBackground)
			titleScreenGroup:insert(playBtn)
	--press button
			playBtn:addEventListener("tap", loadGame)
end


function loadGame(event)
    if event.target.name == "loadGame"  then
			gameOn = true
			transition.to(titleScreenGroup,{time = 0, alpha=0, onComplete =	game});
			playBtn:removeEventListener("tap", loadGame)
	end
end

local function destroyObj(obj)
		display.remove(obj)
		obj=nil
end

-- Take care of collisions
local function onCollision(self, event)
	-- Bullet hit enemy
	if self.name == "bullet" and event.other.name == "enemy" and gameOn then
		-- Increase score
		score = score + 1
		scoreText.text = score
		-- Play Sound
		audio.play(sounds.boom)
		table.insert(toRemove, event.other)

	elseif self.name == "left" and event.other.name == "enemy" then
		table.insert(toRemove, event.other)

	elseif self.name == "right" and event.other.name == "enemy" then
		table.insert(toRemove, event.other)

	-- Player collision - GAME OVER
	elseif self.name == "player" and event.other.name == "enemy" then
		audio.play(sounds.gameOver)
		table.insert(toRemove, event.other)
		table.insert(toRemove, self)
		local gameoverText = display.newText("GAME OVER!", 0, 0, native.systemFont, 35)
		gameoverText:setFillColor(0, 0, 0)
		gameoverText.x = display.contentCenterX
		gameoverText.y = display.contentCenterY
		skyLayer:insert(gameoverText)

		-- This will stop the gameLoop
		gameOn = false
	end
end

local function gameLoop(event)
	if gameOn then
		-- Remove collided enemy planes
		for i = 1, #toRemove do
			toRemove[i].parent:remove(toRemove[i])
			toRemove[i] = nil
		end

		-- Enemy planes
		if event.time - timeLastEnemy >= math.random(1200, 1400) then
			-- Randomly position it on the top of the screen
			local enemy = display.newImage("images/enemy.png")
			enemyPos = math.random(EnemyWidth, display.contentWidth - EnemyWidth)
			if enemyPos >= lastStartPos and enemyPos <= lastEndPos then
				enemy.x = enemyPos - EnemyWidth - 20
			else
				enemy.x = enemyPos
			end
			enemy.x = enemyPos
			enemy.y = -enemy.contentHeight

			lastStartPos = enemyPos
			lastEndPos = enemyPos + EnemyWidth
			-- fall to the bottom of the screen.
			physics.addBody(enemy, "dynamic", {bounce = 0})
			enemy.name = "enemy"

			enemiesAttack:insert(enemy)
			timeLastEnemy = event.time
		end

		-- Bullet
		if event.time - timeLastBullet >= math.random(250, 300) then
			local bullet = display.newImage("images/bullet.png")
			bullet.x = player.x
			bullet.y = player.y - halfPlayerWidth

			-- Kinematic, so it doesn't react to gravity.
			physics.addBody(bullet, "kinematic", {bounce = 0})
			bullet.name = "bullet"

			-- Listen to collisions, so we may know when it hits an enemy.
			bullet.collision = onCollision
			bullet:addEventListener("collision", bullet)

			warZone:insert(bullet)

			-- Pew-pew sound!
			audio.play(sounds.pew)

			-- Move it to the top.
			-- When the movement is complete, it will remove itself: the onComplete event
			-- creates a function to will store information about this bullet and then remove it.
			transition.to(bullet, {	time = 1000,
									x =  shootposX,
									y =  shootposY,
									onComplete = function(self) self.parent:remove(self);
									self = nil;
									end
								  })

			timeLastBullet = event.time
		end
	gravity = gravity + 0.0009
	physics.setGravity(0, gravity)
	end
end

function game()

-- Background Layer(Layer 1)
background 					= display.newImageRect( "images/sky.png",display.contentWidth,display.contentHeight)
background.alpha 			= 0.5
background.y = display.contentHeight/2
background.x = display.contentWidth/2
skyLayer:insert(background)

-- Bullet Layer(Layer 2)
skyLayer:insert(warZone)

-- Enemy Layer(Layer 3)
skyLayer:insert(enemiesAttack)

-- Player Layer(Layer 4)
-- Load and position the player
player = display.newImage("images/player.png")
player.x = display.contentCenterX
player.y = display.contentHeight - player.contentHeight + 20
physics.addBody(player, "kinematic", {bounce = 0})
player.name = "player"
player.collision = onCollision
player:addEventListener("collision", player)
skyLayer:insert(player)
halfPlayerWidth = player.contentWidth * .5


-- Score Layer(Layer 6)
-- Show the score

scoreTextTitle 		= display.newText("SCORE", 0, 0, native.systemFont, 12)
scoreTextTitle:setFillColor(0, 0, 0)
scoreTextTitle.x 	= 30
scoreTextTitle.y 	= 20
skyLayer:insert(scoreTextTitle)

scoreText 			= display.newText(score, 0, 0, native.systemFont, 12)
scoreText:setFillColor(0, 0, 0)
scoreText.x 		= 30
scoreText.y 		= 35
skyLayer:insert(scoreText)

--------------------------------------------------------------------------------
-- Game loop
--------------------------------------------------------------------------------
lastStartPos = display.contentWidth/2
lastEndPos   = lastStartPos + EnemyWidth

-- GameLoop
Runtime:addEventListener("enterFrame", gameLoop)
--------------------------------------------------------------------------------
-- Basic controls
--------------------------------------------------------------------------------
function background:tap(event)
  shootposX = event.x
  shootposY = event.y
  return true
end
background:addEventListener("tap", background)

end

main()


