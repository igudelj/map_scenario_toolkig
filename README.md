# Map Scenario Toolkit

Map Scenario Toolkit provides map-specific scenario data for Transport Fever 3: date- and shipment-triggered industry spawns, custom subsidies that use the game's existing subsidy types, ordered town cargo demand, JSON import for development, and developer controls.

The toolkit is the reusable framework. A map creator supplies the actual scenario in a separate companion content mod, which depends on `map_scenario_toolkit`. This lets each map ship its own data without forking the framework.

## Install and configure

Enable **Map Scenario Toolkit** for the map/save. In the pre-game mod options, select the toolkit and open its settings. These options are stored with that game setup and are applied when the map/save loads:

| Option | Default | Effect |
|---|---|---|
| Developer tools | Off | Shows the developer window and town growth controls. The JSON dataset importer remains available regardless of this setting. |
| Native subsidy offers | Enabled | Keeps the game's normal random subsidy offers enabled alongside scenario subsidy events. |
| Native industry spawning | Enabled | Keeps the game's normal industry development enabled alongside scenario industry events. |

Turning off native subsidies sets the game's subsidy mode to off. Turning off native industry spawning disables its native industry development. These are pre-load options, not in-game runtime toggles. Scenario events are controlled by the map dataset independently.

### Enable developer tools for local development

Before starting or loading the map, open Map Scenario Toolkit's settings in the mod options and set **Developer tools** to **On**. The controls are available for that save; switch the option back to **Off** for normal play. No Lua source edit is needed. The setting is also available to players, so leave its default off in the published mod.
## Dataset formats

A dataset can be supplied in either of two ways:

1. **Bundled with a map-specific companion mod:** the framework discovers a registered generic resource of type `map_scenario_toolkit_data` from the enabled mods. This is the recommended way to publish a map with fixed scenario content.
2. **Pasted in the JSON importer:** available from the toolkit UI regardless of the Developer tools setting. This replaces the currently selected custom dataset for the running save; it does not edit the packaged Lua data.

Both formats represent the same object:

```json
{
  "industryEvents": [],
  "subsidyEvents": [],
  "townConsumptionEvents": []
}
```

Empty arrays mean that dataset contributes no rules of that kind. They do not turn off the game's native industry development or subsidy offers.

## Constructing the JSON dataset

The full working example is [`content/examples/osijek_demo_dataset.json`](content/examples/osijek_demo_dataset.json). The Lua starter for a companion map-data mod is [`content/examples/map_scenario_toolkit_dataset.lua`](content/examples/map_scenario_toolkit_dataset.lua). Mod Hub download folders are managed by mod.io and can vary by installation; examples are under `content/examples/` inside the installed toolkit package. It covers date and shipment industry triggers, date/spawn/shipment subsidy triggers, random subsidy selection, and commercial/industrial town demand. [`content/examples/osijek_demo_events_compact.json`](content/examples/osijek_demo_events_compact.json) is a smaller industry-only example. [`content/examples/town_cargo_reference_temperate.json`](content/examples/town_cargo_reference_temperate.json) is a lookup reference for cargo choices; it is not itself an importable dataset.

### Industry events

Each `industryEvents` entry accepts:

- `id`: unique string used to refer to this event.
- `fileName`: construction resource path, such as `::/industries/farm/farm.con`.
- `name`: name assigned to the spawned industry.
- `trigger`: one of the supported trigger objects below.
- `location` (optional): `{ "townName": "Osijek", "directionWeights": { "north": 4, "east": 2, "south": 1, "west": 1 } }`.
- `rotation` (optional): a number of degrees or `"random"`.

Date trigger:

```json
"trigger": { "type": "date", "date": { "year": 1940, "month": 10, "day": 1 } }
```

Shipment trigger:

```json
"trigger": {
  "type": "shipment",
  "sourceIndustryFileName": "::/industries/farm/farm.con",
  "sourceIndustryName": "Osijek Demo Farm",
  "cargoTypeFileName": "::/cargos/grain/grain.cargo",
  "minimumShippedPerYear": 10
}
```

The source construction path, source industry name, cargo path, and threshold must all match a real source and its shipments. A shipment-triggered event waits until the configured annual amount is reached.

### Subsidy events

Each `subsidyEvents` entry has a unique `id`, a `trigger`, and a `subsidy` action. Triggers are:

- `date`: same date object as above.
- `industrySpawned`: `{ "type": "industrySpawned", "industryEventId": "event_id" }`.
- `shipment`: same source/cargo/annual threshold fields as the industry shipment trigger.

Actions use existing game subsidy types: `deliver_cargo`, `deliver_cargo_town`, `deliver_passengers`, or `deliver_workers`. For industry targets, configure the target construction and any required cargo. `selection` can be `closest` or `random`; `nearIndustryEventId` can select a spawned event as the distance reference. Passenger routes use `sourceTownName` and `targetTownName`; town cargo subsidies use `townName` and `cargoTypeFileName`.

