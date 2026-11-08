--[[
	La fleur au fusil — Registre des combattants (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > ParticipantService

	Un « participant » représente indifféremment un joueur ou un bot :
	  { Id, Name, IsBot, Player, Model, Team, Hits, Taken, RoundHits,
	    RoundTaken, Tier, LastFire, Alive }
	Le modèle du personnage porte l'attribut "FleurId" = participant.Id,
	ce qui permet de retrouver la victime à partir d'une pièce touchée.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))
local Cosmetics = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Cosmetics"))

local ParticipantService = {}

local byId = {}
local order = {} -- ordre d'arrivée, pour des itérations stables
local listeners = {}
local botCounter = 0

local function fireChanged()
	for _, fn in listeners do
		task.spawn(fn)
	end
end

function ParticipantService.OnChanged(fn)
	table.insert(listeners, fn)
end

local function newParticipant(id, name, isBot)
	return {
		Id = id,
		Name = name,
		IsBot = isBot,
		Player = nil,
		Model = nil,
		Team = nil,
		Hits = 0,
		Taken = 0,
		RoundHits = 0,
		RoundTaken = 0,
		Tier = Config.DefaultTier,
		LastFire = 0,
		Alive = false,
		Look = Cosmetics.DefaultLook(), -- { WeaponSkin, FlowerSkin, PetalEffect }
	}
end

local function register(p)
	byId[p.Id] = p
	table.insert(order, p.Id)
	fireChanged()
	return p
end

function ParticipantService.AddPlayer(player)
	local p = newParticipant("P" .. player.UserId, player.DisplayName, false)
	p.Player = player

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, statName in { "Score", "Touches", "Reçues" } do
		local v = Instance.new("IntValue")
		v.Name = statName
		v.Parent = stats
	end
	stats.Parent = player
	player:SetAttribute("FleurTier", p.Tier)
	return register(p)
end

function ParticipantService.AddBot(name)
	botCounter += 1
	local p = newParticipant("B" .. botCounter, name, true)
	return register(p)
end

function ParticipantService.Remove(id)
	if byId[id] then
		byId[id] = nil
		local i = table.find(order, id)
		if i then
			table.remove(order, i)
		end
		fireChanged()
	end
end

function ParticipantService.Get(id)
	return byId[id]
end

function ParticipantService.GetByPlayer(player)
	return byId["P" .. player.UserId]
end

function ParticipantService.All()
	local list = {}
	for _, id in order do
		table.insert(list, byId[id])
	end
	return list
end

function ParticipantService.Humans()
	local list = {}
	for _, p in ParticipantService.All() do
		if not p.IsBot then
			table.insert(list, p)
		end
	end
	return list
end

function ParticipantService.Bots()
	local list = {}
	for _, p in ParticipantService.All() do
		if p.IsBot then
			table.insert(list, p)
		end
	end
	return list
end

-- Retrouve le participant propriétaire d'une pièce (membre, accessoire, arme…)
function ParticipantService.FromInstance(instance)
	local model = instance and instance:FindFirstAncestorOfClass("Model")
	while model do
		local id = model:GetAttribute("FleurId")
		if id then
			return byId[id]
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

-- Met à jour leaderstats / attributs et prévient les abonnés
function ParticipantService.Sync(p)
	if p.Player and p.Player.Parent then
		local stats = p.Player:FindFirstChild("leaderstats")
		if stats then
			stats.Score.Value = (Config.ComputeScore(p.Hits, p.Taken))
			stats.Touches.Value = p.Hits
			stats["Reçues"].Value = p.Taken
		end
		p.Player:SetAttribute("FleurTier", p.Tier)
	end
	if p.Model then
		p.Model:SetAttribute("FleurTier", p.Tier)
	end
	fireChanged()
end

function ParticipantService.RegisterHit(shooter, victim)
	shooter.Hits += 1
	shooter.RoundHits += 1
	victim.Taken += 1
	victim.RoundTaken += 1
	ParticipantService.Sync(shooter)
	ParticipantService.Sync(victim)
end

function ParticipantService.ResetRound()
	for _, p in ParticipantService.All() do
		p.RoundHits = 0
		p.RoundTaken = 0
	end
	fireChanged()
end

function ParticipantService.ResetMatch()
	for _, p in ParticipantService.All() do
		p.Hits = 0
		p.Taken = 0
		p.RoundHits = 0
		p.RoundTaken = 0
		p.Tier = Config.DefaultTier
		p.LastFire = 0
		ParticipantService.Sync(p)
	end
end

-- Tableau sérialisable envoyé aux clients, trié par score final
function ParticipantService.Snapshot()
	local rows = {}
	for _, p in ParticipantService.All() do
		local final, ratio = Config.ComputeScore(p.Hits, p.Taken)
		table.insert(rows, {
			Id = p.Id,
			Name = p.Name,
			IsBot = p.IsBot,
			Team = p.Team,
			Hits = p.Hits,
			Taken = p.Taken,
			RoundHits = p.RoundHits,
			Score = final,
			Ratio = math.floor(ratio * 100 + 0.5) / 100,
			Tier = p.Tier,
		})
	end
	table.sort(rows, function(a, b)
		if a.Score ~= b.Score then
			return a.Score > b.Score
		end
		return a.Hits > b.Hits
	end)
	return rows
end

return ParticipantService
