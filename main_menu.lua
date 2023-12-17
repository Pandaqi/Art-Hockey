-----------------------------------------------------------------------------------------
--
-- main_menu.lua
--
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local widget = require("widget")

local curScreen = nil
local menuLayers = {}
local matchSettings = nil
local gameModeImage = nil

local loadingGame = false

local saveData

local function startGame(event)
  if loadingGame then 
    return
  end
  
  loadingGame = true
  
  -- count number of players
  local playerCount = 0
  local computerPlayers = {false, false, false, false}
  
  -- NOTE: matchSettings is a "scrollView". This behaves like a displayGroup, IF you reference "_collectorGroup" first
  for i=1,matchSettings._collectorGroup.numChildren do
    local obj = matchSettings._collectorGroup[i]
    
    -- if this is the powerup toggle
    if obj.powerupToggle then
      -- set global parameter accordingly
      GLOBALS.powerupsAreEnabled = obj.isOn
    
    -- if this is a victory points radio group ...
    elseif obj.victoryPoints then
      -- go through the group
      for j=1,obj.numChildren do
        -- find the button that is turned on; save its victory points
        if obj[j].isOn then
          GLOBALS.maxPoints = obj[j].myVictoryPoints
          break
        end
      end
    
    -- if this is the game mode radio group ...
    elseif obj.gameModes then

      -- again, find the right setting
      for j=1,obj.numChildren do
        if obj[j].isOn then
          GLOBALS.gameMode = obj[j].myFrame
          break
        end
      end
    
    -- if this is a (player-selecting) radio group ...
    elseif obj.radioNum then
      -- check which of the buttons is turned on
      for j=1,obj.numChildren do
        if obj[j].isOn then
          -- human player?
          if j == 1 then
            playerCount = playerCount + 1
            computerPlayers[obj.radioNum] = false
            
          -- AI player?
          elseif j == 2 then
            playerCount = playerCount + 1
            computerPlayers[obj.radioNum] = true
          end
        end
      end
    end
  end
  
  if playerCount <= 1 then
    playerCount = 2
    computerPlayers[1] = false
    computerPlayers[2] = true
  end
  
  GLOBALS.computerPlayers = computerPlayers
  GLOBALS.playerCount = playerCount
  
  for i=1,menuLayers.settings.numChildren do
    local obj = menuLayers.settings[i]
    if obj.isToggle then
      local s = obj.mySetting
      if s == 'Debugging' then
        GLOBALS.debuggingMode = obj.isOn
      end
    end
  end

  composer.gotoScene("main_game", { time = 500, effect = "crossFade" })
end

local function loadScreen(which)
  if curScreen then
    transition.to(curScreen, {alpha = 0.0, time = 500})
  end
  
  curScreen = menuLayers[which]
  
  transition.to(curScreen, {alpha = 1.0, time = 500})
end

local function floatButton(obj)
  if obj.xScale <= 1.0 then
    transition.to(obj, { xScale = 1.05, yScale = 1.05, time = 700, onComplete = floatButton })
  else
    transition.to(obj, { xScale = 0.95, yScale = 0.95, time = 700, onComplete = floatButton })
  end
end

local function toggleMusic(obj)
  -- update volume in-game
  local newVolume = 0.0
  if obj.isOn then newVolume = 1.0 end
  audio.setVolume(newVolume, { channel = 1})
  
  -- save value immediately
  saveData.musicOn = obj.isOn
  GLOBALS.saveTable(saveData, 'save_data.json')
end

local function toggleSoundFX(obj)
  -- update volume in-game
  local newVolume = 0.0
  if obj.isOn then newVolume = 1.0 end
  
  -- for now, just update all channels 2-32
  -- (might need more or less later)
  for i=2,32 do
    audio.setVolume(newVolume, { channel = i })
  end
  
  -- save value immediately
  saveData.soundOn = obj.isOn
  GLOBALS.saveTable(saveData, 'save_data.json')
end

local function toggleDebugging(obj)
  -- by turning debugging ON, we erase the save file
  if obj.isOn then
    saveData = GLOBALS.createSaveFile()
  end
  
  saveData.debuggingMode = obj.isOn
  GLOBALS.saveTable(saveData, 'save_data.json')
end

local function toggleVibration(obj)
  saveData.vibration = obj.isOn
  GLOBALS.saveTable(saveData, "save_data.json")
