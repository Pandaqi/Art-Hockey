-----------------------------------------------------------------------------------------
--
-- ball.lua
--
-----------------------------------------------------------------------------------------

Ball = Object:extend()

function math.dist(x, y)
  return math.sqrt(x*x + y*y)
end

function Ball:enterFrame() 
  -- if game is paused, ignore all this
  if GLOBALS.paused then return end
  
  if not self.sprite or not self.sprite.removeSelf then
    self:destroy()
    return
  end
  
  -- if ball is flickering, don't move it in any way (and keep constant scale)
  if self.isFlickering then
    self.sprite.xScale = (2*self.sprite.radius / 128)
    self.sprite.yScale = (2*self.sprite.radius / 128)
    
    self.sprite:setLinearVelocity(0,0)
    return
  end
  
  ----------
  -- Velocity manipulation
  --   (max speed, min speed)
  ----------

  -- cap velocity at a maximum speed
  -- (get current speed, normalize to unit vector, multiply by capped speed)
  -- do the same for minimum speed
  local vx, vy = self.sprite:getLinearVelocity()
  
  -- never allow velocities of zero
  -- because we can't divide by zero later on
  if vx == 0 then vx = 2.0 end
  if vy == 0 then vy = 2.0 end
  
  vx = vx / GLOBALS.gameSpeed
  vy = vy / GLOBALS.gameSpeed
  
  local damping = 1.0 -- 0.99
  local curSpeed = math.dist(vx, vy) * damping
  
  local desiredSpeed = math.max( math.min(curSpeed, self.maxSpeed), self.minSpeed)
  
  local newX = vx / curSpeed * desiredSpeed
  local newY = vy / curSpeed * desiredSpeed
  
  -- if the x or y-velocity is (nearly) zero, bump it up a bit
  -- this prevents stalemates/flat movement from the ball
  if math.abs(newX) < 30 then newX = 30 * newX/math.abs(newX) end
  if math.abs(newY) < 60 then newY = 60 * newY/math.abs(newY) end
  
  self.sprite:setLinearVelocity(newX * GLOBALS.gameSpeed, newY * GLOBALS.gameSpeed)
  
  -- rotate ball into movement direction
  self.sprite.rotation = math.deg( math.atan2(newY, newX) )
  
  -- SQUISH/LENGTHEN ball based on speed
  -- (interpolate between current y scale and wanted y scale)
  local squishFactor = 1.0 + 0.5 * (desiredSpeed/self.maxSpeed)
  local wantedXScale = (2*self.sprite.radius / 128) * squishFactor
  local wantedYScale = (2*self.sprite.radius / 128) * 0.90
  local curXScale = self.sprite.xScale
  
  local t = 0.75 -- "how much percent we should keep to the old scale"
  self.sprite.xScale = curXScale*t + (1-t)*wantedXScale
  self.sprite.yScale = self.sprite.yScale*t + (1-t)*wantedYScale
  
  -- make sure particles follow the ball
  self.trailParticles.x = self.sprite.x
  self.trailParticles.y = self.sprite.y
end

function Ball:setRandomVelocity()
  local randAngle = math.random()*2*math.pi
  local speed = 115 * GLOBALS.gameSpeed
  
  -- if a ball is destroyed during its flickering animation,
  -- it will not exist when we call this thing
  -- so back out of here!
  if not self.sprite or not self.sprite.removeSelf then
    return
  end
  
  self.sprite:setLinearVelocity(math.cos(randAngle)*speed, math.sin(randAngle)*speed)
  
  self.isFlickering = false
end

