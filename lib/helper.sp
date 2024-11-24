// Special Infected class definitions
#define Z_SMOKER      1
#define Z_BOOMER      2
#define Z_HUNTER      3
#define Z_SPITTER     4
#define Z_JOCKEY      5
#define Z_CHARGER     6
#define Z_TANK	      8

// Team definitions
#define SURVIVOR_TEAM 2
#define INFECTED_TEAM 3

/**
 * Executes a cheat/admin command for a client by temporarily granting root access
 * and bypassing cheat flags.
 *
 * @param client        Client index to execute the command for
 * @param sCommand      The command to execute
 * @param sArguments    Optional arguments for the command
 */
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

/**
 * Checks if a player is in the incapacitated state (downed but not hanging).
 *
 * @param client    Client index to check
 * @return          True if player is incapacitated, false otherwise
 */
stock bool IsPlayerIncapacitated(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

/**
 * Checks if a player is either incapacitated or hanging from a ledge.
 *
 * @param client    Client index to check
 * @return          True if player is incapacitated or hanging, false otherwise
 */
stock bool IsPlayerIncapacitatedAtAll(int client)
{
	return (IsPlayerIncapacitated(client) || IsHangingFromLedge(client));
}

/**
 * Checks if a player is hanging from a ledge or falling from one.
 *
 * @param client    Client index to check
 * @return          True if player is hanging/falling from ledge, false otherwise
 */
stock bool IsHangingFromLedge(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1) == 1);
}

/**
 * Removes all weapons from a player across all weapon slots (0-4).
 *
 * @param client    Client index to disarm
 */
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

/**
 * Checks if a client index is valid, connected, and in-game.
 *
 * @param client    Client index to validate
 * @return          True if client is valid and in-game, false otherwise
 */
stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

/**
 * Checks if a client is a valid, alive survivor.
 *
 * @param client    Client index to check
 * @return          True if client is a valid alive survivor, false otherwise
 */
stock bool IsValidAliveClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) == SURVIVOR_TEAM));
}

/**
 * Checks if a client is a valid, dead survivor.
 *
 * @param client    Client index to check
 * @return          True if client is a valid dead survivor, false otherwise
 */
stock bool IsValidDeadClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == SURVIVOR_TEAM));
}

/**
 * Checks if a client is a valid survivor.
 *
 * @param client    Client index to check
 * @return          True if client is a valid survivor, false otherwise
 */
stock bool IsValidSurvivor(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && (GetClientTeam(client) == SURVIVOR_TEAM));
}

/**
 * Checks if a client is a Tank special infected.
 * Includes debug logging for validation steps.
 *
 * @param client    Client index to check
 * @return          True if client is a Tank, false otherwise
 */
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

/**
 * Plays a sound to all players in the game.
 *
 * @param sample    Sound file path to play
 */
stock void PlaySoundToAll(const char[] sample)
{
	EmitSoundToAll(sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

/**
 * Callback function type for Tank spawn attempts
 * @param success      Whether the Tank was successfully spawned
 * @param attempts     Number of attempts made
 */
typedef SpawnTankCallback = function void(bool success, int attempts);

/**
 * Attempts to spawn a Tank at the specified position with retry logic and interval.
 *
 * @param pos           Position vector where to spawn the Tank
 * @param callback      Function to call when spawn attempts are complete (can be null)
 * @param retryInterval Time in seconds to wait between retry attempts (default: 0.1)
 * @param maxRetries    Maximum number of spawn attempts (default: 10)
 */
stock void TrySpawnTank(const float pos[3], SpawnTankCallback callback = INVALID_FUNCTION, float retryInterval = 0.5, int maxRetries = 6)
{
	int  attempts  = 1;
	bool IsSuccess = false;

	// First attempt
	IsSuccess      = L4D2_SpawnTank(pos, NULL_VECTOR) > 0;
	if (IsSuccess)
	{
		PrintToServer("Successfully spawned Tank at position: %.1f, %.1f, %.1f", pos[0], pos[1], pos[2]);
		PrintToServer("Successfully spawned Tank at %d attempts", attempts);

		// Call callback if provided
		if (callback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, callback);
			Call_PushCell(true);
			Call_PushCell(attempts);
			Call_Finish();
		}
		return;
	}

	// If first attempt failed, create timer for retry attempts
	if (!IsSuccess && maxRetries > 1)
	{
		DataPack dp = new DataPack();
		dp.WriteFloat(pos[0]);
		dp.WriteFloat(pos[1]);
		dp.WriteFloat(pos[2]);
		dp.WriteFloat(retryInterval);
		dp.WriteCell(attempts + 1);
		dp.WriteCell(maxRetries);
		dp.WriteFunction(callback);

		CreateTimer(retryInterval, Timer_RetrySpawnTank, dp);
		return;
	}

	PrintToServer("Failed to spawn Tank after first attempt");

	// Call callback if provided
	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, callback);
		Call_PushCell(false);
		Call_PushCell(attempts);
		Call_Finish();
	}
}

/**
 * Timer callback for retrying Tank spawn
 */
public Action Timer_RetrySpawnTank(Handle timer, DataPack dp)
{
	dp.Reset();
	float pos[3];
	pos[0]		       = dp.ReadFloat();
	pos[1]		       = dp.ReadFloat();
	pos[2]		       = dp.ReadFloat();
	float	 retryInterval = dp.ReadFloat();
	int	 attempts      = dp.ReadCell();
	int	 maxRetries    = dp.ReadCell();
	Function callback      = dp.ReadFunction();

	bool	 IsSuccess     = L4D2_SpawnTank(pos, NULL_VECTOR) > 0;

	if (IsSuccess)
	{
		PrintToServer("Successfully spawned Tank at position: %.1f, %.1f, %.1f", pos[0], pos[1], pos[2]);
		PrintToServer("Successfully spawned Tank at %d attempts", attempts);

		// Call callback if provided
		if (callback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, callback);
			Call_PushCell(true);
			Call_PushCell(attempts);
			Call_Finish();
		}

		delete dp;
		return Plugin_Stop;
	}

	if (attempts < maxRetries)
	{
		// Schedule next retry
		dp.Reset();
		dp.WriteFloat(pos[0]);
		dp.WriteFloat(pos[1]);
		dp.WriteFloat(pos[2]);
		dp.WriteFloat(retryInterval);
		dp.WriteCell(attempts + 1);
		dp.WriteCell(maxRetries);
		dp.WriteFunction(callback);

		CreateTimer(retryInterval, Timer_RetrySpawnTank, dp);
		return Plugin_Continue;
	}

	PrintToServer("Failed to spawn Tank after %d attempts", maxRetries);

	// Call callback if provided
	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, callback);
		Call_PushCell(false);
		Call_PushCell(attempts);
		Call_Finish();
	}

	delete dp;
	return Plugin_Stop;
}

/**
 * Returns the username associated with the given entity index.
 * @note This function should only used for dev purposes.
 *
 * @param entity      Entity index to retrieve the username for
 * @return           Username associated with the given entity index
 */
stock char[] GetUserNameFromIndex(int entity)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(entity, name, sizeof(name));
	return name;
}
