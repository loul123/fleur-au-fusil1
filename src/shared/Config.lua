--[[
	La fleur au fusil — Configuration partagée (ModuleScript)
	Emplacement : ReplicatedStorage > FleurShared > Config

	Tout le réglage du jeu se fait ici : cadence, dégâts, modes, score, bots.
	Ce module est lu à la fois par le serveur et par les clients.
]]

local Config = {}

Config.ToolName = "FleurAuFusil"
Config.RemotesFolderName = "FleurRemotes"
Config.BotsFolderName = "FleurBots"

---------------------------------------------------------------------------
-- Carte : le potager géant (les personnages paraissent minuscules)
---------------------------------------------------------------------------
Config.Map = {
	Generate = true, -- false si vous construisez votre propre potager (voir README)
	Size = 700, -- côté de la zone de jeu (studs)
	WallHeight = 90, -- hauteur de la clôture en planches
	Seed = 2024, -- graine du placement des légumes
	CharacterScale = 1, -- < 1 pour rétrécir encore les personnages (ex. 0.6)
}

---------------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------------
Config.Combat = {
	MaxHealth = 100, -- « vitalité » d'un personnage
	RespawnTime = 4, -- secondes avant de refleurir
	SpawnProtection = 2.5, -- durée du ForceField d'apparition
	PetalGravity = 22, -- studs/s² : les pétales planent légèrement
	PetalLifetime = 2.5, -- durée de vie max d'un pétale (s)
	PetalRadius = 0.5, -- rayon de collision du pétale (Spherecast)
	MaxOriginOffset = 14, -- anti-triche : distance max entre le tireur et l'origine envoyée
	CooldownTolerance = 0.85, -- tolérance réseau sur la cadence côté serveur
}

---------------------------------------------------------------------------
-- Fleurs (armes). En Gun Game, on progresse de palier en palier.
-- Cooldown = secondes entre deux tirs (anti-spam)
---------------------------------------------------------------------------
Config.WeaponTiers = {
	{ Name = "Pâquerette", Cooldown = 0.35, Speed = 190, Damage = 20, Petals = 1, Spread = 0.6, PetalColor = Color3.fromRGB(255, 255, 255), HeartColor = Color3.fromRGB(255, 215, 0) },
	{ Name = "Marguerite", Cooldown = 0.25, Speed = 200, Damage = 17, Petals = 1, Spread = 1.4, PetalColor = Color3.fromRGB(250, 250, 235), HeartColor = Color3.fromRGB(255, 180, 0) },
	{ Name = "Tulipe", Cooldown = 0.65, Speed = 165, Damage = 14, Petals = 4, Spread = 5.0, PetalColor = Color3.fromRGB(255, 70, 110), HeartColor = Color3.fromRGB(60, 40, 20) },
	{ Name = "Tournesol", Cooldown = 0.11, Speed = 220, Damage = 9, Petals = 1, Spread = 2.6, PetalColor = Color3.fromRGB(255, 200, 0), HeartColor = Color3.fromRGB(90, 50, 20) },
	{ Name = "Rose", Cooldown = 0.95, Speed = 420, Damage = 55, Petals = 1, Spread = 0.0, PetalColor = Color3.fromRGB(200, 0, 40), HeartColor = Color3.fromRGB(120, 0, 20) },
	{ Name = "Lys", Cooldown = 0.45, Speed = 240, Damage = 22, Petals = 2, Spread = 1.5, PetalColor = Color3.fromRGB(255, 160, 60), HeartColor = Color3.fromRGB(140, 60, 0) },
	{ Name = "Pissenlit", Cooldown = 0.08, Speed = 150, Damage = 7, Petals = 1, Spread = 5.5, PetalColor = Color3.fromRGB(255, 240, 80), HeartColor = Color3.fromRGB(200, 170, 0) },
	{ Name = "Orchidée", Cooldown = 0.30, Speed = 270, Damage = 35, Petals = 1, Spread = 0.4, PetalColor = Color3.fromRGB(190, 90, 255), HeartColor = Color3.fromRGB(255, 255, 255) },
}
Config.DefaultTier = 1 -- fleur utilisée hors Gun Game

