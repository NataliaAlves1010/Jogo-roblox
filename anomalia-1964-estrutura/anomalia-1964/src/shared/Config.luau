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
        VentWalkSpeed = 8,
        VentHipHeightReduction = 1,
    },
    GuardVision = {
        Range = 96,
        FieldOfViewDegrees = 90,
    },
    Obstacles = {
        LightBeamHeight = 8,
        LightBeamThickness = 0.5,
        LightBeamWidth = 1.5,
    },
    UI = {
        DialogueTypingDelay = 0.025,
        DialoguePanelWidth = 520,
        DialoguePanelHeight = 180,
        DialogueChoiceHeight = 32,
    },
    Timing = {
        GuardRepathInterval = 1,
        GuardSearchDuration = 8,
        CaptureRespawnDelay = 2,
        FallingFloorDelay = 0.35,
        FallingFloorDuration = 4,
        LightBeamActiveDuration = 3,
        LightBeamSafeDuration = 2,
    },
    Zones = {
        Count = 4,
    },
    Progress = {
        RequiredKeys = { "chave_gabinete" },
        MinimumClues = 5,
        InteractionDistance = 10,
    },
}

export type Config = typeof(config)

return config
