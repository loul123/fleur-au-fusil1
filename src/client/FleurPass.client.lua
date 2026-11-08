--[[
	La fleur au fusil — Pass de saison & casier (LocalScript)
	Emplacement : StarterPlayer > StarterPlayerScripts > FleurClient > FleurPass

	* Bouton « Pass » (touche B) : paliers gratuits / premium, progression en
	  graines, achat du Pass Premium (Game Pass).
	* Onglet Sachets : ouvrir des sachets de graines (tirage d'une fleur,
	  probabilités affichées), en stock ou payés avec le solde de graines.
	* Onglet Casier : aperçu 3D de l'arme, équiper skins d'arme, fleurs et
	  animations de pétales possédés.
	* Fenêtres « +N graines » en fin de partie et « Nouvelle récompense ».
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("FleurShared")
local Config = require(Shared:WaitForChild("Config"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))
local WeaponFactory = require(Shared:WaitForChild("WeaponFactory"))
local remotes = ReplicatedStorage:WaitForChild(Config.RemotesFolderName)

local BP = Config.BattlePass
local FONT = Enum.Font.FredokaOne
local PANEL = Color3.fromRGB(35, 50, 30)
local GOLD = Color3.fromRGB(255, 200, 60)

local profile = { Seeds = 0, SeedBalance = 0, Packs = {}, Premium = false, Owned = {}, Equipped = Cosmetics.DefaultLook() }
local ownedSet = {}
local premiumPrice = nil
local productPrices = {} -- [Key] = prix en Robux

---------------------------------------------------------------------------
-- Aides UI
---------------------------------------------------------------------------
local function make(className, props, parent)
	local obj = Instance.new(className)
	for k, v in props do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function corner(parent, r)
	make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, parent)
end

local function label(props, parent)
	local base = { BackgroundTransparency = 1, Font = FONT, TextColor3 = Color3.new(1, 1, 1), TextScaled = true }
	for k, v in props do
		base[k] = v
	end
	local l = make("TextLabel", base, parent)
	make("UIStroke", { Thickness = 1.2, Color = Color3.fromRGB(20, 30, 15) }, l)
	return l
end

local function button(props, parent)
	local base = { Font = FONT, TextColor3 = Color3.new(1, 1, 1), TextScaled = true, BorderSizePixel = 0, AutoButtonColor = true,
		BackgroundColor3 = Color3.fromRGB(80, 130, 60) }
	for k, v in props do
		base[k] = v
	end
	local b = make("TextButton", base, parent)
	corner(b)
	return b
end

local function clear(container)
	for _, c in container:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function isOwned(typeName, id)
	return ownedSet[Cosmetics.Key(typeName, id)] == true or Cosmetics.IsDefault(typeName, id)
end

local function swatches(item, parent, size)
	local colors
	if item.Type == "WeaponSkin" then
		colors = { item.Body, item.Accent, item.Metal }
	elseif item.Type == "FlowerSkin" then
		colors = if item.PetalColors then { item.PetalColors[1], item.PetalColors[2], item.PetalColors[3] or item.HeartColor }
			else { item.PetalColor, item.PetalColor2 or item.HeartColor }
	elseif item.Type == "Pack" then
		colors = { item.Color }
	else
		colors = nil
	end
	local holder = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, size) }, parent)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4) }, holder)
	if colors then
		for _, c in colors do
			local dot = make("Frame", { Size = UDim2.fromOffset(size, size), BackgroundColor3 = c, BorderSizePixel = 0 }, holder)
			corner(dot, size)
			make("UIStroke", { Color = Color3.fromRGB(20, 20, 20), Thickness = 1 }, dot)
		end
	else
		label({ Size = UDim2.fromOffset(size * 3, size), Text = "✨🌸✨" }, holder)
	end
	return holder
end

---------------------------------------------------------------------------
-- Fenêtre principale
---------------------------------------------------------------------------
local gui = make("ScreenGui", { Name = "FleurPassGui", ResetOnSpawn = false, DisplayOrder = 10 }, player:WaitForChild("PlayerGui"))

