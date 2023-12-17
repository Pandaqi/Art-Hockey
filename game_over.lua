-----------------------------------------------------------------------------------------
--
-- game_over.lua
--
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()

local admob = nil
local widget = require("widget")

local adGroup
local adSpriteLocation

local function restartGame(event)
  composer.gotoScene("main_game", { time = 500, effect = "crossFade" })
end

local function backToMain(event)
  composer.gotoScene("main_menu", { time = 500, effect = "crossFade" })
end

local function clickAdButton(event)
  print("Clicked ad button!")
  
  admob.show( "rewardedVideo" )
end

local function clickedSocialButton(event)
  -- if we merely want to SAVE the image, do that and return
  if event.target.network == "saveImage" then
    local capturedObject = display.capture(event.target.bgCanvas, { saveToPhotoLibrary=true, captureOffscreenArea=false })
    capturedObject:removeSelf()
    
    -- swap button with success image
    local succImg = display.newImageRect(scene.view, 'assets/textures/successFeedbackButton.png', event.target.width, event.target.height)
    succImg.x = event.target.x
    succImg.y = event.target.y
    
    -- remove original button
    event.target:removeSelf()
    
    -- OLD CALL: This saves the file nicely, but doesn't work well on phones (can't save to gallery)
    --display.capture(event.target.bgCanvas, "Art Hockey - Final Painting.png")
    return
  end
  
  -- Use "Social Popup" plugin,
  --  => include drawing from game
  --  => prompt players to provide a funny caption in the message field
  --  => or error if user hasn't installed/signed in to the social network
  local serviceName = event.target.network or "twitter"
  local isAvailable = native.canShowPopup( "social", serviceName )
  
  if ( isAvailable ) then
    local listener = {}
 
    function listener:popup( event )
        print( "name: " .. event.name )
        print( "type: " .. event.type )
        print( "action: " .. tostring( event.action ) )
        print( "limitReached: " .. tostring( event.limitReached ) )
    end
 
    native.showPopup( "social",
    {
        service = serviceName,
        message = "What's a funny caption to this drawing?",
        listener = listener,
        image = 
        {
            { filename=GLOBALS.backgroundCanvas.fileName, baseDir = GLOBALS.backgroundCanvas.baseDir }
        },
        url = 
        {
            "https://play.google.com/store/apps/details?id=com.pandaqi.art_hockey",
            "http://pandaqi.com"
        }
    })
  else 
    native.showAlert(
        "Cannot send " .. serviceName .. " message.",
        "Please setup your " .. serviceName .. " account or check your network connection.",
        { "OK" } )
  end
end

local function floatImage(img)
  img.curDir = img.curDir * -1
  if img.curDir == 1 then
    transition.to(img, { y = img.y - 10, time = 1000, onComplete = floatImage })
  else
    transition.to(img, { y = img.y + 10, time = 1000, onComplete = floatImage })
  end
end

function returnFromRewardedAd()
  -- remove the ad group
  adGroup:removeSelf()
  
  -------
  -- The ads can MESS with our navigation settings => so reset it
  --------
  -- hide the status bar (iOS)
  display.setStatusBar( display.HiddenStatusBar )

  -- Removes status bar on Android
  -- NOTE: Might want to include a setting to disable this, as it's annoying when it keeps popping up/going away!
  if system.getInfo( "androidApiLevel" ) and system.getInfo( "androidApiLevel" ) < 19 then
      native.setProperty( "androidSystemUiVisibility", "lowProfile" )
  else
      native.setProperty( "androidSystemUiVisibility", "immersiveSticky" ) 
  end
  
  -- display a congratulations image
  local img = display.newImageRect(scene.view, 'assets/textures/unlock-success.png', 320, 480*0.5)
  img.x = adSpriteLocation.x
  img.y = adSpriteLocation.y
  img.anchorY = 0
end

