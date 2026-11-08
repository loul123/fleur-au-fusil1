--[[
	La fleur au fusil — IA des bots (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > BotService

	Bots basiques mais crédibles :
	  * Recherche de cible : ennemi vivant le plus proche avec ligne de vue.
	  * Combat : se tourne vers la cible, mitraille en respectant la cadence de
	    la fleur, anticipe le déplacement et la chute du pétale, avec une
	    imprécision réglable ; garde une distance idéale et fait du strafe.
	  * Navigation : PathfindingService vers l'ennemi le plus proche (ou un
	    point au hasard), avec détection de blocage (saut + recalcul).
	  * Réapparition automatique après élimination.
	Les bots tirent via CombatService.TryFire, exactement comme les joueurs.
]]

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))
local WeaponFactory = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("WeaponFactory"))
local Cosmetics = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Cosmetics"))

local BotService = {}
BotService.Active = false -- les bots ne bougent / tirent que pendant une manche

local PS, Combat, Map
local hooks = {}
local brains = {} -- [participant] = état de l'IA
local folder
local rng = Random.new()
local nameCursor = 0
local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude

local BC = Config.Bots

---------------------------------------------------------------------------
-- Construction du personnage
---------------------------------------------------------------------------
local function teamColor(p)
	if p.Team then
		for _, t in Config.Teams do
			if t.Name == p.Team then
				return t.BrickColor.Color
			end
		end
	end
	return Color3.fromHSV(rng:NextNumber(), 0.55, 0.85)
end

local function buildFallbackRig(color)
	-- Rig minimal si CreateHumanoidModelFromDescription échoue
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.Parent = model
	local function limb(name, size, offset, c)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = c
		part.CFrame = root.CFrame * CFrame.new(offset)
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		return part
	end
	limb("UpperTorso", Vector3.new(2, 2, 1), Vector3.zero, color)
	limb("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.6, 0), Color3.fromRGB(255, 220, 180))
	limb("LeftLeg", Vector3.new(0.9, 2, 1), Vector3.new(-0.5, -2, 0), Color3.fromRGB(60, 60, 60))
	limb("RightLeg", Vector3.new(0.9, 2, 1), Vector3.new(0.5, -2, 0), Color3.fromRGB(60, 60, 60))
	local rightHand = limb("RightHand", Vector3.new(0.6, 0.6, 0.6), Vector3.new(1.4, 0, -0.5), Color3.fromRGB(255, 220, 180))
	local grip = Instance.new("Attachment")
	grip.Name = "RightGripAttachment"
	grip.Parent = rightHand
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 2
	humanoid.Parent = model
	model.PrimaryPart = root
	return model
end

local function buildModel(p)
	local color = teamColor(p)
	local desc = Instance.new("HumanoidDescription")
	local skin = Color3.fromRGB(255, 220, 180):Lerp(Color3.fromRGB(120, 80, 50), rng:NextNumber())
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.TorsoColor = color
	desc.LeftLegColor = Color3.fromRGB(60, 60, 70)
	desc.RightLegColor = Color3.fromRGB(60, 60, 70)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		model = buildFallbackRig(color)
	end
	return model
end

local function setupAnimations(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local function load(id, priority)
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = priority
			track.Looped = true
			return track
		end
		return nil
	end
	local idle = load(BC.Animations.Idle, Enum.AnimationPriority.Idle)
	local walk = load(BC.Animations.Walk, Enum.AnimationPriority.Movement)
	local hold = load(BC.Animations.Hold, Enum.AnimationPriority.Action)
	if idle then idle:Play() end
	if hold then hold:Play() end
	humanoid.Running:Connect(function(speed)
		if not walk then
			return
		end
		if speed > 0.5 and not walk.IsPlaying then
			walk:Play(0.15)
		elseif speed <= 0.5 and walk.IsPlaying then
			walk:Stop(0.2)
		end
	end)
end

local function newBrain()
	return {
		Target = nil,
		TargetSince = 0,
		Path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 8 }),
		Waypoints = nil,
		WpIndex = 1,
		Goal = nil,
		LastPath = 0,
		Computing = false,
		StrafeDir = 1,
		NextStrafe = 0,
		LastPos = nil,
		LastMoveCheck = 0,
		NextThink = 0,
	}
end

