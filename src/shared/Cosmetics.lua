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

-- Order : du plus courant au plus rare ; Refund : graines rendues pour un doublon de sachet
Cosmetics.Rarities = {
	Commune = { Order = 1, Color = Color3.fromRGB(175, 185, 175), Label = "Commune", Refund = 10 },
	PeuCommune = { Order = 2, Color = Color3.fromRGB(110, 210, 110), Label = "Peu commune", Refund = 20 },
	Rare = { Order = 3, Color = Color3.fromRGB(80, 160, 255), Label = "Rare", Refund = 40 },
	Epique = { Order = 4, Color = Color3.fromRGB(190, 90, 255), Label = "Épique", Refund = 80 },
	Legendaire = { Order = 5, Color = Color3.fromRGB(255, 190, 40), Label = "Légendaire", Refund = 150 },
	Mythique = { Order = 6, Color = Color3.fromRGB(255, 70, 100), Label = "Mythique", Refund = 300 },
	Divin = { Order = 7, Color = Color3.fromRGB(255, 240, 150), Label = "Divin", Refund = 600 },
	Secret = { Order = 8, Color = Color3.fromRGB(110, 255, 230), Label = "Secret", Refund = 1200 },
	Transcendant = { Order = 9, Color = Color3.fromRGB(255, 255, 255), Label = "Secret / Transcendant", Refund = 2500 },
	Ultime = { Order = 10, Color = Color3.fromRGB(255, 120, 255), Label = "Ultime", Refund = 5000, Rainbow = true },
}
Cosmetics.RarityOrder = { "Commune", "PeuCommune", "Rare", "Epique", "Legendaire", "Mythique", "Divin", "Secret", "Transcendant", "Ultime" }

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
	{ Id = "Classique", Name = "Classique", Rarity = "Commune",
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
-- Fleurs : les 100 fleurs, de #100 (Marguerite Blanche) à #1 (La Fleur de l'Infini)
--   Petals : nombre de pétales ; PetalLength / PetalWidth : forme (×1 = marguerite)
--   Options : Layers (2-3 couronnes), PetalColor2 (couronnes intérieures),
--   PetalColors (couleurs alternées / arc-en-ciel), PetalMaterial, HeartMaterial,
--   HeartScale, Aura (particules), AuraRainbow, Light (lumière)
---------------------------------------------------------------------------
Cosmetics.FlowerSkins = {
	-- Commune
	{ Id = "MargueriteBlanche", Number = 100, Name = "Marguerite Blanche", Rarity = "Commune", Petals = 12, PetalLength = 1, PetalWidth = 1, PetalColor = Color3.fromRGB(255, 255, 255), HeartColor = Color3.fromRGB(255, 215, 0), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "MargueritonJaune", Number = 99, Name = "Margueriton Jaune", Rarity = "Commune", Petals = 12, PetalLength = 1, PetalWidth = 1, PetalColor = Color3.fromRGB(255, 220, 40), HeartColor = Color3.fromRGB(230, 140, 20), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "Pissenlit", Number = 98, Name = "Dandelion / Pissenlit", Rarity = "Commune", Petals = 24, PetalLength = 0.8, PetalWidth = 0.5, PetalColor = Color3.fromRGB(255, 210, 0), HeartColor = Color3.fromRGB(240, 180, 0), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "TrefleATroisFeuilles", Number = 97, Name = "Trèfle à Trois Feuilles", Rarity = "Commune", Petals = 3, PetalLength = 1.1, PetalWidth = 2.2, PetalColor = Color3.fromRGB(60, 170, 60), HeartColor = Color3.fromRGB(40, 120, 40), StemColor = Color3.fromRGB(60, 170, 50), HeartScale = 0.4 },
	{ Id = "TulipeRouge", Number = 96, Name = "Tulipe Rouge", Rarity = "Commune", Petals = 6, PetalLength = 1.2, PetalWidth = 1.8, PetalColor = Color3.fromRGB(220, 30, 40), HeartColor = Color3.fromRGB(60, 20, 20), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "TulipeJaune", Number = 95, Name = "Tulipe Jaune", Rarity = "Commune", Petals = 6, PetalLength = 1.2, PetalWidth = 1.8, PetalColor = Color3.fromRGB(255, 210, 40), HeartColor = Color3.fromRGB(120, 80, 10), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "TulipeRose", Number = 94, Name = "Tulipe Rose", Rarity = "Commune", Petals = 6, PetalLength = 1.2, PetalWidth = 1.8, PetalColor = Color3.fromRGB(255, 120, 170), HeartColor = Color3.fromRGB(120, 40, 60), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "PenseeBleue", Number = 93, Name = "Pensée Bleue", Rarity = "Commune", Petals = 5, PetalLength = 0.9, PetalWidth = 2.2, PetalColor = Color3.fromRGB(70, 100, 230), HeartColor = Color3.fromRGB(255, 220, 60), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "PenseeViolette", Number = 92, Name = "Pensée Violette", Rarity = "Commune", Petals = 5, PetalLength = 0.9, PetalWidth = 2.2, PetalColor = Color3.fromRGB(130, 60, 190), HeartColor = Color3.fromRGB(255, 220, 60), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "RoseSauvage", Number = 91, Name = "Rose Sauvage", Rarity = "Commune", Petals = 5, PetalLength = 1, PetalWidth = 2, PetalColor = Color3.fromRGB(255, 150, 180), HeartColor = Color3.fromRGB(255, 230, 120), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "OeilletDesPres", Number = 90, Name = "Œillet des Prés", Rarity = "Commune", Petals = 16, PetalLength = 0.8, PetalWidth = 0.9, PetalColor = Color3.fromRGB(240, 90, 140), HeartColor = Color3.fromRGB(200, 60, 110), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "BoutonDOr", Number = 89, Name = "Bouton d'Or", Rarity = "Commune", Petals = 5, PetalLength = 0.9, PetalWidth = 2, PetalColor = Color3.fromRGB(255, 215, 0), HeartColor = Color3.fromRGB(220, 170, 0), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "CoquelicotDesChamps", Number = 88, Name = "Coquelicot des Champs", Rarity = "Commune", Petals = 4, PetalLength = 1.1, PetalWidth = 2.4, PetalColor = Color3.fromRGB(230, 30, 30), HeartColor = Color3.fromRGB(25, 20, 20), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "PrimevereDePrintemps", Number = 87, Name = "Primevère de Printemps", Rarity = "Commune", Petals = 5, PetalLength = 0.9, PetalWidth = 2, PetalColor = Color3.fromRGB(255, 245, 150), HeartColor = Color3.fromRGB(255, 190, 40), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "VioletteDesBois", Number = 86, Name = "Violette des Bois", Rarity = "Commune", Petals = 5, PetalLength = 0.9, PetalWidth = 1.8, PetalColor = Color3.fromRGB(110, 50, 170), HeartColor = Color3.fromRGB(250, 240, 200), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "PaqueretteRose", Number = 85, Name = "Pâquerette Rose", Rarity = "Commune", Petals = 14, PetalLength = 0.9, PetalWidth = 0.9, PetalColor = Color3.fromRGB(255, 200, 220), HeartColor = Color3.fromRGB(255, 215, 0), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "BleuetSauvage", Number = 84, Name = "Bleuet Sauvage", Rarity = "Commune", Petals = 10, PetalLength = 0.9, PetalWidth = 0.8, PetalColor = Color3.fromRGB(60, 100, 240), HeartColor = Color3.fromRGB(40, 30, 110), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "MyosotisDEau", Number = 83, Name = "Myosotis d'Eau", Rarity = "Commune", Petals = 5, PetalLength = 0.7, PetalWidth = 2, PetalColor = Color3.fromRGB(120, 180, 255), HeartColor = Color3.fromRGB(255, 230, 80), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "LilasBlanc", Number = 82, Name = "Lilas Blanc", Rarity = "Commune", Petals = 16, PetalLength = 0.6, PetalWidth = 1.2, PetalColor = Color3.fromRGB(245, 240, 250), HeartColor = Color3.fromRGB(230, 220, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	{ Id = "GerberaDesJardins", Number = 81, Name = "Gerbera des Jardins", Rarity = "Commune", Petals = 20, PetalLength = 1.1, PetalWidth = 0.8, PetalColor = Color3.fromRGB(255, 110, 40), HeartColor = Color3.fromRGB(90, 50, 20), StemColor = Color3.fromRGB(60, 170, 50) },
	-- PeuCommune
	{ Id = "PetuniaRose", Number = 80, Name = "Petunia Rose", Rarity = "PeuCommune", Petals = 5, PetalLength = 1, PetalWidth = 2.2, PetalColor = Color3.fromRGB(255, 90, 170), HeartColor = Color3.fromRGB(255, 240, 200), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "PetuniaViolet", Number = 79, Name = "Petunia Violet", Rarity = "PeuCommune", Petals = 5, PetalLength = 1, PetalWidth = 2.2, PetalColor = Color3.fromRGB(150, 60, 200), HeartColor = Color3.fromRGB(255, 240, 200), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "LavandeSauvage", Number = 78, Name = "Lavande Sauvage", Rarity = "PeuCommune", Petals = 18, PetalLength = 0.6, PetalWidth = 0.6, PetalColor = Color3.fromRGB(170, 130, 230), HeartColor = Color3.fromRGB(130, 90, 200), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	{ Id = "HortensiaBleu", Number = 77, Name = "Hortensia Bleu", Rarity = "PeuCommune", Petals = 16, PetalLength = 0.7, PetalWidth = 1.4, PetalColor = Color3.fromRGB(110, 150, 255), HeartColor = Color3.fromRGB(90, 120, 230), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	{ Id = "HortensiaRose", Number = 76, Name = "Hortensia Rose", Rarity = "PeuCommune", Petals = 16, PetalLength = 0.7, PetalWidth = 1.4, PetalColor = Color3.fromRGB(255, 150, 200), HeartColor = Color3.fromRGB(230, 110, 170), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	{ Id = "HibiscusRouge", Number = 75, Name = "Hibiscus Rouge", Rarity = "PeuCommune", Petals = 5, PetalLength = 1.2, PetalWidth = 2.4, PetalColor = Color3.fromRGB(220, 20, 50), HeartColor = Color3.fromRGB(255, 230, 100), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "HibiscusJaune", Number = 74, Name = "Hibiscus Jaune", Rarity = "PeuCommune", Petals = 5, PetalLength = 1.2, PetalWidth = 2.4, PetalColor = Color3.fromRGB(255, 215, 60), HeartColor = Color3.fromRGB(200, 40, 40), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "LysBlanc", Number = 73, Name = "Lys Blanc", Rarity = "PeuCommune", Petals = 6, PetalLength = 1.3, PetalWidth = 1.2, PetalColor = Color3.fromRGB(250, 250, 245), HeartColor = Color3.fromRGB(240, 200, 80), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "LysRose", Number = 72, Name = "Lys Rose", Rarity = "PeuCommune", Petals = 6, PetalLength = 1.3, PetalWidth = 1.2, PetalColor = Color3.fromRGB(255, 160, 190), HeartColor = Color3.fromRGB(240, 200, 80), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "PivoineRose", Number = 71, Name = "Pivoine Rose", Rarity = "PeuCommune", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(255, 140, 180), HeartColor = Color3.fromRGB(255, 200, 215), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(255, 200, 220) },
	{ Id = "PivoineBlanche", Number = 70, Name = "Pivoine Blanche", Rarity = "PeuCommune", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(250, 245, 245), HeartColor = Color3.fromRGB(255, 220, 230), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(255, 225, 235) },
	{ Id = "TournesolDesPlaines", Number = 69, Name = "Tournesol des Plaines", Rarity = "PeuCommune", Petals = 16, PetalLength = 1.1, PetalWidth = 0.9, PetalColor = Color3.fromRGB(255, 195, 0), HeartColor = Color3.fromRGB(90, 50, 20), StemColor = Color3.fromRGB(60, 170, 50), HeartScale = 1.3 },
	{ Id = "AnemoneDePrintemps", Number = 68, Name = "Anémone de Printemps", Rarity = "PeuCommune", Petals = 6, PetalLength = 1, PetalWidth = 2, PetalColor = Color3.fromRGB(230, 60, 90), HeartColor = Color3.fromRGB(30, 30, 60), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "AzaleeRose", Number = 67, Name = "Azalée Rose", Rarity = "PeuCommune", Petals = 5, PetalLength = 1, PetalWidth = 2, PetalColor = Color3.fromRGB(255, 100, 160), HeartColor = Color3.fromRGB(255, 220, 230), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "ChrysanthemeDore", Number = 66, Name = "Chrysanthème Doré", Rarity = "PeuCommune", Petals = 24, PetalLength = 0.9, PetalWidth = 0.5, PetalColor = Color3.fromRGB(255, 190, 30), HeartColor = Color3.fromRGB(230, 150, 0), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalMaterial = "Metal" },
	{ Id = "GlaieulRouge", Number = 65, Name = "Glaïeul Rouge", Rarity = "PeuCommune", Petals = 6, PetalLength = 1.1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(210, 20, 40), HeartColor = Color3.fromRGB(255, 200, 200), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "JasminDEte", Number = 64, Name = "Jasmin d'Été", Rarity = "PeuCommune", Petals = 5, PetalLength = 1, PetalWidth = 1.6, PetalColor = Color3.fromRGB(255, 255, 240), HeartColor = Color3.fromRGB(255, 240, 180), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "JacintheBleue", Number = 63, Name = "Jacinthe Bleue", Rarity = "PeuCommune", Petals = 12, PetalLength = 0.6, PetalWidth = 0.9, PetalColor = Color3.fromRGB(80, 90, 230), HeartColor = Color3.fromRGB(60, 60, 180), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	{ Id = "CameliaRose", Number = 62, Name = "Camélia Rose", Rarity = "PeuCommune", Petals = 8, PetalLength = 1, PetalWidth = 1.9, PetalColor = Color3.fromRGB(255, 110, 150), HeartColor = Color3.fromRGB(255, 215, 90), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	{ Id = "DahliaRouge", Number = 61, Name = "Dahlia Rouge", Rarity = "PeuCommune", Petals = 16, PetalLength = 1, PetalWidth = 1, PetalColor = Color3.fromRGB(200, 20, 40), HeartColor = Color3.fromRGB(150, 10, 30), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	-- Rare
	{ Id = "MagnoliaBlanc", Number = 60, Name = "Magnolia Blanc", Rarity = "Rare", Petals = 8, PetalLength = 1.3, PetalWidth = 1.6, PetalColor = Color3.fromRGB(250, 240, 245), HeartColor = Color3.fromRGB(240, 200, 220), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "OrchideeRose", Number = 59, Name = "Orchidée Rose", Rarity = "Rare", Petals = 5, PetalLength = 1.1, PetalWidth = 2.2, PetalColor = Color3.fromRGB(255, 120, 200), HeartColor = Color3.fromRGB(255, 240, 120), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "OrchideeBlanche", Number = 58, Name = "Orchidée Blanche", Rarity = "Rare", Petals = 5, PetalLength = 1.1, PetalWidth = 2.2, PetalColor = Color3.fromRGB(250, 250, 255), HeartColor = Color3.fromRGB(255, 180, 220), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "OrchideeViolette", Number = 57, Name = "Orchidée Violette", Rarity = "Rare", Petals = 5, PetalLength = 1.1, PetalWidth = 2.2, PetalColor = Color3.fromRGB(160, 60, 220), HeartColor = Color3.fromRGB(255, 240, 120), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "RoseNoire", Number = 56, Name = "Rose Noire", Rarity = "Rare", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(30, 20, 30), HeartColor = Color3.fromRGB(80, 0, 20), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(60, 0, 20) },
	{ Id = "RoseDOrnement", Number = 55, Name = "Rose d'Ornement", Rarity = "Rare", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(230, 40, 90), HeartColor = Color3.fromRGB(255, 210, 90), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, HeartMaterial = "Metal" },
	{ Id = "FleurDeCerisier", Number = 54, Name = "Fleur de Cerisier", Rarity = "Rare", Petals = 5, PetalLength = 0.95, PetalWidth = 1.9, PetalColor = Color3.fromRGB(255, 180, 210), HeartColor = Color3.fromRGB(255, 240, 150), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "FleurDeLotusDEau", Number = 53, Name = "Fleur de Lotus d'Eau", Rarity = "Rare", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(255, 190, 220), HeartColor = Color3.fromRGB(255, 240, 140), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(255, 250, 255) },
	{ Id = "PassifloreViolette", Number = 52, Name = "Passiflore Violette", Rarity = "Rare", Petals = 10, PetalLength = 1, PetalWidth = 0.9, PetalColor = Color3.fromRGB(150, 90, 220), HeartColor = Color3.fromRGB(240, 240, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(90, 40, 160) },
	{ Id = "OiseauDuParadis", Number = 51, Name = "Oiseau du Paradis", Rarity = "Rare", Petals = 5, PetalLength = 1.4, PetalWidth = 0.7, PetalColor = Color3.fromRGB(255, 130, 0), HeartColor = Color3.fromRGB(40, 60, 200), StemColor = Color3.fromRGB(60, 170, 50), PetalColors = { Color3.fromRGB(255, 130, 0), Color3.fromRGB(40, 80, 220) } },
	{ Id = "FleurDIrisCeleste", Number = 50, Name = "Fleur d'Iris Céleste", Rarity = "Rare", Petals = 6, PetalLength = 1.1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(110, 140, 255), HeartColor = Color3.fromRGB(255, 220, 80), StemColor = Color3.fromRGB(60, 170, 50), HeartMaterial = "Neon" },
	{ Id = "AmaryllisEcarlate", Number = 49, Name = "Amaryllis Écarlate", Rarity = "Rare", Petals = 6, PetalLength = 1.3, PetalWidth = 1.5, PetalColor = Color3.fromRGB(220, 0, 30), HeartColor = Color3.fromRGB(255, 240, 220), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "ProteaRoyale", Number = 48, Name = "Protea Royale", Rarity = "Rare", Petals = 20, PetalLength = 1, PetalWidth = 0.8, PetalColor = Color3.fromRGB(240, 120, 150), HeartColor = Color3.fromRGB(250, 220, 200), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	{ Id = "BegoniaNocturne", Number = 47, Name = "Begonia Nocturne", Rarity = "Rare", Petals = 6, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(40, 30, 100), HeartColor = Color3.fromRGB(255, 200, 60), StemColor = Color3.fromRGB(60, 170, 50), HeartMaterial = "Neon" },
	{ Id = "DigitalisPourpre", Number = 46, Name = "Digitalis Pourpre", Rarity = "Rare", Petals = 6, PetalLength = 1.1, PetalWidth = 1.6, PetalColor = Color3.fromRGB(160, 40, 140), HeartColor = Color3.fromRGB(255, 220, 240), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "FreesiaDore", Number = 45, Name = "Freesia Doré", Rarity = "Rare", Petals = 6, PetalLength = 1, PetalWidth = 1.6, PetalColor = Color3.fromRGB(255, 200, 50), HeartColor = Color3.fromRGB(255, 240, 180), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Metal" },
	{ Id = "BelladoneSombre", Number = 44, Name = "Belladone Sombre", Rarity = "Rare", Petals = 5, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(70, 20, 80), HeartColor = Color3.fromRGB(20, 10, 20), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "TournesolGeant", Number = 43, Name = "Tournesol Géant", Rarity = "Rare", Petals = 20, PetalLength = 1.4, PetalWidth = 0.9, PetalColor = Color3.fromRGB(255, 200, 0), HeartColor = Color3.fromRGB(80, 45, 15), StemColor = Color3.fromRGB(60, 170, 50), HeartScale = 1.5 },
	{ Id = "CoeurDeMarieRose", Number = 42, Name = "Coeur-de-Marie Rose", Rarity = "Rare", Petals = 4, PetalLength = 1.1, PetalWidth = 2.4, PetalColor = Color3.fromRGB(255, 110, 160), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50) },
	{ Id = "WisteriaViolets", Number = 41, Name = "Wisteria Violets", Rarity = "Rare", Petals = 20, PetalLength = 0.7, PetalWidth = 0.8, PetalColor = Color3.fromRGB(170, 120, 240), HeartColor = Color3.fromRGB(140, 90, 220), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2 },
	-- Epique
	{ Id = "FleurDeGivre", Number = 40, Name = "Fleur de Givre", Rarity = "Epique", Petals = 12, PetalLength = 1, PetalWidth = 1, PetalColor = Color3.fromRGB(200, 240, 255), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Ice", Aura = Color3.fromRGB(200, 240, 255) },
	{ Id = "LotusDArgent", Number = 39, Name = "Lotus d'Argent", Rarity = "Epique", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(220, 220, 230), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalMaterial = "Metal" },
	{ Id = "RoseDEmeraude", Number = 38, Name = "Rose d'Émeraude", Rarity = "Epique", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(20, 200, 100), HeartColor = Color3.fromRGB(0, 120, 60), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalMaterial = "Glass" },
	{ Id = "LysDesOmbres", Number = 37, Name = "Lys des Ombres", Rarity = "Epique", Petals = 6, PetalLength = 1.3, PetalWidth = 1.2, PetalColor = Color3.fromRGB(40, 30, 60), HeartColor = Color3.fromRGB(150, 80, 255), StemColor = Color3.fromRGB(60, 170, 50), HeartMaterial = "Neon", Aura = Color3.fromRGB(150, 80, 255) },
	{ Id = "DahliaSombre", Number = 36, Name = "Dahlia Sombre", Rarity = "Epique", Petals = 16, PetalLength = 1, PetalWidth = 1, PetalColor = Color3.fromRGB(60, 0, 30), HeartColor = Color3.fromRGB(200, 0, 60), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, HeartMaterial = "Neon" },
	{ Id = "OrchideeSaphir", Number = 35, Name = "Orchidée Saphir", Rarity = "Epique", Petals = 5, PetalLength = 1.1, PetalWidth = 2.2, PetalColor = Color3.fromRGB(20, 60, 220), HeartColor = Color3.fromRGB(150, 220, 255), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Glass", HeartMaterial = "Neon" },
	{ Id = "FleurDAmethyste", Number = 34, Name = "Fleur d'Améthyste", Rarity = "Epique", Petals = 8, PetalLength = 1, PetalWidth = 1.6, PetalColor = Color3.fromRGB(150, 60, 220), HeartColor = Color3.fromRGB(220, 180, 255), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Glass", HeartMaterial = "Neon" },
	{ Id = "HibiscusDeFeu", Number = 33, Name = "Hibiscus de Feu", Rarity = "Epique", Petals = 5, PetalLength = 1.2, PetalWidth = 2.4, PetalColor = Color3.fromRGB(255, 80, 0), HeartColor = Color3.fromRGB(255, 230, 0), StemColor = Color3.fromRGB(60, 170, 50), HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 120, 0) },
	{ Id = "TulipeMagma", Number = 32, Name = "Tulipe Magma", Rarity = "Epique", Petals = 6, PetalLength = 1.2, PetalWidth = 1.8, PetalColor = Color3.fromRGB(255, 60, 0), HeartColor = Color3.fromRGB(60, 10, 0), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "CrackedLava", Aura = Color3.fromRGB(255, 100, 0) },
	{ Id = "JacintheDeGlace", Number = 31, Name = "Jacinthe de Glace", Rarity = "Epique", Petals = 12, PetalLength = 0.7, PetalWidth = 1, PetalColor = Color3.fromRGB(170, 220, 255), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalMaterial = "Ice" },
	{ Id = "MargueriteDAthanor", Number = 30, Name = "Marguerite d'Athanor", Rarity = "Epique", Petals = 14, PetalLength = 1, PetalWidth = 1, PetalColor = Color3.fromRGB(255, 140, 30), HeartColor = Color3.fromRGB(255, 240, 120), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Foil", HeartMaterial = "Neon" },
	{ Id = "FleurDeCristal", Number = 29, Name = "Fleur de Cristal", Rarity = "Epique", Petals = 8, PetalLength = 1.1, PetalWidth = 1.5, PetalColor = Color3.fromRGB(230, 250, 255), HeartColor = Color3.fromRGB(200, 240, 255), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Glass", Aura = Color3.fromRGB(255, 255, 255) },
	{ Id = "LysDeLune", Number = 28, Name = "Lys de Lune", Rarity = "Epique", Petals = 6, PetalLength = 1.3, PetalWidth = 1.2, PetalColor = Color3.fromRGB(220, 230, 255), HeartColor = Color3.fromRGB(255, 255, 220), StemColor = Color3.fromRGB(60, 170, 50), HeartMaterial = "Neon", Aura = Color3.fromRGB(220, 230, 255) },
	{ Id = "RoseDObsidienne", Number = 27, Name = "Rose d'Obsidienne", Rarity = "Epique", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(20, 15, 25), HeartColor = Color3.fromRGB(120, 0, 180), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalMaterial = "Glass", HeartMaterial = "Neon" },
	{ Id = "LotusDeNeon", Number = 26, Name = "Lotus de Néon", Rarity = "Epique", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(0, 255, 200), HeartColor = Color3.fromRGB(255, 0, 200), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(255, 0, 200), PetalMaterial = "Neon", HeartMaterial = "Neon" },
	-- Legendaire
	{ Id = "FleurDeCrepuscule", Number = 25, Name = "Fleur de Crépuscule", Rarity = "Legendaire", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(255, 110, 60), HeartColor = Color3.fromRGB(255, 200, 100), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(120, 60, 200), HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 140, 80) },
	{ Id = "FleurDAurore", Number = 24, Name = "Fleur d'Aurore", Rarity = "Legendaire", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(255, 180, 200), HeartColor = Color3.fromRGB(255, 240, 180), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(120, 255, 200), HeartMaterial = "Neon", Aura = Color3.fromRGB(160, 255, 210) },
	{ Id = "OrchideeFantome", Number = 23, Name = "Orchidée Fantôme", Rarity = "Legendaire", Petals = 5, PetalLength = 1.2, PetalWidth = 2.2, PetalColor = Color3.fromRGB(230, 240, 255), HeartColor = Color3.fromRGB(180, 200, 255), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "ForceField", HeartMaterial = "Neon", Aura = Color3.fromRGB(200, 220, 255) },
	{ Id = "RoseTempete", Number = 22, Name = "Rose Tempête", Rarity = "Legendaire", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(90, 110, 180), HeartColor = Color3.fromRGB(220, 240, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(220, 240, 255), HeartMaterial = "Neon", Aura = Color3.fromRGB(200, 220, 255) },
	{ Id = "LotusDEther", Number = 21, Name = "Lotus d'Éther", Rarity = "Legendaire", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(200, 180, 255), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalMaterial = "ForceField", HeartMaterial = "Neon", Aura = Color3.fromRGB(220, 200, 255) },
	{ Id = "TournesolSolaire", Number = 20, Name = "Tournesol Solaire", Rarity = "Legendaire", Petals = 20, PetalLength = 1.2, PetalWidth = 0.9, PetalColor = Color3.fromRGB(255, 190, 0), HeartColor = Color3.fromRGB(255, 90, 0), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Neon", HeartMaterial = "Neon", HeartScale = 1.4, Aura = Color3.fromRGB(255, 200, 50) },
	{ Id = "PivoineDeSaphir", Number = 19, Name = "Pivoine de Saphir", Rarity = "Legendaire", Petals = 10, PetalLength = 1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(40, 80, 230), HeartColor = Color3.fromRGB(150, 200, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(120, 170, 255), PetalMaterial = "Glass", HeartMaterial = "Neon", Aura = Color3.fromRGB(120, 170, 255) },
	{ Id = "WisteriaStellaire", Number = 18, Name = "Wisteria Stellaire", Rarity = "Legendaire", Petals = 20, PetalLength = 0.8, PetalWidth = 0.8, PetalColor = Color3.fromRGB(160, 120, 255), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(200, 170, 255) },
	{ Id = "FleurDeVraiRubis", Number = 17, Name = "Fleur de Vrai Rubis", Rarity = "Legendaire", Petals = 8, PetalLength = 1.1, PetalWidth = 1.6, PetalColor = Color3.fromRGB(220, 0, 40), HeartColor = Color3.fromRGB(255, 80, 120), StemColor = Color3.fromRGB(60, 170, 50), PetalMaterial = "Glass", HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 60, 100) },
	{ Id = "MargueriteAbyssale", Number = 16, Name = "Marguerite Abyssale", Rarity = "Legendaire", Petals = 14, PetalLength = 1, PetalWidth = 1, PetalColor = Color3.fromRGB(10, 20, 60), HeartColor = Color3.fromRGB(0, 200, 255), StemColor = Color3.fromRGB(60, 170, 50), HeartMaterial = "Neon", Aura = Color3.fromRGB(0, 150, 255) },
	-- Mythique
	{ Id = "FleurDuNeant", Number = 15, Name = "Fleur du Néant", Rarity = "Mythique", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(5, 5, 10), HeartColor = Color3.fromRGB(180, 0, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(90, 0, 160), HeartMaterial = "Neon", Aura = Color3.fromRGB(160, 0, 255), Light = true },
	{ Id = "FleurDeGalaxie", Number = 14, Name = "Fleur de Galaxie", Rarity = "Mythique", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(40, 20, 120), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColors = { Color3.fromRGB(40, 20, 120), Color3.fromRGB(120, 40, 200), Color3.fromRGB(20, 120, 220), Color3.fromRGB(220, 90, 255) }, PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(170, 120, 255), Light = true },
	{ Id = "RoseDOrPur", Number = 13, Name = "Rose d'Or Pur", Rarity = "Mythique", Petals = 10, PetalLength = 1.1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(255, 200, 40), HeartColor = Color3.fromRGB(255, 240, 150), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(255, 225, 120), PetalMaterial = "Metal", HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 210, 80), Light = true },
	{ Id = "LotusEternel", Number = 12, Name = "Lotus Éternel", Rarity = "Mythique", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(255, 240, 250), HeartColor = Color3.fromRGB(255, 220, 120), StemColor = Color3.fromRGB(60, 170, 50), Layers = 3, PetalColor2 = Color3.fromRGB(255, 200, 240), PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 200, 240), Light = true },
	{ Id = "FleurDEclipse", Number = 11, Name = "Fleur d'Éclipse", Rarity = "Mythique", Petals = 12, PetalLength = 1.1, PetalWidth = 1.2, PetalColor = Color3.fromRGB(10, 10, 10), HeartColor = Color3.fromRGB(255, 140, 0), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(255, 170, 0), HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 140, 0), Light = true },
	{ Id = "OrchideeAstrale", Number = 10, Name = "Orchidée Astrale", Rarity = "Mythique", Petals = 6, PetalLength = 1.2, PetalWidth = 2, PetalColor = Color3.fromRGB(120, 90, 255), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(255, 255, 255), PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(170, 150, 255), Light = true },
	-- Divin
	{ Id = "FleurDePhenix", Number = 9, Name = "Fleur de Phénix", Rarity = "Divin", Petals = 12, PetalLength = 1.2, PetalWidth = 1.1, PetalColor = Color3.fromRGB(255, 60, 0), HeartColor = Color3.fromRGB(255, 240, 120), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColors = { Color3.fromRGB(255, 60, 0), Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 220, 0) }, PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 140, 0), Light = true },
	{ Id = "RoseCeleste", Number = 8, Name = "Rose Céleste", Rarity = "Divin", Petals = 10, PetalLength = 1.1, PetalWidth = 1.8, PetalColor = Color3.fromRGB(180, 220, 255), HeartColor = Color3.fromRGB(255, 215, 80), StemColor = Color3.fromRGB(60, 170, 50), Layers = 3, PetalColor2 = Color3.fromRGB(255, 255, 255), PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(200, 230, 255), Light = true },
	{ Id = "LotusCosmique", Number = 7, Name = "Lotus Cosmique", Rarity = "Divin", Petals = 12, PetalLength = 1.2, PetalWidth = 1.2, PetalColor = Color3.fromRGB(60, 0, 140), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 3, PetalColors = { Color3.fromRGB(60, 0, 140), Color3.fromRGB(0, 120, 255), Color3.fromRGB(255, 0, 170) }, PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(150, 80, 255), Light = true },
	{ Id = "FleurDuTemps", Number = 6, Name = "Fleur du Temps", Rarity = "Divin", Petals = 12, PetalLength = 1.1, PetalWidth = 1.1, PetalColor = Color3.fromRGB(240, 220, 160), HeartColor = Color3.fromRGB(120, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColor2 = Color3.fromRGB(120, 90, 40), PetalMaterial = "Metal", HeartMaterial = "Neon", Aura = Color3.fromRGB(120, 255, 255), Light = true },
	-- Secret
	{ Id = "FleurDeDiamant", Number = 5, Name = "Fleur de Diamant", Rarity = "Secret", Petals = 10, PetalLength = 1.2, PetalWidth = 1.5, PetalColor = Color3.fromRGB(230, 250, 255), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 3, PetalMaterial = "Glass", HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 255, 255), Light = true },
	{ Id = "RoseDArcEnCielAstral", Number = 4, Name = "Rose d'Arc-en-Ciel Astral", Rarity = "Secret", Petals = 14, PetalLength = 1.1, PetalWidth = 1.4, PetalColor = Color3.fromRGB(255, 70, 70), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 2, PetalColors = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 235, 60), Color3.fromRGB(80, 220, 90), Color3.fromRGB(70, 170, 255), Color3.fromRGB(90, 90, 255), Color3.fromRGB(200, 90, 255) }, PetalMaterial = "Neon", HeartMaterial = "Neon", AuraRainbow = true, Light = true },
	{ Id = "FleurDeLaCreation", Number = 3, Name = "Fleur de la Création", Rarity = "Secret", Petals = 12, PetalLength = 1.2, PetalWidth = 1.3, PetalColor = Color3.fromRGB(255, 255, 255), HeartColor = Color3.fromRGB(255, 230, 120), StemColor = Color3.fromRGB(60, 170, 50), Layers = 3, PetalColors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 215, 80) }, PetalMaterial = "Neon", HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 230, 150), Light = true },
	-- Transcendant
	{ Id = "LotusDeLaSingularite", Number = 2, Name = "Lotus de la Singularité", Rarity = "Transcendant", Petals = 14, PetalLength = 1.2, PetalWidth = 1.2, PetalColor = Color3.fromRGB(0, 0, 0), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 3, PetalColor2 = Color3.fromRGB(255, 255, 255), PetalMaterial = "ForceField", HeartMaterial = "Neon", Aura = Color3.fromRGB(255, 255, 255), Light = true, HeartScale = 1.2 },
	-- Ultime
	{ Id = "LaFleurDeLInfini", Number = 1, Name = "La Fleur de l'Infini", Rarity = "Ultime", Petals = 16, PetalLength = 1.25, PetalWidth = 1.2, PetalColor = Color3.fromRGB(255, 70, 70), HeartColor = Color3.fromRGB(255, 255, 255), StemColor = Color3.fromRGB(60, 170, 50), Layers = 3, PetalColors = { Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 235, 60), Color3.fromRGB(80, 220, 90), Color3.fromRGB(70, 170, 255), Color3.fromRGB(90, 90, 255), Color3.fromRGB(200, 90, 255) }, PetalMaterial = "Neon", HeartMaterial = "Neon", AuraRainbow = true, Light = true, HeartScale = 1.25 },
}

---------------------------------------------------------------------------
-- Animations de pétales
--   Trail : "Rainbow" ou "Color" ; Sparkles : étincelles ; Orbit : nb de
--   mini-pétales en orbite ; Impact : "Burst" | "Hearts" | "Rain" ; Size : taille
---------------------------------------------------------------------------
Cosmetics.PetalEffects = {
	{ Id = "Simple", Name = "Pétale simple", Rarity = "Commune", Impact = "Burst" },
	{ Id = "Traine", Name = "Traînée florale", Rarity = "Rare", Trail = "Color", Impact = "Burst" },
	{ Id = "Etincelles", Name = "Étincelles", Rarity = "Rare", Sparkles = true, Impact = "Burst" },
	{ Id = "Tourbillon", Name = "Tourbillon", Rarity = "Epique", Orbit = 2, Impact = "Burst" },
	{ Id = "Coeurs", Name = "Pluie de cœurs", Rarity = "Epique", Trail = "Color", Impact = "Hearts" },
	{ Id = "ArcEnCiel", Name = "Arc-en-ciel", Rarity = "Legendaire", Trail = "Rainbow", Sparkles = true, Impact = "Rain", Size = 1.25 },
}

Cosmetics.Defaults = {
	WeaponSkin = "Classique",
	FlowerSkin = "MargueriteBlanche",
	PetalEffect = "Simple",
}

---------------------------------------------------------------------------
-- Sachets de graines (tirage aléatoire d'une fleur)
--   Price : coût en graines (solde dépensable) ; Odds : % par rareté (total 100)
--   Dans une rareté, chaque fleur a la même chance.
--   Doublon : remboursé en graines (Rarities[...].Refund).
---------------------------------------------------------------------------
Cosmetics.Packs = {
	{ Id = "Sachet", Name = "Sachet de graines", Price = 150, Color = Color3.fromRGB(120, 200, 90),
		Odds = { Commune = 55, PeuCommune = 25, Rare = 12, Epique = 5, Legendaire = 2, Mythique = 0.7, Divin = 0.2, Secret = 0.08, Transcendant = 0.019, Ultime = 0.001 } },
	{ Id = "SachetDore", Name = "Sachet doré", Price = 600, Color = Color3.fromRGB(255, 200, 60),
		Odds = { Rare = 70, Epique = 20, Legendaire = 7, Mythique = 2.2, Divin = 0.6, Secret = 0.15, Transcendant = 0.049, Ultime = 0.001 } },
}

function Cosmetics.GetPack(id)
	for _, pack in Cosmetics.Packs do
		if pack.Id == id then
			return pack
		end
	end
	return nil
end

-- Tire une fleur d'un sachet. Renvoie l'objet fleur (à appeler côté serveur).
function Cosmetics.RollPack(pack, rng)
	local r = rng or Random.new()
	local total = 0
	for _, pct in pack.Odds do
		total += pct
	end
	local roll = r:NextNumber() * total
	local chosen = Cosmetics.RarityOrder[1]
	-- du plus rare au plus courant pour que les petites probabilités restent exactes
	for i = #Cosmetics.RarityOrder, 1, -1 do
		local rarity = Cosmetics.RarityOrder[i]
		local pct = pack.Odds[rarity]
		if pct then
			if roll < pct then
				chosen = rarity
				break
			end
			roll -= pct
			chosen = rarity
		end
	end
	local pool = {}
	for _, flower in Cosmetics.FlowerSkins do
		if flower.Rarity == chosen then
			table.insert(pool, flower)
		end
	end
	return pool[r:NextInteger(1, #pool)]
end

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