function Config.GetTier(index)
	index = math.clamp(math.floor(tonumber(index) or Config.DefaultTier), 1, #Config.WeaponTiers)
	return Config.WeaponTiers[index], index
end

-- Dévie une direction aléatoirement dans un cône de `degrees` degrés.
function Config.ApplySpread(direction, degrees, rng)
	local unit = direction.Unit
	if degrees <= 0 then
		return unit
	end
	local r = rng or Random.new()
	local basis = CFrame.lookAt(Vector3.zero, unit)
	local angle = math.rad(degrees) * math.sqrt(r:NextNumber())
	local roll = r:NextNumber() * math.pi * 2
	return (basis * CFrame.Angles(0, 0, roll) * CFrame.Angles(angle, 0, 0)).LookVector
end

---------------------------------------------------------------------------
-- Score
--   Touches données  : +HitPoints chacune
--   Touches reçues   : -PenaltyPoints chacune (points de pénalité)
--   Ratio            : touches / max(1, reçues)
--   Score final      : base × multiplicateur(ratio), borné entre Min et Max
--                      (ratio 0 → ×0.5, ratio 1 → ×1, ratio 3+ → ×2)
--                      un score de base négatif n'est pas multiplié.
---------------------------------------------------------------------------
Config.Scoring = {
	HitPoints = 10,
	PenaltyPoints = 5,
	MinMultiplier = 0.5,
	MaxMultiplier = 2,
}

function Config.ComputeScore(hits, taken)
	local s = Config.Scoring
	local base = hits * s.HitPoints - taken * s.PenaltyPoints
	local ratio = hits / math.max(1, taken)
	local multiplier = math.clamp(0.5 + ratio * 0.5, s.MinMultiplier, s.MaxMultiplier)
	local final = if base > 0 then math.floor(base * multiplier + 0.5) else base
	return final, ratio, base, multiplier
end

---------------------------------------------------------------------------
-- Équipes (Match à mort par équipe)
---------------------------------------------------------------------------
Config.Teams = {
	{ Name = "Coquelicots", BrickColor = BrickColor.new("Bright red") },
	{ Name = "Bleuets", BrickColor = BrickColor.new("Bright blue") },
}

---------------------------------------------------------------------------
-- Modes de jeu (façon Call of Duty)
---------------------------------------------------------------------------
Config.Modes = {
	TDM = {
		DisplayName = "Match à mort par équipe",
		Description = "Coquelicots contre Bleuets : la première équipe à %d touches gagne la manche.",
		Teams = true,
		Rounds = 3, -- au meilleur des 3 manches
		RoundTime = 180,
		TargetPerRound = 40, -- touches d'équipe pour gagner la manche
	},
	FFA = {
		DisplayName = "Chacun pour soi",
		Description = "Tout le monde contre tout le monde : premier à %d touches gagne la manche.",
		Teams = false,
		Rounds = 3,
		RoundTime = 150,
		TargetPerRound = 20,
	},
	GunGame = {
		DisplayName = "Gun Game : premier à 200 touches",
		Description = "Votre fleur évolue toutes les %d touches. Premier à %d touches remporte la partie !",
		Teams = false,
		Rounds = 1,
		RoundTime = 900,
		TargetPerRound = 200,
		TierEvery = 25, -- 8 fleurs × 25 = 200
	},
}
Config.ModeRotation = { "TDM", "FFA", "GunGame" }

Config.IntermissionTime = 15 -- avant chaque partie
Config.RoundBreakTime = 8 -- entre deux manches
Config.ResultsTime = 14 -- écran de résultats

---------------------------------------------------------------------------
-- Bots
---------------------------------------------------------------------------
Config.Bots = {
	Enabled = true,
	FillTo = 6, -- complète jusqu'à ce nombre de combattants (joueurs + bots)
	MaxBots = 10,
	Names = {
		"Radis", "Courgette", "Navet", "Poireau", "Potiron", "Cornichon",
		"Artichaut", "Betterave", "Céleri", "Panais", "Échalote", "Rutabaga",
	},
	WalkSpeed = 15,
	ThinkInterval = 0.15, -- secondes entre deux décisions
	SightRange = 260,
	PreferredRange = 55, -- distance de combat idéale
	ReactionTime = 0.45, -- délai avant le premier tir sur une nouvelle cible
	AimErrorDegrees = 3.5, -- imprécision (plus haut = plus facile)
	LeadSkill = 0.7, -- 0 = ne vise pas devant, 1 = anticipation parfaite
	RepathInterval = 2.5,
	Animations = { -- animations R15 par défaut de Roblox
		Idle = "rbxassetid://507766388",
		Walk = "rbxassetid://507777826",
		Hold = "rbxassetid://507768375",
	},
}

---------------------------------------------------------------------------
-- Sons (remplaçables par vos propres assets)
---------------------------------------------------------------------------
Config.Sounds = {
	Shoot = "rbxasset://sounds/swordslash.wav",
	Hit = "rbxasset://sounds/electronicpingshort.wav",
}

return Config
