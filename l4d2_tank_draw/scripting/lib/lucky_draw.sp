stock Action LuckyDraw(int victim, int attacker)
{
	if (g_iTotalChance == 0)
	{
		DebugPrint("所有概率总和为0，跳过抽奖 / total change equals to 0, do not draw");
		return Plugin_Continue;
	}

	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));

	int random = GetRandomInt(1, g_iTotalChance);
	DebugPrint("total chance: %d, random: %d", g_iTotalChance, random);

	int currentChance = 0;

	// no prize
	currentChance += g_iChanceNoPrize;
	if (random <= currentChance)
	{
		CPrintToChatAll("%t", "TankDrawResult_NoPrize", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_NoPrize_NoColor", attackerName);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceDrugAllSurvivor;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				SetDrug(i, g_iDrugAllSurvivorDuration);
			}
		}

		CPrintToChatAll("%t", "TankDrawResult_DrugAll", attackerName, g_iDrugAllSurvivorDuration);
		PrintHintTextToAll("%t", "TankDrawResult_DrugAll_NoColor", attackerName, g_iDrugAllSurvivorDuration);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceDrugLuckySurvivor;
	if (random <= currentChance)
	{
		if (g_hDrugTimers[attacker] != null)
		{
			SetDrug(attacker, g_iDrugLuckySurvivorDuration);
			CPrintToChatAll("%t", "TankDrawResult_DrugExist", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DrugExist_NoColor", attackerName);
		}
		else {
			SetDrug(attacker, g_iDrugLuckySurvivorDuration);
			CPrintToChatAll("%t", "TankDrawResult_DrugLuckySurvivor", attackerName, g_iDrugLuckySurvivorDuration);
			PrintHintTextToAll("%t", "TankDrawResult_DrugLuckySurvivor_NoColor", attackerName, g_iDrugLuckySurvivorDuration);
		}

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceInfinitePrimaryAmmo;
	if (random <= currentChance)
	{
		// Infinite ammo
		g_hInfiniteAmmo	       = FindConVar("sv_infinite_ammo");
		g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_primary_ammo");
		if (g_hInfiniteAmmo.IntValue == 1)
		{
			g_hInfiniteAmmo.RestoreDefault();
		}
		if (g_hInfinitePrimaryAmmo.IntValue == 0)
		{
			g_hInfinitePrimaryAmmo.IntValue = 1;
			CPrintToChatAll("%t", "TankDrawResult_EnableInfinitePrimaryAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableInfinitePrimaryAmmo_NoColor", attackerName);
		}
		else {
			g_hInfinitePrimaryAmmo.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableInfinitePrimaryAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableInfinitePrimaryAmmo_NoColor", attackerName);
		}

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceResetAllSurvivorHealth;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				CheatCommand(i, "give", "health");
				L4D_SetTempHealth(i, 0.0);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_ResetAllSurvivorHealth", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_ResetAllSurvivorHealth_NoColor", attackerName);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceFreezeBomb;
	if (random <= currentChance)
	{
		SetPlayerFreezeBomb(attacker, g_iFreezeBombCountDown, g_fFreezeBombRadius, g_iFreezeBombDuration);
		CheatCommand(attacker, "give", "adrenaline");
		CPrintToChatAll("%t", "TankDraw_FreezeBomb", attackerName);
		PrintHintTextToAll("%t", "TankDraw_FreezeBomb_NoColor", attackerName);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceDisableGlow;
	if (random <= currentChance)
	{
		if (g_iGlowDisabled == 0)
		{
			g_iGlowDisabled = 1;
			CPrintToChatAll("%t", "TankDraw_DisableGlow", attackerName);
			PrintHintTextToAll("%t", "TankDraw_DisableGlow_NoColor", attackerName);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidAliveClient(i))
				{
					SetEntProp(i, Prop_Send, "m_bSurvivorGlowEnabled", 0);
				}
			}
		}
		else {
			g_iGlowDisabled = 0;
			CPrintToChatAll("%t", "TankDraw_RestoreGlow", attackerName);
			PrintHintTextToAll("%t", "TankDraw_RestoreGlow_NoColor", attackerName);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidAliveClient(i))
				{
					SetEntProp(i, Prop_Send, "m_bSurvivorGlowEnabled", 1);
				}
			}
		}

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceTimerBomb;
	if (random <= currentChance)
	{
		if (g_hTimeBombTimer[attacker] != null)
		{
			delete g_hTimeBombTimer[attacker];
			g_iTimeBombTicks[attacker] = 0;

			// Reset player color
			SetEntityRenderColor(attacker, 255, 255, 255, 255);

			CPrintToChatAll("%t", "TankDraw_Cancel_TimerBomb", attackerName);
			PrintHintTextToAll("%t", "TankDraw_Cancel_TimerBomb_NoColor", attackerName);
		}
		else {
			CPrintToChatAll("%t", "TankDraw_TimerBomb", attackerName);
			PrintHintTextToAll("%t", "TankDraw_TimerBomb_NoColor", attackerName);
			SetPlayerTimeBomb(attacker, g_iTimerBombSecond, g_fTimerBombRadius, g_iTimerBombRangeDamage);
			CheatCommand(attacker, "give", "adrenaline");
		}

		Tank_ZedTime();
		return Plugin_Handled;
	}

	currentChance += g_iChanceNewTank;
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

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceNewWitch;
	if (random <= currentChance)
	{
		if (!IsValidAliveClient(attacker))
		{
			CPrintToChatAll("%t", "TankDraw_SomeThingWrong");
			PrintHintTextToAll("%t", "TankDraw_SomeThingWrong_NoColor");
			return Plugin_Continue;
		}

		CPrintToChatAll("%t", "TankDraw_NewWitch", attackerName);
		PrintHintTextToAll("%t", "TankDraw_NewWitch_NoColor", attackerName);

		float fPos[3];
		GetClientAbsOrigin(attacker, fPos);
		L4D2_SpawnWitch(fPos, NULL_VECTOR);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceReviveAllDead;
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

		Tank_ZedTime();
		return Plugin_Continue;
	}

	// limited time world moon gravity
	currentChance += g_iChanceLimitedTimeWorldMoonGravity;
	if (random <= currentChance)
	{
		g_hWorldGravity = FindConVar("sv_gravity");
		char default_gravity[16];
		g_hWorldGravity.GetDefault(default_gravity, sizeof(default_gravity));
		int default_gravity_int	 = StringToInt(default_gravity);

		g_hWorldGravity.IntValue = g_iWorldMoonGravity;

		if (g_WorldGravityTimer != null)
		{
			delete g_WorldGravityTimer;
		}
		g_WorldGravityTimer = CreateTimer(float(g_iLimitedTimeWorldMoonGravityTimer), ResetWorldGravity, default_gravity_int, NO_REPEAT_TIMER);
		CPrintToChatAll("%t", "TankDrawResult_LimitedMoonGravity", attackerName, g_iLimitedTimeWorldMoonGravityTimer);
		PrintHintTextToAll("%t", "TankDrawResult_LimitedMoonGravity_NoColor", attackerName, g_iLimitedTimeWorldMoonGravityTimer);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	// Limited time moon gravity for drawer
	currentChance += g_iChanceMoonGravityOneLimitedTime;
	if (random <= currentChance)
	{
		SetEntityGravity(attacker, g_fSingleMoonGravity);

		if (g_SingleGravityTimer[attacker] != null)
		{
			delete g_SingleGravityTimer[attacker];
		}
		g_SingleGravityTimer[attacker] = CreateTimer(float(g_iLimitedTimeWorldMoonGravityOne), ResetSingleGravity, attacker, NO_REPEAT_TIMER);
		CPrintToChatAll("%t", "TankDrawResult_SingleMoonGravity", attackerName, g_iLimitedTimeWorldMoonGravityOne);
		PrintHintTextToAll("%t", "TankDrawResult_SingleMoonGravity_NoColor", attackerName, g_iLimitedTimeWorldMoonGravityOne);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	// Toggle world moon gravity
	currentChance += g_iChanceWorldMoonGravityToggle;
	if (random <= currentChance)
	{
		g_hWorldGravity = FindConVar("sv_gravity");
		char default_gravity[16];
		g_hWorldGravity.GetDefault(default_gravity, sizeof(default_gravity));
		int default_gravity_int = StringToInt(default_gravity);

		if (g_hWorldGravity.IntValue == default_gravity_int)
		{
			g_hWorldGravity.IntValue = g_iWorldMoonGravity;
			CPrintToChatAll("%t", "TankDrawResult_EnableMoonGravity", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableMoonGravity_NoColor", attackerName);
		}
		else {
			g_hWorldGravity.RestoreDefault();
			// before timer ends, if draw this prize, should clear timer
			if (g_WorldGravityTimer != null)
			{
				delete g_WorldGravityTimer;
			}
			CPrintToChatAll("%t", "TankDrawResult_DisableMoonGravity", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableMoonGravity_NoColor", attackerName);
		}

		Tank_ZedTime();
		return Plugin_Continue;
	}

	// Increase gravity for drawer
	currentChance += g_iChanceIncreaseGravity;
	if (random <= currentChance)
	{
		SetEntityGravity(attacker, g_fIncreasedGravity);
		CPrintToChatAll("%t", "TankDrawResult_IncreaseGravity", attackerName, g_fIncreasedGravity);
		PrintHintTextToAll("%t", "TankDrawResult_IncreaseGravity_NoColor", attackerName, g_fIncreasedGravity);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceKillSingleSurvivor;
	if (random <= currentChance)
	{
		ForcePlayerSuicide(attacker);
		CPrintToChatAll("%t", "TankDrawResult_KillSingleSurvivor", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_KillSingleSurvivor_NoColor", attackerName);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceKillAllSurvivor;
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

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceIncreaseHealth;
	if (random <= currentChance)
	{
		// Increase player's health randomly
		int randomHealth = GetRandomInt(g_iMinHealthIncrease, g_iMaxHealthIncrease);
		int health	 = GetClientHealth(attacker) + randomHealth;
		SetEntityHealth(attacker, health);
		CPrintToChatAll("%t", "TankDrawResult_IncreaseHealth", attackerName, randomHealth);
		PrintHintTextToAll("%t", "TankDrawResult_IncreaseHealth_NoColor", attackerName, randomHealth);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceInfiniteAmmo;
	if (random <= currentChance)
	{
		// Infinite ammo
		g_hInfiniteAmmo	       = FindConVar("sv_infinite_ammo");
		g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_primary_ammo");
		if (g_hInfinitePrimaryAmmo.IntValue == 1)
		{
			g_hInfinitePrimaryAmmo.RestoreDefault();
		}
		if (g_hInfiniteAmmo.IntValue == 0)
		{
			g_hInfiniteAmmo.IntValue = 1;
			CPrintToChatAll("%t", "TankDrawResult_EnableInfiniteAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableInfiniteAmmo_NoColor", attackerName);
		}
		else {
			g_hInfiniteAmmo.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableInfiniteAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableInfiniteAmmo_NoColor", attackerName);
		}

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceInfiniteMelee;
	if (random <= currentChance)
	{
		// Infinite melee range
		g_hMeleeRange = FindConVar("melee_range");
		char default_range[16];
		g_hMeleeRange.GetDefault(default_range, sizeof(default_range));
		int default_range_int = StringToInt(default_range);

		if (g_hMeleeRange.IntValue == default_range_int)
		{
			g_hMeleeRange.IntValue = g_iInfiniteMeeleRange;
			CPrintToChatAll("%t", "TankDrawResult_EnableInfiniteMelee", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableInfiniteMelee_NoColor", attackerName);
		}
		else {
			g_hMeleeRange.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableInfiniteMelee", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableInfiniteMelee_NoColor", attackerName);
		}

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceAverageHealth;
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
				L4D_SetTempHealth(i, 0.0);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_AverageHealth", attackerName, averageHealth);
		PrintHintTextToAll("%t", "TankDrawResult_AverageHealth_NoColor", attackerName, averageHealth);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceDecreaseHealth;
	if (random <= currentChance)
	{
		int randomHealth = GetRandomInt(g_iMinHealthDecrease, g_iMaxHealthDecrease);
		int health	 = GetClientHealth(attacker);

		if (health > randomHealth)
		{
			SDKHooks_TakeDamage(attacker, attacker, attacker, float(randomHealth), DMG_GENERIC);
			CPrintToChatAll("%t", "TankDrawResult_DecreaseHealth", attackerName, randomHealth);
			PrintHintTextToAll("%t", "TankDrawResult_DecreaseHealth_NoColor", attackerName, randomHealth);
		}
		else
		{
			L4D_SetTempHealth(attacker, 0.0);
			SDKHooks_TakeDamage(attacker, attacker, attacker, float(health) - 1, DMG_GENERIC);
			CPrintToChatAll("%t", "TankDrawResult_DecreaseHealthNotEnough", attackerName, randomHealth, health - 1);
			PrintHintTextToAll("%t", "TankDrawResult_DecreaseHealthNotEnough_NoColor", attackerName, randomHealth, health - 1);
		}

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceClearAllSurvivorHealth;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				if (!IsPlayerIncapacitatedAtAll(i))
				{
					L4D_SetTempHealth(i, 0.0);
					SetEntityHealth(i, 1);
				}
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_ClearAllSurvivorHealth", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_ClearAllSurvivorHealth_NoColor", attackerName);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceDisarmAllSurvivor;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				L4D_RemoveAllWeapons(i);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_DisarmAllSurvivors", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_DisarmAllSurvivors_NoColor", attackerName);

		Tank_ZedTime();
		return Plugin_Continue;
	}

	currentChance += g_iChanceDisarmSingleSurvivor;
	if (random <= currentChance)
	{
		L4D_RemoveAllWeapons(attacker);
		CPrintToChatAll("%t", "TankDrawResult_DisarmSingleSurvivor", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_DisarmSingleSurvivor_NoColor", attackerName);

		Tank_ZedTime();
		return Plugin_Continue;
	}
	// This shouldn't happen, but just in case
	CPrintToChatAll("%t", "TankDraw_SomeThingWrong");
	PrintHintTextToAll("%t", "TankDraw_SomeThingWrong_NoColor");

	Tank_ZedTime();
	return Plugin_Continue;
}
