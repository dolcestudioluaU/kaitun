local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

_G.NoClip = true

local noClipConnection = nil

local function startNoClip()
    if noClipConnection then
        noClipConnection:Disconnect()
    end
    
    noClipConnection = RunService.Stepped:Connect(function()
        if not _G.NoClip then
            if noClipConnection then
                noClipConnection:Disconnect()
                noClipConnection = nil
            end
            return
        end
        
        pcall(function()
            local char = player.Character
            if not char then return end
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

local function stopNoClip()
    _G.NoClip = false
    
    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end
    
    local char = player.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

startNoClip()

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        if _G.NoClip then
            stopNoClip()
        else
            _G.NoClip = true
            startNoClip()
        end
    end
end)

player.CharacterAdded:Connect(function()
    if _G.NoClip then
        task.wait(0.5)
        startNoClip()
    end
end)
