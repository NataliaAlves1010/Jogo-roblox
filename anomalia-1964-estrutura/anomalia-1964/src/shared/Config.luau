--!strict

local config = {
    Maze = {
        Rows = 31,
        Columns = 31,
        Seed = 1964,
        CellSize = 24,
        WallHeight = 18,
        WallThickness = 2,
        FloorThickness = 1,
    },
    Movement = {
        PlayerWalkSpeed = 16,
        GuardWalkSpeed = 14,
    },
    GuardVision = {
        Range = 96,
        FieldOfViewDegrees = 90,
    },
    Timing = {
        GuardRepathInterval = 1,
        GuardSearchDuration = 8,
        CaptureRespawnDelay = 2,
        FallingFloorDelay = 0.35,
        FallingFloorDuration = 4,
    },
    Zones = {
        Count = 4,
    },
}

export type Config = typeof(config)

return config
