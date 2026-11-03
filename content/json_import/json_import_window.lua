local importJson = ug_require('/json_import/json_import.lua')
local actions = ug_require('/developer_tools/developer_tools_actions.lua')
local data = ug_require('/developer_tools/developer_tools_data.lua')
local developerTools = ug_require('/developer_tools/developer_tools_window.lua')
local react = ug_require('::/gui/main/react.lua')
local builtin = ug_require('::/gui/main/builtin.lua')
local mainModButtonArea = ug_require('::/gui/main/main_mod_button_area.tl')
local gameReactGlobals = ug_require('::/gui/main/game_react_globals.tl')
local styleutil = ug_require('::/gui/main/styleutil.tl')

local importWindow
local importWindowOpen = false
local refreshImportToggle

local function makeStyle(props, padding)
    local result = styleutil.makeStyle(props or {})
    if padding then
        result.padding = api.type.Vec4f.new(padding[1], padding[2], padding[3], padding[4])
    end
    return result
end

local importContent = react.RegisterRecipe('MapScenarioToolkitImportEventsContent', function()
    local jsonText = react.useState('')
    local status = react.useState('')

    local function onImported(dataset)
        actions.sendEvent('developerImportEvents', { dataset = dataset }, 'custom event dataset import')
        developerTools.updateEvents(dataset.industryEvents)
        status:set('Loaded ' .. #dataset.industryEvents .. ' industry events, ' .. #dataset.subsidyEvents .. ' subsidy events, and ' .. #(dataset.townConsumptionEvents or {}) .. ' town consumption rules for this save.')
    end

    local function importPastedEvents()
        if jsonText:old() == '' then
            status:set('Paste compact JSON into the field first.')
            return
        end
        local dataset, importError = importJson(jsonText:old(), data.validator)
        if not dataset then
            status:set(importError)
            return
        end
        onImported(dataset)
    end

    return builtin.BoxLayout {
        orientation = builtin.type.Orientation.Vertical,
        children = {
            builtin.TextView {
                text = 'This dataset adds custom events and town cargo-demand overrides to the standard game behavior.',
                meta = { class = 'font-scale-body' },
            },
            builtin.TextView {
                meta = { styleSheet = makeStyle({ size = { 0, 16 } }) },
            },
            builtin.TextInputField {
                value = jsonText:old(),
                placeholderText = 'Paste compact JSON here',
                maxLength = 100000,
                acceptOnFocusLoss = true,
                onTyping = function(value) jsonText:set(value) end,
                onValueChange = function(value) jsonText:set(value) end,
                meta = { styleSheet = makeStyle({ size = { 540, 72 } }) },

            },
            builtin.TextView {
                meta = { styleSheet = makeStyle({ size = { 0, 8 } }) },
            },
            builtin.Button {
                meta = { class = 'primary', styleSheet = makeStyle({ size = { 220, 28 } }) },
                content = builtin.TextView { text = 'Import pasted events' },
                onClick = importPastedEvents,
            },
            builtin.TextView {
                meta = { styleSheet = makeStyle({ size = { 0, 8 } }) },
            },
            builtin.TextView {
                text = status:old(),
                meta = { class = 'font-scale-body' },
            },
        },
    }
end)

local function closeImportWindow()
    local windowApi = gameReactGlobals.getDefaultWindowApi()
    if not windowApi then
        log.error('Import events window API is unavailable')
        return
    end
    windowApi.removeAllWindows(importWindow)
    importWindowOpen = false
    if refreshImportToggle then refreshImportToggle() end
end

importWindow = react.RegisterWrapperRecipe(
    'MapScenarioToolkitImportEventsWindow',
    builtin.Window,
    function()
        local viewportSize = api.gui.camera.getSize()
        local widthFraction = 620 / viewportSize.x
        return builtin.Window {
            id = 'map_scenario_toolkit.import_events',
            title = 'Map Scenario Toolkit - Import Events',
            initialX = math.min(1 - widthFraction, 0.62),
            initialY = 0.32,
            closable = true,
            movable = true,
            autoFocusOnBecomingVisible = true,
            onClose = closeImportWindow,
            content = importContent(),
        }
    end
)

local function openImportWindow()
    if importWindowOpen then return end
    local windowApi = gameReactGlobals.getDefaultWindowApi()
    if not windowApi then
        log.error('Import events window API is unavailable')
        return
    end
    windowApi.addSingletonWindow(importWindow, {})
    importWindowOpen = true
end

local jsonImportPlugin = react.RegisterPluginRecipe(
    mainModButtonArea.MainModButtonAreaExtension,
    'MapScenarioToolkitJsonImport',
    function()
        local toggle = react.useState(importWindowOpen)
        refreshImportToggle = function() toggle:set(importWindowOpen) end
        return builtin.BoxLayout {
            orientation = builtin.type.Orientation.Horizontal,
            children = {
                builtin.ToggleButton {
                    meta = {
                        tooltip = 'Import a custom JSON event dataset',
                        styleSheet = makeStyle({ size = { 52, 40 } }),
                    },
                    content = builtin.TextView {
                        text = 'JSON',
                        meta = { class = 'font-scale-body' },
                    },
                    value = toggle:old() and 1 or 0,
                    onValueChange = function(value)
                        if value == 1 then openImportWindow() else closeImportWindow() end
                        toggle:set(importWindowOpen)
                    end,
                },
            },
        }
    end
)

return jsonImportPlugin
