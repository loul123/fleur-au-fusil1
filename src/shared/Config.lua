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
-- Cartes : 10 potagers à thème + 1 « multi » (tous les légumes)
-- L'Id doit correspondre à un thème défini dans MapBuilder (THEMES).
---------------------------------------------------------------------------
Config.Maps = {
	{ Id = "Tomates", Name = "Le Rang des Tomates", Description = "Plants de tomates géants sur tuteurs, à midi." },
	{ Id = "Ail", Name = "Le Champ d'Ail", Description = "Têtes d'ail et longues tiges, dans la lumière du matin." },
	{ Id = "Carottes", Name = "Le Carré de Carottes", Description = "Des fanes partout : idéal pour se cacher." },
	{ Id = "Citrouilles", Name = "Le Champ de Citrouilles", Description = "Énormes citrouilles au crépuscule, gare à l'épouvantail." },
	{ Id = "Salades", Name = "Le Jardin des Salades", Description = "Laitues et radis sous un ciel couvert." },
	{ Id = "Fraises", Name = "Le Fraisier", Description = "Fraises géantes sur un lit de paille." },
	{ Id = "Mais", Name = "Le Labyrinthe de Maïs", Description = "Des tiges de maïs très hautes forment un dédale." },
	{ Id = "Choux", Name = "Le Potager de Choux", Description = "Choux verts et rouges dans la brume du matin." },
	{ Id = "Piments", Name = "Le Coin des Piments", Description = "Poivrons et piments sous un soleil brûlant." },
	{ Id = "Tournesols", Name = "Le Champ de Tournesols", Description = "Tournesols gigantesques en fin d'après-midi." },
	{ Id = "Multi", Name = "Le Grand Potager", Description = "Un peu de tout : tous les légumes réunis." },
}

