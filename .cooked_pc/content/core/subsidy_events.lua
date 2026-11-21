local M = {}

local subsidyResources = {
    deliver_cargo = "::/game_mechanics/subventions/deliver_cargo/deliver_cargo.res",
    deliver_cargo_town = "::/game_mechanics/subventions/deliver_cargo_town/deliver_cargo_town.res",
    deliver_passengers = "::/game_mechanics/subventions/deliver_passengers/deliver_passengers.res",
    deliver_workers = "::/game_mechanics/subventions/deliver_workers/deliver_workers.res",
}

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function isDenseArray(value, allowEmpty)
    if type(value) ~= "table" then return false end
    local count, maxIndex = 0, 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key ~= math.floor(key) then return false end
        count, maxIndex = count + 1, math.max(maxIndex, key)
    end
    return count == maxIndex and (allowEmpty or count > 0)
end

local function validateCandidate(candidate, index, invalid)
    if type(candidate) ~= "table" or not subsidyResources[candidate.type] then
        invalid(index, "unsupported subsidy type")
        return
    end
    local target = candidate.target
    if type(target) ~= "table" then
        invalid(index, "subsidy target must be an object")
        return
    end
    if candidate.type == "deliver_cargo" or candidate.type == "deliver_workers" then
        if type(target.constructionFileName) ~= "string" or target.constructionFileName == "" then
            invalid(index, "industry subsidy target requires constructionFileName")
        elseif api.res.constructionRep.find(target.constructionFileName) < 0 then
            invalid(index, "industry subsidy construction not found: " .. target.constructionFileName)
        end
        if target.selection ~= nil and target.selection ~= "closest" and target.selection ~= "random" then
            invalid(index, "target.selection must be closest or random")
        end
        if target.nearIndustryEventId ~= nil and type(target.nearIndustryEventId) ~= "string" then
            invalid(index, "nearIndustryEventId must be a string")
        end
        if target.requiredCargoTypeFileName ~= nil then
            if type(target.requiredCargoTypeFileName) ~= "string" or target.requiredCargoTypeFileName == "" then
                invalid(index, "requiredCargoTypeFileName must be a cargo resource path")
            elseif api.res.cargoTypeRep.find(target.requiredCargoTypeFileName) < 0 then
                invalid(index, "required input cargo not found: " .. target.requiredCargoTypeFileName)
            end
        end
    elseif candidate.type == "deliver_cargo_town" then
        if type(target.townName) ~= "string" or target.townName == ""
            or type(target.cargoTypeFileName) ~= "string" or target.cargoTypeFileName == "" then
            invalid(index, "town cargo subsidy requires townName and cargoTypeFileName")
        elseif api.res.cargoTypeRep.find(target.cargoTypeFileName) < 0 then
            invalid(index, "town subsidy cargo not found: " .. target.cargoTypeFileName)
        end
    elseif candidate.type == "deliver_passengers" then
        if type(target.sourceTownName) ~= "string" or target.sourceTownName == ""
            or type(target.targetTownName) ~= "string" or target.targetTownName == "" then
            invalid(index, "passenger subsidy requires sourceTownName and targetTownName")
        end
    end
