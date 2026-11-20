local RunService = game:GetService("RunService")
local Rep = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local SNOW_RATE = 180
local SNOW_SPEED = 22
local SNOW_HEIGHT = 14
local SNOW_DISTANCE = 12

local GRASS_COLOR = Color3.fromRGB(222, 232, 224)
local TERRAIN_GRASS_COLOR = Color3.fromRGB(196, 210, 194)
local TERRAIN_SNOW_COLOR = Color3.fromRGB(220, 230, 222)

local FOG_COLOR = Color3.fromRGB(220, 225, 230)
local FOG_START = 0
local FOG_END = 110

local SKYBOX_IDS = {
    SkyboxBk = "rbxassetid://1370717244",
    SkyboxDn = "rbxassetid://1370717336",
    SkyboxFt = "rbxassetid://1370717438",
    SkyboxLf = "rbxassetid://1370717567",
    SkyboxRt = "rbxassetid://1370717698",
    SkyboxUp = "rbxassetid://1370717782"
}

if _G.EHWeatherStop then
    _G.EHWeatherStop()
end

if _G.PermanentSnowStop then
    _G.PermanentSnowStop()
end

local RuntimeLib = require(
    Rep:WaitForChild("Code")
       :WaitForChild("rbxts_include")
       :WaitForChild("RuntimeLib")
)

local Particles = RuntimeLib.import(
    script,
    Rep,
    "Code",
    "assets",
    "particles"
).default

local SnowPart = Instance.new("Part")
SnowPart.Name = "EHCustomSnow"
SnowPart.Size = Vector3.new(65, 0.1, 65)
SnowPart.Transparency = 1
SnowPart.Anchored = true
SnowPart.CanCollide = false
SnowPart.CanTouch = false
SnowPart.CanQuery = false
SnowPart.CastShadow = false
SnowPart.Parent = WS.CurrentCamera

local Snow = Particles.Snow:Clone()
Snow.Name = "EHCustomSnowParticles"
Snow.Enabled = true
Snow.Rate = SNOW_RATE
Snow.Speed = NumberRange.new(SNOW_SPEED)
Snow.Lifetime = NumberRange.new(1.5, 2)
Snow.EmissionDirection = Enum.NormalId.Bottom
Snow.LockedToPart = false
Snow.Parent = SnowPart

local function ForceSkybox()
    local Sky = Lighting:FindFirstChildOfClass("Sky")

    if not Sky then
        Sky = Instance.new("Sky")
        Sky.Parent = Lighting
    end

    for Property, AssetId in pairs(SKYBOX_IDS) do
        if Sky[Property] ~= AssetId then
            Sky[Property] = AssetId
        end
    end

    Sky.CelestialBodiesShown = false
    Sky.SunAngularSize = 0
    Sky.MoonAngularSize = 0
    Sky.StarCount = 0
end

local function RemoveClouds()
    for _, obj in ipairs(WS.Terrain:GetChildren()) do
        if obj:IsA("Clouds") then
            obj.Cover = 0
            obj.Density = 0
        end
    end
end

local function ForceLighting()
    Lighting.ClockTime = 12
    Lighting.Brightness = 0.6
    Lighting.GlobalShadows = false
    Lighting.ExposureCompensation = -0.2

    Lighting.Ambient = Color3.fromRGB(170, 180, 190)
    Lighting.OutdoorAmbient = Color3.fromRGB(190, 200, 210)

    Lighting.FogColor = FOG_COLOR
    Lighting.FogStart = FOG_START
    Lighting.FogEnd = FOG_END

    local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

    if not Atmosphere then
        Atmosphere = Instance.new("Atmosphere")
        Atmosphere.Parent = Lighting
    end

    Atmosphere.Color = FOG_COLOR
    Atmosphere.Decay = Color3.fromRGB(195, 205, 215)
    Atmosphere.Density = 0.6
    Atmosphere.Haze = 3
    Atmosphere.Glare = 0
    Atmosphere.Offset = 0

    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("SunRaysEffect") then
            obj.Enabled = false
        end
    end
end
iner)
    if not container then return end

    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            local parent = obj.Parent
            local name = obj.Name:lower()
            local parentName = parent and parent.Name:lower() or ""

            if name:find("rain")
                or name:find("splash")
                or parentName:find("rain")
                or parentName:find("splash") then

                obj.Enabled = false
                obj.Rate = 0
                obj:Clear()
            end
        end
    end
