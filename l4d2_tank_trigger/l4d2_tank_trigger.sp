#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <left4dhooks>

#define PLUGIN_VERSION "0.1"

ConVar
	ChanceCarAlarm,
	ChanceWitchKilled;

public Plugin Info = {
	author	    = "Rick",
	name	    = "L4D2 Tank Trigger",
	description = "Spawn tank randomly when something happens",
	version	    = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	ChanceCarAlarm	  = CreateConVar("l4d2_tank_trigger_chance_car_alarm", "30", "车被触发响动时召唤tank概率 | probability of spawning tank when trigger car alarm", _, true, 0.0, true, 100.0);
	ChanceWitchKilled = CreateConVar("l4d2_tank_trigger_chance_witch_killed", "30", "witch被杀时召唤tank概率 | probability of spawning tank when a witch is killed", _, true, 0.0, true, 100.0);

	AutoExecConfig(true, "l4d2_tank_trigger");
	PrintToServer("[Tank Trigger] Plugin loaded");

	HookEvent("witch_killed", Event_Spawn);
	HookEvent("triggered_car_alarm", Event_Spawn);
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	CPrintToChatAll("name: %s", name);

	float pos[3];
	int   attacker = GetClientOfUserId(event.GetInt("userid"));
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", pos);

	SpawnTank(pos);
	return Plugin_Continue;
}

void SpawnTank(float pos[3])
{
	bool SpawnSuccess;
	SpawnSuccess = L4D2_SpawnTank(pos, NULL_VECTOR) > 0;
	if (SpawnSuccess)
	{
		CPrintToChatAll("召唤Tank成功");
	}
}