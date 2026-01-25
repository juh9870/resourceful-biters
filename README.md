[![Release](https://github.com/juh9870/resourceful-biters/actions/workflows/release.yml/badge.svg?branch=main)](https://github.com/juh9870/resourceful-biters/actions/workflows/release.yml)

# Resourceful Biters
Biters ate all resources on Nauvis. Pentapods just couldn't get enough of that stone on Gleba. Demolishers metabolized all of Vulcanus patches. TAKE THEM BACK!

## Descritption
Generation of normal resources is removes. Kill enemies to make them drop resource patches for you to mine

Resources are still present in the map settings. Tweak the `Frequency` slider to make resource drop more or less frequent compared to other resources, `Richness` and `Size` sliders to make this resource drop in greater or lesser quantity (effects from these two sliders are multiplicative). Let me know in the discussions tab if sliders for modded planets don't affect the drops

Built-in support for:
- Vanilla resources
- Space age resources
- Krastorio 2 (and K2SO) - Rare metals
- Rubia

Automatic support for other modded resources. If you encounter a resource that is broken or wrong, please let me know in the discussions

## Recommended mods
- [Fulgoran enemies](https://mods.factorio.com/mod/Electric_flying_enemies) - If you play Space Age, some mod to add enemies to Fulgora is required, **otherwise you get no way to obtain scrap**
- [Decay configuration](https://mods.factorio.com/mod/decay_configuration) - Or some other mod to reduce biter corpse decay time, to make it easier to place drills

## Mod settings
This mod has a startup option to disable the disabling of resources, as well as map settings to control the amount of resources dropped and whenver neutral or player entities would drop the resources on death

By default only enemy drops are enabled for balancing and sanity reasons

## Info for modders
If you wish to blacklist or configure a resource/entity/surface/etc, edit the values inside `data.raw["mod-data"]["resourceful-biters-data"]` in the data-updates stage. See `data.lua` for how it's defined and `lib/api.lua` for the LuaLS type definitions