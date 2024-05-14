-- These could be global, but I made them local since I use pretty generic names like "menuButton"
-- This should avoid any accidental messing with global variables
local menuButton = nil
local jumpWindow = nil
local jumpButton = nil
local playing = false
local updateButtonEvent = nil

local TICK_RATE = 100   -- How long to wait in msec before ticks (a.k.a. button movements)
local BUTTON_SPEED = 10 -- How many pixels to move the button per tick

--[[ I made this table as a useful way to group functions that get the bounds of button movement.
     The reason I did this, instead of just making constants, is that 2 of the fields (max X and max Y)
     are dependent on the current width/height of the window. I didn't want to assume the width
     or height were constant so doing this enables them to change and the logic to still work! ]]
local buttonBounds = {
    -- padding of 10 pixels from the left side of the window
    getMinX = function() return 10 end,
    -- We have to account for the jump button width to see if its right side has hit the window right side
    -- We also add a padding of 10 pixels here
    getMaxX = function() return jumpWindow:getWidth() - jumpButton:getWidth() - 10 end,
    -- padding of 30 pixels from the top of the window (accounting for title bar)
    getMinY = function() return 30 end,
    -- Similar to getMaxX. We account for the jump button's height to see if its bottom has hit the bottom of the window
    -- We also add a padding of 10 pixels
    getMaxY = function() return jumpWindow:getHeight() - jumpButton:getHeight() - 10 end
}

-- This function is called on load via the .otmod file
function init()
    -- I made a button on OTClient so I could easily access my menu. I just reuse the terminal image for the button.
    menuButton = modules.client_topmenu.addLeftGameButton('Q7', 'Jumping Game', '/images/topbuttons/terminal', toggle)
    jumpWindow = g_ui.displayUI('Q7')
    jumpWindow:setVisible(false)

    --[[ I use the button defined in the .otui file here. That way I don't have to create and destroy a button every time
         this window is shown, which should be slightly more efficient. ]]
    jumpButton = jumpWindow:getChildById('jumpButton')
end

-- This function is called on unload via the .otmod file
function terminate()
    jumpWindow:destroy()
    menuButton:destroy()
end

-- This is called every time the gui button is pressed, which will toggle the window.
function toggle()
    if not jumpWindow:isVisible() then
        startPlay()
    else
        stopPlay()
    end
end

-- This function handles resetting the button to a new Y position and begins the process of it moving across the screen
function resetButton()
    --[[ This cancels any scehduled event to move the button. This function already starts the button's movement event
         by calling updateButton. If we didn't remove the event here then updateButton would be getting triggered in
         2 separate event loops with different X and Y values. ]]
    if updateButtonEvent then
        removeEvent(updateButtonEvent)
        updateButtonEvent = nil
    end

    -- Start the button at its max X value (to the right of the window) and randomly place it in a valid Y position
    updateButton(buttonBounds.getMaxX(), math.random(buttonBounds.getMinY(), buttonBounds.getMaxY()))
end

-- This button begins an event loop to move the button from the right to the left of the window every tick.
--[[ I use the names "relX" and "relY" because these are not true X and Y values. These are X and Y values that 
     are relative to the window this button is in.
     For example an X value of 10 means "10 pixels from the left side of the window" ]]
function updateButton(relX, relY)
    -- This breaks us out of the event loop if the window is closed
    if not playing then
        return
    end

    -- The buttonBounds table makes this easy to read. If we go beyond our minimum X then we hit the left side of the window!
    -- This will reset the button to a new position
    if relX <= buttonBounds.getMinX() then
        resetButton()
    else
        -- Adding to the window's x and y enables this logic to work no matter where the window is dragged to
        jumpButton:move(relX + jumpWindow:getX(), relY + jumpWindow:getY())
        -- Subtracting BUTTON_SPEED means we move that many pixels to the left next tick
        updateButtonEvent = scheduleEvent(function() updateButton(relX - BUTTON_SPEED, relY) end, TICK_RATE)
    end
end

function startPlay()
    jumpWindow:show()
    jumpWindow:raise()
    jumpWindow:focus()

    playing = true
    resetButton()   -- resetButton also starts the event loop for updateButton so this begins the button's movement
end

function stopPlay()
    jumpWindow:hide()
    playing = false
end