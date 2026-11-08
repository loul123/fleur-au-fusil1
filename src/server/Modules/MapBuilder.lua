--[[
	La fleur au fusil — Générateur de potagers géants (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > MapBuilder

	11 cartes générées par code (voir Config.Maps) :
	  Tomates, Ail, Carottes, Citrouilles, Salades, Fraises, Maïs (labyrinthe),
	  Choux, Piments, Tournesols et « Multi » (le grand potager mélangé).
	Chaque thème définit : légumes des rangs, densité, couleurs du sol,
	monument central, décors, paquets de graines et ambiance lumineuse.
	La disposition de base (clôture, rangs, spawns des deux camps et neutres)
	est commune à toutes les cartes pour garder un jeu équilibré.

	Échelle : un personnage (≈5 studs) est minuscule à côté d'une carotte de
	15 studs de diamètre, d'une citrouille de 35 studs ou d'un maïs de 90 studs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))

local MapBuilder = {}

local rng = Random.new(Config.Map.Seed)
local mapFolder
local spawns = { Neutral = {} }
local teamsMode = false
local currentMapId = nil

local C = {
	Dirt = Color3.fromRGB(105, 72, 45),
	DarkDirt = Color3.fromRGB(80, 54, 34),
	Grass = Color3.fromRGB(90, 160, 70),
	Leaf = Color3.fromRGB(70, 150, 55),
	DarkLeaf = Color3.fromRGB(45, 110, 40),
	Orange = Color3.fromRGB(240, 120, 30),
	Tomato = Color3.fromRGB(215, 35, 30),
	Radish = Color3.fromRGB(205, 40, 90),
	Wood = Color3.fromRGB(150, 105, 65),
	Pot = Color3.fromRGB(196, 98, 52),
	Stone = Color3.fromRGB(130, 128, 122),
	Metal = Color3.fromRGB(70, 140, 110),
	Garlic = Color3.fromRGB(245, 240, 225),
	GarlicLeaf = Color3.fromRGB(95, 145, 110),
	Straw = Color3.fromRGB(225, 195, 110),
	Strawberry = Color3.fromRGB(225, 25, 45),
	Corn = Color3.fromRGB(250, 210, 60),
	CornLeaf = Color3.fromRGB(110, 160, 60),
	Cabbage = Color3.fromRGB(160, 205, 120),
	RedCabbage = Color3.fromRGB(120, 50, 120),
	Sunflower = Color3.fromRGB(255, 200, 20),
	SunflowerHeart = Color3.fromRGB(85, 50, 20),
}

---------------------------------------------------------------------------
-- Aides de construction
---------------------------------------------------------------------------
local function newPart(props)
	local p = Instance.new(props.Class or "Part")
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "Class" and k ~= "Shape" and k ~= "Parent" and k ~= "Ellipsoid" then
			p[k] = v
		end
	end
	if props.Ellipsoid then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Parent = props.Parent or mapFolder
	return p
end

local VERTICAL = CFrame.Angles(0, 0, math.rad(90)) -- l'axe des cylindres Roblox est X

local function vcyl(name, height, diameter, bottom, color, material, parent)
	return newPart({
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(bottom + Vector3.new(0, height / 2, 0)) * VERTICAL,
		Color = color,
		Material = material,
		Parent = parent,
	})
end

local function ball(name, d, center, color, parent, material)
	return newPart({ Name = name, Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d),
		CFrame = CFrame.new(center), Color = color, Material = material, Parent = parent })
end

-- Feuille / lame qui part de `origin`, orientée selon yaw et inclinée de `tilt` degrés
local function blade(name, origin, yaw, tilt, size, color, parent, ellipsoid)
	local cf = CFrame.new(origin) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(tilt), 0, 0) * CFrame.new(0, size.Y / 2, 0)
	return newPart({ Name = name, Size = size, CFrame = cf, Color = color, Material = Enum.Material.LeafyGrass,
		CanCollide = false, Parent = parent, Ellipsoid = ellipsoid })
end

