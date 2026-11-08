--[[
	La fleur au fusil — Rendu des pétales côté client (ModuleScript)
	Emplacement : ReplicatedStorage > FleurShared > PetalVisual

	Purement visuel : les dégâts sont calculés par le serveur (CombatService).
	Le client simule la même trajectoire (vitesse + gravité) pour l'affichage.
	La couleur vient de la fleur équipée et l'« animation » de l'effet de
	pétales équipé (Cosmetics.PetalEffects) : traînée, étincelles, orbite de
	mini-pétales, et effet d'impact (éclats, cœurs, pluie de pétales).
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(script.Parent:WaitForChild("Config"))
local Cosmetics = require(script.Parent:WaitForChild("Cosmetics"))

local PetalVisual = {}

local active = {}
local fxFolder = nil
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 220, 90)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(70, 140, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 90, 255)),
})
local SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"

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

local function fxPart(size, color, cframe)
	local p = Instance.new("Part")
	p.Name = "PetalFX"
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = cframe
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere -- ellipsoïde = forme de pétale
	mesh.Parent = p
	p.Parent = getFolder()
	return p
end

---------------------------------------------------------------------------
-- Effets d'impact
---------------------------------------------------------------------------
local function impactBurst(position, color)
	for _ = 1, 5 do
		local bit = fxPart(Vector3.new(0.3, 0.05, 0.4), color,
			CFrame.new(position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6))
		local offset = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5) * 4
		TweenService:Create(bit, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = bit.CFrame + offset,
			Transparency = 1,
		}):Play()
		Debris:AddItem(bit, 0.5)
	end
end

local function impactHearts(position, color)
	for _ = 1, 4 do
		local anchor = Instance.new("Part")
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.CFrame = CFrame.new(position + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 2)
		anchor.Parent = getFolder()
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromScale(1.2, 1.2)
		billboard.LightInfluence = 0
		billboard.Parent = anchor
		local heart = Instance.new("TextLabel")
		heart.Size = UDim2.fromScale(1, 1)
		heart.BackgroundTransparency = 1
		heart.Text = "❤"
		heart.TextScaled = true
		heart.TextColor3 = color
		heart.Parent = billboard
		TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = anchor.CFrame + Vector3.new(0, 3 + math.random() * 2, 0),
		}):Play()
		TweenService:Create(heart, TweenInfo.new(0.9), { TextTransparency = 1 }):Play()
		Debris:AddItem(anchor, 1)
	end
end

local function impactRain(position, color)
	for _ = 1, 10 do
		local start = position + Vector3.new(math.random() - 0.5, 2 + math.random() * 2, math.random() - 0.5) * 3
		local bit = fxPart(Vector3.new(0.5, 0.08, 0.7), color, CFrame.new(start) * CFrame.Angles(math.random() * 6, math.random() * 6, 0))
		TweenService:Create(bit, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			CFrame = CFrame.new(start - Vector3.new(0, 3.5, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
			Transparency = 1,
		}):Play()
		Debris:AddItem(bit, 1.4)
	end
end

local IMPACTS = { Burst = impactBurst, Hearts = impactHearts, Rain = impactRain }

---------------------------------------------------------------------------
-- Pétale tiré
---------------------------------------------------------------------------
-- origin, velocity : Vector3 ; flowerId / effectId : Id de cosmétiques ; ignoreModel : le tireur
function PetalVisual.Spawn(origin, velocity, flowerId, effectId, ignoreModel)
	if velocity.Magnitude < 0.01 then
		return
	end
	local flower = Cosmetics.Get("FlowerSkin", flowerId)
	local effect = Cosmetics.Get("PetalEffect", effectId)
	local color = flower.PetalColor
	local scale = effect.Size or 1

	local petal = fxPart(Vector3.new(0.8, 0.15, 1.1) * scale, color, CFrame.lookAt(origin, origin + velocity))

	if effect.Trail then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(-0.35 * scale, 0, 0)
		a0.Parent = petal
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0.35 * scale, 0, 0)
		a1.Parent = petal
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.3
		trail.LightEmission = 0.5
		trail.FaceCamera = true
		trail.Color = if effect.Trail == "Rainbow" then RAINBOW else ColorSequence.new(color)
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Parent = petal
	end

	if effect.Sparkles then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = SPARKLES
		emitter.Rate = 30
		emitter.Lifetime = NumberRange.new(0.25, 0.45)
		emitter.Speed = NumberRange.new(0.5, 1.5)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new(0.35, 0)
		emitter.LightEmission = 1
		emitter.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.5))
		emitter.Parent = petal
	end

	local orbiters = {}
	for _ = 1, effect.Orbit or 0 do
		table.insert(orbiters, fxPart(Vector3.new(0.4, 0.08, 0.55), flower.HeartColor:Lerp(color, 0.5), petal.CFrame))
	end

	table.insert(active, {
		Part = petal,
		Orbiters = orbiters,
		Pos = origin,
		Vel = velocity,
		Born = os.clock(),
		Spin = math.random() * math.pi * 2,
		Color = color,
		Impact = IMPACTS[effect.Impact] or impactBurst,
		Ignore = ignoreModel,
	})
end

local function destroyEntry(p)
	p.Part:Destroy()
	for _, o in p.Orbiters do
		o:Destroy()
	end
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
					p.Impact(result.Position, p.Color)
					finished = true
				else
					p.Pos += displacement
					p.Spin += dt * 12
					local cf = CFrame.lookAt(p.Pos, p.Pos + p.Vel) * CFrame.Angles(0, 0, p.Spin)
					p.Part.CFrame = cf
					for k, o in p.Orbiters do
						local angle = p.Spin * 0.8 + k * (math.pi * 2 / #p.Orbiters)
						o.CFrame = cf * CFrame.new(math.cos(angle) * 0.9, math.sin(angle) * 0.9, 0)
					end
				end
			end
			if finished then
				destroyEntry(p)
				active[i] = active[#active]
				active[#active] = nil
			end
		end
	end)
end

return PetalVisual
