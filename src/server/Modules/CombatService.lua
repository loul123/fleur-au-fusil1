--[[
	La fleur au fusil — Projectiles & touches (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > CombatService

	Autorité serveur :
	  * vérifie la cadence de tir (cooldown anti-spam) de chaque combattant ;
	  * simule chaque pétale (vitesse + gravité) par Spherecast à chaque frame ;
	  * applique les dégâts, compte touches données / reçues ;
	  * diffuse les tirs aux clients pour l'affichage.
	Joueurs et bots passent par la même fonction TryFire.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))

local CombatService = {}
CombatService.Enabled = false -- vrai uniquement pendant une manche
CombatService.TeamsEnabled = false -- tir ami désactivé en mode équipe

local PS
local remotes
local projectiles = {}
local hitListeners = {}
local rng = Random.new()
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

function CombatService.OnHit(fn)
	table.insert(hitListeners, fn)
end

local function getHumanoid(p)
	return p.Model and p.Model:FindFirstChildOfClass("Humanoid")
end

local function getRoot(p)
	return p.Model and p.Model:FindFirstChild("HumanoidRootPart")
end

function CombatService.GetMuzzle(p)
	if not p.Model then
		return nil
	end
	local tool = p.Model:FindFirstChild(Config.ToolName)
	local handle = tool and tool:FindFirstChild("Handle")
	local muzzle = handle and handle:FindFirstChild("Muzzle")
	if muzzle then
		return muzzle.WorldPosition
	end
	local head = p.Model:FindFirstChild("Head")
	return head and head.Position
end

function CombatService.IsFriendly(a, b)
	return CombatService.TeamsEnabled and a.Team ~= nil and a.Team == b.Team
end

function CombatService.ClearProjectiles()
	table.clear(projectiles)
end

-- Tente un tir. Renvoie true si le tir est accepté.
function CombatService.TryFire(p, origin, direction)
	if not CombatService.Enabled or not p.Alive or not p.Model then
		return false
	end
	local humanoid = getHumanoid(p)
	local root = getRoot(p)
	if not humanoid or humanoid.Health <= 0 or not root then
		return false
	end
	if not p.Model:FindFirstChild(Config.ToolName) then
		return false -- l'arme doit être en main
	end

	local tier = Config.GetTier(p.Tier)
	local now = os.clock()
	local tolerance = if p.IsBot then 1 else Config.Combat.CooldownTolerance
	if now - p.LastFire < tier.Cooldown * tolerance then
		return false -- anti-spam
	end
	if direction.Magnitude < 0.01 then
		return false
	end
	if (origin - root.Position).Magnitude > Config.Combat.MaxOriginOffset then
		origin = CombatService.GetMuzzle(p) or root.Position -- origine suspecte : on la corrige
	end
	p.LastFire = now

	local velocities = {}
	for _ = 1, tier.Petals do
		local velocity = Config.ApplySpread(direction, tier.Spread, rng) * tier.Speed
		table.insert(velocities, velocity)
		table.insert(projectiles, {
			Pos = origin,
			Vel = velocity,
			Shooter = p,
			Born = now,
			Damage = tier.Damage,
		})
	end
	remotes.PetalFired:FireAllClients(p.Id, origin, velocities, p.Tier, p.Look.FlowerSkin, p.Look.PetalEffect)
	return true
end

local function onImpact(projectile)
	local shooter = projectile.Shooter
	local victim = projectile.Victim
	if not CombatService.Enabled or not victim or victim == shooter or not victim.Alive then
		return
	end
	if CombatService.IsFriendly(shooter, victim) then
		return
	end
	local humanoid = getHumanoid(victim)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if victim.Model:FindFirstChildOfClass("ForceField") then
		return -- protection d'apparition
	end

	humanoid:TakeDamage(projectile.Damage)
	local eliminated = humanoid.Health <= 0
	PS.RegisterHit(shooter, victim)

	if shooter.Player then
		remotes.HitConfirm:FireClient(shooter.Player, victim.Name, eliminated)
	end
	if victim.Player then
		remotes.HitTaken:FireClient(victim.Player, shooter.Name, projectile.Pos)
	end
	if eliminated then
		remotes.KillFeed:FireAllClients(shooter.Name, victim.Name, Config.GetTier(shooter.Tier).Name)
	end
	for _, fn in hitListeners do
		task.spawn(fn, shooter, victim, eliminated)
	end
end

local function step(dt)
	if #projectiles == 0 then
		return
	end
	local now = os.clock()
	local gravity = Vector3.new(0, -Config.Combat.PetalGravity, 0)
	for i = #projectiles, 1, -1 do
		local pr = projectiles[i]
		local finished = false
		if now - pr.Born > Config.Combat.PetalLifetime then
			finished = true
		else
			pr.Vel += gravity * dt
			local displacement = pr.Vel * dt
			params.FilterDescendantsInstances = { pr.Shooter.Model }
			local result = workspace:Spherecast(pr.Pos, Config.Combat.PetalRadius, displacement, params)
			if result then
				pr.Pos = result.Position
				pr.Victim = PS.FromInstance(result.Instance)
				onImpact(pr)
				finished = true
			else
				pr.Pos += displacement
			end
		end
		if finished then
			projectiles[i] = projectiles[#projectiles]
			projectiles[#projectiles] = nil
		end
	end
end

function CombatService.Init(participantService, remoteTable)
	PS = participantService
	remotes = remoteTable
	RunService.Heartbeat:Connect(step)
end

return CombatService
