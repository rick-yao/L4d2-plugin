#pragma semicolon 1
#pragma newdecls required 1	   // force new syntax

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"
#define PLUGIN_FLAG    FCVAR_SPONLY | FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS

#define Z_TANK 8

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define IsValidAliveClient(%1)	(1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1))

public Plugin myinfo =
{
	author = "Rick",
	name = "L4D2 Tank Draw",
	description = "Face your destiny after killing a tank",
	version = PLUGIN_VERSION,
}

public void
	OnPluginStart()
{
	PrintToServer("[Tank Draw] Plugin loaded");
	PrintToServer("[Tank Draw] maxclients: %d", MaxClients);
	HookEvent("player_death", Event_PlayerDeath);
}


public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Check if the victim is a Tank
	int  victim   = GetClientOfUserId(event.GetInt("userid"));
	if(!IsTank(victim)){
		PrintToServer("[Tank Draw] Victim is not a Tank. Exiting event.");
		return Plugin_Continue;
	}

	// if the victim is a tank, check if the weapon is a melee weapon
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if(!StrEqual(weapon, "melee", false)){
		PrintToServer("[Tank Draw] No Melee weapon detected. Exiting event.");
		return Plugin_Continue;
	}

	// check if the attacker is an alive client
	int  attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!IsValidAliveClient(attacker)){
		PrintToServer("[Tank Draw] Attacker is not a valid alive client. Exiting event.");
		return Plugin_Continue;
	}

	// now the attacker is a valid alive client and the weapon is a melee weapon
	// so we can make the tank draw
	PrintToServer("[Tank Draw] Event_PlayerDeath triggered. Victim: %d, Attacker: %d, weapon: %s", victim, attacker, weapon);

	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));
	PrintToChatAll("[Tank Draw] %s 被玩家 %s 用近战武器击杀，开始幸运抽奖", victimName, attackerName);

	// TODO: 幸运抽奖逻辑
	LuckyDraw(victim, attacker);

	PrintToChatAll("[Tank Draw] 幸运抽奖结束");

	return Plugin_Continue;
}

bool IsTank(int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
}

Action LuckyDraw(int victim, int attacker)
{
	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));

	PrintToChatAll("[Tank Draw] 幸运抽奖开始");

	int random = GetRandomInt(1, 100);
	
	switch(random)
	{
		case 1, 2, 3, 4, 5, 6, 7, 8, 9, 10:
		{
			int randomHealth = GetRandomInt(200, 500);
			int health = GetClientHealth(attacker) + randomHealth;
			SetEntityHealth(attacker, health);
			PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：随机增加%d血量", attackerName, randomHealth);
		}
		// comment for now
		// case 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50:
		// {
		// 	int amount = GetRandomInt(1, 5);
		// 	char item[64];
		// 	item = GetRandomItem();
		// 	for (int i = 0; i < amount; i++)
		// 	{
		// 		CheatCommand(attacker, "give", item);
		// 	}
		// 	PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：%d * %s", attackerName, amount, item);
		// }
		case 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70:
		{
			// sum all alive survivors' health, then set survivor's health to the average health
			int health = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidAliveClient(i))
				{
					health += GetClientHealth(i);
				}
			}
			int averageHealth = RoundToNearest(float(health) / float(GetClientCount()));
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidAliveClient(i))
				{
					SetEntityHealth(i, averageHealth);
				}
			}
			PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：所有人平均血量 %d", attackerName, averageHealth);
		}
		// moon gravity
		case 71, 72, 73, 74, 75, 76, 77, 78, 79, 80:
		{
			SetEntityGravity(attacker,0.2);
			PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：月球重力", attackerName);
		}
		// all players get moon gravity
		case 81, 82, 83, 84, 85, 86, 87, 88, 89, 90:
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidAliveClient(i))
				{
					SetEntityGravity(i,0.2);
				}
			}
			PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：所有幸存者获得月球重力", attackerName);
		}
		case 91, 92, 93, 94, 95 :
		{
			SetEntityGravity(attacker, 2.0);
			PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：获得2倍重力", attackerName);
		}
		case 96, 97, 98, 99, 100:
		{

			int randomHealth = GetRandomInt(200, 500);
			int health = GetClientHealth(attacker) ;
			if (health > randomHealth)
			{
				SetEntityHealth(attacker, health - randomHealth);
				PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：随机减少%d血量", attackerName, randomHealth);
			}
			else
			{
				SetEntityHealth(attacker, 1);
				PrintToChatAll("[Tank Draw] 玩家 %s 的幸运抽奖结果为：随机减少%d血量，但由于血量过低，所以仅剩1血量", attackerName, randomHealth);
			}
		}
		default:
		{
			PrintToChatAll("[Tank Draw] 非常遗憾，此次砍死tank没有中奖");
		}
	}

	return Plugin_Continue;
}

void CheatCommand(int client, char[] command, char[] arguments)
{
	if (!client) return;
	int admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}

StringMap g_smItemNames;

void InitializeItemNames()
{
    g_smItemNames = new StringMap();
    g_smItemNames.SetString("Pistol", "pistol");
    g_smItemNames.SetString("M16", "rifle");
    g_smItemNames.SetString("AK47", "rifle_ak47");
    g_smItemNames.SetString("SCAR", "rifle_desert");
    g_smItemNames.SetString("Military", "sniper_military");
    g_smItemNames.SetString("AWP", "sniper_awp");
    g_smItemNames.SetString("Scout", "sniper_scout");
    g_smItemNames.SetString("Launcher", "grenade_launcher");
    g_smItemNames.SetString("M60", "rifle_m60");
    g_smItemNames.SetString("Machete", "machete");
    g_smItemNames.SetString("Katana", "katana");
    g_smItemNames.SetString("Tonfa", "tonfa");
    g_smItemNames.SetString("FireAxe", "fireaxe");
    g_smItemNames.SetString("Knife", "knife");
    g_smItemNames.SetString("Guitar", "guitar");
    g_smItemNames.SetString("Pan", "melee");
    g_smItemNames.SetString("CricketBat", "cricket_bat");
    g_smItemNames.SetString("ChainSaw", "chainsaw");
    g_smItemNames.SetString("Molotov", "molotov");
    g_smItemNames.SetString("HealthKit", "first_aid_kit");
    g_smItemNames.SetString("Defib", "defibrillator");
    g_smItemNames.SetString("Adren", "adrenaline");
    g_smItemNames.SetString("PitchFork", "pitchfork");
    g_smItemNames.SetString("CrowBar", "crowbar");
    g_smItemNames.SetString("Shovel", "shovel");
}

char[] GetRandomItem()
{
    char itemKey[32];
    char itemValue[64];
    ArrayList keys = new ArrayList(ByteCountToCells(32));
    
    StringMapSnapshot snapshot = g_smItemNames.Snapshot();
    int size = snapshot.Length;
    
    for (int i = 0; i < size; i++)
    {
        snapshot.GetKey(i, itemKey, sizeof(itemKey));
        keys.PushString(itemKey);
    }
    
    int randomIndex = GetRandomInt(0, size - 1);
    keys.GetString(randomIndex, itemKey, sizeof(itemKey));
    g_smItemNames.GetString(itemKey, itemValue, sizeof(itemValue));
    
    delete snapshot;
    delete keys;
    
    return itemValue;
}