local MyUtil = {}

function MyUtil.GetMod(name_or_id)
    for _, mod in ipairs(_G.ModManager.mods) do
        -- note: mod.modname is the mod directory name
        if mod.modinfo.name == name_or_id or mod.modinfo.id == name_or_id then
            return mod
        end
    end
    return nil
end

function MyUtil.IsModEnabled(name_or_id)
    return MyUtil.GetMod(name_or_id)
end

function MyUtil.IsModLoaded(name_or_mod)
    local mod = type(name_or_mod) == "string" and MyUtil.GetMod(name_or_mod) or name_or_mod
    if mod then
        return table.contains(_G.ModManager:GetEnabledModNames(), mod.modname)
    end
    return false
end

return MyUtil
