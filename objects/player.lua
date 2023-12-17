-----------------------------------------------------------------------------------------
--
-- player.lua
--
-----------------------------------------------------------------------------------------

Player = Object:extend()

local json = require( "json" )
local defaultLocation = system.DocumentsDirectory

local composer = require( "composer" )

local touchFills = { {0.4,0,0}, {0,0,0.4}, {0,0.4,0}, {0.4,0,0.4} }
local touchAreaFills = { {0.9, 0.5, 0.5}, {0.5, 0.5, 0.9}, {0.5, 0.9, 0.5}, {0.9, 0.5, 0.9}   }

local cW, cH = display.contentWidth, display.contentHeight
local oX, oY = display.screenOriginX, display.screenOriginY
local cX, cY = display.contentCenterX, display.contentCenterY
local fullX, fullY = cW - oX, cH - oY
local aW, aH = display.actualContentWidth, display.actualContentHeight

local polyCircleRad = 0.5*aH/math.sin((1/6)*math.pi)

local wallSize = 20
local goalSize = 100
local cornerSize = 50

local playerSettings = {
  -- one player (not possible)
  {},
  
  -- two players
  {
    touchPolygons = {
      { x = cX, y = cY + 0.25*aH, vertices = {-0.5*aW,0, 0.5*aW,0, 0.5*aW,0.5*aH, -0.5*aW,0.5*aH} },
      { x = cX, y = cY - 0.25*aH, vertices = {-0.5*aW,-0.5*aH, 0.5*aW,-0.5*aH, 0.5*aW,0, -0.5*aW,0} }
    },
    
    rotations = {
      90,
      270
    },
    
    scoreText = {
      { x = 0, y = 70 },
      { x = 0, y = -70}
    },
    
    -- each player has LEFT wall, RIGHT wall, and two walls with a gap (the goal)
    -- additionally, both players have corners on the left and right
    walls = {
      -- player 1
      { 
        { x = oX, y = cY + 0.25*aH, width = wallSize, height = 0.5*aH },
        { x = fullX, y = cY + 0.25*aH, width = wallSize, height = 0.5*aH },
        { x = cX - 0.5*goalSize - 0.25*aW, y = fullY, width = 0.5*aW, height = wallSize },
        { x = cX + 0.5*goalSize + 0.25*aW , y = fullY, width = 0.5*aW, height = wallSize },
        { x = oX, y = fullY, width = cornerSize, height = cornerSize, rotation = 45 },
        { x = fullX, y = fullY, width = cornerSize, height = cornerSize, rotation = 45 }
      },
      
      -- player 2
      { 
        { x = oX, y = cY - 0.25*aH, width = wallSize, height = 0.5*aH },
        { x = fullX, y = cY - 0.25*aH, width = wallSize, height = 0.5*aH },
        { x = cX - 0.5*goalSize - 0.25*aW, y = oY, width = 0.5*aW, height = wallSize },
        { x = cX + 0.5*goalSize + 0.25*aW , y = oY, width = 0.5*aW, height = wallSize },
        { x = oX, y = oY, width = cornerSize, height = cornerSize, rotation = 45 },
        { x = fullX, y = oY, width = cornerSize, height = cornerSize, rotation = 45 }
      },
    },
    
    -- goals are physics bodies (isSensor = true) that register a goal if the ball crosses them
    goals = {
      { x = cX, y = fullY + 2*wallSize, width = goalSize, height = wallSize*4, rotation = 180 },
      { x = cX, y = oY - 2*wallSize, width = goalSize, height = wallSize*4, rotation = 0 },
    }
  },
  
  -- three players
  -- TO DO: Make cos, sin, pi and (1/6)*pi locals above? Should improve readability
  {
    touchPolygons = {
      { 
        x = cX, 
        y = cY + 0.25*aH, 
        vertices = {0,0, math.cos((1/6)*math.pi)*polyCircleRad,math.sin((1/6)*math.pi)*polyCircleRad, math.cos((5/6)*math.pi)*polyCircleRad,math.sin((5/6)*math.pi)*polyCircleRad} 
      }, 
      
      { 
        x = cX - 0.5*math.cos((1/6)*math.pi)*polyCircleRad, 
        y = cY - 0.5*math.sin((1/6)*math.pi)*polyCircleRad, 
        vertices = {0,0, math.cos((5/6)*math.pi)*polyCircleRad,math.sin((5/6)*math.pi)*polyCircleRad, math.cos((9/6)*math.pi)*polyCircleRad,math.sin((9/6)*math.pi)*polyCircleRad} 
      }, 

      { 
        x = cX + 0.5*math.cos((1/6)*math.pi)*polyCircleRad, 
        y = cY - 0.5*math.sin((1/6)*math.pi)*polyCircleRad, 
        vertices = {0,0, math.cos((9/6)*math.pi)*polyCircleRad,math.sin((9/6)*math.pi)*polyCircleRad, math.cos((13/6)*math.pi)*polyCircleRad,math.sin((13/6)*math.pi)*polyCircleRad} 
      },
    },
    
    scoreText = {
      { x = math.cos(0.5*math.pi)*70, y = math.sin(0.5*math.pi)*70 },
      { x = math.cos((7/6)*math.pi)*70, y = math.sin((7/6)*math.pi)*70 },
      { x = math.cos((11/6)*math.pi)*70, y = math.sin((11/6)*math.pi)*70 },
    },
    
    rotations = {
      90,
      210,
      330
    },
    
    walls = {
      -- player 1
      { 
        { x = oX, y = cY + 0.25*aH, width = wallSize, height = 0.5*aH },
        { x = fullX, y = cY + 0.25*aH, width = wallSize, height = 0.5*aH },
        { x = cX - 0.5*goalSize - 0.25*aW, y = fullY, width = 0.5*aW, height = wallSize },
        { x = cX + 0.5*goalSize + 0.25*aW , y = fullY, width = 0.5*aW, height = wallSize },
        { x = oX, y = fullY, width = cornerSize, height = cornerSize, rotation = 45 },
        { x = fullX, y = fullY, width = cornerSize, height = cornerSize, rotation = 45 }
      },
      
      -- player 2
      -- (only has the LEFT and TOP1 wall)
      { 
        { x = oX, y = cY - 0.25*aH + 0.33*goalSize, width = wallSize, height = 0.5*aH - 0.66*goalSize },
        { x = cX - 0.25*aW + 0.33*goalSize, y = oY, width = 0.5*aW - 0.66*goalSize, height = wallSize },
      },
      
      -- player 3
      -- (only has the RIGHT and top2 wall)
      { 
        { x = fullX, y = cY - 0.25*aH + 0.33*goalSize, width = wallSize, height = 0.5*aH - 0.66*goalSize },
        { x = cX + 0.25*aW - 0.33*goalSize , y = oY, width = 0.5*aW - 0.66*goalSize, height = wallSize },
      },
    },
    
    goals = {
      { x = cX, y = fullY + 2*wallSize, width = goalSize, height = wallSize*4, rotation = 180 },
      { x = oX, y = oY, width = goalSize, height = wallSize*4, rotation = -45 },
      { x = fullX, y = oY, width = goalSize, height = wallSize*4, rotation = 45 }
    }
  },
  
  -- four players
  {
    touchPolygons = {
      { x = cX + 0.25*aW, y = cY + 0.25*aH, vertices = {0,0, 0.5*aW,0, 0.5*aW,0.5*aH, 0,0.5*aH} },
      { x = cX - 0.25*aW, y = cY + 0.25*aH, vertices = {0,0, 0,0.5*aH, -0.5*aW,0.5*aH, -0.5*aW,0} },
      { x = cX - 0.25*aW, y = cY - 0.25*aH, vertices = {0,0, -0.5*aW,0, -0.5*aW,-0.5*aH, 0,-0.5*aH} },
      { x = cX + 0.25*aW, y = cY - 0.25*aH, vertices = {0,0, 0,-0.5*aH, 0.5*aW,-0.5*aH, 0.5*aW,0} }
    },
    
    rotations = {
      45,
      135,
      225,
      315
    },
    
    scoreText = {
      { x = math.cos(0.25*math.pi)*70, y = math.sin(0.25*math.pi)*70 },
      { x = math.cos(0.75*math.pi)*70, y = math.sin(0.75*math.pi)*70 },
      { x = math.cos(1.25*math.pi)*70, y = math.sin(1.25*math.pi)*70 },
      { x = math.cos(1.75*math.pi)*70, y = math.sin(1.75*math.pi)*70 },
    },
    
    walls = {
      -- player 1
      -- (only has the RIGHT2 and BOTTOM2 wall)
      {
        { x = fullX, y = cY + 0.25*aH - 0.33*goalSize, width = wallSize, height = 0.5*aH - 0.66*goalSize },
        { x = cX + 0.25*aW - 0.33*goalSize, y = fullY, width = 0.5*aW - 0.66*goalSize, height = wallSize }
      },
      
      -- player 2
      -- (only has the LEFT2 and BOTTOM1 wall)
      {
        { x = oX, y = cY + 0.25*aH - 0.33*goalSize, width = wallSize, height = 0.5*aH - 0.66*goalSize },
        { x = cX - 0.25*aW + 0.33*goalSize, y = fullY, width = 0.5*aW - 0.66*goalSize, height = wallSize }
      },
      
      -- player 3
      -- (only has the LEFT1 and TOP1 wall)
      { 
        { x = oX, y = cY - 0.25*aH + 0.33*goalSize, width = wallSize, height = 0.5*aH - 0.66*goalSize },
        { x = cX - 0.25*aW + 0.33*goalSize, y = oY, width = 0.5*aW - 0.66*goalSize, height = wallSize },
      },
      
      -- player 4
      -- (only has the RIGHT1 and TOP2 wall)
      { 
        { x = fullX, y = cY - 0.25*aH + 0.33*goalSize, width = wallSize, height = 0.5*aH - 0.66*goalSize },
        { x = cX + 0.25*aW - 0.33*goalSize , y = oY, width = 0.5*aW - 0.66*goalSize, height = wallSize },
      },
    },
    
    goals = {
      { x = fullX , y = fullY, width = goalSize, height = 4*wallSize, rotation = 135 },
      { x = oX, y = fullY, width = goalSize, height = 4*wallSize, rotation = 225 },
      { x = oX, y = oY, width = goalSize, height = 4*wallSize, rotation = -45 },
      { x = fullX, y = oY, width = goalSize, height = 4*wallSize, rotation = 45 }
    }
      
  }
}

