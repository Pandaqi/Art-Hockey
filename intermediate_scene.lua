local composer = require("composer")
local scene = composer.newScene()

function scene.loadActualGame()
  composer.removeScene( "main_menu", true)
    
  -- with a fancy transition (need to learn how those work...)
  composer.gotoScene( "main_menu", { time = 500, effect = "crossFade" })
end

function scene:show(event)
  if event.phase == 'did' then
  
    local delayVal = 500
    if system.getInfo( "environment" ) == "simulator" then
      delayVal = 0
    end
    
    --  Only apply this delay if we're outside of corona simulator!
    timer.performWithDelay(delayVal, scene.loadActualGame)
  end
end

function scene:hide(event)
  
end

function scene:create(event)
  
end

function scene:destroy(event)
  
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- VERY IMPORTANT: return the scene object
return scene

