-----------------------------------------------------------------------------------------
--
-- powerup_manager.lua
--
-----------------------------------------------------------------------------------------

PowerupManager = Object:extend()

local powerupLibrary = require("tools.powerup_library")

function table.hasValue(tbl, v)
  for i=1,#tbl do
    if tbl[i] == v then
      return true
    end
  end
  return false
end

function PowerupManager:planNextPowerup()
  local randDelay = (1 + math.random()*5) / GLOBALS.gameSpeed
  
  self.powerupTimer = timer.performWithDelay(randDelay * 1000, function() self:placePowerup() end)
end

function PowerupManager:placePowerup()
  -- if we already have enough powerups, ignore this event and plan the next check
  if self.numPowerups >= self.maxPowerups then
    self:planNextPowerup()
    return
  end
  
  -- if the game is paused, ignore this event and plan next check
  if GLOBALS.paused then
    self:planNextPowerup()
    return
  end
  
  -- determine random type and location
  -- (we don't want powerups too close to each other; so keep trying until we find something that works
  local edgeMargin = 20 -- stay a certain number of pixels from the edge
  local randX, randY = 0,0
  local tooClose = true
  local distanceLimit = 100
  
  while tooClose do
    randX = math.random() * (display.actualContentWidth - 2*edgeMargin) + display.screenOriginX + edgeMargin
    randY = math.random() * (display.actualContentHeight - 2*edgeMargin) + display.screenOriginY + edgeMargin
    
    tooClose = false
    for i=1,#self.allPowerups do
      if math.dist(randX - self.allPowerups[i].x, randY - self.allPowerups[i].y) <= distanceLimit then
        tooClose = true
        break
      end
    end
    
    -- we also don't want to be too close to the ball
    -- ONLY DO THIS FOR THE FIRST BALL (too expensive to loop through all balls each time)
    -- otherwise it might grab the powerup before we even see it!
    local b = GLOBALS.balls[1].sprite
    if math.dist(randX - b.x, randY - b.y) <= distanceLimit then
      tooClose = true
    end
  end
  
  -- get a random powerup type
  -- different powerups have different probabilities, how do we take those into account?
  -- shuffle array, then check for each type individually if it matches probability
  GLOBALS.gameSettings.powerupsEnabled = table.shuffle(GLOBALS.gameSettings.powerupsEnabled)
  local powerupType = nil
  local tempCounter = 1
  local numPowerups = #GLOBALS.gameSettings.powerupsEnabled
  
  -- create table of existing powerups
  local powerupsOnField = {}
  for i=1,#self.allPowerups do
    table.insert(powerupsOnField, self.allPowerups[i].powerupType)
  end
  
  local numTries = 0
  local possiblePowerup = nil
  while not powerupType do
    -- check if current powerup probability is met
    -- ALSO check if current powerup already exists or not
    -- (we divide by the number of powerups to make this a proper probability distribution)
    -- (otherwise, even something with a very low probability will be picked if it's one of the first elements)
    local curPU = GLOBALS.gameSettings.powerupsEnabled[tempCounter]
    if not table.hasValue(powerupsOnField, curPU) then
      possiblePowerup = curPU
      if math.random() <= (powerupLibrary[curPU].prob / numPowerups) then
        powerupType = curPU
        break
      end
    end
    
    -- update + wrap counter
    tempCounter = tempCounter + 1
    numTries = numTries + 1
    if tempCounter > numPowerups then tempCounter = 1 end
    
    -- if we've tried too many times, just exit with current state
    -- (this prevents loops that take too long, and especially infinte loops)
    if numTries >= 100 then
      print("ERROR! Exceeded maximum number of tries (when placing new powerup)")
      if possiblePowerup then
        powerupType = possiblePowerup
      else
        powerupType = curPU
      end
    end
  end
  
  -- start the transition/animation
  -- (this SIGNALS the player that something is coming here, so they have time to react)
  local animDuration = 1000 / GLOBALS.gameSpeed
  local circ = display.newCircle(self.sceneGroup, randX, randY, 0)
  circ.fill = { 0.5,0.5,0.5 }
  circ.alpha = 0.0
  circ.powerupType = powerupType
  transition.to(circ.path, { radius = 40, time = (animDuration-100) }) 
  transition.to(circ, { alpha = 1.0, time = animDuration, onComplete = function(obj) self:finishPlacingPowerup(obj) end })
end

function PowerupManager:intersectWithPowerups(player, pos)
  for i=1,#self.allPowerups do
    local p = self.allPowerups[i]
    local dist = math.dist(pos.x - p.x, pos.y - p.y)
    
    -- powerup must be within radius of line
    -- there are also certain powerups that can NOT be sliced (such as the second goal)
    if dist <= p.myRadius and p.powerupType ~= 'secondGoal' then
      player:saveSlicedPowerup(p)
    end
  end
end
      

function PowerupManager.onLocalCollision(self, event)
  local o = event.other
  local p = event.phase
  local c = self.myParent

  if p == 'began' then
    -- if this object belongs to a certain player ...
    if o.myPlayer then
      -- save this powerup on the player
      GLOBALS.players[o.myPlayer]:saveSlicedPowerup(self)
    end
  end
  
end

function PowerupManager:finishPlacingPowerup(obj)
  local powerupType = obj.powerupType
  local powerupSize = 40
  
  -- create the new powerup
  -- (use default imageSheet for all powerups, grab frame from powerupLibrary)
  local pu = display.newImageRect(self.sceneGroup, self.imageSheet, powerupLibrary[powerupType].frame, 128, 128)
  pu.x = obj.x
  pu.y = obj.y
  pu:scale(powerupSize / 128, powerupSize / 128)
  pu.rotation = math.random()*360
  
  -- turn into physics body
  physics.addBody(pu, 'static', { isSensor = true, radius = 0.5*powerupSize })
  pu.myRadius = 0.5*powerupSize
  
  -- give some properties
  pu.isPowerup = true
  pu.powerupType = powerupType
  
  if powerupType == 'obstacleSquare' or powerupType == 'obstacleCircle' then
    pu.isSensor = false

    if powerupType == 'obstacleSquare' then
      pu.radius = nil
    end
  end
  
  -- a second goal must be registered as a goal (in all possible ways)
  -- and figure out which player it belongs to
  if powerupType == 'secondGoal' then
    pu.isGoal = true
    pu.playerNum = self:findPowerupArea(pu)
    
    -- YES! Already plan to remove this powerup in 10 seconds
    timer.performWithDelay(10000, function() self:removePowerup(pu) end)
    
    -- NO! If we add a goalObject, it will disappear when someone draws a new line
    --GLOBALS.players[pu.playerNum]:addGoalObject(pu)
  end
  
  -- a goal disabler works on the current area, not who last touched the ball before it hit the powerup
  -- same with the freezer
  -- and the shield (??)
  local areaPowerups = {'goalDisabler', 'freezer', 'shield', 'forcedStart', 'bombSpecial'}
  if table.hasValue(areaPowerups, powerupType) then
    pu.myArea = self:findPowerupArea(pu)
  end
  
  -- if a forced start was created, we immediately inform the player that "owns" it
  if powerupType == 'forcedStart' then
    GLOBALS.players[pu.myArea]:addForcedStart(pu)
    
    -- Already plan to remove this powerup in 10 seconds
    pu.myRemovalTimer = timer.performWithDelay(10000, function() self:removePowerup(pu) end)
  end
  
  -- increment powerups ID 
  -- (so we can uniquely identify/remove powerups when needed)
  self.id = self.id + 1
  pu.id = self.id
  
  -- insert powerup into table
  table.insert(self.allPowerups, pu)
  
  -- remember we placed this
  self.numPowerups = self.numPowerups + 1
  
  -- remove the sprite we used to "animate" our arrival
  obj:removeSelf()
  
  -- and already plan the next powerup
  self:planNextPowerup()
end

function PowerupManager:removePowerup(obj)
  -- it's possible that the same object wants to be removed multiple times in a physics update
  -- so check for that, and don't allow it
  if not obj or not obj.removeSelf then
    return 
  end
  
  -- also remove any timer, if it's connected
  if obj.myRemovalTimer then
    timer.cancel(obj.myRemovalTimer)
  end
  
  -- if it's a forced start, inform the player
  if obj.powerupType == 'forcedStart' then
    GLOBALS.players[obj.myArea]:removeForcedStart()
  end
  
  -- remove object from display list
  obj:removeSelf()
  
  -- remove object from array
  for i=1,#self.allPowerups do
    if self.allPowerups[i].id == obj.id then
      table.remove(self.allPowerups, i)
      break
    end
  end

  -- update counter
  self.numPowerups = self.numPowerups - 1 
end

function PowerupManager:startReverseControls(pu)
  -- to ensure we don't get double timers with double reverse controls,
  -- first remove the old one
  if self.reverseControlTimer then
    timer.cancel(self.reverseControlTimer)
    self:stopReverseControls(self.reverseControlObject)
  end
  
  GLOBALS.reverseControls = true
    
  for i=1,GLOBALS.playerCount do
    GLOBALS.players[i]:addStatusIcon(pu)
  end

  self.reverseControlObject = pu
  self.reverseControlTimer = timer.performWithDelay(10000, function() self:stopReverseControls(pu) end)
end

function PowerupManager:stopReverseControls(pu)
  GLOBALS.reverseControls = false
  
  for i=1,GLOBALS.playerCount do
    GLOBALS.players[i]:removeStatusIcon(pu)
  end
  
  self.reverseControlTimer = nil
end

function PowerupManager:collectPowerup(c, o)
  -- do the appropriate action!
  local t = o.powerupType
  
  if c.lastPlayerHit then
    local pl = GLOBALS.players[c.lastPlayerHit]
    if t == 'extraInk' then
      pl:updateInk(20)
    elseif t == 'penaltyInk' then
      pl:updateInk(-20)
    elseif t == 'bomb' then
      pl:updatePoints(-1)
    elseif t == 'speedupTime' then
      c:changeGameSpeed(2)
    elseif t == 'slowdownTime' then
      c:changeGameSpeed(0.5)
    elseif t == 'freePoint' then
      pl:updatePoints(1)
    end
  end
  
  local connectedPlayer = nil
  if o.myArea then
    connectedPlayer = GLOBALS.players[o.myArea]
  end
  
  -- these powerups don't need to access the "last player hit" variable
  if t == 'ballSizeIncrease' then
    timer.performWithDelay(1, function() c:changeSize(1.5) end)
  elseif t == 'ballSizeDecrease' then
    timer.performWithDelay(1, function() c:changeSize(0.75) end)
  elseif t == 'extraBall' then
    timer.performWithDelay(1, function() c:addBall() end)
  elseif t == 'bombSpecial' then
    -- a special bomb damages the player _in whose area it resides_
    connectedPlayer:updatePoints(-1)
  elseif t == 'goalDisabler' then
    connectedPlayer:addGoalDisabler()
  elseif t == 'freezer' then
    connectedPlayer:freeze(o)
  elseif t == 'forcedStart' then
    connectedPlayer:removeForcedStart()
  elseif t == 'reverseControls' then
    self:startReverseControls(o)
  elseif t == 'shield' then
    connectedPlayer:addShield(o)
  end
  
  -- remove the powerup (next frame; can't within physics call)
  timer.performWithDelay(1, function() self:removePowerup(o) end)
  
  -- create particles
  local emitter = display.newEmitter( require("particles.test") )
  self.sceneGroup:insert(emitter)
  emitter.x = o.x
  emitter.y = o.y
  
  -- play sound effect
  -- (just use the maximum channel for this)
  if not GLOBALS.simulationMode then
    local audioFileName = "powerup"
    local channel, source = audio.play( GLOBALS.audioFiles[audioFileName], { channel = 32 })
    al.Source(source, al.PITCH, math.random()*0.2 + 0.9)
  end
end

function PowerupManager:findPowerupArea(o)
  for i=1,#GLOBALS.players do
    local tempP = GLOBALS.players[i]
    if tempP:eventWithinBounds(o) then
      return i
    end
  end
end

function PowerupManager:checkIfWithinCircle(c, r)
  print("Checking circle ", c[1], c[2], r)
  
  for i=1,#self.allPowerups do
    local p = self.allPowerups[i]
    local dist = math.dist(p.x - c[1], p.y - c[2])
    
    -- if the center of the powerup is within radius of the center of the circle, collect it!
    -- (which is just a guesstimate/heuristic for when a powerup is "within" the drawn circle)
    -- NOTE: We simply pass in the first ball that's available, to "pretend" this was the ball that hit it
    if dist <= r then
      self:collectPowerup(GLOBALS.balls[1], p)
    end
  end
end

function PowerupManager:checkIfSliced(p)
  local pus = p.slicedPowerups
  
  -- it is possible that a powerup is already sliced by ANOTHER player simultaneously
  -- so, first check which powerups still exist
  for k,v in pairs(pus) do
    if not v.removeSelf then
      pus[k] = nil
    end
  end
  
  -- go through all sliced powerups ...
  for k,v in pairs(pus) do
    -- merely colliding with the powerup isn't enough, we also need
    -- 1) Two points on DIFFERENT sides of the object (at least two different quadrants must be used)
    -- 2) At least one point that is OUTSIDE the powerup bounds (distance >= radius)
    local radiusCheckPassed = false
    local directionCheckPassed = false
    local numQuadrantsUsed = 0
    local quadrants = {false, false, false, false}

    for i=1,#p.joints,2 do
      local dX, dY = (p.joints[i] - v.x), (p.joints[i+1] - v.y)
      local dist = math.dist(dX, dY)
      if dist > v.myRadius then
        radiusCheckPassed = true
      end
      
      local angle = math.atan2(dY, dX)
      if angle < 0 then angle = angle + 2*math.pi end
      local angleIndex = math.floor(angle / (2*math.pi) * 4)+1
      
      if not quadrants[angleIndex] then 
        numQuadrantsUsed = numQuadrantsUsed + 1 
      end
      
      quadrants[angleIndex] = true 
    end
    if numQuadrantsUsed >= 2 then directionCheckPassed = true end
    
    if radiusCheckPassed and directionCheckPassed then
      -- some powerups have an automatic effect, thus must be disabled manually
      -- NO: Creates weird issues in simulation, because computer players don't know about powerups.
      --[[
      if v.powerupType == 'forcedStart' then
        GLOBALS.players[v.myArea]:removeForcedStart()
      end
      --]]
      
      -- slicing REMOVES the powerup, without triggering its effect
      -- (some powerups, such as forcedStart, can not be sliced)
      if v.powerupType ~= 'forcedStart' then
        self:removePowerup(v)
      end
    end
  end
end


function PowerupManager:destroy()
  if self.powerupTimer then
    timer.cancel(self.powerupTimer)
  end
end

function PowerupManager:new(scene, powerupsEnabled)
  self.sceneGroup = scene.view
  
  self.allPowerups = {}
  self.numPowerups = 0
  self.maxPowerups = 3
  
  self.id = 0
  
  print("Does the manager think powerups are enabled?", powerupsEnabled)
  -- if powerups are not enabled, then just never plan the first powerup and return here
  if not powerupsEnabled then
    return
  end
  
  self.imageSheet = require("tools.powerup_sheet")

  -- plan the first powerup
  self.powerupTimer = nil
  self:planNextPowerup()
  
  return self
end