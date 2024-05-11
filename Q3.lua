-- More descriptive name that follows the camelCase style of other functions
function removeMemberFromPlayerParty(playerId, memberName)
    --[[ The create player logic that this calls in TFS can return nil if a player with 
         that id does not exist, so we check for that and exit early if so. ]]
    -- I also made player local to avoid creating/affecting a global
    local player = Player(playerId)
    if not player then
        return
    end

    --[[ Similarly, a player may not have a party. TFS will return nil in this case, so we check for that
         and exidt early if so. ]]
    local party = player:getParty()
    if not party then
        return
    end

    -- The key is not used for anything meaningful so I use _ to designate it is not needed
    for _, member in pairs(party:getMembers()) do
        --[[ Looking at TFS, I believe the previous method would have worked since __eq is defined and compares
             the pointers of 2 player objects. Assuming that a unique player only exists once in memory on the
             server then the pointers would compare equal and the check would have worked.
             I choose to check the name directly here because I think it is easier to read at a glance and it 
             avoids having to lookup the player by name on the server multiple times. ]]
        if member:getName() == memberName then
            party:removeMember(member)
        end
    end
end


-- Runnable Example
--[[
local player = {}
local member = {}

local party = {members = {player, member}}
function party.getMembers(self)
    return self.members
end
function party.removeMember(self, member)
    for idx, player in pairs(self.members) do
        if player == member then
            table.remove(self.members, idx)
            return
        end
    end
end

function Player(id)
    return player
end
function player.getParty()
    return party
end
function player.getName()
    return "player"
end

function member.getName()
    return "member"
end

local function getPartyNames()
    local names = {}
    for _, member in pairs(party.members) do
        names[#names+1] = member:getName()
    end
    return table.concat(names, ", ")
end
print("Party members before removal: ", getPartyNames())
removeMemberFromPlayerParty(99, "member")
print("Party members after removal: ", getPartyNames())
--]]