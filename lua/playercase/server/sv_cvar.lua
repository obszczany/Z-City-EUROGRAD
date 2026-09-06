local CVARS = {
    case_drop_on_death = CreateConVar("case_sv_drop_on_death", "1", {FCVAR_ARCHIVE}, "", 0, 1),
    case_drop_excess_ammo = CreateConVar("case_sv_drop_excess_ammo", "1", {FCVAR_ARCHIVE},"", 0, 1),
    case_frame0_pickup = CreateConVar("case_sv_frame_0_pickup", "1", {FCVAR_ARCHIVE}, [[Allows items to be picked up if they were created 0 frames ago
    Useful for mods that replace weapons on pickup]], 0, 1),

    -- SH (SILENT HILL???) Because the client needs to know about them :)
    case_inventory_mode = CreateConVar("case_sh_inventory_mode", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "???", 0, 2),
    case_auto_generate = CreateConVar("case_sh_auto_generate", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, [[0-> Don't auto generate weapons
    1 -> Auto generates ammo/weapons
    2 -> Auto generate and dump some lua code to replicate]], 0, 2),
    case_default_size = CreateConVar("case_sh_default_size", "s", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The default case size players will span with as a letter (S, M, L, XL, XXL) or two numbers (16 16)"),
    -- These ones are kinda customization kinda not
    -- So the server can let clients pick or just enforce one of them
    case_pickup_on_hold = CreateConVar("case_sv_pickup_on_hold", "-1", {FCVAR_ARCHIVE}, [[-1 -> Allow clients to set this value
    0 -> Holding an item doesn't pick it up
    1 -> Holding an item picks it up if walk isn't held
    2 -> Holding an item picks it up]], -1, 2),
    case_pickup_mode = CreateConVar("case_sv_pickup_mode", "-1", {FCVAR_ARCHIVE}, [[-1 -> Allow clients to set this value
    0 -> Items can be walked over to be picked up
    1 -> Items must be +used to pickup (will still be picked up if in a vehicle)
    2 -> Items must be +used no matter what]], -1, 2),
    case_weapon_validation = CreateConVar("case_sv_weapon_validation", "1", {FCVAR_ARCHIVE}, [[0 -> Don't do weapon validation checks (might, maybe increase performance)
    1 -> Do weapon validation checks]], 0, 1),
    case_pickup_compat = CreateConVar("case_sv_pickup_compat", "1", {FCVAR_ARCHIVE}, [[0 -> Don't allow other pickup hooks to be run
    1 -> Rerun all other pickup hooks]], 0, 1)
}



function CaseInventory:GetCVAR(name)
    return CVARS[name]
end