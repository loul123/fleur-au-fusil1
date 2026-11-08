--[[
	La fleur au fusil — Catalogue des cosmétiques (ModuleScript partagé)
	Emplacement : ReplicatedStorage > FleurShared > Cosmetics

	Trois catégories :
	  * WeaponSkin  : couleurs/matériaux du fusil
	  * FlowerSkin  : la fleur au bout du canon (et la couleur des pétales tirés)
	  * PetalEffect : « animation » des pétales tirés (traînée, étincelles,
	                  orbite, effet d'impact…)
	Les récompenses du pass de saison (Config.BattlePass.Tiers) pointent vers
	ces Id. Pour ajouter un objet : ajoutez une entrée ici, puis référencez
	son Id dans un palier.
]]

local Cosmetics = {}

Cosmetics.Rarities = {
	Commun = { Order = 1, Color = Color3.fromRGB(170, 180, 170), Label = "Commun" },
	Rare = { Order = 2, Color = Color3.fromRGB(80, 160, 255), Label = "Rare" },
	Epique = { Order = 3, Color = Color3.fromRGB(190, 90, 255), Label = "Épique" },
	Legendaire = { Order = 4, Color = Color3.fromRGB(255, 190, 40), Label = "Légendaire" },
}

Cosmetics.TypeLabels = {
	WeaponSkin = "Skin d'arme",
	FlowerSkin = "Fleur",
	PetalEffect = "Animation de pétales",
}

---------------------------------------------------------------------------
-- Skins d'arme
--   Body : carcasse (jaune-orangé sur le modèle de base)
--   Accent : crosse, garde-main, poignée, talon du chargeur
--   Metal : canon, lunette, chargeur, rails ; Dark : fentes et détails
---------------------------------------------------------------------------
Cosmetics.WeaponSkins = {
	{ Id = "Classique", Name = "Classique", Rarity = "Commun",
		Body = Color3.fromRGB(245, 170, 40), Accent = Color3.fromRGB(240, 125, 35), Metal = Color3.fromRGB(150, 155, 165), Dark = Color3.fromRGB(80, 82, 90) },
	{ Id = "Potager", Name = "Camouflage Potager", Rarity = "Rare",
		Body = Color3.fromRGB(110, 140, 60), Accent = Color3.fromRGB(125, 90, 55), Metal = Color3.fromRGB(85, 95, 75), Dark = Color3.fromRGB(45, 50, 35) },
	{ Id = "NuitBleue", Name = "Nuit Bleue", Rarity = "Rare",
		Body = Color3.fromRGB(40, 60, 140), Accent = Color3.fromRGB(90, 150, 255), Metal = Color3.fromRGB(45, 45, 60), Dark = Color3.fromRGB(20, 20, 30) },
	{ Id = "OrRose", Name = "Or Rose", Rarity = "Epique", Material = "Metal",
		Body = Color3.fromRGB(240, 180, 165), Accent = Color3.fromRGB(255, 215, 130), Metal = Color3.fromRGB(225, 205, 195), Dark = Color3.fromRGB(150, 110, 100) },
	{ Id = "CoquelicotRoyal", Name = "Coquelicot Royal", Rarity = "Epique",
		Body = Color3.fromRGB(200, 20, 40), Accent = Color3.fromRGB(35, 35, 35), Metal = Color3.fromRGB(235, 235, 235), Dark = Color3.fromRGB(15, 15, 15) },
	{ Id = "JardinNeon", Name = "Jardin Néon", Rarity = "Legendaire", AccentMaterial = "Neon",
		Body = Color3.fromRGB(25, 25, 35), Accent = Color3.fromRGB(0, 255, 170), Metal = Color3.fromRGB(60, 60, 75), Dark = Color3.fromRGB(255, 0, 200) },
}

---------------------------------------------------------------------------
-- Fleurs
--   Petals : nombre de pétales ; PetalLength / PetalWidth : forme (×1 = marguerite)
---------------------------------------------------------------------------
Cosmetics.FlowerSkins = {
	{ Id = "Marguerite", Name = "Marguerite", Rarity = "Commun", Petals = 12, PetalLength = 1, PetalWidth = 1,
		PetalColor = Color3.fromRGB(255, 255, 255), HeartColor = Color3.fromRGB(255, 215, 0), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "Bleuet", Name = "Bleuet", Rarity = "Rare", Petals = 10, PetalLength = 0.9, PetalWidth = 0.8,
		PetalColor = Color3.fromRGB(70, 110, 255), HeartColor = Color3.fromRGB(40, 30, 110), StemColor = Color3.fromRGB(70, 150, 90) },
	{ Id = "Coquelicot", Name = "Coquelicot", Rarity = "Rare", Petals = 5, PetalLength = 1.1, PetalWidth = 2.1,
		PetalColor = Color3.fromRGB(230, 30, 30), HeartColor = Color3.fromRGB(25, 20, 20), StemColor = Color3.fromRGB(70, 150, 60) },
	{ Id = "Tournesol", Name = "Tournesol", Rarity = "Epique", Petals = 16, PetalLength = 1.1, PetalWidth = 0.9, HeartScale = 1.3,
		PetalColor = Color3.fromRGB(255, 200, 0), HeartColor = Color3.fromRGB(90, 50, 20), StemColor = Color3.fromRGB(60, 140, 40) },
	{ Id = "Sakura", Name = "Fleur de cerisier", Rarity = "Epique", Petals = 5, PetalLength = 0.95, PetalWidth = 1.9,
		PetalColor = Color3.fromRGB(255, 180, 210), HeartColor = Color3.fromRGB(255, 240, 150), StemColor = Color3.fromRGB(120, 80, 60) },
	{ Id = "LotusCeleste", Name = "Lotus céleste", Rarity = "Legendaire", Petals = 14, PetalLength = 1.15, PetalWidth = 1.2, HeartMaterial = "Neon",
		PetalColor = Color3.fromRGB(200, 220, 255), HeartColor = Color3.fromRGB(120, 255, 255), StemColor = Color3.fromRGB(60, 200, 170) },
}

---------------------------------------------------------------------------
-- Animations de pétales
--   Trail : "Rainbow" ou "Color" ; Sparkles : étincelles ; Orbit : nb de
--   mini-pétales en orbite ; Impact : "Burst" | "Hearts" | "Rain" ; Size : taille
---------------------------------------------------------------------------
Cosmetics.PetalEffects = {
	{ Id = "Simple", Name = "Pétale simple", Rarity = "Commun", Impact = "Burst" },
	{ Id = "Traine", Name = "Traînée florale", Rarity = "Rare", Trail = "Color", Impact = "Burst" },
	{ Id = "Etincelles", Name = "Étincelles", Rarity = "Rare", Sparkles = true, Impact = "Burst" },
	{ Id = "Tourbillon", Name = "Tourbillon", Rarity = "Epique", Orbit = 2, Impact = "Burst" },
	{ Id = "Coeurs", Name = "Pluie de cœurs", Rarity = "Epique", Trail = "Color", Impact = "Hearts" },
	{ Id = "ArcEnCiel", Name = "Arc-en-ciel", Rarity = "Legendaire", Trail = "Rainbow", Sparkles = true, Impact = "Rain", Size = 1.25 },
}

Cosmetics.Defaults = {
	WeaponSkin = "Classique",
	FlowerSkin = "Marguerite",
	PetalEffect = "Simple",
}

local LISTS = {
	WeaponSkin = Cosmetics.WeaponSkins,
	FlowerSkin = Cosmetics.FlowerSkins,
	PetalEffect = Cosmetics.PetalEffects,
}
Cosmetics.Types = { "WeaponSkin", "FlowerSkin", "PetalEffect" }

local index = {}
for typeName, list in LISTS do
	index[typeName] = {}
	for _, item in list do
		item.Type = typeName
		index[typeName][item.Id] = item
	end
end

function Cosmetics.List(typeName)
	return LISTS[typeName] or {}
end

-- Renvoie l'objet demandé, ou l'objet par défaut de la catégorie si l'Id est inconnu
function Cosmetics.Get(typeName, id)
	local byId = index[typeName]
	if not byId then
		return nil
	end
	return byId[id] or byId[Cosmetics.Defaults[typeName]]
end

function Cosmetics.Exists(typeName, id)
	return index[typeName] ~= nil and index[typeName][id] ~= nil
end

function Cosmetics.Key(typeName, id)
	return typeName .. ":" .. id
end

function Cosmetics.IsDefault(typeName, id)
	return Cosmetics.Defaults[typeName] == id
end

-- Tenue complète : { WeaponSkin = Id, FlowerSkin = Id, PetalEffect = Id }
function Cosmetics.DefaultLook()
	return table.clone(Cosmetics.Defaults)
end

function Cosmetics.RandomLook(rng)
	local r = rng or Random.new()
	local look = {}
	for _, typeName in Cosmetics.Types do
		local list = LISTS[typeName]
		look[typeName] = list[r:NextInteger(1, #list)].Id
	end
	return look
end

return Cosmetics
