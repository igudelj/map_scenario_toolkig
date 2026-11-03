local react = ug_require("::/gui/main/react.lua")
local builtin = ug_require("::/gui/main/builtin.lua")
local contentCard = ug_require("::/gui/main/content_card.tl")
local townEow = ug_require("::/gui/entity_window/town/town_eow.script.tl")
local actions = ug_require("/developer_tools/developer_tools_actions.lua")
local styleutil = ug_require("::/gui/main/styleutil.tl")

local TownGrowthControl = react.RegisterRecipe("MapScenarioToolkitTownGrowthControl", function(params)
    local passes = react.useState(1)
    local status = react.useState("Each pass asks the town developer to add or upgrade buildings near a random point.")
    local experiencePercent = react.useState(10)
    local experienceStatus = react.useState("Adds this percentage of the full experience required for the current level.")

    return builtin.BoxLayout {
        orientation = builtin.type.Orientation.Vertical,
        children = {
            builtin.TextView {
                text = "Development passes: " .. tostring(passes:old()),
                meta = { class = "font-scale-body" },
            },
            builtin.Slider {
                min = 1,
                max = 100,
                step = 1,
                pageStep = 10,
                horizontal = true,
                drawGroove = true,
                value = passes:old(),
                onValueChange = function(value) passes:set(value) end,
                meta = { styleSheet = styleutil.makeStyle({ size = { 480, 36 } }) },
            },
            builtin.Button {
                meta = { class = "primary" },
                content = builtin.TextView { text = "Grow town" },
                onClick = function()
                    local requestedPasses = math.max(1, math.min(100, math.floor(passes:old())))
                    actions.sendEvent("developerGrowTown", {
                        townEntity = params.townEntity,
                        passes = requestedPasses,
                    }, "town growth for " .. tostring(params.townEntity))
                    status:set("Queued " .. requestedPasses .. " development pass(es).")
                end,
            },
            builtin.TextView {
                text = status:old(),
                meta = { class = "font-scale-body" },
            },
            builtin.TextView {
                text = "Experience to add: " .. tostring(experiencePercent:old()) .. "%",
                meta = { class = "font-scale-body" },
            },
            builtin.Slider {
                min = 1,
                max = 100,
                step = 1,
                pageStep = 10,
                horizontal = true,
                drawGroove = true,
                value = experiencePercent:old(),
                onValueChange = function(value) experiencePercent:set(value) end,
                meta = { styleSheet = styleutil.makeStyle({ size = { 480, 36 } }) },
            },
            builtin.Button {
                meta = { class = "primary" },
                content = builtin.TextView { text = "Add town experience" },
                onClick = function()
                    local requestedPercent = math.max(1, math.min(100, math.floor(experiencePercent:old())))
                    actions.grantTownExperience(params.townEntity, requestedPercent / 100)
                    experienceStatus:set("Requested " .. requestedPercent .. "% of this level's experience.")
                end,
            },
            builtin.TextView {
                text = experienceStatus:old(),
                meta = { class = "font-scale-body" },
            },
        },
    }
end)

local TownGrowthPlugin = react.RegisterPluginRecipe(
    townEow.TownEowExtensionPoint,
    "MapScenarioToolkitTownGrowthPlugin",
    function(params)
        return builtin.BoxLayout {
            child = contentCard.ContentCard {
                title = "Developer Town Growth",
                recipeAndParamPermanent = contentCard.makeRecipeAndParam(
                    TownGrowthControl,
                    { townEntity = params.entityId }
                ),
                gameCtx = params.gameCtx,
                showOnRightSide = params.showCalloutOnRightSide,
            },
        }
    end
)

local mod = {
    MapScenarioToolkitTownGrowthPlugin = TownGrowthPlugin,
}

function data()
    return mod
end