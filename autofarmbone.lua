loadstring(game:HttpGet("https://raw.githubusercontent.com/dolcestudioluaU/kaitun/refs/heads/main/autobringmob"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/dolcestudioluaU/kaitun/refs/heads/main/autoattack.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/dolcestudioluaU/kaitun/refs/heads/main/autohaki"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/dolcestudioluaU/kaitun/refs/heads/main/checkmasteryv3"))()

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

local BONE_POSITIONS = {
    CFrame.new(-8769.58984, 142.13063, 6055.27637),
    CFrame.new(-10156.4531, 138.652481, 5964.5752),
    CFrame.new(-9525.17188, 172.13063, 6152.30566),
    CFrame.new(-9570.88281, 5.81831884, 6187.86279),
}

local SPEED = 280
local LOCK_DISTANCE = 5
local currentIndex = 1
local currentTarget = nil
local bodyVelocity = nil
local bodyGyro = nil

local function setupBodyMovers()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if not bodyVelocity then
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FarmBV"
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = root
    end
    
    if not bodyGyro then
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FarmBG"
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.D = 500
        bodyGyro.Parent = root
    end
end

local function removeBodyMovers()
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
end

local function smoothMoveTo(targetPos)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    setupBodyMovers()
    
    local distance = (targetPos - root.Position).Magnitude
    local direction = (targetPos - root.Position).Unit
    
    if distance > LOCK_DISTANCE then
        bodyVelocity.Velocity = direction * SPEED
    else
        bodyVelocity.Velocity = Vector3.zero
    end
    
    bodyGyro.CFrame = CFrame.lookAt(root.Position, targetPos)
end

local function getAliveBone()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    if currentTarget and currentTarget.Parent then
        local hum = currentTarget:FindFirstChild("Humanoid")
        local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            return currentTarget
        else
            currentTarget = nil
        end
    end
    
    local bestDist = math.huge
    local bestEnemy = nil
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local validNames = {
        ["Reborn Skeleton"] = true,
        ["Living Zombie"] = true,
        ["Demonic Soul"] = true,
        ["Posessed Mummy"] = true
    }
    
    for _, enemy in pairs(enemies:GetChildren()) do
        if validNames[enemy.Name] then
            local hum = enemy:FindFirstChild("Humanoid")
            local hrp = enemy:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestEnemy = enemy
                end
            end
        end
    end
    
    currentTarget = bestEnemy
    return bestEnemy
end

local heartbeatConnection = nil

local function startFarm()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not _G.AutoFarmBone then
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end
            removeBodyMovers()
            return
        end
        
        pcall(function()
            local char = player.Character
            if not char then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if not root or not hum then return end
            
            root.CanCollide = false
            hum.PlatformStand = true
            
            local enemy = getAliveBone()
            
            if enemy then
                local hrp = enemy:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local targetPos = Vector3.new(hrp.Position.X, hrp.Position.Y + 20, hrp.Position.Z)
                    smoothMoveTo(targetPos)
                end
            else
                local targetPos = BONE_POSITIONS[currentIndex].Position
                local distance = (targetPos - root.Position).Magnitude
                
                if distance < 10 then
                    currentIndex = (currentIndex % #BONE_POSITIONS) + 1
                end
                
                smoothMoveTo(targetPos)
            end
        end)
    end)
end

local function stopFarm()
    _G.AutoFarmBone = false
    currentTarget = nil
    
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    
    removeBodyMovers()
    
    local char = player.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        
        if root then
            root.CanCollide = true
            root.Velocity = Vector3.zero
        end
        
        if hum then
            hum.PlatformStand = false
        end
    end
end

_G.AutoFarmBone = true
startFarm()

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F8 then
        stopFarm()
    end
end)

player.CharacterAdded:Connect(function()
    removeBodyMovers()
    if _G.AutoFarmBone then
        task.wait(1)
        startFarm()
    end
end)
