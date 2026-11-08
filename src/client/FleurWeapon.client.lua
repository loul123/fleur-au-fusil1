--[[
	La fleur au fusil — Arme côté client (LocalScript)
	Emplacement : StarterPlayer > StarterPlayerScripts > FleurClient > FleurWeapon

	* Clic gauche (ou tap sur mobile) = tirer un pétale ; maintenir = tir continu
	  à la cadence de la fleur (cooldown appliqué aussi côté serveur).
	* Affiche immédiatement les pétales du joueur (pas d'attente réseau) et ceux
	  des autres combattants diffusés par le serveur.
	* Viseur, barre de recharge, hitmarker et flash quand on est touché.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("FleurShared")
local Config = require(shared:WaitForChild("Config"))
local PetalVisual = require(shared:WaitForChild("PetalVisual"))
local Cosmetics = require(shared:WaitForChild("Cosmetics"))

local remotes = ReplicatedStorage:WaitForChild(Config.RemotesFolderName)
local FireRequest = remotes:WaitForChild("FireRequest")
local PetalFired = remotes:WaitForChild("PetalFired")
local HitConfirm = remotes:WaitForChild("HitConfirm")
local HitTaken = remotes:WaitForChild("HitTaken")
local GameState = remotes:WaitForChild("GameState")

local myId = "P" .. player.UserId
local rng = Random.new()
local equippedTool = nil
local holding = false
local lastFire = 0
local phase = "Waiting"
local toolConnections = {}

---------------------------------------------------------------------------
-- Interface : viseur, recharge, hitmarker, flash de dégâts
---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FleurWeaponGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local crosshair = Instance.new("Frame")
crosshair.Name = "Viseur"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(34, 34)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = gui

for i = 0, 3 do
	local bar = Instance.new("Frame")
	local horizontal = i % 2 == 0
	bar.Size = if horizontal then UDim2.fromOffset(10, 3) else UDim2.fromOffset(3, 10)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	local offsets = { Vector2.new(-11, 0), Vector2.new(0, -11), Vector2.new(11, 0), Vector2.new(0, 11) }
	bar.Position = UDim2.new(0.5, offsets[i + 1].X, 0.5, offsets[i + 1].Y)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(40, 60, 30)
	stroke.Parent = bar
	bar.Parent = crosshair
end

local heart = Instance.new("Frame")
heart.Size = UDim2.fromOffset(6, 6)
heart.AnchorPoint = Vector2.new(0.5, 0.5)
heart.Position = UDim2.fromScale(0.5, 0.5)
heart.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
heart.Parent = crosshair
Instance.new("UICorner", heart).CornerRadius = UDim.new(1, 0)

local cooldownBack = Instance.new("Frame")
cooldownBack.Size = UDim2.fromOffset(34, 4)
cooldownBack.Position = UDim2.new(0.5, -17, 1, 6)
cooldownBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
cooldownBack.BackgroundTransparency = 0.4
cooldownBack.BorderSizePixel = 0
cooldownBack.Parent = crosshair
local cooldownFill = Instance.new("Frame")
cooldownFill.Size = UDim2.fromScale(1, 1)
cooldownFill.BackgroundColor3 = Color3.fromRGB(140, 220, 90)
cooldownFill.BorderSizePixel = 0
cooldownFill.Parent = cooldownBack

local hitmarker = Instance.new("TextLabel")
hitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitmarker.Position = UDim2.fromScale(0.5, 0.5)
hitmarker.Size = UDim2.fromOffset(60, 60)
hitmarker.BackgroundTransparency = 1
hitmarker.Text = "✿"
hitmarker.TextScaled = true
hitmarker.Font = Enum.Font.FredokaOne
hitmarker.TextColor3 = Color3.new(1, 1, 1)
hitmarker.TextTransparency = 1
hitmarker.Parent = crosshair

local damageFlash = Instance.new("Frame")
damageFlash.Size = UDim2.fromScale(1, 1)
damageFlash.BackgroundColor3 = Color3.fromRGB(255, 80, 120)
damageFlash.BackgroundTransparency = 1
damageFlash.BorderSizePixel = 0
damageFlash.ZIndex = 0
damageFlash.Parent = gui

local function playSound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = 0.9 + math.random() * 0.25
	SoundService:PlayLocalSound(s)
	task.delay(2, function()
		s:Destroy()
	end)
end

---------------------------------------------------------------------------
-- Tir
---------------------------------------------------------------------------
local aimParams = RaycastParams.new()
aimParams.FilterType = Enum.RaycastFilterType.Exclude

local function getTier()
	return Config.GetTier(player:GetAttribute("FleurTier") or Config.DefaultTier)
end

local function getAimPoint(character)
	local camera = workspace.CurrentCamera
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	aimParams.FilterDescendantsInstances = { character, PetalVisual.GetFolder() }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1500, aimParams)
	return if result then result.Position else ray.Origin + ray.Direction * 1500
end

local function fire()
	local character = player.Character
	local tool = equippedTool
	if not character or not tool or tool.Parent ~= character or phase ~= "Round" then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local tier = getTier()
	local now = os.clock()
	if now - lastFire < tier.Cooldown then
		return -- cadence de tir (anti-spam)
	end

	local handle = tool:FindFirstChild("Handle")
	local muzzle = handle and handle:FindFirstChild("Muzzle")
	local head = character:FindFirstChild("Head")
	local origin = if muzzle then muzzle.WorldPosition elseif head then head.Position else nil
	if not origin then
		return
	end
	local direction = getAimPoint(character) - origin
	if direction.Magnitude < 0.5 then
		return
	end
	direction = direction.Unit
	lastFire = now

	for _ = 1, tier.Petals do
		local velocity = Config.ApplySpread(direction, tier.Spread, rng) * tier.Speed
		PetalVisual.Spawn(origin, velocity, player:GetAttribute("FleurFlower"), player:GetAttribute("FleurEffect"), character)
	end
	FireRequest:FireServer(origin, direction)
	playSound(Config.Sounds.Shoot, 0.35)
end

local function clearToolConnections()
	for _, c in toolConnections do
		c:Disconnect()
	end
	table.clear(toolConnections)
end

local function onToolEquipped(tool)
	clearToolConnections()
	equippedTool = tool
	table.insert(toolConnections, tool.Activated:Connect(function()
		holding = true
		fire()
	end))
	table.insert(toolConnections, tool.Deactivated:Connect(function()
		holding = false
	end))
	crosshair.Visible = true
	UserInputService.MouseIconEnabled = false
end

local function onToolUnequipped()
	clearToolConnections()
	equippedTool = nil
	holding = false
	crosshair.Visible = false
	UserInputService.MouseIconEnabled = true
end

local function hookCharacter(character)
	onToolUnequipped()
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == Config.ToolName then
			onToolEquipped(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child == equippedTool then
			onToolUnequipped()
		end
	end)
	local existing = character:FindFirstChild(Config.ToolName)
	if existing then
		onToolEquipped(existing)
	end
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	hookCharacter(player.Character)
end

RunService.RenderStepped:Connect(function()
	if not crosshair.Visible then
		return
	end
	local mouse = UserInputService:GetMouseLocation()
	crosshair.Position = UDim2.fromOffset(mouse.X, mouse.Y)

	local tier = getTier()
	local progress = math.clamp((os.clock() - lastFire) / tier.Cooldown, 0, 1)
	cooldownFill.Size = UDim2.fromScale(progress, 1)
	heart.BackgroundColor3 = Cosmetics.Get("FlowerSkin", player:GetAttribute("FleurFlower")).HeartColor
	crosshair.Rotation = (1 - progress) * 45

	if holding then
		fire()
	end
end)

---------------------------------------------------------------------------
-- Réseau : pétales des autres, confirmations de touche
---------------------------------------------------------------------------
local function findModel(id)
	if id:sub(1, 1) == "P" then
		local other = Players:GetPlayerByUserId(tonumber(id:sub(2)) or 0)
		return other and other.Character
	end
	local folder = workspace:FindFirstChild(Config.BotsFolderName)
	if folder then
		for _, m in folder:GetChildren() do
			if m:GetAttribute("FleurId") == id then
				return m
			end
		end
	end
	return nil
end

PetalFired.OnClientEvent:Connect(function(shooterId, origin, velocities, _tierIndex, flowerId, effectId)
	if shooterId == myId then
		return -- déjà affiché localement
	end
	local model = findModel(shooterId)
	for _, v in velocities do
		PetalVisual.Spawn(origin, v, flowerId, effectId, model)
	end
end)

HitConfirm.OnClientEvent:Connect(function(_victimName, eliminated)
	hitmarker.TextColor3 = if eliminated then Color3.fromRGB(255, 70, 90) else Color3.new(1, 1, 1)
	hitmarker.TextTransparency = 0
	hitmarker.Size = UDim2.fromOffset(if eliminated then 80 else 56, if eliminated then 80 else 56)
	TweenService:Create(hitmarker, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
	playSound(Config.Sounds.Hit, if eliminated then 0.8 else 0.5)
end)

HitTaken.OnClientEvent:Connect(function()
	damageFlash.BackgroundTransparency = 0.6
	TweenService:Create(damageFlash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
end)

GameState.OnClientEvent:Connect(function(s)
	phase = s.Phase
end)

task.spawn(function()
	local ok, s = pcall(function()
		return remotes:WaitForChild("GetState"):InvokeServer()
	end)
	if ok and s then
		phase = s.Phase
	end
end)
