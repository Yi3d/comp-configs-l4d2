/* GPLv3, just in-case. */
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[L4D2] Consistency Addon Fix",
    author = "Yird",
    description = "Stops players from being kicked with mis-matched names for custom maps",
    version = "1.0",
    url = "https://github.com/Yi3d"
};

public void OnMapStart() {
    ExcludeAddonsFolder()
}

void ExcludeAddonsFolder() {
    int table = FindStringTable("downloadables")
    if (table == INVALID_STRING_TABLE) {
        PrintToServer("Didn't find the downloadables string tables, that's kinda bad.")
        return
    }

    int count = GetStringTableNumStrings(table)
    char path[PLATFORM_MAX_PATH]

    for (int i = 0; i < count; i++) {
        ReadStringTable(table, i, path, sizeof(path))
        if (StrContains(path, "addons/", false) == 0 || StrContains(path, "addons\\", false) == 0 ) {
            SetStringTableData(table, i, NULL_STRING, 1)
        }
    }
}