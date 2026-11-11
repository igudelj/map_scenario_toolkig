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
    },
    brick_works = {
        name = "Brick Works",
        filename = "::/industries/brick_works/brick_works.con",
        climates = { "temperate", "dry" },
        inputs = { "Clay" },
        outputs = { "Bricks" },
    },
    cement_plant = {
        name = "Cement Plant",
        filename = "::/industries/cement_plant/cement_plant.con",
        climates = { "tropical", "subarctic" },
        inputs = { "Stone" },
        outputs = { "Cement" },
    },
    chemical_plant = {
        name = "Chemical Plant",
        filename = "::/industries/chemical_plant/chemical_plant.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Chemicals" },
        outputs = { "Dyes", "Plastic" },
    },
    clay_pit = {
        name = "Clay Pit",
        filename = "::/industries/clay_pit/clay_pit.con",
        climates = { "temperate", "dry" },
        inputs = {},
        outputs = { "Clay" },
        booster = "Tools",
    },
    coal_mine = {
        name = "Coal Mine",
        filename = "::/industries/coal_mine/coal_mine.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Coal" },
        booster = "Tools",
    },
    cotton_farm = {
        name = "Cotton Farm",
        filename = "::/industries/cotton_farm/cotton_farm.con",
        climates = { "temperate", "tropical" },
        inputs = {},
        outputs = { "Wool" },
        booster = "Fertilizer",
    },
    crop_farm = {
        name = "Crop Farm",
        filename = "::/industries/farm/farm.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Grain", "Vegetables" },
        booster = "Fertilizer",
    },
    fishing_grounds = {
        name = "Fishing Grounds",
        filename = "::/industries/fishing_grounds/fishing_grounds.con",
        climates = { "temperate", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Fish" },
        booster = "Tools",
    },
    canning_factory = {
        name = "Canning Factory",
        filename = "::/industries/food_factory/food_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Fish or Meat", "Sheet Metal" },
        outputs = { "Canned Food" },
    },
    furniture_factory = {
        name = "Furniture Factory",
        filename = "::/industries/furniture_factory/furniture_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Planks", "Glass" },
        outputs = { "Furniture" },
        booster = "Machines",
    },
    glass_works = {
        name = "Glass Works",
        filename = "::/industries/glass_works/glass_works.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Sand" },
        outputs = { "Glass" },
    },
    iron_ore_mine = {
        name = "Iron Ore Mine",
        filename = "::/industries/iron_ore_mine/iron_ore_mine.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Iron Ore" },
    },
    livestock_farm = {
        name = "Livestock Farm",
        filename = "::/industries/livestock_farm/livestock_farm.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Grain" },
        outputs = { "Meat", "Wool" },
        booster = "Machines",
    },
    logging_camp = {
        name = "Logging Camp",
        filename = "::/industries/forest/forest.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Logs" },
    },
    machine_factory = {
        name = "Machine Factory",
        filename = "::/industries/machine_factory/machine_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Steel", "Plastic" },
        outputs = { "Machines" },
    },
    oil_platform = {
        name = "Oil Platform",
        filename = "::/industries/oil_platform/oil_platform.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Crude Oil" },
        booster = "Tools",
    },
    oil_refinery = {
        name = "Oil Refinery",
        filename = "::/industries/oil_refinery/oil_refinery.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Crude Oil" },
        outputs = { "Fuel", "Fertilizer", "Chemicals" },
    },
    oil_well = {
        name = "Oil Well",
        filename = "::/industries/oil_well/oil_well.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Crude Oil" },
        booster = "Machines",
    },
    paper_mill = {
        name = "Paper Mill",
        filename = "::/industries/paper_mill/paper_mill.con",
        climates = { "subarctic" },
        inputs = { "Sawdust" },
        outputs = { "Paper" },
    },
    printing_press = {
        name = "Printing Press",
        filename = "::/industries/printing_press/printing_press.con",
        climates = { "subarctic" },
        inputs = { "Paper", "Dyes" },
        outputs = { "Books" },
    },
    quarry = {
        name = "Quarry",
        filename = "::/industries/quarry/quarry.con",
        climates = { "temperate", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Stone" },
        booster = "Tools",
    },
    rubber_farm = {
        name = "Rubber Farm",
        filename = "::/industries/rubber_farm/rubber_farm.con",
        climates = { "tropical" },
        inputs = {},
        outputs = { "Rubber" },
        booster = "Fertilizer",
    },
    sand_excavator = {
        name = "Sand Excavator",
        filename = "::/industries/sand_excavator/sand_excavator.con",
        climates = { "temperate", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Sand" },
        booster = "Machines",
    },
    sand_pit = {
        name = "Sand Pit",
        filename = "::/industries/sand_pit/sand_pit.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = {},
        outputs = { "Sand" },
        booster = "Tools",
    },
    saw_mill = {
        name = "Saw Mill",
        filename = "::/industries/saw_mill/saw_mill.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Logs" },
        outputs = { "Sawdust", "Planks" },
    },
    steel_mill = {
        name = "Steel Mill",
        filename = "::/industries/steel_mill/steel_mill.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Iron Ore", "Coal" },
        outputs = { "Sheet Metal", "Steel" },
    },
    textile_factory = {
        name = "Textile Factory",
        filename = "::/industries/textile_factory/textile_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Fabric", "Dyes" },
        outputs = { "Clothes" },
    },
    tire_factory = {
        name = "Tire Factory",
        filename = "::/industries/tire_factory/tire_factory.con",
        climates = { "tropical" },
        inputs = { "Rubber" },
        outputs = { "Tires" },
    },
    tool_factory = {
        name = "Tool Factory",
        filename = "::/industries/tool_factory/tool_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Planks", "Plastic" },
        outputs = { "Tools" },
    },
    vehicle_factory = {
        name = "Vehicle Factory",
        filename = "::/industries/vehicle_factory/vehicle_factory.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Tires", "Sheet Metal", "Machines" },
        outputs = { "Vehicles" },
    },
    weaving_mill = {
        name = "Weaving Mill",
        filename = "::/industries/weaving_mill/weaving_mill.con",
        climates = { "temperate", "dry", "tropical", "subarctic" },
        inputs = { "Wool" },
        outputs = { "Fabric" },
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
