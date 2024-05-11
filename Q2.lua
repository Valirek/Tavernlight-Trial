function printSmallGuildNames(memberCount)
    local selectGuildQuery = "SELECT name FROM guilds WHERE max_members < %d;"
    local resultId = db.storeQuery(string.format(selectGuildQuery, memberCount))
    -- storeQuery in TFS can return a boolean false on failure, so we handle that here
    if not resultId then
        return
    end

    --[[ The previous solution only printed 1 name even though the query can return multiple. 
         The result table has a next method that points it at the next record for a query result. 
         We use this to iterate over every guild and print their names. ]]
    repeat
        --[[ The previous soltuion did not pass the resultId to getString, which I believe would have resulted
             in an error (based on what I see in TFS for this method). ]]
        print(result.getString(resultId, "name"))
    until not result.next(resultId)
    result.free(resultId)   -- This cleanuup was missing, it is present in TFS for every storeQuery call
end

-- Runnable Example
--[[
result = {recordCount = 2, recordIndex = 1}
function result.getString(id, name)
    return result.recordIndex == 1 and "Guild1" or "Guild2"
end
function result.next(id)
    result.recordIndex = result.recordIndex + 1
    if result.recordIndex > result.recordCount then
        return false
    end
    return true
end
function result.free(id) end

db = {}
function db.storeQuery(query)
    return 1
end

printSmallGuildNames(2)
--]]