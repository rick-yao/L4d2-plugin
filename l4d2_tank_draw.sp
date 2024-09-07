#pragma semicolon 1
#pragma newdecls required 1	   // force new syntax

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"
#define PLUGIN_FLAG    FCVAR_SPONLY | FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS

public Plugin myinfo =
{
	author = "test plugin by rick",


}

public void
	OnPluginStart()
{
	// Hook the tank_killed event
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	// Get the Tank's user ID
	int tankUserId = event.GetInt("userid");
	PrintToServer("[Tank Draw] Tank Spawned - UserID: %d", tankUserId);

	// Get the Tank's client index
	int tankClient = GetClientOfUserId(tankUserId);
	PrintToServer("[Tank Draw] Tank Spawned - Client Index: %d", tankClient);

	// Get and log the Tank's health
	int tankHealth = GetClientHealth(tankClient);
	PrintToServer("[Tank Draw] Tank Spawned - Health: %d", tankHealth);

	// Get and log the Tank's position
	float tankPos[3];
	GetClientAbsOrigin(tankClient, tankPos);
	PrintToServer("[Tank Draw] Tank Spawned - Position: %.2f, %.2f, %.2f", tankPos[0], tankPos[1], tankPos[2]);

	// Get and log the Tank's name (usually "Tank")
	char tankName[MAX_NAME_LENGTH];
	GetClientName(tankClient, tankName, sizeof(tankName));
	PrintToServer("[Tank Draw] Tank Spawned - Name: %s", tankName);

	// Log the current game time
	float gameTime = GetGameTime();
	PrintToServer("[Tank Draw] Tank Spawned - Game Time: %.2f", gameTime);

	// Log the number of alive survivors
	int aliveSurvivors = GetAliveSurvivorCount();
	PrintToServer("[Tank Draw] Tank Spawned - Alive Survivors: %d", aliveSurvivors);

	// Announce Tank spawn to all players
	PrintToChatAll("\x04[Tank Draw] \x01A Tank has spawned with %d health!", tankHealth);
}

// Helper function to get the count of alive survivors
int GetAliveSurvivorCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			count++;
		}
	}
	return count;
}

public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	// Get the Tank's user ID
	int tankUserId = event.GetInt("userid");
	PrintToServer("[Tank Draw] Tank UserID: %d", tankUserId);

	// Get the Tank's client index
	int tankClient = GetClientOfUserId(tankUserId);
	PrintToServer("[Tank Draw] Tank Client Index: %d", tankClient);

	// Get the attacker's user ID
	int attackerUserId = event.GetInt("attacker");
	PrintToServer("[Tank Draw] Attacker UserID: %d", attackerUserId);

	// Get the attacker's client index
	int attackerClient = GetClientOfUserId(attackerUserId);
	PrintToServer("[Tank Draw] Attacker Client Index: %d", attackerClient);

	// check if melee killed
	int isMeleeKilled = event.GetBool("melee_only");
	PrintToServer("[Tank killed]  if melee killed: %d", isMeleeKilled);

	// Check if the attacker is a valid client (not the world)
	if (attackerClient > 0 && attackerClient <= MaxClients && IsClientInGame(attackerClient))
	{
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attackerClient, attackerName, sizeof(attackerName));
		PrintToServer("[Tank Draw] Attacker Name: %s", attackerName);

		// Check if the Tank was killed by melee
		if (isMeleeKilled)
		{
			// Set attacker's health to 200
			SetEntityHealth(attackerClient, 200);
			PrintToServer("[Tank Draw] Attacker %s's health set to 200 for melee kill", attackerName);
		}

		// Print a message to all players
		PrintToChatAll("\x04[Tank Draw] \x01The Tank has been killed by %s!", attackerName);
		PrintToServer("[Tank Draw] The Tank has been killed by %s", attackerName);
	}
	else
	{
		// If the attacker is not a valid client, it might be the world or another entity
		PrintToChatAll("\x04[Tank Draw] \x01The Tank has been killed!");
		PrintToServer("[Tank Draw] The Tank has been killed by an invalid client or the world");
	}

	// Log additional event information
	float tankPos[3];
	GetClientAbsOrigin(tankClient, tankPos);
	PrintToServer("[Tank Draw] Tank death position: %.2f, %.2f, %.2f", tankPos[0], tankPos[1], tankPos[2]);

	int health = event.GetInt("health");
	PrintToServer("[Tank Draw] Tank's remaining health: %d", health);

	bool solo = event.GetBool("solo");
	PrintToServer("[Tank Draw] Was the Tank killed solo? %s", solo ? "Yes" : "No");
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int  victim   = GetClientOfUserId(event.GetInt("userid"));
	int  attacker = GetClientOfUserId(event.GetInt("attacker"));
	char weapon   = event.GetString("weapon");

	PrintToServer("[Tank Draw] Event_PlayerDeath triggered. Victim: %d, Attacker: %d, weapon: &d", victim, attacker, weapon);

	if (!IsValidClient(victim) || !IsValidClient(attacker))
	{
		PrintToServer("[Tank Draw] Invalid client detected. Victim valid: %d, Attacker valid: %d", IsValidClient(victim), IsValidClient(attacker));
		return Plugin_Continue;
	}

	// Check if the victim is a Tank
	int zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
	PrintToServer("[Tank Draw] Victim's zombie class: %d", zombieClass);
	if (zombieClass != 8)
	{
		PrintToServer("[Tank Draw] Victim is not a Tank. Exiting event.");
		return Plugin_Continue;
	}

	bool isBot = event.GetBool("victimisbot");
	PrintToServer("[Tank Draw] is bot: %s", isBot);

	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));
	PrintToServer("[Tank Draw] Victim name: %s, Attacker name: %s", victimName, attackerName);

	// Check if the damage type includes melee

	float tankPos[3];
	GetClientAbsOrigin(victim, tankPos);
	PrintToServer("[Tank Draw] Tank death position: %.2f, %.2f, %.2f", tankPos[0], tankPos[1], tankPos[2]);

	int health = GetClientHealth(attacker);
	PrintToServer("[Tank Draw] Attacker's health after killing Tank: %d", health);

	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}