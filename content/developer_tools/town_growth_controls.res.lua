function data()
    return {
        type = "react-plugin ::TownEowExtensionPoint",
        data = {
            filePath = "map_scenario_toolkit::/developer_tools/town_growth_controls.script@MapScenarioToolkitTownGrowthPlugin",
            condition = "map_scenario_toolkit::/mod.script@isDeveloperMode",
            order = 55,
        },
    }
end