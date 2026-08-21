local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")

local isRunning = false
local currentTool = nil

local function equipMelee()
    local char = player.Character
    if not char then return end
    
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    
    -- Tìm tool Melee trong Backpack
    local meleeTool = nil
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == "Melee" then
            meleeTool = tool
            break
        end
    end
    
    if not meleeTool then return end
    
    -- Kiểm tra tool đang cầm
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped and equipped.Name == meleeTool.Name then
        return -- Đã cầm đúng melee
    end
    
    -- Cầm melee lên
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum:EquipTool(meleeTool)
    end
end

local function start()
    if isRunning then return end
    isRunning = true
    _G.AutoEquipMelee = true
    
    task.spawn(function()
        while isRunning and _G.AutoEquipMelee do
            pcall(equipMelee)
            task.wait(0.1)
        end
    end)
end

local function stop()
    isRunning = false
    _G.AutoEquipMelee = false
end

-- Phím F7 để dừng
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F7 then
        if isRunning then
            stop()
        else
            start()
        end
    end
end)

-- Tự động chạy khi script được load
start()

-- Dừng khi nhân vật chết
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if isRunning then
        pcall(equipMelee)
    end
end)
