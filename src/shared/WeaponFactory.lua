--[[
	La fleur au fusil — Fabrique de l'arme (ModuleScript partagé)
	Emplacement : ReplicatedStorage > FleurShared > WeaponFactory

	Construit par code le fusil « FleurAuFusil » : fusil d'assaut stylisé
	(crosse, carcasse, lunette, chargeur courbe, garde-main ajouré, poignée
	verticale, guidon, cache-flamme) avec une marguerite au bout du canon
	(tige verte, deux feuilles, cœur jaune, pétales blancs vus de profil).
	Les couleurs viennent du skin d'arme et du skin de fleur (Cosmetics).
	Partagé : le serveur l'utilise pour les Tools, le client pour l'aperçu
	dans le casier (ViewportFrame).
]]

local Shared = script.Parent
local Config = require(Shared:WaitForChild("Config"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))

local WeaponFactory = {}

local SCALE = 0.85 -- taille globale de l'arme
local CYL_Z = CFrame.Angles(0, math.rad(90), 0) -- cylindre orienté vers l'avant (-Z)
local Y = 0.05 -- hauteur de l'axe du canon
local FLOWER = CFrame.new(0, Y, -3.5) -- centre de la fleur

local function at(x, y, z)
	return CFrame.new(x, y, z)
end

local function rx(deg)
	return CFrame.Angles(math.rad(deg), 0, 0)
end

-- Géométrie du fusil (avant = -Z, haut = +Y), en studs avant SCALE.
-- Role : Body | Accent | Metal | Dark | Lens
local GUN = {
	{ "Culasse", "Dark", Vector3.new(0.33, 0.1, 0.36), at(0, 0.08, -0.12) },
	{ "Carcasse", "Body", Vector3.new(0.3, 0.22, 0.9), at(0, -0.26, 0.05) },
	{ "Rail", "Metal", Vector3.new(0.2, 0.07, 1.25), at(0, 0.245, -0.05) },
	{ "Montage", "Metal", Vector3.new(0.16, 0.16, 0.35), at(0, 0.34, 0) },
	{ "Lunette", "Metal", Vector3.new(1.1, 0.26, 0.26), at(0, 0.52, -0.02) * CYL_Z, Enum.PartType.Cylinder },
	{ "LunetteAvant", "Metal", Vector3.new(0.28, 0.36, 0.36), at(0, 0.54, -0.55) * CYL_Z, Enum.PartType.Cylinder },
	{ "LunetteArriere", "Metal", Vector3.new(0.2, 0.3, 0.3), at(0, 0.52, 0.52) * CYL_Z, Enum.PartType.Cylinder },
	{ "Tourelle", "Metal", Vector3.new(0.14, 0.12, 0.14), at(0, 0.69, -0.02) },
	{ "Lentille", "Lens", Vector3.new(0.02, 0.3, 0.3), at(0, 0.54, -0.7) * CYL_Z, Enum.PartType.Cylinder },
	{ "Tube", "Metal", Vector3.new(0.8, 0.18, 0.18), at(0, 0.08, 1.05) * CYL_Z, Enum.PartType.Cylinder },
	{ "Crosse", "Accent", Vector3.new(0.3, 0.4, 0.7), at(0, 0.04, 1.55) },
	{ "CrosseBas", "Accent", Vector3.new(0.26, 0.28, 0.5), at(0, -0.26, 1.6) * rx(12) },
	{ "Plaque", "Metal", Vector3.new(0.32, 0.62, 0.08), at(0, -0.06, 1.93) },
	{ "Poignee", "Accent", Vector3.new(0.24, 0.62, 0.26), at(0, -0.5, 0.38) * rx(-20) },
	{ "Pontet", "Metal", Vector3.new(0.06, 0.06, 0.42), at(0, -0.42, 0.02) },
	{ "Detente", "Metal", Vector3.new(0.05, 0.16, 0.05), at(0, -0.34, 0.08) },
	{ "Chargeur", "Metal", Vector3.new(0.2, 0.8, 0.32), at(0, -0.72, -0.38) * rx(15) },
	{ "TalonChargeur", "Accent", Vector3.new(0.24, 0.1, 0.38), at(0, -0.72, -0.38) * rx(15) * at(0, -0.43, 0) },
	{ "GardeMain", "Accent", Vector3.new(0.34, 0.36, 1.25), at(0, 0.03, -1.3) },
	{ "Fente", "Dark", Vector3.new(0.35, 0.06, 0.16), at(0, 0.1, -0.9) },
	{ "Fente", "Dark", Vector3.new(0.35, 0.06, 0.16), at(0, 0.1, -1.17) },
	{ "Fente", "Dark", Vector3.new(0.35, 0.06, 0.16), at(0, 0.1, -1.44) },
	{ "Fente", "Dark", Vector3.new(0.35, 0.06, 0.16), at(0, 0.1, -1.71) },
	{ "RailAvant", "Metal", Vector3.new(0.2, 0.06, 1.2), at(0, 0.24, -1.3) },
	{ "PoigneeAvant", "Metal", Vector3.new(0.18, 0.5, 0.2), at(0, -0.38, -1.45) },
	{ "BaseGuidon", "Metal", Vector3.new(0.16, 0.14, 0.18), at(0, 0.28, -1.95) },
	{ "Guidon", "Metal", Vector3.new(0.07, 0.38, 0.08), at(0, 0.45, -1.95) },
	{ "Bloc", "Metal", Vector3.new(0.18, 0.2, 0.18), at(0, Y, -1.98) },
	{ "Canon", "Metal", Vector3.new(0.7, 0.12, 0.12), at(0, Y, -2.25) * CYL_Z, Enum.PartType.Cylinder },
	{ "CacheFlamme", "Metal", Vector3.new(0.32, 0.2, 0.2), at(0, Y, -2.65) * CYL_Z, Enum.PartType.Cylinder },
}

