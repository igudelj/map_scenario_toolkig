-- Reference metadata only. These display names and production relationships
-- are not verified construction resource IDs or spawn API definitions.
-- Source: https://wiki.transportfever3.com/doku.php?id=gamemanual:simulation:industriescargos

local industries = {
    brewery = {
        name = "Brewery", climates = { "temperate", "dry", "subarctic" },
        inputs = { "Grain", "Glass" }, outputs = { "Beverages" },
    },
    brick_works = {
        name = "Brick Works", climates = { "temperate", "dry" },
        inputs = { "Clay" }, outputs = { "Bricks" },
    },
    cement_plant = {
        name = "Cement Plant", climates = { "tropical", "subarctic" },
        inputs = { "Stone" }, outputs = { "Cement" },
    },
    chemical_plant = {
        name = "Chemical Plant", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Chemicals" }, outputs = { "Dyes", "Plastic" },
    },
    clay_pit = {
        name = "Clay Pit", climates = { "temperate", "dry" },
        inputs = {}, outputs = { "Clay" }, booster = "Tools",
    },
    coal_mine = {
        name = "Coal Mine", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {}, outputs = { "Coal" }, booster = "Tools",
    },
    cotton_farm = {
        name = "Cotton Farm", climates = { "temperate", "tropical" },
        inputs = {}, outputs = { "Wool" }, booster = "Fertilizer",
    },
    crop_farm = {
        name = "Crop Farm", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {}, outputs = { "Grain", "Vegetables" }, booster = "Fertilizer",
    },
    fishing_grounds = {
        name = "Fishing Grounds", climates = { "temperate", "tropical", "subarctic" },
        inputs = {}, outputs = { "Fish" }, booster = "Tools",
    },
    canning_factory = {
        name = "Canning Factory", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Fish or Meat", "Sheet Metal" }, outputs = { "Canned Food" },
    },
    furniture_factory = {
        name = "Furniture Factory", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Planks", "Glass" }, outputs = { "Furniture" }, booster = "Machines",
    },
    glass_works = {
        name = "Glass Works", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Sand" }, outputs = { "Glass" },
    },
    iron_ore_mine = {
        name = "Iron Ore Mine", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {}, outputs = { "Iron Ore" },
    },
    livestock_farm = {
        name = "Livestock Farm", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Grain" }, outputs = { "Meat", "Wool" }, booster = "Machines",
    },
    logging_camp = {
        name = "Logging Camp", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {}, outputs = { "Logs" },
    },
    machine_factory = {
        name = "Machine Factory", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Steel", "Plastic" }, outputs = { "Machines" },
    },
    oil_platform = {
        name = "Oil Platform", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {}, outputs = { "Crude Oil" }, booster = "Tools",
    },
    oil_refinery = {
        name = "Oil Refinery", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Crude Oil" }, outputs = { "Fuel", "Fertilizer", "Chemicals" },
    },
    oil_well = {
        name = "Oil Well", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {}, outputs = { "Crude Oil" }, booster = "Machines",
    },
    paper_mill = {
        name = "Paper Mill", climates = { "subarctic" },
        inputs = { "Sawdust" }, outputs = { "Paper" },
    },
    printing_press = {
        name = "Printing Press", climates = { "subarctic" },
        inputs = { "Paper", "Dyes" }, outputs = { "Books" },
    },
    quarry = {
        name = "Quarry", climates = { "temperate", "tropical", "subarctic" },
        inputs = {}, outputs = { "Stone" }, booster = "Tools",
    },
    rubber_farm = {
        name = "Rubber Farm", climates = { "tropical" },
        inputs = {}, outputs = { "Rubber" }, booster = "Fertilizer",
    },
    sand_excavator = {
        name = "Sand Excavator", climates = { "temperate", "tropical", "subarctic" },
        inputs = {}, outputs = { "Sand" }, booster = "Machines",
    },
    sand_pit = {
        name = "Sand Pit", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {}, outputs = { "Sand" }, booster = "Tools",
    },
    saw_mill = {
        name = "Saw Mill", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Logs" }, outputs = { "Sawdust", "Planks" },
    },
    steel_mill = {
        name = "Steel Mill", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Iron Ore", "Coal" }, outputs = { "Sheet Metal", "Steel" },
    },
    textile_factory = {
        name = "Textile Factory", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Fabric", "Dyes" }, outputs = { "Clothes" },
    },
    tire_factory = {
        name = "Tire Factory", climates = { "tropical" },
        inputs = { "Rubber" }, outputs = { "Tires" },
    },
    tool_factory = {
        name = "Tool Factory", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Planks", "Plastic" }, outputs = { "Tools" },
    },
    vehicle_factory = {
        name = "Vehicle Factory", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Tires", "Sheet Metal", "Machines" }, outputs = { "Vehicles" },
    },
    weaving_mill = {
        name = "Weaving Mill", climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Wool" }, outputs = { "Fabric" },
    },
}

local function getIndustry(key)
    return industries[key]
end

local function listIndustries()
    local keys = {}
    for key in pairs(industries) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

return {
    industries = industries,
    getIndustry = getIndustry,
    listIndustries = listIndustries,
}
