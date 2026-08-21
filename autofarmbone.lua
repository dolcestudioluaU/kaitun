loadstring(game:HttpGet("https://raw.githubusercontent.com/dolcestudioluaU/kaitun/refs/heads/main/autoequipmelee.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/dolcestudioluaU/kaitun/refs/heads/main/autobringmob"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/dolcestudioluaU/kaitun/refs/heads/main/autoattack.lua"))()
loadstring(game:HttpGet(""))()
local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

local BONE_POSITIONS = {
    CFrame.new(-8769.58984, 142.13063, 6055.27637),
    CFrame.new(-10156.4531, 138.652481, 5964.5752),
    CFrame.new(-9525.17188, 172.13063, 6152.30566),
    CFrame.new(-9570.88281, 5.81831884, 6187.86279),
}

local SPEED = 300
local currentIndex = 1
local currentTarget = nil
local isFlying = false
local lockEnabled = false

local function flyTo(targetCFrame, speed)
    speed = speed or 300
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not root or not hum then return end
    
    if _G.CurrentFlyTween then
        _G.CurrentFlyTween:Cancel()
        _G.CurrentFlyTween = nil
    end
    
    root.CanCollide = false
    hum.PlatformStand = true
    isFlying = true
    
    local distance = (targetCFrame.Position - root.Position).Magnitude
    local duration = math.max(distance / speed, 0.5)
    
    _G.CurrentFlyTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    
    _G.CurrentFlyTween.Completed:Connect(function(state)
        if state == Enum.PlaybackState.Completed then
            isFlying = false
        end
    end)
    
    _G.CurrentFlyTween:Play()
end

local function getAliveBone()
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    
    if currentTarget and currentTarget.Parent then
        local hum = currentTarget:FindFirstChild("Humanoid")
        local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            return currentTarget
        end
    end
    
    local bestDist = math.huge
    local bestEnemy = nil
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    for _, enemy in pairs(enemies:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
            local hum = enemy.Humanoid
            local hrp = enemy.HumanoidRootPart
            if hum.Health > 0 then
                local name = enemy.Name
                if name == "Reborn Skeleton" or name == "Living Zombie" or name == "Demonic Soul" or name == "Posessed Mummy" then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestEnemy = enemy
                    end
                end
            end
        end
    end
    
    currentTarget = bestEnemy
    return bestEnemy
end

local function farmBone()
    while _G.AutoFarmBone do
        pcall(function()
            local char = player.Character
            if not char then task.wait(1) return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then task.wait(1) return end
            
            local enemy = getAliveBone()
            
            if enemy then
                local hrp = enemy:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local targetCF = CFrame.new(hrp.Position.X, hrp.Position.Y + 20, hrp.Position.Z)
                    
                    if not isFlying then
                        flyTo(targetCF, SPEED)
                    end
                    
                    lockEnabled = true
                end
            else
                lockEnabled = false
                isFlying = false
                flyTo(BONE_POSITIONS[currentIndex], SPEED)
                task.wait(1.5)
                currentIndex = currentIndex % #BONE_POSITIONS + 1
                currentTarget = nil
            end
            
            task.wait(0.1)
        end)
        task.wait(0.05)
    end
end

-- Loop lock vị trí - FIX GIẬT
task.spawn(function()
    local lastPos = nil
    while _G.AutoFarmBone do
        pcall(function()
            if lockEnabled and currentTarget and currentTarget.Parent then
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
                    if root and hrp then
                        local targetPos = CFrame.new(hrp.Position.X, hrp.Position.Y + 20, hrp.Position.Z)
                        
                        -- Chỉ cập nhật khi quái di chuyển > 2 studs để tránh giật
                        if lastPos == nil or (lastPos.Position - targetPos.Position).Magnitude > 2 then
                            root.CFrame = targetPos
                            root.CanCollide = false
                            lastPos = targetPos
                        end
                        
                        local hum = char:FindFirstChildWhichIsA("Humanoid")
                        if hum then
                            hum.PlatformStand = true
                        end
                    end
                end
            else
                lastPos = nil
            end
        end)
        task.wait(0.1) -- Giảm tần suất để tránh giật
    end
end)

_G.AutoFarmBone = true
farmBone()

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F8 then
        _G.AutoFarmBone = false
        lockEnabled = false
        currentTarget = nil
        if _G.CurrentFlyTween then
            _G.CurrentFlyTween:Cancel()
            _G.CurrentFlyTween = nil
        end
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if root then 
                root.CanCollide = true
            end
            if hum then hum.PlatformStand = false end
        end
        isFlying = false
    end
end)

