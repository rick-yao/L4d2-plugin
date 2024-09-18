# L4D2 Tank Draw

## Basic Function

This SourceMod plugin for Left 4 Dead 2 adds a "lucky draw" feature that triggers when a Tank is killed by a melee weapon. The player who delivers the final melee blow to the Tank gets a chance to win various prizes that affect gameplay.

## Possible Prizes

The plugin includes the following possible outcomes:

1. No prize (bad luck)
2. Increase health randomly
3. Toggle infinite ammo for all players
4. Toggle infinite melee range for all players
5. Limited-time world gravity to moon gravity
6. Limited-time moon gravity for the lucky player
7. Average health for all survivors
8. Toggle world gravity to moon gravity
9. Increase gravity for the lucky player
10. Decrease health randomly for the lucky player
11. Kill the lucky player
12. Kill all players

## Configuration

The plugin is highly configurable.

All these settings can be modified through ConVars, which can be found and adjusted in the plugin's configuration file.

To customize the plugin, look for the `l4d2_tank_draw.cfg` file in your SourceMod `addons/sourcemod/configs/` directory after first running the plugin on your server.

## Installation

1. Place the `l4d2_tank_draw.smx` file in your `addons/sourcemod/plugins/` directory.
2. Restart your server or load the plugin using the `sm plugins load` command.
3. The plugin will automatically create its configuration file (`l4d2_tank_draw.cfg`) in the `addons/sourcemod/configs/` directory after first run.

Enjoy the excitement of random prizes after taking down a Tank with melee weapons!
