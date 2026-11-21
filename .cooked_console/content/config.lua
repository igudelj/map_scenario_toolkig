local modId = "map_scenario_toolkit"

local function getSettings()
    if not api or not api.engine or not api.engine.config then
        return {}
    end

    local allModParams = api.engine.config.getModParams()
    return allModParams and allModParams[modId] or {}
end

return {
    getSettings = getSettings,
    isDeveloperMode = function()
        return getSettings().developerMode == 2
    end,
}