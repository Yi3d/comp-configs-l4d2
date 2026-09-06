#include <sourcemod>
#include <sdktools>
#include <nativevotes>

Menu addonMapMenu = null
char campaignVoteTitle[128]
char campaignVoteLevel[64]

public Plugin myinfo =
{
    name = "[L4D2] Addon Campaign Selector",
    author = "Yird",
    description = "Creates a command to easily select any custom campaigns",
    version = "1.0",
    url = "https://github.com/Yi3d"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_addonmap", Command_AddonMap);
}
public void OnMapStart()
{
    CreateExcludeList()
    GetMissionMaps()
    RemoveInvalidMaps()
    addonMapMenu = BuildAddonMapMenu()
}
public void OnMapEnd()
{
    delete addonMapMenu
}

void CreateExcludeList()
{
    char excludeTxt[PLATFORM_MAX_PATH]
    BuildPath(Path_SM, excludeTxt, sizeof(excludeTxt), "data/exclude_map_list.txt")
    bool exists = FileExists(excludeTxt)
    if (exists)
        return
    File excludeFile = OpenFile(excludeTxt, "w")
    if (excludeFile != null)
    {
        excludeFile.WriteLine("c1m1_hotel")
        excludeFile.WriteLine("c2m1_highway")
        excludeFile.WriteLine("c3m1_plankcountry")
        excludeFile.WriteLine("c4m1_milltown_a")
        excludeFile.WriteLine("c5m1_waterfront")
        excludeFile.WriteLine("c6m1_riverbank")
        excludeFile.WriteLine("c7m1_docks")
        excludeFile.WriteLine("c8m1_apartment")
        excludeFile.WriteLine("c9m1_alleys")
        excludeFile.WriteLine("c10m1_caves")
        excludeFile.WriteLine("c11m1_greenhouse")
        excludeFile.WriteLine("c12m1_hilltop")
        excludeFile.WriteLine("c13m1_alpinecreek")
        excludeFile.WriteLine("c14m1_junkyard")
        CloseHandle(excludeFile)
    }
}

bool IsMapExcluded(const char[] target)
{
    char excludeTxt[PLATFORM_MAX_PATH]
    BuildPath(Path_SM, excludeTxt, sizeof(excludeTxt), "data/exclude_map_list.txt")
    File excludeFile = OpenFile(excludeTxt, "rt")
    if (excludeFile == null)
        return false
    char buffer[64]
    bool found = false

    while (!excludeFile.EndOfFile() && excludeFile.ReadLine(buffer, sizeof(buffer)))
    {
        TrimString(buffer)
        if (StrContains(buffer, target, false) != -1)
        {
            found = true
            break
        }
    }
    CloseHandle(excludeFile)
    return found;
}

void GetMissionMaps()
{
    DirectoryListing missionDir = OpenDirectory("missions", true, NULL_STRING);
    if (missionDir == null)
        return
    char fileName[256]
    char fullPath[256]
    FileType type
    char campaignTxT[PLATFORM_MAX_PATH]
    BuildPath(Path_SM, campaignTxT, sizeof(campaignTxT), "data/campaign_list.txt")
    bool exists = FileExists(campaignTxT);
    
    // Create file with headers if it doesn't exist
    if (!exists)
    {
        File initFile = OpenFile(campaignTxT, "w")
        if (initFile != null)
        {
            initFile.WriteLine("// This file stores a list of all campaigns so it isn't rebuilt");
            initFile.WriteLine("// Any levels that aren't valid will be removed on check");
            CloseHandle(initFile)
        }
    }
    
    // Now open in append mode to add new campaigns
    File campaignFile = OpenFile(campaignTxT, "a")
    while (missionDir.GetNext(fileName, sizeof(fileName), type))
    {
        if (type != FileType_File)
            continue
        Format(fullPath, sizeof(fullPath), "missions/%s", fileName)
        KeyValues kv = new KeyValues("missions")
        if (!kv.ImportFromFile(fullPath))
        {
            delete kv
            continue
        }

        // Have to do this a bit earlier because of nesting
        char campaignTitle[64]
        kv.GetString("DisplayTitle", campaignTitle, sizeof(campaignTitle))

        if (!kv.JumpToKey("modes") || !kv.JumpToKey("versus"))
        {
            delete kv
            continue
        }
        
        // So hopefully we have a campaign now, if so, we'll write the campaign name and first level to a file in addons/sourcemod/data/campaign_list.txt
        // Formated like Dead Center|c1m1_hotel
        int level = 1;
        for (;;)
        {
            char campaignLevel[64]
            char key[8]
            IntToString(level, key, sizeof(key))
            if (!kv.JumpToKey(key))
                break
            kv.GetString("Map", campaignLevel, sizeof(campaignLevel))
            if (!StrEqual(campaignLevel, ""))
            {
                // Let's make sure it isn't on the exclusion list and isn't already in the file
                bool isExcluded = IsMapExcluded(campaignLevel)
                if (isExcluded)
                    continue
                
                // Check if map already exists by opening in read mode
                File readFile = OpenFile(campaignTxT, "r")
                bool alreadyExists = false
                if (readFile != null)
                {
                    char buffer[128]
                    while (!readFile.EndOfFile() && readFile.ReadLine(buffer, sizeof(buffer)))
                    {
                        TrimString(buffer)
                        if (StrContains(buffer, campaignLevel, false) != -1)
                        {
                            alreadyExists = true
                            break
                        }
                    }
                    CloseHandle(readFile)
                }
                if (alreadyExists)
                    continue
                char line[256]
                Format(line, sizeof(line), "%s|%s", campaignTitle, campaignLevel)
                campaignFile.WriteLine(line)
            }
        }
        delete kv
    }
    if (campaignFile != null)
        CloseHandle(campaignFile)
}

