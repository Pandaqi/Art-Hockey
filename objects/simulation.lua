-----------------------------------------------------------------------------------------
--
-- simulation.lua
--
-----------------------------------------------------------------------------------------

Simulation = Object:extend()

-- Returns normally distributed values
-- (mostly used for seeding initial random neural networks)
function math.gaussian (mean, variance)
    return  math.sqrt(-2 * variance * math.log(math.random())) *
            math.cos(2 * math.pi * math.random()) + mean
end

function Simulation:generateRandomNetwork()
  -- size of each layer (and subsequently amount of layers)
  -- URL: https://stats.stackexchange.com/questions/181/how-to-choose-the-number-of-hidden-layers-and-nodes-in-a-feedforward-neural-netw
  local sizeOfLayers = {15, 10, 3}
  local numLayers = #sizeOfLayers
  
  -- for each layer, create random weights and biases
  -- except for the input layer (as those aren't actually perceptrons)
  local nLayers = {}
  for i=1,(numLayers-1) do
    -- create empty layer
    nLayers[i] = {}
    
    -- for every perceptron in this layer ...
    for j=1,sizeOfLayers[i+1] do
      nLayers[i][j] = {}
      
      -- set weights (based on how many perceptrons there were in the previous layer)
      local prevSize = sizeOfLayers[i]
      for k=1,prevSize do
        nLayers[i][j][k] = math.gaussian(0,1)
      end
      
      -- add bias
      nLayers[i][j][prevSize+1] = math.gaussian(0,1)
    end
  end
  
  return nLayers
end

function Simulation:startMatch()
  -- check if we need to change speed
  if self.speedTogglePlanned then
    if GLOBALS.gameSpeed ~= 1 then
      self.oldGameSpeed = GLOBALS.gameSpeed
      GLOBALS.gameSpeed = 1
    else
      GLOBALS.gameSpeed = self.oldGameSpeed
    end
    self.speedTogglePlanned = false
  end
  
  -- increment match counter
  self.curMatch = self.curMatch + 1
  
  -- plan timer for match end
  local tempDuration = 1000*self.roundDuration / GLOBALS.gameSpeed
  self.endMatchTimer = timer.performWithDelay(tempDuration, function() self:endMatch() end)
  
  -- destroy all balls, except the first
  for i=2,#GLOBALS.balls do
    GLOBALS.balls[i]:destroy()
  end
  
  -- reset the remaining ball
  GLOBALS.balls[1]:reset()
  
  -- reset score/settings on all AI players
  local mainOpponentSet = false
  for i=1,GLOBALS.playerCount do
    local p = GLOBALS.players[i]
    if p.computerPlayer then
      -- TO DO: reset player
      p:reset()
      
      p.isMainOpponent = false
      if not mainOpponentSet then
        p:setNeuralNetwork(self.mainOpponent)
        mainOpponentSet = true
        p.isMainOpponent = true
      else
      
        -- if first round, hand players a random neural network
        if self.curRound == 0 and not GLOBALS.resumeSimulation then
          p:setNeuralNetwork(self:generateRandomNetwork())
        
        -- otherwise, grab the next in line from networks
        else 
          self.nextNetworkIndex = self.nextNetworkIndex + 1
          
          -- NOTE: NETWORKS saves arrays with {actualNetwork, itsFitness}, so take first element only
          local tempNet = self.NETWORKS[self.nextNetworkIndex][1] 
          
          p:setNeuralNetwork(tempNet)
        end
      end
    end
  end
end

function Simulation:endMatch()
  timer.cancel(self.endMatchTimer)
  
  -- Save all the neural networks, including their fitness
  for i=1,GLOBALS.playerCount do
    local p = GLOBALS.players[i]
    if p.computerPlayer and not p.isMainOpponent then
      ----------
      -- Calculate the FITNESS of this network
      ----------
      --local finalPenalty = (p.boundsPenalties / 5)
      --local fitness = p.points*10 + p.ballTouches*10 - 3*p.goalsConceded - (p.boundsPenalties/5)

      -- Factor #1: Meaningful line ratio. (We want to draw lines that actually hit the ball.)
      -- Factor #2: Good goals. (Goals scored directly by us.)
      -- Factor #3: Own goals. (Goals scored against us, because of a line WE drew.)
      -- Factor #4: How often we went out of bounds. (We don't want to do this all the time.)
      -- OPTIONAL factor #5: encourage spatial diversity, could also solve the out-of-bounds problem
      
      local mlRatio = 0
      local fitness = -10
      if p.linesDrawn > 0 then 
        mlRatio = (p.ballTouches/p.linesDrawn) 
        fitness = mlRatio*100 + p.goodGoals*5 - (p.goalsConceded + p.ownGoals)*5
      end

      print(mlRatio, p.goodGoals, p.ownGoals)
      print("PLAYER FITNESS: " .. fitness)

      self.NETWORKS[#self.NETWORKS+1] = {p:getNeuralNetwork(), fitness}
      
      self.totalFitness = self.totalFitness + fitness
    end
  end
  
  -- if we've played enough matches this round, advance the simulation
  local simulationDone = false
  if self.curMatch >= self.matchesPerRound then
    simulationDone = self:advanceRound()
    
    if simulationDone then
      print("SIMULATION DONE! Quitting.")
      
      -- TO DO: Print final ("best") neural networks
    end
  end
  
  if not simulationDone then
    self:startMatch()
  end
end

function Simulation:advanceRound()
  print("ADVANCED TO ROUND " .. tostring(self.curRound+1))
  print("Total fitness: " .. self.totalFitness)
  
  -- increment round counter
  self.curRound = self.curRound + 1
  
  -- reset match counter
  self.curMatch = 0
  self.nextNetworkIndex = 0
  
  -- breed the new generation
  self:breedGeneration()
  
  -- reset some variables
  self.totalFitness = 0
  
  -- Check if complete simulation should be finished
  if self.curRound >= self.maxRounds then
    return true
  end
  
  return false
end

function Simulation:breedGeneration()
  local n = self.NETWORKS
  local population = #n
  
  -- first, sort by fitness
  -- and then kill off the worst half
  table.sort(n, function(a,b) 
      if a[2] > b[2] then 
        return true 
      else 
        return false 
      end
    end)
  
  -- save the best network in file
  self.savedNetworks[tostring(self.curRound)] = n[1]
  local saveSuccess = GLOBALS.saveTable(self.savedNetworks, 'neural_networks.json')
  
  -- also save this network as the main opponent
  self.mainOpponent = n[1][1]
  
  -- save the WHOLE population into a different file
  -- (Why? So we can, if needed, pause simulation and then restart from this population later
  GLOBALS.saveTable(n, 'neural_networks_population.json')
  
  -- find two random networks to breed from
  -- do this based on probability
  local newNetworks = {}
  
  -- ELITISM: Always preserve the top 10%
  local topten = math.floor(0.1 * population)
  for i=1,topten do
   newNetworks[i] = {n[i][1], 0}
  end
  
  --[[
  -- POOR MAN'S NETWORK: Remove the bottom 50%
  for i=population,math.ceil(0.5*population),-1 do
    table.remove(n, i)
  end
  --]]
  
  -- REMOVE ALL NON-POSITIVE FITNESS NETWORKS
  -- (this happens when you: do nothing and/or concede way too many goals)
  for i=population,1,-1 do
    if n[i][2] <= 0 then
      table.remove(n, i)
    end
  end
  
  print("BREEDING POPULATION: " .. tostring(#n))
  
  -- create cumulative probability
  local runningSum = 0
  for i=1,#n do
    runningSum = runningSum + n[i][2]
    n[i][2] = runningSum
  end
  
  -- Randomly breed the rest (outside of top 10%)
  for i=(topten + 1),population do
    local rand1 = self:getNetworkByProb(runningSum)[1]
    local rand2 = self:getNetworkByProb(runningSum)[1]
    
    local newNet = self:breedNetwork(rand1, rand2)
    newNetworks[i] = {newNet, 0}
  end
  
  -- shuffle the networks
  -- (otherwise, we only pit networks against each other with equal skill, which will prematurely eliminate good ones)
  table.shuffle(newNetworks)
  
  -- replace old networks by all the new ones
  self.NETWORKS = newNetworks
end

function table.shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function Simulation:getNetworkByProb(runningSum)
  local randNum = math.random() * runningSum
  
  for i=1,#self.NETWORKS do
    if self.NETWORKS[i][2] > randNum then
      return self.NETWORKS[i]
    end
  end
end

function Simulation:breedNetwork(n1, n2)
  -- take the first network (n1) as starting point
  -- with X% chance, swap two properties between n1 and n2
  -- with Y% chance, mutate a property (nudge it up or down)
  local n = table.copy(n1)
  
  local crossOverProbability = 0.5
  local mutationProbability = 0.001
  
  -- go through all layers of network
  for i=1,#n do
    
    -- for each neuron in the layer
    local numN = #n[i]
    for j=1,numN do
      
      -- go through connections
      -- flip connections to other parent's value
      local numNN = #n[i][j]-1
      for k=1,numNN do
        if math.random() <= crossOverProbability then
          -- flip to n2 value!
          n[i][j][k] = n2[i][j][k]
        end
        
        -- mutate with low probability
        if math.random() <= mutationProbability then
          n[i][j][k] = n[i][j][k] + math.gaussian(0, 0.2)
        end
      end
      
      -- same flipping idea for the bias
      if math.random() <= crossOverProbability then
        n[i][j][numNN+1] = n2[i][j][numNN+1]
      end
      
      -- mutate with low probability
      if math.random() <= mutationProbability then
        n[i][j][numNN+1] = n[i][j][numNN+1] + math.gaussian(0, 0.2)
      end
    end
  end
  
  return n
end

function Simulation:onKeyEvent(event)
  local p = event.phase
  local key = event.keyName
  
  -- If you press 'p', the simulation will toggle game speed when the next match starts
  -- (toggling = going back/forth between 1 and max speed defined at the start)
  if p == 'up' and key == 'p' then
    self.speedTogglePlanned = true
  end
  
  -- we're not overriding default behaviour
  return false
end

function Simulation:new()
  -- get neural networks from file
  -- self.savedNetworks = GLOBALS.loadTable('neural_networks.json')
  if not self.savedNetworks then self.savedNetworks = {} end
  
  -- set some basic variables
  self.curMatch = 0
  self.curRound = 0
  self.roundDuration = 60
  self.matchesPerRound = 30
  self.maxRounds = 100
  self.totalFitness = 0
  
  
  
  -- THE ALMIGHTY VARIABLE WITH ALL NETWORKS
  self.NETWORKS = {}
  
  -- if we're resuming a simulation, load this stuff from the file
  if GLOBALS.resumeSimulation then
    self.NETWORKS = GLOBALS.loadTable('neural_networks_population.json')
  end
  
  -- Create a random main opponent
  -- Every generation, all players play against this single opponent, to keep rankings fair
  self.mainOpponent = self:generateRandomNetwork()
  self.nextNetworkIndex = 0
  
  -- start first match
  self:startMatch()
  
  -- touch event (for controlling the simulation, like pausing it)
  self.keyListener = function(event) self:onKeyEvent(event) end
  Runtime:addEventListener('key', self.keyListener)
  
  -- Create update event => mainly for timing
  --[[
  self.updateListener = function() self:enterFrame() end
  Runtime:addEventListener('enterFrame', self.updateListener)
  --]]
  
  return self
end