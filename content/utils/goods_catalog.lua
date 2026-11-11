local goods = {
    beverages = {
        name = "Beverages",
        filename = "::/cargos/beverages/beverages.cargo",
    },
    books = {
        name = "Books",
        filename = "::/cargos/books/books.cargo",
    },
    bricks = {
        name = "Bricks",
        filename = "::/cargos/bricks/bricks.cargo",
    },
    canned_food = {
        name = "Canned Food",
        filename = "::/cargos/canned_food/canned_food.cargo",
    },
    cement = {
        name = "Cement",
        filename = "::/cargos/cement/cement.cargo",
    },
    chemicals = {
        name = "Chemicals",
        filename = "::/cargos/chemicals/chemicals.cargo",
    },
    clay = {
        name = "Clay",
        filename = "::/cargos/clay/clay.cargo",
    },
    clothes = {
        name = "Clothes",
        filename = "::/cargos/clothes/clothes.cargo",
    },
    coal = {
        name = "Coal",
        filename = "::/cargos/coal/coal.cargo",
    },
    crude_oil = {
        name = "Crude Oil",
        filename = "::/cargos/crude_oil/crude_oil.cargo",
    },
    dyes = {
        name = "Dyes",
        filename = "::/cargos/dyes/dyes.cargo",
    },
    fabric = {
        name = "Fabric",
        filename = "::/cargos/fabric/fabric.cargo",
    },
    fertilizer = {
        name = "Fertilizer",
        filename = "::/cargos/fertilizer/fertilizer.cargo",
    },
    fish = {
        name = "Fish",
        filename = "::/cargos/fish/fish.cargo",
    },
    fuel = {
        name = "Fuel",
        filename = "::/cargos/fuel/fuel.cargo",
    },
    furniture = {
        name = "Furniture",
        filename = "::/cargos/furniture/furniture.cargo",
    },
    glass = {
        name = "Glass",
        filename = "::/cargos/glass/glass.cargo",
    },
    grain = {
        name = "Grain",
        filename = "::/cargos/grain/grain.cargo",
    },
    iron_ore = {
        name = "Iron Ore",
        filename = "::/cargos/iron_ore/iron_ore.cargo",
    },
    logs = {
        name = "Logs",
        filename = "::/cargos/logs/logs.cargo",
    },
    machines = {
        name = "Machines",
        filename = "::/cargos/machines/machines.cargo",
    },
    meat = {
        name = "Meat",
        filename = "::/cargos/meat/meat.cargo",
    },
    paper = {
        name = "Paper",
        filename = "::/cargos/paper/paper.cargo",
    },
    planks = {
        name = "Planks",
        filename = "::/cargos/planks/planks.cargo",
    },
    plastic = {
        name = "Plastic",
        filename = "::/cargos/plastic/plastic.cargo",
    },
    rubber = {
        name = "Rubber",
        filename = "::/cargos/rubber/rubber.cargo",
    },
    sand = {
        name = "Sand",
        filename = "::/cargos/sand/sand.cargo",
    },
    sawdust = {
        name = "Sawdust",
        filename = "::/cargos/sawdust/sawdust.cargo",
    },
    sheet_metal = {
        name = "Sheet Metal",
        filename = "::/cargos/sheet_metal/sheet_metal.cargo",
    },
    steel = {
        name = "Steel",
        filename = "::/cargos/steel/steel.cargo",
    },
    stone = {
        name = "Stone",
        filename = "::/cargos/stone/stone.cargo",
    },
    tires = {
        name = "Tires",
        filename = "::/cargos/tires/tires.cargo",
    },
    tools = {
        name = "Tools",
        filename = "::/cargos/tools/tools.cargo",
    },
    vegetables = {
        name = "Vegetables",
        filename = "::/cargos/vegetables/vegetables.cargo",
    },
    vehicles = {
        name = "Vehicles",
        filename = "::/cargos/vehicles/vehicles.cargo",
    },
    wool = {
        name = "Wool",
        filename = "::/cargos/wool/wool.cargo",
    },
}

local function getGood(key)
    return goods[key]
end

local function listGoods()
    local keys = {}
    for key in pairs(goods) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

return {
    goods = goods,
    getGood = getGood,
    listGoods = listGoods,
}
