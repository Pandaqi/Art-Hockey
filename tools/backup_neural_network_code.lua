--[[

OLD INPUT STUFF

--]]
 
 -----------
  -- Collect input for the neural network
  -----------
  local vec = {0,0,0,0,0,0,0,0,0}
  local root = math.sqrt(12)
  local b = GLOBALS.balls[1]
  
  -- determine distance between ball and goal
  local ballDistToGoal = math.dist(b.sprite.x - self.goal.x, b.sprite.y - self.goal.y)
  local ballDistToPos = math.dist(b.sprite.x - self.curPos.x, b.sprite.y - self.curPos.y)
  
  -- determine goal vec + orthogonal goal vec 
  -- (rotations are clockwise, rectangle goal at the top is 0 degrees)
  local goalVec = { x = math.cos(math.rad(self.goal.rotation)), y = math.sin(math.rad(self.goal.rotation)) }
  local orthoGoalVec = { x = -goalVec.y, y = goalVec.x }
  
  local ballVec = { x = (b.sprite.x - self.goal.x) / ballDistToGoal, y = (b.sprite.y - self.goal.y) / ballDistToGoal }
  local posVec = { x = (b.sprite.x - self.curPos.x) / ballDistToPos, y = (b.sprite.y - self.curPos.y) / ballDistToPos }
  
  -- orthogonal dot product between goal and ball
  -- orthoDot = a.x*-b.y + a.y*b.x
  -- determines if b is to the left or to the right of a
  -- (if > 0 then goal on the right of ball, if < 0 then goal on the left of ball)
  -- & distance between ball and goal
  vec[1] = goalVec.x*ballVec.x + goalVec.y+ballVec.y
  vec[2] = (ballDistToGoal - aH) * root / (2*aH)
  
  -- dot product between ball velocity and goal
  -- (NOTE: determines if ball is going toward goal or not; if dot product negative, it's coming for the goal)
  -- & actual ball velocity
  local vx, vy = b.sprite:getLinearVelocity()
  local totalBallVelocity = math.dist(vx, vy)
  vec[3] = orthoGoalVec.x * (vx/totalBallVelocity) + orthoGoalVec.y * (vy/totalBallVelocity)
  vec[4] = totalBallVelocity * root / (2*b.maxSpeed*GLOBALS.gameSpeed)
  
  -- whether we're currently drawing or not
  vec[5] = 0
  if self.touchActive then vec[5] = 1 end
  
  -- orthogonal dot product between ball and last drawing pos
  -- & distance between ball and last drawing pos
  vec[6] = ballVec.x*(-posVec.y) + ballVec.y*posVec.x
  vec[7] = (ballDistToPos - aH) * root / (2*aH)
  
  -- distance between last position and bounds (of polygon or screen)
  -- used to teach the computer to stay away from the edges
  -- normalizing this is hard (polygons + screens have different sizes); so just divide by screen size
  vec[8] = self.prevBoundsDistance / math.dist(0.5*aW, 0.5*aH)
  
  -- fraction; runs from 0 to 1
  vec[9] = self.curChainLength/self.maxChainLength
  
  --[[
  ORIGINAL INPUT VECTOR SYSTEM
  
  -- Take original value, subtract mean, divide by standard deviation
  -- For uniform variables, the standard deviation = (b-a)/sqrt(12)
  -- As such, if we divide by that, we switch fraction and get: (blabla - mean) * root / (totalRange)
  vec[1] = (b.sprite.x - self.goal.x - aW) * root / (2*aW)
  vec[2] = (b.sprite.y - self.goal.y - aH) * root / (2*aH)
  
  local vx, vy = b.sprite:getLinearVelocity()
  vec[3] = vx * root / (2*b.maxSpeed)
  vec[4] = vy * root / (2*b.maxSpeed)
  
  -- boolean; already either 0 and 1
  vec[5] = 0
  if self.touchActive then vec[5] = 1 end
  
  -- We give the computer our current position RELATIVE to the ball
  -- vec[6] = (self.curPos.x - cX) * root / aW
  -- vec[7] = (self.curPos.y - cY) * root / aH
  vec[6] = (b.sprite.x - self.curPos.x - aW) * root / (2*aW)
  vec[7] = (b.sprite.y - self.curPos.y - aH) * root / (2*aH)
  
  -- boolean; already either 0 or 1
  vec[8] = self.outOfBounds
  
  -- fraction; runs from 0 to 1
  vec[9] = self.curChainLength/self.maxChainLength
  
  --]]
  
  --[[
  for k,v in pairs(vec) do
    print(k,v)
  end
  --]]
  
  
  
  
  
  
--[[

OLD OUTPUT STUFF

--]]


  -- first number is the ANGLE of movement
  -- second number is the MAGNITUDE of movement
  -- combine them to get total movement
  local angle = vec[1]*2*math.pi
  local moveVec = { x = math.cos(angle), y = math.sin(angle) }
  local maxPixelsPerMove = 10
  local maxMoveSpeed = vec[2] * maxPixelsPerMove * GLOBALS.gameSpeed
  local curPos = { x = self.curPos.x + moveVec.x * maxMoveSpeed, y = self.curPos.y + moveVec.y * maxMoveSpeed }