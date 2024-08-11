local Advanced_trajectory = require "Advanced_trajectory_core"

-- REFERENCE 
--[[
    local projectilePlayerData = 
    {
        item = nil,                             --1 item obj
        square = nil,                           --2 square obj
        dirVector = {deltX,deltY},              --3 vector
        bulletPos = {offX, offY, offZ},         --4 offset BULLET POS
        bulletDir = dirc,                       --5 direction
        damage = nil,                           --6 damage
        bulletDist = handWeapon:getMaxRange() , --7 distance
        winddir = 1,                            --8 ballistic small categories
        weaponName = "",                        --9 types
        rotSpeed = 0,                           --10 rotation speed
        canPenetrate = false,                   --11 whether it can penetrate
        bulletSpeed = 0.15,                     --12 ballistic speed
        iscanbigger = 0,                        --13 can be made bigger
        projectileType = "",                    --14 ballistic name
        canPassThroughWall = true,              --15 det whether it can pass through the wall
        size = 1,                               --16 size
        currDist = 0,                           --17 current distance
        distanceConst = 0,                      --18 distance constant
        player = character,                     --19 players
        playerPos = {offX, offY, offZ},         --20 original offset PLAYER POS
        count = 0,                              --21 count
        throwinfo = {}                          --22 thrown object attributes                                                       
    }
]]


-- "Base.examplegun"
local mygun = {}

mygun.bulletPos = {0.75, 0.75, 0.45}
mygun.weaponName = "revolver"
mygun.canPenetrate = true
mygun.ballisticSpeed = 16
mygun.projectileType = "Base.revolversfx"

Advanced_trajectory.FullWeaponTypes["Base.examplegun"] = mygun
