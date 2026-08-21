local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- Remote references
local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
local Net = Modules and Modules:FindFirstChild("Net")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5)

local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit = Net and Net:FindFirstChild("RE/RegisterHit")
local ShootGunEvent = Net and Net:FindFirstChild("RE/ShootGunEvent")
local GunValidator = RemotesFolder and RemotesFolder:FindFirstChild("Validator2")

-- Configuration
local Config = {
	AttackDistance = 65,
	AttackMobs = true,
	AttackPlayers = true,
	AttackCooldown = 0.12,
	ComboResetTime = 0.3,
	MaxCombo = 4,
	HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand", "HumanoidRootPart"},
	AutoClickEnabled = true
}

-- FastAttack Class
local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
	local self = setmetatable({
		Debounce = 0,
		ComboDebounce = 0,
		ShootDebounce = 0,
		M1Combo = 0,
		EnemyRootPart = nil,
		SpecialShoots = {
			["Skull Guitar"] = "TAP",
			["Bazooka"] = "Position",
			["Cannon"] = "Position",
			["Dragonstorm"] = "Overheat"
		}
	}, FastAttack)

	-- Upvalue extraction safely wrapped in pcall
	pcall(function()
		local combatController = require(ReplicatedStorage.Controllers.CombatController)
		self.ShootFunction = getupvalue(combatController.Attack, 9)
		
		local localScript = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
		if localScript and getsenv then
			self.HitFunction = getsenv(localScript)._G.SendHitsToServer
		end
	end)

	return self
end

function FastAttack:IsAlive(entity)
	local humanoid = entity and entity:FindFirstChild("Humanoid")
	return humanoid and humanoid.Health > 0
end

function FastAttack:CanAttack(character, humanoid, toolTip)
	if humanoid.Sit and (toolTip == "Sword" or toolTip == "Melee" or toolTip == "Blox Fruit") then
		return false
	end
	
	local stun = character:FindFirstChild("Stun")
	local busy = character:FindFirstChild("Busy")
	if (stun and stun.Value > 0) or (busy and busy.Value) then
		return false
	end
	
	return true
end

