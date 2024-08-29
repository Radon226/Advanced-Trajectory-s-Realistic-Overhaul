local Advanced_trajectory = require "Advanced_trajectory_core"

Advanced_trajectory.hitboxes = {
    -- radius, circleHitbox1, circleHitbox2, etc.
    standHumanoid = {
        radius = 0.5,
        isRotate = false,
        hitbox = {
            {0.2, 0.2},
            {0.7, 0.7},
            {1.2, 1.2},
        }
    },

    proneHumanoid = {
        radius = 0.5,
        isRotate = false,
        hitbox = {
            {0.3, 0.3},
        }
    },

    sitHumanoid = {
        radius = 0.5,
        isRotate = false,
        hitbox = {
            {0, 0},
        }
    }
}