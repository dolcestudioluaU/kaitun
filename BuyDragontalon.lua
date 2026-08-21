local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")

local DOOR_POSITION = CFrame.new(-5026.5, 313.2, -3206.7)
local NPC_POSITION = CFrame.new(5661.89014, 1211.31909, 864.836731, 0.811413169, -1.36805838e-08, -0.584473014, 4.75227395e-08, 1, 4.25682458e-08, 0.584473014, -6.23161966e-08, 0.811413169)
local SPEED = 250

local function flyTo(targetCFrame, speed)
    speed = speed or SPEED
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
    
    local distance = (targetCFrame.Position - root.Position).Magnitude
    local duration = math.max(distance / speed, 0.5)
    
    _G.CurrentFlyTween = TweenService:Create(
        root, 
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), 
        {CFrame = targetCFrame}
    )
    
    _G.CurrentFlyTween:Play()
    _G.CurrentFlyTween.Completed:Wait()
    
    root.CanCollide = true
    hum.PlatformStand = false
    _G.CurrentFlyTween = nil
end

local function waitForTeleport(timeout)
    timeout = timeout or 2
    local startPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not startPos then return false end
    local startPosCopy = startPos.Position
    local elapsed = 0
    
    while elapsed < timeout do
        task.wait(0.1)
        elapsed = elapsed + 0.1
        local currentPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if currentPos then
            if (currentPos.Position - startPosCopy).Magnitude > 50 then
                return true
            end
        end
    end
    return false
end

local function buyDragonTalon()
    pcall(function()
        replicated.Remotes.CommF_:InvokeServer("BuyDragonTalon")
        task.wait(0.3)
        replicated.Remotes.CommF_:InvokeServer("BuyDragonTalon")
        task.wait(0.3)
        local module = replicated.Modules and replicated.Modules.Net and replicated.Modules.Net["RF/InteractDragonQuest"]
        if module then
            module:InvokeServer({["NPC"] = "Uzoth", ["Command"] = "Upgrade"})
        end
        task.wait(0.3)
        replicated.Remotes.CommF_:InvokeServer("BuyDragonTalon")
    end)
end

local function smartFlyToNPC()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local distToDoor = (root.Position - DOOR_POSITION.Position).Magnitude
    local distToNPC = (root.Position - NPC_POSITION.Position).Magnitude
    
    if distToNPC <= 50 then
        buyDragonTalon()
        return
    end
    
    if distToNPC < distToDoor then
        flyTo(NPC_POSITION, SPEED)
        task.wait(0.5)
        buyDragonTalon()
    else
        flyTo(DOOR_POSITION, SPEED)
        task.wait(0.5)
        
        local teleported = waitForTeleport(2)
        
        if teleported then
            task.wait(0.5)
        end
        
        flyTo(NPC_POSITION, SPEED)
        task.wait(0.5)
        buyDragonTalon()
    end
end

smartFlyToNPC()

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F8 then
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
            if hum then 
                hum.PlatformStand = false 
            end
        end
    end
end)