local function material(name, fallback)
	if not name then
		return fallback
	end
	local ok, value = pcall(function()
		return Enum.Material[name]
	end)
	return if ok and value then value else fallback
end

local function addPart(handle, name, role, size, cframe, shape, ellipsoid)
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size * SCALE
	p.CFrame = CFrame.new(cframe.Position * SCALE) * cframe.Rotation
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("Role", role)
	if ellipsoid then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = handle
	return p
end

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 220, 90)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 140, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
})

-- Couleur d'un pétale (couronne `ring`, position `index`)
function WeaponFactory.PetalColor(flower, ring, index)
	if flower.PetalColors then
		local list = flower.PetalColors
		return list[(index + ring) % #list + 1]
	end
	if ring > 0 then
		return flower.PetalColor2 or flower.PetalColor:Lerp(Color3.new(1, 1, 1), 0.25 * ring)
	end
	return flower.PetalColor
end

local function buildFlower(handle, flower)
	-- tige + deux feuilles entre le cache-flamme et la fleur
	addPart(handle, "Tige", "Stem", Vector3.new(0.65, 0.07, 0.07), at(0, Y, -3.13) * CYL_Z, Enum.PartType.Cylinder)
	addPart(handle, "Feuille", "Stem", Vector3.new(0.05, 0.2, 0.45), at(0, Y + 0.13, -3.0) * rx(35), nil, true)
	addPart(handle, "Feuille", "Stem", Vector3.new(0.05, 0.2, 0.45), at(0, Y - 0.13, -3.0) * rx(-35), nil, true)

	-- fleur vue de profil (comme sur le modèle) : pétales dans le plan YZ
	local heartSize = 0.48 * (flower.HeartScale or 1)
	local heart = addPart(handle, "Coeur", "Heart", Vector3.new(0.22, heartSize, heartSize), FLOWER, nil, true)
	local count = flower.Petals or 12
	local layers = math.clamp(flower.Layers or 1, 1, 3)
	for ring = 0, layers - 1 do
		local scale = 1 - 0.28 * ring
		local length = 0.5 * (flower.PetalLength or 1) * scale
		local width = math.min(0.24 * (flower.PetalWidth or 1), 0.6) * scale
		local radius = heartSize / 2 + length / 2 - 0.05
		local offset = if ring % 2 == 1 then 180 / count else 0 -- couronnes décalées
		for i = 0, count - 1 do
			local petal = addPart(handle, "Petal", "Petal", Vector3.new(0.06 + 0.03 * ring, length, width),
				FLOWER * rx(i * 360 / count + offset) * at(0, radius, 0), nil, true)
			petal:SetAttribute("Ring", ring)
			petal:SetAttribute("Index", i)
		end
	end

	-- aura de particules et lumière pour les fleurs rares
	if flower.Aura or flower.AuraRainbow then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Aura"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Rate = 10
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(0.3, 0.8)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new(0.25, 0)
		emitter.LightEmission = 1
		emitter.Color = if flower.AuraRainbow then RAINBOW else ColorSequence.new(flower.Aura)
		emitter.Parent = heart
	end
	if flower.Light then
		local light = Instance.new("PointLight")
		light.Range = 5
		light.Brightness = 1.2
		light.Color = flower.Aura or flower.HeartColor
		light.Parent = heart
	end
end

-- Applique les couleurs / matériaux d'une tenue à toutes les pièces
function WeaponFactory.ApplyLook(root, look)
	local skin = Cosmetics.Get("WeaponSkin", look and look.WeaponSkin)
	local flower = Cosmetics.Get("FlowerSkin", look and look.FlowerSkin)
	local base = material(skin.Material, Enum.Material.SmoothPlastic)
	local colors = {
		Body = { skin.Body, base },
		Accent = { skin.Accent, material(skin.AccentMaterial, base) },
		Metal = { skin.Metal, material(skin.MetalMaterial, Enum.Material.SmoothPlastic) },
		Dark = { skin.Dark, Enum.Material.SmoothPlastic },
		Lens = { Color3.fromRGB(90, 190, 255), Enum.Material.Glass },
		Stem = { flower.StemColor, Enum.Material.SmoothPlastic },
		Heart = { flower.HeartColor, material(flower.HeartMaterial, Enum.Material.SmoothPlastic) },
		Petal = { flower.PetalColor, material(flower.PetalMaterial, Enum.Material.SmoothPlastic) },
	}
	local parts = root:GetDescendants()
	if root:IsA("BasePart") then
		table.insert(parts, root)
	end
	for _, p in parts do
		if p:IsA("BasePart") then
			local entry = colors[p:GetAttribute("Role")]
			if entry then
				p.Color = entry[1]
				p.Material = entry[2]
				if p:GetAttribute("Role") == "Petal" then
					p.Color = WeaponFactory.PetalColor(flower, p:GetAttribute("Ring") or 0, p:GetAttribute("Index") or 0)
				end
			end
		end
	end
end

local function buildHandle(look)
	local flower = Cosmetics.Get("FlowerSkin", look and look.FlowerSkin)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.32, 0.42, 1.3) * SCALE -- carcasse supérieure
	handle.CFrame = CFrame.new()
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CastShadow = false
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle:SetAttribute("Role", "Body")

	for _, spec in GUN do
		addPart(handle, spec[1], spec[2], spec[3], spec[4], spec[5])
	end
	buildFlower(handle, flower)

	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, Y, -3.6) * SCALE
	muzzle.Parent = handle

	WeaponFactory.ApplyLook(handle, look)
	return handle