--[[
function Player:eventWithinBounds(event)
   local bounds = self.touchArea.contentBounds
   local x, y = event.x, event.y
        
   if ((x >= bounds.xMin) and (x <= bounds.xMax) and (y >= bounds.yMin) and (y <= bounds.yMax)) then
      return true
   end
    
   return false   
end
--]]

function Player:eventWithinBounds(event)
  -- first check the screen (the fast, global check)
  -- exit immediately if we're off screen
  -- but if we're on screen, continue to the next check
  if not self:onScreen(event) then return false end
  
  -- then check the polygon (much slower and complex)
  return self:pointInsidePolygon(event, self.modifiedPolygon)
end

function Player:pointInsidePolygon(point, vs)
  local x, y = point.x, point.y
  local inside = false

  local j = #vs - 1
  for i=1,#vs,2 do
    local xi, yi = vs[i], vs[i+1]
    local xj, yj = vs[j], vs[j+1]
    
    local intersect = ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
    if intersect then
      inside = not inside
    end
    
    j = i
  end
  
  return inside
end

function Player:onScreen(point)
  return (point.x > oX and point.x < fullX and point.y > oY and point.y < fullY)
end

function Player:distanceToBounds(event)
  local screenDist = self:distanceToScreen(event)
  local polyDist = self:distanceToPolygon(event, self.modifiedPolygon)
  
  return math.min(polyDist, screenDist)
end

function Player:distanceToScreen(point)
  -- basically, just check right angle distance to each side (left, right, top, bottom)
  -- and return the minimum out of all those
  local minX = math.min(math.abs(point.x-oX), math.abs(fullX-point.x))
  local minY = math.min(math.abs(point.y-oY), math.abs(fullY-point.y))
  
  return math.min(minX, minY)
end

function Player:distanceToPolygon(point, vs)
  local x, y = point.x, point.y
  local minDist = 1000000
  
  -- loop through all vertices
  local j = #vs - 1
  for i=1,#vs,2 do
    local p1 = { x = vs[i], y = vs[i+1] }
    local p2 = { x = vs[j], y = vs[j+1] }
    
    local diffVec = { x = (p2.x - p1.x), y = (p2.y - p1.y) }
    local pointVec = { x = (x - p1.x), y = (y - p1.y) }
    local lineMagnitude = math.dist(diffVec.x, diffVec.y)
    
    -- determine value (between 0 and 1) that closest point is on the line segment
    local r = (diffVec.x * pointVec.x + diffVec.y * pointVec.y) / (lineMagnitude*lineMagnitude)
    
    -- determine distance from given point to that point (r) on the line segment
    local dist = 0
    
    --[[
    if r <= 0 or r >= 1 then
      print(diffVec.x, diffVec.y)
      print(pointVec.x, pointVec.y)
      print(lineMagnitude)
      print(r)
      print("OUTSIDE EDGE?")
    end
    --]]
    
    -- if r < 0, we're outside the line segment, so shortest distance is just to p1
    if r <= 0 then 
      dist = math.dist(pointVec.x, pointVec.y)
    
    -- if r > 1, we're also outside (but on the other side), so shortest distance is just to p2
    elseif r >= 1 then 
      dist = math.dist((p2.x - x), (p2.y - y))
      
    -- otherwise, we do a distance calculation between given point and chosen point
    else
      local newPoint = { x = p1.x + r * diffVec.x, y = p1.y + r * diffVec.y }
      -- math.sqrt( math.dist(pointVec.x, pointVec.y)*math.dist(pointVec.x, pointVec.y) - r*lineMagnitude*lineMagnitude)
      dist = math.dist(x - newPoint.x, y - newPoint.y)
    end
    
    -- finally, save the smallest distance ("swap new distance or keep old minimum?")
    minDist = math.min(dist, minDist)
    
    -- DON'T FORGET: to update to the next line segment of the polygon
    j = i
  end
  
  -- return the minimum distance we found!
  return minDist
end

function Player:activateTouch(event)
  -- If a "forcedStart" powerup is active, 
  -- we ONLY activate a touch if it's within radius of that powerup
  -- (otherwise, we return out of this function)
  if self.forcedStart then
    local dist = math.dist(self.forcedStart.x - event.x, self.forcedStart.y - event.y)
    if dist > self.forcedStart.myRadius then
      return
    end
  end
  
  -- update the active touch
  self.activeTouch = event
  
  -- start the first joint
  self:addJoint(event.x, event.y)
end

function Player:deactivateTouch()
  -- cache active touch
  local t = self.activeTouch
  
  -- finalize line
  self:finalizeLine()
  
  -- remove active touch
  self.activeTouch = nil
end
  