local function spawnBot(p)
	if not PS.Get(p.Id) then
		return
	end
	if p.Model then
		p.Model:Destroy()
		p.Model = nil
	end

	local model = buildModel(p)
	model.Name = p.Name
	model:SetAttribute("FleurId", p.Id)
	model:SetAttribute("FleurTier", p.Tier)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = "🌱 " .. p.Name
	humanoid.MaxHealth = Config.Combat.MaxHealth
	humanoid.Health = Config.Combat.MaxHealth
	humanoid.WalkSpeed = BC.WalkSpeed
	model:PivotTo(Map.GetSpawnCFrame(p.Team))
	model.Parent = folder

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:CanSetNetworkOwnership() then
			part:SetNetworkOwner(nil) -- physique gérée par le serveur
		end
	end

	local forceField = Instance.new("ForceField")
	forceField.Visible = true
	forceField.Parent = model
	Debris:AddItem(forceField, Config.Combat.SpawnProtection)

	local tool = WeaponFactory.Create(p.Tier, p.Look)
	tool.Parent = model
	pcall(function()
		humanoid:EquipTool(tool)
	end)
	pcall(setupAnimations, humanoid)

	p.Model = model
	p.Alive = true
	p.LastFire = 0
	brains[p] = newBrain()

	humanoid.Died:Connect(function()
		p.Alive = false
		task.delay(Config.Combat.RespawnTime, function()
			if PS.Get(p.Id) == p and p.Model == model then
				spawnBot(p)
			end
		end)
	end)

	if hooks.OnSpawned then
		hooks.OnSpawned(p)
	end
end

