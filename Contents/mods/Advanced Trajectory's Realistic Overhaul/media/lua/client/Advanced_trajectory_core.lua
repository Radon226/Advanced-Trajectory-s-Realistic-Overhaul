Advanced_trajectory                     = {}
Advanced_trajectory.table               = {}
Advanced_trajectory.boomtable           = {}
Advanced_trajectory.aimcursor           = nil
Advanced_trajectory.aimcursorsq         = nil
Advanced_trajectory.panel               = {}
Advanced_trajectory.panel.instance      = nil
Advanced_trajectory.aimnum              = 100
Advanced_trajectory.aimnumBeforeShot    = 0
Advanced_trajectory.maxaimnum           = 100
Advanced_trajectory.minaimnum           = 0

Advanced_trajectory.missedShot          = false
Advanced_trajectory.targetDistance      = 0
Advanced_trajectory.isOverDistanceLimit = false

Advanced_trajectory.inhaleCounter       = 0
Advanced_trajectory.exhaleCounter       = 0
Advanced_trajectory.maxFocusCounter     = 100
Advanced_trajectory.aimrate             = 0

Advanced_trajectory.crouchCounter       = 100
Advanced_trajectory.isCrouch            = false
Advanced_trajectory.isCrawl             = false

Advanced_trajectory.hasFlameWeapon      = false

-- for aimtex
Advanced_trajectory.alpha           = 0
Advanced_trajectory.stressEffect    = 0
Advanced_trajectory.painEffect      = 0
Advanced_trajectory.panicEffect     = 0

Advanced_trajectory.aimtexwtable    = {}
Advanced_trajectory.aimtexdistance  = 0 -- Weapons containing crosshairs

Advanced_trajectory.Advanced_trajectory = {}

-- DmgZom are the damage multipliers for zombies
Advanced_trajectory.HeadShotDmgZomMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.headShotDmgZomMultiplier"):getValue()
Advanced_trajectory.BodyShotDmgZomMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.bodyShotDmgZomMultiplier"):getValue()
Advanced_trajectory.FootShotDmgZomMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.footShotDmgZomMultiplier"):getValue()

-- DmgPlayer are the damage multipliers for players
Advanced_trajectory.HeadShotDmgPlayerMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.headShotDmgPlayerMultiplier"):getValue()
Advanced_trajectory.BodyShotDmgPlayerMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.bodyShotDmgPlayerMultiplier"):getValue()
Advanced_trajectory.FootShotDmgPlayerMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.footShotDmgPlayerMultiplier"):getValue()


----------------------------------------------------------------
--REMOVE ITEM (ex. bullet projectile when collide) FUNC SECT---
----------------------------------------------------------------
function Advanced_trajectory.itemremove(worlditem)
    if worlditem == nil then return end
    -- worlditem:getWorldItem():getSquare():transmitRemoveItemFromSquare(worlditem:getWorldItem())
    worlditem:getWorldItem():removeFromSquare()
end

-------------------------
--MATH FLOOR FUNC SECT---
-------------------------
function Advanced_trajectory.mathfloor(number)
    return number - math.floor(number)
end

-----------------------------
--ADD TEXTURE FX FUNC SECT---
-----------------------------
function Advanced_trajectory.additemsfx(square,itemname,x,y,z)
    if square:getZ() > 7 then return end
    local iteminv = InventoryItemFactory.CreateItem(itemname)
    local itemin = IsoWorldInventoryObject.new(iteminv,square,Advanced_trajectory.mathfloor(x),Advanced_trajectory.mathfloor(y),Advanced_trajectory.mathfloor(z));
    iteminv:setWorldItem(itemin)
    square:getWorldObjects():add(itemin)
    square:getObjects():add(itemin)
    local chunk = square:getChunk()
    
    if chunk then
        square:getChunk():recalcHashCodeObjects()
    else return end
    -- iteminv:setAutoAge();
    -- itemin:setKeyId(iteminv:getKeyId());
    -- itemin:setName(iteminv:getName());
    return iteminv
end

-------------------------
--TABLE ?? FUNC SECT---
-------------------------
function Advanced_trajectory.twotable(table2)
    local table1={}

    for i,k in pairs(table2) do
        table1[i]=table2[i]
    end
    -- print(table1)
    return table1
end

----------------------------------------------------
--BULLET HIT ZOMBIE/PLAYER DETECTION ?? FUNC SECT---
----------------------------------------------------
--[[
NOTES:  - bulletTable (position table of offsets xyz {})
        - damage 1+angleoff = head || 2 = body || 3 = foot
        - shooter (client player (you) shooting)
]]
function Advanced_trajectory.getShootzombie(bulletTable,damage,playerTable)

    -- Initialize tables to store zombies and players
    local zbtable = {}  -- zombie table
    local prtable = {}  -- player table

    local player = getPlayer()
    local isPlayerSafe = player:getSafety():isEnabled()
    
    local playerNum = player:getPlayerNum()

    local playerDir = player:getForwardDirection():getDirection()*360/(2*math.pi)
    --print("Bullet pos: ", math.floor(bulletTable[1]), " | ", math.floor(bulletTable[2]))
    --print("Player pos: ", math.floor(playerTable[1]), " | ", math.floor(playerTable[2]))

    -- Define grid dimensions
    local gridMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugGridMultiplier"):getValue()    
    local ignorePVPSafety = getSandboxOptions():getOptionByName("Advanced_trajectory.IgnorePVPSafety"):getValue()   

    -- minimum distance from player to target
    local mindistance = 0

    -- is target in bullet cell? mindistance = 1
    local minzb = {false,1}
    local minpr = {false,1}

    if Advanced_trajectory.missedShot then
        return minzb[1],minpr[1]
    end
    
    --local numZomsShootable = 0

    -- Loop through a 3x3 grid centered around the bullet
    for kz = -1, 1 do  -- X position
        for vz = -1, 1 do  -- Y position
            
            -- Calculate the coordinates for the current grid square
            local x = bulletTable[1] + kz * gridMultiplier
            local y = bulletTable[2] + vz * gridMultiplier
            local z = bulletTable[3]

            -- Get the grid square at the calculated coordinates
            local sq = getCell():getGridSquare(x, y, z)

            -- Check if the grid square is valid and can be seen by the player
            if sq and sq:isCanSee(playerNum) then
                local movingObjects = sq:getMovingObjects()

                -- Iterate through moving objects in the grid square
                for zz = 1, movingObjects:size() do
                    local zombieOrPlayer = movingObjects:get(zz - 1)

                    -- Check if the object is an IsoZombie or IsoPlayer
                    if instanceof(zombieOrPlayer, "IsoZombie") then
                        zbtable[zombieOrPlayer] = 1  -- Add to zombie table
                    end
                    if instanceof(zombieOrPlayer, "IsoPlayer") then
                        --print("FOUND PLAYER SHOOTER/TARGET SAFE?: ", isPlayerSafe, " || ", zombieOrPlayer:getSafety():isEnabled())
                        if (not isPlayerSafe or not zombieOrPlayer:getSafety():isEnabled()) or ignorePVPSafety then
                            --print("player registered for a meal [it's a bullet]")
                            prtable[zombieOrPlayer] = 1  -- Add to player table
                        end
                    end
                end

            -- make exception if bullet and player are on the same floor to prevent issue with blindness
            elseif sq and math.floor(bulletTable[3]) == math.floor(playerTable[3]) then
                local movingObjects = sq:getMovingObjects()

                for zz = 1, movingObjects:size() do
                    local zombieOrPlayer = movingObjects:get(zz - 1)

                    if instanceof(zombieOrPlayer, "IsoZombie") then
                        zbtable[zombieOrPlayer] = 1 
                        --numZomsShootable = numZomsShootable + 1
                    end
                    if instanceof(zombieOrPlayer, "IsoPlayer") then
                        --print("FOUND PLAYER SHOOTER/TARGET SAFE?: ", isPlayerSafe, " || ", zombieOrPlayer:getSafety():isEnabled())
                        if (not isPlayerSafe or not zombieOrPlayer:getSafety():isEnabled()) or ignorePVPSafety then
                            --print("player registered for a meal [it's a bullet]")
                            prtable[zombieOrPlayer] = 1  -- Add to player table
                        end
                    end
                end
            end
        end
    end

    --print("Num Zoms Shootable: ", numZomsShootable)
    --print("*********END**********")

    local zomMindistModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugZomMindistCondition"):getValue()
    local playerMindistModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugPlayerMindistCondition"):getValue()
    
    --print('-----------START-------------------')
    -- goes through zombie table which contains a number of zombies found in the half 3x3 grid
    -- SEEMS LIKE THIS DETERMINES HITBOX, FOCUS ON THIS INSTEAD FOR ZOMBIE COLLISION
    for sz,bz in pairs(zbtable) do
        -- if zombie is behind player when looking SE, skip
        if (playerDir <= 90 and playerDir >= 0) and ((sz:getX() < playerTable[1]-1 and sz:getY() > playerTable[2]+1) or (sz:getX() < playerTable[1] and sz:getY() < playerTable[2]) or (sz:getX() > playerTable[1]+1 and sz:getY() < playerTable[2]-1)) then
            --print("**********skipCheckBehind LOOKING DOWN  ********")
            --print("Player dir: ", playerDir)
        elseif (playerDir >= -180 and playerDir <= -90) and (sz:getX() > playerTable[1] and sz:getY() > playerTable[2]) then
            --print("**********skipCheckBehind LOOKING UP    *********")
            --print("Player dir: ", playerDir)
        elseif (playerDir <= 0 and playerDir >= -90) and (sz:getX() < playerTable[1] and sz:getY() > playerTable[2]) then
            --print("**********skipCheckBehind LOOKING RIGHT *********")
            --print("Player dir: ", playerDir)
        elseif (playerDir >= 90 and playerDir <= 180) and (sz:getX() > playerTable[1] and sz:getY() < playerTable[2]) then
            --print("**********skipCheckBehind LOOKING LEFT *********")
            --print("Player dir: ", playerDir)
        else
            -- uses euclidian distance to find distance between target and bullet
            --mindistance = math.sqrt((bulletTable[1] - sz:getX())^2 + (bulletTable[2] - sz:getY())^2 )
            mindistance = (bulletTable[1] - sz:getX())^2 + (bulletTable[2] - sz:getY())^2 
            --print("Mindist <= mindistMod*dmg: --->>> ", mindistance, " <= ", zomMindistModifier*damage)
            
            if mindistance < minzb[2] and (mindistance <= zomMindistModifier * damage) then
                minzb = {sz,mindistance}
                --print("Updated minzb")
            end
        end
    end

    -- player table [0.4 mindistancemodifier]
    for sz,bz in pairs(prtable) do
        -- if zombie is behind player when looking SE, skip
        if (playerDir <= 90 and playerDir >= 0) and ((sz:getX() < playerTable[1]-1 and sz:getY() > playerTable[2]+1) or (sz:getX() < playerTable[1] and sz:getY() < playerTable[2]) or (sz:getX() > playerTable[1]+1 and sz:getY() < playerTable[2]-1)) then
            --print("**********skipCheckBehind LOOKING DOWN  ********")
        elseif (playerDir >= -180 and playerDir <= -90) and (sz:getX() > playerTable[1] and sz:getY() > playerTable[2]) then
            --print("**********skipCheckBehind LOOKING UP    *********")
        elseif (playerDir <= 0 and playerDir >= -90) and (sz:getX() < playerTable[1] and sz:getY() > playerTable[2]) then
            --print("**********skipCheckBehind LOOKING RIGHT *********")
        elseif (playerDir >= 90 and playerDir <= 180) and (sz:getX() > playerTable[1] and sz:getY() < playerTable[2]) then
            --print("**********skipCheckBehind LOOKING LEFT *********")
        else

            --mindistance = math.sqrt((bulletTable[1] - sz:getX())^2 + (bulletTable[2] - sz:getY())^2)
            mindistance = (bulletTable[1] - sz:getX())^2 + (bulletTable[2] - sz:getY())^2 
            --print("Mindist <= mindistMod*dmg: ", mindistance, " <= ", playerMindistModifier * damage)
            
            if mindistance < minpr[2] and (mindistance <= playerMindistModifier * damage) then
                minpr = {sz,mindistance}
                --print("Updated minpr")
            end
        end
    end

    --print('mindistance: ', mindistance)
    --print('FINAL minzb/mindist: ', minzb[1], '/', minzb[2])
    --print('-----------END-------------------')

    -- returns BOOL on whether zombie or player was hit
    return minzb[1],minpr[1]

end


