local eventData = ug_require("/core/event_data_loader.lua")
local industrySpawns = eventData.industryEvents
local events = ug_require("/core/events.lua")

local initialTestDate

for _, spawn in ipairs(industrySpawns) do
    if spawn.trigger.type == "date" then
        local date = spawn.trigger.date
        if not initialTestDate then
            initialTestDate = {
                year = date.year,
                month = date.month,
                day = date.day,
            }
        end
    end
end

return {
    initialTestDate = initialTestDate or { year = 1940, month = 1, day = 1 },
    events = events,
    validator = eventData.validateDataset,
}