Config.MapSelection = {
	Mode = "Vote", -- "Vote" (les joueurs votent), "Rotation" (dans l'ordre) ou "Random"
	Choices = 3, -- nombre de cartes proposées au vote
	StartMap = "Multi", -- carte chargée au démarrage du serveur
}

function Config.GetMap(id)
	for _, m in Config.Maps do
		if m.Id == id then
			return m
		end
	end
	return nil
end

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
-- Pass de saison (battle pass) & graines
---------------------------------------------------------------------------
Config.BattlePass = {
	Season = 1, -- changer ce numéro remet la progression (graines) à zéro ; les objets gagnés restent
	SeasonName = "Saison 1 — Printemps au potager",

	-- Pass Premium payant = un Game Pass Roblox. Créez-le sur create.roblox.com
	-- (votre expérience > Monétisation > Passes) et collez son ID ici.
	-- Conseil : un nouveau Game Pass par saison.
	GamePassId = 0,
	StudioFreePremium = true, -- si GamePassId = 0 : dans Studio, le bouton d'achat débloque le premium (test)
	PremiumSeedBonus = 0.2, -- +20 % de graines avec le pass premium

	-- Graines gagnées en fin de partie (en fonction des statistiques)
	Seeds = {
		WinBase = 40, -- bonus de victoire
		PerHit = 1, -- par touche donnée
		ScorePerSeed = 20, -- 1 graine pour 20 points de score final
		RatioBonusPerPoint = 10, -- par point de ratio touches/reçues…
		RatioBonusMax = 30, -- …plafonné
		MVPBonus = 15, -- meilleur score de la partie
		LoserShare = 0.3, -- part reçue en cas de défaite (0 = seuls les gagnants gagnent des graines)
		MaxPerMatch = 250,
	},

	-- Paliers : graines cumulées dans la saison (progression, jamais dépensées) → récompenses.
	-- Type = "FlowerSkin" | "WeaponSkin" | "PetalEffect" (Id de Cosmetics.lua)
	--      ou "Pack" (Id = "Sachet" / "SachetDore", Count = nombre de sachets).
	-- Free = piste gratuite, Premium = piste payante (nil = rien à ce palier).
	-- Les fleurs Mythique, Divin, Secret, Transcendant et Ultime ne s'obtiennent qu'en sachet.
	Tiers = {
		{ Seeds = 60, Free = { Type = "FlowerSkin", Id = "MargueritonJaune" }, Premium = { Type = "FlowerSkin", Id = "PetuniaRose" } }, -- 1 : Margueriton Jaune / Petunia Rose
		{ Seeds = 130, Free = { Type = "FlowerSkin", Id = "Pissenlit" }, Premium = { Type = "FlowerSkin", Id = "PetuniaViolet" } }, -- 2 : Dandelion / Pissenlit / Petunia Violet
		{ Seeds = 220, Free = { Type = "Pack", Id = "Sachet", Count = 1 }, Premium = { Type = "FlowerSkin", Id = "LavandeSauvage" } }, -- 3 : Sachet / Lavande Sauvage
		{ Seeds = 330, Free = { Type = "FlowerSkin", Id = "TrefleATroisFeuilles" }, Premium = { Type = "FlowerSkin", Id = "HortensiaBleu" } }, -- 4 : Trèfle à Trois Feuilles / Hortensia Bleu
		{ Seeds = 450, Free = { Type = "FlowerSkin", Id = "TulipeRouge" }, Premium = { Type = "Pack", Id = "SachetDore", Count = 1 } }, -- 5 : Tulipe Rouge / SachetDore
		{ Seeds = 590, Free = { Type = "PetalEffect", Id = "Traine" }, Premium = { Type = "FlowerSkin", Id = "HortensiaRose" } }, -- 6 : Traine / Hortensia Rose
		{ Seeds = 740, Free = { Type = "FlowerSkin", Id = "TulipeJaune" }, Premium = { Type = "FlowerSkin", Id = "HibiscusRouge" } }, -- 7 : Tulipe Jaune / Hibiscus Rouge
		{ Seeds = 910, Free = { Type = "FlowerSkin", Id = "TulipeRose" }, Premium = { Type = "FlowerSkin", Id = "HibiscusJaune" } }, -- 8 : Tulipe Rose / Hibiscus Jaune
		{ Seeds = 1100, Free = { Type = "Pack", Id = "Sachet", Count = 1 }, Premium = { Type = "FlowerSkin", Id = "LysBlanc" } }, -- 9 : Sachet / Lys Blanc
		{ Seeds = 1300, Free = { Type = "FlowerSkin", Id = "PenseeBleue" }, Premium = { Type = "WeaponSkin", Id = "NuitBleue" } }, -- 10 : Pensée Bleue / NuitBleue
		{ Seeds = 1520, Free = { Type = "FlowerSkin", Id = "PenseeViolette" }, Premium = { Type = "FlowerSkin", Id = "LysRose" } }, -- 11 : Pensée Violette / Lys Rose
		{ Seeds = 1750, Free = { Type = "Pack", Id = "Sachet", Count = 1 }, Premium = { Type = "PetalEffect", Id = "Tourbillon" } }, -- 12 : Sachet / Tourbillon
		{ Seeds = 2000, Free = { Type = "FlowerSkin", Id = "RoseSauvage" }, Premium = { Type = "FlowerSkin", Id = "PivoineRose" } }, -- 13 : Rose Sauvage / Pivoine Rose
		{ Seeds = 2270, Free = { Type = "FlowerSkin", Id = "OeilletDesPres" }, Premium = { Type = "FlowerSkin", Id = "MagnoliaBlanc" } }, -- 14 : Œillet des Prés / Magnolia Blanc
		{ Seeds = 2550, Free = { Type = "WeaponSkin", Id = "Potager" }, Premium = { Type = "Pack", Id = "SachetDore", Count = 1 } }, -- 15 : Potager / SachetDore
		{ Seeds = 2850, Free = { Type = "FlowerSkin", Id = "BoutonDOr" }, Premium = { Type = "FlowerSkin", Id = "OrchideeRose" } }, -- 16 : Bouton d'Or / Orchidée Rose
		{ Seeds = 3160, Free = { Type = "FlowerSkin", Id = "CoquelicotDesChamps" }, Premium = { Type = "FlowerSkin", Id = "OrchideeBlanche" } }, -- 17 : Coquelicot des Champs / Orchidée Blanche
		{ Seeds = 3490, Free = { Type = "Pack", Id = "Sachet", Count = 1 }, Premium = { Type = "WeaponSkin", Id = "OrRose" } }, -- 18 : Sachet / OrRose
		{ Seeds = 3840, Free = { Type = "FlowerSkin", Id = "PrimevereDePrintemps" }, Premium = { Type = "FlowerSkin", Id = "OrchideeViolette" } }, -- 19 : Primevère de Printemps / Orchidée Violette
		{ Seeds = 4200, Free = { Type = "PetalEffect", Id = "Etincelles" }, Premium = { Type = "PetalEffect", Id = "Coeurs" } }, -- 20 : Etincelles / Coeurs
		{ Seeds = 4580, Free = { Type = "Pack", Id = "Sachet", Count = 1 }, Premium = { Type = "FlowerSkin", Id = "RoseNoire" } }, -- 21 : Sachet / Rose Noire
		{ Seeds = 4970, Free = { Type = "FlowerSkin", Id = "VioletteDesBois" }, Premium = { Type = "WeaponSkin", Id = "CoquelicotRoyal" } }, -- 22 : Violette des Bois / CoquelicotRoyal
		{ Seeds = 5380, Free = { Type = "FlowerSkin", Id = "PaqueretteRose" }, Premium = { Type = "FlowerSkin", Id = "RoseDOrnement" } }, -- 23 : Pâquerette Rose / Rose d'Ornement
		{ Seeds = 5810, Free = { Type = "Pack", Id = "Sachet", Count = 1 }, Premium = { Type = "FlowerSkin", Id = "FleurDeGivre" } }, -- 24 : Sachet / Fleur de Givre
		{ Seeds = 6250, Free = { Type = "FlowerSkin", Id = "BleuetSauvage" }, Premium = { Type = "Pack", Id = "SachetDore", Count = 1 } }, -- 25 : Bleuet Sauvage / SachetDore
		{ Seeds = 6710, Free = { Type = "FlowerSkin", Id = "MyosotisDEau" }, Premium = { Type = "FlowerSkin", Id = "LotusDArgent" } }, -- 26 : Myosotis d'Eau / Lotus d'Argent
		{ Seeds = 7180, Free = { Type = "Pack", Id = "Sachet", Count = 1 }, Premium = { Type = "FlowerSkin", Id = "RoseDEmeraude" } }, -- 27 : Sachet / Rose d'Émeraude
		{ Seeds = 7670, Free = { Type = "FlowerSkin", Id = "LilasBlanc" }, Premium = { Type = "PetalEffect", Id = "ArcEnCiel" } }, -- 28 : Lilas Blanc / ArcEnCiel
		{ Seeds = 8180, Free = { Type = "FlowerSkin", Id = "GerberaDesJardins" }, Premium = { Type = "FlowerSkin", Id = "FleurDeCrepuscule" } }, -- 29 : Gerbera des Jardins / Fleur de Crépuscule
		{ Seeds = 8700, Free = { Type = "Pack", Id = "SachetDore", Count = 1 }, Premium = { Type = "WeaponSkin", Id = "JardinNeon" } }, -- 30 : SachetDore / JardinNeon
	},
}

---------------------------------------------------------------------------
-- Boutique Robux : sachets de graines (Developer Products)
-- Créez chaque produit sur create.roblox.com > votre expérience >
-- Monétisation > Produits pour développeurs, fixez le prix, collez l'ID.
-- Le prix affiché en jeu est lu automatiquement chez Roblox.
---------------------------------------------------------------------------
Config.Shop = {
	StudioFreeProducts = true, -- si ProductId = 0 : dans Studio, l'achat est simulé (gratuit, pour tester)
	Products = {
		{ Key = "Sachet1", PackId = "Sachet", Count = 1, ProductId = 0, Label = "×1" },
		{ Key = "Sachet5", PackId = "Sachet", Count = 5, ProductId = 0, Label = "×5" },
		{ Key = "SachetDore1", PackId = "SachetDore", Count = 1, ProductId = 0, Label = "×1" },
		{ Key = "SachetDore5", PackId = "SachetDore", Count = 5, ProductId = 0, Label = "×5" },
	},
}

function Config.GetProduct(key)
	for _, product in Config.Shop.Products do
		if product.Key == key then
			return product
		end
	end
	return nil
end

function Config.GetProductById(productId)
	for _, product in Config.Shop.Products do
		if product.ProductId ~= 0 and product.ProductId == productId then
			return product
		end
	end
	return nil
end

-- Graines d'une partie. stats = { Won, Hits, Taken, FinalScore, Ratio, IsMVP }
function Config.ComputeSeeds(stats, hasPremium)
	local s = Config.BattlePass.Seeds
	local lines = {}
	local function add(label, amount)
		amount = math.floor(amount + 0.5)
		if amount > 0 then
			table.insert(lines, { Label = label, Amount = amount })
		end
		return amount
	end
	if stats.Hits == 0 and stats.Taken == 0 then
		return 0, lines -- inactif : rien
	end
	local total = 0
	if stats.Won then
		total += add("Victoire", s.WinBase)
	end
	total += add("Touches", stats.Hits * s.PerHit)
	total += add("Score", math.max(0, stats.FinalScore) / s.ScorePerSeed)
	total += add("Ratio", math.min(s.RatioBonusMax, stats.Ratio * s.RatioBonusPerPoint))
	if stats.IsMVP then
		total += add("MVP", s.MVPBonus)
	end
	if not stats.Won then
		local before = total
		total = math.floor(total * s.LoserShare + 0.5)
		table.insert(lines, { Label = string.format("Défaite (×%.1f)", s.LoserShare), Amount = total - before })
	end
	if hasPremium and total > 0 then
		local bonus = math.floor(total * Config.BattlePass.PremiumSeedBonus + 0.5)
		total += add("Bonus Premium", bonus)
	end
	total = math.min(total, s.MaxPerMatch)
	return total, lines
end

---------------------------------------------------------------------------
-- Sons (remplaçables par vos propres assets)
---------------------------------------------------------------------------
Config.Sounds = {
	Shoot = "rbxasset://sounds/swordslash.wav",
	Hit = "rbxasset://sounds/electronicpingshort.wav",
}

return Config
