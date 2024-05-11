-- Assumption: The goal of this script is to remove certain storage ids from a player on logout

--[[ I updated the releaseStorage function to handle any number of storage IDs. That way if new storage
     ids ever need to be reset on logout, they can just be added to this one script easily. ]]
local function releaseStorage(player, storageIds)
    for _, id in ipairs(storageIds) do
        --[[ I changed this to check ~= -1 so that I catch if a storage is set at all.
             If the storage value ever becomes something other than 1 due to a change in game logic then
             this function will still work and reset it on logout. ]]
        if player:getStorageValue(id) ~= -1 then
            --[[ I removed the addEvent call due to a possible bad memory access issue. Looking at TFS, after
                 onLogout is called (with a true return) its possible for the player reference count to be decremented. 
                 This could result in the player object getting deleted before the callback in addEvent is triggered!
                 This would cause the C++ api to try and access invalid memory when setStorageValue is called. ]]
            --[[ If scheduling an event is required then this function just needs to return a boolean to indicate
                 if any storage was scheduled for reset. That way onLogout could return false in that case.
                 I believe returning false cancels the logout but also does not trigger the reference decrement. ]]
            player:setStorageValue(id, -1)
        end
    end
end

function onLogout(player)
    --[[ A very easy to extend release function! It is easy to see that 1000 is in a table, so other values
         can easily be added after it and all of them will be handled. ]]
    releaseStorage(player, {1000})
    return true
end


-- Runnable Example
--[[
local player = {storage = {}}
player.setStorageValue = function(self, id, val) self.storage[id] = val end
player.getStorageValue = function(self, id) return self.storage[id] end

local function printStorage(player)
    for id, val in pairs(player.storage) do
        print("ID: ", id, ", VALUE: ", val)
    end
end

player:setStorageValue(1000, 3)
player:setStorageValue(2000, 1)
print("Before\n==================")
printStorage(player)
print()

releaseStorage(player, {1000, 2000})
print("After\n====================")
printStorage(player)
--]]