----------------------------------------------------
--BULLET COLLISION WITH STATIC OBJECTS FUNC SECT---
----------------------------------------------------
-- checks the squares that the bullet travels
-- this function determines whether bullets should "break" meaning they stop, pretty much a collision checker
-- bullet square, dirc, bullet offset, player offset, nonsfx
function Advanced_trajectory.checkiswallordoor(square,bulletAngle,bulletPosition,playerPosition,nosfx)
    --print("----SQUARE---: ",   square:getX(), "  //  ", square:getY())

    local bulletPosFloorX = math.floor(bulletPosition[1])
    local bulletPosFloorY = math.floor(bulletPosition[2])

    local playerPosFloorX = math.floor(playerPosition[1])
    local playerPosFloorY = math.floor(playerPosition[2])
    local playerPosFloorZ = math.floor(playerPosition[3])

    local bulletPosX = bulletPosition[1]
    local bulletPosY = bulletPosition[2]
    local playerPosX = playerPosition[1]
    local playerPosY = playerPosition[2]

    local angle = bulletAngle
    if angle > 180 then
        angle = -180 + (angle-180)
    end
    if angle < -180 then
        angle = 180 + (angle+180)
    end

    -- direction from -pi to pi OR -180 to 180 deg
    -- N (top left corner): pi,-pi  (180, -180)
    -- W (bottom left): pi/2 (90)
    -- E (top right): -pi/2 (-90)
    -- S (bottom right corner): 0
    --print("initial angle: ",          bulletAngle)
    --print("after angle: ",          angle)
    --print("bulletPosFl: ", bulletPosFloorX, "  //  ", bulletPosFloorY)

    -- walk towards bot right means X+
    -- walk towards bot left means  Y+
    -- walk towards top left means  X-
    -- walk towards top right means Y-
    --print("playerPosFl: ",     playerPosFloorX , "  //  ", playerPosFloorY)

    --print("bulletPos: ",   bulletPosX, "  //  ", bulletPosY)
    --print("playerPos: ",   playerPosX , "  //  ", playerPosY)
    --print("------------------------------------------------------------------")

    -- returns an array of objects in that square, for loop and filter it to get what you want
    local objects = square:getObjects()
    if objects then
        for i=1,objects:size() do

            local locobject = objects:get(i-1)
            local sprite = locobject:getSprite()
            if sprite  then
                local Properties = sprite:getProperties()
                if Properties then

                    local wallN = Properties:Is(IsoFlagType.WallN)
                    local doorN = Properties:Is(IsoFlagType.doorN)

                    local wallNW = Properties:Is(IsoFlagType.WallNW)
                    local wallSE = Properties:Is(IsoFlagType.WallSE)

                    local wallW = Properties:Is(IsoFlagType.WallW)
                    local doorW = Properties:Is(IsoFlagType.doorW)

                    -- if the locoobject is "IsoWindow" which is a class and it's not smashed, smash it
                    if instanceof(locobject,"IsoWindow") and not locobject:isSmashed() and not locobject:IsOpen() then

                        if nosfx then return true end
                        locobject:setSmashed(true)
                        getSoundManager():PlayWorldSoundWav("SmashWindow",square, 0.5, 2, 0.5, true);
                        return true
                    end

                    local isAngleTrue = false

                    -- prevents wall collision when shooting targets below on roofs by ignoring wall near player
                    if Advanced_trajectory.aimlevels then 
                        --print("Aim Level | playerZ: ", Advanced_trajectory.aimlevels, " || ", playerPosFloorZ)
                        if (wallN or doorN or wallNW or wallSE or wallW or doorW) and (Advanced_trajectory.aimlevels ~= playerPosFloorZ) then
                            return false
                        end
                    end

                    if wallNW then
                        --if shooting into corner, then break
                        -- - means player > sq
                        -- + means player < sq
                        if 
                        (angle<=135 and angle>=90) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle<=90 and angle>=0) and (playerPosY  < square:getY() or playerPosX  < square:getX()) or
                        (angle<=0 and angle>=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX())
                        then
                            --print("----Facing outside into wallNW----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        if 
                        (angle>=135 and angle<=180) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle>=-180 and angle<=-90) and (playerPosY  > square:getY() or playerPosX  > square:getX()) or
                        (angle>=-90 and angle<=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX()) 
                        then
                            --print("----Facing inside into wallNW----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end
                    elseif wallSE then
                        if 
                        (angle<=135 and angle>=90) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle<=90 and angle>=0) and (playerPosY  < square:getY() or playerPosX  < square:getX()) or
                        (angle<=0 and angle>=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX())
                        then
                            --print("----Facing inside into wallSE----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        if 
                        (angle>=135 and angle<=180) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle>=-180 and angle<=-90) and (playerPosY  > square:getY() or playerPosX  > square:getX()) or
                        (angle>=-90 and angle<=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX()) 
                        then
                            --print("----Facing outside into wallSE----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end
                    elseif wallN or (doorN and not locobject:IsOpen()) then
                        isAngleTrue = angle <=0 and angle >= -180
                        -- facing east into wallN
                        if (isAngleTrue) and playerPosY  > square:getY() then
                            --print("----Facing EAST into wallN----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        isAngleTrue = angle >=0 and angle <= 180
                        -- facing west into wallN
                        if (isAngleTrue) and playerPosY < square:getY() then
                            --print("----Facing WEST into wallN----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        --print("++++Angle was true for wallN++++")
                    elseif wallW or (doorW and  not locobject:IsOpen()) then
                        isAngleTrue = (angle >=0 and angle <= 90) or (angle <=0 and angle >= -90)
                        -- facing south into wallW
                        if (isAngleTrue) and playerPosX < square:getX() then
                            --print("----Facing SOUTH into wallW----")

                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        isAngleTrue = (angle >=90 and angle <= 180) or (angle <=-90 and angle >= -180)
                        -- facing north into wallW
                        if (isAngleTrue) and playerPosX > square:getX() then
                            --print("----Facing NORTH into wallW----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        --print("++++Angle was true for wallW++++")
                    end
                    

                end
            end
        end
    end

    local player = getPlayer()
    local playervehicle 
    if player then
        playervehicle = player:getVehicle()
    end

    local squarecar = playervehicle or square:getVehicleContainer()
    -- local squarecar2
    -- local player = getPlayer()
    -- if player then
    --     local vehsq = player:getCurrentSquare()
    --     if vehsq then
    --         squarecar2 = vehsq:getVehicleContainer()
    --     end
    -- end
    
    if squarecar and ((squarecar:getX() -playerPosition[1] )^2  + (squarecar:getY() -playerPosition[2])^2)  >8 then
        if nosfx then return true end

        if ((squarecar:getX() -bulletPosition[1] )^2  + (squarecar:getY() -bulletPosition[2])^2) < 2.8  then
            if getSandboxOptions():getOptionByName("AT_VehicleDamageenable"):getValue() then
                squarecar:HitByVehicle(squarecar, 0.3)
            end

            return true
        end 
    end

end

-----------------------------------
--EXPLOSION LOGIC ?? FUNC SECT---
-----------------------------------
function Advanced_trajectory.boomontick()

    local tablenow = Advanced_trajectory.boomtable
    for kt,vt in pairs(tablenow) do

        for kz,vz in pairs(vt[12]) do
            Advanced_trajectory.itemremove(vt[12][vt[3] - vt[13]])
        end

        if vt[3] > vt[2] + vt[13] then
            tablenow[kt] = nil
            break
        end

        if vt[3]== 1 and  vt[7]==0 then 


            local itemornone = Advanced_trajectory.additemsfx(vt[5],vt[1]..tostring(vt[3]),vt[4][1],vt[4][2],vt[4][3])
            table.insert(vt[12],itemornone)
            vt[3]=vt[3]+1
        elseif vt[7] > vt[6] and vt[3] <= vt[2] then
            vt[7] = 0

            local itemornone = Advanced_trajectory.additemsfx(vt[5],vt[1]..tostring(vt[3]),vt[4][1],vt[4][2],vt[4][3])
            table.insert(vt[12],itemornone)
            vt[3]=vt[3]+1
        elseif vt[7] > vt[6] then
            vt[7] = 0 
            vt[3]=vt[3]+1
        end
            
        vt[7] = vt[7] + getGameTime():getMultiplier()

    end


end

-----------------------------------
--EXPLOSION FX ?? FUNC SECT---
-----------------------------------
function Advanced_trajectory.boomsfx(sq,sfxName,sfxNum,ticktime)
    -- print(sq)
    local sfxname = sfxName or"Base.theMH_MkII_SFX"
    local sfxnum = sfxNum or 12
    local nowsfxnum =1
    local sfxcount = 0
    local pos = {sq:getX(), sq:getY() ,sq:getZ()}
    local square = sq
    local ticktime = ticktime or 3.5
    local func = function() return end
    local varz1,varz2,varz3
    local item = {}
    local offset = 3

    local tablesfx = {

        sfxname,         ---1
        sfxnum,          ---2
        nowsfxnum,       ---3
        pos,             ---4
        square,          ---5
        ticktime,        ---6
        sfxcount,        ---7
        func,            ---8
        varz1,           ---9
        varz2,           ---10
        varz3,           ---11
        item,            ---12
        offset           ---13滞后
    }

    table.insert(Advanced_trajectory.boomtable,tablesfx)
end

-----------------------------------
--ATTACHMENT EFFECTS FUNC SECT-----
-----------------------------------
-- Consider vanilla AND brita's into account
function Advanced_trajectory.getAttachmentEffects(weapon)  
    local scope     = weapon:getScope()         -- scopes/reddots/sights
    local canon     = weapon:getCanon()         -- britas: bayonets, barrels, chokes
    local stock     = weapon:getStock()         -- stocks, lasers
    local recoilPad = weapon:getRecoilpad()     -- britas: pad, pistol stock
    local sling     = weapon:getSling()         -- britas: slings, foregrips, launchers, ammobelts

    --print("Scp/Can/Stk/Rec/Slg: ", scope, " / ", canon, " / ", stock, " / ", recoilPad, " / ", sling)

    local modTable  = {scope, canon, stock, recoilPad}

    local aimingTime = 0         --1 multiply to reduceSpeed           + good
    local hitChance  = 0         --2 multiply to focusCounterSpeed     + good
    local recoil     = 0         --3 multiply to recoil                - good
    local range      = 0         --4 add to proj range                 + good
    local angle      = 0         --5                                   - good

    local effectsTable =  {
        aimingTime,         
        hitChance ,       
        recoil    ,       
        range     ,        
        angle     ,  
    }

    -- for every attachment, add all of their buffs/nerfs into var
    for index, mod in pairs(modTable) do
        -- check if it exists first
        if mod then
            effectsTable[1]  = effectsTable[1] + mod:getAimingTime()
            effectsTable[2]  = effectsTable[2] + mod:getHitChance()
            effectsTable[3]  = effectsTable[3] + mod:getRecoilDelay()
            effectsTable[4]  = effectsTable[4] + mod:getMaxRange()
            effectsTable[5]  = effectsTable[5] + mod:getAngle()
        end
    end

    --aimingTime: flat nerf/buff                1.1 - table
    if  effectsTable[1] < 0 then
        effectsTable[1] = effectsTable[1]*2 / 100 
    else
        effectsTable[1] = effectsTable[1]*5 / 100 
    end

    --hitChance: flat nerf/buff                 2 - table
    if  effectsTable[2] < 0 then
        effectsTable[2] = effectsTable[2]*3 / 100 
    else
        effectsTable[2] = effectsTable[2]*8 / 100 
    end

    effectsTable[3]     = (effectsTable[3]*5 / 100) + 1
    effectsTable[4]     =  effectsTable[4] * 0.5
    effectsTable[5]     =  effectsTable[5] * 10

    return effectsTable
end


-----------------------------------
--AIMNUM/BLOOM LOGIC FUNC SECT---
-----------------------------------
function Advanced_trajectory.OnPlayerUpdate()

    local player = getPlayer() 
    if not player then return end
    local weaitem = player:getPrimaryHandItem()

    if player:isAiming() and instanceof(weaitem,"HandWeapon") then
        Advanced_trajectory.hasFlameWeapon = string.contains(weaitem:getAmmoType() or "","FlameFuel")
    end

    if player:isAiming() and instanceof(weaitem,"HandWeapon") and not weaitem:hasTag("Thrown") and not Advanced_trajectory.hasFlameWeapon and not (weaitem:hasTag("XBow") and not getSandboxOptions():getOptionByName("Advanced_trajectory.DebugEnableBow"):getValue()) and (((weaitem:isRanged() and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue()) or (weaitem:getSwingAnim() =="Throw" and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablethrow"):getValue())) or Advanced_trajectory.Advanced_trajectory[weaitem:getFullType()]) then
        --print(player:getForwardDirection():getDirection()*360/(2*math.pi))
        -- print(getPlayer():getCoopPVP())

        if getSandboxOptions():getOptionByName("Advanced_trajectory.showOutlines"):getValue() then
            weaitem:setMaxHitCount(1)
        else
            weaitem:setMaxHitCount(0)
        end


        local modEffectsTable = Advanced_trajectory.getAttachmentEffects(weaitem)  
        --print("Rs: ", modEffectsTable[1], " / Fc: ", modEffectsTable[2], " / Re: ", modEffectsTable[3], " / Ra: ", modEffectsTable[4], " / A:", modEffectsTable[5])

        Mouse.setCursorVisible(false)
        
        ------------------------
        --AIMNUM SCALING SECT---
        ------------------------
        local reversedLevel = 11-player:getPerkLevel(Perks.Aiming)  -- 11 to 1 
        local realLevel     = player:getPerkLevel(Perks.Aiming)     -- 0 to 10

        local gametimemul   = getGameTime():getMultiplier() * 16 / (reversedLevel + 10)
        local constantTime  = getGameTime():getMultiplier() * 16 / (1 + 10)

        local maxaimnumModifier         = getSandboxOptions():getOptionByName("Advanced_trajectory.maxaimnum"):getValue() 
        local realMaxaimnum             = weaitem:getAimingTime() + (reversedLevel * maxaimnumModifier)

        local minaimnumModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.minaimnumModifier"):getValue() 
        local realMin           = (reversedLevel - 1) * minaimnumModifier

        -- aimbot level (sorta)
        if realLevel >= 10 then
            realMin = 5 
        end

        -- bloom reduction scaling rate capped at 6
        if realLevel > 6 then
            gametimemul = getGameTime():getMultiplier() * 16 / (12-6 + 10)
        end

        if realLevel < 3 then
            gametimemul = getGameTime():getMultiplier() * 16 / (12-3 + 10)
        end

        -- maxaimnum capped at 8
        if realLevel > 8 then
            realMaxaimnum = weaitem:getAimingTime() + ((11-8) * maxaimnumModifier)
        end

        local canRunNGun = false
        -- run and gun unlock
        if realLevel >= getSandboxOptions():getOptionByName("Advanced_trajectory.runNGunLv"):getValue() or player:HasTrait("RunNGun") then
            canRunNGun = true
        end

        Advanced_trajectory.maxaimnum   = realMaxaimnum

        --------------------------------------------------------------------------------
        ---FOCUS MECHANIC SECT (IF MINAIMNUM IS REACHED, start counting down to 0)---
        --------------------------------------------------------------------------------
        -- If player moves or shoots (aimnum increases), reset counter and minaimnum.

        -- rate of reduction for minaimnum
        local maxFocusSpeed = getSandboxOptions():getOptionByName("Advanced_trajectory.maxFocusSpeed"):getValue() 

        -- max recoil delay is 100 (sniper), 50 (shotgun), 20-30 (pistol), 0 (m16/m14)
        -- lower means slower
        local recoilDelay = weaitem:getRecoilDelay() 
        local recoilDelayModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.recoilDelayModifier"):getValue() 

        local focusCounterSpeed = getSandboxOptions():getOptionByName("Advanced_trajectory.focusCounterSpeed"):getValue() 
        focusCounterSpeed = focusCounterSpeed - (recoilDelay * recoilDelayModifier)
        
        local focusLevelGained = getSandboxOptions():getOptionByName("Advanced_trajectory.focusLevel"):getValue() 
        local focusCounterSpeedScaleModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.focusCounterSpeedScaleModifier"):getValue() 
        local hasFocusSkill = true

        --if realLevel >= focusLevelGained then
        --    hasFocusSkill = true
        --end

        local focusLimit = 0

        -- focusCounterSpeed scales with flat buff
        if realLevel > focusLevelGained then
            focusCounterSpeed = focusCounterSpeed + (((realLevel-focusLevelGained) * focusCounterSpeedScaleModifier) / 10)
        end

        if realLevel < focusLevelGained then
            focusLimit = focusLimit + 20/(realLevel+1)
        end

        ------------------------
        -- MOODLE LEVELS SECT--
        ------------------------
        -- level 0 to 4 (least to severe)
        local stressLv      = player:getMoodles():getMoodleLevel(MoodleType.Stress) -- inc minaimnum
        local enduranceLv   = player:getMoodles():getMoodleLevel(MoodleType.Endurance) -- inc minaimnum, dec aim speed
        local panicLv       = player:getMoodles():getMoodleLevel(MoodleType.Panic) -- transparency
        local drunkLv       = player:getMoodles():getMoodleLevel(MoodleType.Drunk) -- scaling and pos
        local painLv        = player:getMoodles():getMoodleLevel(MoodleType.Pain)
        
        local hyperLv   = player:getMoodles():getMoodleLevel(MoodleType.Hyperthermia) -- dec aim speed
        local hypoLv    = player:getMoodles():getMoodleLevel(MoodleType.Hypothermia) -- dec aim speed
        local tiredLv   = player:getMoodles():getMoodleLevel(MoodleType.Tired) -- dec aim speed

        local heavyLv   = player:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) -- add bloom


         -- Main purpose is to nerf lv 10 when exhausted
        if enduranceLv > 0 then    
            realMin = realMin + 6    
            Advanced_trajectory.maxaimnum = Advanced_trajectory.maxaimnum + enduranceLv*2
        end
        -----------------------------------
        --TRUE CROUCH/CRAWL (FIRST) SECT---
        -----------------------------------
        if player:getVariableBoolean("IsCrouchAim") and not hasFocusSkill then
            realMin = realMin - 15
        end

        if player:getVariableBoolean("isCrawling") and not hasFocusSkill then
            realMin = realMin - 25
        end

        --------------------------------
        ---TARGET DISTANCE LIMIT SECT---
        --------------------------------
        getTargetDistance(player)
        local enableDistanceLimitPenalty  = getSandboxOptions():getOptionByName("Advanced_trajectory.enableDistanceLimitPenalty"):getValue() 
        local distanceFocusPenalty  = getSandboxOptions():getOptionByName("Advanced_trajectory.distanceFocusPenalty"):getValue() 
 
        local shotgunDistanceModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunDistanceModifier"):getValue()

        local maxDistance = getSandboxOptions():getOptionByName("Advanced_trajectory.bulletdistance"):getValue() * weaitem:getMaxRange()

        if getIsHoldingShotgun(weaitem) then
            --print("Holding shotgun")
            maxDistance = maxDistance * shotgunDistanceModifier
        end

        maxDistance = math.floor(modEffectsTable[4] + maxDistance)
        
        --local distanceLimit = (maxDistance * distanceLimitPenalty) + ((maxDistance * (1-distanceLimitPenalty)) * realLevel/10)
        local distanceLimit = maxDistance * realLevel/10
        
        local targetDist = Advanced_trajectory.targetDistance

        print("target / maxDistance / limit: ", targetDist, " || ", maxDistance, " || ", distanceLimit)

        if targetDist > maxDistance then
            targetDist = maxDistance
            Advanced_trajectory.isOverDistanceLimit = true  
        else
            Advanced_trajectory.isOverDistanceLimit = false
        end



        -- PANIC SECT -- 
        ----------------
        -- panic causes shakiness and penalty for aiming at farther targets is increased
        local panicPenaltyModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.panicPenaltyModifier"):getValue() 
        local panicVisualModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.panicVisualModifier"):getValue() 
        if panicLv > 1 then
            Advanced_trajectory.panicEffect = panicVisualModifier * panicLv
            distanceFocusPenalty = distanceFocusPenalty * panicPenaltyModifier * panicLv
            distanceLimit = distanceLimit * ((4-panicLv)/5)
        else
            Advanced_trajectory.panicEffect = 0
        end




        if targetDist > distanceLimit then
            if enableDistanceLimitPenalty and (maxDistance - distanceLimit > 0) then
                focusLimit = focusLimit + (((targetDist-distanceLimit)*distanceFocusPenalty*reversedLevel) / (maxDistance-distanceLimit))
            end
        end

        -------------------------
        ------ STRESS SECT ------
        -------------------------
        local stressBloomModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.stressBloomModifier"):getValue() 
        local stressVisualModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.stressVisualModifier"):getValue() 
        -- no effects for lv 1 stress
        if stressLv > 1 then
            Advanced_trajectory.stressEffect = stressVisualModifier * stressLv
        else
            Advanced_trajectory.stressEffect = 0
        end

        if stressLv > 1 and realLevel < 3 then
            realMin = realMin + (stressBloomModifier * stressLv)
        end

        if stressLv > 1 and hasFocusSkill then
            focusLimit = focusLimit + 6 * (stressLv-1)
        end

        --print('realMin: ', realMin)

        ----------------------
        ---DRUNK/HEAVY SECT---
        ----------------------
        local drunkMaxBloomModifier     = getSandboxOptions():getOptionByName("Advanced_trajectory.drunkMaxBloomModifier"):getValue() 
        local heavyMaxBloomModifier     = getSandboxOptions():getOptionByName("Advanced_trajectory.heavyMaxBloomModifier"):getValue() 
        Advanced_trajectory.maxaimnum   = Advanced_trajectory.maxaimnum + (drunkLv*drunkMaxBloomModifier) + (heavyLv*heavyMaxBloomModifier)

        ----------------------------
        -- HYPER, HYPO, TIRED SECT--
        ----------------------------
        -- SPEED EFFECTS (must be greater than 0, higher number means less effect)
        -- considering that you can only get hypo or hyper, there are mainly 2 moodles that can stack (temp and tired)
        -- can either stack to -100% if full severity with 0s
        -- all 1s mean stack -66%
        -- all 0s mean stack -100%
        local hyperHypoModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.hyperHypoModifier"):getValue() 
        local tiredModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.tiredModifier"):getValue() 

        -- with default modifiers of 1, it should total up to 1
        local speed = getSandboxOptions():getOptionByName("Advanced_trajectory.reducespeed"):getValue() 
        local reduceSpeed = speed 

        -- needs to subtract at most 1/3 --> 1/(x-4) = 1/3
        -- no effects for lv 1 temp serverity
        if hyperLv > 1 then
            reduceSpeed = reduceSpeed * (hyperHypoModifier  - ((hyperLv - 2) / 5))
        end

        if hypoLv > 1 then
            reduceSpeed = reduceSpeed * (hyperHypoModifier  - ((hypoLv - 2) / 5))
        end

        if tiredLv > 0 then
            reduceSpeed = reduceSpeed * (tiredModifier      - ((tiredLv - 1) / 8))
        end

        ----------------------------
        -- ARMS, HANDS DAMAGE SECT--
        ----------------------------
        local bodyDamage = player:getBodyDamage()

        -- PAIN VARIABLES float values (0 - 200)
        -- 30 lv1, 50 lv2, 100 lv3, 150-200 lv 4
        -- def reduceSpeed for all aim levels: 1.1
        local handPainL = bodyDamage:getBodyPart(BodyPartType.Hand_L):getPain()   
        local forearmPainL = bodyDamage:getBodyPart(BodyPartType.ForeArm_L):getPain()  
        local upperarmPainL = bodyDamage:getBodyPart(BodyPartType.UpperArm_L):getPain()  

        local handPainR = bodyDamage:getBodyPart(BodyPartType.Hand_R):getPain()  
        local forearmPainR = bodyDamage:getBodyPart(BodyPartType.ForeArm_R):getPain()  
        local upperarmPainR = bodyDamage:getBodyPart(BodyPartType.UpperArm_R):getPain()  

        local totalArmPain = handPainL + forearmPainL + upperarmPainL + handPainR + forearmPainR + upperarmPainR
        
        local painModifider = getSandboxOptions():getOptionByName("Advanced_trajectory.painModifier"):getValue() 

        if totalArmPain > 200 then
            totalArmPain = 200
        end

        -- limits how small minaimnum can go (affected by pain/stress)
        if totalArmPain >= 39 and painLv > 1 then
            if hasFocusSkill then
                if painLv == 2 then
                    focusLimit = focusLimit + 6
                else
                    focusLimit = focusLimit + 6 * (0.5 + totalArmPain/50)
                end
            end

            reduceSpeed =  reduceSpeed * (1 - (painModifider * (0.5+totalArmPain/50)))

            Advanced_trajectory.painEffect = getSandboxOptions():getOptionByName("Advanced_trajectory.painVisualModifier"):getValue() 
        else
            Advanced_trajectory.painEffect = 0
        end

        ------------------------
        -- SNEEZE, COUGH SECT---
        ------------------------
        -- returns 1 (sneeze) or 2 (cough)  
        local isSneezeCough = bodyDamage:getSneezeCoughActive() 
        local coughModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.coughModifier"):getValue() 

        -- COUGHING: Add onto aimnum, adds way too much for some reason (goes over maxaimnum ex. goes to 64 when max is 50)
        -- use gametime or else value goes wild (value would be added through framerate and not gametimewhich is not accurate)
        --print("coughEffect: ", coughEffect)
        if isSneezeCough == 2 then
            if Advanced_trajectory.aimnum < Advanced_trajectory.maxaimnum then
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + coughModifier*gametimemul
            end
            Advanced_trajectory.maxFocusCounter = 100
        end

        -- SNEEEZING: Reset aimnum
        if isSneezeCough == 1 then
            if Advanced_trajectory.aimnum < Advanced_trajectory.maxaimnum then
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + 4*gametimemul
            end
            Advanced_trajectory.maxFocusCounter = 100
        end

        ------------------------ ------------------------ ------------------------ 
        -- AIMNUM LIMITER SECT [ALL REALMIN CHANGES MUST BE DONE BEFORE THIS LINE]-
        ------------------------ ------------------------ ------------------------ 
        if realMin < focusLimit then
            realMin = realMin + (focusLimit - realMin)
        end

        -- if counter is not used, keep minaimnum as is
        if Advanced_trajectory.maxFocusCounter >= 100 and Advanced_trajectory.minaimnum ~= realMin  then
            Advanced_trajectory.minaimnum = Advanced_trajectory.minaimnum + 2*gametimemul
            if Advanced_trajectory.minaimnum > realMin then
                Advanced_trajectory.minaimnum = realMin
            end
        end

        if Advanced_trajectory.minaimnum > Advanced_trajectory.maxaimnum then
            Advanced_trajectory.minaimnum = Advanced_trajectory.maxaimnum
        end
        
        ----------------------------------
        -----RELOADING AND RACKING SECT---
        ----------------------------------
        local reloadlevel = 11-player:getPerkLevel(Perks.Reload)
        local reloadEffectModifier =  getSandboxOptions():getOptionByName("Advanced_trajectory.reloadEffectModifier"):getValue() 
        if player:getVariableBoolean("isUnloading") or player:getVariableBoolean("isLoading") or player:getVariableBoolean("isLoadingMag") or player:getVariableBoolean("isRacking") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + constantTime*reloadEffectModifier*reloadlevel
            Advanced_trajectory.alpha = Advanced_trajectory.alpha - gametimemul*0.1
            Advanced_trajectory.maxFocusCounter = 100
        end    

        

        ----------------------------
        -----PENALIZE CROUCH SECT---
        ----------------------------
        local isCrouching = player:getVariableBoolean("IsCrouchAim")
        local heavyTurnEffectModifier   = getSandboxOptions():getOptionByName("Advanced_trajectory.heavyTurnEffectModifier"):getValue() 

        -- Need to check if mod is enabled or not to be safe
        if isCrouching ~= nil then
            local crouchCounterSpeed      = getSandboxOptions():getOptionByName("Advanced_trajectory.crouchCounterSpeed"):getValue() 
            local crouchPenaltyModifier   = getSandboxOptions():getOptionByName("Advanced_trajectory.crouchPenaltyModifier"):getValue() 
    
            local crouchPenaltyEffect = crouchPenaltyModifier
    
            if heavyLv > 0 then
                crouchPenaltyEffect = crouchPenaltyEffect + (heavyLv * heavyTurnEffectModifier)
            end

            -- TF of FT, then player is switching stance
            -- if TT or FF, then player is at stance
            if (isCrouching ~= Advanced_trajectory.isCrouch) and (Advanced_trajectory.crouchCounter <= 0) then
                --print("***CURRENTLY SWITCHING STANCE (CROUCH)****")
                Advanced_trajectory.crouchCounter = 100
            end

            if canRunNGun then
                crouchPenaltyEffect = crouchPenaltyEffect * 0.25
            end

            if Advanced_trajectory.crouchCounter > 0 then
                Advanced_trajectory.crouchCounter = Advanced_trajectory.crouchCounter - crouchCounterSpeed*constantTime
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + constantTime*crouchPenaltyEffect
            end

            -- counter can not go below 0
            if Advanced_trajectory.crouchCounter < 0 then
                Advanced_trajectory.crouchCounter = 0
            end

            -- if counter reaches 0 and the stance has not been confirmed finished, confirm it. Then start focusing.
            if Advanced_trajectory.crouchCounter <= 0 and isCrouching ~= Advanced_trajectory.isCrouch then
                if isCrouching then 
                    Advanced_trajectory.isCrouch = true
                else 
                    Advanced_trajectory.isCrouch = false
                end

                local endurance = player:getStats():getEndurance()
                local staminaCrouchScale = getSandboxOptions():getOptionByName("Advanced_trajectory.staminaCrouchScale"):getValue() 
                local staminaHeavyCrouchScale    = getSandboxOptions():getOptionByName("Advanced_trajectory.staminaHeavyCrouchScale"):getValue() 

                if endurance > 0 then 
                    local effect = staminaCrouchScale * ((heavyLv*staminaHeavyCrouchScale) + 1) * (11 - player:getPerkLevel(Perks.Fitness))
                    player:getStats():setEndurance(player:getStats():getEndurance() - effect)
                end

                Advanced_trajectory.maxFocusCounter = 100
            end

            --print("Crouch counter: ", Advanced_trajectory.crouchCounter)
            --print("AFTER isCrouching | isCrouch: ", isCrouching, " || ", Advanced_trajectory.isCrouch)
        else
            Advanced_trajectory.isCrouch = false
        end

        ------------------
        --PENALIZE CRAWL--
        ------------------
        local isCrawling = player:getVariableBoolean("isCrawling")

        -- Need to check if mod is enabled or not to be safe
        if isCrawling ~= nil then
            if isCrawling ~= Advanced_trajectory.isCrawl then
                --print("***CURRENTLY SWITCHING STANCE (CRAWL)****")
                if isCrawling then 
                    Advanced_trajectory.isCrawl = true
                else 
                    Advanced_trajectory.isCrawl = false
                end

                local endurance = player:getStats():getEndurance()
                local staminaCrawlScale         = getSandboxOptions():getOptionByName("Advanced_trajectory.staminaCrawlScale"):getValue() 
                local staminaHeavyCrawlScale    = getSandboxOptions():getOptionByName("Advanced_trajectory.staminaHeavyCrawlScale"):getValue() 
                if endurance > 0 then 
                    local effect = staminaCrawlScale * ((heavyLv * staminaHeavyCrawlScale) + 1) * (11 - player:getPerkLevel(Perks.Fitness))
                    player:getStats():setEndurance(player:getStats():getEndurance() - effect)
                end
            end
        else
            Advanced_trajectory.isCrawl = false
        end


        ----------------------------
        -- TURNING AND MOVING SECT--
        ----------------------------
        local runNGunMultiplierBuff = 1
        if canRunNGun then
            runNGunMultiplierBuff = 0.25
        end

        local drunkActionEffectModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.drunkActionEffectModifier"):getValue() 
        if player:getVariableBoolean("isMoving") then
            local totalMoveEffect = getSandboxOptions():getOptionByName("Advanced_trajectory.moveeffect"):getValue() * runNGunMultiplierBuff * ((drunkLv*drunkActionEffectModifier)+1) * (heavyLv * heavyTurnEffectModifier + 1)
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + gametimemul * totalMoveEffect
            Advanced_trajectory.maxFocusCounter = 100
        end
        

        local turningEffect = gametimemul * getSandboxOptions():getOptionByName("Advanced_trajectory.turningeffect"):getValue() * (drunkLv * drunkActionEffectModifier + 1) * (heavyLv * heavyTurnEffectModifier + 1)
        if player:getVariableBoolean("isTurning") then
            if Advanced_trajectory.isCrouch then
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + turningEffect * getSandboxOptions():getOptionByName("Advanced_trajectory.crouchTurnEffect"):getValue() * runNGunMultiplierBuff

            elseif Advanced_trajectory.isCrawl  then
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + turningEffect * getSandboxOptions():getOptionByName("Advanced_trajectory.proneTurnEffect"):getValue()  * runNGunMultiplierBuff
            
            else
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + turningEffect * runNGunMultiplierBuff
            end
            Advanced_trajectory.maxFocusCounter = 100
        end

        --------------------------------------------
        --REDUCESPEED/AIMINGTIME ATTACHMENT EFFECT--
        --------------------------------------------
        local reduceSpeedMod = modEffectsTable[1]
        if reduceSpeedMod ~= 0 then
            reduceSpeed = reduceSpeed + reduceSpeedMod
        end

        if Advanced_trajectory.isCrouch then
            reduceSpeed = reduceSpeed + getSandboxOptions():getOptionByName("Advanced_trajectory.crouchReduceSpeedBuff"):getValue() 
        end

        if Advanced_trajectory.isCrawl  then
            reduceSpeed = reduceSpeed + getSandboxOptions():getOptionByName("Advanced_trajectory.proneReduceSpeedBuff"):getValue() 
        end

        local minReduceSpeed = 0.1
        if reduceSpeed < minReduceSpeed then
            reduceSpeed = minReduceSpeed
        end 

        if Advanced_trajectory.aimnum > Advanced_trajectory.minaimnum then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum - gametimemul*reduceSpeed
        end
        ----------------------------
        ------- AIMNUM LIMIT SECT---
        ----------------------------
        if Advanced_trajectory.aimnum > Advanced_trajectory.maxaimnum then
            Advanced_trajectory.aimnum = Advanced_trajectory.maxaimnum
        end

        if Advanced_trajectory.aimnum < Advanced_trajectory.minaimnum then
            Advanced_trajectory.aimnum = Advanced_trajectory.minaimnum
        end
        
        ---------------------------------------------------
        --FOCUSCOUNTERSPEED/HITCHANCE ATTACHMENT EFFECT----
        ---------------------------------------------------
        focusCounterSpeedMod = modEffectsTable[2]
        if focusCounterSpeedMod ~= 0 then
            focusCounterSpeed = focusCounterSpeed + focusCounterSpeedMod
        end

        -- Prone stance means faster focus time
        local proneFocusCounterSpeedBuff = getSandboxOptions():getOptionByName("Advanced_trajectory.proneFocusCounterSpeedBuff"):getValue() 
        if Advanced_trajectory.isCrawl and hasFocusSkill then
            focusCounterSpeed = focusCounterSpeed * 1.5
            focusLimit = focusLimit * getSandboxOptions():getOptionByName("Advanced_trajectory.proneFocusLimitBuff"):getValue() 
        end

        if Advanced_trajectory.isCrouch and hasFocusSkill then
            focusLimit = focusLimit * getSandboxOptions():getOptionByName("Advanced_trajectory.crouchFocusLimitBuff"):getValue() 
        end

        -- crouching means no need to wait to get to 0 when below minaimnum (helpful when bursting)
        if hasFocusSkill then
            if Advanced_trajectory.isCrouch and Advanced_trajectory.aimnum < (realLevel*1.5 - (recoilDelay*2)/10) then
                    Advanced_trajectory.maxFocusCounter = 0
            
            elseif Advanced_trajectory.isCrawl and Advanced_trajectory.aimnum < (realLevel*1.75 - (recoilDelay*2)/10) then
                    Advanced_trajectory.maxFocusCounter = 0
            end
        end

        -- player unlocks max focus skill when reaching certain level
        if Advanced_trajectory.aimnum <= Advanced_trajectory.minaimnum and Advanced_trajectory.maxFocusCounter > 0 and hasFocusSkill then
            Advanced_trajectory.maxFocusCounter = Advanced_trajectory.maxFocusCounter - focusCounterSpeed*constantTime
        end

        -- counter can not go below 0
        if Advanced_trajectory.maxFocusCounter < 0 then
            Advanced_trajectory.maxFocusCounter = 0
        end

        -- if counter reaches 0, reduce minaimnum until its no longer greater than 0
        if Advanced_trajectory.maxFocusCounter <= 0  and Advanced_trajectory.minaimnum > focusLimit then
            Advanced_trajectory.minaimnum = Advanced_trajectory.minaimnum - gametimemul*maxFocusSpeed
        end

        --print('maxFocusCounter: ', Advanced_trajectory.maxFocusCounter)

        if focusLimit > Advanced_trajectory.maxaimnum then
            focusLimit = Advanced_trajectory.maxaimnum
        end

        if Advanced_trajectory.minaimnum < focusLimit then
            Advanced_trajectory.minaimnum = Advanced_trajectory.minaimnum + gametimemul

            if Advanced_trajectory.minaimnum > focusLimit then
                Advanced_trajectory.minaimnum = focusLimit
            end
        end

        ------------------------
        ----- ENDURANCE SECT----
        ------------------------

        local enduranceBreathModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.enduranceBreathModifier"):getValue() 
        local inhaleModifier1 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier1"):getValue() 
        local inhaleModifier2 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier2"):getValue() 
        local inhaleModifier3 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier3"):getValue() 
        local inhaleModifier4 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier4"):getValue() 

        local exhaleModifier1 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier1"):getValue() 
        local exhaleModifier2 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier2"):getValue() 
        local exhaleModifier3 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier3"):getValue() 
        local exhaleModifier4 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier4"):getValue() 

        if enduranceLv > 0 and Advanced_trajectory.aimnum <= Advanced_trajectory.minaimnum+5+(enduranceLv*3) and Advanced_trajectory.inhaleCounter <= 0 and Advanced_trajectory.exhaleCounter <= 0 then
            Advanced_trajectory.inhaleCounter = 100
            reduceSpeed = reduceSpeed * (1 - enduranceLv*7/100)
        end

        -- inhale, count from 100 to 0
        if Advanced_trajectory.inhaleCounter > 0 then

            -- three diff levels of inhale and exhale speed
            if enduranceLv == 1 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier1*constantTime
            end
            if enduranceLv == 2 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier2*constantTime
            end
            if enduranceLv == 3 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier3*constantTime
            end
            if enduranceLv == 4 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier4*constantTime
            end

            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + enduranceBreathModifier * constantTime
        
            -- exhale, steady aim
        elseif Advanced_trajectory.exhaleCounter > 0 then

            -- higher endurance level means less time to have steady aim
            -- three diff levels of inhale and exhale speed
            if enduranceLv == 1 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier1*constantTime
            end
            if enduranceLv == 2 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier2*constantTime
            end
            if enduranceLv == 3 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier3*constantTime
            end
            if enduranceLv == 4 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier4*constantTime
            end

        elseif Advanced_trajectory.inhaleCounter <= 0 and Advanced_trajectory.exhaleCounter <= 0 then
            Advanced_trajectory.exhaleCounter = 100
        end
      
        if enduranceLv == 0 then
            Advanced_trajectory.inhaleCounter = 0
            Advanced_trajectory.exhaleCounter = 0
        end

        --print("inhaleCounter / exhaleCounter: ", Advanced_trajectory.inhaleCounter, " / ", Advanced_trajectory.exhaleCounter)

        -------------------------------
        -------- PANIC (END) SECT-----
        -------------------------------
        -- needs to be between max and min or else crosshair just disappears if ur aim is dog
        -- place after other minaimnum effects

        --[[
        local limit = 0
        if panicLv == 4 then
            limit = 10
        elseif panicLv == 3 then
            limit = Advanced_trajectory.maxaimnum * 0.25
        else
            limit = Advanced_trajectory.maxaimnum * 0.5
        end

        if panicLv > 1 then
            if Advanced_trajectory.aimnum <= limit then
                Advanced_trajectory.alpha = Advanced_trajectory.alpha + gametimemul*0.05
            else
                Advanced_trajectory.alpha = Advanced_trajectory.alpha - gametimemul*0.1
            end
        else
            Advanced_trajectory.alpha = Advanced_trajectory.alpha + gametimemul*0.025
        end
        ]]
        
        -- Purpose is to keep crosshair visible
        Advanced_trajectory.alpha = Advanced_trajectory.alpha + gametimemul*0.025

        if Advanced_trajectory.alpha > 0.6 then
            Advanced_trajectory.alpha = 0.6
        end

        if Advanced_trajectory.alpha < 0 then
            Advanced_trajectory.alpha = 0
        end

        --print("Trans/Alpha: ", Advanced_trajectory.alpha)
        --print("Shaky Effect: ", Advanced_trajectory.stressEffect + Advanced_trajectory.painEffect + Advanced_trajectory.panicEffect)
        --print("totalArmPain [arms]: ", totalArmPain, ", HL", handPainL ,", FL", forearmPainL ,", UL", upperarmPainL ,", HR", handPainR ,", FR", forearmPainR ,", UR", upperarmPainR)
        --print("isSneezeCough: ", isSneezeCough)
        --print("P", panicLv, ", E", enduranceLv ,", H", hyperLv ,", H", hypoLv ,", S", stressLv,", T", tiredLv)
        --print("Aim Level (code): ", reversedLevel)
        --print("Aim Level (real): ", realLevel)
        --print("Def/Curr ReduceSpeed: ", speed, "/", reduceSpeed)
        --print("FocusCounterSpeed: ", focusCounterSpeed)
        --print("FocusLimit/Min/Max/Aimnum: ", focusLimit, " / ", Advanced_trajectory.minaimnum, " / ", Advanced_trajectory.maxaimnum, " / ", Advanced_trajectory.aimnum)   
        --------------------------------------------------------------------
        if not Advanced_trajectory.panel.instance and getSandboxOptions():getOptionByName("Advanced_trajectory.aimpoint"):getValue() then
            Advanced_trajectory.panel.instance = Advanced_trajectory.panel:new(0, 0, 200, 200)
            Advanced_trajectory.panel.instance:initialise()
            Advanced_trajectory.panel.instance:addToUIManager()
        end

        local isspwaepon = Advanced_trajectory.Advanced_trajectory[weaitem:getFullType()]

        if weaitem:getSwingAnim() =="Throw"  or (isspwaepon and isspwaepon["islightsq"]) then

            weaitem:setPhysicsObject(nil)  
            weaitem:setMaxHitCount(0)

            --getPlayer():getPrimaryHandItem():getSmokeRange()

            if not Advanced_trajectory.aimcursor then
                -- Advanced_trajectory.thorwerinfo = {
                --     weaitem:getSmokeRange(),
                --     weaitem:getExplosionPower(),
                --     weaitem:getExplosionRange(),
                --     weaitem:getFirePower(),
                --     weaitem:getFireRange()
                -- }
                Advanced_trajectory.aimcursor = ISThorowitemToCursor:new("", "", player,weaitem)
                getCell():setDrag(Advanced_trajectory.aimcursor, 0)
            end
        end


        -- Get the scaled mouse coordinates
        local mouseX = getMouseXScaled()
        local mouseY = getMouseYScaled()

        -- Get the player's Z position and player number
        local playerZ = math.floor(player:getZ())
        local playerX = math.floor(player:getX())
        local playerY = math.floor(player:getY())
        local playerNum = player:getPlayerNum()

        -- Initialize a flag to check if we are aiming at an object
        local isAimingObject = false

        -- Loop through Z levels from 0 to 7
        for Z = 0, 7 do
            -- Calculate the distance difference between Z level and player's Z position
            local delDis = Z - playerZ

            -- Calculate world coordinates adjusted for the Z level
            local wx, wy = ISCoordConversion.ToWorld(mouseX - 3 * delDis, mouseY - 3 * delDis, Z)
            wx, wy = math.floor(wx), math.floor(wy)

            -- Get the current world cell
            local cell = getWorld():getCell()

            -- Iterate through nearby Y and Z offsets
            for yz = -1, 1 do
                for lz = -1, 1 do
                    -- Get the grid square at the adjusted position
                    local sq = cell:getGridSquare(wx + 2.2 + yz, wy + 2.2 + lz, Z)

                    -- Check if the grid square is valid and can be seen by the player
                    if sq and sq:isCanSee(playerNum) then
                        local movingObjects = sq:getMovingObjects()

                        -- Iterate through moving objects in the grid square
                        for zz = 1, movingObjects:size() do
                            local zombie = movingObjects:get(zz - 1)

                            -- Check if the object is an IsoZombie or IsoPlayer
                            if instanceof(zombie, "IsoZombie") or instanceof(zombie, "IsoPlayer") then
                                -- Set the aim level and flag, then return
                                Advanced_trajectory.aimlevels = Z
                                isAimingObject = true
                                return
                            end
                        end

                    -- make exception if bullet and player are on the same floor to prevent issue with blindness
                    elseif sq and Z == playerZ then
                        local movingObjects = sq:getMovingObjects()

                        for zz = 1, movingObjects:size() do
                            local zombie = movingObjects:get(zz - 1)

                            if instanceof(zombie, "IsoZombie") or instanceof(zombie, "IsoPlayer") then
                                Advanced_trajectory.aimlevels = Z
                                isAimingObject = true   
                                return
                            end
                        end
                    end
                end
            end
        end

        --print("Aim Level", Advanced_trajectory.aimlevels)

        -- If no object is aimed at, reset the aim level
        if not isAimingObject then
            Advanced_trajectory.aimlevels = nil
        end

        -- print(Advanced_trajectory.aimlevels)
         
        
    else 
        if Advanced_trajectory.aimcursor then
            getCell():setDrag(nil, 0);
            Advanced_trajectory.aimcursor=nil
            Advanced_trajectory.thorwerinfo={}
        end
        if Advanced_trajectory.panel.instance then
            Advanced_trajectory.panel.instance:removeFromUIManager()
            Advanced_trajectory.panel.instance=nil
        end
        local constantTime = getGameTime():getMultiplier() * 16/(1+10)
        local nonAdsEffect = 2
        Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + constantTime
        Advanced_trajectory.maxFocusCounter = 100
        Advanced_trajectory.alpha = 0
    end
    
end

function getTargetDistance(player)
        local mouseX = getMouseXScaled()
        local mouseY = getMouseYScaled()

        local playerX = math.floor(player:getX())
        local playerY = math.floor(player:getY())
        local playerZ = math.floor(player:getZ())
        
        local wx, wy = ISCoordConversion.ToWorld(mouseX, mouseY, playerZ)
        wx, wy = math.floor(wx) + 2, math.floor(wy) + 2

        Advanced_trajectory.targetDistance = (math.sqrt((playerX - wx)^2 + (playerY - wy)^2))

        --print("Player X/Y || MouseX/Y: ", playerX," / ",playerY, " || ", wx," / ",wy)
        --print("Target Distance: ", Advanced_trajectory.targetDistance)
end

Advanced_trajectory.damagedisplayer = {}

function checkBowAndCrossbow(player, Zombie)
    ------------------------------------------------------------------------------
    ------COMPATABILITY FOR BRITA'S BOWS AND CROSSBOWS (CREDITS TO LISOLA/BRITA)---------
    ------------------------------------------------------------------------------
    local weaitem = player:getPrimaryHandItem()

    local proj  = ""
    local isBow = false
    local broke = false
    if string.contains(weaitem:getAmmoType() or "","Arrow_Fiberglass") then
        proj  = InventoryItemFactory.CreateItem("Arrow_Fiberglass")
        isBow = true
    end

    if string.contains(weaitem:getAmmoType() or "","Bolt_Bear") then
        proj  = InventoryItemFactory.CreateItem("Bolt_Bear")
        isBow = true
    end

    local bowBreakChance = 100 - getSandboxOptions():getOptionByName("Advanced_trajectory.bowBreakChance"):getValue()
    if isBow and ZombRand(100+Advanced_trajectory.aimnumBeforeShot) >= bowBreakChance then
        proj  = InventoryItemFactory.CreateItem(proj:getModData().Break)
        broke = true
    end

    if isBow then
        if isClient() then
            sendClientCommand("ATY_bowzombie", "attachProjZombie", {player:getOnlineID(), Zombie:getOnlineID(), {Zombie:getX(), Zombie:getY(), Zombie:getZ()}, proj, broke})
        end

        if Zombie and Zombie:isAlive() then
            if Zombie:getModData().stuck_Body01 == nil then
                Zombie:setAttachedItem("Stuck Body01", proj)
                Zombie:getModData().stuck_Body01 = 1
            elseif	Zombie:getModData().stuck_Body02 == nil then
                Zombie:setAttachedItem("Stuck Body02", proj)
                Zombie:getModData().stuck_Body02 = 1
            elseif	Zombie:getModData().stuck_Body03 == nil then
                Zombie:setAttachedItem("Stuck Body03", proj)
                Zombie:getModData().stuck_Body03 = 1
            elseif	Zombie:getModData().stuck_Body04 == nil then
                Zombie:setAttachedItem("Stuck Body04", proj)
                Zombie:getModData().stuck_Body04 = 1
            elseif	Zombie:getModData().stuck_Body05 == nil then
                Zombie:setAttachedItem("Stuck Body05", proj)
                Zombie:getModData().stuck_Body05 = 1
            elseif	Zombie:getModData().stuck_Body06 == nil then
                Zombie:setAttachedItem("Stuck Body06", proj)
                Zombie:getModData().stuck_Body06 = 1
            else
                Zombie:getCurrentSquare():AddWorldInventoryItem(proj, 0.0, 0.0, 0.0)
            end
        else
            Zombie:getInventory():AddItem(proj)
        end
    end
end

function displayDamageOnZom(damagezb, Zombie)
    local damagea = TextDrawObject.new()
    damagea:setDefaultColors(1,1,0.1,0.7)
    damagea:setOutlineColors(0,0,0,1)
    damagea:ReadString(UIFont.Middle, "-" ..tostring(math.floor(damagezb*100)), -1)
    local sx = IsoUtils.XToScreen(Zombie:getX(), Zombie:getY(), Zombie:getZ(), 0);
    local sy = IsoUtils.YToScreen(Zombie:getX(), Zombie:getY(), Zombie:getZ(), 0);
    sx = sx - IsoCamera.getOffX() - Zombie:getOffsetX();
    sy = sy - IsoCamera.getOffY() - Zombie:getOffsetY();
    sy = sy - 64
    sx = sx / getCore():getZoom(0)
    sy = sy / getCore():getZoom(0)
    sy = sy - damagea:getHeight()

    table.insert(Advanced_trajectory.damagedisplayer,{60,damagea,sx,sy,sx,sy})
end

function searchAndDmgClothing(player, shotpart)

    local hasBulletProof= false
    local playerWornInv = player:getWornItems();

    -- use this to compare shot part and covered part
    local nameShotPart = BodyPartType.getDisplayName(shotpart)

    -- use this to find coveredPart
    local strShotPart = BodyPartType.ToString(shotpart)

    local shotBloodPart = nil

    local shotBulletProofItems = {}
    local shotNormalItems = {}

    for i=0, playerWornInv:size()-1 do
        local item = playerWornInv:getItemByIndex(i);

        if item and instanceof(item, "Clothing") then
            local listBloodClothTypes = item:getBloodClothingType()

            -- arraylist of BloodBodyPartTypes
            local listOfCoveredAreas = BloodClothingType.getCoveredParts(listBloodClothTypes)   
    
            -- size of list
            local areaCount = BloodClothingType.getCoveredPartCount(listBloodClothTypes)   
    
            for i=0, areaCount-1 do
                -- returns BloodBodyPartType
                local coveredPart = listOfCoveredAreas:get(i)
                local nameCoveredPart = coveredPart:getDisplayName()
    
                if nameCoveredPart == nameShotPart then
                    shotBloodPart = coveredPart
                    
                    -- check if has bullet proof armor
                    local bulletDefense = item:getBulletDefense()
                    --print("Bullet Defense: ", bulletDefense)
                    if bulletDefense > 0 then
                        hasBulletProof = true
                        table.insert(shotBulletProofItems, item)
                    else
                        table.insert(shotNormalItems, item)
                    end
                end
            end
        end
    end

    --print("HAS BULLET PROOF: ", hasBulletProof)
    if hasBulletProof then
        for i = 1, #shotBulletProofItems do
            local item = shotBulletProofItems[i]

            -- Minimum reduction value is 1 due to integer type
            item:setCondition(item:getCondition() - 1)          

            --print(item:getName(), "'s MaxCondition / Curr: ", item:getConditionMax(), " / ", item:getCondition())
        end
    else
        for i = 1, #shotNormalItems do
            local item = shotNormalItems[i]

            -- hole is added only if the shot part initially had no hole. added hole means damage to clothing
            -- decided to add holes only so players can still wear their battlescarred clothing
            if item:getHolesNumber() < item:getNbrOfCoveredParts() then
                player:addHole(shotBloodPart, true)
            end

            --print(item:getName(), "'s MaxCondition / Curr: ", item:getConditionMax(), " / ", item:getCondition())
            --print(nameShotPart, " [", item:getName() ,"] clothing damaged.")
        end
    end

    if getSandboxOptions():getOptionByName("Advanced_trajectory.DebugSayShotPart"):getValue() then
        player:Say("Ow! My " .. nameShotPart .. "!")
    end
end

-- function is here for testing through voodoo
function damagePlayershot(player, damage, baseGunDmg, headShotDmg, bodyShotDmg, footShotDmg)
    local highShot = {
        BodyPartType.Head, BodyPartType.Head,
        BodyPartType.Neck
    }
        
    -- chest is biggest target so increase its chances of being wounded; will make vest armor useful
    local midShot = {
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.UpperArm_L, BodyPartType.UpperArm_R,
        BodyPartType.ForeArm_L,  BodyPartType.ForeArm_R,
        BodyPartType.Hand_L,     BodyPartType.Hand_R
    }
    
    local lowShot = {
        BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R,
        BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R,
        BodyPartType.LowerLeg_L, BodyPartType.LowerLeg_R,
        BodyPartType.Foot_L,     BodyPartType.Foot_R,
        BodyPartType.Groin
    }

    local shotpart = BodyPartType.Torso_Upper

    local footChance = 5
    local headChance = 10

    local incHeadChance = 0
    if damage == headShotDmg then
        incHeadChance = getSandboxOptions():getOptionByName("Advanced_trajectory.headShotIncChance"):getValue()
    end

    local incFootChance = 0
    if damage == footShotDmg then
        incFootChance = getSandboxOptions():getOptionByName("Advanced_trajectory.footShotIncChance"):getValue()
    end

    if damage > 0 then

        local randNum = ZombRand(100)

        -- lowShot
        if randNum <= (footChance + incFootChance) then                   
            shotpart = lowShot[ZombRand(#lowShot) + 1]
        
        -- highShot
        elseif randNum > (footChance + incFootChance) and randNum <= (footChance + incFootChance) + (headChance + incHeadChance) then
            shotpart = highShot[ZombRand(#highShot)+1]
        
        -- midShot
        else
            shotpart = midShot[ZombRand(#midShot)+1]
        end

    end

    --print("DmgMult / BaseDmg: ", damage, " / ", baseGunDmg)
    searchAndDmgClothing(player, shotpart)
    
    local bodypart = player:getBodyDamage():getBodyPart(shotpart)

    -- float (part, isBite, isBullet)
    -- bulletdefense is usually 100
    local defense = player:getBodyPartClothingDefense(shotpart:index(),false,true)

    --print("BodyPartClothingDefense: ", defense)

    if defense < 0.5 then
        --print("WOUNDED")
        if bodypart:haveBullet() then
            local deepWound = bodypart:isDeepWounded()
            local deepWoundTime = bodypart:getDeepWoundTime()
            local bleedTime = bodypart:getBleedingTime()
            --bodypart:setHaveBullet(false, 0)
            bodypart:setDeepWoundTime(deepWoundTime)
            bodypart:setDeepWounded(deepWound)
            bodypart:setBleedingTime(bleedTime)
        else
            bodypart:setHaveBullet(true, 0)
        end
        -- Destroy bandage if bandaged
        if bodypart:bandaged() then
            bodypart:setBandaged(false, 0)
        end
    end

    local maxDefense = getSandboxOptions():getOptionByName("Advanced_trajectory.maxDefenseReduction"):getValue()
    if defense > maxDefense then
        defense = maxDefense
    end

    local playerDamageDealt = baseGunDmg*damage*(1-defense)

    player:getBodyDamage():ReduceGeneralHealth(playerDamageDealt)
end

-----------------------------------
-----BODY PART LOGIC FUNC SECT-----
-----------------------------------
function Advanced_trajectory.checkontick()

    Advanced_trajectory.boomontick()
    Advanced_trajectory.OnPlayerUpdate()


    local timemultiplier = getGameTime():getMultiplier()

    for la,lb in pairs(Advanced_trajectory.damagedisplayer) do

        lb[1] = lb[1] - timemultiplier
        if lb[1] < 0 then
            lb = nil
        else

            lb[3] = lb[3] + timemultiplier
            lb[4] = lb[4] - timemultiplier
            lb[2]:AddBatchedDraw(lb[3], lb[4], true)

            -- print(Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5])
            
        end
    
    
    end

    local tablenow = Advanced_trajectory.table
    -- print(#tablenow)
    -- print(getGameTime():getMultiplier())

    for kt, vt in pairs(tablenow) do

        Advanced_trajectory.itemremove(vt[1])

        local tablenowz12_ = vt[12] * 0.35

        -- RADON NOTES: PERHAPS THIS DETERMINES IF BULLET SHOULD DISAPPEAR/BREAK IF COLLIDE WITH SOMETHING
        if Advanced_trajectory.aimlevels then
            vt[2] = getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], Advanced_trajectory.aimlevels)
        else
            vt[2] = getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], vt[4][3])
        end

        vt[22]["pos"] = {Advanced_trajectory.mathfloor(vt[4][1]), Advanced_trajectory.mathfloor(vt[4][2])}


       if vt[2] then
            -- bullet square, dirc, offset, offset, nonsfx
            if Advanced_trajectory.checkiswallordoor(vt[2],vt[5],vt[4],vt[20],vt["nonsfx"]) and not vt[15] then
                --print("***********Bullet collided with wall.************")
                --print("Wallcarmouse: ", vt["wallcarmouse"])
                --print("Wallcarzombie: ", vt["wallcarzombie"])
                --print("Cell: ", vt[4][1],", ",vt[4][2],", ",vt[4][3])
                if  vt[9] =="Grenade" or vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        -- print("Boom")
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                    
                end
                Advanced_trajectory.itemremove(vt[1]) 
                tablenow[kt]=nil
                break
            end

            -- reassign so visual offset of bullet doesn't go whack
            if getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], vt[4][3]) then
                vt[2] = getWorld():getCell():getOrCreateGridSquare(vt[4][1], vt[4][2], vt[4][3])
            end

            local mathfloor = Advanced_trajectory.mathfloor


            vt[1] = Advanced_trajectory.additemsfx(vt[2], vt[14] .. tostring(vt[8]), mathfloor(vt[4][1]), mathfloor(vt[4][2]), mathfloor(vt[4][3]))
            local spnumber = (vt[3][1]^2 + vt[3][2]^2) ^ 0.5* tablenowz12_
            vt[7] = vt[7] - spnumber
            vt[17] = vt[17] + spnumber

            if vt[9] == "flamethrower" then

                -- print(vt[17])
                if vt[17] >3 then
                    vt[17] = 0
                    vt[21]=vt[21]+1
                    vt[4] = Advanced_trajectory.twotable(vt[20])
                end
                -- print(vt[21])
                if vt[21] >4 then
                    Advanced_trajectory.itemremove(vt[1]) 
                    tablenow[kt]=nil
                    break
                end
            
            elseif vt[7]<0 and vt[9] ~= "Grenade"  then

                if vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                end



                Advanced_trajectory.itemremove(vt[1])
                tablenow[kt]=nil
                break
            end


            vt[5] = vt[5] + vt[10]
            if vt[1] then
                vt[1]:setWorldZRotation(vt[5])
            end

            vt[4][1] = vt[4][1]+tablenowz12_ * vt[3][1]
            vt[4][2] = vt[4][2]+tablenowz12_ * vt[3][2]

            if  vt["isparabola"]  then

                vt[4][3] = 0.5-vt["isparabola"]*vt[17]*(vt[17]-vt[18])
                
                if vt[4][3]<=0.3  then
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                    
                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    break
                end

            end

            -- NOTES IMPORTANT, WORK HERE: Headshot, Bodypart, Footpart
            if  (vt[9] ~= "Grenade" or (vt[22][8]or 0) > 0 or vt["wallcarzombie"]) and  not vt["wallcarmouse"] then
                
                -- direction of bullet
                local angleammo = vt[5]

                -- offset of bullet
                local angleammooff = 0

                if angleammo >= 135 and angleammo <= 180 then
                    angleammooff = angleammo - 135
                elseif angleammo >= -180 and angleammo <= -135 then
                    angleammooff = angleammo+180 +45
                elseif angleammo >= -135 and angleammo <= -45 then
                    angleammooff = -angleammo - 45 
                end

                angleammooff = angleammooff / 30
                --print('angleammo: ', angleammo)
                --print('angleammooff: ', angleammooff)
               
                local admindel = vt["animlevels"] - math.floor(vt[4][3])
                local shootlevel =  vt[4][3] + admindel

                if  vt["isparabola"] then
                    
                    shootlevel  = vt[4][3]
                end
                    
                --print('admindel (for x and y): ', admindel)
                --print('shootlevel (z): ', shootlevel)

                local Playershot

                local saywhat = ""

                -- returns object zombie and player that was shot
                local Zombie,Playershot =  Advanced_trajectory.getShootzombie({vt[4][1] + admindel * 3, vt[4][2]  + admindel * 3, shootlevel}, 1 + angleammooff, {vt[20][1], vt[20][2], vt[20][3]})
                
                -- headshot on zombie
                local damagezb = 0

                -- headshot damage multiplier on player (will be multiplied by vt6 in player's if statement)
                local damagepr = 0

                -- steady aim wins the game, else bodyshot damage 
                if Advanced_trajectory.aimnumBeforeShot <= 5 then
                    damagezb = Advanced_trajectory.HeadShotDmgZomMultiplier            -- zombie headshot aka strong headshot
                    damagepr = Advanced_trajectory.HeadShotDmgPlayerMultiplier         -- player headshot aka strong headshot
                    saywhat = "IGUI_Headshot (STRONG): " .. Advanced_trajectory.aimnumBeforeShot
                else
                    damagezb = Advanced_trajectory.BodyShotDmgZomMultiplier            -- zombie bodyshot aka weak headshot
                    damagepr = Advanced_trajectory.BodyShotDmgPlayerMultiplier         -- player bodyshot aka weak headshot
                    saywhat = "IGUI_Headshot (WEAK): " .. Advanced_trajectory.aimnumBeforeShot
                end
                -- vt[4] is offset xyz
                if not Zombie and not Playershot  then
                    Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1] - 0.9 + angleammooff*0.45 + admindel*3, vt[4][2] - 0.9 + angleammooff*0.45 + admindel*3, shootlevel}, 2, {vt[20][1], vt[20][2], vt[20][3]})
                    damagezb = Advanced_trajectory.BodyShotDmgZomMultiplier            -- zombie bodyshot
                    damagepr = Advanced_trajectory.BodyShotDmgPlayerMultiplier         -- player bodyshot
                    saywhat = "IGUI_Bodyshot"
                end
                if not Zombie and not Playershot then
                    Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1] - 1.8 + angleammooff*0.9 + admindel*3, vt[4][2] - 1.8 + angleammooff*0.9 + admindel*3, shootlevel}, 3, {vt[20][1], vt[20][2], vt[20][3]})
                    damagezb = Advanced_trajectory.FootShotDmgZomMultiplier            -- zombie footshot
                    damagepr = Advanced_trajectory.FootShotDmgPlayerMultiplier         -- player footshot
                    saywhat = "IGUI_Footshot"
                end
                
                -------------------------------------
                ---DEAL WITH ALIVE PLAYER WHEN HIT---
                -------------------------------------
                -- NOTES: if it's a non friendly player is shot at, determine damage done and which body part is affected
                -- vt[19] is the player itself (you)
                -- the player shot can not be the client player (you can't shoot you)
                if not vt["nonsfx"] and Playershot and vt[19] and Playershot ~= vt[19] and (Faction.getPlayerFaction(Playershot)~=Faction.getPlayerFaction(vt[19]) or not Faction.getPlayerFaction(Playershot))     then
                    
                    --Playershot:setX(Playershot:getX()+0.15*vt[3][1])
                    --Playershot:setY(Playershot:getY()+0.15*vt[3][2])
                    Playershot:addBlood(100)

                    -- isClient() returns true if the code is being run in MP
                    if isClient() then
                        sendClientCommand("ATY_shotplayer", "true", {vt[19]:getOnlineID(), Playershot:getOnlineID(), damagepr, vt[6], Advanced_trajectory.HeadShotDmgPlayerMultiplier, Advanced_trajectory.BodyShotDmgPlayerMultiplier, Advanced_trajectory.FootShotDmgPlayerMultiplier})
                    else
                        damagePlayershot(Playershot, damagepr, vt[6], Advanced_trajectory.HeadShotDmgPlayerMultiplier, Advanced_trajectory.BodyShotDmgPlayerMultiplier, Advanced_trajectory.FootShotDmgPlayerMultiplier)
                    end

                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    break
                end

                -------------------------------------
                ---DEAL WITH ALIVE ZOMBIE WHEN HIT--
                -------------------------------------
                if Zombie and Zombie:isAlive() then

                    -- If zombies are alive, announce the body part it hits if the advanced trajectory option is enabled
                    if vt[19] and getSandboxOptions():getOptionByName("Advanced_trajectory.callshot"):getValue() then
                        vt[19]:Say(getText(saywhat))
                    end

                    if getSandboxOptions():getOptionByName("Advanced_trajectory.DebugEnableVoodoo"):getValue() then
                        if isClient() then
                            sendClientCommand("ATY_shotplayer", "true", {vt[19]:getOnlineID(), vt[19]:getOnlineID(), damagezb, vt[6]*0.1, Advanced_trajectory.HeadShotDmgZomMultiplier, Advanced_trajectory.BodyShotDmgZomMultiplier, Advanced_trajectory.FootShotDmgZomMultiplier})
                        else
                            damagePlayershot(vt[19], damagezb, vt[6]*0.1, Advanced_trajectory.HeadShotDmgZomMultiplier, Advanced_trajectory.BodyShotDmgZomMultiplier, Advanced_trajectory.FootShotDmgZomMultiplier)
                        end
                    end
                    

                    if vt["wallcarzombie"] or vt[9] == "Grenade"then

                        vt[22]["zombie"] = Zombie
                        if vt[22][2] > 0 then
                            Advanced_trajectory.boomsfx(vt[2])
                        end
                        if not vt["nonsfx"] then
                            Advanced_trajectory.Boom(vt[2], vt[22])
                        end
                        
                        Advanced_trajectory.itemremove(vt[1])
                        tablenow[kt] = nil
                        break

                    elseif not vt["nonsfx"]  then
                        if vt[9] == "flamethrower" then
                            Zombie:setOnFire(true)
    
                            -- Uncomment this section if you want to handle GrenadeLauncher differently
                            -- elseif vt[9] == "GrenadeLauncher" then
                            --     tanksuperboom(vt[2])
                            -- end
                        end
                        
                        if isClient() then
                            sendClientCommand("ATY_cshotzombie","true",{Zombie:getOnlineID(),vt[19]:getOnlineID()})
                        end

                        damagezb = damagezb * vt[6] * 0.1

                        if not Advanced_trajectory.hasFlameWeapon then
                            -- give xp upon hit
                            local hitXP = getSandboxOptions():getOptionByName("Advanced_trajectory.XPHitModifier"):getValue()
                            triggerEvent("OnWeaponHitCharacter", vt[19], Zombie, vt[19]:getPrimaryHandItem(), damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,victim,weapon,damage)
                            if isServer() == false then
                                Events.OnWeaponHitXp.Add(vt[19]:getXp():AddXP(Perks.Aiming, hitXP));
                            end
                        end

                        -- display damage done to zombie from bullet 
                        if getSandboxOptions():getOptionByName("ATY_damagedisplay"):getValue() then
                            displayDamageOnZom(damagezb, Zombie)
                        end

                        -- subtract health from zombie 
                        Zombie:setHealth(Zombie:getHealth()-damagezb)
                        Zombie:setHitReaction("Shot")
                        Zombie:addBlood(getSandboxOptions():getOptionByName("AT_Blood"):getValue())
                        
                        -- if zombie's health is very low, just kill it (recall full health is over 140) and give xp like usual
                        if Zombie:getHealth()<=0.1 then                           
                            -- if zombie's health is very low, just kill it (recall full health is over 140) and give xp like usual                         
                            if vt[19] then
                                if isClient() then
                                    sendClientCommand("ATY_killzombie","true",{Zombie:getOnlineID()})
                                end

                                Zombie:Kill(vt[19])
                                            
                                vt[19]:setZombieKills(vt[19]:getZombieKills()+1)
                                vt[19]:setLastHitCount(1)

                                if not Advanced_trajectory.hasFlameWeapon then
                                    local killXP = getSandboxOptions():getOptionByName("Advanced_trajectory.XPKillModifier"):getValue()
                                    -- multiplier to 0.67
                                    triggerEvent("OnWeaponHitXp",vt[19], vt[19]:getPrimaryHandItem(), Zombie, damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,weapon,victim,damage)
                                
                                    if isServer() == false then
                                        Events.OnWeaponHitXp.Add(vt[19]:getXp():AddXP(Perks.Aiming, killXP));
                                    end
                                end
                            end 
                        end

                        if getSandboxOptions():getOptionByName("Advanced_trajectory.DebugEnableBow"):getValue() then
                            checkBowAndCrossbow(vt[19], Zombie)
                        end
                        
                    end
                    

                    Advanced_trajectory.itemremove(vt[1])

                    -- set penetration to 1 if null, subtract after zombie is hit
                    if not vt["ThroNumber"] then vt["ThroNumber"] = 1 end
                    vt["ThroNumber"] = vt["ThroNumber"]-1

                    -- reduce damage after penetration
                    local penDmgReduction = getSandboxOptions():getOptionByName("Advanced_trajectory.penDamageReductionMultiplier"):getValue()
                    vt[6] = penDmgReduction * vt[6]

                    -- break if iscantthrough and penetration is 0
                    if not vt[11] and (vt["ThroNumber"] <= 0  )then
                        tablenow[kt]=nil
                        break
                        
                    end  
                end
  
            end  
        end

    end

    -- print(Advanced_trajectory.table == tablenow)

    -- Advanced_trajectory.table =  tablenow
end

Events.OnTick.Add(Advanced_trajectory.checkontick)

function determineHitOrMiss(isHoldingShotgun) 
    local player = getPlayer()
    local aimingLevel = player:getPerkLevel(Perks.Aiming)

    local buff = 0
    if isHoldingShotgun then
        buff = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunHitBuff"):getValue()
    end

    local hitLevelScaling = getSandboxOptions():getOptionByName("Advanced_trajectory.hitLevelScaling"):getValue()
    local missMin = getSandboxOptions():getOptionByName("Advanced_trajectory.missMin"):getValue()
    local missMax = getSandboxOptions():getOptionByName("Advanced_trajectory.missMax"):getValue()

    local randNum = ZombRandFloat(missMin + aimingLevel*hitLevelScaling + buff, missMax) 

    local enableAnnounce = getSandboxOptions():getOptionByName("Advanced_trajectory.announceHitOrMiss"):getValue()
    if Advanced_trajectory.aimnumBeforeShot > randNum then
        Advanced_trajectory.missedShot = true
        if enableAnnounce then
            player:Say(getText("Missed: " .. Advanced_trajectory.aimnumBeforeShot .. " > " .. randNum))
        end
    else
        Advanced_trajectory.missedShot = false
        if enableAnnounce then
            player:Say(getText("Hit: " .. Advanced_trajectory.aimnumBeforeShot .. " <= " .. randNum))
        end
    end
end

function getIsHoldingShotgun(weapon)
    if (string.contains(weapon:getAmmoType() or "","Shotgun") or string.contains(weapon:getAmmoType() or "","shotgun") or string.contains(weapon:getAmmoType() or "","shell") or string.contains(weapon:getAmmoType() or "","Shell")) then
        return true
    end

    return false
end

-----------------------------------
--SHOOTING PROJECTILE FUNC SECT---
-----------------------------------
function Advanced_trajectory.OnWeaponSwing(character, handWeapon)
    
    if getSandboxOptions():getOptionByName("Advanced_trajectory.showOutlines"):getValue() and instanceof(handWeapon,"HandWeapon") and not handWeapon:hasTag("Thrown") and not Advanced_trajectory.hasFlameWeapon and not (handWeapon:hasTag("XBow") and not getSandboxOptions():getOptionByName("Advanced_trajectory.DebugEnableBow"):getValue()) and (handWeapon:isRanged() and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue()) then
        handWeapon:setMaxHitCount(0)
    end

    local playerLevel = character:getPerkLevel(Perks.Aiming)
    local modEffectsTable = Advanced_trajectory.getAttachmentEffects(handWeapon)  

    -- print(character)
    local item
    local winddir = 1
    local weaponname = ""
    local rollspeed = 0
    local iscanthrough = false
    local ballisticspeed = 0.15  
    local ballisticdistance = handWeapon:getMaxRange() 
    local itemtypename = ""
    local iscanbigger = 0
    local sfxname = ""
    local isthroughwall =true
    local distancez = 0

    local player=character

    local deltX
    local deltY
    local ProjectileCount = 1

    local throwinfo ={}
    local ispass =false


    local square
    local _damage

    -- direction from -pi to pi OR -180 to 180 deg
    -- N (top left corner): pi,-pi  (180, -180)
    -- W (bottom left): pi/2 (90)
    -- E (top right): -pi/2 (-90)
    -- S (bottom right corner): 0
    local playerDir = player:getForwardDirection():getDirection()

    -- bullet position 
    local spawnOffset = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugSpawnOffset"):getValue()
    local offx = character:getX()+spawnOffset * math.cos(playerDir)
    local offy = character:getY()+spawnOffset * math.sin(playerDir)
    local offz = character:getZ()

    --local offx = character:getX()
    --local offy = character:getY()
    --local offz = character:getZ()

    -- pi/250 = .7 degrees
    -- aimnum can go up to (77-9+40) 108 
    -- max/min -+96 degrees, and even more when drunk (6*24+108 = 252 => 208 deg)
    -- og denominator was 250

    local maxProjCone = getSandboxOptions():getOptionByName("Advanced_trajectory.MaxProjCone"):getValue()
    -- 120 as max aimnum
    local denom = 120 * math.pi / maxProjCone
    Advanced_trajectory.aimrate = Advanced_trajectory.aimnum * math.pi / denom

    --print("MaxProjCone: ", maxProjCone)
    --print("Aimrate: ", Advanced_trajectory.aimrate )
    
    -- NOTES: I'm assuming aimrate, which is affected by aimnum, determines how wide the bullets can spread.
    -- adding dirc (direction player is facing) will cause bullets to go towards the direction of where player is looking
    local dirc = playerDir + ZombRandFloat(-Advanced_trajectory.aimrate, Advanced_trajectory.aimrate)

    --print("Dirc: ", dirc)
    deltX = math.cos(dirc)
    deltY = math.sin(dirc)

    



    local tablez = 
    {
        item,                       --1 item obj
        square,                     --2 square obj
        {deltX,deltY},              --3 vector
        {offx, offy, offz},         --4 offset BULLET POS
        dirc,                       --5 direction
        _damage,                    --6 damage
        ballisticdistance,          --7 distance
        winddir,                    --8 ballistic small categories
        weaponname,                 --9 types
        rollspeed,                  --10 rotation speed
        iscanthrough,               --11 whether it can penetrate
        ballisticspeed,             --12 ballistic speed
        iscanbigger,                --13 can be made bigger
        sfxname,                    --14 ballistic name
        isthroughwall,              --15 whether it can pass through the wall
        1,                          --16 size
        0,                          --17 current distance
        distancez,                  --18 distance constant
        player,                     --19 players
        {offx, offy, offz},         --20 original offset PLAYER POS
        0,                          --21 count
        throwinfo                   --22 thrown object attributes                                                       
    }

    tablez["boomsfx"] = {}
    tablez["animlevels"] = Advanced_trajectory.aimlevels or math.floor(tablez[4][3])

    tablez[22] = {
        handWeapon:getSmokeRange(),
        handWeapon:getExplosionPower(),
        handWeapon:getExplosionRange(),
        handWeapon:getFirePower(),
        handWeapon:getFireRange()
    }




    tablez[22][7] = handWeapon:getExplosionSound()

    tablez["ThroNumber"] = 1


    local isspweapon = Advanced_trajectory.Advanced_trajectory[handWeapon:getFullType()] 
    if isspweapon then
        for lk,pk in pairs(isspweapon) do
            if lk == 4 then
                tablez[4][1] = tablez[4][1]+pk[1]*tablez[3][1]
                tablez[4][2] = tablez[4][2]+pk[2]*tablez[3][2]
                tablez[4][3] = tablez[4][3]+pk[3]
            else 
                tablez[lk] = pk
            end
            
        end
        ispass = true
    end

    if Advanced_trajectory.aimcursorsq then
        tablez[18] = ((Advanced_trajectory.aimcursorsq:getX()+0.5-offx)^2+(Advanced_trajectory.aimcursorsq:getY()+0.5-offy)^2)^0.5
    else
        tablez[18] =handWeapon:getMaxRange(character)
    end

    local isHoldingShotgun = false
    if not ispass then  
        if getSandboxOptions():getOptionByName("Advanced_trajectory.Enablethrow"):getValue() and handWeapon:getSwingAnim() =="Throw" then  --投掷物

            
    
            
            
            if tablez[22][1] == 0 and tablez[22][2] == 0 and tablez[22][4] == 0 then
                tablez[22][6] = 0.016
                
            else
                tablez[22][6] = 0.04 -- radian
            end
    
            
            tablez[22][9] = handWeapon:canBeReused()
    
    
            tablez[7] = tablez[18]
            tablez[9]="Grenade"
            tablez[14] = handWeapon:getFullType()
            tablez[8] = ""
            tablez[11] = false
            tablez[15] = false

            tablez[4][1] = tablez[4][1] + 0.3 * tablez[3][1]
            tablez[4][2] = tablez[4][2] + 0.3 * tablez[3][2]

            tablez[10] = 6
            tablez[12] = 0.3
    
            tablez[22][10] = tablez[14]
            tablez["isparabola"] = tablez[22][6]
        
            -- disabling enable range means guns don't work (no projectiles)
        elseif getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue() and handWeapon:getSubCategory() =="Firearm" then ----枪

            local hideTracer = getSandboxOptions():getOptionByName("Advanced_trajectory.hideTracer"):getValue()
            --print("Tracer hidden: ", hideTracer)

            local offset = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugOffset"):getValue()

            if  getIsHoldingShotgun(handWeapon) then
                local shotgunDistanceModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunDistanceModifier"):getValue()
                
                tablez[9] = "Shotgun" --weapon name

                --wpn sndfx
                if hideTracer then
                    --print("Empty")
                    tablez[14] = "Empty.aty_Shotguna"    
                else
                    --print("Base")
                    tablez[14] = "Base.aty_Shotguna"  
                end

                -- Shotgun's max cone spread is independent from default spread
                local maxShotgunProjCone = getSandboxOptions():getOptionByName("Advanced_trajectory.maxShotgunProjCone"):getValue()
                if (dirc > playerDir + maxShotgunProjCone or dirc < playerDir - maxShotgunProjCone) then
                    tablez[5] = playerDir + ZombRandFloat(-maxShotgunProjCone, maxShotgunProjCone)
                end

                tablez[12] = 1.6                                    --ballistic speed
                tablez[7] = tablez[7] * shotgunDistanceModifier     --ballistic distance
                tablez[15] = false                                  --isthroughwall

                tablez[4][1] = tablez[4][1] + offset*tablez[3][1]    --offsetx=offsetx +.6 * deltX; deltX is cos of dirc
                tablez[4][2] = tablez[4][2] + offset*tablez[3][2]    --offsety=offsety +.6 * deltY; deltY is sin of dirc
                tablez[4][3] = tablez[4][3]+0.5                      --offsetz=offsetz +.5

                isHoldingShotgun = true
            
            elseif (string.contains(handWeapon:getAmmoType() or "", "Round") or string.contains(handWeapon:getAmmoType() or "", "round")) then 
                -- The idea here is to solve issue of Brita's launchers spawning a bullet along with their grenade.
                return
            elseif Advanced_trajectory.hasFlameWeapon then 
                -- Break bullet if flamethrower
                return
            elseif ((handWeapon:hasTag("XBow") and not getSandboxOptions():getOptionByName("Advanced_trajectory.DebugEnableBow"):getValue()) or handWeapon:hasTag("Thrown")) then
                -- Break bullet if bow
                return
            else
                tablez[9] = "revolver"

                --wpn sndfx
                if hideTracer then
                    --print("Empty")
                    tablez[14] = "Empty.aty_revolversfx"  
                else
                    --print("Base")
                    tablez[14] = "Base.aty_revolversfx" 
                end


                tablez[12] = 1.8
                tablez[15]  = false

                tablez[4][1] = tablez[4][1] + offset*tablez[3][1]
                tablez[4][2] = tablez[4][2] + offset*tablez[3][2]
                tablez[4][3] = tablez[4][3] + 0.5

                -- determines number of zombies it can hit with one bullet (pen), if enabled set to stat. Else it will be set to 1 in checkontick.
                if getSandboxOptions():getOptionByName("Advanced_trajectory.enableBulletPenFlesh"):getValue() then
                    tablez["ThroNumber"] = ScriptManager.instance:getItem(handWeapon:getFullType()):getMaxHitCount()
                else
                    tablez["ThroNumber"] = 1
                end

                isHoldingShotgun = false
            end
        else
            return
            
        end
        

    end

    tablez[2] = tablez[2] or getWorld():getCell():getGridSquare(offx,offy,offz)
    if tablez[2] == nil then return end

    -- NOTES: tablez[6] is damage, firearm damages vary from 0 to 2. Example, M16 has min to max: 0.8 to 1.4 (source wiki)
    tablez[6] = tablez[6] or (handWeapon:getMinDamage() + ZombRandFloat(0.1, 1.3) * (0.5 + handWeapon:getMaxDamage() - handWeapon:getMinDamage()))

    if isHoldingShotgun then
        local shotgunDamageMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunDamageMultiplier"):getValue()
        tablez[6] = tablez[6] * shotgunDamageMultiplier
    end
    
    -- firearm crit chance can vary from 0 to 30. Ex, M16 has a crit chance of 30 (source wiki)
    -- Rifles - 25 to 30
    -- M14 - 0 crit but higher hit chance
    -- Pistols - 20
    -- Shotguns - 60 to 80
    -- Lower aimnum (to reduce spamming crits with god awful bloom) and higher player level means higher crit chance.
    local critChanceModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.critChanceModifier"):getValue() 
    local critChanceAdd = (Advanced_trajectory.aimnumBeforeShot*critChanceModifier) + (11-playerLevel)

    -- higher = higher crit chance
    local critIncreaseShotgun = getSandboxOptions():getOptionByName("Advanced_trajectory.critChanceModifierShotgunsOnly"):getValue() 
    if isHoldingShotgun then
        critChanceAdd = (critChanceAdd * 0) - (critIncreaseShotgun - playerLevel)
    end
    if ZombRand(100+critChanceAdd) <= handWeapon:getCriticalChance() then
        tablez[6]=tablez[6] * 2
    end


    -- throwinfo[8] = tablez[6]
    tablez[22][8] = handWeapon:getMinDamage()

    -- tablez[5] is dirc
    local dirc1 = tablez[5]
    tablez[5] = tablez[5]*360 / (2*math.pi)

    -- ballistic speed
    tablez[12] = tablez[12] * getSandboxOptions():getOptionByName("Advanced_trajectory.bulletspeed"):getValue() 

    -- bullet distance
    tablez[7] = tablez[7] * getSandboxOptions():getOptionByName("Advanced_trajectory.bulletdistance"):getValue() 


    ------------------------------
    -----RANGE ATTACHMENT EFFECT--
    ------------------------------
    local rangeMod = modEffectsTable[4]
    if rangeMod ~= 0 then
        tablez[7] = tablez[7] + rangeMod
    end

    local bulletnumber = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunnum"):getValue() 

    local damagemutiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.ATY_damage"):getValue()  or 1

    -- NOTES: damage is multiplied by user setting (default 1)
    tablez[6] = tablez[6] * damagemutiplier

    local damageer = tablez[6]

    -- print(tablez[5])
    if tablez[9] == "Shotgun" then

        local aimtable = {}

        for shot = 1, bulletnumber do
            local adirc

            -- lower value means tighter spread
            local numpi = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgundivision"):getValue() *0.7

            --------------------------------
            -----ANGLE ATTACHMENT EFFECT---
            --------------------------------
            local angleMod = modEffectsTable[5]
            if angleMod ~= 0 then
                numpi = numpi * angleMod
            end


            adirc = dirc1 +ZombRandFloat(-math.pi * numpi,math.pi*numpi)

            tablez[3] = {math.cos(adirc), math.sin(adirc)}
            tablez[4] = {tablez[4][1], tablez[4][2], tablez[4][3]}
            tablez[5] = adirc * 360 / (2 * math.pi)
            tablez[20] = {tablez[4][1], tablez[4][2], tablez[4][3]}

            tablez[6] = damageer / 4
            

            if isClient() then
                tablez["nonsfx"] = 1
                sendClientCommand("ATY_shotsfx","true",{tablez, character:getOnlineID()})
            end
            tablez["nonsfx"] = nil
            table.insert(Advanced_trajectory.table,Advanced_trajectory.twotable(tablez))
        end
    else

        -- print(tablez[9])
        if tablez["wallcarmouse"] then
            tablez[7] = Advanced_trajectory.aimtexdistance - 1
        end
        tablez[20] = {offx, offy, tablez[4][3]}
        table.insert(Advanced_trajectory.table,Advanced_trajectory.twotable(tablez))
        if isClient() then
            tablez["nonsfx"] = 1
            sendClientCommand("ATY_shotsfx","true",{tablez,character:getOnlineID()})
        end

        -- print(Advanced_trajectory.aimtexdistance)
    end


    local recoilModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.recoilModifier"):getValue()
    local recoilScaleModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.recoilScaleModifier"):getValue()
    local proneRecoilBuff = getSandboxOptions():getOptionByName("Advanced_trajectory.proneRecoilBuff"):getValue()
    local proneExpoRecoilBuff = getSandboxOptions():getOptionByName("Advanced_trajectory.proneExpoRecoilBuff"):getValue()
    local crouchRecoilBuff = getSandboxOptions():getOptionByName("Advanced_trajectory.crouchRecoilBuff"):getValue()
    local crouchExpoRecoilBuff = getSandboxOptions():getOptionByName("Advanced_trajectory.crouchExpoRecoilBuff"):getValue()
    Advanced_trajectory.aimnumBeforeShot = Advanced_trajectory.aimnum

    -----------------
    ---MISSED SHOT---
    -----------------
    determineHitOrMiss(isHoldingShotgun) 
    
    -- typ dmg from wep category

    -- recoilModifier = ?? < 10
    -- Britas 2.5 - 2.7 (rifles)
    -- Britas 3.0 - 6.0 (snipers)
    -- Britas 1.4 - 1.5 (SMG, pistols)

    -- recoilModifier = 10
    -- Vanilla 1.0 - 1.4 (light pistols)
    -- Vanilla 1.4 - 2.0 (rifles)
    -- Vanilla 2.2 - 2.7 (shotguns)

    -- recoilModifier = 10
    -- VFE 1.0 - 1.4 (SMG, pistols)
    -- VFE 2.0 - 2.7 (rifles)
    -- VFE 2.2 - 2.7 (shotguns)
    -- VFE 2.9 - 3.2 (snipers)

    -----------------------------
    --RECOIL ATTACHMENT EFFECT---
    -----------------------------
    -- recoilMod is always 0.5
    local recoilMod = modEffectsTable[3]
    local wepMaxDmg = handWeapon:getMaxDamage()
    if recoilMod ~= 0 then
        wepMaxDmg = wepMaxDmg * recoilMod
    end

    -- recoil control capped at lv9
    if playerLevel >= 10 then
        playerLevel = 9
    end

    -- linear relationship between player level and recoil
    local recoil = (wepMaxDmg * recoilModifier) + (11-playerLevel)

    -- Prone stance means less recoil
    if Advanced_trajectory.isCrawl  then
        recoil = recoil * proneRecoilBuff
        recoilScaleModifier = recoilScaleModifier * proneExpoRecoilBuff

    elseif Advanced_trajectory.isCrouch  then
        recoil = recoil * crouchRecoilBuff
        recoilScaleModifier = recoilScaleModifier * crouchExpoRecoilBuff
    end

    -- simulates recoil control through exponential function
    -- embraces burst and tap fire but not full auto spraying
    local exponentialRecoil = 1 + ( (11-playerLevel) * (  20^((Advanced_trajectory.aimnumBeforeShot - recoilScaleModifier) * 0.01) * 0.01  ) )



    local totalRecoil = recoil * exponentialRecoil
    --print("Total / Recoil / Exponential: ", totalRecoil, " || ", recoil, " || ", exponentialRecoil)

    Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + totalRecoil
    Advanced_trajectory.maxFocusCounter = 100

    
end

Events.OnWeaponSwingHitPoint.Add(Advanced_trajectory.OnWeaponSwing)

--function Advanced_trajectory.OnWeaponSwing(character, handWeapon)