end
function M.validate(events, source)
    source = source or "subsidy"
    if not isDenseArray(events, true) then
        log.error("Invalid " .. source .. " events: expected an array")
        return false
    end
    local valid, seen = true, {}
    local function invalid(index, message)
        log.error("Invalid " .. source .. " event at index " .. index .. ": " .. message)
        valid = false
    end
    for i, event in ipairs(events) do
        if type(event) ~= "table" then
            invalid(i, "expected an object")
        else
            if type(event.id) ~= "string" or event.id == "" or seen[event.id] then
                invalid(i, "id must be a unique non-empty string")
            else
                seen[event.id] = true
            end
            local trigger = event.trigger
            if type(trigger) ~= "table" then
                invalid(i, "trigger must be an object")
            elseif trigger.type == "date" then
                local date = trigger.date
                if type(date) ~= "table" or not isFiniteNumber(date.year) or date.year < 1 or date.year ~= math.floor(date.year)
                    or not isFiniteNumber(date.month) or date.month < 1 or date.month > 12 or date.month ~= math.floor(date.month)
                    or not isFiniteNumber(date.day) or date.day < 1 or date.day > 31 or date.day ~= math.floor(date.day) then
                    invalid(i, "date trigger requires integer year, month, and day")
                elseif trigger.timeOfDaySec ~= nil and (not isFiniteNumber(trigger.timeOfDaySec)
                    or trigger.timeOfDaySec < 0 or trigger.timeOfDaySec >= 86400) then
                    invalid(i, "timeOfDaySec must be between 0 and 86399")
                end
            elseif trigger.type == "industrySpawned" then
                if type(trigger.industryEventId) ~= "string" or trigger.industryEventId == "" then
                    invalid(i, "industrySpawned trigger requires industryEventId")
                end
            elseif trigger.type == "shipment" then
                local direction = trigger.direction or "shipped"
                if direction ~= "shipped" and direction ~= "delivered" then
                    invalid(i, "shipment direction must be shipped or delivered")
                end
                local industryFileName = trigger.industryFileName or trigger.sourceIndustryFileName
                local industryName = trigger.industryName or trigger.sourceIndustryName
                if type(industryFileName) ~= "string" or industryFileName == "" then
                    invalid(i, "shipment trigger requires industryFileName")
                elseif api.res.constructionRep.find(industryFileName) < 0 then
                    invalid(i, "shipment industry construction not found: " .. industryFileName)
                end
                if type(industryName) ~= "string" or industryName == "" then
                    invalid(i, "shipment trigger requires industryName")
                end
                if type(trigger.cargoTypeFileName) ~= "string" or trigger.cargoTypeFileName == "" then
                    invalid(i, "shipment trigger requires cargoTypeFileName")
                elseif api.res.cargoTypeRep.find(trigger.cargoTypeFileName) < 0 then
                    invalid(i, "shipment cargo not found: " .. trigger.cargoTypeFileName)
                end
                local minimumPerYear = trigger.minimumShippedPerYear
                if direction == "delivered" then
                    minimumPerYear = trigger.minimumDeliveredPerYear
                end
                if not isFiniteNumber(minimumPerYear) or minimumPerYear < 0 then
                    local field = direction == "delivered"
                        and "minimumDeliveredPerYear" or "minimumShippedPerYear"
                    invalid(i, field .. " must be a non-negative number")
                end
            else
                invalid(i, "trigger.type must be date, industrySpawned, or shipment")
            end
            local subsidy = event.subsidy
            if type(subsidy) ~= "table" then
                invalid(i, "subsidy must be an object")
            elseif subsidy.type == "random" then
                if not isDenseArray(subsidy.candidates, false) then
                    invalid(i, "random subsidy requires a non-empty candidates array")
                else
                    for candidateIndex, candidate in ipairs(subsidy.candidates) do
                        validateCandidate(candidate, i, invalid)
                    end
                end
            elseif not subsidyResources[subsidy.type] then
                invalid(i, "unsupported subsidy type")
            else
                validateCandidate(subsidy, i, invalid)
            end
        end
    end
    return valid
end

local function dateReached(current, target)
    if current.year ~= target.year then return current.year > target.year end
    if current.month ~= target.month then return current.month > target.month end
    return current.day >= target.day
end

local function findTown(name)
    local found
    api.engine.forEachEntityWithComponent(function(entity)
        if found then return end
        local c = api.engine.getComponent(entity, api.type.ComponentType.NAME)
        if c and c.name == name then found = entity end
    end, api.type.ComponentType.TOWN)
    return found
end

local function getIndustryPosition(industry)
    local construction = api.engine.getComponent(industry.construction, api.type.ComponentType.CONSTRUCTION)
    if construction and construction.transf then
        return { x = construction.transf[13], y = construction.transf[14] }
    end
end