end

local function tooltip(tool, tierIndex, look)
	local tier, index = Config.GetTier(tierIndex)
	local skin = Cosmetics.Get("WeaponSkin", look and look.WeaponSkin)
	tool:SetAttribute("Tier", index)
	tool.ToolTip = string.format("La fleur au fusil — %s (%s)", tier.Name, skin.Name)
end

-- Crée le Tool. look = { WeaponSkin, FlowerSkin, PetalEffect } (optionnel)
function WeaponFactory.Create(tierIndex, look)
	local tool = Instance.new("Tool")
	tool.Name = Config.ToolName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(Vector3.new(0, -0.5, 0.38) * SCALE) -- la main tient la poignée pistolet
	tooltip(tool, tierIndex, look)
	buildHandle(look).Parent = tool
	return tool
end

-- Palier de Gun Game : l'apparence (skin) ne change pas, seules les stats changent
function WeaponFactory.SetTier(tool, tierIndex, look)
	tooltip(tool, tierIndex, look)
end

-- Modèle statique pour un aperçu (ViewportFrame) ; l'arme est centrée sur l'origine
function WeaponFactory.CreatePreview(look)
	local model = Instance.new("Model")
	model.Name = "ApercuArme"
	local handle = buildHandle(look)
	for _, d in handle:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	handle.Anchored = true
	handle.Parent = model
	model.PrimaryPart = handle
	return model
end

return WeaponFactory
