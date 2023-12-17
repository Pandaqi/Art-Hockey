-- create one image sheet
-- (this will hold all the powerups, 1 per 128x128 frame)
local options =
{
    --required parameters
    width = 128,
    height = 128,
    numFrames = 20,
     
    --optional parameters; used for scaled content support
    sheetContentWidth = 128*5,  -- width of original 1x size of entire sheet
    sheetContentHeight = 128*4,   -- height of original 1x size of entire sheet
}

return graphics.newImageSheet('assets/textures/powerups.png', options)