function Ball.onLocalCollision(self, event)
  local o = event.other
  local p = event.phase
  local c = self.myParent
  
  if c.planningToReset then
    return
  end
  
  -- if we hit something that is SOLID
  if not o.isSensor then
    local squishFactor = 0.2
    self.xScale = (2*self.radius / 128) * squishFactor
    self.yScale = (2*self.radius / 128) * 1.5
    
    if not o.isGoal and not GLOBALS.simulationMode then
      -- play sound effect
      local audioFileName = "bounce"
      local channel, source = audio.play( GLOBALS.audioFiles[audioFileName], { channel = (5+c.id) })
      al.Source(source, al.PITCH, math.random()*0.2 + 0.9)
    end
  end
  
  if p == 'ended' then
    -- if this object has a player attached (a LINE)
    if o.myPlayer then
      c.lastPlayerHit = o.myPlayer
      c:updateBallColor()
      
      -- let the player remember how many times it hit the ball
      GLOBALS.players[o.myPlayer]:updateBallTouches(1)
    end
  end
  
  if p == 'began' then
    -- if the ball ENTERS a GOAL body ...
    if o.isGoal then
      local playerNum = o.playerNum
      local curPlayer = GLOBALS.players[playerNum]
      
      -- in game modes 2 and 3, the shield does something different
      -- (because, "passing" through goals is a bit impossible, as goals are at the edge)
      if curPlayer:isShieldActive() then
        if GLOBALS.gameMode ~= 1 then
          timer.performWithDelay(1, function() c:invertBall() end)
        end
      end
      
      -- check if this player has a shield active; only react if a shield is NOT active
      if not GLOBALS.players[playerNum]:isShieldActive() then
        c.planningToReset = true
        
        -- remember we scored against that player
        timer.performWithDelay(1, function() c:scoredAgainstPlayer(playerNum) end)
        
        -- in SIMULATION mode, we don't splash ink nor play sounds
        if not GLOBALS.simulationMode then
          -- randomly splash ink blobs against a background canvas
          local numBlobs = math.random(2,10)
          local range = 16
          for i=1,numBlobs do
            local randSize = math.random(8, 32)
            local randType = math.random(4)
            local b = display.newImageRect('particles/paintBlob' .. randType .. '.png', randSize, randSize)
            b:setFillColor( math.random()*0.3 + 0.7, math.random()*0.3+0.7, math.random()*0.3+0.7 )
            
            -- in game mode 1, we splash particles around the goal
            -- otherwise we splash the particles around the ball, because the object we're hitting is NOT centered nicely
            if GLOBALS.gameMode == 1 then
              b.x = o.x
              b.y = o.y
            else
              b.x = self.x
              b.y = self.y
            end
              
            b.x = b.x - display.contentCenterX + math.random(-range, range)
            b.y = b.y - display.contentCenterY + math.random(-range, range)
            b.rotation = math.random(360)
            b.alpha = 1.0
            
            -- plan "fade in"
            timer.performWithDelay(math.random(0,200), function() GLOBALS.paintCanvas:draw(b) GLOBALS.paintCanvas:invalidate() end)
            
            -- plan "fade out"
            timer.performWithDelay(2000, function() b.alpha = 0.0 GLOBALS.paintCanvas:invalidate() end)
          end
        
          -- play sound effect
          -- (just use one of the maximum channels for this)
          local audioFileName = "score"
          local channel, source = audio.play( GLOBALS.audioFiles[audioFileName], { channel = 31 })
          al.Source(source, al.PITCH, math.random()*0.2 + 0.9)
        
        -- if we ARE in simulation mode ...
        else
          -- only count goals we scored ourselves (not those scored by noone)
          -- and keep track of own goals
          if c.lastPlayerHit then
            if c.lastPlayerHit == o.playerNum then
              GLOBALS.players[o.playerNum].ownGoals = GLOBALS.players[o.playerNum].ownGoals + 1
            else
              GLOBALS.players[c.lastPlayerHit].goodGoals = GLOBALS.players[c.lastPlayerHit].goodGoals + 1
            end
          end
        end
        
        
        --[[
        -- instantiate particle effect (at goal)
        local explosionParticles = display.newEmitter( require("particles.explosion") )
        c.sceneGroup:insert(explosionParticles)
        
        explosionParticles.x = o.x
        explosionParticles.y = o.y
        --]]
      end
      
    -- if the ball enters a POWERUP, take the appropriate action!
    elseif o.isPowerup then
      GLOBALS.powerupManager:collectPowerup(c, o)
    end
  end
  
  
end

function Ball:addBall()
  -- bit of a weird function this
  -- but it simply adds a new ball (which registers itself automatically in the global balls array)
  Ball(self.scene)
end

function Ball:updateBallColor()
  -- if no color to set, delete effect
  if not self.lastPlayerHit then
    self.sprite.fill.effect = nil
    return
  end
  
  -- change our modulate?
  local touchFills = { {0.5,0.1,0.1}, {0.1,0.1,0.5}, {0.1,0.5,0.1}, {0.5,0.1,0.5} }
  self.sprite.fill.effect = "filter.duotone"
  self.sprite.fill.effect.darkColor = touchFills[self.lastPlayerHit]
  self.sprite.fill.effect.lightColor = {1,1,1}
end

function Ball:invertBall()
  local vx, vy = self.sprite:getLinearVelocity()
  self.sprite:setLinearVelocity(-vx, -vy)
end

