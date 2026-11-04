local mapDataResourceType = "map_scenario_toolkit_data"
local subsidyEventRuntime = ug_require("/core/subsidy_events.lua")
local townConsumptionRuntime = ug_require("/core/town_consumption.lua")

local function isFiniteNumber(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function isInteger(value)
    return isFiniteNumber(value) and value == math.floor(value)
end

local function validateEventData(eventData, source, allowEmpty)
    if type(eventData) ~= "table" then
        log.error("Invalid " .. source .. " event data: expected a table")
        return false
    end

    local count = 0
    local maxIndex = 0
    for key in pairs(eventData) do
        if not isInteger(key) or key < 1 then
            log.error("Invalid " .. source .. " event data: expected a dense array of events")
            return false
        end
        count = count + 1
        maxIndex = math.max(maxIndex, key)
    end
    if (count == 0 and not allowEmpty) or count ~= maxIndex then
        log.error("Invalid " .. source .. " event data: expected a dense array of events")
        return false
    end

    local valid = true
    local seenIds = {}
    local function invalid(index, message)
        log.error("Invalid " .. source .. " event at index " .. index .. ": " .. message)
        valid = false
    end

    for index, event in ipairs(eventData) do
        if type(event) ~= "table" then
            invalid(index, "expected a table")
        else
            if type(event.id) ~= "string" or event.id == "" then
                invalid(index, "id must be a non-empty string")
            elseif seenIds[event.id] then
                invalid(index, "duplicate id " .. event.id)
            else
                seenIds[event.id] = true
            end

            if type(event.fileName) ~= "string" or event.fileName == "" then
                invalid(index, "fileName must be a non-empty construction resource path")
            elseif api.res.constructionRep.find(event.fileName) < 0 then
                invalid(index, "construction resource not found: " .. event.fileName)
            end
            if type(event.name) ~= "string" or event.name == "" then
                invalid(index, "name must be a non-empty string")
            end

            local trigger = event.trigger
            if type(trigger) ~= "table" then
                invalid(index, "trigger must be a table")
            elseif trigger.type == "date" then
                local date = trigger.date
                if type(date) ~= "table" or not isInteger(date.year) or date.year < 1
                    or not isInteger(date.month) or date.month < 1 or date.month > 12
                    or not isInteger(date.day) or date.day < 1 then
                    invalid(index, "date trigger requires a valid year, month, and day")
                elseif date.day > ({ 31, date.year % 4 == 0
                        and (date.year % 100 ~= 0 or date.year % 400 == 0) and 29 or 28,
                    31, 30, 31, 30, 31, 31, 30, 31, 30, 31 })[date.month] then
                    invalid(index, "date trigger day is invalid for its month")
                end
                if trigger.timeOfDaySec ~= nil
                    and (not isFiniteNumber(trigger.timeOfDaySec)
                        or trigger.timeOfDaySec < 0 or trigger.timeOfDaySec >= 24 * 60 * 60) then
                    invalid(index, "timeOfDaySec must be between 0 and 86399")
                end
            elseif trigger.type == "shipment" then
                if type(trigger.sourceIndustryFileName) ~= "string"
                    or trigger.sourceIndustryFileName == "" then
                    invalid(index, "shipment trigger requires sourceIndustryFileName")
                elseif api.res.constructionRep.find(trigger.sourceIndustryFileName) < 0 then
                    invalid(index, "source industry construction not found: " .. trigger.sourceIndustryFileName)
                end
                if type(trigger.sourceIndustryName) ~= "string" or trigger.sourceIndustryName == "" then
                    invalid(index, "shipment trigger requires sourceIndustryName")
                end
                if type(trigger.cargoTypeFileName) ~= "string" or trigger.cargoTypeFileName == "" then
                    invalid(index, "shipment trigger requires cargoTypeFileName")
                elseif api.res.cargoTypeRep.find(trigger.cargoTypeFileName) < 0 then
                    invalid(index, "cargo resource not found: " .. trigger.cargoTypeFileName)
                end
                if not isFiniteNumber(trigger.minimumShippedPerYear)
                    or trigger.minimumShippedPerYear < 0 then
                    invalid(index, "minimumShippedPerYear must be a non-negative number")
                end
            else
                invalid(index, "trigger.type must be 'date' or 'shipment'")
            end

            if event.location ~= nil then
                if type(event.location) ~= "table"
                    or type(event.location.townName) ~= "string" or event.location.townName == "" then
                    invalid(index, "location requires a non-empty townName")
                elseif event.location.directionWeights ~= nil then
                    local weights = event.location.directionWeights
                    local total = 0
                    if type(weights) ~= "table" then
                        invalid(index, "directionWeights must be a table")
                    else
                        for _, direction in ipairs({ "north", "east", "south", "west" }) do
                            local weight = weights[direction]
                            if weight == nil then
                                weight = 0
                            end
                            if not isFiniteNumber(weight) or weight < 0 then
                                invalid(index, "directionWeights must contain non-negative numbers")
                                break
                            end
                            total = total + weight
                        end
                        if total <= 0 then
                            invalid(index, "directionWeights must have a positive total")
                        end
                    end
                end
            end

            if event.rotation ~= nil
                and event.rotation ~= "random" and not isFiniteNumber(event.rotation) then
                invalid(index, "rotation must be a number or 'random'")
            end
        end
    end

    return valid
end

local function validateDataset(dataset, source)
    if type(dataset) ~= "table" then
        log.error("Invalid " .. source .. " dataset: expected an object")
        return false
    end
    local industries = dataset.industryEvents or {}
    local subsidies = dataset.subsidyEvents or {}
    local townConsumption = dataset.townConsumptionEvents or {}
    if not validateEventData(industries, source .. " industry", true)
        or not subsidyEventRuntime.validate(subsidies, source .. " subsidy")
        or not townConsumptionRuntime.validate(townConsumption, source) then
        return false
    end
    local industryIds = {}
    for _, event in ipairs(industries) do industryIds[event.id] = true end
    for index, event in ipairs(subsidies) do
        if event.trigger.type == "industrySpawned" and not industryIds[event.trigger.industryEventId] then
            log.error("Invalid " .. source .. " subsidy event at index " .. index
                .. ": unknown industryEventId " .. event.trigger.industryEventId)
            return false
        end
    end
    return true
end

local function makeDataset(industryEvents, subsidyEvents, townConsumptionEvents)
    return {
        industryEvents = industryEvents or {},
        subsidyEvents = subsidyEvents or {},
        townConsumptionEvents = townConsumptionEvents or {},
    }
end

local function loadEventData()
    if not api.res then
        return makeDataset({}, {}, {})
    end

    local customResourceIds = api.res.genericRep.getAllOfType(mapDataResourceType)
    if #customResourceIds == 0 then
        log.message("No map event dataset is registered; no bundled industry spawns are configured")
        return makeDataset({}, {})
    end

    if #customResourceIds ~= 1 then
        log.error("Found " .. #customResourceIds .. " map event data resources; expected one. No custom events will be scheduled")
        return makeDataset({}, {})
    end

    local resourceId = customResourceIds[1]
    local resourceName = api.res.genericRep.getName(resourceId)
    local resource = api.res.genericRep.get(resourceId)
    if not resource or type(resource.data) ~= "table" then
        log.error("Map event data resource is missing or malformed: " .. tostring(resourceName)
            .. ". No custom events will be scheduled")
        return makeDataset({}, {})
    end

    local resourceData = resource.data
    local dataset = (resourceData.industryEvents ~= nil
        or resourceData.subsidyEvents ~= nil
        or resourceData.townConsumptionEvents ~= nil)
        and resourceData or makeDataset(resourceData, {})
    if validateDataset(dataset, "map " .. tostring(resourceName)) then
        log.message("Using map-specific event dataset from " .. tostring(resourceName))
        return makeDataset(dataset.industryEvents, dataset.subsidyEvents, dataset.townConsumptionEvents)
    end

    log.error("Discarded invalid map event data from " .. tostring(resourceName) .. "; no custom events will be scheduled")
    return makeDataset({}, {})
end
local loadedData = loadEventData()
loadedData.validate = validateEventData
loadedData.validateDataset = validateDataset
return loadedData










