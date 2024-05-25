require "onin_tase"
require "Advanced_trajectory_core"

local tasergun = {}

tasergun[4] = {0.75,0.75,0.45}
tasergun[6] = 0
tasergun[7] = 2
tasergun[9] = "Taser"
tasergun[11] = false
tasergun[12] = 0.125
tasergun[13] = false
tasergun[14] = "Base.aty_revolversfx"

Advanced_trajectory.Advanced_trajectory["Base.Taser"] = tasergun

local function OnGameStart()
    -- add compat to taser mod from Ae
    if getActivatedMods():contains("Taser") then

        local old_damageZombie = damageZombie
        local old_damagePlayerShot = damagePlayerShot

        -- override function
        damageZombie = function(zombie, damage)
            if (string.contains(getPlayer():getPrimaryHandItem():getAmmoType() or "", "TaserCart")) then
                print("Tased")
                zombie:setUseless(true)
                OnTaseZ(zombie)
            else
                print("No tase")
                return old_damageZombie(zombie, damage)
            end
        end

        damagePlayerShot = function(playerShot, damage, baseGunDmg, headShotDmg, bodyShotDmg, footShotDmg)
            if (string.contains(getPlayer():getPrimaryHandItem():getAmmoType() or "", "TaserCart")) then
                print("Tased")
                OnTaseGun(playerShot)
                return BodyPartType.getDisplayName(BodyPartType.Torso_Upper), 0
            else
                print("No tase")
                return old_damagePlayerShot(playerShot, damage, baseGunDmg, headShotDmg, bodyShotDmg, footShotDmg)
            end
        end
    end
end

Events.OnGameStart.Add(OnGameStart)