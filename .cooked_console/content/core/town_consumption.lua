local fields = {
    {
        name = "consumptionCommercialSlots",
        district = "COMMERCIAL",
        cargoNeedsIndex = 2,
    },
    {
        name = "consumptionIndustrialSlots",
        district = "INDUSTRIAL",
        cargoNeedsIndex = 3,
    },
}

local cargoTypeIds = {}
local function getCargoTypeId(fileName)
    local cargoTypeId = cargoTypeIds[fileName]
    if cargoTypeId == nil then
        cargoTypeId = api.res.cargoTypeRep.find(fileName)
        cargoTypeIds[fileName] = cargoTypeId
    end
    return cargoTypeId
end

local function arrayContains(values, expected)
    for _, value in ipairs(values or {}) do
        if value == expected then return true end
    end
    return false
end

local function getCurrentEconomy()
    local baseConfig = api.res.getBaseConfig()
    local economyId = api.res.economyRep.find(baseConfig.economyId)
    if economyId < 0 then return nil end
    return api.res.economyRep.get(economyId)
end

local function validateCargoList(cargoList, field, rule, economy, invalid)
    if type(cargoList) ~= "table" then
        invalid(field .. " must be an ordered array of cargo resource paths")
        return
    end

    local count, maxIndex = 0, 0
    for key in pairs(cargoList) do
        if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
            invalid(field .. " must be a dense ordered array")
            return
        end
        count = count + 1
        maxIndex = math.max(maxIndex, key)
    end
    if count < 1 or count ~= maxIndex then
        invalid(field .. " must contain at least one cargo path")
        return
    end

    local seen = {}
    for _, fileName in ipairs(cargoList) do
        if type(fileName) ~= "string" or fileName == "" then
            invalid(field .. " entries must be non-empty cargo resource paths")
        else
            local cargoTypeId = getCargoTypeId(fileName)
            if cargoTypeId < 0 then
                invalid(field .. " cargo resource not found: " .. fileName)
            elseif seen[cargoTypeId] then
                invalid(field .. " must not list the same cargo more than once: " .. fileName)
            else
                seen[cargoTypeId] = true
                local cargoType = api.res.cargoTypeRep.get(cargoTypeId)
                local category = cargoType and economy and economy.cargoCategories and economy.cargoCategories[cargoType.category]
                local landUseTypes = api.type.enum and api.type.enum.LandUseType or api.type["enum"].LandUseType
                local landUse = landUseTypes and landUseTypes[rule.district]
                if not category or not (arrayContains(category.landUses, landUse)
                    or arrayContains(category.landUses, rule.district)) then
                    invalid(fileName .. " is not available for the " .. rule.district .. " district in the selected economy")
                end
            end
        end
    end
end

local function validate(events, source)
    if type(events) ~= "table" then
        log.error("Invalid " .. source .. " town consumption events: expected an array")
        return false
    end

    local valid = true
    local count, maxIndex = 0, 0
    for key in pairs(events) do
        if type(key) ~= "number" or key ~= math.floor(key) or key < 1 then
            log.error("Invalid " .. source .. " town consumption events: expected a dense array")
            return false
        end
        count = count + 1
        maxIndex = math.max(maxIndex, key)
    end
    if count ~= maxIndex then
        log.error("Invalid " .. source .. " town consumption events: expected a dense array")
        return false
    end

    local economy = getCurrentEconomy()
    local seenTowns = {}
    for index, event in ipairs(events) do
        local function invalid(message)
            log.error("Invalid " .. source .. " town consumption event at index " .. index .. ": " .. message)
            valid = false
        end

        if type(event) ~= "table" then
            invalid("expected an object")
        else
            if type(event.townName) ~= "string" or event.townName == "" then
                invalid("townName must be a non-empty string")
            elseif seenTowns[event.townName] then
                invalid("duplicate townName " .. event.townName)
            else
                seenTowns[event.townName] = true
            end

            local hasConfiguredList = false
            for _, rule in ipairs(fields) do
                if event[rule.name] ~= nil then
                    hasConfiguredList = true
                    validateCargoList(event[rule.name], rule.name, rule, economy, invalid)
                end
            end
            if not hasConfiguredList then
                invalid("at least one ordered commercial or industrial slot list must be provided")
            end
        end
    end
    return valid
end

local function getTownCargoNeeds(town)
    local cargoNeeds = { {}, {}, {} }
    for districtIndex = 1, 3 do
        for _, cargoTypeAndFactor in ipairs(town.cargoNeeds[districtIndex] or {}) do
            local cargoTypeId = type(cargoTypeAndFactor) == "table"
                and cargoTypeAndFactor[1] or cargoTypeAndFactor
            if cargoTypeId ~= nil then
                cargoNeeds[districtIndex][#cargoNeeds[districtIndex] + 1] = cargoTypeId
            end
        end
    end
    return cargoNeeds
end

local missingTowns = {}
local function update(events, _spawnerState)
    if #events == 0 then return false end
    local stateChanged = false
    local foundTowns = {}

    api.engine.forEachEntityWithComponent(function(townEntity)
        local name = api.engine.getComponent(townEntity, api.type.ComponentType.NAME)
        if not name then return end

        for _, event in ipairs(events) do
            if event.townName == name.name then
                foundTowns[event.townName] = true
                missingTowns[event.townName] = nil
                local town = api.engine.getComponent(townEntity, api.type.ComponentType.TOWN)
                if not town then return end
                local cargoNeeds = getTownCargoNeeds(town)
                local changed = false

                for _, rule in ipairs(fields) do
                    local configuredSlots = event[rule.name]
                    local districtIndex = rule.cargoNeedsIndex
                    local demandCount = #cargoNeeds[districtIndex]
                    local configuredSlotCount = configuredSlots and #configuredSlots or 0
                    local customSlotCount = math.min(configuredSlotCount, math.max(0, demandCount - 1))
                    local ruleChanged = false

                    for configuredIndex = 1, customSlotCount do
                        local cargoTypeId = getCargoTypeId(configuredSlots[configuredIndex])
                        local townSlotIndex = configuredIndex + 1
                        if cargoNeeds[districtIndex][townSlotIndex] ~= cargoTypeId then
                            cargoNeeds[districtIndex][townSlotIndex] = cargoTypeId
                            changed = true
                            ruleChanged = true
                        end
                    end

                    if ruleChanged then
                        log.message("Applied " .. customSlotCount .. " custom " .. rule.district
                            .. " cargo slot(s) to " .. event.townName .. "; native slot 1 is preserved")
                    end
                end

                if changed then
                    api.cmd.sendCommand(api.cmd.makeTownUpdateCargoNeedsCmd(townEntity, cargoNeeds, true))
                    stateChanged = true
                end
            end
        end
    end, api.type.ComponentType.TOWN)

    for _, event in ipairs(events) do
        if not foundTowns[event.townName] and not missingTowns[event.townName] then
            log.warning("Town consumption event is waiting for town: " .. event.townName)
            missingTowns[event.townName] = true
        end
    end

    return stateChanged
end

return {
    validate = validate,
    update = update,
}