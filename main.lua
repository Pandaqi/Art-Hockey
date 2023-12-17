-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- make stuff full screen
native.setProperty("windowMode", "fullscreen")

-- hide the status bar (iOS)
display.setStatusBar( display.HiddenStatusBar )

-- Removes status bar on Android
-- NOTE: Might want to include a setting to disable this, as it's annoying when it keeps popping up/going away!
if system.getInfo( "androidApiLevel" ) and system.getInfo( "androidApiLevel" ) < 19 then
    native.setProperty( "androidSystemUiVisibility", "lowProfile" )
else
    native.setProperty( "androidSystemUiVisibility", "immersiveSticky" ) 
end

--------
-- ASK FOR STORAGE PERMISSION
--------
local function isStoragePermissionGranted( grantedAppPermissionsTable )
    for k,v in pairs( grantedAppPermissionsTable ) do
         if ( v == "Storage" ) then
             print( "** Storage permission granted! **" )
             return true
         end
    end
    return false
end

local function appPermissionsListener( event )
    if ( isStoragePermissionGranted( event.grantedAppPermissions ) ) then
        -- Do stuff requiring storage permission
    else
        -- Handle not having storage permission
    end
end

if system.getInfo('androidApiLevel') then
  if not isStoragePermissionGranted( system.getInfo( "grantedAppPermissions" ) ) then
      if ( native.canShowPopup( "requestAppPermission" ) ) then
          -- Request Storage Permission.
          local options =
          {
              appPermission = "Storage",
              listener = appPermissionsListener,
          }

          native.showPopup( "requestAppPermission", options )
      else
          -- You need to add a permission in the Storage group to your build.settings.
      end
  end 
end

----------
-- END OF STORAGE PERMISSIONS ASKER
----------

-- include the Corona "composer" module
local composer = require "composer"

-- activate multitouch (WHY IS THIS OFF BY DEFAULT??)
system.activate( "multitouch" )

-- randomly seed math stuff
math.randomseed( os.time() )

-- one global variable to hold everything!
-- this also initializes to the DEFAULT values for everything (in case of first time user/no save data to draw from)
GLOBALS = {}
GLOBALS.mainFont = 'assets/fonts/sketchy.ttf'
GLOBALS.textFont = 'assets/fonts/Sriracha.ttf'
GLOBALS.maxPoints = 5
GLOBALS.gameMode = 1
GLOBALS.simulationMode = false
GLOBALS.resumeSimulation = false
GLOBALS.gameSpeed = 1
GLOBALS.beigeBackground = {251/255, 240/255, 226/255}

------------
-- ADS
-------------
GLOBALS.adListener = function( event )
 if ( event.phase == "init" ) then 
    -- Successful initialization
    print("Initialization Succesful!")

  elseif ( event.phase == "failed" ) then  -- The ad failed to load
    print( event.type )
    print( event.isError )
    print( event.response )
  end
  
  -- Checks if a rewardedVideo was closed AND fully played
  -- (rewardedVideos can also be static/interactive, 
  --  which is why we can't just listen to playbackEnded events)
  if event.data ~= nil and event.type == "rewardedVideo" and event.phase == "reward" then
      -- event.data.name and event.data.reward should contain JSON data with reward
      -- Give the reward! Add the new powerup to the list of unlocked powerups
      local saveData = GLOBALS.loadTable('save_data.json')
      
      table.insert(saveData.unlockedPowerups, GLOBALS.wantedPowerup)
      
      GLOBALS.saveTable(saveData, 'save_data.json')
      GLOBALS.powerupsAreEnabled = true -- immediately enable powerups
      
      -- call function in game over scene
      returnFromRewardedAd()
  end
end

if system.getInfo("platformName") ~= "Win" then
  local admob = require( "plugin.admob" )
  
  local adSettings = { appId="ca-app-pub-7465988806111884~5463435628" }
  admob.init( GLOBALS.adListener, adSettings )
end

-----------
-- FILE MANAGEMENT (save/load/create files)
-- For saving game data and settings, and retrieving them of course
-----------
local json = require( "json" )
local defaultLocation = system.DocumentsDirectory
--local defaultLocation = system.ProjectDirectory

-- General functions (for loading/saving stuff)
GLOBALS.loadTable = function( filename, location )
    local loc = location
    if not location then loc = defaultLocation end
 
    -- Path for the file to read
    local path = system.pathForFile( filename, loc )
 
    -- Open the file handle
    local file, errorString = io.open( path, "r" )
 
    if not file then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
        return false
    else
        -- Read data from file
        local contents = file:read( "*a" )
        -- Decode JSON data into Lua table
        local t = json.decode( contents )
        -- Close the file handle
        io.close( file )
        -- Return table
        return t
    end
end

GLOBALS.saveTable = function( t, filename, location )
    local loc = location
    if not location then loc = defaultLocation end
 
    -- Path for the file to write
    local path = system.pathForFile( filename, loc )
 
    -- Open the file handle
    local file, errorString = io.open( path, "w" )
 
    if not file then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
        return false
    else      
        -- Write encoded JSON data to file
        file:write( json.encode( t ) )
        -- Close the file handle
        io.close( file )
        return true
    end
end

GLOBALS.createSaveFile = function()
  -- this is the initial save data object with all the default settings
  -- NOTE: I use this to already insert a few basic, unlocked powerups. 
  -- (Why? These are the most boring powerups and need no explanation, yet they are a "gift" and will make the player feel nice about it)
  local saveData = { 
    numGamesPlayed = 0, 
    unlockedPowerups = {'obstacleSquare', 'obstacleCircle', 'extraInk', 'penaltyInk'},
    musicOn = true,
    soundOn = true,
    debuggingMode = false,
    vibration = true
  }
  
  GLOBALS.saveTable(saveData, 'save_data.json')
  
  return saveData
end

-- check if save file exists; if not, create it
if not GLOBALS.loadTable('save_data.json') then
  GLOBALS.createSaveFile()
end

-----------
-- Game pausing/game state management
-----------
GLOBALS.pauseGame = function()
  GLOBALS.paused = true
  physics.pause()
end

GLOBALS.unPauseGame = function()
  GLOBALS.paused = false
  physics.start()
end
    

----------
-- AUDIO
-- Load all necessary audio files once, here, and save in global variable
----------
GLOBALS.audioFiles = {
  bgMusic = audio.loadStream( "assets/audio/bgMusic.mp3" ),
  chalk1 = audio.loadSound( "assets/audio/chalk1.mp3" ),
  chalk2 = audio.loadSound( "assets/audio/chalk2.mp3" ),
  chalk3 = audio.loadSound( "assets/audio/chalk3.mp3" ),
  chalk4 = audio.loadSound( "assets/audio/chalk4.mp3" ),
  powerup = audio.loadSound( "assets/audio/powerup.wav" ),
  bounce = audio.loadSound( "assets/audio/bounce.mp3" ),
  score = audio.loadSound( "assets/audio/score.mp3" )
}

display.setDefault( "background", GLOBALS.beigeBackground )

-- load menu screen
composer.gotoScene( "intermediate_scene" )