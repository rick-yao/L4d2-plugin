# L4D2 Tank Draw

#### Other language

[简体中文](/l4d2_tank_draw/README_CN.md)


## Basic Function

This SourceMod plugin for Left 4 Dead 2 adds a "lucky draw" feature that triggers when a Tank is killed by a melee weapon. The player who delivers the final melee blow to the Tank gets a chance to win various prizes that affect gameplay.

## Possible Prizes

The plugin includes the following possible prizes:

**The default configuration sets the probability of "no prize" to 10, while all other prizes are set to 0. Please configure them yourself.**  
**The probability of a single prize is calculated as: (prize probability) / (sum of all prize probabilities)** 

1. No prize
2. Lucky player gains random health (Survivor's total health cannot exceed the server's maximum health limit)
3. Average health among all survivors (Averages the actual health of all standing survivors and clears temporary health)
4. Reset all survivors' health to 100 and clear their incapped counts
5. Clear all standing survivors' health (Sets the actual health of all standing survivors to 1 and clears temporary health)
6. Lucky player takes random damage (If damage exceeds health, health is set to 1 instead of incapacitating)
7. All survivors gain infinite ammo (Global game parameter, repeated draws will reset to default; cannot coexist with infinite primary ammo)
8. All survivors gain infinite primary ammo (Global game parameter, repeated draws will reset to default; cannot coexist with infinite ammo)
9. All survivors gain infinite melee range (Global game parameter, repeated draws will reset to default)
10. Temporarily adjust world gravity to moon gravity (Global game parameter, climbing ladders does not remove the buff; repeated draws reset the timer)
11. Temporarily adjust the lucky player's gravity to moon gravity (Climbing ladders can remove the buff)
12. Toggle world gravity to moon gravity (Global game parameter, climbing ladders does not remove the buff; repeated draws will reset to default)
13. Increase gravity for the lucky player (Climbing ladders can remove the buff)
14. Kill the lucky player
15. Kill all survivors
16. Resurrect all dead survivors
17. Disarm the lucky player (Clears all item slots)
18. Disarm all survivors (Clears all item slots)
19. Spawn a lucky Tank
20. Spawn a lucky Witch
21. Turn the lucky player into a "timer bomb" (Repeated draws will cancel the timer)
22. Turn the lucky player into a "freeze bomb" (Repeated draws will cancel the timer)
23. Remove survivor outlines (Removes survivor glow outlines, but names above players remain visible; not recommended as many plugins modify outlines)
24. Temporarily Drug lucky player
24. Temporarily Drug all survivors

## Configuration

The plugin is highly configurable.

All these settings can be modified through ConVars, which can be found and adjusted in the plugin's configuration file.

To customize the plugin, look for the `l4d2_tank_draw.cfg` file in your SourceMod `addons/sourcemod/configs/` directory after first running the plugin on your server.

## Installation

1. Place the `l4d2_tank_draw.smx` file in your `addons/sourcemod/plugins/` directory.
2. Put `l4d2_tank_draw.phrases.txt` inside `addons/sourcemod/translations/` directory.
3. Restart your server or load the plugin using the `sm plugins reload` command.
4. The plugin will automatically create its configuration file (`l4d2_tank_draw.cfg`) in the `addons/sourcemod/configs/` directory after first run.
5. Modify cfg then reload

Enjoy the excitement of random prizes after taking down a Tank with melee weapons!

#### NOTE

Since infinite ammo is also applied to molotov, so I added a mechanism to randomly disarm/kill/turn into a timer bomb player if the player throw molotov when infinite ammo is on. If you don't need it you can set punishment chance to 0.