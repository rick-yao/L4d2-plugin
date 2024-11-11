#define Z_SMOKER      1
#define Z_BOOMER      2
#define Z_HUNTER      3
#define Z_SPITTER     4
#define Z_JOCKEY      5
#define Z_CHARGER     6
#define Z_TANK	      8

#define SURVIVOR_TEAM 2
#define INFECTED_TEAM 3

stock void CheatCommand(int client, const char[] sCommand, const char[] sArguments = "")
{
	static int iFlagBits, iCmdFlags;
	iFlagBits = GetUserFlagBits(client);
	iCmdFlags = GetCommandFlags(sCommand);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(sCommand, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCommand, sArguments);
	SetUserFlagBits(client, iFlagBits);
	SetCommandFlags(sCommand, iCmdFlags);
}

stock bool IsPlayerIncapacitated(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

stock bool IsPlayerIncapacitatedAtAll(int client)
{
	return (IsPlayerIncapacitated(client) || IsHangingFromLedge(client));
}

stock bool IsHangingFromLedge(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1) == 1);
}

stock void DisarmPlayer(int client)
{
	for (int slot = 0; slot <= 4; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEntity(weapon);
		}
	}
}

stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

stock bool IsValidAliveClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) == SURVIVOR_TEAM));
}

stock bool IsValidDeadClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == SURVIVOR_TEAM));
}

stock bool IsTank(int client)
{
	// Check if the client is valid and in-game
	if (!IsValidClient(client))
	{
		PrintToServer("IsTank: Client %d is not valid", client);
		return false;
	}

	// Check if the client is on the infected team
	if (GetClientTeam(client) != INFECTED_TEAM)	   // 3 is typically the infected team in L4D2
	{
		PrintToServer("IsTank: Client %d is not on the infected team (Team: %d)", client, GetClientTeam(client));
		return false;
	}
	if (!HasEntProp(client, Prop_Send, "m_zombieClass"))
	{
		return false;
	}

	PrintToServer("IsTank: Client %d passed all preliminary checks", client);
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
}

stock void PlaySoundToAll(const char[] sample)
{
	EmitSoundToAll(sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

stock bool TrySpawnTank(const float pos[3], int maxRetries = 3)
{
	int  attempts  = 1;
	bool IsSuccess = false;

	while (attempts <= maxRetries && !IsSuccess)
	{
		IsSuccess = L4D2_SpawnTank(pos, NULL_VECTOR) > 0;

		if (IsSuccess)
		{
			PrintToServer("Successfully spawned Tank at position: %.1f, %.1f, %.1f", pos[0], pos[1], pos[2]);
			PrintToServer("Successfully spawned Tank at %d attempts", attempts);
			return true;
		}

		attempts++;
	}

	PrintToServer("Failed to spawn Tank after %d attempts", maxRetries);
	return false;
}