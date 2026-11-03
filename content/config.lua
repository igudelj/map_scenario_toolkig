local modId = "map_scenario_toolkit"

local function getSettings()
    local allModParams = api.engine.config.getModParams()
    return allModParams[modId] or {}
end

return {
    getSettings = getSettings,
    isDeveloperMode = function()
        return getSettings().developerMode == 2
    end,
}