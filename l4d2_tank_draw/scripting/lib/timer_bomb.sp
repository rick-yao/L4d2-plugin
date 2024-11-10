// In timebomb.sp
#define DAMAGE_BASE    100
#define DEFAULT_RADIUS 300.0
#define BEEP_SOUND     "weapons/hegrenade/beep.wav"
#define EXPLODE_SOUND  "animation/plane_engine_explode.wav"

// Beam related variables
int    g_BeamSprite	 = -1;
int    g_HaloSprite	 = -1;
int    g_ExplosionSprite = -1;
int    greyColor[4]	 = { 128, 128, 128, 255 };
int    whiteColor[4]	 = { 255, 255, 255, 255 };

// Sound related variables (keeping from original)
char   g_BoomSound[PLATFORM_MAX_PATH];

Handle g_hTimeBombTimer[MAXPLAYERS + 1];
int    g_iTimeBombTicks[MAXPLAYERS + 1];

public void OnMapStart()
{
	g_BeamSprite	  = PrecacheModel("sprites/laserbeam.vmt");
	g_HaloSprite	  = PrecacheModel("sprites/glow01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/floorfire4_.vmt");

	PrecacheSound(BEEP_SOUND);
	PrecacheSound(EXPLODE_SOUND);
}

/**
 * Sets or removes a time bomb on a player
 *
 * @param target        Target player index
 * @param ticks         Number of ticks before explosion (default: 5)
 * @param radius        Explosion radius (default: 300.0)
 * @return             True if bomb was set, false if removed
 */
stock bool SetPlayerTimeBomb(int target, int ticks = 5, float radius = DEFAULT_RADIUS, int damage = DAMAGE_BASE)
{
	// Validate target
	if (!IsValidClient(target) || !IsPlayerAlive(target))
		return false;

	// If timer exists, kill it
	if (g_hTimeBombTimer[target] != null)
	{
		KillTimer(g_hTimeBombTimer[target]);
		g_hTimeBombTimer[target] = null;
		g_iTimeBombTicks[target] = 0;

		// Reset player color
		SetEntityRenderColor(target, 255, 255, 255, 255);
		return false;
	}

	// Set up new timer bomb
	g_iTimeBombTicks[target] = ticks;

	DataPack data		 = new DataPack();
	data.WriteCell(target);
	data.WriteCell(damage);
	data.WriteFloat(radius);
	g_hTimeBombTimer[target] = CreateTimer(1.0, Timer_HandleBomb, data, TIMER_REPEAT);

	return true;
}

public Action Timer_HandleBomb(Handle timer, DataPack data)
{
	data.Reset();
	int   target = data.ReadCell();
	int   damage = data.ReadCell();
	float radius = data.ReadFloat();

	if (!IsValidClient(target) || !IsPlayerAlive(target))
	{
		g_hTimeBombTimer[target] = null;
		return Plugin_Stop;
	}

	g_iTimeBombTicks[target]--;

	// Get player position for effects
	float vecOrigin[3];
	GetClientAbsOrigin(target, vecOrigin);
	vecOrigin[2] += 10;	   // Raise effect slightly above ground

	// Visual feedback - player turns more red as timer counts down
	int color = RoundToFloor(g_iTimeBombTicks[target] * (255.0 / 5.0));
	SetEntityRenderColor(target, 255, color, color, 255);

	// Play beep sound
	if (g_iTimeBombTicks[target] >= 1)
	{
		PlaySoundToAll(BEEP_SOUND);
	}
	else if (g_iTimeBombTicks[target] == 0)
	{
		PlaySoundToAll(EXPLODE_SOUND);
	}
	// Create beam rings
	if (g_BeamSprite > -1 && g_HaloSprite > -1)
	{
		// Inner ring (grey)
		TE_SetupBeamRingPoint(vecOrigin, 10.0, radius, g_BeamSprite, g_HaloSprite,
				      0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();

		// Outer ring (white)
		TE_SetupBeamRingPoint(vecOrigin, 10.0, radius, g_BeamSprite, g_HaloSprite,
				      0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
	}

	// Display countdown
	char targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, sizeof(targetName));
	PrintCenterTextAll("%t", "TankDraw_TimeToDie_NoColor", targetName, g_iTimeBombTicks[target]);
	CPrintToChatAll("%t", "TankDraw_TimeToDie", targetName, g_iTimeBombTicks[target]);

	if (g_iTimeBombTicks[target] <= 0)
	{
		// Create explosion effect
		if (g_ExplosionSprite > -1)
		{
			TE_SetupExplosion(vecOrigin, g_ExplosionSprite, 5.0, 1, 0,
					  RoundToNearest(radius), 5000);
			TE_SendToAll();
		}

		// Play explosion sound
		if (g_BoomSound[0])
		{
			EmitAmbientSound(g_BoomSound, vecOrigin, target, SNDLEVEL_RAIDSIREN);
		}

		// Kill the bomb holder
		ForcePlayerSuicide(target);

		// Damage nearby players
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || !IsPlayerAlive(i) || i == target)
				continue;

			float targetPos[3];
			GetClientAbsOrigin(i, targetPos);

			float distance = GetVectorDistance(vecOrigin, targetPos);
			if (distance <= radius)
			{
				// Calculate damage based on distance
				damage = RoundToFloor(damage * ((radius - distance) / radius));

				// Create smaller explosion effect on damaged players
				if (g_ExplosionSprite > -1)
				{
					TE_SetupExplosion(targetPos, g_ExplosionSprite, 0.2, 1, 0, 1, 1);
					TE_SendToAll();
				}

				// Apply damage
				SlapPlayer(i, 0);
				SDKHooks_TakeDamage(i, i, i, float(damage), DMG_GENERIC);
			}
		}

		// Reset variables
		g_hTimeBombTimer[target] = null;
		SetEntityRenderColor(target, 255, 255, 255, 255);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

stock void KillTimeBomb(int client)
{
	if (g_hTimeBombTimer[client] != null)
	{
		KillTimer(g_hTimeBombTimer[client]);
		g_hTimeBombTimer[client] = null;
		g_iTimeBombTicks[client] = 0;
	}

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

stock void KillAllTimeBombs()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillTimeBomb(i);
	}
}