function scene:show(event)
  local sceneGroup = scene.view
  
  -- make sure to fully destroy the main game
  composer.removeScene("main_game")
  
  -- update some properties
  -- (such as number of games played)
  local saveData = GLOBALS.loadTable('save_data.json')
  saveData.numGamesPlayed = saveData.numGamesPlayed + 1
  GLOBALS.saveTable(saveData, 'save_data.json')
  
  -------
  -- BACKGROUND
  --------
  local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
  bg.fill = GLOBALS.beigeBackground
  
  if event.phase == 'did' then
    
    -- reset repeat effect to get rid of those annoying errors
    -- that textures need to be a power-of-two (on mobile devices)
    display.setDefault( "textureWrapX", "clampToEdge" )
    display.setDefault( "textureWrapY", "clampToEdge" )
    
    -------------
    -- Initialize some settings for placement of all UI items
    -------------
    
    local curX = display.contentCenterX
    local curY = 20
    local buttonHeight = 60
    local margin = 10
    
    local y = display.screenOriginY + margin
    
    -- display an image that shows which player won!
    local winnerImg = display.newImageRect(sceneGroup, 'assets/textures/winnerImage-' .. GLOBALS.winningPlayer .. '.png', 320, 80)
    winnerImg.x = display.contentCenterX
    winnerImg.y = y
    winnerImg.anchorY = 0
    
    y = y + 80
    
    local buttonSettings = {
          label= "BLALA",
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
    
    local rewardedVideoAvailable = false
    if system.getInfo("platformName") ~= "Win" then
      admob = require( "plugin.admob" )
      rewardedVideoAvailable = admob.isLoaded( "rewardedVideo" )
    end
    local randomSocialElement = (math.random() <= 0.85) -- most of the time, it displays a rewarded video; sometimes, though, it shows a social popup
    
    -- determine a random powerup the user doesn't have yet
    local unlockedPowerups = saveData.unlockedPowerups
    local shuffledPowerups = table.shuffle(GLOBALS.allPowerups)
    local wantedPowerup = nil
    for i=1,#shuffledPowerups do
      local v = shuffledPowerups[i]
      if not table.hasValue(unlockedPowerups, v) then
        wantedPowerup = v
        break
      end
    end
    
    print("Is rewarded video available? ", rewardedVideoAvailable)
    
    -- if we want to display an ad, and it's available, and there's a powerup to dish out ... DISPLAY EVERYTHING
    -- (we OVERRIDE this when using debugging mode, for testing ads on computer)
    if (randomSocialElement and rewardedVideoAvailable and wantedPowerup) then
      adGroup = display.newGroup()
      sceneGroup:insert(adGroup)

      -- remember this powerup, so we can give it to the player once he finishes watching the ad
      GLOBALS.wantedPowerup = wantedPowerup
      
      local adButtonSettings = {
        onRelease = clickAdButton,
        defaultFile = 'assets/textures/unlockButton.png',
        overFile = 'assets/textures/unlockButtonOver.png',
        width = 320,
        height = 80,
      }

      y = y + 0.5*buttonHeight
      
      local adButton = widget.newButton(adButtonSettings)
      adButton.x = display.contentCenterX
      adButton.y = y
      
      -- save location, so I know where to display the success image
      adSpriteLocation = { x = adButton.x, y = adButton.y - 0.5*buttonHeight}
      
      adGroup:insert(adButton)
      
      -- display text that explains what happens when you press the button
      y = y + buttonHeight - 16
      local textOptions = {
        parent = adGroup,
        x = display.contentCenterX,
        y = y,
        font = GLOBALS.textFont,
        width = display.contentWidth,
        text = '(watch rewarded ad)',
        align = 'center',
        fontSize = 16
      }
      
      local txt = display.newText(textOptions)
      txt.fill = {0.5,0.5,0.5}
      
      y = y + 12

      -- display (unlock) image with powerup explanation
      local img = display.newImageRect(adGroup, 'assets/textures/unlock-' .. wantedPowerup .. '.png', 320, 240)
      img.x = display.contentCenterX
      img.y = y
      img.anchorY = 0
      img.curDir = 1
      
      floatImage(img)
      
      y = y + 480*0.5
    else
      -- Text that actually explains what the (social) buttons do
      y = y + 12
      
      local textOptions = {
          parent = sceneGroup,
          x = display.contentCenterX,
          y = y,
          font = GLOBALS.textFont,
          width = display.contentWidth,
          text = 'Look at your beautiful painting!',
          align = 'center',
          fontSize = 16
        }
        
      local txt = display.newText(textOptions)
      txt.fill = {0.5,0.5,0.5}
      
      y = y + 12
      
      --------
      -- Display the background canvas!
      -- This contains all the lines you've drawn this game, on top of each other
      -- You're able to caption it + share it
      --------
      
      -- create a backdrop for the image
      local aW = display.actualContentWidth
      local aH = display.actualContentHeight
      
      y = y + 0.5*0.4*aH + margin
      
      -- Display the background canvas (create sprite for it; invalidate texture so that it actually UPDATES)
      local backgroundImage = display.newImageRect(GLOBALS.backgroundCanvas.filename, GLOBALS.backgroundCanvas.baseDir, display.actualContentWidth, display.actualContentHeight)
      backgroundImage.x = display.contentCenterX
      backgroundImage.y = y
      backgroundImage.width = 0.4*aW
      backgroundImage.height = (aH / aW) * backgroundImage.width
      
      GLOBALS.backgroundCanvas:invalidate()
      
      backgroundImage.stroke = {0.2, 0.2, 0.2}
      backgroundImage.strokeWidth = 5
      
      -- Add a shadow
      local shadow = display.newImageRect(sceneGroup, 'assets/textures/dropShadow.png', backgroundImage.width + 30, backgroundImage.height + 30)
      shadow.x = display.contentCenterX
      shadow.y = backgroundImage.y
      
      -- Insert image latest, so it's on top of shadow and stuff
      sceneGroup:insert(backgroundImage)
     
      y = y + 0.5*0.4*aH + margin
      
      local tempButtonSettings = {
        width = 80,
        height = 80,
        onRelease = clickedSocialButton
      }
      
      local networkNames = {"twitter", "facebook", "saveImage"}
      
      for i=1,3 do
        tempButtonSettings.defaultFile = 'assets/textures/'.. networkNames[i] .. 'Button.png'
        tempButtonSettings.overFile = 'assets/textures/'.. networkNames[i] .. 'ButtonOver.png'

        local socialButton = widget.newButton(tempButtonSettings)
        socialButton.x = display.contentCenterX + 0.25*(i-2)*aW
        socialButton.y = y
        socialButton.network = networkNames[i]
        sceneGroup:insert(socialButton)
        
        if i == 3 then
          socialButton.bgCanvas = backgroundImage
        end
      end
    end
    
    -- display the other buttons (restart/menu/etc.) from the bottom
    -- in reverse, upwards (so restart is ABOVE back to menu)
    buttonSettings.fontSize = 24
    buttonSettings.width = 320 - margin*2
    
    y = display.contentHeight - display.screenOriginY - 0.5*buttonHeight - margin
    
    local buttonTexts = {"back", "restart"}
    local buttonCallbacks = {backToMain, restartGame}
    for i=1,2 do
      -- display buttons for selecting player count
      local tutButton = widget.newButton({
        defaultFile = 'assets/textures/' .. buttonTexts[i] .. 'Button.png',
        overFile = 'assets/textures/' .. buttonTexts[i] .. 'ButtonOver.png',
        width = 320,
        height = 80,
        onRelease = buttonCallbacks[i],
      })
      
      tutButton.x = curX
      tutButton.y = y
      tutButton.playerCount = i
      
      sceneGroup:insert(tutButton)
      
      y = y - buttonHeight - 2*margin
    end

  end
end

function table.hasValue(tbl, v)
  for i=1,#tbl do
    if tbl[i] == v then
      return true
    end
  end
  return false
end

function scene:hide(event) end

function scene:create(event) end

function scene:destroy(event) 
  -- release the background canvas
  -- (if it still exists => TO DO: should probably be more careful about properly destroying scenes on exit)
  if GLOBALS.backgroundCanvas then
    GLOBALS.backgroundCanvas:releaseSelf() -- apparently, textures need the "releaseSelf()" call instead!
    GLOBALS.backgroundCanvas = nil
  end
  
  -- release the paint canvas
  if GLOBALS.paintCanvas then
    GLOBALS.paintCanvas:releaseSelf()
    GLOBALS.paintCanvas = nil
  end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- VERY IMPORTANT: return the scene object
return scene

