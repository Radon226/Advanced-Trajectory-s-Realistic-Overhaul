local Advanced_trajectory = require "Advanced_trajectory_core"

Advanced_trajectory.hitboxes = {
    -- radius, circleHitbox1, circleHitbox2, etc.
    standHumanoid = {
        radius = 0.5,
        isRotate = false,
        hitbox = {
            {0, 0},
            {0.5, 0.5},
            {1, 1},
            {1.5, 1.5},
        }
    },

    crouchHumanoid = {
        radius = 0.5,
        isRotate = false,
        hitbox = {
            {0, 0},
            {0.5, 0.5},
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