To choose a random action from configured options, use `"type": "random"` and a `candidates` array containing regular subsidy action objects. This randomizes among your listed candidates; it does not replace or customize the game's native subsidy system. The game controls subsidy notification text, so the dataset cannot provide custom messages.

See `subsidyEvents` in the Osijek example for complete combinations. An `industrySpawned` subsidy must reference an ID that exists in the same dataset's `industryEvents` array.

### Town cargo demand

Each `townConsumptionEvents` entry targets a town by exact `townName` and may provide ordered cargo arrays:

```json
{
  "townName": "Osijek",
  "consumptionCommercialSlots": [
    "::/cargos/meat/meat.cargo",
    "::/cargos/vegetables/vegetables.cargo",
    "::/cargos/tinned_food/tinned_food.cargo"
  ],
  "consumptionIndustrialSlots": [
    "::/cargos/bricks/bricks.cargo",
    "::/cargos/planks/planks.cargo",
    "::/cargos/fuel/fuel.cargo"
  ]
}
```

Array order is preserved. The first configured entry fills additional demand slot 2, the next fills slot 3, then slot 4, and so on. Native slot 1 is left intact. Omit a district's array to leave its additional demands under normal game control. The game applies the configured cargoes when the town's demand slots are created/updated; changes may not be visible until the next town update or growth cycle. Cargoes must exist and be valid for the town's economy/district.

## Publish a map-specific data mod

Keep the toolkit as the reusable baseline and publish map data as a separate companion mod. A companion mod is ordinary mod content; a Lua file placed directly inside a map package is not discovered as a registered resource. The resource type is the connection between the companion data pack and the toolkit.

1. Create a separate folder in the game's staging area for the companion mod. Give it a unique `modId`, for example `map_yugoslavia_events`, plus `_metadata/modinfo.json`, `content/`, and `_content.json`. The mod folder and `modId` should match.
2. In the companion `mod.json`, add a required dependency on the toolkit:

   ```json
   {
     "mod": { "modId": "map_scenario_toolkit", "revisionMin": 1, "revisionMax": -1 },
     "modInfo": { "displayName": "Map Scenario Toolkit", "url": "" },
     "loadBefore": true,
     "optional": false
   }
   ```

   Add this object to the `dependencies` array while retaining the companion's own `modId` and other header fields.
3. Create `content/map_scenario_toolkit_dataset.lua`. Return a Lua table with the same three keys as the JSON format. Lua syntax uses `=` and no quotes around keys; resource paths and strings still need quotes.
4. Create `content/map_scenario_toolkit_dataset.res.lua` to register that table:

   ```lua
   local dataset = ug_require("/map_scenario_toolkit_dataset.lua")

   function data()
       return {
           type = "map_scenario_toolkit_data",
           data = dataset,
       }
   end
   ```

   The `ug_require` string is the path to your Lua data file inside the companion mod. The `type` value must match the toolkit's resource type exactly.
5. List both content files in the companion's `_content.json`:

   ```json
   {
     "files": [
       "map_scenario_toolkit_dataset.lua",
       "map_scenario_toolkit_dataset.res.lua"
     ]
   }
   ```
6. Enable the toolkit and companion mod for a new game/save using the target map. Check the game log for the dataset load/validation result and test the event dates, shipment conditions, subsidy targets, and town cargo arrays. Enable only one `map_scenario_toolkit_data` resource per save; multiple packs make the dataset source ambiguous.
7. For local testing, the staging-area folder is the editable mod source. Use Transport Fever 3's Mod Hub workflow to validate and publish each mod separately; there is no separate toolkit command that compiles the dataset. Upload the companion data mod as its own item, then publish/update the map and set the companion as a required dependency where the map publishing workflow supports dependencies. Players need the map, the data pack, and Map Scenario Toolkit enabled. The companion's mod dependency ensures the toolkit is available.

The base toolkit can be published once and reused by multiple map data packs. Increment the companion mod revision when publishing changes to its Lua data or resource declaration. The game modding guide describes mods as directories with their own `mod.json`, metadata, and content files: [Transport Fever 3 mod parameter guide](https://tf3-docs.transportfever.net/en/guides/mod-structure.html).

## Troubleshooting

- **Developer controls are missing:** select Map Scenario Toolkit in the pre-game mod options and set **Developer tools** to **On** before loading the map/save.
- **No bundled data is found:** check that the companion `_content.json` lists both files, the `.res.lua` uses type `map_scenario_toolkit_data`, and the companion mod is enabled for the save.
- **No events trigger:** check the game log for validation errors. Verify exact town/industry names, resource paths, dates, cargo paths, and shipment thresholds.
- **More than one data pack is enabled:** disable extras so only one mod registers `map_scenario_toolkit_data` for the save.
- **Town cargo demand has not changed:** allow the town to refresh/update; configured demand is applied as slots update, not as a manual immediate population-level change.
- **Native events still occur:** check the **Native subsidy offers** and **Native industry spawning** options in the pre-game mod settings; they take effect when the map/save loads.