local eventData = ug_require("/core/event_data_loader.lua")
local industrySpawns = eventData.industryEvents
local events = {}

for _, spawn in ipairs(industrySpawns) do
    events[#events + 1] = {
        id = spawn.id,
        spawnId = spawn.id,
        name = "Spawn " .. spawn.name,
    }
end

return events
 

