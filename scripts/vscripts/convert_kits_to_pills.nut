function ConvertMedkitsToPills() {
    local spawner = null
    local converted = 0
    local positions = []

    while (spawner = Entities.FindByClassname(spawner, "weapon_spawn")) {
        local modelName = spawner.GetModelName()
        if (modelName == "models/w_models/weapons/w_eq_Medkit.mdl") {
            positions.append({
                pos = spawner.GetOrigin(),
                ang = spawner.GetAngles()
            })
            spawner.Kill()
            converted++
        }
    }

    foreach(data in positions) {
        SpawnEntityFromTable("weapon_pain_pills_spawn", {
            origin = data.pos,
            angles = data.ang,
            spawnflags = 2
        })
    }

    printl("Converted " + converted + " medkits to pills")
}

ConvertMedkitsToPills()