end

local function DisableRainSounds()
    for _, obj in ipairs(SoundService:GetDescendants()) do
        if obj:IsA("Sound")
            and obj.Name:lower():find("rain") then

            obj.Volume = 0
            obj:Stop()
        end
    end
end

local Terrain = WS.Terrain

local GrassConnections = {}
local GrassOriginals = {}

local TerrainOriginal = {
    GrassColor = Terrain:GetMaterialColor(Enum.Material.Grass),
    SnowColor = Terrain:GetMaterialColor(Enum.Material.Snow)
}

local function MakeSnowyGrass(obj)
    if not obj:IsA("BasePart") then
        return
    end

    if obj.Material ~= Enum.Material.Grass then
        return
    end

    if not GrassOriginals[obj] then
        GrassOriginals[obj] = {
            Material = obj.Material,
            Color = obj.Color
        }
    end

    if obj.Color ~= GRASS_COLOR then
        obj.Color = GRASS_COLOR
    end
end

local function WatchGrass(obj)
    if not obj:IsA("BasePart") then
        return
    end

    if GrassConnections[obj] then
        return
    end

    MakeSnowyGrass(obj)

    GrassConnections[obj] =
        obj:GetPropertyChangedSignal("Material"):Connect(function()
            MakeSnowyGrass(obj)
        end)
end

for _, obj in ipairs(WS:GetDescendants()) do
    WatchGrass(obj)
end

local GrassAddedConnection = WS.DescendantAdded:Connect(function(obj)
    WatchGrass(obj)
end)

local GrassRemovedConnection = WS.DescendantRemoving:Connect(function(obj)
    if GrassConnections[obj] then
        GrassConnections[obj]:Disconnect()
        GrassConnections[obj] = nil
    end
end)

local function ForceSnowyTerrain()
    Terrain:SetMaterialColor(
        Enum.Material.Grass,
        TERRAIN_GRASS_COLOR
    )

    Terrain:SetMaterialColor(
        Enum.Material.Snow,
        TERRAIN_SNOW_COLOR
    )
end

local function ApplyWeather()
    ForceLighting()
    ForceSkybox()
    RemoveClouds()
end

local RenderConnection = RunService.RenderStepped:Connect(function()
    local Camera = WS.CurrentCamera
    if not Camera then return end

    ApplyWeather()

    if SnowPart.Parent ~= Camera then
        SnowPart.Parent = Camera
    end

    SnowPart.CFrame = CFrame.new(
        Camera.CFrame.Position
        + Camera.CFrame.LookVector * SNOW_DISTANCE
        + Vector3.new(0, SNOW_HEIGHT, 0)
    )
end)

local Timer = 0
local GrassTimer = 0

local RainConnection = RunService.Heartbeat:Connect(function(dt)
    Timer += dt
    GrassTimer += dt

    if Timer >= 0.1 then
        Timer = 0

        DisableRain(WS.CurrentCamera)
        DisableRain(WS.Terrain)
        DisableRainSounds()
        ForceSnowyTerrain()
    end

    if GrassTimer >= 1 then
        GrassTimer = 0

        for obj in pairs(GrassConnections) do
            if obj.Parent then
                MakeSnowyGrass(obj)
            end
        end
    end
end)

ApplyWeather()
ForceSnowyTerrain()

DisableRain(WS.CurrentCamera)
DisableRain(WS.Terrain)
DisableRainSounds()

_G.EHWeatherStop = function()
    RenderConnection:Disconnect()
    RainConnection:Disconnect()

    GrassAddedConnection:Disconnect()
    GrassRemovedConnection:Disconnect()

    for _, connection in pairs(GrassConnections) do
        connection:Disconnect()
    end

    for obj, original in pairs(GrassOriginals) do
        if obj.Parent then
            obj.Color = original.Color
        end
    end

    Terrain:SetMaterialColor(
        Enum.Material.Grass,
        TerrainOriginal.GrassColor
    )

    Terrain:SetMaterialColor(
        Enum.Material.Snow,
        TerrainOriginal.SnowColor
    )

    SnowPart:Destroy()

    _G.EHWeatherStop = nil
end
