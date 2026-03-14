local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local GetMouseLocation = UserInputService.GetMouseLocation
local FindFirstChild = game.FindFirstChild

local oldNamecall = nil
local fovConnection = nil

local silentAimFOV = Drawing.new("Circle")
silentAimFOV.Thickness = 1
silentAimFOV.NumSides = 100
silentAimFOV.Radius = 130
silentAimFOV.Filled = false
silentAimFOV.Visible = false
silentAimFOV.ZIndex = 999
silentAimFOV.Transparency = 1
silentAimFOV.Color = Color3.fromRGB(255, 255, 255)

local ExpectedArguments = {
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

local function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function getClosestPlayer()
    local Settings = getgenv().SilentAimSettings
    local Closest
    local DistanceToMouse

    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end

        local Character = Player.Character
        if not Character then continue end

        if Settings.VisibleCheck then
            local LocalPlayerCharacter = LocalPlayer.Character
            if not (Character or LocalPlayerCharacter) then continue end
            local PlayerRoot = FindFirstChild(Character, "HumanoidRootPart")
            if not PlayerRoot then continue end
            local CastPoints = {PlayerRoot.Position}
            local IgnoreList = {LocalPlayerCharacter, Character}
            local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
            if ObscuringObjects > 0 then continue end
        end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if not Settings.IgnoreFOV and Distance > (Settings.FOVSize or 2000) then continue end
            if Distance <= (DistanceToMouse or Settings.FOVSize or 2000) then
            if Settings.TargetPart["Head"] and Settings.TargetPart["HumanoidRootPart"] then
                if Settings.TargetMode == "Random" then
                    if CalculateChance(Settings.HeadHitChance) then
                        Closest = FindFirstChild(Character, "Head")
                    else
                        Closest = FindFirstChild(Character, "HumanoidRootPart")
                    end
                else
                    Closest = FindFirstChild(Character, "HumanoidRootPart")
                end
            elseif Settings.TargetPart["Head"] then
                Closest = FindFirstChild(Character, "Head")
            else
                Closest = FindFirstChild(Character, "HumanoidRootPart")
            end
            DistanceToMouse = Distance
        end
    end

    return Closest
end

local SilentAim = {}

function SilentAim.Load(Settings)
    if oldNamecall then return end

    getgenv().SilentAimSettings = Settings

    fovConnection = RunService.RenderStepped:Connect(function()
        local s = getgenv().SilentAimSettings
        if not s then silentAimFOV.Visible = false return end

        if s.DrawFOV then
            silentAimFOV.Visible = true
            silentAimFOV.Position = GetMouseLocation(UserInputService)
            silentAimFOV.Color = s.FOVColor or Color3.fromRGB(255, 255, 255)
            silentAimFOV.Radius = s.FOVSize or 130
        else
            silentAimFOV.Visible = false
        end
    end)

    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
        local Method = getnamecallmethod()
        local Arguments = {...}
        local self = Arguments[1]
        local s = getgenv().SilentAimSettings

        if s.Enabled and self == workspace and not checkcaller() and Method == "Raycast" then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local chance = CalculateChance(s.HitChance)
                if chance then
                    local HitPart = getClosestPlayer()
                    if HitPart then
                        Arguments[3] = getDirection(Arguments[2], HitPart.Position)
                        return oldNamecall(unpack(Arguments))
                    end
                end
            end
        end

        return oldNamecall(...)
    end))

end

function SilentAim.Unload()
    if not oldNamecall then return end

    hookmetamethod(game, "__namecall", oldNamecall)
    oldNamecall = nil

    if fovConnection then
        fovConnection:Disconnect()
        fovConnection = nil
    end

    silentAimFOV.Visible = false
    getgenv().SilentAimSettings = nil

end

return SilentAim