local function group(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = mapFolder
	return m
end

---------------------------------------------------------------------------
-- Légumes
---------------------------------------------------------------------------
local Crops = {}

function Crops.carrot(base)
	local m = group("Carotte")
	local d = rng:NextNumber(11, 17)
	local h = rng:NextNumber(5, 9)
	vcyl("Racine", h, d, base, C.Orange, nil, m)
	local top = base + Vector3.new(0, h, 0)
	for i = 1, 6 do
		blade("Fane", top, i * 60 + rng:NextNumber(-15, 15), rng:NextNumber(12, 30), Vector3.new(1.2, rng:NextNumber(30, 50), 4), C.Leaf, m)
	end
end

function Crops.lettuce(base)
	local m = group("Laitue")
	for _ = 1, 7 do
		local d = rng:NextNumber(12, 22)
		local offset = Vector3.new(rng:NextNumber(-8, 8), d * 0.25, rng:NextNumber(-8, 8))
		ball("Feuille", d, base + offset, C.Leaf:Lerp(Color3.fromRGB(170, 220, 90), rng:NextNumber()), m, Enum.Material.LeafyGrass)
	end
end

function Crops.tomato(base)
	local m = group("Tomate")
	local h = rng:NextNumber(45, 65)
	newPart({ Name = "Tuteur", Size = Vector3.new(2.5, h + 10, 2.5), CFrame = CFrame.new(base + Vector3.new(4, (h + 10) / 2, 0)),
		Color = C.Wood, Material = Enum.Material.Wood, Parent = m })
	vcyl("Tige", h, 3, base, C.DarkLeaf, nil, m)
	for i = 1, 4 do
		local y = h * (0.25 + 0.17 * i)
		local branch = CFrame.new(base + Vector3.new(0, y, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		newPart({ Name = "Branche", Size = Vector3.new(1.4, 1.4, 12), CFrame = branch * CFrame.new(0, 0, -6),
			Color = C.DarkLeaf, CanCollide = false, Parent = m })
		local tip = branch * CFrame.new(0, 0, -12)
		newPart({ Name = "Feuille", Size = Vector3.new(9, 0.8, 9), CFrame = tip * CFrame.new(0, 1, 0) * CFrame.Angles(0, math.rad(45), 0),
			Color = C.Leaf, Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = m })
		local d = rng:NextNumber(8, 13)
		local color = if rng:NextNumber() < 0.2 then Color3.fromRGB(120, 190, 60) else C.Tomato -- quelques tomates vertes
		newPart({ Name = "Tomate", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d),
			CFrame = tip * CFrame.new(0, -d / 2 - 0.5, 0), Color = color, Parent = m })
	end
end

function Crops.radish(base)
	local m = group("Radis")
	local d = rng:NextNumber(8, 11)
	ball("Radis", d, base + Vector3.new(0, d * 0.25, 0), C.Radish, m)
	for i = 1, 3 do
		blade("Fane", base + Vector3.new(0, d * 0.7, 0), i * 120, 25, Vector3.new(5, rng:NextNumber(16, 24), 0.8), C.Leaf, m, true)
	end
end

function Crops.pumpkin(base)
	local m = group("Citrouille")
	local d = rng:NextNumber(30, 38)
	for i = 0, 4 do
		local offset = if i == 0 then Vector3.zero else Vector3.new(math.cos(i * math.pi / 2), 0, math.sin(i * math.pi / 2)) * 3
		ball("Cote", d, base + offset + Vector3.new(0, d * 0.38, 0), C.Orange:Lerp(Color3.fromRGB(255, 150, 40), i * 0.1), m)
	end
	vcyl("Pedoncule", 7, 3.5, base + Vector3.new(0, d * 0.85, 0), Color3.fromRGB(100, 120, 50), Enum.Material.Wood, m)
	for i = 1, 3 do
		newPart({ Name = "Feuille", Size = Vector3.new(16, 1, 16), Ellipsoid = true, CanCollide = false, Parent = m,
			CFrame = CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.rad(i * 120), 0) * CFrame.new(0, 0, -d / 2 - 4),
			Color = C.Leaf, Material = Enum.Material.LeafyGrass })
	end
end

function Crops.garlic(base)
	local m = group("Ail")
	local d = rng:NextNumber(12, 16)
	local tint = C.Garlic:Lerp(Color3.fromRGB(200, 160, 200), rng:NextNumber(0, 0.4))
	ball("Tete", d, base + Vector3.new(0, d * 0.3, 0), tint, m)
	for i = 1, 5 do
		local a = i * (math.pi * 2 / 5)
		ball("Gousse", d * 0.55, base + Vector3.new(math.cos(a) * d * 0.35, d * 0.25, math.sin(a) * d * 0.35), tint, m)
	end
	vcyl("Col", 8, d * 0.25, base + Vector3.new(0, d * 0.7, 0), C.Garlic, nil, m)
	for i = 1, 4 do
		blade("Feuille", base + Vector3.new(0, d * 0.7 + 6, 0), i * 90 + rng:NextNumber(-20, 20), rng:NextNumber(5, 18),
			Vector3.new(2.5, rng:NextNumber(40, 58), 0.6), C.GarlicLeaf, m)
	end
end

function Crops.strawberry(base)
	local m = group("Fraisier")
	for i = 1, 6 do
		newPart({ Name = "Feuille", Size = Vector3.new(11, 1, 13), Ellipsoid = true, CanCollide = false, Parent = m,
			CFrame = CFrame.new(base + Vector3.new(0, 6, 0)) * CFrame.Angles(0, math.rad(i * 60), 0) * CFrame.new(0, 0, -6) * CFrame.Angles(math.rad(-15), 0, 0),
			Color = C.Leaf, Material = Enum.Material.LeafyGrass })
	end
	for _ = 1, rng:NextInteger(2, 3) do
		local a = rng:NextNumber(0, math.pi * 2)
		local pos = base + Vector3.new(math.cos(a) * 11, 4.5, math.sin(a) * 11)
		local ripe = rng:NextNumber() < 0.8
		newPart({ Name = "Fraise", Size = Vector3.new(9, 11, 9), Ellipsoid = true, Parent = m,
			CFrame = CFrame.new(pos) * CFrame.Angles(0, a, math.rad(rng:NextNumber(-25, 25))),
			Color = if ripe then C.Strawberry else Color3.fromRGB(240, 240, 200) })
		vcyl("Collerette", 1.2, 6, pos + Vector3.new(0, 5, 0), C.Leaf, nil, m)
	end
end

function Crops.corn(base)
	local m = group("Mais")
	local h = rng:NextNumber(70, 95)
	vcyl("Tige", h, 3.5, base, C.CornLeaf, nil, m)
	for i = 1, 6 do
		blade("Feuille", base + Vector3.new(0, h * (0.15 + i * 0.1), 0), i * 137, rng:NextNumber(45, 65),
			Vector3.new(3, rng:NextNumber(18, 28), 0.5), C.CornLeaf, m)
	end
	local cobY = h * rng:NextNumber(0.45, 0.6)
	local cob = CFrame.new(base + Vector3.new(0, cobY, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0) * CFrame.new(0, 0, -3) * CFrame.Angles(math.rad(-20), 0, 0)
	newPart({ Name = "Epi", Size = Vector3.new(4.5, 15, 4.5), Ellipsoid = true, CFrame = cob, Color = C.Corn, Parent = m })
	newPart({ Name = "Spathe", Size = Vector3.new(5, 10, 5), Ellipsoid = true, CFrame = cob * CFrame.new(0, -3, 0), Color = C.Leaf, CanCollide = false, Parent = m })
	for i = 1, 4 do
		blade("Panicule", base + Vector3.new(0, h, 0), i * 90, 30, Vector3.new(0.6, 8, 0.6), Color3.fromRGB(210, 190, 120), m)
	end
end

function Crops.cabbage(base)
	local m = group("Chou")
	local red = rng:NextNumber() < 0.35
	local color = if red then C.RedCabbage else C.Cabbage
	local d = rng:NextNumber(20, 28)
	ball("Coeur", d, base + Vector3.new(0, d * 0.4, 0), color, m, Enum.Material.LeafyGrass)
	for i = 1, 6 do
		newPart({ Name = "Feuille", Size = Vector3.new(d * 0.8, 2, d), Ellipsoid = true, CanCollide = false, Parent = m,
			CFrame = CFrame.new(base + Vector3.new(0, d * 0.3, 0)) * CFrame.Angles(0, math.rad(i * 60), 0) * CFrame.new(0, 0, -d * 0.45) * CFrame.Angles(math.rad(40), 0, 0),
			Color = color:Lerp(Color3.fromRGB(60, 120, 50), 0.35), Material = Enum.Material.LeafyGrass })
	end
end

local PEPPER_COLORS = { Color3.fromRGB(220, 30, 30), Color3.fromRGB(250, 200, 20), Color3.fromRGB(60, 150, 40), Color3.fromRGB(245, 120, 20) }

function Crops.pepper(base)
	local m = group("Piment")
	local h = rng:NextNumber(22, 32)
	vcyl("Tige", h, 2.5, base, C.DarkLeaf, nil, m)
	for i = 1, 5 do
		blade("Feuille", base + Vector3.new(0, h * (0.4 + i * 0.1), 0), i * 72, 60, Vector3.new(5, 10, 0.6), C.Leaf, m, true)
	end
	for i = 1, rng:NextInteger(2, 4) do
		local a = i * 2.1 + rng:NextNumber()
		local pos = base + Vector3.new(math.cos(a) * 5, h * rng:NextNumber(0.4, 0.8), math.sin(a) * 5)
		local chili = rng:NextNumber() < 0.4
		local size = if chili then Vector3.new(2.5, 11, 2.5) else Vector3.new(7, 9, 7)
		local color = if chili then Color3.fromRGB(200, 15, 15) else PEPPER_COLORS[rng:NextInteger(1, #PEPPER_COLORS)]
		newPart({ Name = if chili then "Piment" else "Poivron", Size = size, Ellipsoid = true, Parent = m,
			CFrame = CFrame.new(pos - Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-15, 15))), Color = color })
	end
end

function Crops.sunflower(base)
	local m = group("Tournesol")
	local h = rng:NextNumber(70, 95)
	vcyl("Tige", h, 3, base, C.DarkLeaf, nil, m)
	for i = 1, 3 do
		blade("Feuille", base + Vector3.new(0, h * (0.2 + i * 0.18), 0), i * 120, 70, Vector3.new(10, 14, 0.6), C.Leaf, m, true)
	end
	-- capitule tourné vers l'ouest (soleil couchant), légèrement penché
	local head = CFrame.new(base + Vector3.new(0, h + 2, 0)) * CFrame.Angles(0, math.rad(90 + rng:NextNumber(-25, 25)), 0) * CFrame.Angles(math.rad(-20), 0, 0)
	newPart({ Name = "Coeur", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 20, 20),
		CFrame = head * CFrame.Angles(0, math.rad(90), 0), Color = C.SunflowerHeart, Material = Enum.Material.Sand, Parent = m })
	for i = 0, 13 do
		newPart({ Name = "Petale", Size = Vector3.new(4, 10, 0.6), Ellipsoid = true, CanCollide = false, Parent = m,
			CFrame = head * CFrame.Angles(0, 0, math.rad(i * (360 / 14))) * CFrame.new(0, 13, 0), Color = C.Sunflower })
	end
end

---------------------------------------------------------------------------
-- Décors des sillons
---------------------------------------------------------------------------
local function stone(base)
	local d = rng:NextNumber(5, 12)
	ball("Caillou", d, base + Vector3.new(0, d * 0.25, 0), C.Stone, nil, Enum.Material.Slate)
end

local SEED_COLORS = { Color3.fromRGB(230, 70, 90), Color3.fromRGB(250, 160, 40), Color3.fromRGB(80, 170, 230), Color3.fromRGB(250, 220, 60), Color3.fromRGB(140, 200, 90) }

local function seedPacket(base, text)
	local packet = newPart({ Name = "PaquetDeGraines", Size = Vector3.new(26, 34, 1.5),
		CFrame = CFrame.new(base + Vector3.new(0, 16.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), math.rad(rng:NextNumber(-6, 6))),
		Color = SEED_COLORS[rng:NextInteger(1, #SEED_COLORS)] })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.PixelsPerStud = 10
		gui.Parent = packet
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 0.4)
		label.Position = UDim2.fromScale(0, 0.05)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
	end
end

local function strawBale(base)
	newPart({ Name = "BotteDePaille", Size = Vector3.new(22, 14, 14), CFrame = CFrame.new(base + Vector3.new(0, 7, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
		Color = C.Straw, Material = Enum.Material.Fabric })
end

---------------------------------------------------------------------------
-- Décors / monuments
---------------------------------------------------------------------------
local Props = {}

function Props.flowerPot(base)
	local m = group("PotDeFleur")
	vcyl("Pot", 24, 28, base, C.Pot, nil, m)
	vcyl("Rebord", 4, 32, base + Vector3.new(0, 22, 0), C.Pot, nil, m)
	vcyl("Terreau", 1, 27, base + Vector3.new(0, 24.6, 0), C.DarkDirt, Enum.Material.Ground, m)
	vcyl("Tige", 55, 2.5, base + Vector3.new(0, 25, 0), C.DarkLeaf, nil, m)
	local top = base + Vector3.new(0, 80, 0)
	local color = Color3.fromHSV(rng:NextNumber(), 0.6, 1)
	ball("Coeur", 8, top, Color3.fromRGB(255, 210, 40), m)
	for i = 0, 7 do
		newPart({ Name = "Petale", Size = Vector3.new(7, 1.5, 15), Ellipsoid = true, CanCollide = false, Parent = m,
			CFrame = CFrame.new(top) * CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0, -9) * CFrame.Angles(math.rad(-15), 0, 0), Color = color })
	end
end

Props.pumpkin = Crops.pumpkin
Props.strawBale = strawBale

function Props.wateringCan(base)
	local m = group("ArrosoirGeant")
	vcyl("Corps", 44, 50, base, C.Metal, Enum.Material.Metal, m)
	vcyl("Bord", 2, 52, base + Vector3.new(0, 44, 0), C.Metal, Enum.Material.Metal, m)
	for _, z in { -14, 14 } do
		newPart({ Name = "Anse", Size = Vector3.new(5, 20, 5), CFrame = CFrame.new(base + Vector3.new(0, 54, z)),
			Color = C.Metal, Material = Enum.Material.Metal, Parent = m })
	end
	newPart({ Name = "Anse", Size = Vector3.new(5, 5, 33), CFrame = CFrame.new(base + Vector3.new(0, 64, 0)),
		Color = C.Metal, Material = Enum.Material.Metal, Parent = m })
	local spout = CFrame.new(base + Vector3.new(24, 10, 0)) * CFrame.Angles(0, 0, math.rad(40))
	newPart({ Name = "Bec", Shape = Enum.PartType.Cylinder, Size = Vector3.new(50, 6, 6), CFrame = spout * CFrame.new(25, 0, 0),
		Color = C.Metal, Material = Enum.Material.Metal, Parent = m })
	newPart({ Name = "Pomme", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 14, 14), CFrame = spout * CFrame.new(51, 0, 0),
		Color = C.Metal, Material = Enum.Material.Metal, Parent = m })
end

function Props.wheelbarrow(base)
	local m = group("BrouetteGeante")
	local red = Color3.fromRGB(190, 40, 35)
	local function box(name, size, offset, color, material)
		newPart({ Name = name, Size = size, CFrame = CFrame.new(base + offset), Color = color or red, Material = material or Enum.Material.Metal, Parent = m })
	end
	box("Fond", Vector3.new(44, 2, 30), Vector3.new(0, 16, 0))
	box("Paroi", Vector3.new(44, 16, 2), Vector3.new(0, 24, 15))
	box("Paroi", Vector3.new(44, 16, 2), Vector3.new(0, 24, -15))
	box("Paroi", Vector3.new(2, 16, 30), Vector3.new(22, 24, 0))
	box("Paroi", Vector3.new(2, 16, 30), Vector3.new(-22, 24, 0))
	box("Terre", Vector3.new(40, 10, 26), Vector3.new(0, 22, 0), C.DarkDirt, Enum.Material.Ground)
	newPart({ Name = "Roue", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 20, 20), Parent = m,
		CFrame = CFrame.new(base + Vector3.new(30, 10, 0)) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(40, 40, 40) })
	for _, z in { -10, 10 } do
		box("Bras", Vector3.new(70, 2.5, 2.5), Vector3.new(-10, 17, z), C.Wood, Enum.Material.Wood)
		box("Pied", Vector3.new(2.5, 14, 2.5), Vector3.new(-18, 7, z), red)
	end
end

function Props.scarecrow(base)
	local m = group("Epouvantail")
	newPart({ Name = "Poteau", Size = Vector3.new(3, 72, 3), CFrame = CFrame.new(base + Vector3.new(0, 36, 0)), Color = C.Wood, Material = Enum.Material.Wood, Parent = m })
	newPart({ Name = "Bras", Size = Vector3.new(44, 3, 3), CFrame = CFrame.new(base + Vector3.new(0, 56, 0)), Color = C.Wood, Material = Enum.Material.Wood, Parent = m })
	newPart({ Name = "Chemise", Size = Vector3.new(16, 20, 7), CFrame = CFrame.new(base + Vector3.new(0, 50, 0)), Color = Color3.fromRGB(170, 50, 40), Material = Enum.Material.Fabric, Parent = m })
	for _, x in { -14, 14 } do
		newPart({ Name = "Manche", Size = Vector3.new(12, 6, 6), CFrame = CFrame.new(base + Vector3.new(x, 56, 0)), Color = Color3.fromRGB(150, 40, 35), Material = Enum.Material.Fabric, Parent = m })
		blade("Paille", base + Vector3.new(x * 1.45, 56, 0), if x > 0 then 90 else -90, 100, Vector3.new(1, 6, 1), C.Straw, m)
	end
	ball("Tete", 13, base + Vector3.new(0, 67, 0), Color3.fromRGB(200, 170, 120), m, Enum.Material.Fabric)
	vcyl("Bord", 1, 24, base + Vector3.new(0, 72, 0), Color3.fromRGB(110, 80, 40), Enum.Material.Fabric, m)
	vcyl("Chapeau", 9, 12, base + Vector3.new(0, 72, 0), Color3.fromRGB(110, 80, 40), Enum.Material.Fabric, m)
end

function Props.gnome(base)
	-- nain de jardin générique
	local m = group("NainDeJardin")
	vcyl("Bottes", 6, 22, base, Color3.fromRGB(60, 40, 30), nil, m)
	vcyl("Corps", 24, 20, base + Vector3.new(0, 6, 0), Color3.fromRGB(40, 90, 170), nil, m)
	vcyl("Ceinture", 3, 21, base + Vector3.new(0, 14, 0), Color3.fromRGB(40, 30, 20), nil, m)
	ball("Barbe", 16, base + Vector3.new(0, 30, -4), Color3.fromRGB(245, 245, 245), m)
	ball("Visage", 13, base + Vector3.new(0, 36, -1), Color3.fromRGB(250, 205, 170), m)
	ball("Nez", 4, base + Vector3.new(0, 36, -7.5), Color3.fromRGB(240, 150, 130), m)
	local hatColor = Color3.fromRGB(210, 30, 40)
	local y = 40
	for i = 0, 5 do
		local d = 15 - i * 2.4
		vcyl("Bonnet", 4, d, base + Vector3.new(0, y, 0), hatColor, nil, m)
		y += 4
	end
end

---------------------------------------------------------------------------
-- Thèmes (les Id correspondent à Config.Maps)
---------------------------------------------------------------------------
local ALL_CROPS = { Crops.carrot, Crops.lettuce, Crops.tomato, Crops.radish, Crops.garlic, Crops.strawberry, Crops.corn, Crops.cabbage, Crops.pepper, Crops.sunflower }

local THEMES = {
	Tomates = {
		Crops = { Crops.tomato }, Spacing = { 30, 45 }, Landmark = Props.wateringCan,
		Props = { Props.flowerPot, Props.wheelbarrow }, Seeds = "GRAINES DE TOMATES",
		Light = { ClockTime = 13, Brightness = 2.6, Atmosphere = Color3.fromRGB(220, 235, 255), Density = 0.25 },
	},
	Ail = {
		Crops = { Crops.garlic }, Spacing = { 18, 28 }, Landmark = Props.wheelbarrow,
		Props = { Props.flowerPot, Props.strawBale }, Seeds = "AIL ROSE", Soil = Color3.fromRGB(125, 95, 65),
		Light = { ClockTime = 8.5, Brightness = 2.2, Atmosphere = Color3.fromRGB(255, 235, 210), Density = 0.3 },
	},
	Carottes = {
		Crops = { Crops.carrot }, Spacing = { 20, 32 }, Landmark = Props.gnome,
		Props = { Props.flowerPot, Props.pumpkin }, Seeds = "GRAINES DE CAROTTES",
		Light = { ClockTime = 12, Brightness = 2.6, Atmosphere = Color3.fromRGB(220, 235, 255), Density = 0.25 },
	},
	Citrouilles = {
		Crops = { Crops.pumpkin }, Spacing = { 45, 62 }, Landmark = Props.scarecrow,
		Props = { Props.strawBale, Props.pumpkin }, Seeds = "GRAINES DE COURGES",
		Light = { ClockTime = 18.2, Brightness = 1.6, Atmosphere = Color3.fromRGB(255, 160, 90), Density = 0.4 },
	},
	Salades = {
		Crops = { Crops.lettuce, Crops.lettuce, Crops.radish }, Spacing = { 26, 40 }, Landmark = Props.wateringCan,
		Props = { Props.flowerPot, Props.gnome }, Seeds = "LAITUE BATAVIA",
		Light = { ClockTime = 11, Brightness = 1.3, Atmosphere = Color3.fromRGB(190, 200, 210), Density = 0.45 },
	},
	Fraises = {
		Crops = { Crops.strawberry }, Spacing = { 20, 28 }, Landmark = Props.wheelbarrow, RowColor = C.Straw, RowMaterial = Enum.Material.Fabric,
		Props = { Props.strawBale, Props.flowerPot }, Seeds = "FRAISES GARIGUETTE",
		Light = { ClockTime = 15, Brightness = 2.5, Atmosphere = Color3.fromRGB(255, 225, 230), Density = 0.25 },
	},
	Mais = {
		Crops = { Crops.corn }, Spacing = { 11, 15 }, GapChance = 0.12, GapSize = 26, Landmark = Props.scarecrow,
		Props = { Props.strawBale, Props.pumpkin }, Seeds = "MAÏS DOUX", RowWidth = 14,
		Light = { ClockTime = 16.5, Brightness = 2.2, Atmosphere = Color3.fromRGB(255, 220, 160), Density = 0.3 },
	},
	Choux = {
		Crops = { Crops.cabbage }, Spacing = { 30, 42 }, Landmark = Props.gnome,
		Props = { Props.flowerPot, Props.wheelbarrow }, Seeds = "CHOU DE MILAN",
		Light = { ClockTime = 7.5, Brightness = 1.6, Atmosphere = Color3.fromRGB(215, 225, 235), Density = 0.55 },
	},
	Piments = {
		Crops = { Crops.pepper }, Spacing = { 22, 32 }, Landmark = Props.wateringCan, Soil = Color3.fromRGB(140, 85, 50),
		Props = { Props.flowerPot, Props.strawBale }, Seeds = "PIMENT D'ESPELETTE",
		Light = { ClockTime = 14, Brightness = 3, Atmosphere = Color3.fromRGB(255, 200, 150), Density = 0.3 },
	},
	Tournesols = {
		Crops = { Crops.sunflower }, Spacing = { 20, 30 }, Landmark = Props.gnome,
		Props = { Props.strawBale, Props.wheelbarrow }, Seeds = "GRAINES DE TOURNESOL",
		Light = { ClockTime = 17.3, Brightness = 2, Atmosphere = Color3.fromRGB(255, 205, 140), Density = 0.3 },
	},
	Multi = {
		CropsPerRow = ALL_CROPS, Spacing = { 35, 60 }, Landmark = Props.wateringCan,
		Props = { Props.flowerPot, Props.pumpkin, Props.wheelbarrow, Props.scarecrow, Props.gnome, Props.strawBale }, Seeds = "LE GRAND POTAGER",
		Light = { ClockTime = 13.5, Brightness = 2.5, Atmosphere = Color3.fromRGB(220, 235, 255), Density = 0.25 },
	},
}

---------------------------------------------------------------------------
-- Structure commune : sol, clôture, spawns, rangs
---------------------------------------------------------------------------
local function buildGround(half, theme)
	newPart({ Name = "Sol", Size = Vector3.new(half * 2 + 300, 10, half * 2 + 300), CFrame = CFrame.new(0, -5, 0),
		Color = theme.Soil or C.Dirt, Material = Enum.Material.Ground })
	newPart({ Name = "Pelouse", Size = Vector3.new(half * 2 + 1200, 9, half * 2 + 1200), CFrame = CFrame.new(0, -5.5, 0),
		Color = C.Grass, Material = Enum.Material.Grass })
end

local function buildFence(half)
	local h = Config.Map.WallHeight
	local fence = group("Cloture")
	local step = 12
	for s = -half, half - step, step do
		local ph = h + rng:NextNumber(-6, 6)
		local c = s + step / 2
		for _, info in {
			{ Vector3.new(c, ph / 2, half + 1.5), Vector3.new(step - 0.6, ph, 3) },
			{ Vector3.new(c, ph / 2, -half - 1.5), Vector3.new(step - 0.6, ph, 3) },
			{ Vector3.new(half + 1.5, ph / 2, c), Vector3.new(3, ph, step - 0.6) },
			{ Vector3.new(-half - 1.5, ph / 2, c), Vector3.new(3, ph, step - 0.6) },
		} do
			newPart({ Name = "Planche", Size = info[2], CFrame = CFrame.new(info[1]),
				Color = C.Wood:Lerp(Color3.fromRGB(110, 75, 45), rng:NextNumber()), Material = Enum.Material.WoodPlanks, Parent = fence })
		end
	end
	-- murs invisibles : impossible de sortir du potager
	for _, info in {
		{ Vector3.new(0, 150, half + 4), Vector3.new(half * 2 + 20, 300, 2) },
		{ Vector3.new(0, 150, -half - 4), Vector3.new(half * 2 + 20, 300, 2) },
		{ Vector3.new(half + 4, 150, 0), Vector3.new(2, 300, half * 2 + 20) },
		{ Vector3.new(-half - 4, 150, 0), Vector3.new(2, 300, half * 2 + 20) },
	} do
		newPart({ Name = "MurInvisible", Size = info[2], CFrame = CFrame.new(info[1]), Transparency = 1, CanQuery = false, Parent = fence })
	end
end

local function makeSpawn(position, teamName)
	local s = Instance.new("SpawnLocation")
	s.Name = "Spawn_" .. (teamName or "Neutre")
	s.Anchored = true
	s.Size = Vector3.new(12, 1, 12)
	s.CFrame = CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
	s.Material = Enum.Material.Grass
	s.Duration = Config.Combat.SpawnProtection
	s.AllowTeamChangeOnTouch = false
	s.TopSurface = Enum.SurfaceType.Smooth
	if teamName then
		for _, t in Config.Teams do
			if t.Name == teamName then
				s.TeamColor = t.BrickColor
				s.BrickColor = t.BrickColor
			end
		end
		spawns[teamName] = spawns[teamName] or {}
		table.insert(spawns[teamName], s)
	else
		s.Color = Color3.fromRGB(240, 240, 200)
		table.insert(spawns.Neutral, s)
	end
	s.Parent = mapFolder
end

local function buildSpawns(half)
	local a, b = Config.Teams[1].Name, Config.Teams[2].Name
	for _, z in { -150, -50, 50, 150 } do
		makeSpawn(Vector3.new(-half + 35, 0.5, z), a)
		makeSpawn(Vector3.new(half - 35, 0.5, z), b)
	end
	for _, pos in {
		Vector3.new(-150, 0.5, half - 25), Vector3.new(0, 0.5, half - 25), Vector3.new(150, 0.5, half - 25),
		Vector3.new(-150, 0.5, -half + 25), Vector3.new(0, 0.5, -half + 25), Vector3.new(150, 0.5, -half + 25),
	} do
		makeSpawn(pos, nil)
	end
end

local function buildGarden(half, theme)
	local rowIndex = 0
	local rowLength = half * 2 - 180
	local spacing = theme.Spacing
	for z = -half + 50, half - 50, 75 do
		rowIndex += 1
		newPart({ Name = "Rang", Size = Vector3.new(rowLength, 3, theme.RowWidth or 24), CFrame = CFrame.new(0, 1.5, z),
			Color = theme.RowColor or C.DarkDirt, Material = theme.RowMaterial or Enum.Material.Ground })

		local rowCrops = theme.Crops
		if theme.CropsPerRow then
			rowCrops = { theme.CropsPerRow[(rowIndex - 1) % #theme.CropsPerRow + 1] }
		end

		local x = -rowLength / 2 + 15
		while x < rowLength / 2 - 15 do
			local pos = Vector3.new(x, 3, z + rng:NextNumber(-3, 3))
			if pos.Magnitude > 60 then -- centre libre pour le monument
				rowCrops[rng:NextInteger(1, #rowCrops)](pos)
			end
			x += rng:NextNumber(spacing[1], spacing[2])
			if theme.GapChance and rng:NextNumber() < theme.GapChance then
				x += theme.GapSize or 20 -- passage (labyrinthe de maïs)
			end
		end

		-- sillon suivant : cailloux et paquets de graines
		local furrowZ = z + 37.5
		if furrowZ < half - 20 then
			for _ = 1, 3 do
				stone(Vector3.new(rng:NextNumber(-half + 100, half - 100), 0, furrowZ + rng:NextNumber(-10, 10)))
			end
			if rng:NextNumber() < 0.7 then
				seedPacket(Vector3.new(rng:NextNumber(-half + 120, half - 120), 0, furrowZ), theme.Seeds)
			end
		end
	end

	theme.Landmark(Vector3.new(0, 0, 0))
	local propPositions = {
		Vector3.new(130, 0, 187.5), Vector3.new(-130, 0, -187.5), Vector3.new(-130, 0, 187.5), Vector3.new(130, 0, -187.5),
		Vector3.new(-half + 75, 0, 100), Vector3.new(-half + 75, 0, -100), Vector3.new(half - 75, 0, 100), Vector3.new(half - 75, 0, -100),
		Vector3.new(0, 0, half - 85), Vector3.new(0, 0, -half + 85), Vector3.new(220, 0, 37.5), Vector3.new(-220, 0, -37.5),
	}
	for i, pos in propPositions do
		theme.Props[(i - 1) % #theme.Props + 1](pos)
	end
end

local function setupLighting(light)
	Lighting.ClockTime = light.ClockTime
	Lighting.Brightness = light.Brightness
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 140)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Color = light.Atmosphere
	atmosphere.Density = light.Density
end

---------------------------------------------------------------------------
-- API
---------------------------------------------------------------------------
local function collectCustomSpawns(container)
	for _, s in container:GetDescendants() do
		if s:IsA("SpawnLocation") then
			local teamName = s.Name:match("^Spawn_(.+)$")
			if teamName and teamName ~= "Neutre" then
				spawns[teamName] = spawns[teamName] or {}
				table.insert(spawns[teamName], s)
			else
				table.insert(spawns.Neutral, s)
			end
		end
	end
end

function MapBuilder.IsGenerated()
	return Config.Map.Generate
end

function MapBuilder.GetCurrentMapId()
	return currentMapId
end

-- Construit (ou reconstruit) la carte `mapId`. Renvoie l'Id réellement chargé.
function MapBuilder.Build(mapId)
	spawns = { Neutral = {} }
	local existing = workspace:FindFirstChild("PotagerGeant")

	if not Config.Map.Generate and existing then
		-- Carte faite à la main : on réutilise ses SpawnLocation (Spawn_<Equipe> ou Spawn_Neutre)
		mapFolder = existing
		collectCustomSpawns(existing)
		currentMapId = "Custom"
		return currentMapId
	end

	if not THEMES[mapId] then
		mapId = "Multi"
	end
	local theme = THEMES[mapId]
	local hash = 0
	for i = 1, #mapId do
		hash = (hash * 31 + string.byte(mapId, i)) % 1000003
	end
	rng = Random.new(Config.Map.Seed + hash)

	if existing then
		existing:Destroy()
	end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "PotagerGeant"
	mapFolder:SetAttribute("MapId", mapId)

	local half = Config.Map.Size / 2
	buildGround(half, theme)
	buildFence(half)
	buildSpawns(half)
	buildGarden(half, theme)
	setupLighting(theme.Light)
	mapFolder.Parent = workspace -- parenté à la fin : une seule réplication

	-- supprime le Baseplate / SpawnLocation par défaut du template Studio
	for _, name in { "Baseplate", "SpawnLocation" } do
		local obj = workspace:FindFirstChild(name)
		if obj and obj.Parent == workspace then
			obj:Destroy()
		end
	end

	currentMapId = mapId
	MapBuilder.ConfigureSpawns(teamsMode)
	return mapId
end

-- Mode équipe : spawns des camps réservés à leur équipe, spawns neutres coupés.
-- Chacun pour soi : tous les spawns deviennent neutres.
function MapBuilder.ConfigureSpawns(useTeams)
	teamsMode = useTeams
	for key, list in spawns do
		for _, s in list do
			if key == "Neutral" then
				s.Neutral = true
				s.Enabled = not useTeams
			else
				s.Neutral = not useTeams
				s.Enabled = true
			end
		end
	end
end

function MapBuilder.GetSpawnCFrame(teamName)
	local list = {}
	if teamsMode and teamName and spawns[teamName] then
		list = spawns[teamName]
	else
		for _, l in spawns do
			for _, s in l do
				table.insert(list, s)
			end
		end
	end
	if #list == 0 then
		return CFrame.new(0, 10, 0)
	end
	local s = list[rng:NextInteger(1, #list)]
	return s.CFrame * CFrame.new(rng:NextNumber(-4, 4), 4, rng:NextNumber(-4, 4))
end

function MapBuilder.GetRandomPoint()
	local half = Config.Map.Size / 2 - 30
	return Vector3.new(rng:NextNumber(-half, half), 3, rng:NextNumber(-half, half))
end

return MapBuilder
