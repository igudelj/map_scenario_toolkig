local catalog = ug_require("/utils/industry_catalog.lua")

local function getIndustry(key)
    local industry = catalog.getIndustry(key)
    if not industry then
        error("Unknown vanilla industry catalog key: " .. tostring(key))
    end

    return industry
end

local function isAvailableInClimate(key, climate)
    local industry = getIndustry(key)
    for _, availableClimate in ipairs(industry.climates) do
        if availableClimate == climate then
            return true
        end
    end

    return false
end

return {
    getIndustry = getIndustry,
    listIndustries = catalog.listIndustries,
    isAvailableInClimate = isAvailableInClimate,
}
