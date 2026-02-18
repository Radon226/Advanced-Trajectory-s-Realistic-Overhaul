local Advanced_trajectory = require "Advanced_trajectory_core"

function Advanced_trajectory.sqobject(sqa)
    local cell = getWorld():getCell();
	local sq = sqa
	if sq == nil then return false; end
	local sqObjs = sq:getObjects();
	local sqSize = sqObjs:size();
	local tbl = {}
	for i = sqSize - 1, 0, -1 do 
		local obj = sqObjs:get(i);
		table.insert(tbl, obj)
	end
	return sq, sqObjs, tbl, cell
end

function Advanced_trajectory.Boom(sq, info)

    local player = getPlayer()
    if not sq or not info or not player then return end

    --local isPlayerSafe = player:getSafety():isEnabled()

    if info["zombie"] then
        info["zombie"]:knockDown(false)
        info["zombie"]:setHealth(info["zombie"]:getHealth()-info[8]*0.1)

        if info["zombie"]:getHealth() <0.1 then
            info["zombie"]:Kill(player)
        end
    end

    if info[9] and  info["pos"] then
        sq:AddWorldInventoryItem(info[10], info["pos"][1], info["pos"][2], 0)
    end

    local smokeRange        = info[1] - 2
    local explosionPower    = info[2]
    local explosionRange    = info[3] - 2
    --local firePower         = info[4]
    local fireRange         = info[5] - 2

    for i = -smokeRange, smokeRange do
        for k = -smokeRange, smokeRange do
            local square = getCell():getGridSquare(sq:getX() + i, sq:getY() + k, sq:getZ())
            if square then
                local corenumber = (i^2 + k^2)
                if ZombRand(smokeRange^2 + smokeRange^2) >= corenumber then
                    
                    if isClient() then
                        local args = { x = square:getX(), y = square:getY(), z = square:getZ() }
                        sendClientCommand('object', 'addSmokeOnSquare', args)
                        
                    else
                        IsoFireManager.StartSmoke(getCell(), square, true, 200, 3000)
                    end
                end
            end
        end
    end
    



    for zkl = 0, 1 do
        for i = -explosionRange, explosionRange do
            for k = -explosionRange, explosionRange do
                local square=getCell():getGridSquare(sq:getX() + i, sq:getY() + k, sq:getZ() + zkl)
                if square then
                    local corenumber = (i^2 + k^2)
                    if explosionPower > 100 and ZombRand(explosionRange^2 + explosionRange^2) / 1.5 >= corenumber then
                        local sqz, sqObjs, objTbl, cell = Advanced_trajectory.sqobject(square)
                        local z = sq:getZ()
                        for izk = 1, #objTbl do
                            local obj = objTbl[izk]
                            local sprite = obj:getSprite()
                            if sprite and (zkl > 0 or sprite:getProperties():Is(IsoFlagType.solidfloor) ~= true) then
                                local stairObjects = buildUtil.getStairObjects(obj)
                                if #stairObjects > 0 then
                                    for i=1, #stairObjects do
                                        if isClient() then
                                            sledgeDestroy(stairObjects[i])
                                        else
                                            stairObjects[i]:getSquare():RemoveTileObject(stairObjects[i])
                                        end
                                    end
                                else
                                    if isClient() then
                                        sledgeDestroy(obj)
                                    else
                                        sqz:RemoveTileObject(obj);
                                        sqz:getSpecialObjects():remove(obj);
                                        sqz:getObjects():remove(obj);
                                    end
                                end
                            end
                        end

                        --suixie
    
                        -- if zkl == 0 then
                        --     if ZombRand(10)<=4 then
                        --         local objectz = IsoObject.new(square, "floors_burnt_01_0", "", false)
                        --         square:AddTileObject(objectz)
                        --         if isClient() then objectz:transmitCompleteItemToServer(); end
                        --     elseif ZombRand(10)<=6 then
                        --         local objectz = IsoObject.new(square, "floors_burnt_01_1", "", false)
                        --         square:AddTileObject(objectz)
                        --         if isClient() then objectz:transmitCompleteItemToServer(); end
                        --     else
                        --         local objectz = IsoObject.new(square, "floors_burnt_01_2", "", false)
                        --         square:AddTileObject(objectz)
                        --         if isClient() then objectz:transmitCompleteItemToServer(); end
                        --     end
                        -- end
                        
                    end
    
                    
                    local movingObjects = square:getMovingObjects()
                    for zz=1, movingObjects:size() do
                        local zombiez = movingObjects:get(zz-1)
                        if instanceof(zombiez,"IsoZombie") then
                            zombiez:knockDown(false)
                            if ZombRand(explosionRange^2 + explosionRange^2) >= corenumber then

                                zombiez:Kill(player)
                               
                            end
                            
                        elseif instanceof(zombiez,"IsoPlayer") then
                            --if (not isPlayerSafe or not zombiez:getSafety():isEnabled()) or getSandboxOptions():getOptionByName("Advanced_trajectory.IgnorePVPSafety"):getValue() then
                                if isClient() then
                                    sendClientCommand("ATY_reducehealth", "true", {explosionPower, zombiez:getOnlineID()})
                                else
                                    zombiez:getBodyDamage():ReduceGeneralHealth(explosionPower)
                                end
                            --end
                        
                        end
                    end
                    
                end
            end
        end
    end



    for i = -fireRange, fireRange do
        for k = -fireRange, fireRange do
            local square=getCell():getGridSquare(sq:getX() + i, sq:getY() + k, sq:getZ())
            if square then
                local corenumber = (i^2 + k^2)
                if ZombRand(fireRange^2 + fireRange^2) >= corenumber then

                    if isClient() then
                        local args = { x = square:getX(), y = square:getY(), z = square:getZ() }
                        sendClientCommand('object', 'addFireOnSquare', args)

                    else
                        IsoFireManager.StartFire(getCell(), square, true, 100, 500);
                    end

                end
            end
        end
    end

    -- getSoundManager():PlayWorldSoundWav(info[7],sq, 10, 2, 0.5, true);
    -- print(info[7])
    -- player:playSound(info[7])

    local sound = getSoundManager():PlayWorldSound(info[7], sq, 0, 4, 1.0, false);

    
    local noiseRange = info[11]
    --print("Noise : ", noiseRange, " || ", " Smoke : ", smokeRange, " || ", " fireRange : ", fireRange, " || ", " Explosion: ", explosionPower, " || ", " firePower: ", firePower)


    -- Use addSound(IsoObject source, int x, int y, int z, int radius, int volume) to attract zombies.

    if noiseRange > 0 then
        addSound(player, sq:getX(), sq:getY(), sq:getZ(), noiseRange, 50); 
    elseif smokeRange > 0 then
        addSound(player, sq:getX(), sq:getY(), sq:getZ(), smokeRange * 7, 50); 
    --elseif fireRange > 0 then
        --addSound(player, sq:getX(), sq:getY(), sq:getZ(), firePower, 50); --firepower deprecated b42
    else
        addSound(player, sq:getX(), sq:getY(), sq:getZ(), explosionPower, 50); 
    end

    
    -- print(info[7])


end