function FastAttack:GetBladeHits(character, maxDistance)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return {} end

	local myPos = rootPart.Position
	local hits = {}
	maxDistance = maxDistance or Config.AttackDistance

	self.EnemyRootPart = nil

	local function scanFolder(folder)
		if not folder then return end
		for _, enemy in ipairs(folder:GetChildren()) do
			if enemy ~= character and self:IsAlive(enemy) then
				-- Find valid limb or default to RootPart
				local limbName = Config.HitboxLimbs[math.random(#Config.HitboxLimbs)]
				local targetPart = enemy:FindFirstChild(limbName) or enemy:FindFirstChild("HumanoidRootPart")
				
				if targetPart and (myPos - targetPart.Position).Magnitude <= maxDistance then
					if not self.EnemyRootPart then
						self.EnemyRootPart = targetPart
					end
					table.insert(hits, {enemy, targetPart})
				end
			end
		end
	end

	if Config.AttackMobs then scanFolder(Workspace:FindFirstChild("Enemies")) end
	if Config.AttackPlayers then scanFolder(Workspace:FindFirstChild("Characters")) end

	return hits
end

function FastAttack:GetClosestEnemy(character, maxDistance)
	local hits = self:GetBladeHits(character, maxDistance)
	local closestPart, minDistance = nil, math.huge
	local myPos = character:GetPivot().Position

	for _, hit in ipairs(hits) do
		local dist = (myPos - hit[2].Position).Magnitude
		if dist < minDistance then
			minDistance = dist
			closestPart = hit[2]
		end
	end
	
	return closestPart
end

function FastAttack:GetCombo()
	local now = tick()
	local combo = (now - self.ComboDebounce <= Config.ComboResetTime) and self.M1Combo or 0
	combo = (combo >= Config.MaxCombo) and 1 or (combo + 1)
	
	self.ComboDebounce = now
	self.M1Combo = combo
	return combo
end

function FastAttack:GetValidator2()
	if not self.ShootFunction then return 0, 0 end

	local v1 = getupvalue(self.ShootFunction, 15)
	local v2 = getupvalue(self.ShootFunction, 13)
	local v3 = getupvalue(self.ShootFunction, 16)
	local v4 = getupvalue(self.ShootFunction, 17)
	local v5 = getupvalue(self.ShootFunction, 14)
	local v6 = getupvalue(self.ShootFunction, 12)
	local v7 = getupvalue(self.ShootFunction, 18)

	local v8 = v6 * v2
	local v9 = (v5 * v2 + v6 * v1) % v3
	v9 = (v9 * v3 + v8) % v4
	v5 = math.floor(v9 / v3)
	v6 = v9 - v5 * v3
	v7 = v7 + 1

	setupvalue(self.ShootFunction, 14, v5)
	setupvalue(self.ShootFunction, 12, v6)
	setupvalue(self.ShootFunction, 18, v7)

	return math.floor(v9 / v4 * 16777215), v7
end

function FastAttack:ShootGun(targetPosition)
	local character = LocalPlayer.Character
	if not self:IsAlive(character) then return end

	local equipped = character:FindFirstChildOfClass("Tool")
	if not equipped or equipped.ToolTip ~= "Gun" then return end

	local cooldown = equipped:FindFirstChild("Cooldown") and equipped.Cooldown.Value or 0.3
	if (tick() - self.ShootDebounce) < cooldown then return end

	local shootType = self.SpecialShoots[equipped.Name] or "Normal"
	
	if (shootType == "Position" or shootType == "TAP") and GunValidator then
		equipped:SetAttribute("LocalTotalShots", (equipped:GetAttribute("LocalTotalShots") or 0) + 1)
		GunValidator:FireServer(self:GetValidator2())

		if shootType == "TAP" and equipped:FindFirstChild("RemoteEvent") then
			equipped.RemoteEvent:FireServer("TAP", targetPosition)
		elseif ShootGunEvent then
			ShootGunEvent:FireServer(targetPosition)
		end
	else
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
		task.wait(0.05)
		VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
	end
	
	self.ShootDebounce = tick()
end

function FastAttack:ProcessMelee(character, cooldown)
	local hits = self:GetBladeHits(character)
	if self.EnemyRootPart then
		if RegisterAttack then
			RegisterAttack:FireServer(cooldown)
		end
		
		if self.HitFunction then
			self.HitFunction(self.EnemyRootPart, hits)
		elseif RegisterHit then
			RegisterHit:FireServer(self.EnemyRootPart, hits)
		end
	end
end

function FastAttack:ProcessFruit(character, equipped, combo)
	local hits = self:GetBladeHits(character)
	if hits[1] and equipped:FindFirstChild("LeftClickRemote") then
		local dir = (hits[1][2].Position - character:GetPivot().Position).Unit
		equipped.LeftClickRemote:FireServer(dir, combo)
	end
end

function FastAttack:Attack()
	if not Config.AutoClickEnabled or (tick() - self.Debounce) < Config.AttackCooldown then return end

	local character = LocalPlayer.Character
	if not character or not self:IsAlive(character) then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local equipped = character:FindFirstChildOfClass("Tool")
	if not humanoid or not equipped then return end

	local toolTip = equipped.ToolTip
	if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, toolTip) then return end
	if not self:CanAttack(character, humanoid, toolTip) then return end

	local baseCooldown = equipped:FindFirstChild("Cooldown") and equipped.Cooldown.Value or Config.AttackCooldown
	local combo = self:GetCombo()
	
	self.Debounce = tick()

	if toolTip == "Blox Fruit" then
		self:ProcessFruit(character, equipped, combo)
	elseif toolTip == "Gun" then
		local target = self:GetClosestEnemy(character, 120)
		if target then
			self:ShootGun(target.Position)
		end
	else
		self:ProcessMelee(character, baseCooldown)
	end
end

-- Initialization
local attacker = FastAttack.new()

RunService.Stepped:Connect(function()
	attacker:Attack()
end)