function Ball:changeGameSpeed(ds)
  local minSpeed = 0.25
  local maxSpeed = 4
  
  GLOBALS.gameSpeed = math.max( math.min(maxSpeed, GLOBALS.gameSpeed * ds), minSpeed )
  
  -- TO DO: Perform some immediate changes?
  -- Now, most of the changes will only go into effect within a few seconds (when a new powerup appears, or the ball is sped up, or whatever)
end
  

function Ball:scoredAgainstPlayer(i)
  local gameOver = false

  -- vibrate the phone!
  if GLOBALS.gameSettings.vibration then
    system.vibrate()
  end
  
  -- display GOAL! text
  -- (and animate it to pop up, then fade out, then remove itself)
  local vx, vy = self.sprite:getLinearVelocity()
  local goalFeedback = display.newImageRect(self.sceneGroup, 'assets/textures/goalFeedback.png', 112, 80)
  goalFeedback.x = self.sprite.x
  goalFeedback.y = self.sprite.y
  goalFeedback:scale(0.01, 0.01)
  goalFeedback.rotation = math.deg( math.atan2(vy, vx) + 0.5*math.pi)
  
  transition.to(goalFeedback, { xScale = 1, yScale = 1, time = 500, transition = easing.outElastic })
  transition.to(goalFeedback, { alpha = 0, time = 500, delay = 1000, onComplete = function(obj) obj:removeSelf() end }) 
  
  
  -- award points to the player who last HIT the ball
  -- (if that was the player itself, go through to next case)
  if self.lastPlayerHit and self.lastPlayerHit ~= i then
    gameOver = GLOBALS.players[self.lastPlayerHit]:updatePoints(1)
  
  else
    -- otherwise, award points to ALL players (except the one scored against)
    for p=1,GLOBALS.playerCount do
      local pp = GLOBALS.players[p]
      if p ~= i then
        gameOver = pp:updatePoints(1)
        if gameOver then break end
      end
    end
  end
  
  -- if someone had enough points (after updating), the game is OVER!)
  -- (don't examine this function any further; the player:updatePoints() function actually handles moving to game_over scene)
  if gameOver then return end
  
  -- make player scored against CONCEDE a goal
  GLOBALS.players[i]:concedeGoal()
  
  -- if there are multiple balls, simply destroy this one
  if #GLOBALS.balls > 1 then
    self:destroy()
  
  -- otherwise, if this is the LAST remaining ball, reset it to the center of the field
  else
    -- change this ball's size back to normal)
    self:changeSize(-1)
  
    -- reset to center of field
    self:reset()
  end
end

function Ball:changeSize(ds)  
  -- determine new size
  local curRadius = self.sprite.radius
  local newRadius = math.max(math.min(curRadius * ds, self.maxRadius), self.minRadius)
  
  -- the value -1 means a hard reset
  if ds == -1 then newRadius = 10 end
  
  local oldX = self.sprite.x
  local oldY = self.sprite.y
  local oldvx, oldvy = self.sprite:getLinearVelocity()
  
  -- destroy current ball
  self.sprite:removeSelf()
  
  -- instantiate new ball
  self:createSprite(newRadius, oldX, oldY, oldvx, oldvy)
end

function Ball:reset(x,y)
  x = x or display.contentCenterX
  y = y or display.contentCenterY
  
  -- reset ball to center
  self.sprite.x = x
  self.sprite.y = y
  
  -- reset particles to be underneath ball
  self.trailParticles.x = x
  self.trailParticles.y = y
  
  -- reset last player hit
  self.lastPlayerHit = nil
  self.sprite.fill.effect = nil
  self.planningToReset = false
  
  -- reset game speed
  -- (EXPERIMENTAL: Might help, might be annoying.)
  if not GLOBALS.simulationMode then
    GLOBALS.gameSpeed = 1
    
    -- stop any linear velocity
    self.isFlickering = true
    
    -- if this is the very first reset (start of the game), we don't want the flickering animation)
    if self.firstReset then
      self.firstReset = false
      self:setRandomVelocity()
    
    else
      -- plan a flickering animation; once it ends, the ball regains velocity again
      local flickerTime = 200
      transition.to(self.sprite, { alpha = 0.0, time = flickerTime })
      transition.to(self.sprite, { alpha = 1.0, time = flickerTime, delay = flickerTime })
      transition.to(self.sprite, { alpha = 0.0, time = flickerTime, delay = 2*flickerTime })
      transition.to(self.sprite, { alpha = 1.0, time = flickerTime, delay = 3*flickerTime })
      transition.to(self.sprite, { alpha = 0.0, time = flickerTime, delay = 4*flickerTime })
      transition.to(self.sprite, { alpha = 1.0, time = flickerTime, delay = 5*flickerTime })
      transition.to(self.sprite, { alpha = 0.0, time = flickerTime, delay = 6*flickerTime })
      transition.to(self.sprite, { alpha = 1.0, time = flickerTime, delay = 7*flickerTime })
      transition.to(self.sprite, { alpha = 0.0, time = flickerTime, delay = 8*flickerTime })
      transition.to(self.sprite, { alpha = 1.0, time = flickerTime, delay = 9*flickerTime, onComplete = function() self:setRandomVelocity() end })
    end
  else
    -- if we ARE in simulation mode, just set random velocity and start immediately
    -- (NO TIME TO WASTE!)
    self.firstReset = false
    self:setRandomVelocity()
  end
end

function Ball:createSprite(radius, x, y, vx, vy)
  radius = radius or 10
  x = x or display.contentCenterX
  y = y or display.contentCenterY
  vx = vx or 0
  vy = vy or 0
  
  -- create sprite
  self.sprite = display.newSprite(self.sceneGroup, self.imageSheet, self.sequenceData)
  self.sprite.x = x
  self.sprite.y = y
  self.sprite:scale(2*radius / 128, 2*radius / 128)
  
  self.sprite:play("squiggle")
  self.sprite.radius = radius
  
  -- turn into physics body
  local bodyProperties = { density = 1.0, bounce = 1.5, friction = 0.0, radius = radius }
  physics.addBody(self.sprite, 'dynamic', bodyProperties)
  
  -- set physics body properties
  -- self.sprite.linearDamping = 0.2
  self.sprite.isFixedRotation = true
  self.sprite.myParent = self
    
  -- create collision event listener
  self.sprite.collision = self.onLocalCollision
  self.sprite:addEventListener("collision")
  
  -- set starting velocity
  self.sprite:setLinearVelocity(vx, vy)
  
  -- update ball color (if needed)
  self:updateBallColor()
end

function Ball:destroy()
  -- remove ourselves from the ball array
  -- (leaving no gaps)
  local indexInArray = -1
  for k,v in pairs(GLOBALS.balls) do
    if v.id == self.id then
      indexInArray = k
      table.remove(GLOBALS.balls, k)
      break
    end
  end
  
  if indexInArray == -1 then
    print("Couldn't find BALL in GLOBALS.balls array")
  end
  
  -- remove event listeners (collision + update)
  if self.sprite.removeSelf then
    self.sprite:removeEventListener("collision")
    self.sprite:removeSelf() -- destroy sprite
    self.sprite = nil
  end
  
  Runtime:removeEventListener("enterFrame", self.updateListener)
  
  -- destroy particle effect
  if self.trailParticles then
    if self.trailParticles.removeSelf then self.trailParticles:removeSelf() end
    self.trailParticles = nil
  end
end


function Ball:new(scene, x, y)
  self.scene = scene
  self.sceneGroup = scene.view
    
  -- add PARTICLES that will trail behind the ball
  self.trailParticles = display.newEmitter( require("particles.trailParticles") )
  self.sceneGroup:insert(self.trailParticles)
  
  self.maxRadius = 30
  self.minRadius = 5
  
  GLOBALS.ballID = GLOBALS.ballID + 1
  self.id = GLOBALS.ballID
  
  -- insert ourselves into balls array
  table.insert(GLOBALS.balls, self)
  
  -- create one image sheet
  local options =
  {
      width = 128,
      height = 128,
      numFrames = 4,
       
      sheetContentWidth = 128*4,  -- width of original 1x size of entire sheet
      sheetContentHeight = 128*1,   -- height of original 1x size of entire sheet
  }
  self.imageSheet = graphics.newImageSheet('assets/textures/ballSpritesheet.png', options)
  self.sequenceData = {
    {
        name = "squiggle",
        start = 1,
        count = 4,
        time = 500,
        loopCount = 0,
        loopDirection = "forward"
    }
  }
  
  
  -- actually create the sprite
  self:createSprite(10, x, y)
  
  self.minSpeed = 80
  self.maxSpeed = 450

  -- create update event listener
  self.updateListener = function() self:enterFrame() end
  Runtime:addEventListener("enterFrame", self.updateListener)
  
  -- some properties for powerups and stuff
  self.lastPlayerHit = nil
  self.planningToReset = false
  
  -- is this the first ball? Then perform exception: first reset
  if #GLOBALS.balls <= 1 then
    self.firstReset = true
  end
  
  -- by calling "reset", we immediately get the right position+velocity at the start
  self:reset(x, y)

  return self
end