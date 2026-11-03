local decodeJson = ug_require('/utils/json_decode.lua')

return function(jsonText, validator)
    local ok, decoded = pcall(decodeJson, jsonText)
    if not ok then
        return nil, 'Invalid JSON: ' .. tostring(decoded)
    end
    if type(decoded) ~= 'table' then
        return nil, 'Dataset must be a JSON object.'
    end

    local dataset
    if decoded.industryEvents ~= nil or decoded.subsidyEvents ~= nil or decoded.townConsumptionEvents ~= nil then
        dataset = {
            industryEvents = decoded.industryEvents or {},
            subsidyEvents = decoded.subsidyEvents or {},
            townConsumptionEvents = decoded.townConsumptionEvents or {},
        }
    else
        local legacyEvents = decoded.events or decoded
        dataset = { industryEvents = legacyEvents, subsidyEvents = {}, townConsumptionEvents = {} }
    end

    if not validator(dataset, 'pasted JSON') then
        return nil, 'Dataset failed validation; see the game log.'
    end
    return dataset
end
