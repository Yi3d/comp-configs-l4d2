#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

ConVar tv_enabled;
bool confogl_loaded = false;

public Plugin myinfo = 
{
    name = "SourceTV AutoDemo",
    author = "Yird",
    description = "Automatically records a demo once round starts in confgol",
    version = "1.0",
    url = "https://github.com/Yi3d"
};

public void OnPluginStart()
{
    tv_enabled = FindConVar("tv_enable");
    confogl_loaded = LibraryExists("confogl");
    HookEvent("player_left_start_area", Event_SurvivorLeftStartArea, EventHookMode_Post);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

bool IsSourceTvEnabled()
{
    if (tv_enabled == INVALID_HANDLE)
        return false;
    return GetConVarBool(tv_enabled);
}

void GetCurrentMapAndTime(char[] buffer, int maxlen)
{
    // Return map and date as a string for demo naming
    char mapName[64];
    char timeStr[32];
    char result[128];
    GetCurrentMap(mapName, sizeof(mapName));
    FormatTime(timeStr, sizeof(timeStr), "%Y-%m-%d_%H-%M-%S");
    Format(result, sizeof(result), "%s_%s", mapName, timeStr);
    strcopy(buffer, maxlen, result);
}

public Action Event_SurvivorLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsSourceTvEnabled() || !confogl_loaded)
    {
        PrintToServer("source tv not enabled or confogl not loaded");
        return Plugin_Continue;
    }
    char demoName[128];
    GetCurrentMapAndTime(demoName, sizeof(demoName));
    ServerCommand("tv_record demos/%s", demoName);
    return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!IsSourceTvEnabled() || !confogl_loaded)
    {
        PrintToServer("source tv not enabled or confogl not loaded");
        return Plugin_Continue;
    }
    CreateTimer(14.0, Timer_StopTvRecording);
    return Plugin_Continue;
}

public Action Timer_StopTvRecording(Handle timer, any data)
{
    ServerCommand("tv_stoprecord");
    return Plugin_Stop;
}

public void OnMapStart()
{
    ServerCommand("tv_stoprecord");
}