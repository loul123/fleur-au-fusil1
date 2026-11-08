--[[
	La fleur au fusil — Rendu des pétales côté client (ModuleScript)
	Emplacement : ReplicatedStorage > FleurShared > PetalVisual

	Purement visuel : les dégâts sont calculés par le serveur (CombatService).
	Le client simule la même trajectoire (vitesse + gravité) pour l'affichage.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(script.Parent:WaitForChild("Config"))

local PetalVisual = {}

local active = {}
local fxFolder = nil
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function getFolder()
	if not fxFolder or not fxFolder.Parent then
		fxFolder = Instance.new("Folder")
		fxFolder.Name = "FleurPetalsFX"
		fxFolder.Parent = workspace
	end
	return fxFolder
end

function PetalVisual.GetFolder()
	return getFolder()
end

local function burst(position, color)
	for _ = 1, 5 do
		local bit = Instance.new("Part")
		bit.Size = Vector3.new(0.3, 0.05, 0.4)
		bit.Color = color
		bit.Material = Enum.Material.SmoothPlastic
		bit.Anchored = true
		bit.CanCollide = false
		bit.CanQuery = false
		bit.CanTouch = false
		bit.CastShadow = false
		bit.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		bit.Parent = getFolder()
		local offset = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5) * 4
		TweenService:Create(bit, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = bit.CFrame + offset,
			Transparency = 1,
		}):Play()
		Debris:AddItem(bit, 0.5)
	end
end

-- origin : Vector3, velocity : Vector3 (studs/s), color : Color3, ignoreModel : Model? (le tireur)
function PetalVisual.Spawn(origin, velocity, color, ignoreModel)
	if velocity.Magnitude < 0.01 then
		return
	end
	local petal = Instance.new("Part")
	petal.Name = "PetalFX"
	petal.Size = Vector3.new(0.8, 0.15, 1.1)
	petal.Color = color
	petal.Material = Enum.Material.SmoothPlastic
	petal.Anchored = true
	petal.CanCollide = false
	petal.CanQuery = false
	petal.CanTouch = false
	petal.CastShadow = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere -- ellipsoïde = forme de pétale
	mesh.Parent = petal
	petal.CFrame = CFrame.lookAt(origin, origin + velocity)
	petal.Parent = getFolder()

	table.insert(active, {
		Part = petal,
		Pos = origin,
		Vel = velocity,
		Born = os.clock(),
		Spin = math.random() * math.pi * 2,
		Color = color,
		Ignore = ignoreModel,
	})
end

if RunService:IsClient() then
	local gravity = Vector3.new(0, -Config.Combat.PetalGravity, 0)
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		for i = #active, 1, -1 do
			local p = active[i]
			local finished = false
			if now - p.Born > Config.Combat.PetalLifetime then
				finished = true
			else
				p.Vel += gravity * dt
				local displacement = p.Vel * dt
				params.FilterDescendantsInstances = { getFolder(), p.Ignore }
				local result = workspace:Raycast(p.Pos, displacement, params)
				if result then
					burst(result.Position, p.Color)
					finished = true
				else
					p.Pos += displacement
					p.Spin += dt * 12
					p.Part.CFrame = CFrame.lookAt(p.Pos, p.Pos + p.Vel) * CFrame.Angles(0, 0, p.Spin)
				end
			end
			if finished then
				p.Part:Destroy()
				active[i] = active[#active]
				active[#active] = nil
			end
		end
	end)
end

return PetalVisual