void RemoveInvalidMaps()
{
    char campaignTxT[PLATFORM_MAX_PATH]
    BuildPath(Path_SM, campaignTxT, sizeof(campaignTxT), "data/campaign_list.txt")
    bool exists = FileExists(campaignTxT);
    if (!exists)
        return;

    File campaignFile = OpenFile(campaignTxT, "rt")
    if (campaignFile == null)
        return;

    const int MAX_LINES = 512;
    char validLines[MAX_LINES][256];
    int validCount = 0;

    char buffer[256];
    while (!campaignFile.EndOfFile() && campaignFile.ReadLine(buffer, sizeof(buffer)))
    {
        TrimString(buffer);
        if (buffer[0] == '\0')
            continue;

        int pipe = StrContains(buffer, "|");
        if (pipe == -1)
            continue;

        char mapName[128];
        strcopy(mapName, sizeof(mapName), buffer[pipe + 1]);
        TrimString(mapName);

        bool validCampaign = IsMapValid(mapName);
        if (validCampaign)
        {
            if (validCount < MAX_LINES)
                strcopy(validLines[validCount++], sizeof(validLines[]), buffer);
        }
    }
    CloseHandle(campaignFile);

    // Re-open file for writing and overwrite with only valid lines
    File outFile = OpenFile(campaignTxT, "w")
    if (outFile == null)
        return;
    for (int i = 0; i < validCount; i++)
    {
        outFile.WriteLine(validLines[i]);
    }
    CloseHandle(outFile);
}

Menu BuildAddonMapMenu()
{
    char campaignTxT[PLATFORM_MAX_PATH]
    BuildPath(Path_SM, campaignTxT, sizeof(campaignTxT), "data/campaign_list.txt")
    File campaignFile = OpenFile(campaignTxT, "r")
    if (campaignFile == null)
        return null
    
    Menu menu = new Menu(Menu_AddonMap)
    char buffer[256]
    char campaignTitle[128]
    char campaignLevel[64]
    while (!campaignFile.EndOfFile() && campaignFile.ReadLine(buffer, sizeof(buffer)))
    {
        TrimString(buffer)
        int pipe = StrContains(buffer, "|");
        SplitString(buffer, "|", campaignTitle, sizeof(campaignTitle))
        strcopy(campaignLevel, sizeof(campaignLevel), buffer[pipe + 1]);
        if (!IsMapValid(campaignLevel))
            continue
        menu.AddItem(campaignLevel, campaignTitle)
    }
    CloseHandle(campaignFile)
    menu.SetTitle("Select Custom Campaign")
    return menu
}

public int Menu_AddonMap(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        menu.GetItem(param2, campaignVoteLevel, sizeof(campaignVoteLevel), _, campaignVoteTitle, sizeof(campaignVoteTitle))
        NativeVote campaignVote = new NativeVote(Vote_AddonMap, NativeVotesType_ChgCampaign)
        NativeVotes_SetInitiator(campaignVote, param1)
        NativeVotes_SetDetails(campaignVote, campaignVoteTitle)
        NativeVotes_DisplayToAll(campaignVote, 15)
    }

    return 0;
}

public int Vote_AddonMap(NativeVote vote, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_VoteEnd)
    {
        if (param1 == NATIVEVOTES_VOTE_YES)
        {
            NativeVotes_DisplayPass(vote, campaignVoteTitle)
            CloseHandle(vote)
            CreateTimer(3.0, Timer_ChangeCampaign)
        }
        else
        {
            NativeVotes_DisplayFail(vote)
            CloseHandle(vote)
        }
    }
    if (action == MenuAction_Cancel)
    {
        NativeVotes_DisplayFail(vote)
        CloseHandle(vote)
    }
    return 0;
}

public Action Timer_ChangeCampaign(Handle timer)
{
    ServerCommand("changelevel %s", campaignVoteLevel)
    CloseHandle(timer)
    return Plugin_Continue
}

public Action Command_AddonMap(int client, int args)
{
    if (addonMapMenu == null)
        return Plugin_Handled
    addonMapMenu.Display(client, MENU_TIME_FOREVER)
    return Plugin_Handled
}

