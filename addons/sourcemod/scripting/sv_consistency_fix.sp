#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

bool
	g_bIsEventHook = false;

ConVar
	g_hCvarServerMessageToggle = null,
	g_hCvarServerWelcomeMessage = null,
	g_hCvarConsistencyCheckCasters = null;
// keep track of who is caster
ArrayList g_CasterList;


public Plugin myinfo =
{
	name = "sv_consistency fixes",
	author = "step, Sir, A1m`",
	description = "Fixes multiple sv_consistency issues.",
	version = "1.4.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
};

public void OnPluginStart()
{
	if (!FileExists("whitelist.cfg")) {
		SetFailState("Couldn't find whitelist.cfg");
	}
	
	g_hCvarServerMessageToggle = CreateConVar( \
		"svctyfix_message_enable", \
		"1.0", \
		"Enable print message in console when player join.", \
		_, true, 0.0, true, 1.0 \
	);
	
	g_hCvarServerWelcomeMessage = CreateConVar( \
		"svctyfix_welcome_message", \
		"a SoundM Protected Server", \
		"Message to show to Players in console" \
	);
	
	ConVar hConsistencyCheckInterval = CreateConVar( \
		"cl_consistencycheck_interval", \
		"180.0", \
		"Perform a consistency check after this amount of time (seconds) has passed since the last.", \
		FCVAR_REPLICATED \
	);

	g_hCvarConsistencyCheckCasters = CreateConVar( \
		"cl_consistencycheck_casters", \
		"0.0", \
		"Perform a consistency on players marked as !cast, not recommended since it might break their addons.", \
		FCVAR_REPLICATED, true, 0.0, true, 1.0 \
	);
	
	hConsistencyCheckInterval.SetInt(999999);
	
	ToggleMessage();
	g_hCvarServerMessageToggle.AddChangeHook(Cvar_Changed);
	
	RegAdminCmd("sm_consistencycheck", Cmd_ConsistencyCheck, ADMFLAG_RCON, "Performs a consistency check on all players.");
	AddCommandListener(OnCastCmd, "sm_cast");
	
	LoadTranslations("common.phrases"); // Load translations (for targeting player)
}

// bad fix since the foward doesn't work
// get the client of whoever calls !cast and put them in the caster arraylist
Action OnCastCmd(int client, const char[] command, int args)
{
	if (client > 0)
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("%s registered as caster", name);
		g_CasterList.Push(client);
	}
	return Plugin_Continue;
}


void ToggleMessage()
{
	if (g_hCvarServerMessageToggle.BoolValue) {
		if (!g_bIsEventHook) {
			HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Post);
			g_bIsEventHook = true;
		}

		return;
	}

	if (g_bIsEventHook) {
		UnhookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Post);
		g_bIsEventHook = false;
	}
}

void Cvar_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ToggleMessage();
}

// Exclude casters from checks
public void OnClientConnected(int iClient)
{
	PrintToServer("DEBUG DEBUG OnClientConnected!!!!!");
	if (!g_hCvarConsistencyCheckCasters.BoolValue) {
		if (g_CasterList.FindValue(iClient) != -1) {
			PrintToServer("DEBUG DEBUG not checking consistency for caster %N (%d) !!!!!", iClient, iClient);
			return;
		}
		ClientCommand(iClient, "cl_consistencycheck");
	} else {
		PrintToServer("DEBUG DEBUG we are checking consistency for casters !!!!!");
		ClientCommand(iClient, "cl_consistencycheck");
	}
}

void Event_PlayerConnectFull(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iUserId = hEvent.GetInt("userid");
	CreateTimer(0.2, PrintWhitelist, iUserId, TIMER_FLAG_NO_MAPCHANGE);
}

Action PrintWhitelist(Handle hTimer, any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (iClient > 0) {
		char sMessage[128];
		GetConVarString(g_hCvarServerWelcomeMessage, sMessage, sizeof(sMessage));

		PrintToConsole(iClient, " ");
		PrintToConsole(iClient, " ");
		PrintToConsole(iClient, "// -------------------------------- \\");
		PrintToConsole(iClient, "/| --> Welcome to %s <--", sMessage);
		PrintToConsole(iClient, "|");
		PrintToConsole(iClient, "| Your Sound Files have been checked.");
		PrintToConsole(iClient, "| Don't be a filthy Cheater.");
		PrintToConsole(iClient, "| Enjoy your Stay, or don't.");
		PrintToConsole(iClient, "|");
		PrintToConsole(iClient, "/| --> Welcome to %s <--", sMessage);
		PrintToConsole(iClient, "// -------------------------------- \\");
		PrintToConsole(iClient, " ");
		PrintToConsole(iClient, " ");
	}

	return Plugin_Stop;
}

Action Cmd_ConsistencyCheck(int iClient, int iArgs)
{
	if (iArgs < 1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i)) {
				continue;
			}
	
			ClientCommand(i, "cl_consistencycheck");
		}
		
		ReplyToCommand(iClient, "Started checking the consistency of files for all players!");
		return Plugin_Handled;
	}

	char sArg1[MAX_NAME_LENGTH];
	GetCmdArg(1, sArg1, sizeof(sArg1));

	// Try and find a matching player
	int iTarget = FindTarget(iClient, sArg1, true);
	if (iTarget == -1) {
		return Plugin_Handled;
	}
	
	ClientCommand(iTarget, "cl_consistencycheck");

	ReplyToCommand(iClient, "Started checking the consistency of files for the player %N (%d)", iTarget, iTarget);
	
	return Plugin_Handled;
}
