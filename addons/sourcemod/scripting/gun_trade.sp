#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

int g_LastButtons[MAXPLAYERS + 1]
int g_TradePartner[MAXPLAYERS + 1]
float g_TradeTime[MAXPLAYERS + 1]
float g_TradeCooldown[MAXPLAYERS + 1]

public Plugin myinfo =
{
    name = "[L4D2] Gun Trade",
    author = "Yird",
    description = "Allows survivors to trade primary weapons with each other",
    version = "0.1",
    url = "https://github.com/Yi3d"
};

public OnPluginStart() {
    PrintToServer("Gun trade plugin is here")
}
public OnMapStart() {
    for (int i = 1; i <= MaxClients; i++) {
        g_TradeCooldown[i] = 0.0;
        g_TradePartner[i] = 0;
        g_TradeTime[i] = 0.0;
        g_LastButtons[i] = 0;
    }
}

public Action OnPlayerRunCmd(int client, int &buttons) {
    if ((buttons & IN_USE) && !(g_LastButtons[client] & IN_USE)) {
        PrimaryGunTrade(client)
    }
    g_LastButtons[client] = buttons
    return Plugin_Continue
}

public void PrimaryGunTrade(int client) {
    int clientTeam = GetClientTeam(client)
    int target = GetClientAimTarget(client)
    float distance = 40.0
    if (clientTeam != 2)
        return
    if (target < 1 || target > MaxClients || !IsClientInGame(target))
        return
    if (GetClientTeam(target) != 2)
        return
    int weapon1 = GetPlayerWeaponSlot(client, 0)
    int weapon2 = GetPlayerWeaponSlot(target, 0)
    if (weapon1 == -1 || weapon2 == -1)
        return
    float clientPos[3], targetPos[3]
    GetClientAbsOrigin(client, clientPos)
    GetClientAbsOrigin(target, targetPos)
    if (GetVectorDistance(clientPos, targetPos) > distance)
        return
    Handle trace = TR_TraceRayFilterEx(clientPos, targetPos, MASK_SHOT, RayType_EndPoint, TraceFilter, client)
    bool hitWall = TR_DidHit(trace)
    int hitEntity = TR_GetEntityIndex(trace)
    CloseHandle(trace)
    if (hitWall && hitEntity != target)
        return
    // After all that math, we have a valid target!
    char clientName[32], targetName[32]
    GetClientName(client, clientName, sizeof(clientName))
    GetClientName(target, targetName, sizeof(targetName))
    float currentTime = GetGameTime()
    bool isBot = IsFakeClient(target)
    if (currentTime - g_TradeCooldown[client] < 3.0) {
        PrintToChat(client, "\x05[Trade]\x01 Wait 3s before trading again")
        return
    }
    if (currentTime - g_TradeCooldown[target] < 3.0) {
        PrintToChat(client, "\x05[Trade]\x01 Wait 3s before trading again with %s", clientName)
        return
    }
    if (isBot) {
        if (g_TradePartner[client] == target && currentTime - g_TradeTime[client] < 5.0) {
            SwapPrimaryWeapons(client, target)
            g_TradePartner[client] = 0
            g_TradeCooldown[client] = currentTime
            PrintToChat(client, "\x05[Trade]\x01 Traded with \x04%s\x01", targetName)
        } else {
            g_TradePartner[client] = target
            g_TradeTime[client] = currentTime
            PrintToChat(client, "\x05[Trade]\x01 Press +use within 5s to trade primary with \x04%s\x01", targetName)
        }
    }
    if (g_TradePartner[target] == client && !isBot && currentTime - g_TradeTime[target] < 5.0) {
        SwapPrimaryWeapons(client, target)
        g_TradePartner[client] = 0
        g_TradePartner[target] = 0
        g_TradeCooldown[client] = currentTime
        g_TradeCooldown[target] = currentTime
        PrintToChat(client, "\x05[Trade]\x01 Traded with \x04%s\x01", targetName)
        PrintToChat(target, "\x05[Trade]\x01 Traded with \x04%s\x01", clientName)
    } else if (!isBot) {
        g_TradePartner[client] = target
        g_TradeTime[client] = currentTime
        PrintToChat(client, "\x05[Trade]\x01 Send request to \x04%s\x01", targetName)
        PrintToChat(target, "\x05[Trade]\x01 \x04%s\x01 wants to trade primary with you, press +use within 5s", clientName)
    }
}

void SwapPrimaryWeapons(int client1, int client2) {
    int weapon1 = GetPlayerWeaponSlot(client1, 0)
    int weapon2 = GetPlayerWeaponSlot(client2, 0)
    int ammo1 = -1, ammo2 = -1

    if (weapon1 != -1) {
        ammo1 = L4D_GetReserveAmmo(client1, weapon1)
        RemovePlayerItem(client1, weapon1)
    }
    if (weapon2 != -1) {
        ammo2 = L4D_GetReserveAmmo(client2, weapon2)
        RemovePlayerItem(client2, weapon2)
    }
    if (weapon1 != -1) {
        EquipPlayerWeapon(client2, weapon1)
        if (ammo1 != -1)
            L4D_SetReserveAmmo(client2, weapon1, ammo1)
    }
    if (weapon2 != -1) {
        EquipPlayerWeapon(client1, weapon2)
        if (ammo2 != -1)
            L4D_SetReserveAmmo(client1, weapon2, ammo2)
    }
}

public bool TraceFilter(int entity, int contentsMask, int client) {
    return entity != client
}