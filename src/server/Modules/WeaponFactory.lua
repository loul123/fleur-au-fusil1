--[[
	La fleur au fusil — Fabrique de l'arme (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > WeaponFactory

	Construit par code un Tool « FleurAuFusil » : crosse en bois, canon-tige
	vert et une fleur au bout (dont la couleur dépend du palier de l'arme).
	Aucun modèle à importer.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))

local WeaponFactory = {}

local WOOD = Color3.fromRGB(124, 84, 50)
local STEM = Color3.fromRGB(70, 150, 60)
local FLOWER_Y = 0.15
local FLOWER_Z = -4.0

local function makePart(handle, name, size, cframe, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = handle
	return p
end

local function ellipsoid(part)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
end

function WeaponFactory.Create(tierIndex)
	local tier, index = Config.GetTier(tierIndex)

	local tool = Instance.new("Tool")
	tool.Name = Config.ToolName
	tool.ToolTip = "La fleur au fusil — " .. tier.Name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -0.1, 1.0) -- la main tient l'arrière de la crosse
	tool:SetAttribute("Tier", index)

	-- Crosse (Handle) construite à l'origine : toutes les pièces sont placées relativement
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.55, 3.2)
	handle.CFrame = CFrame.new()
	handle.Color = WOOD
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.CanTouch = false
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth

	-- Canon = tige de fleur
	makePart(handle, "Tige", Vector3.new(2.6, 0.22, 0.22),
		CFrame.new(0, FLOWER_Y, -2.6) * CFrame.Angles(0, math.rad(90), 0), STEM, Enum.PartType.Cylinder)

	-- Petite feuille sur la tige
	local leaf = makePart(handle, "Feuille", Vector3.new(0.08, 0.35, 0.8),
		CFrame.new(0.22, FLOWER_Y + 0.12, -2.4) * CFrame.Angles(0, 0, math.rad(-35)), STEM)
	ellipsoid(leaf)

	-- Cœur de la fleur
	local heart = makePart(handle, "Coeur", Vector3.new(0.45, 0.45, 0.45),
		CFrame.new(0, FLOWER_Y, FLOWER_Z), tier.HeartColor, Enum.PartType.Ball)
	heart.Material = Enum.Material.Neon

	-- Couronne de pétales, dans le plan face au tir
	local center = CFrame.new(0, FLOWER_Y, FLOWER_Z + 0.05)
	for i = 0, 7 do
		local petal = makePart(handle, "Petal", Vector3.new(0.32, 0.6, 0.08),
			center * CFrame.Angles(0, 0, math.rad(i * 45)) * CFrame.new(0, 0.42, 0), tier.PetalColor)
		ellipsoid(petal)
	end

	-- Point de sortie des projectiles
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, FLOWER_Y, FLOWER_Z - 0.4)
	muzzle.Parent = handle

	handle.Parent = tool
	return tool
end

-- Change la couleur de la fleur quand le palier évolue (Gun Game)
function WeaponFactory.Recolor(tool, tierIndex)
	local tier, index = Config.GetTier(tierIndex)
	tool:SetAttribute("Tier", index)
	tool.ToolTip = "La fleur au fusil — " .. tier.Name
	for _, d in tool:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Petal" then
				d.Color = tier.PetalColor
			elseif d.Name == "Coeur" then
				d.Color = tier.HeartColor
			end
		end
	end
end

return WeaponFactory
