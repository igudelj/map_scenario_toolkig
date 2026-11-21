local ssu = require "::/gui/main/stylesheetutil.lua"

function data()
    local result = {}
    local add = ssu.makeAdder(result)

    add("R::MapScenarioToolkitImportEventsContent BoxLayout", {
        outerSpacing = { 12, 12 },
        innerSpacing = { 0, 1 },
    })

    return result
end