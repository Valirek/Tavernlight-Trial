--[[ This is the area matching the example. 
     The 2 in the center indicates that the spell should not be cast on the tile
     that the caster is on. ]]
local AREA = {
    {0, 0, 0, 1, 0, 0, 0},
    {0, 0, 1, 1, 1, 0, 0},
    {0, 1, 1, 1, 1, 1, 0},
    {1, 1, 1, 2, 1, 1, 1},
    {0, 1, 1, 1, 1, 1, 0},
    {0, 0, 1, 1, 1, 0, 0},
    {0, 0, 0, 1, 0, 0, 0}
}

-- EFFECT is acting as an enum for the different types of tornados that can appear on tiles for this spell
local EFFECT = {NONE = 0, SMALL_TORNADO = 1, BIG_TORNADO = 2}

-- We want to limit how long each tornado lasts, this variable controls that
local MAX_TICKS = 5

-- These functions just are helpers to make code more readable later on
local function isEven(num)
    return num % 2 == 0
end

local function isOdd(num)
    return not isEven(num)
end

-- Determines the effect to draw at position
local function getEffect(caster, position)
    -- Find the offset from this tile to the caster of the spell
    local offset = {x = position.x - caster:getPosition().x, y = position.y - caster:getPosition().y}

    --[[ This logic allows us to check what type of tornado is at this position.
         Big tornados are always at odd X offsets and even Y offsets, the reverse is true for small tornados.
         If both X and Y are odd/even then no effect is on this tile.
         Technically this relies on how the effect is animated on the client, but I liked this approach because
         then we can more naturally control when each type of tornado appears on a tile (a.k.a. controlling the
         "flicker" of the small tornados). ]]
    if isOdd(offset.x) and isEven(offset.y) then
        return EFFECT.BIG_TORNADO
    elseif isEven(offset.x) and isOdd(offset.y) then
        return EFFECT.SMALL_TORNADO
    end
    return EFFECT.NONE
end

-- Updates the drawing and damage of an effect at position
local function updateEffect(casterId, effect, position, tick)
    --[[ Small tornados "flicker" at a constant rate
         We do this by drawing the tornado when the tick is even and not drawing it when odd.
         This causes the tornado to toggle every half a second (due to our 500 msec event) ]]
    if effect == EFFECT.SMALL_TORNADO and isEven(tick) then
        position:sendMagicEffect(CONST_ME_NONE)
    else
        --[[ And here we deal some damage! The min and max values (-10,-100) are just randomly chosen.
             I decided to only cause damage if the effect was drawn. I think this adds more skill to the 
             ability and allows enemies/players that are hit a chance to react or even navigate through 
             it if skilled enough! ]]
        -- The 0 parameter is important, I believe it signifies that we only want the damage on this exact position.
        doAreaCombat(casterId, COMBAT_ICEDAMAGE, position, 0, -10, -100, CONST_ME_ICETORNADO)
    end

    -- Each effect only lasts 5 "ticks" (a.k.a. 5 callbacks to this function)
    tick = tick + 1
    if tick <= MAX_TICKS then
        --[[ We use a constant rate here (500 msec) to match the seemingly constant flicker 
             for small tornados in the video. ]]
        addEvent(updateEffect, 500, casterId, effect, position, tick)
    end
end

-- Callback when the spell is cast on a tile
function onTargetTile(caster, position)
    -- Looking at TFS, the caster may be nill, so we catch that here to return gracefully
    if not caster then
        return
    end

    --[[ No need to trigger the effect logic for tiles that never have tornados on them. I believe the old Tibia
         spell "eternal winter" does damage on all area of effect tiles (even if tornados don't show up there).
         I like this approach more because what the user sees on screen directly relates to damage. A.k.a. no taking
         damage on a tile that doesn't have a tornado. ]]
    local effect = getEffect(caster, position)
    if effect == EFFECT.NONE then
        return
    end

    -- The effect start is randomized, matching the seemingly random appearing of tornados in the video
    addEvent(updateEffect, math.random(100, 1000), caster:getId(), effect, position, 1)
end

local combat = Combat()
combat:setArea(createCombatArea(AREA))
combat:setCallback(CALLBACK_PARAM_TARGETTILE, "onTargetTile") -- This will be called for every tile in the spell area

function onCastSpell(creature, variant, isHotkey)
    return combat:execute(creature, variant)
end