# L4D2 Tank Draw

## Basic Function

This SourceMod plugin for Left 4 Dead 2 adds a "lucky draw" feature that triggers when a Tank is killed by a melee weapon. The player who delivers the final melee blow to the Tank gets a chance to win various prizes that affect gameplay.

## Possible Prizes

The plugin includes the following possible prizes:

1. No prize
2. Lucky player gains random health
3. Average health among all survivors
4. Reset all survivors' health to 100 and reset their incapped times
5. Clear all survivors' health
6. Lucky player takes random damage
7. All survivors gain infinite ammo
8. All survivors gain infinite primary ammo
9. All survivors gain infinite melee range
10. Temporary moon gravity for all
11. Temporary moon gravity for the lucky player
12. Toggle moon gravity for all
13. Increase gravity for the lucky player
14. Kill the lucky player
15. Kill all survivors
16. Resurrect all dead survivors
17. Disarm the lucky player
18. Disarm all survivors
19. A lucky Tank
20. A lucky Witch
21. Turn the lucky player into a "timer bomb"
22. Turn the lucky player into a "freeze bomb"

## Configuration

The plugin is highly configurable.

All these settings can be modified through ConVars, which can be found and adjusted in the plugin's configuration file.

To customize the plugin, look for the `l4d2_tank_draw.cfg` file in your SourceMod `addons/sourcemod/configs/` directory after first running the plugin on your server.

## Installation

1. Place the `l4d2_tank_draw.smx` file in your `addons/sourcemod/plugins/` directory.
2. Put l4d2_tank_draw/translations/l4d2_tank_draw.phrases.txt inside `addons/sourcemod/translations/` directory.
3. Restart your server or load the plugin using the `sm plugins load` command.
4. The plugin will automatically create its configuration file (`l4d2_tank_draw.cfg`) in the `addons/sourcemod/configs/` directory after first run.

Enjoy the excitement of random prizes after taking down a Tank with melee weapons!

#### NOTE

Since infinite ammo is also applied to molotov, so I added a mechanism to randomly disarm/kill/turn into a timer bomb player if the player throw molotov when infinite ammo is on.

#### Other language

[简体中文](/l4d2_tank_draw/README_CN.md)