function Player:onTouchEvent(event)
  if GLOBALS.paused then return end
  
  -- if a goal disabler is active, and we're inside it, return!
  if self.goalDisabler then
    local dist = math.dist(self.goalDisabler.x - event.x, self.goalDisabler.y - event.y)
    if dist <= self.goalDisabler.radius then
      return
    end
  end
  
  -- If we're frozen, then return!
  if self.isFrozen then
    return
  end
  
  --------
  -- Step 1: some checks to see if we should do ANYTHING with this touch
  -------
  local p = event.phase
  
  -- did this touch originate in a different area?
  if not self:eventWithinBounds({ x = event.xStart, y = event.yStart }) then
    -- then ignore it
    return
  end
  
  -- is this touch currently outside our polygon?
  if not self:eventWithinBounds(event) then
    -- if this is the active touch, deactivate it
    if self.activeTouch and event.id == self.activeTouch.id then
      self:deactivateTouch()
    end
    
    -- in any case, return
    return
  end
  
  -- is this touch different from the active touch?
  if self.activeTouch and event.id ~= self.activeTouch.id then
    -- then ignore it (we don't allow more than one touch per player)
    return
  end

  -- have we ran out of chain length?
  if self.curChainLength >= self.maxChainLength then
    -- then any touch will be worthless
    return
  end
  
  -- is there already a line active?
  if self.linesActive >= 1 then
    return
  end
  
  --------
  -- Step 2: check if this touch warrants the creation of a new active touch
  -------
  if p == 'began' or not self.activeTouch then
    self:activateTouch(event)
  end
  
  --------
  -- Step 3: check if the current active touch has ended
  -------
  if p == 'ended' or p == 'canceled' then
    self:deactivateTouch()
  end
  
  --------
  -- Step 4: check if the current active touch has moved
  -------
  if p == 'moved' and self.activeTouch then
    -- If reverse controls are activated ... 
    --  => calculate vector between CURRENT touch and OLD touch => that's how we moved our finger
    --  => also calculate the old position (where we previously placed a joint
    --  => now add the NEGATED movement vector to the old position to get the final position
    local tX, tY = event.x, event.y
    if GLOBALS.reverseControls and #self.joints >= 2 then
      local oldTouch = { x = self.activeTouch.x, y = self.activeTouch.y }
      local oldPos = { x = self.joints[#self.joints-1], y = self.joints[#self.joints] }
      local vec = { x = (event.x - oldTouch.x), y = (event.y - oldTouch.y) }
      
      tX = (oldPos.x - vec.x)
      tY = (oldPos.y - vec.y)
    end

    -- add new joint at the calculated location
    if self:addJoint(tX, tY) then
      -- if adding the joint was SUCCESSFUL, save new position
      -- (if not, the touch was either deactivated or was too small to register)
      self.activeTouch.x = event.x
      self.activeTouch.y = event.y
    end
  end
end

function Player:addJoint(x,y)
  local ind = #self.joints+1
  local distToPreviousJoint = 0

  
  if #self.joints >= 2 then
    if not GLOBALS.simulationMode then
      -- play sound effect
      local audioFileName = "chalk" .. self.playerNum
      local channel, source = audio.play( GLOBALS.audioFiles[audioFileName], { channel = (self.playerNum+1) })
      al.Source(source, al.PITCH, math.random()*0.2 + 0.9)
    end
    
    -- determine distance to previous joint
    distToPreviousJoint = math.dist(x - self.joints[ind-2], y - self.joints[ind-1])
  
    -- check if this would exceed max line length
    if (self.curChainLength + distToPreviousJoint) >= self.maxChainLength then
      -- get (normalized) vector between new and previous joint
      local vec = { x = (x - self.joints[ind-2]) / distToPreviousJoint, y = (y - self.joints[ind-1]) / distToPreviousJoint }
      
      -- shrink joint distance to upper bound
      -- get maximum movement allowed
      distToPreviousJoint = self.maxChainLength - self.curChainLength
      
      -- move along this vector
      -- (previous joint + max allowed movement in the direction of new joint)
      x = self.joints[ind-2] + vec.x * distToPreviousJoint
      y = self.joints[ind-1] + vec.y * distToPreviousJoint
      
      -- update computer position to the LIMITED position
      -- NOTE/TO DO: Is this even an improvement???
      self.curPos = { x = x, y = y }
    end
    
    -- if the distance to the previous joint is too little abort mission here
    local lineThreshold = 3.5
    if distToPreviousJoint <= lineThreshold then
      return false
    end
  end
  
  
  
  -- we store joints this way so that we can quickly make a line later
  -- (double unpack() functions don't have amazing performance)
  self.joints[ind] = x
  self.joints[ind+1] = y
  
  -- if rope chains are enabled ...
  if GLOBALS.gameSettings.ropeChains then
    -- create a small body
    -- (first body is always static, the rest becomes part of a rope/elastic type thingy)
    local vertex = display.newCircle(self.sceneGroup, x, y, 5)
    local bodyType = 'dynamic'
    if #self.joints <= 2 then bodyType = 'static' end
    
    physics.addBody(vertex, bodyType, { radius = 5 })
    table.insert(self.jointBodies, vertex)
  end
  
  -- add the amount of space we moved to the chain length
  if #self.joints > 2 then
    self:updateChainLength(distToPreviousJoint)
    
    -- again, only execute this code if rope chains are enabled ...
    if GLOBALS.gameSettings.ropeChains then
      -- add joint to previous body
      local prevBody = self.jointBodies[#self.jointBodies-1]
      local ropeJoint = physics.newJoint( "rope", vertex, prevBody, 0, 0, 0, 0)
      
      -- set maximum length between bodies to initial distance + some margin
      ropeJoint.maxLength = distToPreviousJoint
      
      -- also, remember this maximum length
      vertex.maxLength = distToPreviousJoint
    end
  end
  
  -- then draw a new line
  self:createLine()
  
  -- if we're above max chain length ...
  if self.curChainLength >= self.maxChainLength then
    -- deactivate the touch
    self:deactivateTouch()
    return false
  end
  
  return true
end

function Player:createLine()
  -- if we have too few joints (2 pairs of coordinates), do nothing
  local n = #self.joints
  if n < 4 then
    return
  end
  
  -- draw rectangle from latest point to previous point
  local curPoint = { x = self.joints[n-1], y = self.joints[n] }
  local prevPoint = { x = self.joints[n-3], y = self.joints[n-2] }
  local avgPoint = { x = 0.5*(curPoint.x + prevPoint.x), y = 0.5*(curPoint.y + prevPoint.y) }
  
  local strokeWidth = 10 -- math.random() * 5 + 7.5
  local lineLength = math.dist(curPoint.x - prevPoint.x, curPoint.y - prevPoint.y) 
  
  local line = display.newRect(self.sceneGroup, curPoint.x, curPoint.y, lineLength, strokeWidth)
  line.rotation = math.deg( math.atan2(curPoint.y - prevPoint.y, curPoint.x - prevPoint.x) )
  
  -- anchor line at the end point; so we can shrink-fade it
  line.anchorX = 1
  
  -- add texture to the line
  line.fill = self.brushTexture
  line:setFillColor(unpack(touchFills[self.playerNum]))
  line.fill.scaleX = 16 / lineLength
  line.fill.scaleY = 16 / strokeWidth
  
  -- NOTE: Offset is a value between (-1,1) and is RELATIVE to the fill texture dimensions (in this case, 16x16)
  -- (NOTE 2: A positive X offset will shift the object to the LEFT, negative x offset will shift it to the RIGHT)
  line.fill.x = self.curChainOffset / 16 % 1
  self.curChainOffset = self.curChainOffset + lineLength
  
  -- turn it into a body
  local bodyProperties = { density = 1.0, bounce = 1.0, friction = 0.0 }
  physics.addBody(line, 'static', bodyProperties)

  -- Remember length of this line, so we can give back this chain length later
  line.chainLength = lineLength
  
  
  -- Remember who drew this line; for simulation and statistics
  line.myPlayer = self.playerNum
    
  -- plan fade out effect
  local delayVal = 2000 / GLOBALS.gameSpeed
  local timeVal = 200 / GLOBALS.gameSpeed
  transition.to(line, { alpha = 0.0, xScale = 0.01, time = timeVal, delay = delayVal, onComplete = function(obj) self:lineFadeComplete(line) end })
  
  self.transitionsInEffect = self.transitionsInEffect + 1

  -- save the line in a big array of all lines
  -- (might need that sometime in the future)
  table.insert(self.oldLines, line)
  
  -- also, draw a line into the background canvas
  local bgLine = display.newLine( curPoint.x - oX - 0.5*aW, curPoint.y - oY - 0.5*aH, prevPoint.x - oX - 0.5*aW, prevPoint.y - oY - 0.5*aH)
  bgLine.strokeWidth = strokeWidth
  bgLine:setStrokeColor(unpack(touchFills[self.playerNum]))
  GLOBALS.backgroundCanvas:draw( bgLine )
  
  -- check if our AVERAGE POINT intersects with any of the powerups
  -- (if so, save it, so we can check at the end if we sliced/crossed this powerup)
  GLOBALS.powerupManager:intersectWithPowerups(self, avgPoint)
end

function Player:lineFadeComplete(obj)
  -- give back chain length to player
  if obj.chainLength then
    self:updateChainLength(-obj.chainLength)
  end
  
  self.transitionsInEffect = self.transitionsInEffect - 1
  
  -- check if this was the FIRST part of a line being removed
  if self.maxTransitionsInEffect and self.transitionsInEffect == (self.maxTransitionsInEffect - 1) then
    if GLOBALS.gameMode == 1 then
      -- if so, remove old goal (on game mode 1)
      self:removeGoal()
    end
  end
  
  -- check if the COMPLETE line was removed
  if self.transitionsInEffect <= 0 then
    self.linesActive = 0
    
    if GLOBALS.gameMode == 2 then
      -- add a new ball (on game mode 2)
      -- once the previous line is completely removed
      Ball(self.scene, obj.x, obj.y)
    end
  end
  
  -- in game mode 1 (art hockey), the line now turns into a goal!
  if GLOBALS.gameMode == 1 then
    local tempDuration = 500 / GLOBALS.gameSpeed
    transition.to(obj, { alpha = 1.0, xScale = 1.0, time = tempDuration })
    
    -- gray lines are to DIFFERENTIATE between regular lines and goal lines
    -- TO DO: might need something stronger
    obj:setFillColor(0.2, 0.2, 0.2) 

    -- give correct properties for a goal body
    obj.isGoal = true
    obj.playerNum = self.playerNum
    obj.isSensor = true
    obj.myPlayer = nil
    
    -- remember this is a goal (so we can remove it later)
    table.insert(self.goalObjects, obj)
  
  else
    -- otherwise, simply remove the line
    obj:removeSelf()
  end
end

function Player:removeGoal()
  -- remove the actual objects
  for i=1,#self.goalObjects do
    self.goalObjects[i]:removeSelf()
  end
  
  -- clear the array
  self.goalObjects = { }
end

function Player:finalizeLine()
  -- if rope chains are enabled
  if GLOBALS.gameSettings.ropeChains then
    ------
    -- convert last body to a static one
    ------
    local oldBody = self.jointBodies[#self.jointBodies]
    local oldX = oldBody.x
    local oldY = oldBody.y
    local oldMaxLength = oldBody.maxLength
    self.jointBodies[#self.jointBodies]:removeSelf()
    
    local newBody = display.newCircle(self.sceneGroup, oldX, oldY, 5)
    physics.addBody(newBody, 'static')
    
    local ropeJoint = physics.newJoint( "rope", newBody, self.jointBodies[#self.jointBodies-1], 0, 0, 0, 0)
    ropeJoint.maxLength = oldMaxLength
  end
  
  -- count number of transitions in effect; so we know when the first one is done
  self.maxTransitionsInEffect = self.transitionsInEffect
  
  -------
  -- Make sure the current line isn't the ACTIVE one anymore
  -- All we need to do for this, is empty the joints array (to start afresh on the next joint)
  -- (if we have too few joints, we never had a line to begin with, so DON'T set linesActive to 1)
  -------
  if #self.joints >= 4 then
    self.linesActive = 1
    
    self.linesDrawn = self.linesDrawn + 1
      
    -- CHECK if the user drew a circle
    local isCircle, circleCenter, circleRadius = self:checkCircle()
    
   if GLOBALS.gameSettings.circlingEnabled then
      -- If so, go through all powerups, and check if one of them lies inside the circle
      if isCircle then
        GLOBALS.powerupManager:checkIfWithinCircle(circleCenter, circleRadius)
      end
    end
    
    -- If it's NOT a circle, check if it's a SLICE/CUT
    if not isCircle then
      if GLOBALS.gameSettings.slicingEnabled then
        -- powerup manager checks all sliced powerups
        -- if the slice is correct, it removes them
        GLOBALS.powerupManager:checkIfSliced(self)
      end
    end
  end
  
  -- NOTE: We could re-calculate the average goal position here.
  -- However, it would be way too early. The line has just been drawn, it will take a few seconds before it becomes a goal.
  -- I think that's why, in earlier simulations, the computer drew lines too EARLY and then suffered the consequences when the ball hit
  -- Instead, now the average goal position is updated as soon as the complete previous line has turned into a goal.
  -- in simulation mode, we want to get the average position of all the joints
  
  -- THE COMMENT ABOVE is true, but, self.joints = {} at the end of this function
  -- As such, we don't have this information anymore at a later stadium
  -- We must retrieve it here now
  -- OPTIONALLY, we can store the position temporarily, and only make it take effect when self.transitionsInEffect <= 0
  if GLOBALS.gameMode == 1 and self.computerPlayer then
    local numJoints = #self.joints
    self.startGoalPos = { x = self.joints[1], y = self.joints[2] }
    self.averageGoalPos = { x = 0, y = 0 }
    self.endGoalPos = { x = self.joints[numJoints-1], y = self.joints[numJoints] }
    
    for i=1,numJoints,2 do
      self.averageGoalPos.x = self.averageGoalPos.x + self.joints[i]
      self.averageGoalPos.y = self.averageGoalPos.y + self.joints[i+1]
    end
    
    self.averageGoalPos.x = self.averageGoalPos.x / numJoints * 2
    self.averageGoalPos.y = self.averageGoalPos.y / numJoints * 2
  end
  
  -- empty joints array
  self.joints = {}
  
  -- empty list of sliced powerups
  self.slicedPowerups = {}
  
  self.curChainOffset = 0
end

function Player:checkCircle()
  -- determine average point
  local avg = {0,0}
  local numPoints = #self.joints
  for i=1,numPoints,2 do
    avg[1] = avg[1] + self.joints[i]
    avg[2] = avg[2] + self.joints[i+1]
  end
  
  avg[1] = avg[1] / numPoints * 2
  avg[2] = avg[2] / numPoints * 2
  
  -- now determine the average DISTANCE from each joint to this point
  -- (this is essentially the RADIUS of the best fitting circle through all these points)
  local avgDist = 0
  for i=1,numPoints,2 do
    avgDist = avgDist + math.dist(self.joints[i] - avg[1], self.joints[i+1] - avg[2])
  end
  
  avgDist = avgDist / numPoints * 2
  
  -- finally, determine how many of the points are within range
  -- ALSO determine their angle to see if we hit all four quadrants
  local percentageWithinRange = 0
  local quadrants = {false, false, false, false, false, false, false, false}
  for i=1,numPoints,2 do
    local dX, dY = (self.joints[i] - avg[1]), (self.joints[i+1] - avg[2])
    local dist = math.dist(dX, dY)
    local errorMargin = 5
    
    if math.abs(dist - avgDist) <= errorMargin then
      percentageWithinRange = percentageWithinRange + 1
    end
    
    local angle = math.atan2(dY, dX)
    if angle < 0 then angle = angle + 2*math.pi end
    local angleIndex = math.floor(angle / (2*math.pi) * 8)+1

    quadrants[angleIndex] = true
  end
  
  percentageWithinRange = percentageWithinRange / numPoints * 2
  
  -- if not all quadrants are used, it can never be a circle (at least, not a completed one)
  local allQuadrantsUsed = true
  for i=1,8 do
    if not quadrants[i] then
      allQuadrantsUsed = false
      break
    end
  end
  
  local circleThreshold = 0.8
  if percentageWithinRange >= circleThreshold and allQuadrantsUsed then
    return true, avg, avgDist
  end
  
  return false
end

function Player:endGame()
  -- in simulation mode, getting to X points simply starts the next match
  -- (instead of going to game over and quitting the whole simulation)
  if GLOBALS.simulationMode then
    GLOBALS.sim:endMatch()
    return
  end
  
  -- save who won this game
  GLOBALS.winningPlayer = self.playerNum
    
  -- pause the game
  -- why? so that all update events (and physics) do not run anymore, while the transition is happening
  GLOBALS.pauseGame()
  
  -- transition to game over screen
  composer.gotoScene("game_over", { time = 500, effect = "flip" })
end

function Player:concedeGoal()
  self.goalsConceded = self.goalsConceded + 1
end

function Player:updatePoints(dp)
  -- update point value
  self.points = self.points + dp
  
  -- update text
  self.scoreText.text = self.points
  
  -- if we're above max points, end game!
  -- (in simulation mode, games go on until timer runs out)
  if not GLOBALS.simulationMode then
    if self.points >= GLOBALS.maxPoints then
      self:endGame()
      return true
    end
  end
  
  return false
end

function Player:addStatusIcon(pu)
  -- create sprite with the given powerupType
  -- grab image sheet + powerup library from my own (tools) libraries
  local size = 32
  local newIcon = display.newImageRect(self.sceneGroup, require("tools.powerup_sheet"), require("tools.powerup_library")[pu.powerupType].frame, size, size)
  newIcon.alpha = 0.3
  newIcon.id = pu.id
  
  -- add to list
  table.insert(self.statusIcons, newIcon)
  
  -- place it
  -- (shift all icons to the left to make place)
  self:updateStatusIcons()
end

function Player:updateStatusIcons()
  -- Get the orthogonal vector on the actual rotation (because status icons are laid out side by side)
  -- (actual rotation = defaultRotation - 90, so thats why this is needed)
  local orthoVec = { x = math.cos(math.rad(self.defaultRotation-90)), y = math.sin(math.rad(self.defaultRotation-90)) }
  local size = 32
  local numIcons = #self.statusIcons
  for i=1,numIcons do
    local icon = self.statusIcons[i]
  
    icon.x = self.statusIconLocation.x + (i-0.5*numIcons-0.5)*size*orthoVec.x
    icon.y = self.statusIconLocation.y + (i-0.5*numIcons-0.5)*size*orthoVec.y
    icon.rotation = self.defaultRotation-90
  end
end

function Player:removeStatusIcon(pu)
  -- find the corresponding icon
  -- remove it from game + list
  for i=1,#self.statusIcons do
    local icon = self.statusIcons[i]
    if icon.id == pu.id then
      icon:removeSelf()
      table.remove(self.statusIcons, i)
      break
    end
  end
  
  -- update status icons
  self:updateStatusIcons()
end

function Player:addForcedStart(o)
  self.forcedStart = o
end

function Player:removeForcedStart()
  self.forcedStart = nil
end

function Player:addShield(pu)
  if self.shieldTimer then
    timer.cancel(self.shieldTimer)
    self:removeShield(self.shieldObject)
  end
  
  self.shieldActive = true
  self:addStatusIcon(pu)
  
  self.shieldTimer = timer.performWithDelay(10000, function() self:removeShield(pu) end)
  self.shieldObject = pu
end

function Player:removeShield(pu)
  self.shieldActive = false
  self:removeStatusIcon(pu)
  
  self.shieldTimer = nil
end

function Player:isShieldActive()
  return self.shieldActive
end

function Player:freeze(pu)
  -- if we're already frozen, first remove the old one
  if self.frozenTimer then
    timer.cancel(self.frozenTimer)
    self:unfreeze(self.frozenObject, true)
  end
  
  self.isFrozen = true
  self:addStatusIcon(pu)
  
  -- fade out touchArea
  transition.to(self.touchArea, { alpha = 0.0, time = 500 })
  
  -- plan event to unfreeze
  self.frozenTimer = timer.performWithDelay(10000, function() self:unfreeze(pu) end)
  self.frozenObject = pu
end

function Player:unfreeze(pu, keepVisual)
  -- (if we're unfreezing only to immediately refreeze, we don't want to change the visuals and mess things up)
  keepVisual = false or keepVisual
  
  self.isFrozen = false
  self:removeStatusIcon(pu)
  
  -- fade in touchArea
  if not keepVisual then
    transition.to(self.touchArea, { alpha = 0.1, time = 500 })
  end
  
  self.frozenTimer = nil
end

function Player:addGoalDisabler()
  -- check if a current goal disabler should be removed
  self:removeGoalDisabler()
  
  -- find average point between all goal objects
  local avg = { x = 0, y = 0 }
  for i=1,#self.goalObjects do
    avg.x = avg.x + self.goalObjects[i].x
    avg.y = avg.y + self.goalObjects[i].y
  end
  
  avg.x = avg.x / #self.goalObjects
  avg.y = avg.y / #self.goalObjects
  
  -- create circle 
  -- (just a visual guide to show player what's happening)
  local rad = 60
  local gd = display.newCircle(self.sceneGroup, avg.x, avg.y, rad)
  gd.fill = {0.6, 0.2, 0.2, 0.5}
  gd.radius = rad
  
  -- plan removal event
  local timer = timer.performWithDelay(10000, function() self:removeGoalDisabler() end)
  gd.myTimer = timer
  
  -- save reference
  self.goalDisabler = gd
end

function Player:removeGoalDisabler()
  -- destroy current goal disabler (if it exists)
  -- (and remove its timer, just in case)
  if self.goalDisabler then
    timer.cancel(self.goalDisabler.myTimer)
    self.goalDisabler:removeSelf()
    
    self.goalDisabler = nil
  end
end

function Player:updateInk(di)
  -- update maximum ink
  -- (but ensure we stay within reasonable bounds; don't lose all your ink or get too much)
  local minInk = 20
  local maxInk = 120
  
  self.maxChainLength = math.max( math.min(self.maxChainLength + di, maxInk), minInk )
  
  -- update visual indicator
  self:updateChainLength(0)
end

function Player:updateChainLength(dc)
  -- update overall/global chain length
  -- and clamp it (between 0, maxLength)
  -- (not necessarily length of current line)
  local oldChainLength = self.curChainLength
  self.curChainLength = math.max( math.min(self.curChainLength + dc, self.maxChainLength), 0)

  -- remember exactly how much ink we used, but only if we actually USED it (instead of getting it back)
  if self.curChainLength > oldChainLength then
    self.inkUsed = self.inkUsed + (self.curChainLength - oldChainLength)
  end
  
  -- now update the graphical indicator
  local newXScale = (1.0 - self.curChainLength / self.maxChainLength)
  
  self.chainLengthIndicator.isVisible = true
  -- xScale <= 0 is not possible, so in that case we just completely hide it
  if newXScale <= 0 then 
    newXScale = 1.0 
    self.chainLengthIndicator.isVisible = false
  end
  self.chainLengthIndicator.xScale = newXScale
end

function Player:updateBallTouches(dt)
  self.ballTouches = self.ballTouches + dt
end

function Player:addGoalObject(o)
  table.insert(self.goalObjects, o)
end

function Player:saveSlicedPowerup(pu)
  -- save powerup based on ID
  -- this way, if we hit the same powerup multiple times, we do NOT get duplicates
  self.slicedPowerups[pu.id] = pu
end

function Player:createGoalSparkles()
  -- if the game is paused, simply PLAN the next sparkles ... but RETURN before you create them
  -- plan next sparkles
  local randDuration = math.random()*850 + 150
  timer.performWithDelay(randDuration, function() self:createGoalSparkles() end)
  
  if GLOBALS.paused or #self.goalObjects <= 0 then
    return
  end
  
  -- create new particle emitter
  local emitterParams = require("particles.test")
  local col = touchFills[self.playerNum]
  
  emitterParams.finishColorRed = col[1]
  emitterParams.startColorRed = col[1]
  
  emitterParams.finishColorGreen = col[2]
  emitterParams.startColorGreen = col[2]
  
  emitterParams.finishColorBlue = col[3]
  emitterParams.startColorBlue = col[3]
  
  local emitter = display.newEmitter( emitterParams )
  self.sceneGroup:insert(emitter)
  
  -- place emitter at random goal point
  local randGoalObject = self.goalObjects[math.random(#self.goalObjects)]
  emitter.x = randGoalObject.x
  emitter.y = randGoalObject.y
end
    

function Player:destroy()
  -- remove touch event (if it exists)
  if self.touchListener then
    Runtime:removeEventListener( 'touch', self.touchListener )
  end
  
  -- remove update event (if it exists)
  if self.updateListener then
    Runtime:removeEventListener('enterFrame', self.updateListener)
  end
end

function Player:reset()
  -- cancel any transitions
  -- TO DO: Might want to make it more specific: save the ID of the transitions, cancel them individually
  transition.cancel()
  
  -- remove any lines we've drawn
  for i=1,#self.oldLines do
    local l = self.oldLines[i]
    -- if the object still has the removeSelf function,
    -- then it hasn't been removed yet by Corona
    if l and l.removeSelf then
      l:removeSelf()
    end
  end
  
  -- reset our goal objects
  -- (only on game mode 1; the other game modes we just keep our current goal)
  if GLOBALS.gameMode == 1 then
    -- Remove all current goal objects
    self:removeGoal()
    
    -- Instantiate the default goal again
    -- PROBLEM? This makes most matches very short when training computer players (simulation), as they haven't learnt how to defend yet
    self:createProperGoals()
  end
  
  -- set everything we can to nil/empty array/0
  self.activeTouch = nil
  
  self.joints = {}
  self.jointBodies = {}
  self.oldLines = {}
  
  self.maxChainLength = 50
  self.curChainLength = 0
  self.linesDrawn = 0
  
  self.ownGoals = 0
  self.goodGoals = 0
  
  -- reset simulation parameters -- VERY IMPORTANT!
  self.curPos = { x = self.startPos.x, y = self.startPos.y }
  self.inkUsed = 0
  self.ballTouches = 0
  self.boundsPenalties = 0
  self.prevBoundsDistance = 0
  self.goalsConceded = 0
  self.linesActive = 0
  
  self.transitionsInEffect = 0
  self.maxTransitionsInEffect = 0
  
  -- reset points to 0
  self:updatePoints(-self.points)
end

function Player:new(scene, i, n, playerAI, bg, brush)
  self.scene = scene
  self.sceneGroup = scene.view
  self.playerNum = i
  self.playerCount = n
  self.settings = playerSettings[n]
  
  ----------
  -- Check if this is a computer player
  ----------
  if playerAI then
    self.computerPlayer = true
    
    -- start "finger position" at the center of our polygon
    local touchPolygon = self.settings.touchPolygons[i]
    self.curPos = { x = touchPolygon.x, y = touchPolygon.y }
    self.startPos = { x = touchPolygon.x, y = touchPolygon.y }
    
    -- determine our movement "bounding box"
    -- TO DO: This bounding box is incorrect for 3 players
    self.boundingBox = { center = { x = touchPolygon.x, y = touchPolygon.y }, halfWidth = 0.5*aW - 30, halfHeight = 0.5*0.5*aH - 30 }
    
    -- some variables for simulation
    self.prevBoundsDistance = 0
    self.boundsPenalties = 0
    
    -- if simulation mode is NOT enabled, this means this player should be controlled by a neural network!
    -- grab a random network from the file and apply it
    local networks = GLOBALS.loadTable('neural_networks_final.json', system.ResourceDirectory)
    
    -- determine the keys in this list ...
    local keyset={}
    local n=0

    for k,v in pairs(networks) do
      n=n+1
      keyset[n]=k
    end
    
    -- ... so we can grab a random network
    self:setNeuralNetwork(networks[ keyset[math.random(#keyset)] ][1])
    
    -- DEBUGGING: Grab specific network
    self:setNeuralNetwork(networks["12"][1])
    --self:setNeuralNetwork(networks["1"][1])
  end
  
  -- keep track of ink usage, as a good computer player should draw a LOT
  -- (NOTE: I might also want to use this for some fun player statistics)
  self.inkUsed = 0 
  self.ballTouches = 0
  self.goalsConceded = 0
  self.linesDrawn = 0
  
  self.ownGoals = 0
  self.goodGoals = 0

 -----------
  -- Walls
  -----------
  local walls = self.settings.walls[i]
  local paint = {
      type = "image",
      filename = "assets/textures/stripes.png",
  }
  local paint2 = {
    type = "image",
    filename = "assets/textures/wobblyStroke.png"
  }
  
  -- if we're in the first game mode, there are no goals (the whole area is sealed off)
  -- in that case, the first player creates all the walls
  -- all other players create nothing
  if GLOBALS.gameMode == 1 then
    if self.playerNum == 1 then
      walls = {
          { x = cX, y = oY, width = aW, height = wallSize }, -- top wall
          { x = cX, y = fullY, width = aW, height = wallSize },  -- bottom wall
          { x = oX, y = cY, width = wallSize, height = aH }, -- left wall
          { x = fullX, y = cY, width = wallSize, height = aH },  -- right wall
          
          { x = oX, y = oY, width = cornerSize, height = cornerSize, rotation = 45 },
          { x = oX, y = fullY, width = cornerSize, height = cornerSize, rotation = 45 },
          { x = fullX, y = fullY, width = cornerSize, height = cornerSize, rotation = 45 },
          { x = fullX, y = oY, width = cornerSize, height = cornerSize, rotation = 45 }
      }
    else
      walls = {}
    end
  end

  for w=1,#walls do
    local prop = walls[w]
    local wall = display.newRect(self.sceneGroup, prop.x, prop.y, prop.width, prop.height)
    
    local bodyProperties = { density = 1.0, bounce = 1.1, friction = 0.0 }
    physics.addBody(wall, 'static', bodyProperties)
    
    wall.fill = paint
    wall:setFillColor(0.1,0.1,0.1)
    
    local zoomFactor = 2
    
    local scaleFactorX = 128.0 / prop.width / zoomFactor
    local scaleFactorY = 128.0 / prop.height / zoomFactor
    wall.fill.scaleX = scaleFactorX
    wall.fill.scaleY = scaleFactorY
    
    wall.stroke = paint2
    wall.strokeWidth = 10
    wall.stroke.scaleX = 1
    wall.stroke.scaleY = 16/wall.strokeWidth
    wall:setStrokeColor(0.1, 0.1, 0.1)
    
    if prop.rotation then 
      wall.fill = {0.1, 0.1, 0.1}
      wall.rotation = prop.rotation 
    end
  end
  
  -----------
  -- Position / Touch Area
  -----------
  -- create general touch area
  local touchPolygon = self.settings.touchPolygons[i]
  
  -- save our polygon for quick checking if a touch is inside or outside its bounds
  -- HOWEVER, the polygon is automatically centered and repositioned (by Corona), so we must save the modified polygon ourselves
  local modifiedPolygon = {}
  for a=1,#touchPolygon.vertices,2 do
    -- grab original vertices
    local vX, vY = touchPolygon.vertices[a], touchPolygon.vertices[a+1]
    
    -- both polygons originate from (0,0)
    -- so just move that point to the center
    vX = vX + cX
    vY = vY + cY
    
    -- insert new coordinates into modified polygon
    table.insert(modifiedPolygon, vX)
    table.insert(modifiedPolygon, vY)
  end
  self.modifiedPolygon = modifiedPolygon

  local tA = display.newPolygon(self.sceneGroup, touchPolygon.x, touchPolygon.y, touchPolygon.vertices)
  tA.isHitTestable = true
  tA.isVisible = true
  tA.alpha = 0.1

  local stripedBG = {
      type = "image",
      filename = "assets/textures/" .. bg .. ".png",
  }
  tA.fill = stripedBG
  tA.fill.scaleX = 128 / tA.width / 2
  tA.fill.scaleY = 128 / tA.height / 2
  tA:setFillColor(unpack(touchFills[i]))

  self.touchArea = tA
  
  -- create stroke around touch area
  -- local tALine = display.newLine(self.sceneGroup, unpack(modifiedPolygon))
  
  tA.stroke = paint2
  tA.strokeWidth = 10
  tA:setStrokeColor(unpack(touchFills[i]))
  
  tA.stroke.scaleX = 1
  tA.stroke.scaleY = (16/tA.strokeWidth)
  
  self.brushTexture = {
      type = "image",
      filename = "assets/textures/" .. brush .. ".png",
  }
  
  return self
end

function Player:createProperGoals()
  local startGoalRadius = 10
  local touchPolygon = self.settings.touchPolygons[self.playerNum]
  local cX, cY = touchPolygon.x, touchPolygon.y
  
  if GLOBALS.playerCount == 3 then
    local angle = self.playerNum * (2*math.pi/3) - (1/6)*math.pi
    
    cX = display.contentCenterX + math.cos(angle)*140
    cY = display.contentCenterY + math.sin(angle)*140
  end
  
  local goalCirc = display.newCircle(self.sceneGroup, cX, cY, startGoalRadius)
  goalCirc.fill = touchFills[self.playerNum]
  goalCirc.isGoal = true
  goalCirc.playerNum = self.playerNum
  
  physics.addBody(goalCirc, 'static', { isSensor = true, radius = startGoalRadius })
  
  -- initialize goal objects list with just this first object
  self.goalObjects = { goalCirc }
  
  self.averageGoalPos = { x = cX, y = cY }
  self.startGoalPos = { x = cX, y = cY }
  self.endGoalPos = { x = cX, y = cY }
end

function Player:lateInitialization()
  local i = self.playerNum
  local touchPolygon = self.settings.touchPolygons[i]
  
  -----------
  -- Create goal
  -----------
  self.goalObjects = {}
  self.averageGoalPos = { x = 0, y = 0 }
  if GLOBALS.gameMode ~= 1 then
    local goalProps = self.settings.goals[i]
    local goal = display.newRect(self.sceneGroup, goalProps.x, goalProps.y, goalProps.width, goalProps.height)
    goal.isVisible = false

    physics.addBody(goal, 'static', { isSensor = true })
    goal.playerNum = i
    goal.isGoal = true
    
    if goalProps.rotation then
      goal.rotation = goalProps.rotation
    end
  
    
    -- Draw a line from start to end point, dropping vertices randomly along the way
    --        This should create a wobbly line.
    --        Alternative: create circular ropejoints and allow them to swing/bend whenever someone scores
    local goalVec = { x = math.cos(math.rad(goal.rotation)), y = math.sin(math.rad(goal.rotation)) }
    local orthoGoalVec = { x = -goalVec.y, y = goalVec.x }
    local startPoint = { 
      x = goalProps.x + orthoGoalVec.x*0.5*goalProps.height - goalVec.x*0.5*goalProps.width, 
      y = goalProps.y + orthoGoalVec.y*0.5*goalProps.height - goalVec.y*0.5*goalProps.width 
    }
    
    -- remember our average goal position
    -- NOTE: START + END location are remembered below, because we already have those AFTER drawing the wobbly line
    self.averageGoalPos = { 
      x = goalProps.x + orthoGoalVec.x*0.5*goalProps.height, 
      y = goalProps.y + orthoGoalVec.y*0.5*goalProps.height
    }

    local t = 0
    local lineVertices = {startPoint.x, startPoint.y}
    local randAngleOffset = math.random()*2*math.pi
    while(t < 1) do
      t = t + math.random()*0.05 + 0.05
      local newPoint = { x = startPoint.x + goalVec.x*t*goalProps.width, y = startPoint.y + goalVec.y*t*goalProps.width }
      
      -- a random perturbation
      local offset = math.sin(t*4*math.pi + randAngleOffset)*goalProps.height*0.05
      newPoint.x = newPoint.x + offset*orthoGoalVec.x
      newPoint.y = newPoint.y + offset*orthoGoalVec.y
      
      lineVertices[#lineVertices+1] = newPoint.x
      lineVertices[#lineVertices+1] = newPoint.y
      
      -- save this point as a (pretend) goal object, so we can add sparkles
      table.insert(self.goalObjects, newPoint)
    end
    
    local wobblyLine = display.newLine(self.sceneGroup, unpack(lineVertices))
    wobblyLine.strokeWidth = 3
    wobblyLine:setStrokeColor(unpack(touchFills[self.playerNum]))
    wobblyLine.alpha = 0.3
    
    self.goal = goal
    
    -- remember start + end position of goal
    self.startGoalPos = startPoint
    self.endGoalPos = { x = self.goalObjects[#self.goalObjects].x, y = self.goalObjects[#self.goalObjects].y }
  end
  
  -- in game mode 1, we don't have fixed goals
  -- instead, we begin with a circle in the center of our polygon
  -- (as soon as we draw the first line, that goal disappears
  if GLOBALS.gameMode == 1 and not GLOBALS.simulationMode then
    self:createProperGoals()
  end
  
  -- Start the "goal random particles" chain
  -- This randomly creates sparkles around goals, to make them stand out
  self:createGoalSparkles()
  
  -- a game with 3 players needs a special starting position
  if GLOBALS.playerCount == 3 then
    self.startPos = { x = self.averageGoalPos.x, y = self.averageGoalPos.y }
  end
  
  -----------
  -- Touch + chain tracker(s)
  -----------
  
  -- add variable to track active touch
  self.activeTouch = nil
  
  -- add array to track current line ( = joints)
  -- and old line objects
  self.linesActive = 0
  self.transitionsInEffect = 0
  self.joints = {}
  self.jointBodies = {}
  self.oldLines = {}
  
  -- add variables to keep track of used chain
  self.maxChainLength = 50
  self.curChainLength = 0
  self.curChainOffset = 0

  -- add variables for score/modifiers
  self.points = 0
  
  -- array to keep track of which powerups our line hits
  self.slicedPowerups = {}
  
  -----------
  -- Interface
  -----------
  
  local scoreTextPos = self.settings.scoreText[i]
  local options = { 
    parent = self.sceneGroup, 
    text = '0', 
    x = cX + scoreTextPos.x, 
    y = cY + scoreTextPos.y,
    font = GLOBALS.mainFont, 
    fontSize = 64 
  }
  self.scoreText = display.newText(options)
  self.scoreText.fill = {0,0,0}
  self.scoreText.alpha = 0.3
  self.scoreText.rotation = self.settings.rotations[i] - 90
  
  -- create chain indicator
  local l = display.newRect(self.sceneGroup, cX + scoreTextPos.x*1.66, cY + scoreTextPos.y*1.66, 100, 5)
  l:setFillColor(unpack(touchFills[i]))
  l.alpha = 0.2
  l.rotation = self.settings.rotations[i] - 90
  
  self.chainLengthIndicator = l
  self:updateChainLength(0)
  
  -- status icons
  self.statusIcons = {}
  self.defaultRotation = self.settings.rotations[i]
  self.statusIconLocation = { x = self.scoreText.x, y = self.scoreText.y }
  
  -----------
  -- add event listener to our general area (NOT the player itself)
  -- don't do this for computer players (they don't need it, anyway)
  -----------
  if not self.computerPlayer then
    self.touchListener = function(event) self:onTouchEvent(event) end
    Runtime:addEventListener( 'touch', self.touchListener )
  
  -- instead, computer players simply run a function every frame
  else
    self.updateListener = function() self:enterFrame() end
    Runtime:addEventListener('enterFrame', self.updateListener)
  end
  
  if self.computerPlayer and GLOBALS.debuggingMode then
    self.debugText = display.newText(self.sceneGroup, 'LALA', display.contentCenterX, display.contentCenterY, native.systemFont, 24)
    self.debugText.fill = {0,0,0}
  end
end


---------------
-- Neural Network code!
--
-- INPUT (9 numbers)
--  => vecBallToGoal (X)
--  => vecBallToGoal (Y)
--
--  => ballVelocity (X)
--  => ballVelocity (Y)
--
--  => lastTouchInfo (touch on/off)
--  => lastTouchInfo (X)
--  => lastTouchInfo (Y)
--  => lastTouchInfo (out of bounds)
--
--  => inkAvailability (percentage of maximum)
--
-- OUTPUT (3 numbers)
--  => vecMove (X)
--  => vecMove (Y)
--  => curTouch (touch on/off)
--
---------------

function Player:setNeuralNetwork(nn)
  self.nLayers = nn
end

function Player:getNeuralNetwork()
  return self.nLayers
end

function Player:enterFrame()
  if GLOBALS.paused then return end
  
  local networkAI = false
  
  if networkAI then
    self:networkEnterFrame()
  else
    self:manualEnterFrame()
  end
end

function Player:manualEnterFrame()
  -- if no line is active
  if #self.joints <= 0 then    
    -- go through all balls to find the closest one (to our goal)
    -- only consider that ball in the rest of the calculations
    local b = nil
    local closestDistance = 100000
    for i=1,#GLOBALS.balls do
      local ball = GLOBALS.balls[i].sprite
      local dist = math.dist(ball.x - self.averageGoalPos.x, ball.y - self.averageGoalPos.y)
      if dist < closestDistance then
        b = ball
        closestDistance = dist
      end
    end
    
    local vx, vy = b:getLinearVelocity()
    local totalVel = math.dist(vx, vy)
    local totalDist = math.dist(self.averageGoalPos.x - b.x, self.averageGoalPos.y - b.y)
    
    -- check if ball is coming towards our goal
    -- if not, DON'T draw a line
    -- NOTE 1: check for 0, otherwise we get errors because we're dividing by 0
    -- NOTE 2: we DO introduce a random chance of drawing a line anyway, for variety (and attacking) purposes
    local wantALineProb = 0.33
    local vecProd = 0
    if totalVel > 0 and totalDist > 0 then
      vecProd = (self.averageGoalPos.x - b.x)/totalDist * vx/totalVel + (self.averageGoalPos.y - b.y)/totalDist * vy/totalVel
      if vecProd <= 0.75 and math.random() <= wantALineProb  then
        return
      end
    end
    
    -- check if the ball is close to an edge AND moving towards it
    local wallPoint = nil
    local wallMargin = 15
    local goalMargin = 100
    if (b.x - oX) <= wallMargin then
      wallPoint = { x = oX, y = b.y }
    elseif (fullX - b.x) <= wallMargin then
      wallPoint = { x = fullX, y = b.y }
    elseif (b.y - oY) <= wallMargin then
      wallPoint = { x = b.x, y = oY }
    elseif (fullY - b.y) <= wallMargin then
      wallPoint = { x = b.x, y = fullY }
    end
    
    -- if a wall point exists (ball is close to SOME edge)
    -- and the ball is NOT going towards our goal
    if wallPoint and vecProd <= 0 then
      -- get vector product => if positive, ball must be moving toward this point
      local vecProd = (wallPoint.x - b.x)*vx + (wallPoint.y - b.y)*vy
      if vecProd > 0 then
        -- and if the ball will soon bounce, don't draw a line
        -- (we essentially "wait" until the ball is done bouncing)
        return
      end
    end

    
    -- find projected ball location 
    -- take into account the DISTANCE from the ball to the goal => if closer to goal, we project closer to the ball)
    local distFactorX, distFactorY = 0.5, 0.5
    if totalDist <= goalMargin then
      distFactorX = 0.07 + math.random()*0.25
      distFactorY = 0.07 + math.random()*0.25
    end
    local newX, newY = b.x + distFactorX * (vx / GLOBALS.gameSpeed), b.y + distFactorY * (vy / GLOBALS.gameSpeed)
    
    -- add a random offset
    -- WHY? It makes lines more natural/human-like, and adds possibility of slight errors/mistimings
    -- BUT: we do always move the line towards the ball
    local angle = math.random()*2*math.pi
    local maxRadius = math.min(self.maxChainLength, 40) -- if we have less ink, draw closer to the ball
    local radius = math.random(0,maxRadius)
    
    -- if we're really close to the goal, draw a line really close to the ball
    -- and rotate it orthogonally, so we bounce it back perfectly
    -- but only if ball is actually moving towards goal!
    if totalDist <= goalMargin and vecProd >= 0.25 then 
      radius = 5
      angle = math.atan2(vy, vx) + 0.5*math.pi + math.random()*0.1*math.pi
    end
    
    -- do NOT angle the line in such a way that we shoot towards our own goal
    -- How? Each line has two orthogonal vectors (one pointing to one side, one pointing to the opposite side)
    -- Check if any of these (roughly) points at our goal
    -- If so, check if the ball is on the same side
    local tempMoveVector = { x = -math.cos(angle), y = -math.sin(angle) }
    local orthoVec1 = { x = -tempMoveVector.y, y = tempMoveVector.x }
    
    local pointToGoalDist = math.dist(self.averageGoalPos.x - newX, self.averageGoalPos.y - newY)
    local pointToGoal = { x = (self.averageGoalPos.x - newX) / pointToGoalDist, y = (self.averageGoalPos.y - newY) / pointToGoalDist }
    
    local dot1 = orthoVec1.x * pointToGoal.x + orthoVec1.y * pointToGoal.y
    if dot1 >= 0.75 or dot1 <= -0.75 then
      -- determine dot product between BALL and our current position
      local pointToBallDist = math.dist(b.x - newX, b.y - newY)
      local pointToBall = { x = (b.x - newX) / pointToBallDist, y = (b.y - newY) / pointToBallDist }
      local dot2 = orthoVec1.x * pointToBall.x + orthoVec1.y * pointToBall.y
      
      -- MAGIC BIT: If both dot products have the same _sign_, then they must be on the same side
      if dot1 / dot2 >= 0 then
        -- So, we've determined the line is angled towards our goal, and the ball will soon hit it
        -- With 75% chance, return
        -- Otherwise, just rotate the line a bit and and hope for the best
        if math.random() <= 0.75 then
          return
        else
          angle = angle + 0.3*math.pi
        end
      end
    end
    
    -- FINALLY, calculate the offset and movement vectors from the parameters above
    local offsetX, offsetY = newX + math.cos(angle)*radius, newY + math.sin(angle)*radius
    self.lineMoveVector = { x = -math.cos(angle), y = -math.sin(angle) }
    
    -- this vector makes the line "rotate/curve"
    -- if the line is really close to the goal, I can't afford to curve/wobble (might miss ball completely)
    self.orthoLineMoveVector = { x = 0, y = 0 }
    if totalDist > goalMargin then
      if math.random() <= 0.33 then
        self.orthoLineMoveVector = { x = -self.lineMoveVector.y, y = self.lineMoveVector.x }
      elseif math.random() <= 0.66 then
        self.orthoLineMoveVector = { x = self.lineMoveVector.y, y = -self.lineMoveVector.x }
      end
    end

    self.curX = offsetX
    self.curY = offsetY
    
    -- start drawing there
    local ev = {
      phase = 'began',
      x = offsetX, 
      y = offsetY,
      id = 'WHOCARES',
      xStart = self.startPos.x,
      yStart = self.startPos.y
    }
    
    -- don't start events too close to bounds!
    local distToBounds = self:distanceToBounds(ev)
    if distToBounds <= 50 then
      return
    end
    
    self:onTouchEvent(ev)
  
  -- if a line is active ...
  else

    -- (initialize event randomly, as a backup)
    local ev = {
      phase = 'moved',
      x = math.random()*cW,
      y = math.random()*cH,
      id = 'WHOCARES',
      xStart = self.startPos.x,
      yStart = self.startPos.y,
    }
    
    -- if line becomes too long, truncate it
    -- in other words: END the line here!
    if self.curChainLength >= 65 then
      ev.phase = 'ended'
    end
  
    -- move towards our movement vector
    local movementPerFrame = 5
    local orthoMovementPerFrame = (1/10)
    
    ev.x = self.curX + self.lineMoveVector.x * movementPerFrame + self.orthoLineMoveVector.x * orthoMovementPerFrame
    ev.y = self.curY + self.lineMoveVector.y * movementPerFrame + self.orthoLineMoveVector.y * orthoMovementPerFrame
    
    -- if we're going too near the edge of our polygon ...
    -- REVERSE drawing direction! (curX - ev.x, looks fine mostly, but not graceful enough??)
    -- END our touch!
    local distToBounds = self:distanceToBounds(ev)
    if distToBounds <= 25 then
      ev.x = self.curX - ev.x
      ev.y = self.curY - ev.y
      -- ev.phase = 'ended'
    end
    
    
    -- increase orthogonal movement to gradually get a curve
    self.orthoLineMoveVector.x = self.orthoLineMoveVector.x * 2
    self.orthoLineMoveVector.y = self.orthoLineMoveVector.y * 2
    
    -- fake the touch
    self:onTouchEvent(ev)
    
    self.curX = ev.x
    self.curY = ev.y
  end
end

function Player:networkEnterFrame()
  -----------
  -- Collect input for the neural network
  -- TO DO: Check nearest ball(s), instead of always ball 1
  -----------
  local vec = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  local root = math.sqrt(12)
  local b = GLOBALS.balls[1]
  local hW, hH = 0.5*aW, 0.5*aH
  
  -- average goal position (normalized to full screen)
  vec[1] = (self.averageGoalPos.x - hW) * root / (2*aW)
  vec[2] = (self.averageGoalPos.y - hH) * root / (2*aH)
  
  -- ball position (normalized to full screen)
  vec[3] = (b.sprite.x - hW) * root / (2*aW)
  vec[4] = (b.sprite.y - hH) * root / (2*aH)
  
  -- ball velocity (normalized to maximum speed of ball; mean = 0 of course)
  local vx, vy = b.sprite:getLinearVelocity()
  vec[5] = vx * root / (2*b.maxSpeed*GLOBALS.gameSpeed)
  vec[6] = vy * root / (2*b.maxSpeed*GLOBALS.gameSpeed)
  
  -- current drawing position
  vec[7] = (self.curPos.x - hW) * root / (2*aW)
  vec[8] = (self.curPos.y - hH) * root / (2*aH)
  
  -- is touch currently active?
  vec[9] = -1
  if self.touchActive then vec[9] = 1 end
  
  -- how far are we from the bounds of the screen/our area?
  -- (this is at most half the screen width)
  --vec[10] = self.prevBoundsDistance / hW
  
  -- how much ink do we have left?
  vec[10] = self.curChainLength / self.maxChainLength
  
  -- is a line currently active?
  vec[11] = -1
  if self.linesActive > 0 then vec[12] = 1 end
  
  -- check start + end position of goal
  vec[12] = (self.startGoalPos.x - hW) * root / (2*aW)
  vec[13] = (self.startGoalPos.y - hH) * root / (2*aH)
  
  vec[14] = (self.endGoalPos.x - hW) * root / (2*aW)
  vec[15] = (self.endGoalPos.y - hH) * root / (2*aH)
  
  --[[
  for i=1,15 do
    print(i, vec[i])
  end
  --]]

  -- this vector will hold results in next layer(s)
  -- until it holds the output
  local newVec = {}
  local n = self.nLayers
  
  -- go through all layers of network
  for i=1,#n do
    
    -- for each neuron in the layer ...
    local numN = #n[i]
    for j=1,numN do
      -- determine the sum of all connections (multiplied by weights, bias added)
      local sum = 0
      
      -- go through connections, multiply weights
      local numNN = #n[i][j]-1
      for k=1,numNN do
        sum = sum + n[i][j][k] * vec[k]
      end
      
      -- except last one; that's the bias
      -- add it seperately
      sum = sum + n[i][j][numNN+1]
      
      -- calculate the new value
      -- put it in the vector
      newVec[j] = math.tanh(sum) -- self:sigmoid(sum)
    end
    
    vec = table.copy(newVec)
    newVec = {}
  end

  -- now, variable _vec_ holds the result of this calculation
  self:takeAction(vec)
end

function Player:sigmoid(z)
  return 1.0 / (1.0 + math.exp(-z))
end

function Player:takeAction(vec)
  ------------
  -- We use the output of the neural network to take an action
  -- Essentially, we determine our new location and touch on/off, and use that to fake the right touch event
  ------------
  
  ------------
  -- MOVE our computery finger
  --
  -- The idea? Each computer has a fixed (rectangular) bounding box in which it can draw
  --           The network outputs two values (X,Y) in the range (-1,1)
  --           We simply use these values to find the location within the bounding box and IMMEDIATELY jump to that spot
  ------------
  local curPos = { 
    x = self.boundingBox.center.x + vec[1]*self.boundingBox.halfWidth, 
    y = self.boundingBox.center.y + vec[2]*self.boundingBox.halfHeight 
  }
  
  --[[
  -- OLD CODE FOR MOVING (deltaX, deltaY idea)
  -- move according to X and Y coordinates (output 1 and 2 of neural network)
  -- also NORMALIZE these coordinates, otherwise the computer wants to move only diagonally because it's faster
  local maxMoveSpeed = 10
  local totalMagnitude = math.dist(vec[1], vec[2])
  local moveVec = { x = vec[1]/totalMagnitude*maxMoveSpeed*GLOBALS.gameSpeed, y = vec[2]/totalMagnitude*maxMoveSpeed*GLOBALS.gameSpeed }
  local curPos = { x = self.curPos.x + moveVec.x, y = self.curPos.y + moveVec.y }
  --]]
  
  
  -- third number is "TOUCH THE SCREEN OR NOT"
  -- based on the parameters (and current state), we fake a touch or not
  local ev = {
    phase = 'began',
    x = curPos.x,
    y = curPos.y,
    id = 'WHOCARES',
    xStart = self.startPos.x,
    yStart = self.startPos.y
  }

  -- YES, touch the screen
  if vec[3] >= 0 then
    -- if there's no active touch, start one
    if not self.activeTouch then
      self:onTouchEvent(ev)
      
    -- otherwise, only MOVE the touch
    else
      ev.phase = 'moved'
      self:onTouchEvent(ev)
    end
  
  -- NO, don't touch the screen
  else
    -- if there was an active touch, end it
    if self.activeTouch then
      ev.phase = 'ended'
      self:onTouchEvent(ev)
    end
    
    -- if there was no active touch, then nothing should change
  end
  
  -- check if touch is outside of polygon OR screen
  if not self:eventWithinBounds(ev) then 
    -- if so, penalize the computer
    self.boundsPenalties = self.boundsPenalties + 1
    
    -- NOTE: if the new touch was NOT within bounds, don't update computer position!
    
    -- on edge/outside of bounds, our distance to the bounds is just always 0
    self.prevBoundsDistance = 0
  else
    -- save the exact distance to the bounds (of polygon or screen)
    self.prevBoundsDistance = self:distanceToBounds(ev)
  end
  
  -- update current position
  self.curPos = curPos

    
  
  --[[
  for k,v in pairs(vec) do
    print(k,v)
  end
  --]]
end
  