local Advanced_trajectory = require "Advanced_trajectory_core"

-------------------------------
--DAMAGE PLAYER THAT WAS SHOT--
--------------------------------
local function damagePlayershotPVP(player, playerShot, damage, baseGunDmg, playerDmgMultipliers, playerOnlineID, playershotOnlineID)

    --print("playerShot:", playerShot, " damagepr:", damage, " firearmdamage:", baseGunDmg)

    local nameShotPart, playerDamageDealt = Advanced_trajectory.damagePlayershot(playerShot, damage, baseGunDmg, playerDmgMultipliers)

    local isDead = false
    if playerShot:getHealth() < 1 or playerShot:isDead() == true then
        --print(playerShot:getUsername() ," is most likely dead.")
        isDead = true
    end
  
    sendClientCommand("ATY_writePVPLog", "true", {playerOnlineID, playershotOnlineID, nameShotPart, damage, baseGunDmg, playerDamageDealt, isDead})
end


local function Advanced_trajectory_OnServerCommand(module, command, arguments)

    -- this is the target player that was shot
    -- if target was you (id 0), return 
    -- if you are the only player in mp, clientPlayershot id would be your id even when shooting diff zombies
    local clientPlayershot = getPlayer()

    -- will always pass if statement if playing in MP no matter what IsoGameChar you shoot
    if not clientPlayershot then return end

    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- sendClientCommand("ATY_shotplayer", "true", {vt[19]:getOnlineID(), Playershot:getOnlineID(), damagepr, vt[6], Advanced_trajectory.HeadShotDmgPlayerMultiplier, Advanced_trajectory.BodyShotDmgPlayerMultiplier, Advanced_trajectory.FootShotDmgPlayerMultiplier})--
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	if module == "ATY_shotplayer" then

        local playerOnlineID        = arguments[1]  
        local playershotOnlineID    = arguments[2]         
        local damagepr              = arguments[3]                 
        local baseGunDmg            = arguments[4]               
        local playerDmgMultipliers  = arguments[5]

        local player = getPlayerByOnlineID(playerOnlineID)

        damagePlayershotPVP(player, clientPlayershot, damagepr, baseGunDmg, playerDmgMultipliers, playerOnlineID, playershotOnlineID)   
    
    -----------------------------------------------------------------------------------------------------------------------------------
    --sendClientCommand("ATY_writePVPLog", "true", {player, playerShot, nameShotPart, damage, baseGunDmg, playerDamageDealt, isDead})--
    -----------------------------------------------------------------------------------------------------------------------------------
    elseif module == "ATY_writePVPLog" then
        local shooter                   = getPlayerByOnlineID(arguments[1]):getUsername()
        local target                    = getPlayerByOnlineID(arguments[2]):getUsername()
        local strShotPart               = arguments[3]   
        local damagepr                  = arguments[4]                 
        local baseGunDmg                = arguments[5]     
        local damageDealtToTarget       = arguments[6]     
        local targetIsDead              = arguments[7]  
        
        -- if shooter is invisible from admin power, then shooter var will be nil
        if not shooter then
            shooter = 'unknown/invisible'
        end
        
        if not target then
            target = 'unknown/invisible'
        end
    
        local log1 = string.format(("[ATROPVP] \"%s\" shot \"%s\" (PartShot: \"%s\" || HitDmg: \"%s\" || BaseGunDmg: \"%s\"  || ActDmg: \"%s\")"), shooter, target, strShotPart, damagepr, baseGunDmg, damageDealtToTarget)
        writeLog("ATROPVP", log1)
    
        if targetIsDead == true then
            local killLog = string.format(("[ATROPVP] \"%s\" was killed by \"%s\""), target, shooter)
            writeLog("ATROPVP", killLog)
        end

    ----------------------------------------------------------------------------
    --sendClientCommand("ATY_shotsfx", "true", {tablez, character:getOnlineID()})--
    ----------------------------------------------------------------------------
    elseif module == "ATY_shotsfx" then

        local itemobj = arguments[1]            --tablez[1] or item obj
        local playerOnlineID = arguments[2]     --character:getOnlineID()

        if playerOnlineID == clientPlayershot:getOnlineID() then return end
        table.insert(Advanced_trajectory.table, itemobj)



    -----------------------------------
    -- Can't find module in core file--
    -----------------------------------
    elseif module == "ATY_reducehealth" then

        local ExplosionPower = arguments[1]     --ExplosionPower

        clientPlayershot:getBodyDamage():ReduceGeneralHealth(ExplosionPower)



    -----------------------------------------------------------------------------------------------------
    --sendClientCommand("ATY_cshotzombie", "true", {Zombie:getOnlineID(),vt[19]:getOnlineID(), damage})--
    -----------------------------------------------------------------------------------------------------
    elseif module == "ATY_cshotzombie" then

        local zedOnlineID       = arguments[1]      -- Zombie:getOnlineID()
        local playerOnlineID    = arguments[2]      -- vt[19]:getOnlineID()
        local damage            = arguments[3]      -- damage
        local isCrit            = arguments[4]
        local limbShot          = arguments[5]

        local player = getPlayerByOnlineID(playerOnlineID)
        if not player then
            player = clientPlayershot
        end

        local zombies = getCell():getZombieList()

        for i = 1, zombies:size() do
            local zombie = zombies:get(i - 1)
            if zombie:getOnlineID() == zedOnlineID then
                Advanced_trajectory.damageZombie(zombie, damage, isCrit, limbShot, player) 
            end
        end
        
    -------------------------------------------------------------------
    --sendClientCommand("ATY_killzombie", "true", {Zombie:getOnlineID()})--
    --------------------------------------------------------------------
    elseif module == "ATY_killzombie" then

        local zedOnlineID = arguments[1] --Zombie:getOnlineID()

        local zombies = getCell():getZombieList()

        for i=1,zombies:size() do

            local zombiez = zombies:get(i - 1)
            if zombiez:getOnlineID() == zedOnlineID then

                zombiez:Kill(zombiez)

            end
        end

    end

end

Events.OnServerCommand.Add(Advanced_trajectory_OnServerCommand)