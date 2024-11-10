// In timebomb.sp
#define DAMAGE_BASE    100
#define DEFAULT_RADIUS 300.0

// Beam related variables - these can be set from the main plugin
int	   g_BeamSprite	     = -1;
int	   g_HaloSprite	     = -1;
int	   g_ExplosionSprite = -1;
int	   greyColor[4]	     = { 128, 128, 128, 255 };
int	   whiteColor[4]     = { 255, 255, 255, 255 };

Handle	   g_hTimeBombTimer[MAXPLAYERS + 1];
int	   g_iTimeBombTicks[MAXPLAYERS + 1];

/**
 * Sets sprites for beam effects
 *
 * @param beamSprite    Beam sprite index
 * @param haloSprite    Halo sprite index
 * @param explosionSprite Explosion sprite index
 */
stock void SetTimeBombSprites(int beamSprite, int haloSprite, int explosionSprite)
{
	g_BeamSprite	  = beamSprite;
	g_HaloSprite	  = haloSprite;
	g_ExplosionSprite = explosionSprite;
}

/**
 * Sets or removes a time bomb on a player
 *
 * @param target        Target player index
 * @param ticks         Number of ticks before explosion (default: 5)
 * @param radius        Explosion radius (default: 300.0)
 * @return             True if bomb was set, false if removed
 */
stock bool SetPlayerTimeBomb(int target, int ticks = 5, float radius = DEFAULT_RADIUS)
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
	g_hTimeBombTimer[target] = CreateTimer(1.0, Timer_HandleBomb, target, TIMER_REPEAT);

	return true;
}

public Action Timer_HandleBomb(Handle timer, any target)
{
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

	// Create beam rings if sprites are set
	if (g_BeamSprite > -1 && g_HaloSprite > -1)
	{
		// Inner ring (grey)
		TE_SetupBeamRingPoint(vecOrigin, 10.0, DEFAULT_RADIUS / 3.0, g_BeamSprite, g_HaloSprite,
				      0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();

		// Outer ring (white)
		TE_SetupBeamRingPoint(vecOrigin, 10.0, DEFAULT_RADIUS / 3.0, g_BeamSprite, g_HaloSprite,
				      0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
	}

	// Display countdown
	PrintToChatAll("Player will explode in: %d", g_iTimeBombTicks[target]);

	if (g_iTimeBombTicks[target] <= 0)
	{
		// Create explosion effect if sprite is set
		if (g_ExplosionSprite > -1)
		{
			TE_SetupExplosion(vecOrigin, g_ExplosionSprite, 5.0, 1, 0,
					  RoundToNearest(DEFAULT_RADIUS), 5000);
			TE_SendToAll();
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
			if (distance <= DEFAULT_RADIUS)
			{
				// Calculate damage based on distance
				int damage = DAMAGE_BASE;
				damage	   = RoundToFloor(damage * ((DEFAULT_RADIUS - distance) / DEFAULT_RADIUS));

				// Create smaller explosion effect on damaged players
				if (g_ExplosionSprite > -1)
				{
					TE_SetupExplosion(targetPos, g_ExplosionSprite, 0.05, 1, 0, 1, 1);
					TE_SendToAll();
				}

				// Apply damage
				SlapPlayer(i, damage, false);
			}
		}

		// Reset variables
		g_hTimeBombTimer[target] = null;
		SetEntityRenderColor(target, 255, 255, 255, 255);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}