local openButton = button({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12), Size = UDim2.fromOffset(170, 46),
	Text = "🌱 Pass (B)", BackgroundColor3 = Color3.fromRGB(60, 120, 50) }, gui)

local window = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(820, 500),
	BackgroundColor3 = PANEL, BackgroundTransparency = 0.05, Visible = false }, gui)
corner(window, 14)
make("UIStroke", { Color = Color3.fromRGB(140, 200, 100), Thickness = 2 }, window)

local title = label({ Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -200, 0, 30), Text = BP.SeasonName, TextXAlignment = Enum.TextXAlignment.Left }, window)
local closeButton = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(36, 36), Text = "✕",
	BackgroundColor3 = Color3.fromRGB(170, 60, 60) }, window)
local tabPass = button({ Position = UDim2.fromOffset(16, 48), Size = UDim2.fromOffset(170, 32), Text = "Pass de saison" }, window)
local tabPacks = button({ Position = UDim2.fromOffset(194, 48), Size = UDim2.fromOffset(130, 32), Text = "Sachets" }, window)
local tabLocker = button({ Position = UDim2.fromOffset(332, 48), Size = UDim2.fromOffset(130, 32), Text = "Casier" }, window)
local balanceLabel = label({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -56, 0, 50), Size = UDim2.fromOffset(300, 28), Text = "",
	TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(180, 240, 140) }, window)

local pagePass = make("Frame", { Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 1, -88), BackgroundTransparency = 1 }, window)
local pageLocker = make("Frame", { Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 1, -88), BackgroundTransparency = 1, Visible = false }, window)
local pagePacks = make("Frame", { Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 1, -88), BackgroundTransparency = 1, Visible = false }, window)

---------------------------------------------------------------------------
-- Onglet Pass
---------------------------------------------------------------------------
local seedsLabel = label({ Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(330, 30), Text = "🌱 0 graines", TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(180, 240, 140) }, pagePass)
local progressText = label({ Position = UDim2.fromOffset(16, 32), Size = UDim2.fromOffset(440, 20), Text = "", TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(210, 230, 200) }, pagePass)
local barBack = make("Frame", { Position = UDim2.fromOffset(16, 56), Size = UDim2.fromOffset(440, 10), BackgroundColor3 = Color3.fromRGB(20, 25, 15), BorderSizePixel = 0 }, pagePass)
corner(barBack, 5)
local barFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(140, 220, 90), BorderSizePixel = 0 }, barBack)
corner(barFill, 5)

local premiumButton = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 0), Size = UDim2.fromOffset(330, 52),
	Text = "Débloquer le Pass Premium", BackgroundColor3 = Color3.fromRGB(200, 140, 20) }, pagePass)
make("UIStroke", { Color = GOLD, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, premiumButton)

label({ Position = UDim2.fromOffset(16, 76), Size = UDim2.fromOffset(420, 20), Text = "En haut : piste gratuite  •  En bas : piste premium ✿",
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD }, pagePass)

local track = make("ScrollingFrame", { Position = UDim2.fromOffset(16, 100), Size = UDim2.new(1, -32, 1, -112), BackgroundTransparency = 1,
	ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.X,
	CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0 }, pagePass)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, track)

