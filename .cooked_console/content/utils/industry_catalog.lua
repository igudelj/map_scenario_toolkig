-- Reference metadata only. These display names and production relationships
-- are not verified construction resource IDs or spawn API definitions.
-- Source: https://wiki.transportfever3.com/doku.php?id=gamemanual:simulation:industriescargos

local industries = {
    brewery = {
        name = "Brewery",
        filename = "::/industries/brewery/brewery.con",
        climates = { "temperate", "dry", "subarctic" },
        inputs = { "Grain", "Glass" },
        outputs = { "Beverages" },
        placement = "land",
    },
    brick_works = {
        name = "Brick Works",
        filename = "::/industries/bricks_works/bricks_works.con",
        climates = { "temperate", "dry" },
        inputs = { "Clay" },
        outputs = { "Bricks" },
        placement = "land",
    },
    cement_plant = {
        name = "Cement Plant",
        filename = "::/industries/cement_plant/cement_plant.con",
        climates = { "tropical", "subarctic" },
        inputs = { "Stone" },
        outputs = { "Cement" },
        placement = "land",
    },
    chemical_plant = {
        name = "Chemical Plant",
        filename = "::/industries/chemical_plant/chemical_plant.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Chemicals" },
        outputs = { "Dyes", "Plastic" },
        placement = "land",
    },
    clay_pit = {
        name = "Clay Pit",
        filename = "::/industries/clay_pit/clay_pit.con",
        climates = { "temperate", "dry" },
        inputs = {},
        outputs = { "Clay" },
        booster = "Tools",
        placement = "land",
    },
    coal_mine = {
        name = "Coal Mine",
        filename = "::/industries/coal_mine/coal_mine.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Coal" },
        booster = "Tools",
        placement = "land",
    },
    cotton_farm = {
        name = "Cotton Farm",
        filename = "::/industries/cotton_farm/cotton_farm.con",
        climates = { "temperate", "tropical" },
        inputs = {},
        outputs = { "Wool" },
        booster = "Fertilizer",
        placement = "land",
    },
    crop_farm = {
        name = "Crop Farm",
        filename = "::/industries/farm/farm.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Grain", "Vegetables" },
        booster = "Fertilizer",
        placement = "land",
    },
    fishing_grounds = {
        name = "Fishing Grounds",
        filename = "::/industries/fishing_grounds/fishing_grounds.con",
        climates = { "temperate", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Fish" },
        booster = "Tools",
        placement = "water",
    },
    canning_factory = {
        name = "Canning Factory",
        filename = "::/industries/food_factory/food_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Fish or Meat", "Sheet Metal" },
        outputs = { "Canned Food" },
        placement = "land",
    },
    furniture_factory = {
        name = "Furniture Factory",
        filename = "::/industries/furniture_factory/furniture_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Planks", "Glass" },
        outputs = { "Furniture" },
        booster = "Machines",
        placement = "land",
    },
    glass_works = {
        name = "Glass Works",
        filename = "::/industries/glass_works/glass_works.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Sand" },
        outputs = { "Glass" },
        placement = "land",
    },
    iron_ore_mine = {
        name = "Iron Ore Mine",
        filename = "::/industries/iron_ore_mine/iron_ore_mine.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Iron Ore" },
        placement = "land",
    },
    livestock_farm = {
        name = "Livestock Farm",
        filename = "::/industries/livestock_farm/livestock_farm.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Grain" },
        outputs = { "Meat", "Wool" },
        booster = "Machines",
        placement = "land",
    },
    logging_camp = {
        name = "Logging Camp",
        filename = "::/industries/forest/forest.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Logs" },
        placement = "land",
    },
    machine_factory = {
        name = "Machine Factory",
        filename = "::/industries/machine_factory/machine_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Steel", "Plastic" },
        outputs = { "Machines" },
        placement = "land",
    },
    oil_platform = {
        name = "Oil Platform",
        filename = "::/industries/oil_platform/oil_platform.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Crude Oil" },
        booster = "Tools",
        placement = "water",
    },
    oil_refinery = {
        name = "Oil Refinery",
        filename = "::/industries/oil_refinery/oil_refinery.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Crude Oil" },
        outputs = { "Fuel", "Fertilizer", "Chemicals" },
        placement = "land",
    },
    oil_well = {
        name = "Oil Well",
        filename = "::/industries/oil_well/oil_well.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Crude Oil" },
        booster = "Machines",
        placement = "land",
    },
    paper_mill = {
        name = "Paper Mill",
        filename = "::/industries/paper_mill/paper_mill.con",
        climates = { "subarctic" },
        inputs = { "Sawdust" },
        outputs = { "Paper" },
        placement = "land",
    },
    printing_press = {
        name = "Printing Press",
        filename = "::/industries/printing_press/printing_press.con",
        climates = { "subarctic" },
        inputs = { "Paper", "Dyes" },
        outputs = { "Books" },
        placement = "land",
    },
    quarry = {
        name = "Quarry",
        filename = "::/industries/quarry/quarry.con",
        climates = { "temperate", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Stone" },
        booster = "Tools",
        placement = "land",
    },
    rubber_farm = {
        name = "Rubber Farm",
        filename = "::/industries/rubber_farm/rubber_farm.con",
        climates = { "tropical" },
        inputs = {},
        outputs = { "Rubber" },
        booster = "Fertilizer",
        placement = "land",
    },
    sand_excavator = {
        name = "Sand Excavator",
        filename = "::/industries/sand_excavator/sand_excavator.con",
        climates = { "temperate", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Sand" },
        booster = "Machines",
        placement = "water",
    },
    sand_pit = {
        name = "Sand Pit",
        filename = "::/industries/sand_pit/sand_pit.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Sand" },
        booster = "Tools",
        placement = "land",
    },
    saw_mill = {
        name = "Saw Mill",
        filename = "::/industries/saw_mill/saw_mill.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Logs" },
        outputs = { "Sawdust", "Planks" },
        placement = "land",
    },
    steel_mill = {
        name = "Steel Mill",
        filename = "::/industries/steel_mill/steel_mill.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Iron Ore", "Coal" },
        outputs = { "Sheet Metal", "Steel" },
        placement = "land",
    },
    textile_factory = {
        name = "Textile Factory",
        filename = "::/industries/textile_factory/textile_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Fabric", "Dyes" },
        outputs = { "Clothes" },
        placement = "land",
    },
    tire_factory = {
        name = "Tire Factory",
        filename = "::/industries/tire_factory/tire_factory.con",
        climates = { "tropical" },
        inputs = { "Rubber" },
        outputs = { "Tires" },
        placement = "land",
    },
    tool_factory = {
        name = "Tool Factory",
        filename = "::/industries/tool_factory/tool_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Planks", "Plastic" },
        outputs = { "Tools" },
        placement = "land",
    },
    vehicle_factory = {
        name = "Vehicle Factory",
        filename = "::/industries/vehicle_factory/vehicle_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Tires", "Sheet Metal", "Machines" },
        outputs = { "Vehicles" },
        placement = "land",
    },
    weaving_mill = {
        name = "Weaving Mill",
        filename = "::/industries/weaving_mill/weaving_mill.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Wool" },
        outputs = { "Fabric" },
        placement = "land",
    },
}

local function getIndustry(key)
    return industries[key]
end

local function getIndustryByFilename(filename)
    for _, industry in pairs(industries) do
        if industry.filename == filename then
            return industry
        end
    end
    return nil
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
    getIndustryByFilename = getIndustryByFilename,
    listIndustries = listIndustries,
}
