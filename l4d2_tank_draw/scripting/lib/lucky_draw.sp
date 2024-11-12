stock Action LuckyDraw(int victim, int attacker)
{
	int chanceNoPrice		      = ChanceNoPrice.IntValue;
	int chanceIncreaseHealth	      = ChanceIncreaseHealth.IntValue;
	int chanceInfiniteAmmo		      = ChanceInfiniteAmmo.IntValue;
	int chanceInfiniteMelee		      = ChanceInfiniteMelee.IntValue;
	int chanceAverageHealth		      = ChanceAverageHealth.IntValue;
	int chanceDecreaseHealth	      = ChanceDecreaseHealth.IntValue;
	int chanceKillAllSurvivor	      = ChanceKillAllSurvivor.IntValue;
	int chanceKillSingleSurvivor	      = ChanceKillSingleSurvivor.IntValue;
	int chanceDisarmAllSurvivor	      = ChanceDisarmAllSurvivor.IntValue;
	int chanceDisarmSingleSurvivor	      = ChanceDisarmSingleSurvivor.IntValue;
	int chanceNewTank		      = ChanceNewTank.IntValue;
	int chanceTimerBomb		      = ChanceTimerBomb.IntValue;
	int chanceIncreaseTempHealth	      = ChanceIncreaseTempHealth.IntValue;

	int chanceLimitedTimeWorldMoonGravity = ChanceLimitedTimeWorldMoonGravity.IntValue;
	int chanceMoonGravityOneLimitedTime   = ChanceMoonGravityOneLimitedTime.IntValue;
	int chanceWorldMoonGravityToggle      = ChanceWorldMoonGravityToggle.IntValue;
	int chanceIncreaseGravity	      = ChanceIncreaseGravity.IntValue;
	int chanceClearAllSurvivorHealth      = ChanceClearAllSurvivorHealth.IntValue;
	int chanceReviveAllDead		      = ChanceReviveAllDead.IntValue;

	int totalChance			      = chanceNoPrice + chanceIncreaseTempHealth + chanceTimerBomb + chanceReviveAllDead + chanceNewTank + chanceDisarmSingleSurvivor + chanceDisarmAllSurvivor + chanceDecreaseHealth + chanceClearAllSurvivorHealth + chanceIncreaseHealth + chanceInfiniteAmmo + chanceInfiniteMelee + chanceAverageHealth + chanceKillAllSurvivor + chanceKillSingleSurvivor;
	totalChance += chanceLimitedTimeWorldMoonGravity + chanceMoonGravityOneLimitedTime + chanceWorldMoonGravityToggle + chanceIncreaseGravity;

	if (totalChance == 0)
	{
		PrintToServer("所有概率总和为0，跳过抽奖 / total change equals to 0, do not draw");
		return Plugin_Continue;
	}

	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));

	int random = GetRandomInt(1, totalChance);
	PrintToServer("total chance: %d, random: %d", totalChance, random);

	int currentChance = 0;

	// no prize
	currentChance += chanceNoPrice;
	if (random <= currentChance)
	{
		CPrintToChatAll("%t", "TankDrawResult_NoPrize", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_NoPrize_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceIncreaseTempHealth;
	if (random <= currentChance)
	{
		int minHealth	 = MinTempHealthIncrease.IntValue;
		int maxHealth	 = MaxTempHealthIncrease.IntValue;
		int randomHealth = GetRandomInt(minHealth, maxHealth);

		int temp	 = L4D_GetPlayerTempHealth(attacker) + randomHealth;

		L4D_SetPlayerTempHealthFloat(attacker, float(temp));

		CPrintToChatAll("%t", "TankDrawResult_IncreaseTempHealth", attackerName, randomHealth);
		PrintHintTextToAll("%t", "TankDrawResult_IncreaseTempHealth_NoColor", attackerName, randomHealth);

		return Plugin_Continue;
	}

	currentChance += chanceTimerBomb;
	if (random <= currentChance)
	{
		CPrintToChatAll("%t", "TankDraw_TimerBomb", attackerName);
		PrintHintTextToAll("%t", "TankDraw_TimerBomb_NoColor", attackerName);
		SetPlayerTimeBomb(attacker, TimerBombSecond.IntValue, TimerBombRadius.FloatValue, TimerBombRangeDamage.IntValue);

		return Plugin_Handled;
	}

	currentChance += chanceNewTank;
	if (random <= currentChance)
	{
		if (!IsValidAliveClient(attacker))
		{
			CPrintToChatAll("%t", "TankDraw_SomeThingWrong");
			PrintHintTextToAll("%t", "TankDraw_SomeThingWrong_NoColor");
			return Plugin_Continue;
		}

		CPrintToChatAll("%t", "TankDraw_NewTank", attackerName);
		PrintHintTextToAll("%t", "TankDraw_NewTank_NoColor", attackerName);

		float fPos[3];
		GetClientAbsOrigin(attacker, fPos);
		TrySpawnTank(fPos, OnSpawnComplete);

		return Plugin_Continue;
	}

	currentChance += chanceReviveAllDead;
	if (random <= currentChance)
	{
		if (!IsValidAliveClient(attacker))
		{
			CPrintToChatAll("%t", "TankDraw_SomeThingWrong");
			PrintHintTextToAll("%t", "TankDraw_SomeThingWrong_NoColor");
			return Plugin_Continue;
		}

		float fPos[3];
		GetClientAbsOrigin(attacker, fPos);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidDeadClient(i))
			{
				L4D_RespawnPlayer(i);
				TeleportEntity(i, fPos, NULL_VECTOR, NULL_VECTOR);
			}
		}

		CPrintToChatAll("%t", "TankDraw_ReviveAllDead", attackerName);
		PrintHintTextToAll("%t", "TankDraw_ReviveAllDead_NoColor", attackerName);
		return Plugin_Continue;
	}

	// limited time world moon gravity
	currentChance += chanceLimitedTimeWorldMoonGravity;
	if (random <= currentChance)
	{
		g_WorldGravity = FindConVar("sv_gravity");
		char default_gravity[16];
		g_WorldGravity.GetDefault(default_gravity, sizeof(default_gravity));
		int default_gravity_int = StringToInt(default_gravity);

		g_WorldGravity.IntValue = WorldMoonGravity.IntValue;

		if (g_WorldGravityTimer)
		{
			delete g_WorldGravityTimer;
		}
		g_WorldGravityTimer = CreateTimer(GetConVarFloat(LimitedTimeWorldMoonGravityTimer), ResetWorldGravity, default_gravity_int);
		CPrintToChatAll("%t", "TankDrawResult_LimitedMoonGravity", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityTimer));
		PrintHintTextToAll("%t", "TankDrawResult_LimitedMoonGravity_NoColor", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityTimer));

		return Plugin_Continue;
	}

	// Limited time moon gravity for drawer
	currentChance += chanceMoonGravityOneLimitedTime;
	if (random <= currentChance)
	{
		SetEntityGravity(attacker, GetConVarFloat(SingleMoonGravity));

		if (g_SingleGravityTimer[attacker])
		{
			delete g_SingleGravityTimer[attacker];
		}
		g_SingleGravityTimer[attacker] = CreateTimer(GetConVarFloat(LimitedTimeWorldMoonGravityOne), ResetSingleGravity, attacker);
		CPrintToChatAll("%t", "TankDrawResult_SingleMoonGravity", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityOne));
		PrintHintTextToAll("%t", "TankDrawResult_SingleMoonGravity_NoColor", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityOne));

		return Plugin_Continue;
	}

	// Toggle world moon gravity
	currentChance += chanceWorldMoonGravityToggle;
	if (random <= currentChance)
	{
		g_WorldGravity = FindConVar("sv_gravity");
		char default_gravity[16];
		g_WorldGravity.GetDefault(default_gravity, sizeof(default_gravity));
		int default_gravity_int = StringToInt(default_gravity);

		if (g_WorldGravity.IntValue == default_gravity_int)
		{
			g_WorldGravity.IntValue = WorldMoonGravity.IntValue;
			CPrintToChatAll("%t", "TankDrawResult_EnableMoonGravity", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableMoonGravity_NoColor", attackerName);
		}
		else {
			g_WorldGravity.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableMoonGravity", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableMoonGravity_NoColor", attackerName);
		}
		return Plugin_Continue;
	}

	// Increase gravity for drawer
	currentChance += chanceIncreaseGravity;
	if (random <= currentChance)
	{
		SetEntityGravity(attacker, GetConVarFloat(IncreasedGravity));
		CPrintToChatAll("%t", "TankDrawResult_IncreaseGravity", attackerName, GetConVarFloat(IncreasedGravity));
		PrintHintTextToAll("%t", "TankDrawResult_IncreaseGravity_NoColor", attackerName, GetConVarFloat(IncreasedGravity));

		return Plugin_Continue;
	}

	currentChance += chanceKillSingleSurvivor;
	if (random <= currentChance)
	{
		ForcePlayerSuicide(attacker);
		CPrintToChatAll("%t", "TankDrawResult_KillSingleSurvivor", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_KillSingleSurvivor_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceKillAllSurvivor;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				ForcePlayerSuicide(i);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_KillAllSurvivors", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_KillAllSurvivors_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceIncreaseHealth;
	if (random <= currentChance)
	{
		// Increase player's health randomly
		int minHealth	 = GetConVarInt(MinHealthIncrease);
		int maxHealth	 = GetConVarInt(MaxHealthIncrease);
		int randomHealth = GetRandomInt(minHealth, maxHealth);
		int health	 = GetClientHealth(attacker) + randomHealth;
		SetEntityHealth(attacker, health);
		CPrintToChatAll("%t", "TankDrawResult_IncreaseHealth", attackerName, randomHealth);
		PrintHintTextToAll("%t", "TankDrawResult_IncreaseHealth_NoColor", attackerName, randomHealth);

		return Plugin_Continue;
	}

	currentChance += chanceInfiniteAmmo;
	if (random <= currentChance)
	{
		// Infinite ammo
		g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_ammo");
		if (g_hInfinitePrimaryAmmo.IntValue == 0)
		{
			g_hInfinitePrimaryAmmo.IntValue = 1;
			CPrintToChatAll("%t", "TankDrawResult_EnableInfiniteAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableInfiniteAmmo_NoColor", attackerName);
		}
		else {
			g_hInfinitePrimaryAmmo.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableInfiniteAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableInfiniteAmmo_NoColor", attackerName);
		}
		return Plugin_Continue;
	}

	currentChance += chanceInfiniteMelee;
	if (random <= currentChance)
	{
		// Infinite melee range
		g_MeleeRange = FindConVar("melee_range");
		char default_range[16];
		g_MeleeRange.GetDefault(default_range, sizeof(default_range));
		int default_range_int = StringToInt(default_range);

		if (g_MeleeRange.IntValue == default_range_int)
		{
			g_MeleeRange.IntValue = GetConVarInt(InfiniteMeeleRange);
			CPrintToChatAll("%t", "TankDrawResult_EnableInfiniteMelee", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableInfiniteMelee_NoColor", attackerName);
		}
		else {
			g_MeleeRange.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableInfiniteMelee", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableInfiniteMelee_NoColor", attackerName);
		}
		return Plugin_Continue;
	}

	currentChance += chanceAverageHealth;
	if (random <= currentChance)
	{
		// Average all survivors' health
		int health	     = 0;
		int numOfAliveClient = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i) && !IsPlayerIncapacitatedAtAll(i))
			{
				health += GetClientHealth(i);
				numOfAliveClient++;
			}
		}

		int averageHealth = RoundToNearest(float(health) / float(numOfAliveClient));
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i) && !IsPlayerIncapacitatedAtAll(i))
			{
				SetEntityHealth(i, averageHealth);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_AverageHealth", attackerName, averageHealth);
		PrintHintTextToAll("%t", "TankDrawResult_AverageHealth_NoColor", attackerName, averageHealth);

		return Plugin_Continue;
	}

	currentChance += chanceDecreaseHealth;
	if (random <= currentChance)
	{
		int minDecrease	 = GetConVarInt(MinHealthDecrease);
		int maxDecrease	 = GetConVarInt(MaxHealthDecrease);
		int randomHealth = GetRandomInt(minDecrease, maxDecrease);
		int health	 = GetClientHealth(attacker);

		if (health > randomHealth)
		{
			SDKHooks_TakeDamage(attacker, attacker, attacker, float(randomHealth), DMG_GENERIC);
			CPrintToChatAll("%t", "TankDrawResult_DecreaseHealth", attackerName, randomHealth);
			PrintHintTextToAll("%t", "TankDrawResult_DecreaseHealth_NoColor", attackerName, randomHealth);
		}
		else
		{
			L4D_SetPlayerTempHealthFloat(attacker, 0.0);
			SDKHooks_TakeDamage(attacker, attacker, attacker, float(health) - 1, DMG_GENERIC);
			CPrintToChatAll("%t", "TankDrawResult_DecreaseHealthNotEnough", attackerName, randomHealth, health - 1);
			PrintHintTextToAll("%t", "TankDrawResult_DecreaseHealthNotEnough_NoColor", attackerName, randomHealth, health - 1);
		}

		return Plugin_Continue;
	}

	currentChance += chanceClearAllSurvivorHealth;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				if (!IsPlayerIncapacitatedAtAll(i))
				{
					L4D_SetPlayerTempHealthFloat(i, 0.0);
					SetEntityHealth(i, 1);
				}
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_ClearAllSurvivorHealth", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_ClearAllSurvivorHealth_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceDisarmAllSurvivor;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				DisarmPlayer(i);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_DisarmAllSurvivors", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_DisarmAllSurvivors_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceDisarmSingleSurvivor;
	if (random <= currentChance)
	{
		DisarmPlayer(attacker);
		CPrintToChatAll("%t", "TankDrawResult_DisarmSingleSurvivor", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_DisarmSingleSurvivor_NoColor", attackerName);

		return Plugin_Continue;
	}
	// This shouldn't happen, but just in case
	CPrintToChatAll("%t", "TankDraw_SomeThingWrong");
	PrintHintTextToAll("%t", "TankDraw_SomeThingWrong_NoColor");
	return Plugin_Continue;
}
