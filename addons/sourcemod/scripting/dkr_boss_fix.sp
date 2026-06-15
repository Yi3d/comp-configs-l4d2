#include <sourcemod>
#include <left4dhooks>
#include <l4d2util_rounds>
#define L4D2UTIL_STOCKS_ONLY

bool bossPercentAvailable;

public Plugin myinfo =
{
    name = "DKR Boss Fix",
    author = "Yird",
    description = "Workaround for disabling DKR boss scripts",
    version = "1.0",
    url = "https://github.com/Yi3d"
}

public void OnAllPluginsLoaded()
{
    bossPercentAvailable = LibraryExists("l4d_boss_percent");
}
public void OnPluginStart()
{
    HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
}

bool IsDarkCarniRemix()
{
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    return StrContains(mapName, "dkr_", false) != -1;
}
public Action Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!bossPercentAvailable)
        return Plugin_Continue;
    if (!IsDarkCarniRemix() || InSecondHalfOfRound())
        return Plugin_Continue;
    CreateTimer(1.0, Timer_AnnounceBosses, _, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

Action Timer_AnnounceBosses(Handle timer)
{
    /* Tank
	float fTankFlow = L4D2Direct_GetVSTankFlowPercent(0);
	if (fTankFlow > 0.0)
	{
		int iTankPct = RoundToNearest(fTankFlow * 100.0);
		char sTankMsg[64];
		FormatEx(sTankMsg, sizeof(sTankMsg), "The Tank will spawn here. (%d%% Map Distance)", iTankPct);
		FireSayEvent(sTankMsg);
	}
    */

	// Witch
	float fWitchFlow = L4D2Direct_GetVSWitchFlowPercent(0);
	if (fWitchFlow > 0.0)
	{
		int iWitchPct = RoundToNearest(fWitchFlow * 100.0);
		char sWitchMsg[64];
		FormatEx(sWitchMsg, sizeof(sWitchMsg), "The Witch will spawn. (%d%% Map Distance)", iWitchPct);
		FireSayEvent(sWitchMsg);
	}
	return Plugin_Stop;
}

void FireSayEvent(const char[] text)
{
	Event hEvent = CreateEvent("player_say");
	if (hEvent == null)
        return;
	hEvent.SetInt("userid", 0);
	hEvent.SetString("text", text);
	hEvent.Fire();
}


