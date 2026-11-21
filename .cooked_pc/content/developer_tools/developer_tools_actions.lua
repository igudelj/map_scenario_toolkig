local townCargoUtil = ug_require("::/game_mechanics/towns/town_cargo_util.tl")

local function setTestDate(date)
    local apiDate = api.type.Date.new(date.year, date.month, date.day)
    log.message(string.format("Developer requested test date %04d-%02d-%02d", date.year, date.month, date.day))
    api.cmd.sendCommand(api.cmd.makeGameSetDateCmd(apiDate), function(_, success)
        if success then
            log.message(string.format("Developer set game date to %04d-%02d-%02d", date.year, date.month, date.day))
        else
            log.warning("Developer tool failed to set game date")
        end
    end)
end

local function sendEvent(name, param, description)
    api.cmd.sendCommand(api.cmd.makeScriptingSendEventCmd(
        "",
        "map_scenario_toolkit",
        name,
        param
    ), function(_, success)
        if success then
            log.message("Developer tool requested: " .. description)
        else
            log.error("Developer tool failed: " .. description)
        end
    end)
end

local function grantTownExperience(townEntity, fractionOfLevelRequirement)
    local fraction = math.max(0.01, math.min(1, tonumber(fractionOfLevelRequirement) or 0.01))
    local townData = townCargoUtil.getTownCargoState(townEntity)
    if not townData or type(townData.experience) ~= "number" then
        log.warning("Developer town experience ignored because town growth state is unavailable; entity = " .. tostring(townEntity))
        return
    end

    local _, _, currentLevelExperience, nextLevelExperience = townCargoUtil.getLevelAndFraction(townData.experience)
    local experiencePerLevel = math.max(1, nextLevelExperience - currentLevelExperience)
    local amount = math.max(1, math.ceil(experiencePerLevel * fraction))

    api.cmd.sendCommand(api.cmd.makeScriptingSendEventCmd(
        "",
        "Towns",
        "_debugAddExperience",
        {
            entity = townEntity,
            amount = amount,
        }
    ), function(_, success)
        if success then
            log.message("Developer tool added " .. amount .. " direct experience points to town entity " .. tostring(townEntity))
        else
            log.error("Developer tool failed to add town experience to entity " .. tostring(townEntity))
        end
    end)
end

return {
    setTestDate = setTestDate,
    sendEvent = sendEvent,
    grantTownExperience = grantTownExperience,
    resetMap = function()
        sendEvent("developerResetMap", {}, "map test changes reset")
    end,
}