-- CombinedTeleportSetup.lua (Server Script)
-- Place this Script inside ServerScriptService.
-- It will:
-- 1) Ensure a RemoteEvent named "RequestTeleport" exists in ReplicatedStorage.
-- 2) Ensure a Part named "Spawn" exists in Workspace (creates a default if missing).
-- 3) Run the server-side teleport validation handler.
-- 4) Create two LocalScripts in StarterPlayerScripts:
--    - DemoInsecure.lua  (client-side insecure demo; for Studio only)
--    - TeleportClient.lua (client-side secure requester)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 1) Ensure RemoteEvent
local teleportEvent = ReplicatedStorage:FindFirstChild("RequestTeleport")
if not teleportEvent then
    teleportEvent = Instance.new("RemoteEvent")
    teleportEvent.Name = "RequestTeleport"
    teleportEvent.Parent = ReplicatedStorage
end

-- 2) Ensure Spawn part exists
local spawnPart = Workspace:FindFirstChild("Spawn")
if not spawnPart then
    spawnPart = Instance.new("Part")
    spawnPart.Name = "Spawn"
    spawnPart.Size = Vector3.new(6,1,6)
    spawnPart.Position = Vector3.new(0, 5, 0)
    spawnPart.Anchored = true
    spawnPart.Parent = Workspace
    warn("Spawn part not found — created default Spawn at (0,5,0).")
end

-- 3) Server-side teleport handler (validates and teleports)
local cooldowns = {}
local COOLDOWN_SECONDS = 3

teleportEvent.OnServerEvent:Connect(function(player)
    if not player or not player.Parent then return end

    -- Simple cooldown per player
    local now = os.time()
    local last = cooldowns[player.UserId]
    if last and now - last < COOLDOWN_SECONDS then
        -- Too fast; ignore
        return
    end
    cooldowns[player.UserId] = now

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then
        return
    end

    -- OPTIONAL: add other checks here (distance checks, permission/role checks, zone checks, etc.)

    local targetCFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
    local success, err = pcall(function()
        hrp.CFrame = targetCFrame
    end)
    if not success then
        warn("Teleport error for player " .. tostring(player.Name) .. ": " .. tostring(err))
    end
end)

-- Helper to safely create or replace a LocalScript in StarterPlayerScripts
local function createOrReplaceLocalScript(name, source)
    local existing = StarterPlayerScripts:FindFirstChild(name)
    if existing then
        existing:Destroy()
    end
    local ls = Instance.new("LocalScript")
    ls.Name = name
    ls.Source = source
    ls.Parent = StarterPlayerScripts
    return ls
end

-- 4A) DemoInsecure LocalScript (client moves HRP directly) -- FOR STUDIO DEMO ONLY
local demoSource = [[
-- DemoInsecure.lua (LocalScript) -- DEMO ONLY, use in Studio Local Server
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local spawnPart = workspace:WaitForChild("Spawn")
local playerGui = player:WaitForChild("PlayerGui")

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DemoInsecureGui"
screenGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.8, 0)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Text = "Teleport me (INSECURE)"
button.Parent = screenGui

button.MouseButton1Click:Connect(function()
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Insecure behavior: client moves its own HumanoidRootPart directly
        hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
    end
end)
]]

-- 4B) TeleportClient LocalScript (client requests teleport from server)
local clientSource = [[
-- TeleportClient.lua (LocalScript) -- Secure client that requests teleport via RemoteEvent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
if not player then return end

local teleportEvent = ReplicatedStorage:WaitForChild("RequestTeleport")
local playerGui = player:WaitForChild("PlayerGui")

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGuiSecure"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.8, 0)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Text = "Request Teleport (Secure)"
button.Font = Enum.Font.SourceSansBold
button.TextSize = 22
button.Parent = screenGui

local busy = false
button.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    teleportEvent:FireServer()
    -- Small client-side debounce; server also enforces cooldown
    wait(0.5)
    busy = false
end)
]]

-- Create/replace the two LocalScripts in StarterPlayerScripts
createOrReplaceLocalScript("DemoInsecure", demoSource)
createOrReplaceLocalScript("TeleportClient", clientSource)

-- Info to the developer
print("Combined teleport setup complete. Created RequestTeleport RemoteEvent (if missing), ensured Spawn part, and placed DemoInsecure & TeleportClient LocalScripts in StarterPlayerScripts.")
print("NOTE: DemoInsecure is only for classroom demo in Studio. Do NOT publish the insecure demo in production.")
]]

-- End of combined server script
