local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
-- Localize for performance + less detection
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local GetMouseLocation = UserInputService.GetMouseLocation
local FindFirstChild = game.FindFirstChild
-- Hook state
local oldNamecall = nil
local fovConnection = nil
local hooked = false
-- FOV Drawing
local silentAimFOV
pcall(function()
    silentAimFOV = Drawing.new("Circle")
    silentAimFOV.Thickness = 1
    silentAimFOV.NumSides = 100
    silentAimFOV.Radius = 130
    silentAimFOV.Filled = false
    silentAimFOV.Visible = false
    silentAimFOV.ZIndex = 999
    silentAimFOV.Transparency = 1
    silentAimFOV.Color = Color3.fromRGB(255, 255, 255)
end)
local ExpectedArguments = {
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}
local function CalculateChance(Percentage)
    local ok, result = pcall(function()
        Percentage = math.floor(Percentage)
        local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
        return chance <= Percentage / 100
    end)
    if ok then return result end
    return false
end
local function getPositionOnScreen(Vector)
    local ok, vec, onScreen = pcall(function()
        local Vec3, OnScreen = WorldToScreen(Camera, Vector)
        return Vector2.new(Vec3.X, Vec3.Y), OnScreen
    end)
    if ok then return vec, onScreen end
    return Vector2.new(0, 0), false
end
local function ValidateArguments(Args, RayMethod)
    local ok, result = pcall(function()
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
    end)
    if ok then return result end
    return false
end
local function getDirection(Origin, Position)
    local ok, result = pcall(function()
        return (Position - Origin).Unit * 1000
    end)
    if ok then return result end
    return Vector3.new(0, 0, 0)
end
local function getMousePosition()
    local ok, result = pcall(function()
        return GetMouseLocation(UserInputService)
    end)
    if ok then return result end
    return Vector2.new(0, 0)
end
local function applyJitter(position, amount)
    local ok, result = pcall(function()
        amount = amount or 0
        if amount <= 0 then return position end
        return position + Vector3.new(
            (math.random() - 0.5) * 2 * amount,
            (math.random() - 0.5) * 2 * amount,
            (math.random() - 0.5) * 2 * amount
        )
    end)
    if ok then return result end
    return position
end
local function getClosestPlayer()
    local ok, result = pcall(function()
        local Settings = getgenv().SilentAimSettings
        local Closest
        local DistanceToMouse
        for _, Player in next, GetPlayers(Players) do
            if Player == LocalPlayer then continue end
            local Character = Player.Character
            if not Character then continue end
            if Settings.TeamCheck and Player.Team == LocalPlayer.Team then continue end
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
    end)
    if ok then return result end
    return nil
end
local SilentAim = {}
function SilentAim.Load(Settings)
    if hooked then return end
    pcall(function()
        getgenv().SilentAimSettings = Settings
    end)
    -- FOV Renderer
    pcall(function()
        fovConnection = RunService.RenderStepped:Connect(function()
            pcall(function()
                local s = getgenv().SilentAimSettings
                if not silentAimFOV then return end
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
        end)
    end)
    -- ===== RAW METATABLE HOOK =====
    pcall(function()
        local mt = getrawmetatable(game)
        local wasReadonly = isreadonly(mt)
        setreadonly(mt, false)
        oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(...)
            local Method
            local okMethod = pcall(function()
                Method = getnamecallmethod()
            end)
            if not okMethod then return oldNamecall(...) end

            local Arguments = {...}
            local self = Arguments[1]
            local s
            pcall(function() s = getgenv().SilentAimSettings end)

            if s and s.Enabled and self == workspace and not checkcaller() and Method == "Raycast" then
                local hookOk, hookResult = pcall(function()
                    if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                        if CalculateChance(s.HitChance) then
                            local HitPart = getClosestPlayer()
                            if HitPart then
                                local targetPos = applyJitter(HitPart.Position, s.JitterAmount or 0)
                                Arguments[3] = getDirection(Arguments[2], targetPos)
                                return { oldNamecall(unpack(Arguments)) }
                            end
                        end
                    end
                    return nil
                end)
                if hookOk and hookResult then
                    return unpack(hookResult)
                end
            end
            return oldNamecall(...)
        end)
        setreadonly(mt, wasReadonly)
        hooked = true
    end)
end
function SilentAim.Unload()
    if not hooked then return end
    pcall(function()
        local mt = getrawmetatable(game)
        local wasReadonly = isreadonly(mt)
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, wasReadonly)
    end)
    oldNamecall = nil
    hooked = false
    pcall(function()
        if fovConnection then
            fovConnection:Disconnect()
            fovConnection = nil
        end
    end)
    pcall(function()
        if silentAimFOV then silentAimFOV.Visible = false end
    end)
    pcall(function()
        getgenv().SilentAimSettings = nil
    end)
end

return SilentAim
