require "Advanced_trajectory_core"

-------------------------------
--DAMAGE PLAYER THAT WAS SHOT--
--------------------------------
local function damagePlayershotPVP(player, playerShot, damage, baseGunDmg, headShotDmg, bodyShotDmg, footShotDmg, playerOnlineID, playershotOnlineID)

    --print("DamagePlayershotPVP - ", "playerShot:", playerShot, " damagepr:", damage, " firearmdamage:", baseGunDmg)

    local nameShotPart, playerDamageDealt = Advanced_trajectory.damagePlayershot(playerShot, damage, baseGunDmg, headShotDmg, bodyShotDmg, footShotDmg)

    local isDead = false
    if playerShot:getHealth() < 1 or playerShot:isDead() == true then
        print(playerShot:getUsername() ," is most likely dead.")
        isDead = true
    end

    --Advanced_trajectory.writePVPLog({player, playerShot, nameShotPart, damage, baseGunDmg, playerDamageDealt, isDead})   
    sendClientCommand("ATY_writePVPLog", "true", {playerOnlineID, playershotOnlineID, nameShotPart, damage, baseGunDmg, playerDamageDealt, isDead})
end


local function Advanced_trajectory_OnServerCommand(module, command, arguments)

    local clientPlayershot = getPlayer()
    if not clientPlayershot then return end


    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- sendClientCommand("ATY_shotplayer", "true", {vt[19]:getOnlineID(), Playershot:getOnlineID(), damagepr, vt[6], Advanced_trajectory.HeadShotDmgPlayerMultiplier, Advanced_trajectory.BodyShotDmgPlayerMultiplier, Advanced_trajectory.FootShotDmgPlayerMultiplier})--
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	if module == "ATY_shotplayer" then

        local playerOnlineID        = arguments[1]  
        local playershotOnlineID    = arguments[2]         
        local damagepr              = arguments[3]                 
        local baseGunDmg            = arguments[4]               
        local headShotDmgMultiplier = arguments[5]
        local bodyShotDmgMultiplier = arguments[6]
        local footShotDmgMultiplier = arguments[7]

        local player     = getPlayerByOnlineID(playerOnlineID)

        --print(player:getUsername(), " -> ", playershot:getUsername())

        --if playershotOnlineID ~= clientPlayershot:getOnlineID() then return end

        if (getSandboxOptions():getOptionByName("ATY_nonpvp_protect"):getValue() and NonPvpZone.getNonPvpZone(clientPlayershot:getX(), clientPlayershot:getY())) or (getSandboxOptions():getOptionByName("ATY_safezone_protect"):getValue() and SafeHouse.getSafeHouse(clientPlayershot:getCurrentSquare())) then return end
        -- print(NonPvpZone.getNonPvpZone(getPlayer():getX(), getPlayer():getY()))
        -- print(SafeHouse.getSafeHouse(getPlayer():getCurrentSquare()))

        damagePlayershotPVP(player, clientPlayershot, damagepr, baseGunDmg, headShotDmgMultiplier, bodyShotDmgMultiplier, footShotDmgMultiplier, playerOnlineID, playershotOnlineID)   
    
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
        local characterOnlineID = arguments[2]  --character:getOnlineID()

        if characterOnlineID == clientPlayershot:getOnlineID() then return end
        table.insert(Advanced_trajectory.table, itemobj)



    -----------------------------------
    -- Can't find module in core file--
    -----------------------------------
    elseif module == "ATY_reducehealth" then

        local ExplosionPower = arguments[1]     --ExplosionPower

        clientPlayershot:getBodyDamage():ReduceGeneralHealth(ExplosionPower)



    -------------------------------------------------------------------------------------------
    --sendClientCommand("ATY_cshotzombie", "true", {Zombie:getOnlineID(),vt[19]:getOnlineID()})--
    -------------------------------------------------------------------------------------------
    elseif module == "ATY_cshotzombie" then

        local zedOnlineID = arguments[1]        --Zombie:getOnlineID()
        local playerOnlineID = arguments[2]     --vt[19]:getOnlineID()

        if clientPlayershot:getOnlineID() == playerOnlineID then return end
        local zombies = getCell():getZombieList()

        for i = 1, zombies:size() do

            local zombiez = zombies:get(i - 1)
            if zombiez:getOnlineID() == zedOnlineID then

                -- if not string.find(tostring(zombiez:getCurrentState()), "Climb") and not string.find(tostring(zombiez:getCurrentState()), "Craw") then

                --     zombiez:changeState(ZombieIdleState.instance())

                -- end
                zombiez:setHitReaction("Shot")
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