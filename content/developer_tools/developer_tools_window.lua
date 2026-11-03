local data = ug_require("/developer_tools/developer_tools_data.lua")
local actions = ug_require("/developer_tools/developer_tools_actions.lua")
local react = ug_require("::/gui/main/react.lua")
local builtin = ug_require("::/gui/main/builtin.lua")
local mainModButtonArea = ug_require("::/gui/main/main_mod_button_area.tl")
local gameReactGlobals = ug_require("::/gui/main/game_react_globals.tl")
local styleutil = ug_require("::/gui/main/styleutil.tl")

local developerToolsWindow
local developerToolsWindowOpen = false
local refreshDeveloperToolsToggle
local refreshDeveloperEventList
local activeEventsForUi = data.events

local function makeStyle(props, padding)
    local result = styleutil.makeStyle(props or {})
    if padding then
        result.padding = api.type.Vec4f.new(padding[1], padding[2], padding[3], padding[4])
    end
    return result
end

local function spacer(width, height)
    return builtin.TextView {
        text = "",
        meta = { styleSheet = makeStyle({ size = { width, height } }) },
    }
end

local function heading(label)
    return builtin.TextView {
        text = label,
        meta = {
            class = "font-scale-title-3",
            styleSheet = makeStyle({ color = { 0.85, 0.90, 1.0, 1 } }),
        },
    }
end

local function button(label, onClick, options)
    options = options or {}
    local meta = {
        class = options.selected and "primary" or "secondary",
        styleSheet = makeStyle({ size = { options.width or 480, 24 } }),
    }
    if options.enabled ~= nil then
        meta.enabled = options.enabled
    end
    return builtin.Button {
        meta = meta,
        content = builtin.TextView {
            text = label,
            meta = { class = "font-scale-body" },
        },
        onClick = onClick,
    }
end

local function daysInMonth(year, month)
    if month == 2 then
        local isLeapYear = year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
        return isLeapYear and 29 or 28
    end
    if month == 4 or month == 6 or month == 9 or month == 11 then
        return 30
    end
    return 31
end

local function makeDateSlider(label, value, minimum, maximum, pageStep, onValueChange)
    return builtin.BoxLayout {
        orientation = builtin.type.Orientation.Vertical,
        children = {
            builtin.TextView {
                text = label .. ": " .. tostring(value),
                meta = { class = "font-scale-body" },
            },
            builtin.Slider {
                min = minimum,
                max = maximum,
                step = 1,
                pageStep = pageStep,
                horizontal = true,
                drawGroove = true,
                value = value,
                onValueChange = onValueChange,
                meta = {
                    styleSheet = makeStyle({ size = { 540, 36 } }),
                },
            },
        },
    }
end

local function makeDateEditor(year, month, day)
    return {
        heading("Set test date"),
        makeDateSlider("Year", year:old(), 1900, 2200, 1, function(value)
            year:set(value)
            day:set(math.min(day:old(), daysInMonth(value, month:old())))
        end),
        makeDateSlider("Month", month:old(), 1, 12, 1, function(value)
            month:set(value)
            day:set(math.min(day:old(), daysInMonth(year:old(), value)))
        end),
        makeDateSlider("Day", day:old(), 1, daysInMonth(year:old(), month:old()), 1, function(value)
            day:set(value)
        end),
        button("Apply date", function()
            actions.setTestDate({
                year = year:old(),
                month = month:old(),
                day = day:old(),
            })
        end, { width = 180 }),
    }
end

local function makeEventOption(value, text)
    return builtin.ComboBoxItem {
        value = value,
        content = builtin.TextView {
            text = text
        },
    }
end