local function rewardCard(reward, unlocked, isPremium, parent, order)
	local card = make("Frame", { Size = UDim2.new(1, 0, 0, 130), LayoutOrder = order, BorderSizePixel = 0,
		BackgroundColor3 = if isPremium then Color3.fromRGB(70, 55, 20) else Color3.fromRGB(45, 65, 40) }, parent)
	corner(card)
	make("UIStroke", { Color = if isPremium then GOLD else Color3.fromRGB(110, 150, 90), Thickness = if unlocked then 3 else 1 }, card)
	if not reward then
		label({ Size = UDim2.fromScale(1, 1), Text = "—", TextColor3 = Color3.fromRGB(120, 140, 110) }, card)
		return card
	end
	local item
	if reward.Type == "Pack" then
		local pack = Cosmetics.GetPack(reward.Id)
		item = { Type = "Pack", Name = string.format("%s ×%d", pack.Name, reward.Count or 1), Color = pack.Color,
			Rarity = if pack.Id == "SachetDore" then "Legendaire" else "Rare" }
	else
		item = Cosmetics.Get(reward.Type, reward.Id)
	end
	local rarity = Cosmetics.Rarities[item.Rarity] or Cosmetics.Rarities.Commune
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, card)
	make("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	label({ Size = UDim2.new(1, 0, 0, 14), Text = if reward.Type == "Pack" then "Sachet" else Cosmetics.TypeLabels[reward.Type], TextColor3 = Color3.fromRGB(200, 210, 190), LayoutOrder = 1 }, card)
	swatches(item, card, 18).LayoutOrder = 2
	label({ Size = UDim2.new(1, 0, 0, 34), Text = item.Name, TextWrapped = true, LayoutOrder = 3 }, card)
	label({ Size = UDim2.new(1, 0, 0, 14), Text = rarity.Label, TextColor3 = rarity.Color, LayoutOrder = 4 }, card)
	local state = if unlocked then "✔ Obtenu" elseif isPremium and not profile.Premium then "🔒 Premium" else "🔒"
	label({ Size = UDim2.new(1, 0, 0, 18), Text = state, LayoutOrder = 5,
		TextColor3 = if unlocked then Color3.fromRGB(140, 240, 120) else Color3.fromRGB(220, 200, 180) }, card)
	return card
end

local function renderPass()
	clear(track)
	local seeds = profile.Seeds or 0
	local reached = 0
	for i, tier in BP.Tiers do
		if seeds >= tier.Seeds then
			reached = i
		end
		local column = make("Frame", { Size = UDim2.new(0, 120, 1, -10), BackgroundTransparency = 1, LayoutOrder = i }, track)
		make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, column)
		local done = seeds >= tier.Seeds
		rewardCard(tier.Free, done, false, column, 1)
		label({ Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 2, Text = string.format("%d • 🌱%d", i, tier.Seeds),
			TextColor3 = if done then Color3.fromRGB(180, 240, 140) else Color3.fromRGB(200, 200, 200) }, column)
		rewardCard(tier.Premium, done and profile.Premium, true, column, 3)
	end

	seedsLabel.Text = string.format("Progression : 🌱 %d graines", seeds)
	local nextTier = BP.Tiers[reached + 1]
	if nextTier then
		local from = if reached > 0 then BP.Tiers[reached].Seeds else 0
		progressText.Text = string.format("Palier %d/%d — encore %d graines pour le palier %d", reached, #BP.Tiers, nextTier.Seeds - seeds, reached + 1)
		barFill.Size = UDim2.fromScale(math.clamp((seeds - from) / math.max(1, nextTier.Seeds - from), 0, 1), 1)
	else
		progressText.Text = string.format("Pass terminé ! (%d/%d paliers)", reached, #BP.Tiers)
		barFill.Size = UDim2.fromScale(1, 1)
	end

	if profile.Premium then
		premiumButton.Text = "✿ PASS PREMIUM ACTIF ✿"
		premiumButton.AutoButtonColor = false
		premiumButton.BackgroundColor3 = Color3.fromRGB(150, 110, 20)
	else
		premiumButton.Text = string.format("Débloquer le Pass Premium%s  (+%d%% graines)",
			if premiumPrice then " — R$ " .. premiumPrice else "", math.floor(BP.PremiumSeedBonus * 100 + 0.5))
	end
	openButton.Text = string.format("🌱 %d  •  Pass (B)", profile.SeedBalance or 0)
	balanceLabel.Text = string.format("Solde : 🌱 %d graines", profile.SeedBalance or 0)
end

premiumButton.Activated:Connect(function()
	if not profile.Premium then
		remotes.BuyPremium:FireServer()
	end
end)

---------------------------------------------------------------------------
-- Onglet Casier (avec aperçu 3D de l'arme)
---------------------------------------------------------------------------
local viewport = make("ViewportFrame", { Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(330, 300), BackgroundColor3 = Color3.fromRGB(225, 228, 232),
	Ambient = Color3.fromRGB(170, 170, 170), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -1, -0.5) }, pageLocker)
corner(viewport, 12)
local viewportCamera = make("Camera", { FieldOfView = 30 }, viewport)
viewport.CurrentCamera = viewportCamera
local previewModel = nil
local previewKey = ""
local previewAngle = 0
local lookLabel = label({ Position = UDim2.fromOffset(16, 306), Size = UDim2.fromOffset(330, 60), Text = "", TextWrapped = true,
	TextColor3 = Color3.fromRGB(210, 230, 200) }, pageLocker)

local function refreshPreview()
	local look = profile.Equipped
	local key = look.WeaponSkin .. look.FlowerSkin
	if key == previewKey and previewModel then
		return
	end
	previewKey = key
	if previewModel then
		previewModel:Destroy()
	end
	previewModel = WeaponFactory.CreatePreview(look)
	previewModel.Parent = viewport
	local effect = Cosmetics.Get("PetalEffect", look.PetalEffect)
	lookLabel.Text = string.format("%s\n%s • %s", Cosmetics.Get("WeaponSkin", look.WeaponSkin).Name,
		Cosmetics.Get("FlowerSkin", look.FlowerSkin).Name, effect.Name)
end

local lists = make("ScrollingFrame", { Position = UDim2.fromOffset(362, 0), Size = UDim2.new(1, -378, 1, -12), BackgroundTransparency = 1,
	ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0 }, pageLocker)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, lists)

local function renderLocker()
	clear(lists)
	local order = 0
	for _, typeName in Cosmetics.Types do
		order += 1
		label({ Size = UDim2.new(1, -10, 0, 24), LayoutOrder = order, Text = Cosmetics.TypeLabels[typeName], TextXAlignment = Enum.TextXAlignment.Left }, lists)
		order += 1
		local grid = make("Frame", { Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, lists)
		make("UIGridLayout", { CellSize = UDim2.fromOffset(136, 74), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		for i, item in Cosmetics.List(typeName) do
			local owned = isOwned(typeName, item.Id)
			local equipped = profile.Equipped[typeName] == item.Id
			local rarity = Cosmetics.Rarities[item.Rarity] or Cosmetics.Rarities.Commune
			local cell = button({ Text = "", LayoutOrder = rarity.Order * 100 + i, AutoButtonColor = owned,
				BackgroundColor3 = if owned then Color3.fromRGB(55, 80, 45) else Color3.fromRGB(45, 45, 45) }, grid)
			make("UIStroke", { Color = if equipped then Color3.fromRGB(140, 255, 120) else rarity.Color, Thickness = if equipped then 3 else 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, cell)
			local swatch = swatches(item, cell, 14)
			swatch.Position = UDim2.fromOffset(0, 6)
			label({ Position = UDim2.fromOffset(4, 24), Size = UDim2.new(1, -8, 0, 26),
				Text = if item.Number then string.format("#%d %s", item.Number, item.Name) else item.Name, TextWrapped = true,
				TextTransparency = if owned then 0 else 0.4 }, cell)
			label({ Position = UDim2.fromOffset(4, 52), Size = UDim2.new(1, -8, 0, 16),
				Text = if equipped then "Équipé" elseif owned then rarity.Label else "🔒 Pass de saison",
				TextColor3 = if equipped then Color3.fromRGB(140, 255, 120) else rarity.Color }, cell)
			cell.Activated:Connect(function()
				if owned and not equipped then
					remotes.EquipCosmetic:FireServer(typeName, item.Id)
				end
			end)
		end
	end
	refreshPreview()
end

RunService.RenderStepped:Connect(function(dt)
	if not (window.Visible and pageLocker.Visible and previewModel) then
		return
	end
	previewAngle += dt * 0.6
	local radius = 12
	local pos = Vector3.new(math.sin(previewAngle) * radius, 1.5, math.cos(previewAngle) * radius)
	viewportCamera.CFrame = CFrame.lookAt(pos, Vector3.new(0, 0, -0.9))
end)

---------------------------------------------------------------------------
-- Onglet Sachets (tirage d'une fleur)
---------------------------------------------------------------------------
local packList = make("Frame", { Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(470, 400), BackgroundTransparency = 1 }, pagePacks)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }, packList)

local reveal = make("Frame", { Position = UDim2.fromOffset(500, 0), Size = UDim2.new(1, -516, 1, -12), BackgroundColor3 = Color3.fromRGB(25, 35, 22) }, pagePacks)
corner(reveal, 12)
local revealStroke = make("UIStroke", { Color = Color3.fromRGB(110, 150, 90), Thickness = 2 }, reveal)
local revealViewport = make("ViewportFrame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 200), BackgroundTransparency = 1,
	Ambient = Color3.fromRGB(180, 180, 180), LightDirection = Vector3.new(-1, -1, -0.5) }, reveal)
local revealCamera = make("Camera", { FieldOfView = 30 }, revealViewport)
revealViewport.CurrentCamera = revealCamera
revealCamera.CFrame = CFrame.lookAt(Vector3.new(6, 0.2, -3.0), Vector3.new(0, 0.05, -3.0)) -- gros plan sur la fleur (vue de profil)
local revealName = label({ Position = UDim2.fromOffset(10, 216), Size = UDim2.new(1, -20, 0, 30), Text = "Ouvrez un sachet !" }, reveal)
local revealRarity = label({ Position = UDim2.fromOffset(10, 248), Size = UDim2.new(1, -20, 0, 24), Text = "" }, reveal)
local revealInfo = label({ Position = UDim2.fromOffset(10, 276), Size = UDim2.new(1, -20, 0, 40), Text = "", TextWrapped = true,
	TextColor3 = Color3.fromRGB(210, 230, 200) }, reveal)
local revealModel = nil
local rolling = false

local function showFlower(flowerId)
	if revealModel then
		revealModel:Destroy()
	end
	local look = table.clone(profile.Equipped)
	look.FlowerSkin = flowerId
	revealModel = WeaponFactory.CreatePreview(look)
	revealModel.Parent = revealViewport
	local flower = Cosmetics.Get("FlowerSkin", flowerId)
	local rarity = Cosmetics.Rarities[flower.Rarity] or Cosmetics.Rarities.Commune
	revealName.Text = string.format("#%d %s", flower.Number or 0, flower.Name)
	revealRarity.Text = rarity.Label
	revealRarity.TextColor3 = rarity.Color
	revealStroke.Color = rarity.Color
end

local function oddsText(pack)
	local lines = {}
	for _, rarityName in Cosmetics.RarityOrder do
		local pct = pack.Odds[rarityName]
		if pct then
			table.insert(lines, string.format("%s : %s %%", Cosmetics.Rarities[rarityName].Label, tostring(pct)))
		end
	end
	return table.concat(lines, "\n")
end

renderPacks = function()
	clear(packList)
	for _, pack in Cosmetics.Packs do
		local stock = (profile.Packs and profile.Packs[pack.Id]) or 0
		local card = make("Frame", { Size = UDim2.fromOffset(230, 395), BackgroundColor3 = Color3.fromRGB(45, 65, 40) }, packList)
		corner(card, 12)
		make("UIStroke", { Color = pack.Color, Thickness = 2 }, card)
		label({ Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 28), Text = pack.Name, TextColor3 = pack.Color }, card)
		label({ Position = UDim2.fromOffset(8, 40), Size = UDim2.new(1, -16, 0, 20),
			Text = string.format("En stock : %d   •   Prix : 🌱 %d", stock, pack.Price) }, card)
		local odds = label({ Position = UDim2.fromOffset(12, 66), Size = UDim2.new(1, -24, 0, 175), Text = "Probabilités :\n" .. oddsText(pack),
			TextScaled = false, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = Color3.fromRGB(215, 230, 205) }, card)
		odds.TextWrapped = true

		-- Achat en Robux (Developer Products)
		local products = {}
		for _, product in Config.Shop.Products do
			if product.PackId == pack.Id then
				table.insert(products, product)
			end
		end
		if profile.PaidRandomRestricted then
			label({ Position = UDim2.fromOffset(10, 250), Size = UDim2.new(1, -20, 0, 34), Text = "Achat en Robux indisponible dans votre pays",
				TextWrapped = true, TextColor3 = Color3.fromRGB(220, 200, 180) }, card)
		elseif #products > 0 then
			label({ Position = UDim2.fromOffset(10, 246), Size = UDim2.new(1, -20, 0, 18), Text = "Acheter avec des Robux :", TextColor3 = GOLD }, card)
			local width = math.floor((210 - 6 * (#products - 1)) / #products)
			for i, product in products do
				local price = productPrices[product.Key]
				local buy = button({ Position = UDim2.fromOffset(10 + (i - 1) * (width + 6), 268), Size = UDim2.fromOffset(width, 50),
					Text = string.format("%s\n%s", product.Label, if price then "R$ " .. price elseif product.ProductId == 0 then "R$ (test)" else "R$ …"),
					BackgroundColor3 = Color3.fromRGB(0, 140, 70) }, card)
				make("UIStroke", { Color = GOLD, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, buy)
				buy.Activated:Connect(function()
					remotes.BuyProduct:FireServer(product.Key)
				end)
			end
		end
		local canOpen = stock > 0 or (profile.SeedBalance or 0) >= pack.Price
		local open = button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(1, -20, 0, 46),
			Text = if stock > 0 then "Ouvrir (en stock)" else string.format("Ouvrir — 🌱 %d", pack.Price),
			BackgroundColor3 = if canOpen then Color3.fromRGB(80, 150, 60) else Color3.fromRGB(80, 80, 80), AutoButtonColor = canOpen }, card)
		open.Activated:Connect(function()
			if canOpen and not rolling then
				rolling = true
				revealInfo.Text = "Ouverture…"
				remotes.OpenPack:FireServer(pack.Id)
				task.delay(5, function()
					rolling = false -- sécurité si le serveur ne répond pas
				end)
			end
		end)
	end
end

remotes:WaitForChild("PackResult").OnClientEvent:Connect(function(result)
	if result.Error then
		rolling = false
		revealInfo.Text = result.Error
		return
	end
	-- petite animation : défilement de fleurs avant la vraie
	local pool = Cosmetics.List("FlowerSkin")
	for i = 1, 14 do
		showFlower(pool[math.random(1, #pool)].Id)
		task.wait(0.05 + i * 0.012)
	end
	showFlower(result.FlowerId)
	revealInfo.Text = if result.Duplicate then string.format("Doublon : +%d graines remboursées", result.Refund) else "Nouvelle fleur ajoutée au casier !"
	rolling = false
	if pagePacks.Visible then
		renderPacks()
	end
end)

---------------------------------------------------------------------------
-- Navigation
---------------------------------------------------------------------------
local renderPacks -- défini plus bas
local currentTab = "Pass"

local function showTab(name)
	currentTab = name
	pagePass.Visible = name == "Pass"
	pagePacks.Visible = name == "Packs"
	pageLocker.Visible = name == "Locker"
	for tabName, b in { Pass = tabPass, Packs = tabPacks, Locker = tabLocker } do
		b.BackgroundColor3 = if name == tabName then Color3.fromRGB(110, 170, 80) else Color3.fromRGB(70, 100, 55)
	end
	if name == "Pass" then
		renderPass()
	elseif name == "Packs" then
		renderPacks()
	else
		renderLocker()
	end
end

local function toggle(open)
	window.Visible = if open == nil then not window.Visible else open
	if window.Visible then
		showTab(currentTab)
	end
end

openButton.Activated:Connect(function()
	toggle()
end)
closeButton.Activated:Connect(function()
	toggle(false)
end)
tabPass.Activated:Connect(function()
	showTab("Pass")
end)
tabPacks.Activated:Connect(function()
	showTab("Packs")
end)
tabLocker.Activated:Connect(function()
	showTab("Locker")
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.B then
		toggle()
	end
end)

---------------------------------------------------------------------------
-- Notifications : graines gagnées, nouvelles récompenses
---------------------------------------------------------------------------
local toastHolder = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -190), Size = UDim2.fromOffset(380, 300),
	BackgroundTransparency = 1 }, gui)
make("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, toastHolder)
local toastOrder = 0

local function toast(lines, accent, duration)
	toastOrder += 1
	local frame = make("Frame", { Size = UDim2.new(1, 0, 0, 16 + #lines * 24), BackgroundColor3 = PANEL, BackgroundTransparency = 0.1, LayoutOrder = toastOrder }, toastHolder)
	corner(frame, 10)
	make("UIStroke", { Color = accent, Thickness = 2 }, frame)
	for i, text in lines do
		label({ Position = UDim2.fromOffset(10, 8 + (i - 1) * 24), Size = UDim2.new(1, -20, 0, if i == 1 then 24 else 20), Text = text,
			TextColor3 = if i == 1 then accent else Color3.new(1, 1, 1) }, frame)
	end
	task.delay(duration or 7, function()
		if frame.Parent then
			TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			task.wait(0.4)
			frame:Destroy()
		end
	end)
end

remotes:WaitForChild("SeedsAwarded").OnClientEvent:Connect(function(data)
	local lines = { string.format("+%d graines 🌱  %s", data.Amount, if data.Won then "(Victoire !)" else "") }
	for _, line in data.Lines or {} do
		table.insert(lines, string.format("%s : %s%d", line.Label, if line.Amount >= 0 then "+" else "", line.Amount))
	end
	if data.TierAfter > data.TierBefore then
		table.insert(lines, string.format("Palier %d atteint ! Ouvrez le Pass (B)", data.TierAfter))
	end
	toast(lines, Color3.fromRGB(150, 240, 110), 9)
end)

remotes:WaitForChild("Unlocked").OnClientEvent:Connect(function(items, message)
	if message then
		toast({ message }, GOLD, 6)
	end
	for _, item in items or {} do
		local rarity = Cosmetics.Rarities[item.Rarity] or Cosmetics.Rarities.Commune
		toast({ "Nouvelle récompense !", string.format("%s : %s (%s)", Cosmetics.TypeLabels[item.Type] or "", item.Name, rarity.Label) }, rarity.Color, 8)
	end
end)

remotes:WaitForChild("Profile").OnClientEvent:Connect(function(data)
	profile = data
	table.clear(ownedSet)
	for _, key in data.Owned or {} do
		ownedSet[key] = true
	end
	title.Text = BP.SeasonName .. (if data.Saved == false then "  (non sauvegardé)" else "")
	renderPass()
	if window.Visible and pageLocker.Visible then
		renderLocker()
	elseif window.Visible and pagePacks.Visible then
		renderPacks()
	end
end)

task.spawn(function()
	for _, product in Config.Shop.Products do
		if product.ProductId ~= 0 then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(product.ProductId, Enum.InfoType.Product)
			end)
			if ok and info and info.PriceInRobux then
				productPrices[product.Key] = info.PriceInRobux
			end
		end
	end
	if window.Visible and pagePacks.Visible then
		renderPacks()
	end
end)

task.spawn(function()
	if BP.GamePassId and BP.GamePassId > 0 then
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(BP.GamePassId, Enum.InfoType.GamePass)
		end)
		if ok and info and info.PriceInRobux then
			premiumPrice = info.PriceInRobux
			renderPass()
		end
	end
end)

renderPass()
