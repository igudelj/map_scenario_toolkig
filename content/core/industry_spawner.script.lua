local defaultEventData = ug_require("/core/event_data_loader.lua")
local subsidyEventRuntime = ug_require("/core/subsidy_events.lua")
local townConsumptionRuntime = ug_require("/core/town_consumption.lua")
local validateDataset = defaultEventData.validateDataset
local function getIndustrySpawns(spawnerState)
    local combined, seen = {}, {}
    for _, list in ipairs({ defaultEventData.industryEvents or {}, spawnerState and spawnerState.customIndustrySpawns or {} }) do
        for _, event in ipairs(list) do
            if not seen[event.id] then
                seen[event.id] = true
                combined[#combined + 1] = event
            end
        end
    end
    return combined
end
local function getSubsidyEvents(spawnerState)
    local combined = {}
    for _, event in ipairs(defaultEventData.subsidyEvents or {}) do combined[#combined + 1] = event end
    for _, event in ipairs(spawnerState and spawnerState.customSubsidyEvents or {}) do combined[#combined + 1] = event end
    return combined
end
local function getTownConsumptionEvents(spawnerState)
    local eventsByTown, combined = {}, {}
    local fields = {
        "consumptionCommercialSlots",
        "consumptionIndustrialSlots",
    }

    for _, eventList in ipairs({
        defaultEventData.townConsumptionEvents or {},
        spawnerState and spawnerState.customTownConsumptionEvents or {},
    }) do
        for _, event in ipairs(eventList) do
            local merged = eventsByTown[event.townName]
            if not merged then
                merged = { townName = event.townName }
                eventsByTown[event.townName] = merged
                combined[#combined + 1] = merged
            end
            for _, field in ipairs(fields) do
                if event[field] ~= nil then merged[field] = event[field] end
            end
        end
    end

    return combined
end
local cargoTypeIds = {}
local missingCargoTypes = {}
local missingTowns = {}
local roadConnectionCheckUnavailableLogged = false
local queuedSpawnCompletions = {}

local function getConstructionSeed(spawnId)
    local seed = 0
    for index = 1, #spawnId do
        seed = (seed * 31 + string.byte(spawnId, index)) % 2147483647
    end

    return seed == 0 and 1 or seed
end

local function isDateReached(currentDate, targetDate)
    if currentDate.year ~= targetDate.year then
        return currentDate.year > targetDate.year
    end
    if currentDate.month ~= targetDate.month then
        return currentDate.month > targetDate.month
    end
    return currentDate.day >= targetDate.day
end

local function getCargoTypeId(cargoTypeFileName)
    local cargoTypeId = cargoTypeIds[cargoTypeFileName]
    if cargoTypeId == nil then
        cargoTypeId = api.res.cargoTypeRep.find(cargoTypeFileName)
        cargoTypeIds[cargoTypeFileName] = cargoTypeId
    end

    if cargoTypeId < 0 then
        if not missingCargoTypes[cargoTypeFileName] then
            log.warning("Cargo type resource not found; its trigger will remain inactive; resName = "
                .. cargoTypeFileName)
            missingCargoTypes[cargoTypeFileName] = true
        end
        return nil
    end

    return cargoTypeId
end

local function getIndustryCargoFlow(trigger)
    local cargoTypeId = getCargoTypeId(trigger.cargoTypeFileName)
    if not cargoTypeId then
        return nil
    end

    local industryFileName = trigger.industryFileName or trigger.sourceIndustryFileName
    local industryName = trigger.industryName or trigger.sourceIndustryName
    local cargoPerYear
    api.engine.forEachEntityWithComponent(function(entity)
        if cargoPerYear ~= nil then
            return
        end

        local industry = api.engine.getComponent(entity, api.type.ComponentType.INDUSTRY)
        local construction = industry
            and api.engine.getComponent(industry.construction, api.type.ComponentType.CONSTRUCTION)
        if not construction or construction.fileName ~= industryFileName then
            return
        end

        local name = api.engine.getComponent(industry.construction, api.type.ComponentType.NAME)
        if not name or name.name ~= industryName then
            name = api.engine.getComponent(entity, api.type.ComponentType.NAME)
        end
        if not name or name.name ~= industryName then
            return
        end

        if (trigger.direction or "shipped") == "delivered" then
            cargoPerYear = api.engine.util.stock.getCargoTypeDeliveredPerYear(industry.stockList, cargoTypeId)
        else
            cargoPerYear = api.engine.util.stock.getCargoTypeShippedPerYear(industry.stockList, cargoTypeId)
        end
    end, api.type.ComponentType.INDUSTRY)

    return cargoPerYear
end

local function isDue(spawn, currentDate, currentTimeOfDaySec)
    local trigger = spawn.trigger
    if trigger.type == "date" then
        if not isDateReached(currentDate, trigger.date) then
            return false
        end

        if currentDate.year == trigger.date.year
            and currentDate.month == trigger.date.month
            and currentDate.day == trigger.date.day
            and currentTimeOfDaySec < (trigger.timeOfDaySec or 0) then
            return false
        end

        return true
    elseif trigger.type == "shipment" then
        local cargoPerYear = getIndustryCargoFlow(trigger)
        local minimumPerYear = trigger.minimumShippedPerYear
        if trigger.direction == "delivered" then
            minimumPerYear = trigger.minimumDeliveredPerYear
        end
        return cargoPerYear ~= nil and cargoPerYear >= minimumPerYear
    end

    log.error("Unknown industry spawn trigger type; id = " .. spawn.id .. ", type = " .. tostring(trigger.type))
    return false
end

local function findTownByName(townName)
    local matchingTown
    api.engine.forEachEntityWithComponent(function(entity)
        if matchingTown then
            return
        end

        local name = api.engine.getComponent(entity, api.type.ComponentType.NAME)
        if name and name.name == townName then
            matchingTown = entity
        end
    end, api.type.ComponentType.TOWN)

    return matchingTown
end

local function hasSpawnTown(spawn)
    if not spawn.location then
        return true
    end

    local townName = spawn.location.townName
    if type(townName) ~= "string" or townName == "" then
        log.error("Industry spawn location requires a town name; id = " .. spawn.id)
        return false
    end

    if findTownByName(townName) then
        missingTowns[townName] = nil
        return true
    end

    if not missingTowns[townName] then
        log.error("Industry spawn town not found; spawn will wait; id = " .. spawn.id .. ", town = " .. townName)
        missingTowns[townName] = true
    end
    return false
end

local function getCompassDirection(position, referencePosition)
    local xDistance = position.x - referencePosition.x
    local yDistance = position.y - referencePosition.y
    if math.abs(xDistance) > math.abs(yDistance) then
        return xDistance >= 0 and "east" or "west"
    end
    return yDistance >= 0 and "north" or "south"
end

local function getWeightedDirection(weights)
    local directions = { "north", "east", "south", "west" }
    local totalWeight = 0
    for _, direction in ipairs(directions) do
        local weight = weights[direction] or 0
        if type(weight) ~= "number" or weight < 0 then
            return nil
        end
        totalWeight = totalWeight + weight
    end
    if totalWeight <= 0 then
        return nil
    end

    local selection = math.random() * totalWeight
    for _, direction in ipairs(directions) do
        selection = selection - (weights[direction] or 0)
        if selection < 0 then
            return direction
        end
    end
    return directions[#directions]
end

local function getTownPositions(spawn)
    local townName = spawn.location.townName
    local townEntity = findTownByName(townName)
    if not townEntity then
        log.error("Industry spawn town not found; id = " .. spawn.id .. ", town = " .. tostring(townName))
        return {}
    end

    local weights = spawn.location.directionWeights or { north = 1, east = 1, south = 1, west = 1 }
    if not getWeightedDirection(weights) then
        log.error("Industry spawn has invalid directionWeights; id = " .. spawn.id)
        return {}
    end

    local xTotal, yTotal, buildingCount = 0, 0, 0
    local townBuildings = api.engine.system.townBuildingSystem.getTown2BuildingMap()[townEntity] or {}
    for _, townBuildingEntity in ipairs(townBuildings) do
        local townBuilding = api.engine.getComponent(townBuildingEntity, api.type.ComponentType.TOWN_BUILDING)
        local construction = townBuilding
            and api.engine.getComponent(townBuilding.construction, api.type.ComponentType.CONSTRUCTION)
        if construction then
            xTotal = xTotal + construction.transf[13]
            yTotal = yTotal + construction.transf[14]
            buildingCount = buildingCount + 1
        end
    end

    local referencePosition
    if buildingCount > 0 then
        referencePosition = { x = xTotal / buildingCount, y = yTotal / buildingCount }
    else
        local position = api.engine.util.town.getRandomTownPosition(townEntity, math.random(0, 10000))
        referencePosition = { x = position.x, y = position.y }
    end

    local roadNodes = {}
    local node2StreetEdgeMap = api.engine.system.streetSystem.getNode2StreetEdgeMap()
    for entity, streetEdges in pairs(node2StreetEdgeMap) do
        if #streetEdges > 0 then
            local node = api.engine.getComponent(entity, api.type.ComponentType.BASE_NODE)
            if node then
                local xDistance = node.position.x - referencePosition.x
                local yDistance = node.position.y - referencePosition.y
                if xDistance * xDistance + yDistance * yDistance <= 2500 * 2500 then
                    roadNodes[#roadNodes + 1] = node.position
                end
            end
        end
    end

    if #roadNodes == 0 then
        log.warning("No nearby road nodes found for industry spawn; id = " .. spawn.id)
        return {}
    end

    local positionsByDirection = { north = {}, east = {}, south = {}, west = {} }
    for _ = 1, 512 do
        local position = api.engine.util.town.getRandomTownPosition(townEntity, math.random(0, 10000))
        local candidate = { x = position.x, y = position.y }
        if api.engine.terrain.isValidCoordinate(api.type.Vec2f.new(candidate.x, candidate.y)) then
            local xFromTown = candidate.x - referencePosition.x
            local yFromTown = candidate.y - referencePosition.y
            local distanceFromTown = math.sqrt(xFromTown * xFromTown + yFromTown * yFromTown)
            if distanceFromTown <= 2500 then
                local nearestRoadDistance = math.huge
                local nearestRoadHeight
                for _, roadNode in ipairs(roadNodes) do
                    local xDistance = candidate.x - roadNode.x
                    local yDistance = candidate.y - roadNode.y
                    local roadDistance = math.sqrt(xDistance * xDistance + yDistance * yDistance)
                    if roadDistance < nearestRoadDistance then
                        nearestRoadDistance = roadDistance
                        nearestRoadHeight = roadNode.z
                    end
                end

                local position2d = api.type.Vec2f.new(candidate.x, candidate.y)
                local height = api.engine.terrain.getHeightAt(position2d)
                local slopeRange = 0
                local validTerrainSamples = true
                for _, offset in ipairs({
                    { x = -50, y = 0 },
                    { x = 50, y = 0 },
                    { x = 0, y = -50 },
                    { x = 0, y = 50 },
                }) do
                    local sample = api.type.Vec2f.new(candidate.x + offset.x, candidate.y + offset.y)
                    if not api.engine.terrain.isValidCoordinate(sample) then
                        validTerrainSamples = false
                        break
                    end
                    local sampleHeight = api.engine.terrain.getHeightAt(sample)
                    slopeRange = math.max(slopeRange, math.abs(sampleHeight - height))
                end

                if validTerrainSamples
                    and nearestRoadDistance >= 30
                    and nearestRoadDistance <= 350
                    and math.abs(height - nearestRoadHeight) <= 15
                    and slopeRange <= 12 then
                    local direction = getCompassDirection(candidate, referencePosition)
                    local candidates = positionsByDirection[direction]
                    candidates[#candidates + 1] = candidate
                end
            end
        end
    end

    for _, direction in ipairs({ "north", "east", "south", "west" }) do
        local candidates = positionsByDirection[direction]
        while #candidates > 32 do
            table.remove(candidates, math.random(#candidates))
        end
    end

    local remainingWeights = {
        north = weights.north or 0,
        east = weights.east or 0,
        south = weights.south or 0,
        west = weights.west or 0,
    }
    local positions = {}
    while true do
        local direction = getWeightedDirection(remainingWeights)
        if direction and #positionsByDirection[direction] > 0 then
            local candidates = positionsByDirection[direction]
            local candidateIndex = math.random(#candidates)
            positions[#positions + 1] = table.remove(candidates, candidateIndex)
        elseif direction then
            remainingWeights[direction] = 0
        else
            local availableDirections = {}
            for _, fallbackDirection in ipairs({ "north", "east", "south", "west" }) do
                if #positionsByDirection[fallbackDirection] > 0 then
                    availableDirections[#availableDirections + 1] = fallbackDirection
                end
            end
            if #availableDirections == 0 then
                break
            end

            local fallbackDirection = availableDirections[math.random(#availableDirections)]
            local candidates = positionsByDirection[fallbackDirection]
            local candidateIndex = math.random(#candidates)
            positions[#positions + 1] = table.remove(candidates, candidateIndex)
        end
    end

    return positions
end

local function getSpawnPositions(spawn)
    if spawn.location then
        return getTownPositions(spawn)
    end

    return { spawn.position }
end

local function getSpawnRotation(spawn)
    if spawn.rotation == "random" then
        return math.random() * math.pi * 2
    end
    return spawn.rotation or 0
end

local function connectIndustryToNearestTown(constructionEntity, spawn)
    local townEntity = api.engine.system.streetConnectorSystem.getConstructionClosestTown(constructionEntity)
    if (not townEntity or townEntity < 0) and spawn.location and spawn.location.townName then
        townEntity = findTownByName(spawn.location.townName)
    end
    if not townEntity or townEntity < 0 then
        local construction = api.engine.getComponent(constructionEntity, api.type.ComponentType.CONSTRUCTION)
        if construction then
            local position = api.type.Mat4f.getTransl and api.type.Mat4f.getTransl(construction.transf)
                or api.type.Vec3f.new(construction.transf[13], construction.transf[14], construction.transf[15])
            townEntity = api.engine.util.town.getClosestTown(position)
        end
    end
    if not townEntity or townEntity < 0 then
        log.error("Unable to resolve a town for spawned industry road connection; id = " .. spawn.id)
        return
    end

    log.message("Generating town road connections for spawned industry: " .. spawn.id)
    local command = api.cmd.makeTownConnectWithIndustriesCmd({ townEntity }, {}, true)
    api.cmd.sendCommand(command, function(_, success)
        if success then
            log.message("Town road connection generation succeeded for spawned industry: " .. spawn.id)
        else
            log.error("Failed to generate town road connections for spawned industry; id = " .. spawn.id)
        end
    end)
end

local function getConstructionEntityForRoadProblem(entity)
    if api.engine.getComponent(entity, api.type.ComponentType.CONSTRUCTION) then
        return entity
    end

    local constructionEntity = api.engine.system.streetConnectorSystem.getConstructionEntityForNode(entity)
    if constructionEntity and constructionEntity >= 0
        and api.engine.getComponent(constructionEntity, api.type.ComponentType.CONSTRUCTION) then
        return constructionEntity
    end

    return nil
end

local function getNoRoadConnectionConstructionSet()
    local getNoRoadConnectionProblems = api.engine.util.getNoRoadConnectionProblems
    if type(getNoRoadConnectionProblems) ~= "function" then
        if not roadConnectionCheckUnavailableLogged then
            log.warning("This TF3 runtime does not expose getNoRoadConnectionProblems; manual road status checks are unavailable")
            roadConnectionCheckUnavailableLogged = true
        end
        return nil
    end

    local noRoadConnectionProblems = {}
    for _, problemEntity in ipairs(getNoRoadConnectionProblems()) do
        local constructionEntity = getConstructionEntityForRoadProblem(problemEntity)
        if constructionEntity then
            noRoadConnectionProblems[constructionEntity] = true
        else
            log.warning("Unable to resolve construction from no-road-connection result; entity = "
                .. tostring(problemEntity))
        end
    end

    return noRoadConnectionProblems
end

local function checkSpawnedIndustryRoadConnections(spawnerState)
    local industrySpawns = getIndustrySpawns(spawnerState)
    local noRoadConnectionProblems = getNoRoadConnectionConstructionSet()
    if not noRoadConnectionProblems then
        log.warning("Cannot check spawned-industry road status with this TF3 runtime")
        return
    end

    local connectedCount = 0
    local disconnectedCount = 0
    local townsToReconnect = {}
    local checkedConstructions = {}
    api.engine.forEachEntityWithComponent(function(entity)
        local industry = api.engine.getComponent(entity, api.type.ComponentType.INDUSTRY)
        if not industry or checkedConstructions[industry.construction] then
            return
        end

        local construction = api.engine.getComponent(industry.construction, api.type.ComponentType.CONSTRUCTION)
        if not construction then
            return
        end

        local name = api.engine.getComponent(industry.construction, api.type.ComponentType.NAME)
        if not name or not name.name then
            name = api.engine.getComponent(entity, api.type.ComponentType.NAME)
        end
        if not name then
            return
        end

        local matchingSpawn
        for _, spawn in ipairs(industrySpawns) do
            if construction.fileName == spawn.fileName and name.name == spawn.name then
                matchingSpawn = spawn
                break
            end
        end
        if not matchingSpawn then
            return
        end

        checkedConstructions[industry.construction] = true
        if noRoadConnectionProblems[industry.construction] then
            disconnectedCount = disconnectedCount + 1
            local townEntity = matchingSpawn.location and findTownByName(matchingSpawn.location.townName)
            if not townEntity or townEntity < 0 then
                townEntity = api.engine.system.streetConnectorSystem.getConstructionClosestTown(industry.construction)
            end
            if townEntity and townEntity >= 0 then
                townsToReconnect[townEntity] = true
            else
                log.error("Disconnected spawned industry has no town to connect; id = " .. matchingSpawn.id)
            end
        else
            connectedCount = connectedCount + 1
        end
    end, api.type.ComponentType.INDUSTRY)

    log.message("Developer road check: " .. connectedCount .. " spawned industry/industries connected; "
        .. disconnectedCount .. " disconnected")

    for townEntity in pairs(townsToReconnect) do
        local command = api.cmd.makeTownConnectWithIndustriesCmd({ townEntity }, {}, true)
        api.cmd.sendCommand(command, function(_, success)
            if success then
                log.message("Requested road connection generation for disconnected spawned industries; town = "
                    .. tostring(townEntity))
            else
                log.error("Failed to request road connection generation; town = " .. tostring(townEntity))
            end
        end)
    end
end

local function spawnIndustry(spawn, onComplete)
    local constructionId = api.res.constructionRep.find(spawn.fileName)
    if constructionId == -1 then
        log.error("Industry construction resource not found; resName = " .. spawn.fileName)
        onComplete(false)
        return
    end

    local positions = getSpawnPositions(spawn)
    if #positions == 0 then
        log.error("No valid spawn positions found; id = " .. spawn.id)
        onComplete(false)
        return
    end

    local function tryPosition(index)
        local position = positions[index]
        if not position then
            onComplete(false)
            return
        end

        local position2d = api.type.Vec2f.new(position.x, position.y)
        if not api.engine.terrain.isValidCoordinate(position2d) then
            tryPosition(index + 1)
            return
        end
        local height = api.engine.terrain.getHeightAt(position2d)
        local transformation = api.type.Mat4f.rotZTransl(
            getSpawnRotation(spawn),
            api.type.Vec3f.new(position.x, position.y, height)
        )

        local construction = api.type.SimpleProposal.ConstructionEntity.new()
        construction.fileName = spawn.fileName
        local constructionParams = {}
        for key, value in pairs(spawn.params or {}) do
            constructionParams[key] = value
        end
        if constructionParams.seed == nil then
            constructionParams.seed = getConstructionSeed(spawn.id)
        end
        construction.params = constructionParams
        construction.transf = transformation
        construction.name = spawn.name
        construction.playerEntity = -1

        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToAdd = { construction }

        local command = api.cmd.makeWorldBuildProposalCmd(proposal, nil, false, false)
        api.cmd.sendCommand(command, function(_, success, resultEntities)
            if success then
                log.message("Industry spawn succeeded: " .. spawn.id .. " (" .. spawn.name .. ")")
                local constructionEntity = resultEntities and resultEntities[1] and resultEntities[1][1]
                if constructionEntity then
                    onComplete(true, position, constructionEntity)
                else
                    log.error("Industry spawned but no construction entity was returned for road connection; id = "
                        .. spawn.id)
                    onComplete(true, position)
                end
                return
            end

            if spawn.location then
                tryPosition(index + 1)
                return
            end

            onComplete(false)
        end)
    end

    tryPosition(1)
end

local function completeSpawn(spawnerState, spawnId, succeeded, constructionEntity, updateCount)
    spawnerState.pendingSpawns = spawnerState.pendingSpawns or {}
    spawnerState.completedSpawns = spawnerState.completedSpawns or {}
    spawnerState.spawnedConstructions = spawnerState.spawnedConstructions or {}
    spawnerState.retryAfterUpdate = spawnerState.retryAfterUpdate or {}
    spawnerState.pendingRoadConnections = spawnerState.pendingRoadConnections or {}
    spawnerState.pendingSpawns[spawnId] = nil

    if succeeded then
        spawnerState.completedSpawns[spawnId] = true
        spawnerState.retryAfterUpdate[spawnId] = nil
        if constructionEntity then
            spawnerState.spawnedConstructions[spawnId] = constructionEntity
            spawnerState.pendingRoadConnections[#spawnerState.pendingRoadConnections + 1] = {
                constructionEntity = constructionEntity,
                spawnId = spawnId,
            }
        end
    else
        spawnerState.retryAfterUpdate[spawnId] = updateCount + 60
        log.error("Industry spawn failed; it will retry on a later update; id = " .. spawnId)
    end
end

local function queueSpawnCompletion(spawnId, succeeded, constructionEntity)
    queuedSpawnCompletions[#queuedSpawnCompletions + 1] = {
        spawnId = spawnId,
        succeeded = succeeded,
        constructionEntity = constructionEntity,
    }
end

local industrySpawner = {}

local function collectSpawnedConstructionEntities(spawnerState)
    local industrySpawns = getIndustrySpawns(spawnerState)
    local constructionEntities = {}
    local seenEntities = {}
    local spawnedConstructions = spawnerState.spawnedConstructions or {}
    local function addConstruction(entity)
        if entity and entity >= 0
            and not seenEntities[entity]
            and api.engine.getComponent(entity, api.type.ComponentType.CONSTRUCTION) then
            seenEntities[entity] = true
            constructionEntities[#constructionEntities + 1] = entity
        end
    end

    for _, entity in pairs(spawnedConstructions) do
        addConstruction(entity)
    end

    api.engine.forEachEntityWithComponent(function(entity)
        local industry = api.engine.getComponent(entity, api.type.ComponentType.INDUSTRY)
        if not industry then
            return
        end

        local construction = api.engine.getComponent(industry.construction, api.type.ComponentType.CONSTRUCTION)
        if not construction then
            return
        end

        for _, spawn in ipairs(industrySpawns) do
            if construction.fileName == spawn.fileName then
                local name = api.engine.getComponent(industry.construction, api.type.ComponentType.NAME)
                if not name or name.name ~= spawn.name then
                    name = api.engine.getComponent(entity, api.type.ComponentType.NAME)
                end
                if name and name.name == spawn.name then
                    addConstruction(industry.construction)
                    log.message("Map test reset matched configured industry: "
                        .. spawn.id .. " (construction " .. tostring(industry.construction) .. ")")
                    break
                end
            end
        end
    end, api.type.ComponentType.INDUSTRY)

    return constructionEntities
end

local function resetMapTestChanges(state)
    local spawnerState = state:get() or {}
    spawnerState.pendingSpawns = spawnerState.pendingSpawns or {}
    spawnerState.completedSpawns = spawnerState.completedSpawns or {}
    spawnerState.spawnedConstructions = spawnerState.spawnedConstructions or {}
    state:set(spawnerState)
    if spawnerState.resetInProgress then
        log.warning("Map test reset ignored because another reset is already running")
        return
    end
    for _, isPending in pairs(spawnerState.pendingSpawns or {}) do
        if isPending then
            log.warning("Map test reset ignored while an industry spawn is in progress; try again shortly")
            return
        end
    end

    if not spawnerState.startDate then
        log.error("Cannot reset map date because the starting date was not captured")
        return
    end
    spawnerState.resetInProgress = true
    spawnerState.pendingRoadConnections = {}
    state:set(spawnerState)

    local constructionEntities = collectSpawnedConstructionEntities(spawnerState)
    local function clearSpawnTracking(currentState)
        currentState.pendingSpawns = {}
        currentState.completedSpawns = {}
        currentState.spawnedConstructions = {}
        currentState.retryAfterUpdate = {}
        currentState.pendingRoadConnections = {}
        currentState.roadConnectionRepairScanDone = nil
    end
    local function resetDate()
        local startDate = spawnerState.startDate
        local date = api.type.Date.new(startDate.year, startDate.month, startDate.day)
        api.cmd.sendCommand(api.cmd.makeGameSetDateCmd(date), function(_, success)
            local currentState = state:get() or {}
            currentState.resetInProgress = nil
            if success then
                log.message(string.format(
                    "Map test reset complete; restored start date to %04d-%02d-%02d",
                    startDate.year,
                    startDate.month,
                    startDate.day
                ))
            else
                log.error("Map test reset could not restore the starting date")
            end
            state:set(currentState)
        end)
    end

    if #constructionEntities == 0 then
        clearSpawnTracking(spawnerState)
        state:set(spawnerState)
        log.warning("Map test reset found no industries matching configured construction paths and names")
        resetDate()
        return
    end

    local segmentsToRemove = {}
    local seenSegments = {}
    for _, constructionEntity in ipairs(constructionEntities) do
        local segments = api.engine.util.construction.findSegmentsToDelete(constructionEntity, false)
        for _, segmentEntity in ipairs(segments or {}) do
            if not seenSegments[segmentEntity] then
                seenSegments[segmentEntity] = true
                segmentsToRemove[#segmentsToRemove + 1] = segmentEntity
            end
        end
    end

    local function removeConstructions(roadsRemoved)
        log.message("Map test reset attempting to remove " .. #constructionEntities .. " industry construction(s)")
        local proposal = api.type.SimpleProposal.new()
        proposal.constructionsToRemove = constructionEntities
        local command = api.cmd.makeWorldBuildProposalCmd(proposal, nil, false, false)
        api.cmd.sendCommand(command, function(_, success)
            if not success then
                local currentState = state:get() or {}
                currentState.resetInProgress = nil
                state:set(currentState)
                log.error("Failed to remove spawned industries; map test reset was not completed")
                return
            end

            local currentState = state:get() or {}
            clearSpawnTracking(currentState)
            state:set(currentState)
            log.message("Removed " .. #constructionEntities .. " mod-spawned industry construction(s)")
            if not roadsRemoved then
                log.warning("Some industry road segments could not be removed during map test reset")
            end
            resetDate()
        end)
    end

    if #segmentsToRemove == 0 then
        removeConstructions(true)
        return
    end

    log.message("Map test reset attempting to remove " .. #segmentsToRemove .. " industry road segment(s)")
    local roadProposal = api.engine.util.proposal.makeSegmentsRemoveProposal(segmentsToRemove)
    local roadCommand = api.cmd.makeWorldBuildProposalCmd(roadProposal, nil, false, false)
    api.cmd.sendCommand(roadCommand, function(_, roadsRemoved)
        if roadsRemoved then
            log.message("Removed " .. #segmentsToRemove .. " industry road segment(s)")
        else
            log.warning("Failed to remove industry road segments; continuing with industry removal")
        end
        removeConstructions(roadsRemoved)
    end)
end

local function queueExistingSpawnRoadConnections(spawnerState)
    local industrySpawns = getIndustrySpawns(spawnerState)
    if spawnerState.roadConnectionRepairScanDone then
        return
    end
    local noRoadConnectionProblems = getNoRoadConnectionConstructionSet()
    if not noRoadConnectionProblems then
        return
    end
    spawnerState.roadConnectionRepairScanDone = true

    for _, spawn in ipairs(industrySpawns) do
        if spawnerState.completedSpawns[spawn.id] then
            local queuedConstructions = {}
            api.engine.forEachEntityWithComponent(function(entity)
                local industry = api.engine.getComponent(entity, api.type.ComponentType.INDUSTRY)
                local construction = industry
                    and api.engine.getComponent(industry.construction, api.type.ComponentType.CONSTRUCTION)
                if not construction or construction.fileName ~= spawn.fileName then
                    return
                end

                local name = api.engine.getComponent(industry.construction, api.type.ComponentType.NAME)
                if not name or name.name ~= spawn.name then
                    name = api.engine.getComponent(entity, api.type.ComponentType.NAME)
                end
                if not name or name.name ~= spawn.name then
                    return
                end

                if queuedConstructions[industry.construction] then
                    return
                end
                queuedConstructions[industry.construction] = true
                if noRoadConnectionProblems[industry.construction] then
                    spawnerState.pendingRoadConnections[#spawnerState.pendingRoadConnections + 1] = {
                        constructionEntity = industry.construction,
                        spawnId = spawn.id,
                    }
                    log.message("Queuing road connection repair for disconnected industry: " .. spawn.id)
                else
                    log.message("Existing spawned industry is already road-connected: " .. spawn.id)
                end
            end, api.type.ComponentType.INDUSTRY)
        end
    end

end

industrySpawner.update = function(_userParams, state, _dt)
    state:subscribeToEvent("developerTriggerSpawn")
    state:subscribeToEvent("developerImportEvents")
    state:subscribeToEvent("developerGrowTown")
    state:subscribeToEvent("developerCheckIndustryRoadConnections")
    state:subscribeToEvent("developerResetMap")

    local spawnerState = state:get() or {}
    local industrySpawns = getIndustrySpawns(spawnerState)
    spawnerState.updateCount = (spawnerState.updateCount or 0) + 1
    spawnerState.pendingSpawns = spawnerState.pendingSpawns or {}
    spawnerState.completedSpawns = spawnerState.completedSpawns or {}
    spawnerState.retryAfterUpdate = spawnerState.retryAfterUpdate or {}
    spawnerState.pendingRoadConnections = spawnerState.pendingRoadConnections or {}
    queueExistingSpawnRoadConnections(spawnerState)
    if not spawnerState.initialized then
        log.message("Map Scenario Toolkit spawner is running (" .. #industrySpawns .. " configured spawns)")
        spawnerState.initialized = true
    end

    local world = api.engine.util.getWorld()
    local gameTime = api.engine.getComponent(world, api.type.ComponentType.GAME_TIME)
    local currentDate = api.engine.util.getCalendarDate(gameTime.gameTime)
    for _, completion in ipairs(queuedSpawnCompletions) do
        completeSpawn(
            spawnerState,
            completion.spawnId,
            completion.succeeded,
            completion.constructionEntity,
            spawnerState.updateCount
        )
    end
    queuedSpawnCompletions = {}
    subsidyEventRuntime.update(getSubsidyEvents(spawnerState), spawnerState, currentDate, gameTime.timeOfDaySec)
    townConsumptionRuntime.update(getTownConsumptionEvents(spawnerState), spawnerState)

    if not spawnerState.startDate then
        spawnerState.startDate = {
            year = currentDate.year,
            month = currentDate.month,
            day = currentDate.day,
        }
        log.message(string.format(
            "Captured map starting date: %04d-%02d-%02d",
            currentDate.year,
            currentDate.month,
            currentDate.day
        ))
    end
    if spawnerState.resetInProgress then
        state:set(spawnerState)
        return false
    end
    local dueSpawns = {}
    local roadConnections = spawnerState.pendingRoadConnections
    spawnerState.pendingRoadConnections = {}

    local hasPendingSpawn = false
    for _, isPending in pairs(spawnerState.pendingSpawns) do
        if isPending then
            hasPendingSpawn = true
            break
        end
    end
    if not hasPendingSpawn then
        for _, spawn in ipairs(industrySpawns) do
            if not spawnerState.completedSpawns[spawn.id]
                and (not spawnerState.retryAfterUpdate[spawn.id]
                    or spawnerState.updateCount >= spawnerState.retryAfterUpdate[spawn.id])
                and isDue(spawn, currentDate, gameTime.timeOfDaySec)
                and hasSpawnTown(spawn) then
                log.message("Industry spawn trigger reached: " .. spawn.id)
                spawnerState.pendingSpawns[spawn.id] = true
                dueSpawns[#dueSpawns + 1] = spawn
                break
            end
        end
    end

    state:set(spawnerState)
    if #dueSpawns == 0 and #roadConnections == 0 then
        return false
    end

    return {
        dueSpawns = dueSpawns,
        roadConnections = roadConnections,
    }
end

industrySpawner.postUpdate = function(_userParams, state, _dt, updateResult)
    if not updateResult then
        return
    end
    local industrySpawns = getIndustrySpawns(state:get() or {})

    local noRoadConnectionProblems
    if #(updateResult.roadConnections or {}) > 0 then
        noRoadConnectionProblems = getNoRoadConnectionConstructionSet()
    end

    for _, connection in ipairs(updateResult.roadConnections or {}) do
        local spawn
        for _, configuredSpawn in ipairs(industrySpawns) do
            if configuredSpawn.id == connection.spawnId then
                spawn = configuredSpawn
                break
            end
        end
        if spawn and not noRoadConnectionProblems then
            log.warning("Automatic road repair skipped because this runtime cannot check road status; industry may need a manual road connection; id = " .. spawn.id)
        elseif spawn and noRoadConnectionProblems[connection.constructionEntity] then
            connectIndustryToNearestTown(connection.constructionEntity, spawn)
        elseif spawn then
            log.message("Spawned industry is already road-connected; skipping repair: " .. spawn.id)
        else
            log.error("Cannot connect spawned industry because its spawn definition is missing; id = "
                .. tostring(connection.spawnId))
        end
    end

    for _, spawn in ipairs(updateResult.dueSpawns or {}) do
        spawnIndustry(spawn, function(succeeded, _position, constructionEntity)
            queueSpawnCompletion(spawn.id, succeeded, constructionEntity)
        end)
    end

end

industrySpawner.handleEvent = function(_userParams, state, _src, id, name, param)
    if id ~= "map_scenario_toolkit" then
        return
    end

    if name == "developerGrowTown" then
        local townEntity = param and param.townEntity
        local passes = param and math.floor(tonumber(param.passes) or 0)
        if not townEntity or not passes or passes < 1 then
            log.warning("Developer town growth ignored because its town or pass count is invalid")
            return
        end
        passes = math.min(100, passes)
        local town = api.engine.getComponent(townEntity, api.type.ComponentType.TOWN)
        if not town then
            log.warning("Developer town growth ignored because the town no longer exists; entity = " .. tostring(townEntity))
            return
        end

        local submitted = 0
        for _ = 1, passes do
            local position = api.engine.util.town.getRandomTownPosition(townEntity, math.random(0, 10000))
            if position then
                local command = api.cmd.makeTownDevelopAtCmd(
                    api.type.Vec2f.new(position.x, position.y),
                    true,
                    true
                )
                api.cmd.sendCommand(command)
                submitted = submitted + 1
            end
        end
        log.message("Developer requested " .. submitted .. " town development pass(es) for entity " .. tostring(townEntity))
        return
    end
    if name == "developerImportEvents" then
        local dataset = param and param.dataset
        if validateDataset(dataset, "imported JSON") then
            local spawnerState = state:get() or {}
            spawnerState.customIndustrySpawns = dataset.industryEvents
            spawnerState.customSubsidyEvents = dataset.subsidyEvents
            spawnerState.customTownConsumptionEvents = dataset.townConsumptionEvents or {}
            state:set(spawnerState)
            log.message("Loaded " .. #dataset.industryEvents .. " custom industry spawn events, "
                .. #dataset.subsidyEvents .. " custom subsidy events, and "
                .. #(dataset.townConsumptionEvents or {}) .. " town consumption rules")
        end
        return
    end
    if name == "developerCheckIndustryRoadConnections" then
        log.message("Developer requested spawned-industry road connection check")
        checkSpawnedIndustryRoadConnections(state:get() or {})
        return
    end

    if name == "developerResetMap" then
        log.message("Developer requested map test reset")
        resetMapTestChanges(state)
        return
    end

    if name ~= "developerTriggerSpawn" then
        return
    end

    local spawnId = param and param.spawnId
    for _, spawn in ipairs(getIndustrySpawns(state:get() or {})) do
        if spawn.id == spawnId then
            local spawnerState = state:get() or {}
            spawnerState.pendingSpawns = spawnerState.pendingSpawns or {}
            spawnerState.completedSpawns = spawnerState.completedSpawns or {}
            if spawnerState.pendingSpawns[spawn.id] or spawnerState.completedSpawns[spawn.id] then
                log.warning("Developer spawn ignored because it is already pending or complete: " .. spawn.id)
                return
            end

            spawnerState.pendingSpawns[spawn.id] = true
            state:set(spawnerState)
            log.message("Developer requested industry spawn: " .. spawn.id)
            spawnIndustry(spawn, function(succeeded, _position, constructionEntity)
                queueSpawnCompletion(spawn.id, succeeded, constructionEntity)
            end)
            return
        end
    end

    log.error("Developer requested unknown industry spawn; id = " .. tostring(spawnId))
end

function data()
    return industrySpawner
end










