-- Starter map dataset. Copy this file into a companion mod and edit its events.
return {
    industryEvents = {
        {
            id = "example_date_farm_1940",
            fileName = "::/industries/farm/farm.con",
            name = "Map Event Farm",
            trigger = {
                type = "date",
                date = { year = 1940, month = 11, day = 1 },
            },
            location = {
                townName = "Osijek",
                directionWeights = { north = 4, east = 2, south = 1, west = 1 },
            },
            rotation = "random",
        },
        {
            id = "example_farm_shipment_livestock_farm",
            fileName = "::/industries/livestock_farm/livestock_farm.con",
            name = "Map Event Livestock Farm",
            trigger = {
                type = "shipment",
                sourceIndustryFileName = "::/industries/farm/farm.con",
                sourceIndustryName = "Map Event Farm",
                cargoTypeFileName = "::/cargos/grain/grain.cargo",
                minimumShippedPerYear = 10,
            },
            location = {
                townName = "Osijek",
                directionWeights = { north = 1, east = 4, south = 1, west = 2 },
            },
            rotation = "random",
        },
        {
            id = "example_livestock_delivery_tool_factory",
            fileName = "::/industries/tool_factory/tool_factory.con",
            name = "Map Event Tool Factory",
            trigger = {
                type = "shipment",
                direction = "delivered",
                industryFileName = "::/industries/livestock_farm/livestock_farm.con",
                industryName = "Map Event Livestock Farm",
                cargoTypeFileName = "::/cargos/grain/grain.cargo",
                minimumDeliveredPerYear = 10,
            },
            location = {
                townName = "Osijek",
                directionWeights = { north = 2, east = 3, south = 1, west = 1 },
            },
            rotation = "random",
        },
    },
    subsidyEvents = {},
    townConsumptionEvents = {},
}