if getActivatedMods():contains("Advanced_Trajectorys_Realistic_Overhaul") then
    require "onin_tase"

    local Advanced_trajectory = require "Advanced_trajectory_core"

    local tasergun = {}

    tasergun.damage = 0
    tasergun.bulletPos = {0, 0, 0.5}
    tasergun.bulletDist = 1.5
    tasergun.weaponName = "Taser"
    tasergun.projectileType = "Base.aty_revolversfx"

    Advanced_trajectory.FullWeaponTypes["Base.Taser"] = tasergun

    local function OnGameStart()
        -- add compat to taser mod from Ae
        if getActivatedMods():contains("Taser") then

            local old_damagePlayerShot = Advanced_trajectory.damagePlayerShot
            local old_damageZombie = Advanced_trajectory.damageZombie
            
            -- override function
            Advanced_trajectory.damagePlayerShot = function(playerShot, damage, baseGunDmg, playerDmgMultipliers)
                if (string.contains(getPlayer():getPrimaryHandItem():getAmmoType() or "", "TaserCart")) then
                    --print("Tased")
                    OnTaseGun(playerShot)
                    return BodyPartType.getDisplayName(BodyPartType.Torso_Upper), 0
                else
                    --print("No tase")
                    return old_damagePlayerShot(playerShot, damage, baseGunDmg, playerDmgMultipliers)
                end
            end

            Advanced_trajectory.damageZombie = function(zombie, damage)
                if (string.contains(getPlayer():getPrimaryHandItem():getAmmoType() or "", "TaserCart")) then
                    --print("Tased")
                    zombie:setUseless(true)
                    OnTaseZ(zombie)
                else
                    --print("No tase")
                    return old_damageZombie(zombie, damage)
                end
            end
        end
    end

    Events.OnGameStart.Add(OnGameStart)
end