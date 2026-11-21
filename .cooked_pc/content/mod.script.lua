local config = ug_require("/config.lua")
local developerTools = ug_require("/developer_tools/developer_tools_window.lua")
local jsonImport = ug_require("/json_import/json_import_window.lua")

local function isDeveloperMode()
    return config.isDeveloperMode()
end

local mod = {
    developerMode = isDeveloperMode(),
    isDeveloperMode = isDeveloperMode,
    DeveloperToolsPlugin = developerTools.plugin,
    JsonImportPlugin = jsonImport,
}

function data()
    return mod
end