end

local function switchGameMode(event)
  gameModeImage:setFrame( event.target.myFrame )
end

local function loadGameSettings()
  -- load the save file into the _saveData_ variable
  saveData = GLOBALS.loadTable('save_data.json')
  
  -- turn on/off sound (based on save data)
  toggleMusic({ isOn = saveData.musicOn })
  toggleSoundFX({ isOn = saveData.soundOn })
  toggleVibration({ isOn = saveData.vibration })
end

local function toggledSetting(event)
  local obj = event.target
  local s = obj.mySetting
  
  if s == 'Music' then
    toggleMusic(obj)
  elseif s == 'Sound FX' then
    toggleSoundFX(obj)
  elseif s == 'Debugging' then
    toggleDebugging(obj)
  elseif s == 'Vibration' then
    toggleVibration(obj)
  end
end

local function onPowerupSettingTap( event )
    --print( "Tap event on: " .. event.target.name )
    system.openURL('http://pandaqi.com/art-hockey#powerupLibrary')
  
    -- I guess we must do this for tap event, like with key events??
    return true
end
  
  
  

local function buttonPressed(event)
  local btn = event.target.myLabel
  
  if btn == "play" then
    loadScreen("playerSelect")
  elseif btn == "settings" then
    loadScreen("settings")
  elseif btn == "more" then
    system.openURL("http://pandaqi.com")
  elseif btn == "quit" then
    native.requestExit()
  elseif btn == "startGame" then
    startGame()
  elseif btn == 'back' then
    loadScreen("mainLayer")
  end
end