local function findTargetIndustry(selector, referencePosition, randomize, mustNotHaveProduced)
    selector = selector or {}
    local matches = {}
    api.engine.forEachEntityWithComponent(function(entity)
        local industry = api.engine.getComponent(entity, api.type.ComponentType.INDUSTRY)
        local construction = industry and api.engine.getComponent(industry.construction, api.type.ComponentType.CONSTRUCTION)
        if not construction or (selector.constructionFileName and construction.fileName ~= selector.constructionFileName) then return end
        local name = api.engine.getComponent(industry.construction, api.type.ComponentType.NAME)
            or api.engine.getComponent(entity, api.type.ComponentType.NAME)
        if selector.industryName and (not name or name.name ~= selector.industryName) then return end
        if mustNotHaveProduced and api.engine.util.stock.getCargoOutputPerYear(industry.stockList) > 0 then return end
        if selector.requiredCargoTypeFileName then
            local requiredCargoId = api.res.cargoTypeRep.find(selector.requiredCargoTypeFileName)
            local inputs = api.engine.util.stock.getInputsOutputsFromRules(industry.stockList)[1] or {}
            local hasRequiredInput = false
            for _, cargoTypeId in ipairs(inputs) do
                if cargoTypeId == requiredCargoId then hasRequiredInput = true; break end
            end
            if not hasRequiredInput then return end
        end
        local position = getIndustryPosition(industry)
        local distanceSquared = 0
        if referencePosition and position then
            local dx, dy = position.x - referencePosition.x, position.y - referencePosition.y
            distanceSquared = dx * dx + dy * dy
        end
        matches[#matches + 1] = { entity = entity, distanceSquared = distanceSquared }
    end, api.type.ComponentType.INDUSTRY)
    if #matches == 0 then return nil end
    if randomize then return matches[math.random(#matches)].entity end
    table.sort(matches, function(a, b) return a.distanceSquared < b.distanceSquared end)
    return matches[1].entity
end

local function getReferencePosition(selector, state)
    local eventId = selector and selector.nearIndustryEventId
    local constructionEntity = eventId and state.spawnedConstructions and state.spawnedConstructions[eventId]
    local construction = constructionEntity and api.engine.getComponent(constructionEntity, api.type.ComponentType.CONSTRUCTION)
    if construction and construction.transf then
        return { x = construction.transf[13], y = construction.transf[14] }
    end
end

local function resolveCandidate(candidate, state)
    local target = candidate.target or {}
    local param = { expireDurationProposed = -1 }
    if candidate.type == "deliver_cargo" or candidate.type == "deliver_workers" then
        local reference = getReferencePosition(target, state)
        local entity = findTargetIndustry(target, reference, target.selection == "random", candidate.type == "deliver_cargo")
        if not entity then return nil end
        param.target = entity
    elseif candidate.type == "deliver_cargo_town" then
        local entity = findTown(target.townName)
        local cargoTypeId = target.cargoTypeFileName and api.res.cargoTypeRep.find(target.cargoTypeFileName)
        if not entity or not cargoTypeId or cargoTypeId < 0 then return nil end
        param.target, param.cargoTypeId = entity, cargoTypeId
    elseif candidate.type == "deliver_passengers" then
        local source, destination = findTown(target.sourceTownName), findTown(target.targetTownName)
        if not source or not destination then return nil end
        param.source, param.target = source, destination
    else
        return nil
    end
    return { type = candidate.type, param = param }
end

local function fire(event, state)
    local subsidy = event.subsidy
    local selected
    if subsidy.type == "random" then
        local valid = {}
        for _, candidate in ipairs(subsidy.candidates) do
            local resolved = resolveCandidate(candidate, state)
            if resolved then valid[#valid + 1] = resolved end
        end
        if #valid > 0 then selected = valid[math.random(#valid)] end
    else
        selected = resolveCandidate(subsidy, state)
    end
    if not selected then return false end
    local uid = 0
    for index = 1, #event.id do uid = (uid * 31 + string.byte(event.id, index)) % 2147483647 end
    selected.param.uid = uid == 0 and 1 or uid
    api.cmd.sendCommand(api.cmd.makeScriptingSendEventCmd("", "Subvention", "subventionSpawn", {
        name = subsidyResources[selected.type],
        specific = selected.param,
    }))
    log.message("Triggered configured subsidy event: " .. event.id .. " (" .. selected.type .. ")")
    return true
end

local function shipmentReached(trigger)
    local cargoTypeId = api.res.cargoTypeRep.find(trigger.cargoTypeFileName)
    if cargoTypeId < 0 then return false end
    local industryFileName = trigger.industryFileName or trigger.sourceIndustryFileName
    local industryName = trigger.industryName or trigger.sourceIndustryName
    local minimumPerYear = trigger.minimumShippedPerYear
    if trigger.direction == "delivered" then
        minimumPerYear = trigger.minimumDeliveredPerYear
    end
    local reached = false
    api.engine.forEachEntityWithComponent(function(entity)
        if reached then return end
        local industry = api.engine.getComponent(entity, api.type.ComponentType.INDUSTRY)
        local construction = industry and api.engine.getComponent(industry.construction, api.type.ComponentType.CONSTRUCTION)
        if not construction or construction.fileName ~= industryFileName then return end
        local name = api.engine.getComponent(industry.construction, api.type.ComponentType.NAME)
            or api.engine.getComponent(entity, api.type.ComponentType.NAME)
        if not name or name.name ~= industryName then return end
        local cargoPerYear
        if (trigger.direction or "shipped") == "delivered" then
            cargoPerYear = api.engine.util.stock.getCargoTypeDeliveredPerYear(industry.stockList, cargoTypeId)
        else
            cargoPerYear = api.engine.util.stock.getCargoTypeShippedPerYear(industry.stockList, cargoTypeId)
        end
        reached = cargoPerYear >= minimumPerYear
    end, api.type.ComponentType.INDUSTRY)
    return reached
end

function M.update(events, state, currentDate, currentTimeOfDaySec)
    state.firedSubsidyEvents = state.firedSubsidyEvents or {}
    for _, event in ipairs(events or {}) do
        if not state.firedSubsidyEvents[event.id] then
            local trigger = event.trigger
            local due = false
            if trigger.type == "date" then
                due = dateReached(currentDate, trigger.date)
                if due and currentDate.year == trigger.date.year and currentDate.month == trigger.date.month
                    and currentDate.day == trigger.date.day and currentTimeOfDaySec < (trigger.timeOfDaySec or 0) then
                    due = false
                end
            elseif trigger.type == "industrySpawned" then
                due = state.completedSpawns and state.completedSpawns[trigger.industryEventId] == true
            elseif trigger.type == "shipment" then
                due = shipmentReached(trigger)
            end
            if due and fire(event, state) then state.firedSubsidyEvents[event.id] = true end
        end
    end
end

return M







