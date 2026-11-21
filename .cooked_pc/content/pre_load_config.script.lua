local modId = "map_scenario_toolkit"

function data()
    return {
        preRunFn = function(_captureParams, _configDict, allModParams, baseConfig)
            local settings = allModParams[modId] or {}

            if settings.enableNativeSubsidyOffers == 2 then
                baseConfig.advancedOptions.subventionMode = 0
            end

            if settings.enableNativeIndustrySpawns == 2 then
                baseConfig.economy.industryDevelopment.spawnIndustries = false
            end
        end,
    }
end