function scene:show(event)
  local sceneGroup = scene.view
  
  -------
  -- BACKGROUND
  --------
  local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
  bg.fill = GLOBALS.beigeBackground
  
  if event.phase == 'did' then
    -- load the game settings
    -- (do this anew every time, as it might have changed between games)
    loadGameSettings()
    
    local curX = display.contentCenterX
    local curY = 20
    local buttonHeight = 60
    local margin = 20
    local y = display.screenOriginY
    
    local buttonSettingsTable = {
          onRelease = buttonPressed,
          emboss = false,
          shape = "roundedRect",
          width = 320 - margin*2,
          height = buttonHeight,
          font = GLOBALS.mainFont,
          fontSize = 36,
          labelColor = { default = { 0, 0, 0 }, over = { 0.5, 0.5, 0.5 } },
          cornerRadius = 8,
          labelYOffset = 0, 
          fillColor = { default={ 0.5, 0, 0, 0.1 }, over={ 0.5, 0.75, 1, 0.1 } },
          strokeColor = { default={ 0.2, 0, 0, 0.1 }, over={ 0.333, 0.667, 1, 0.1 } },
          strokeWidth = 2
      }
    
    -------
    -- FIRST MENU LAYER
    -- (Logo, "Play!", "Settings", "Quit")
    --------
    menuLayers.mainLayer = display.newGroup()
    menuLayers.mainLayer.alpha = 0.0
    sceneGroup:insert(menuLayers.mainLayer)
    
    -- Display game logo
    local nlWidth = 320
    local nlHeight = nlWidth / 512 * (512/2)
    
    y = display.screenOriginY + margin
    
    local nameLogo = display.newImageRect(menuLayers.mainLayer, 'assets/textures/nameLogo.png', nlWidth, nlHeight)
    nameLogo.anchorY = 0
    nameLogo.x = display.contentCenterX
    nameLogo.y = y
    
    y = y + nlHeight + (0.5*buttonHeight + margin)
    
    -- Display three main buttons
    local mainLabels = {"play", "settings", "more", "quit"}
    for i=1,4 do
      local tutButton = widget.newButton({
        defaultFile = 'assets/textures/' .. mainLabels[i] .. 'Button.png',
        overFile = 'assets/textures/' .. mainLabels[i] .. 'ButtonOver.png',
        width = 320,
        height = 80,
        onRelease = buttonPressed,
      })
      
      tutButton.x = curX
      tutButton.y = y
      tutButton.playerCount = i
      tutButton.myLabel = mainLabels[i]
      
      menuLayers.mainLayer:insert(tutButton)
      
      -- add animation to play button
      if i == 1 then
        floatButton(tutButton)
      end
      
      y = y + (buttonHeight + 20)
    end
    
    

    -------
    -- MATCH SETTINGS ("player select") player
    -- (For each player, allow selecting Human/AI/None)
    -- (Allow turning powerups on/off)
    -- (Allow setting "number of points until victory")
    -- (Allow setting the "game mode" => art hockey/bountiful balls/classic)
    --------
    menuLayers.playerSelect = display.newGroup()
    menuLayers.playerSelect.alpha = 0.0
    sceneGroup:insert(menuLayers.playerSelect)

    
    y = display.screenOriginY
    
    local headerImg = display.newImageRect(menuLayers.playerSelect, 'assets/textures/matchSettings.png', 320, 80)
    headerImg.x = display.contentCenterX
    headerImg.y = y
    headerImg.anchorY = 0
    
    y = y + 80
    
    -- create a new scroll view (which will contain all settings, but not header + start button)
    local scrollOptions = {
      left = 0,
      top = y,
      width = display.contentWidth,
      height = display.contentHeight - display.screenOriginY - 80 - 0.5*buttonHeight - margin, -- full screen height, minus top part (image), minus bottom part (start button)
      backgroundColor = {0,0,0,0},
      bottomPadding = 50,
      horizontalScrollDisabled = true,
    }
    local scrollView = widget.newScrollView( scrollOptions )
    menuLayers.playerSelect:insert(scrollView)
    
    matchSettings = scrollView -- save this scroll view in more global variable, for easy access on startGame
    
    -- create image sheets for radio buttons
    local textOptions = {
      x = 10,
      font = GLOBALS.textFont,
      text = '??',
      align = 'left',
      fontSize = 24
    }
    local radioSheetOptions = {
      width = 128,
      height = 128,
      numFrames = 2,
      sheetContentWidth = 128*2,
      sheetContentHeight = 128
    }
    local sheets = {
      graphics.newImageSheet( "assets/textures/radioHuman.png", radioSheetOptions ), 
      graphics.newImageSheet( "assets/textures/radioComputer.png", radioSheetOptions ), 
      graphics.newImageSheet( "assets/textures/radioNone.png", radioSheetOptions )
    }
    local toggleSheet = graphics.newImageSheet( "assets/textures/radioToggle.png", radioSheetOptions )
    local initialStates = { true, false, false }

    for i=1,4 do
      -- create new radio button group
      local radioGroup = display.newGroup()
      scrollView:insert(radioGroup)
      radioGroup.radioNum = i
      
      local x = display.contentCenterX
      
      -- create player label text
      local touchFills = { {0.4,0,0}, {0,0,0.4}, {0,0.4,0}, {0.4,0,0.4} }
      
      textOptions.y = y
      local txt = display.newText(textOptions)
      txt.anchorX = 0
      txt.fill = touchFills[i]
      txt.text = 'Player ' .. tostring(i)
      scrollView:insert(txt)
      
      -- create three radio buttons
      for a=1,3 do
        local radioButton1 = widget.newSwitch(
        {
            style = "radio",
            width = 64,
            height = 64,
            initialSwitchState = initialStates[a],
            sheet = sheets[a],
            frameOff = 1,
            frameOn = 2
        })
        radioButton1.x = x
        radioButton1.y = y
        
        -- increase x to spread out the buttons
        x = x + 64
        radioGroup:insert( radioButton1 )
      end
      
      y = y + 64
    end
    
    -- only display advanced settings on certain occasions
    -- (e.g. we don't want to intimidate a first time user)
    local displayAdvancedSettings = (saveData.numGamesPlayed >= 1)
    
    if displayAdvancedSettings then
      -- Powerups (divider) image
      local divider = display.newImageRect('assets/textures/dividerPowerups.png', 640, 80)
      divider.x = display.contentCenterX
      divider.y = y
      divider.anchorY = 0
      
      scrollView:insert(divider)
      
      y = y + 80
      
      -- POWERUPS setting
      textOptions.y = y
      local txt2 = display.newText(textOptions)
      txt2.anchorX = 0
      txt2.fill = {0,0,0}
      txt2.text = "Powerups?"
      scrollView:insert(txt2)
      
      local powerupToggle = widget.newSwitch(
        {
            style = "checkbox",
            width = 64,
            height = 64,
            initialSwitchState = true,
            sheet = toggleSheet,
            frameOff = 1,
            frameOn = 2
        })
      powerupToggle.x = display.contentCenterX + 2*64
      powerupToggle.y = txt2.y
      powerupToggle.powerupToggle = true
      
      scrollView:insert(powerupToggle)
      
      y = y + 64
      
      -- Create link/text to show full powerup library
      local linkTextOptions = {
        x = display.contentCenterX,
        y = y - 8,
        font = GLOBALS.textFont,
        width = display.contentWidth,
        text = '(click here to see full powerup library)',
        align = 'center',
        fontSize = 16
      }
      
      local txt = display.newText(linkTextOptions)
      txt.fill = {0.5,0.5,0.5}
      scrollView:insert(txt)
      
      txt:addEventListener( "tap", onPowerupSettingTap )
      
      y = y + 24
      
      -- Match length (divider) image
      divider = display.newImageRect('assets/textures/dividerMatchLength.png', 640, 80)
      divider.x = display.contentCenterX
      divider.y = y
      divider.anchorY = 0
      
      scrollView:insert(divider)
      
      y = y + 80 - 12
      
      -- POINTS TO VICTORY
      textOptions.y = y
      local txt3 = display.newText(textOptions)
      txt3.anchorX = 0
      txt3.fill = {0,0,0}
      txt3.text = "Points until victory?"
      scrollView:insert(txt3)

      local radioGroup = display.newGroup()
      radioGroup.victoryPoints = true
      scrollView:insert(radioGroup)
      
      y = y + 24 + 0.5*64
      
      local victorySheets = {
        graphics.newImageSheet( "assets/textures/victoryPoints3.png", radioSheetOptions ),   
        graphics.newImageSheet( "assets/textures/victoryPoints5.png", radioSheetOptions ),
        graphics.newImageSheet( "assets/textures/victoryPoints10.png", radioSheetOptions ),
        graphics.newImageSheet( "assets/textures/victoryPoints15.png", radioSheetOptions ),
        graphics.newImageSheet( "assets/textures/victoryPoints20.png", radioSheetOptions ),
      }
      local initialVictoryStates = {false, false, true, false, false}
      local numPointsPerButton = {3,5,10,15,20}
      
      for i=1,5 do
        local radioButton1 = widget.newSwitch(
        {
            style = "radio",
            width = 64,
            height = 64,
            initialSwitchState = initialVictoryStates[i],
            sheet = victorySheets[i],
            frameOff = 1,
            frameOn = 2
        })
        radioButton1.x = 0 + (i-0.5)*(display.contentWidth/5)
        radioButton1.y = y
        
        radioButton1.myVictoryPoints = numPointsPerButton[i]
        
        radioGroup:insert(radioButton1)
      end
      
      -- Choose GAME MODE here
      -- Radio buttons with options: ("art hockey", "bountiful balls", "classic")
      y = y + 64
      
      -- Game Mode (divider) image
      divider = display.newImageRect('assets/textures/dividerGameMode.png', 640, 80)
      divider.x = display.contentCenterX
      divider.y = y
      divider.anchorY = 0
      
      scrollView:insert(divider)
      
      y = y + 80
      
      -- GAME MODE
      textOptions.y = y
      local txt4 = display.newText(textOptions)
      txt4.anchorX = 0
      txt4.fill = {0,0,0}
      txt4.text = "Mode?"
      scrollView:insert(txt4)
    
      radioGroup = display.newGroup()
      radioGroup.gameModes = true
      scrollView:insert(radioGroup)
      
      local gameModeSheets = {
        graphics.newImageSheet( "assets/textures/gameMode-artHockey.png", radioSheetOptions ),   
        graphics.newImageSheet( "assets/textures/gameMode-ballBountiful.png", radioSheetOptions ),
        graphics.newImageSheet( "assets/textures/gameMode-classic.png", radioSheetOptions ),
      }
      local initialModeStates = {true, false, false}
      
      for i=1,3 do
        local radioButton1 = widget.newSwitch(
        {
            style = "radio",
            width = 64,
            height = 64,
            initialSwitchState = initialModeStates[i],
            sheet = gameModeSheets[i],
            onRelease = switchGameMode,
            frameOff = 1,
            frameOn = 2
        })
        radioButton1.x = display.contentWidth - (3.5-i)*(display.contentWidth/5)
        radioButton1.y = y
        
        radioButton1.myFrame = i

        radioGroup:insert(radioButton1)
      end
      
      y = y + 32
      
      -- display sprite with explanation for this game mode
      local gameModeOptions =
      {
          --required parameters
          width = 320,
          height = 240,
          numFrames = 3,
           
          --optional parameters; used for scaled content support
          sheetContentWidth = 320*3,  -- width of original 1x size of entire sheet
          sheetContentHeight = 240*1,   -- height of original 1x size of entire sheet
      }
      local imageSheet = graphics.newImageSheet('assets/textures/modeExplanations.png', gameModeOptions)
      
      local modeImg = display.newSprite(imageSheet, { name="all", start=1, count=3 })
      modeImg.x = display.contentCenterX
      modeImg.y = y
      modeImg.width = 320
      modeImg.height = 240
      modeImg.anchorY = 0
      
      modeImg:setFrame(1)
      
      -- save this image somewhere we can access it
      gameModeImage = modeImg
      
      scrollView:insert(modeImg)
    end
    
    -- constrict scroll view width to screen width!
    -- (otherwise it will just assume the widest width of children elements)
    scrollView:setScrollWidth(display.contentWidth)
    
    
    -- finally, display the actual starting button
    -- this button is simply fixed to the bottom of the screen
    local tutButton = widget.newButton({
      defaultFile = 'assets/textures/playButton.png',
      overFile = 'assets/textures/playButtonOver.png',
      width = 320,
      height = 80,
      onRelease = buttonPressed,
    })
    
    tutButton.x = display.contentCenterX
    tutButton.y = display.contentHeight - display.screenOriginY - 0.5*buttonHeight - margin
    tutButton.myLabel = 'startGame'
    
    menuLayers.playerSelect:insert(tutButton)
    
    ---------
    -- SETTINGS LAYER
    ---------
    menuLayers.settings = display.newGroup()
    menuLayers.settings.alpha = 0.0
    sceneGroup:insert(menuLayers.settings)
    
    --local settingNames = {"Music", "Sound FX", "Vibration", "Debugging"}
    --local settingValues = {saveData.musicOn, saveData.soundOn, saveData.vibration, saveData.debuggingMode}
    
    local settingNames = {"Music", "Sound FX", "Vibration"}
    local settingValues = {saveData.musicOn, saveData.soundOn, saveData.vibration}
    
    y = display.screenOriginY
    
    headerImg = display.newImageRect(menuLayers.settings, 'assets/textures/gameSettings.png', 320, 80)
    headerImg.x = display.contentCenterX
    headerImg.y = y
    headerImg.anchorY = 0
    
    y = y + 80 + 2*margin
    
    
    for i=1,#settingNames do 
      textOptions.y = y
      textOptions.parent = menuLayers.settings
      local txt2 = display.newText(textOptions)
      txt2.anchorX = 0
      txt2.fill = {0,0,0}
      txt2.text = settingNames[i]
      
      local toggle = widget.newSwitch(
          {
              style = "checkbox",
              width = 64,
              height = 64,
              initialSwitchState = settingValues[i],
              sheet = toggleSheet,
              onRelease = toggledSetting,
              frameOff = 1,
              frameOn = 2
          })
      toggle.x = display.contentWidth - display.screenOriginX - margin
      toggle.y = y
      toggle.anchorX = 1
      toggle.isToggle = true
      toggle.mySetting = settingNames[i]
      
      menuLayers.settings:insert(toggle)
      
      y = y + 64
    end
    
    -- create back button
    local backButton = widget.newButton({
      defaultFile = 'assets/textures/backButton.png',
      overFile = 'assets/textures/backButtonOver.png',
      width = 320,
      height = 80,
      onRelease = buttonPressed,
    })
    
    backButton.x = display.contentCenterX
    backButton.y = display.contentHeight - display.screenOriginY - 0.5*buttonHeight - margin
    backButton.myLabel = "back"
    
    menuLayers.settings:insert(backButton)
    
    ------
    -- FINALLY, load the first layer
    ------
    loadScreen('mainLayer')
  end
end

function scene:hide(event) end

function scene:create(event) 
  loadGameSettings()
    
  -- play the background music (loaded from stream; loops indefinitely)
  if not GLOBALS.simulationMode then
    audio.play(GLOBALS.audioFiles.bgMusic, { channel = 1, loops = -1 })
  end
end

function scene:destroy(event) end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- VERY IMPORTANT: return the scene object
return scene