local developerToolsContent = react.RegisterRecipe("MapScenarioToolkitDeveloperToolsContent", function()
    local year = react.useState(data.initialTestDate.year)
    local month = react.useState(data.initialTestDate.month)
    local day = react.useState(data.initialTestDate.day)
    local selectedEventId = react.useState(nil)
    local activeEvents = react.useState(activeEventsForUi)
    refreshDeveloperEventList = function()
        activeEvents:set(activeEventsForUi)
        selectedEventId:set(nil)
    end
    local children = makeDateEditor(year, month, day)

    log.message("Rendering developer tools; selected event = ".. tostring(selectedEventId:old() or ""))

    local comboStyle = api.gui.StyleSheet.new()
    comboStyle.padding = api.type.Vec4f.new(0, 0, 0, 0)

    children[#children + 1] = spacer(0, 8)
    children[#children + 1] = heading("Force-spawn event")
    children[#children + 1] = spacer(0, 4)
    if #activeEvents:old() == 0 then
        children[#children + 1] = builtin.TextView { text = "No events registered." }
    else
        local eventOptions = {
            makeEventOption("", "Select an event to trigger"),
        }
        for _, event in ipairs(activeEvents:old()) do
            eventOptions[#eventOptions + 1] = makeEventOption(event.id, event.name)
        end

        children[#children + 1] = builtin.ComboBox {
            value = selectedEventId:old() or "",
            items = eventOptions,
            onValueChange = function(value)
                selectedEventId:set(value ~= "" and tostring(value) or nil)
            end,
            meta = {
                styleSheet = comboStyle,
                tooltip = "Choose a configured event to trigger immediately",
            },
        }
        children[#children + 1] = button("Trigger selected event", function()
            local selectedId = selectedEventId:old()
            if not selectedId then
                return
            end
            for _, event in ipairs(activeEvents:old()) do
                if event.id == selectedId then
                    log.message("Developer requested event trigger: " .. event.id)
                    actions.sendEvent(
                        "developerTriggerSpawn",
                        { spawnId = event.spawnId },
                        "event trigger for " .. event.id
                    )
                    return
                end
            end
            log.error("Selected developer event is no longer registered: " .. tostring(selectedId))
        end, { enabled = selectedEventId:old() ~= nil })
    end

    children[#children + 1] = spacer(0, 16)
    children[#children + 1] = heading("Industry road connections")
    children[#children + 1] = button("Check spawned industry road connections", function()
        actions.sendEvent(
            "developerCheckIndustryRoadConnections",
            {},
            "spawned-industry road connection check"
        )
    end)
    children[#children + 1] = spacer(0, 16)
    children[#children + 1] = heading("Reset test changes")
    children[#children + 1] = builtin.TextView {
        text = "Removes mod-spawned industries and restores the captured start date.",
        meta = {
            class = "font-scale-body",
            styleSheet = makeStyle({ color = { 0.95, 0.78, 0.40, 1 }, size = { 540, 48 } }),
        },
    }
    children[#children + 1] = button(
        "Reset test changes", function()
            actions.resetMap()
        end
    )

    return builtin.BoxLayout {
        orientation = builtin.type.Orientation.Vertical,
        children = children,
    }
end)

local function closeDeveloperToolsWindow()
    local windowApi = gameReactGlobals.getDefaultWindowApi()
    if not windowApi then
        log.error("Developer tools window API is unavailable")
        return
    end
    windowApi.removeAllWindows(developerToolsWindow)
    developerToolsWindowOpen = false
    refreshDeveloperEventList = nil
    if refreshDeveloperToolsToggle then refreshDeveloperToolsToggle() end
end

developerToolsWindow = react.RegisterWrapperRecipe(
    "MapScenarioToolkitDeveloperToolsWindow",
    builtin.Window,
    function()
        local viewportSize = api.gui.camera.getSize()
        local windowWidthFraction = 620 / viewportSize.x
        local windowHeightFraction = 560 / viewportSize.y
        return builtin.Window {
            id = "map_scenario_toolkit.developer_tools",
            title = "Map Scenario Toolkit - Developer Tools",
            initialX = (1 - windowWidthFraction) / 2,
            initialY = (1 - windowHeightFraction) / 2,
            closable = true,
            movable = true,
            autoFocusOnBecomingVisible = true,
            onClose = closeDeveloperToolsWindow,
            content = developerToolsContent()
        }
    end
)


local function openDeveloperToolsWindow()
    local viewportSize = api.gui.camera.getSize()
    log.message("Developer tools viewport size: " .. viewportSize.x .. " x " .. viewportSize.y)
    if developerToolsWindowOpen then
        return
    end
    local windowApi = gameReactGlobals.getDefaultWindowApi()
    if not windowApi then
        log.error("Developer tools window API is unavailable")
        return
    end
    windowApi.addSingletonWindow(developerToolsWindow, {})
    developerToolsWindowOpen = true
end

local developerToolsPlugin = react.RegisterPluginRecipe(
    mainModButtonArea.MainModButtonAreaExtension,
    "MapScenarioToolkitDeveloperTools",
    function()
        local developerToggle = react.useState(developerToolsWindowOpen)
        refreshDeveloperToolsToggle = function() developerToggle:set(developerToolsWindowOpen) end

        return builtin.BoxLayout {
            orientation = builtin.type.Orientation.Horizontal,
            children = {
                builtin.ToggleButton {
                    meta = {
                        tooltip = "Open Map Scenario Toolkit developer tools",
                        styleSheet = makeStyle({ size = { 44, 40 } }),
                    },
                    content = builtin.ImageView {
                        path = "map_scenario_toolkit::/developer_tools/dev_tools_icon.tga",
                        scaling = builtin.type.ImageViewScaling.AutoFit,
                        meta = { styleSheet = styleutil.makeStyle({ size = { 36, 24 } }) },
                    },
                    value = developerToggle:old() and 1 or 0,
                    onValueChange = function(value)
                        if value == 1 then
                            openDeveloperToolsWindow()
                        else
                            closeDeveloperToolsWindow()
                        end
                        developerToggle:set(developerToolsWindowOpen)
                    end,
                },

            },
        }
    end
)

return {
    plugin = developerToolsPlugin,
    updateEvents = function(events)
        activeEventsForUi = {}
        for _, event in ipairs(events) do
            activeEventsForUi[#activeEventsForUi + 1] = {
                id = event.id,
                spawnId = event.id,
                name = "Spawn " .. event.name,
            }
        end
        if refreshDeveloperEventList then
            refreshDeveloperEventList()
        end
    end,
}