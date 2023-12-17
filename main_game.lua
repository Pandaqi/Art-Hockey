-----------------------------------------------------------------------------------------
--
-- main_game.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()

-- include all objects
Object = require("tools.classic")
require("objects.player")
require("objects.ball")
require("objects.simulation")
require("objects.powerup_manager")

require("tools.timer2")

function table.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table.copy(k, s)] = table.copy(v, s) end
  return res
end

function scene:create( event )
	local sceneGroup = self.view
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
  
  -- only execute this whole function if phase == 'did'
  if phase == "will" then
    return
  end
  
  -- make sure to fully destroy the other scenes
  -- TO DO: Must be a better way than this, surely?
  composer.removeScene("game_over")
  composer.removeScene("main_menu")
  
  ---------
  -- ADS
  -- (preload one whenever we start a game, so it's loaded upon gameover)
  ---------
  if system.getInfo("platformName") ~= "Win" then
    local admob = require( "plugin.admob" )
    local adcfg = {
      adUnitId = "ca-app-pub-7465988806111884/4808358997",
      childSafe = true,
      designedForFamilies = true,
      hasUserConsent = false,
    }
    admob.load("rewardedVideo", adcfg)
  end

  ---------
  -- PHYSICS
  ---------
  -- start physics engine
  physics = require( "physics" )
  physics.start()
  
  -- disable gravity
  physics.setGravity(0, 0)
  
  -- increase physics accuracy on faster simulation speeds
  physics.setVelocityIterations(math.floor( 8 * (0.8 + GLOBALS.gameSpeed*0.2) ))
  physics.setPositionIterations(math.floor( 3 * (0.8 + GLOBALS.gameSpeed*0.2) ))
  
  -- physics.setDrawMode('hybrid')
  
  -- make sure texture/stroke fills wrap nicely, instead of stretching
  -- (really stupid way of doing things, but hey, it's Corona)
  display.setDefault( "textureWrapX", "repeat" )
  display.setDefault( "textureWrapY", "repeat" )
  
  
  --------
  -- BACKGROUND
  --------
  local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
  bg.fill = GLOBALS.beigeBackground
  
  
  -------
  -- PLAYERS
  -------
  -- grab number of players; if unavailable, default to 2
  local numPlayers = GLOBALS.playerCount
  if not numPlayers then 
    numPlayers = 2
    GLOBALS.playerCount = 2
  end
  
  -- (in the match settings, the user can determine which player is AI => we just take over that setting)
  local isComputerPlayer = GLOBALS.computerPlayers
  
  -- hand out a (UNIQUE) brush and background pattern/texture to each player
  local allBackgrounds = {'stripes', 'dots', 'triangles', 'rectangles', 'stars'}
  local allBrushes = {'brushBasic', 'brushGrungy', 'brushWatercolor', 'brushDotty', 'brushStarry', 'brushRectangle', 'brushTriangle', 'brushCircle'}
  table.shuffle(allBackgrounds)
  table.shuffle(allBrushes)
  
  GLOBALS.numComputerPlayers = 0
  GLOBALS.players = {}
  for i=1,numPlayers do
    local playerAI = isComputerPlayer[i]
    if GLOBALS.simulationMode then playerAI = true end
    
    local randBG = allBackgrounds[i]
    local randBrush = allBrushes[i]
    
    local p = Player(scene, i, numPlayers, playerAI, randBG, randBrush)
    GLOBALS.players[i] = p
    
    if playerAI then
      GLOBALS.numComputerPlayers = GLOBALS.numComputerPlayers + 1
    end
  end
  
  --------
  -- Background canvas
  -- This keeps track of EVERYTHING users have drawn, so it can display a final "painting" at the end
  -- Also, already start with the BEIGE background
  --------
  GLOBALS.backgroundCanvas = graphics.newTexture( { type="canvas", width=display.actualContentWidth, height=display.actualContentHeight } )
  
  local backdrop = display.newRect(0, 0, display.actualContentWidth, display.actualContentHeight)
  backdrop.fill = {251/255, 240/255, 226/255}
  GLOBALS.backgroundCanvas:draw(backdrop)
  
  ---------
  -- Second background canvas
  -- This simply registers some particle effects (paint blobs and such) during the game
  ---------
  GLOBALS.paintCanvas = graphics.newTexture( { type="canvas", width = display.actualContentWidth, height = display.actualContentHeight })
  local actualPaintCanvas = display.newImageRect(sceneGroup, GLOBALS.paintCanvas.filename, GLOBALS.paintCanvas.baseDir, display.actualContentWidth, display.actualContentHeight)
  actualPaintCanvas.x = display.contentCenterX
  actualPaintCanvas.y = display.contentCenterY
  
  GLOBALS.paintCanvas:invalidate()
  
  -- now do a "late initialization" on players (some things should be created AFTER the paintCanvas)
  for i=1,numPlayers do
    GLOBALS.players[i]:lateInitialization()
  end
  
  -------
  -- BALL
  -- initialize "balls" array, starting with one (the default center ball)
  -------
  GLOBALS.ballID = 0
  GLOBALS.balls = {}
  Ball(scene)
  
  ------
  -- GAME SETTINGS
  -- (such as: powerups currently in play)
  ------
  GLOBALS.gameSettings = {
      ropeChains = false,
      vibration = false,
      circlingEnabled = false,
      slicingEnabled = false,
  }
  
  ------
  -- POWERUPS
  -- (if powerups are enabled, start the powerup manager)
  ------
  GLOBALS.allPowerups = {
    'extraInk',
    'obstacleSquare',
    'obstacleCircle',
    'bomb',
    'bombSpecial',
    'ballSizeIncrease',
    'ballSizeDecrease',
    'extraBall',
    'speedupTime',
    'slowdownTime',
    'circleMechanic',
    'sliceMechanic',
    'penaltyInk',
    'secondGoal',
    'freePoint',
    'goalDisabler', 
    'freezer',
    'forcedStart',
    'reverseControls',
    'shield'
  }
  
  -- if the user chose to disable powerups, just empty the array of powerups
  local saveData = GLOBALS.loadTable('save_data.json')
  if not GLOBALS.powerupsAreEnabled or GLOBALS.simulationMode then
    GLOBALS.gameSettings.powerupsEnabled = {}
  else
    local unlockedPowerups = saveData.unlockedPowerups
    GLOBALS.gameSettings.powerupsEnabled = unlockedPowerups
    
    -- if we're in DEBUGGING mode, we enable ALL powerups automatically
    if GLOBALS.debuggingMode then
      --GLOBALS.gameSettings.powerupsEnabled = {'speedupTime', 'slowdownTime'}
      GLOBALS.gameSettings.powerupsEnabled = GLOBALS.allPowerups
    end
  end
  
  -- check if CIRCLE or SLICE mechanic are enabled
  local pe = GLOBALS.gameSettings.powerupsEnabled
  for i=#pe,1,-1 do
    if pe[i] == 'circleMechanic' then
      table.remove(pe, i)
      GLOBALS.gameSettings.circlingEnabled = true
    elseif pe[i] == 'sliceMechanic' then
      table.remove(pe, i)
      GLOBALS.gameSettings.slicingEnabled = true
    end
  end
  
  -- save vibration settings
  GLOBALS.gameSettings.vibration = saveData.vibration
  
  ----------
  -- Initialize Powerup Manager
  -- (even if we don't have powerups, as we need some helper functions in all game modes)
  -- (nevertheless, we do need to tell the powerup manager if it should be active or not, that's the second parameter)
  ----------
  GLOBALS.powerupManager = PowerupManager(scene, (#GLOBALS.gameSettings.powerupsEnabled >= 1))
  
  
  -----------
  -- If simulation is enabled ...
  --  => create the object
  --  => initialize
  ------------
  if GLOBALS.simulationMode then
    local sim = Simulation()
  end
  
  ---------
  -- Finally, pause the game
  -- (Because, each game starts with a slight delay/countdown)
  ---------
  GLOBALS.pauseGame()
  
  -- if tutorial is enabled, show that animation before doing anything else
  local tutorialEnabled = (saveData.numGamesPlayed <= 0)
  if tutorialEnabled then
    local tutSheetOptions = {
      width = 320,
      height = 480,
      numFrames = 4,
      
      sheetContentWidth = 320*4,
      sheetContentHeight = 480
    }
    local tutSheet = graphics.newImageSheet( "assets/textures/tutorialSpritesheet.png", tutSheetOptions )
    
    local tutSequence = {
      name = "default",
      start = 1,
      count = 5,
      time = 4*7000,
      loopCount = 1,
    }
    
    local tutImg = display.newSprite(sceneGroup, tutSheet, tutSequence)
    tutImg.x = display.contentCenterX
    tutImg.y = display.contentCenterY
    
    tutImg:setSequence("default")
    tutImg:play()
    
    tutImg:addEventListener( "sprite", scene.tutorialListener )
  else
    scene:startCountdown()
  end
end

function scene.tutorialListener(event)
  local obj = event.target
  
  -- if tutorial animation is done, remove tutorial image, start actual countdown
  if event.phase == "ended" then
    obj:removeSelf()
    scene:startCountdown()
  end
end

function scene:startCountdown()
  local countdownOptions = {
    parent = scene.view,
    text = '4',
    font = GLOBALS.mainFont,
    fontSize = 128,
    x = display.contentCenterX,
    y = display.contentCenterY
  }
  
  -- NOTE: in debugging mode, we don't want this countdown
  if GLOBALS.debuggingMode then
    countdownOptions.text = '1'
  end
  
  local countdownText = display.newText(countdownOptions)
  countdownText.fill = {0,0,0}  
  
  -- also create player field/area indicators
  -- (and save it on the countdown text, so we can remove these when we remove the countdown text
  local rad = 70
  local playerIndicators = {}
  local angleOffset = 0.5*math.pi
  if GLOBALS.playerCount == 4 then angleOffset = 0.25*math.pi end
  
  for i=1,GLOBALS.playerCount do
    local newIndicator = display.newImageRect(scene.view, 'assets/textures/playerIndicator-' .. tostring(i) .. '.png', 80, 80)
    
    local angle = angleOffset + (i-1)*2*math.pi / GLOBALS.playerCount
    newIndicator.x = display.contentCenterX + math.cos(angle)*rad
    newIndicator.y = display.contentCenterY + math.sin(angle)*rad
    
    newIndicator.rotation = math.deg(angle - 0.5*math.pi)
    newIndicator.alpha = 1.0
    
    table.insert(playerIndicators, newIndicator)
  end
  
  countdownText.playerIndicators = playerIndicators
  
  -- finally start the countdown
  scene:continueCountdown(countdownText)
end

function scene:continueCountdown(obj)
  local txt = obj
  local newNum = tonumber(txt.text) - 1
  
  -- if this was the last number, stop counting down and start the game!
  if newNum <= 0 then
    obj:removeSelf()
    
    for i=1,#obj.playerIndicators do
      obj.playerIndicators[i]:removeSelf()
    end
    
    GLOBALS.unPauseGame()
    return
  end
  
  -- if we're at the LAST number, already start fading the player indicators
  if newNum == 1 then
    for i=1,#obj.playerIndicators do
      transition.to(obj.playerIndicators[i], { alpha = 0.0, time = 900 })
    end
  end
    
  
  -- subtract one from number
  txt.text = newNum
  txt.alpha = 1.0
  txt.xScale = 1.0
  txt.yScale = 1.0
  
  -- create scale/fade transition
  transition.to(txt, { alpha = 0.0, xScale = 0.01, yScale = 0.01, time = 1000, onComplete = function(event) scene:continueCountdown(event) end })
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if event.phase == "will" then

	elseif phase == "did" then

	end	
	
end

function scene:destroy( event )
	local sceneGroup = self.view
  
  -- stop all timers
  transition.cancel()
  timer.cancel()
  
  -- stop physics; nil reference
  physics.stop()
  physics = nil
  
  -- go through all players and properly destroy them
  for i=1,GLOBALS.playerCount do
    GLOBALS.players[i]:destroy()
  end
  
  -- destroy ball(s)
  -- TO DO: Look into why some balls aren't properly destroyed??
  for i=1,#GLOBALS.balls do
    local b = GLOBALS.balls[i]
    if b then
      b:destroy()
    end
  end
  
  -- destroy powerup manager
  if GLOBALS.powerupManager then
    GLOBALS.powerupManager:destroy()
  end
  
  -- nil all references
  GLOBALS.players = nil
  GLOBALS.balls = nil
  GLOBALS.sim = nil
  GLOBALS.powerupManager = nil
  GLOBALS.reverseControls = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene