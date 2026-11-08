--[[
	La fleur au fusil — Générateur du potager géant (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > MapBuilder

	Génère : sol de terre, rangs de culture, carottes, laitues, plants de
	tomates, radis, citrouilles, pots de fleurs, paquets de graines, cailloux,
	un arrosoir géant au centre, une clôture en planches et les points
	d'apparition (deux camps + spawns neutres pour le chacun pour soi).
	Échelle : un personnage (≈5 studs) est minuscule à côté d'une carotte de 15 studs
	de diamètre ou d'une citrouille de 35 studs.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))

local MapBuilder = {}

local rng
local mapFolder
local spawns = { Neutral = {} }
local teamsMode = false

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
}

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
		if k ~= "Class" and k ~= "Shape" and k ~= "Parent" then
			p[k] = v
		end
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

local function group(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = mapFolder
	return m
end

---------------------------------------------------------------------------
-- Légumes & décor
---------------------------------------------------------------------------
local function carrot(base)
	local m = group("Carotte")
	local d = rng:NextNumber(11, 17)
	local h = rng:NextNumber(5, 9)
	vcyl("Racine", h, d, base, C.Orange, nil, m)
	local top = base + Vector3.new(0, h, 0)
	for i = 1, 6 do
		local len = rng:NextNumber(30, 50)
		local cf = CFrame.new(top)
			* CFrame.Angles(0, math.rad(i * 60 + rng:NextNumber(-15, 15)), 0)
			* CFrame.Angles(math.rad(rng:NextNumber(12, 30)), 0, 0)
			* CFrame.new(0, len / 2, 0)
		newPart({ Name = "Fane", Size = Vector3.new(1.2, len, 4), CFrame = cf, Color = C.Leaf,
			Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = m })
	end
end

local function lettuce(base)
	local m = group("Laitue")
	for _ = 1, 7 do
		local d = rng:NextNumber(12, 22)
		local offset = Vector3.new(rng:NextNumber(-8, 8), d * 0.25, rng:NextNumber(-8, 8))
		local shade = C.Leaf:Lerp(Color3.fromRGB(170, 220, 90), rng:NextNumber())
		newPart({ Name = "Feuille", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d),
			CFrame = CFrame.new(base + offset), Color = shade, Material = Enum.Material.LeafyGrass, Parent = m })
	end
end

local function tomatoPlant(base)
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
		newPart({ Name = "Tomate", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d),
			CFrame = tip * CFrame.new(0, -d / 2 - 0.5, 0), Color = C.Tomato, Parent = m })
	end
end

local function radish(base)
	local m = group("Radis")
	local d = rng:NextNumber(8, 11)
	newPart({ Name = "Radis", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d),
		CFrame = CFrame.new(base + Vector3.new(0, d * 0.25, 0)), Color = C.Radish, Parent = m })
	for i = 1, 3 do
		local len = rng:NextNumber(16, 24)
		local cf = CFrame.new(base + Vector3.new(0, d * 0.7, 0)) * CFrame.Angles(0, math.rad(i * 120), 0)
			* CFrame.Angles(math.rad(25), 0, 0) * CFrame.new(0, len / 2, 0)
		newPart({ Name = "Fane", Size = Vector3.new(5, len, 0.8), CFrame = cf, Color = C.Leaf,
			Material = Enum.Material.LeafyGrass, CanCollide = false, Parent = m })
	end
end

local function pumpkin(base)
	local m = group("Citrouille")
	local d = rng:NextNumber(30, 38)
	for i = 0, 4 do
		local offset = if i == 0 then Vector3.zero else Vector3.new(math.cos(i * math.pi / 2), 0, math.sin(i * math.pi / 2)) * 3
		newPart({ Name = "Cote", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d),
			CFrame = CFrame.new(base + offset + Vector3.new(0, d * 0.38, 0)),
			Color = C.Orange:Lerp(Color3.fromRGB(255, 150, 40), i * 0.1), Parent = m })
	end
	vcyl("Pedoncule", 7, 3.5, base + Vector3.new(0, d * 0.85, 0), Color3.fromRGB(100, 120, 50), Enum.Material.Wood, m)
end

local function stone(base)
	local d = rng:NextNumber(5, 12)
	newPart({ Name = "Caillou", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d),
		CFrame = CFrame.new(base + Vector3.new(0, d * 0.25, 0)), Color = C.Stone, Material = Enum.Material.Slate })
end

local SEED_LABELS = { "GRAINES DE RADIS", "GRAINES DE CAROTTES", "GRAINES DE TOMATES", "GRAINES DE TOURNESOL" }
local SEED_COLORS = { Color3.fromRGB(230, 70, 90), Color3.fromRGB(250, 160, 40), Color3.fromRGB(80, 170, 230), Color3.fromRGB(250, 220, 60) }

local function seedPacket(base)
	local k = rng:NextInteger(1, #SEED_LABELS)
	local packet = newPart({ Name = "PaquetDeGraines", Size = Vector3.new(26, 34, 1.5),
		CFrame = CFrame.new(base + Vector3.new(0, 16.5, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), math.rad(rng:NextNumber(-6, 6))),
		Color = SEED_COLORS[k] })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.PixelsPerStud = 10
		gui.Parent = packet
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 0.4)
		label.Position = UDim2.fromScale(0, 0.05)
		label.BackgroundTransparency = 1
		label.Text = SEED_LABELS[k]
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
	end
end

local function flowerPot(base)
	local m = group("PotDeFleur")
	vcyl("Pot", 24, 28, base, C.Pot, nil, m)
	vcyl("Rebord", 4, 32, base + Vector3.new(0, 22, 0), C.Pot, nil, m)
	vcyl("Terreau", 1, 27, base + Vector3.new(0, 24.6, 0), C.DarkDirt, Enum.Material.Ground, m)
	vcyl("Tige", 55, 2.5, base + Vector3.new(0, 25, 0), C.DarkLeaf, nil, m)
	local top = base + Vector3.new(0, 80, 0)
	local color = Color3.fromHSV(rng:NextNumber(), 0.6, 1)
	newPart({ Name = "Coeur", Shape = Enum.PartType.Ball, Size = Vector3.new(8, 8, 8), CFrame = CFrame.new(top),
		Color = Color3.fromRGB(255, 210, 40), Parent = m })
	for i = 0, 7 do
		local petal = newPart({ Name = "Petale", Size = Vector3.new(7, 1.5, 15),
			CFrame = CFrame.new(top) * CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0, -9) * CFrame.Angles(math.rad(-15), 0, 0),
			Color = color, CanCollide = false, Parent = m })
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = petal
	end
end

local function wateringCan(base)
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

---------------------------------------------------------------------------
-- Structure : sol, rangs, clôture, spawns
---------------------------------------------------------------------------
local function buildGround(half)
	newPart({ Name = "Sol", Size = Vector3.new(half * 2 + 300, 10, half * 2 + 300), CFrame = CFrame.new(0, -5, 0),
		Color = C.Dirt, Material = Enum.Material.Ground })
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

local ROW_TYPES = { "Carotte", "Laitue", "Tomate", "Radis", "Mix" }
local CROPS = { Carotte = carrot, Laitue = lettuce, Tomate = tomatoPlant, Radis = radish }
local MIX = { carrot, lettuce, tomatoPlant, radish }

local function buildGarden(half)
	local rowIndex = 0
	local rowLength = half * 2 - 180
	for z = -half + 50, half - 50, 75 do
		rowIndex += 1
		newPart({ Name = "Rang", Size = Vector3.new(rowLength, 3, 24), CFrame = CFrame.new(0, 1.5, z),
			Color = C.DarkDirt, Material = Enum.Material.Ground })
		local rowType = ROW_TYPES[(rowIndex - 1) % #ROW_TYPES + 1]
		local x = -rowLength / 2 + 20
		while x < rowLength / 2 - 20 do
			local pos = Vector3.new(x, 3, z + rng:NextNumber(-3, 3))
			if pos.Magnitude > 60 then -- garder le centre libre pour l'arrosoir
				local builder = CROPS[rowType] or MIX[rng:NextInteger(1, #MIX)]
				builder(pos)
			end
			x += rng:NextNumber(40, 70)
		end
		-- sillon suivant : cailloux et paquets de graines
		local furrowZ = z + 37.5
		if furrowZ < half - 20 then
			for _ = 1, 3 do
				stone(Vector3.new(rng:NextNumber(-half + 100, half - 100), 0, furrowZ + rng:NextNumber(-10, 10)))
			end
			if rng:NextNumber() < 0.7 then
				seedPacket(Vector3.new(rng:NextNumber(-half + 120, half - 120), 0, furrowZ))
			end
		end
	end

	wateringCan(Vector3.new(0, 0, 0))
	for _, pos in {
		Vector3.new(130, 0, 187.5), Vector3.new(-130, 0, -187.5), Vector3.new(-130, 0, 187.5), Vector3.new(130, 0, -187.5),
		Vector3.new(-half + 75, 0, 100), Vector3.new(-half + 75, 0, -100), Vector3.new(half - 75, 0, 100), Vector3.new(half - 75, 0, -100),
	} do
		flowerPot(pos)
	end
	for _, pos in { Vector3.new(0, 0, half - 85), Vector3.new(0, 0, -half + 85), Vector3.new(220, 0, 37.5), Vector3.new(-220, 0, -37.5) } do
		pumpkin(pos)
	end
end

local function setupLighting()
	Lighting.ClockTime = 13.5
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 140)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.25
		atmosphere.Color = Color3.fromRGB(220, 235, 255)
		atmosphere.Parent = Lighting
	end
end

function MapBuilder.Build()
	rng = Random.new(Config.Map.Seed)
	local existing = workspace:FindFirstChild("PotagerGeant")

	if not Config.Map.Generate and existing then
		-- Carte faite à la main : on réutilise ses SpawnLocation (nommées Spawn_<Equipe> ou Spawn_Neutre)
		mapFolder = existing
		for _, s in existing:GetDescendants() do
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
		return
	end

	if existing then
		existing:Destroy()
	end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "PotagerGeant"
	mapFolder.Parent = workspace

	local half = Config.Map.Size / 2
	buildGround(half)
	buildFence(half)
	buildSpawns(half)
	buildGarden(half)
	setupLighting()

	-- supprime le Baseplate / SpawnLocation par défaut du template Studio
	for _, name in { "Baseplate", "SpawnLocation" } do
		local obj = workspace:FindFirstChild(name)
		if obj and obj.Parent == workspace then
			obj:Destroy()
		end
	end
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