---------------------------------------------------------------------------
-- Gestion de la population
---------------------------------------------------------------------------
function BotService.AddBot()
	nameCursor += 1
	local base = BC.Names[(nameCursor - 1) % #BC.Names + 1]
	local suffix = if nameCursor > #BC.Names then " " .. tostring(math.ceil(nameCursor / #BC.Names)) else ""
	local p = PS.AddBot(base .. suffix)
	p.Look = Cosmetics.RandomLook(rng) -- les bots exhibent des skins variés
	if hooks.OnCreated then
		hooks.OnCreated(p)
	end
	spawnBot(p)
	return p
end

function BotService.RemoveBot(p)
	brains[p] = nil
	if p.Model then
		p.Model:Destroy()
		p.Model = nil
	end
	p.Alive = false
	PS.Remove(p.Id)
end

function BotService.RespawnAll()
	for _, p in PS.Bots() do
		spawnBot(p)
	end
end

function BotService.UpdateTier(p)
	if p.Model then
		local tool = p.Model:FindFirstChild(Config.ToolName)
		if tool then
			WeaponFactory.SetTier(tool, p.Tier, p.Look)
		end
	end
end

function BotService.RefreshAppearance(p)
	if not p.Model then
		return
	end
	local color = teamColor(p)
	for _, name in { "UpperTorso", "LowerTorso", "Torso" } do
		local part = p.Model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
	if hooks.OnSpawned then
		hooks.OnSpawned(p)
	end
end

---------------------------------------------------------------------------
-- Perception
---------------------------------------------------------------------------
local function aimPartOf(model)
	return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
end

local function hasLineOfSight(fromPos, selfModel, targetModel)
	local part = targetModel:FindFirstChild("Head") or aimPartOf(targetModel)
	if not part then
		return false
	end
	losParams.FilterDescendantsInstances = { selfModel }
	local result = workspace:Raycast(fromPos, part.Position - fromPos, losParams)
	return result == nil or result.Instance:IsDescendantOf(targetModel)
end

local function isValidEnemy(p, other)
	if other == p or not other.Alive or not other.Model then
		return false
	end
	local hum = other.Model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	return hooks.IsEnemy(p, other)
end

local function findTargets(p, root, eye)
	local visible, visibleDist = nil, math.huge
	local nearest, nearestDist = nil, math.huge
	for _, other in PS.All() do
		if isValidEnemy(p, other) then
			local oroot = other.Model:FindFirstChild("HumanoidRootPart")
			if oroot then
				local d = (oroot.Position - root.Position).Magnitude
				if d < nearestDist then
					nearest, nearestDist = other, d
				end
				if d < BC.SightRange and d < visibleDist and hasLineOfSight(eye, p.Model, other.Model) then
					visible, visibleDist = other, d
				end
			end
		end
	end
	return visible, nearest
end

---------------------------------------------------------------------------
-- Déplacement
---------------------------------------------------------------------------
local function moveAlongPath(brain, humanoid, root, goal, now)
	local needRepath = brain.Waypoints == nil
		or now - brain.LastPath > BC.RepathInterval
		or (brain.Goal and (brain.Goal - goal).Magnitude > 30)
	if needRepath and not brain.Computing then
		brain.Computing = true
		local from = root.Position
		task.spawn(function()
			local ok = pcall(function()
				brain.Path:ComputeAsync(from, goal)
			end)
			if ok and brain.Path.Status == Enum.PathStatus.Success then
				brain.Waypoints = brain.Path:GetWaypoints()
				brain.WpIndex = 2
			else
				brain.Waypoints = nil
			end
			brain.Goal = goal
			brain.LastPath = os.clock()
			brain.Computing = false
		end)
	end

	local waypoints = brain.Waypoints
	local wp = waypoints and waypoints[brain.WpIndex]
	if wp then
		local flat = (wp.Position - root.Position) * Vector3.new(1, 0, 1)
		if flat.Magnitude < 4 then
			brain.WpIndex += 1
			wp = waypoints[brain.WpIndex]
		end
	end
	if wp then
		humanoid:MoveTo(wp.Position)
		if wp.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end
	else
		humanoid:MoveTo(goal) -- ligne droite en secours
	end
end

local function checkStuck(brain, humanoid, root, now)
	if now - brain.LastMoveCheck < 1.5 then
		return
	end
	if brain.LastPos and (root.Position - brain.LastPos).Magnitude < 1.5 then
		humanoid.Jump = true
		brain.Waypoints = nil
		brain.StrafeDir = -brain.StrafeDir
	end
	brain.LastPos = root.Position
	brain.LastMoveCheck = now
end

---------------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------------
local function engage(p, brain, humanoid, root, target, now)
	local troot = target.Model:FindFirstChild("HumanoidRootPart")
	local aimPart = aimPartOf(target.Model)
	if not troot or not aimPart then
		return
	end

	-- se tourner vers la cible
	local toTarget = troot.Position - root.Position
	local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
	local dist = flat.Magnitude
	if dist < 0.1 then
		return
	end
	local forward = flat.Unit
	humanoid.AutoRotate = false
	root.CFrame = CFrame.lookAt(root.Position, root.Position + forward)

	-- strafe + gestion de la distance
	if now > brain.NextStrafe then
		brain.StrafeDir = if rng:NextNumber() < 0.5 then -1 else 1
		brain.NextStrafe = now + rng:NextNumber(0.8, 2.0)
		if rng:NextNumber() < 0.15 then
			humanoid.Jump = true
		end
	end
	local move = forward:Cross(Vector3.yAxis) * brain.StrafeDir
	if dist > BC.PreferredRange * 1.3 then
		move += forward * 1.5
	elseif dist < BC.PreferredRange * 0.6 then
		move -= forward
	end
	humanoid:MoveTo(root.Position + move.Unit * 10)

	-- tir
	if now - brain.TargetSince < BC.ReactionTime then
		return
	end
	local tier = Config.GetTier(p.Tier)
	if now - p.LastFire < tier.Cooldown then
		return
	end
	local origin = Combat.GetMuzzle(p)
	if not origin then
		return
	end
	local targetPos = aimPart.Position
	local travel = (targetPos - origin).Magnitude / tier.Speed
	local lead = troot.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * travel * BC.LeadSkill
	local drop = Vector3.new(0, 0.5 * Config.Combat.PetalGravity * travel * travel, 0)
	local aim = targetPos + lead + drop
	local direction = Config.ApplySpread(aim - origin, BC.AimErrorDegrees, rng)
	Combat.TryFire(p, origin, direction)
end

local function think(p, brain, now)
	local model = p.Model
	if not p.Alive or not model then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head") or root
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end

	local visible, nearest = findTargets(p, root, head.Position)
	if visible then
		if brain.Target ~= visible then
			brain.Target = visible
			brain.TargetSince = now
		end
		engage(p, brain, humanoid, root, visible, now)
	else
		brain.Target = nil
		humanoid.AutoRotate = true
		local goal
		if nearest then
			goal = nearest.Model.HumanoidRootPart.Position
		else
			if not brain.Goal or (brain.Goal - root.Position).Magnitude < 10 then
				brain.Goal = Map.GetRandomPoint()
			end
			goal = brain.Goal
		end
		moveAlongPath(brain, humanoid, root, goal, now)
	end
	checkStuck(brain, humanoid, root, now)
end

---------------------------------------------------------------------------
-- Boucle principale
---------------------------------------------------------------------------
function BotService.SetActive(active)
	BotService.Active = active
	if not active then
		for p in brains do
			local humanoid = p.Model and p.Model:FindFirstChildOfClass("Humanoid")
			local root = p.Model and p.Model:FindFirstChild("HumanoidRootPart")
			if humanoid and root then
				humanoid:MoveTo(root.Position)
				humanoid.AutoRotate = true
			end
		end
	end
end

-- options = { Map, IsEnemy(a, b), OnCreated(p), OnSpawned(p) }
function BotService.Init(participantService, combatService, options)
	PS = participantService
	Combat = combatService
	Map = options.Map
	hooks.IsEnemy = options.IsEnemy
	hooks.OnCreated = options.OnCreated
	hooks.OnSpawned = options.OnSpawned

	folder = workspace:FindFirstChild(Config.BotsFolderName) or Instance.new("Folder")
	folder.Name = Config.BotsFolderName
	folder.Parent = workspace

	RunService.Heartbeat:Connect(function()
		if not BotService.Active then
			return
		end
		local now = os.clock()
		for p, brain in brains do
			if now >= brain.NextThink then
				brain.NextThink = now + BC.ThinkInterval * rng:NextNumber(0.8, 1.2)
				local ok, err = pcall(think, p, brain, now)
				if not ok then
					warn("[FleurBots] " .. tostring(err))
				end
			end
		end
	end)
end

return BotService
