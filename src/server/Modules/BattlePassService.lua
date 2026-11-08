--[[
	La fleur au fusil — Pass de saison, graines, casier (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > BattlePassService

	* Profil sauvegardé en DataStore : graines de la saison, objets possédés,
	  tenue équipée.
	* Les graines (gagnées en fin de partie selon les stats) font monter les
	  paliers : récompenses gratuites pour tous, premium si le joueur possède
	  le Game Pass (rétroactif si acheté en cours de saison).
	* Sachets de graines : tirage d'une fleur selon les probabilités de
	  Cosmetics.Packs ; payés avec le solde de graines ou donnés par le pass.
	  Doublon = remboursement en graines.
	* Boutique Robux : sachets vendus en Developer Products (ProcessReceipt,
	  reçus mémorisés pour ne jamais créditer deux fois, sauvegarde immédiate).
	  Bloquée pour les joueurs dont le pays interdit les objets aléatoires
	  payants (PolicyService.ArePaidRandomItemsRestricted).
	* Équipement des cosmétiques (vérifié : seulement les objets possédés).
	Sans accès DataStore (Studio sans « Enable Studio Access to API Services »),
	le profil fonctionne pour la session mais n'est pas sauvegardé.
]]

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("FleurShared")
local Config = require(Shared:WaitForChild("Config"))
local Cosmetics = require(Shared:WaitForChild("Cosmetics"))

local BattlePassService = {}

local BP = Config.BattlePass
local STORE_NAME = "FleurAuFusil_Profils_v1"

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[FleurPass] DataStore indisponible, progression non sauvegardée : " .. tostring(result))
	end
end

local remotes
local onLookChanged
local profiles = {} -- [Player] = profil
local premium = {} -- [Player] = bool
local canSave = {} -- [Player] = bool (faux si le chargement a échoué : on n'écrase pas les données)
local randomRestricted = {} -- [Player] = bool (objets aléatoires payants interdits)

---------------------------------------------------------------------------
-- Profil
---------------------------------------------------------------------------
local function defaultProfile()
	local owned = {}
	for typeName, id in Cosmetics.Defaults do
		owned[Cosmetics.Key(typeName, id)] = true
	end
	return {
		Version = 1,
		Season = BP.Season,
		Seeds = 0, -- graines de la saison en cours (progression du pass, jamais dépensées)
		TotalSeeds = 0, -- toutes saisons confondues
		SeedBalance = 0, -- solde dépensable (sachets)
		Packs = {}, -- [PackId] = nombre de sachets non ouverts
		Claimed = {}, -- paliers déjà récompensés cette saison ("F3", "P3"…)
		Receipts = {}, -- derniers achats Robux traités (PurchaseId)
		Owned = owned,
		Equipped = Cosmetics.DefaultLook(),
	}
end

local function reconcile(data)
	local profile = defaultProfile()
	if type(data) ~= "table" then
		return profile
	end
	profile.Seeds = tonumber(data.Seeds) or 0
	profile.TotalSeeds = tonumber(data.TotalSeeds) or profile.Seeds
	profile.Season = tonumber(data.Season) or BP.Season
	profile.SeedBalance = tonumber(data.SeedBalance) or 0
	if type(data.Packs) == "table" then
		for id, n in data.Packs do
			if Cosmetics.GetPack(id) and tonumber(n) then
				profile.Packs[id] = math.max(0, math.floor(tonumber(n)))
			end
		end
	end
	if type(data.Receipts) == "table" then
		for _, id in data.Receipts do
			if type(id) == "string" then
				table.insert(profile.Receipts, id)
			end
		end
	end
	if type(data.Claimed) == "table" then
		for key, v in data.Claimed do
			if v then
				profile.Claimed[key] = true
			end
		end
	end
	if type(data.Owned) == "table" then
		for key, v in data.Owned do
			if v then
				profile.Owned[key] = true
			end
		end
	end
	if type(data.Equipped) == "table" then
		for _, typeName in Cosmetics.Types do
			local id = data.Equipped[typeName]
			if type(id) == "string" and Cosmetics.Exists(typeName, id) and profile.Owned[Cosmetics.Key(typeName, id)] then
				profile.Equipped[typeName] = id
			end
		end
	end
	if profile.Season ~= BP.Season then -- nouvelle saison : progression remise à zéro
		profile.Season = BP.Season
		profile.Seeds = 0
		profile.Claimed = {}
	end
	return profile
end

local function keyFor(player)
	return "Joueur_" .. player.UserId
end

-- Renvoie true si la sauvegarde a réussi
local function save(player)
	local profile = profiles[player]
	if not store or not profile or not canSave[player] then
		return false
	end
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function()
			return profile
		end)
	end)
	if not ok then
		warn("[FleurPass] Sauvegarde échouée pour " .. player.Name .. " : " .. tostring(err))
	end
	return ok
end

---------------------------------------------------------------------------
-- Pass & récompenses
---------------------------------------------------------------------------
function BattlePassService.HasPremium(player)
	return premium[player] == true
end

-- Palier atteint (0 si aucun) pour un nombre de graines
function BattlePassService.GetTierIndex(seeds)
	local reached = 0
	for i, tier in BP.Tiers do
		if seeds >= tier.Seeds then
			reached = i
		end
	end
	return reached
end

-- Donne toutes les récompenses des paliers atteints. Renvoie les nouveaux objets.
local function grantRewards(player)
	local profile = profiles[player]
	if not profile then
		return {}
	end
	local newItems = {}
	local function give(reward)
		if not reward then
			return
		end
		if reward.Type == "Pack" then
			local pack = Cosmetics.GetPack(reward.Id)
			if pack then
				local count = reward.Count or 1
				profile.Packs[pack.Id] = (profile.Packs[pack.Id] or 0) + count
				table.insert(newItems, { Type = "Pack", Id = pack.Id, Name = string.format("%s ×%d", pack.Name, count), Rarity = "Rare" })
			end
		elseif Cosmetics.Exists(reward.Type, reward.Id) then
			local key = Cosmetics.Key(reward.Type, reward.Id)
			if not profile.Owned[key] then
				profile.Owned[key] = true
				local item = Cosmetics.Get(reward.Type, reward.Id)
				table.insert(newItems, { Type = reward.Type, Id = reward.Id, Name = item.Name, Rarity = item.Rarity })
			end
		end
	end
	for i, tier in BP.Tiers do
		if profile.Seeds >= tier.Seeds then
			if not profile.Claimed["F" .. i] then
				profile.Claimed["F" .. i] = true
				give(tier.Free)
			end
			if premium[player] and not profile.Claimed["P" .. i] then
				profile.Claimed["P" .. i] = true
				give(tier.Premium)
			end
		end
	end
	return newItems
end

local function sendProfile(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local owned = {}
	for key in profile.Owned do
		table.insert(owned, key)
	end
	remotes.Profile:FireClient(player, {
		Seeds = profile.Seeds,
		TotalSeeds = profile.TotalSeeds,
		Season = profile.Season,
		SeedBalance = profile.SeedBalance,
		Packs = profile.Packs,
		Premium = premium[player] == true,
		Owned = owned,
		Equipped = profile.Equipped,
		Saved = store ~= nil and canSave[player] == true,
		PaidRandomRestricted = randomRestricted[player] == true,
	})
end

local function notifyUnlocks(player, items)
	if #items > 0 then
		remotes.Unlocked:FireClient(player, items)
	end
end

function BattlePassService.GetLook(player)
	local profile = profiles[player]
	return if profile then table.clone(profile.Equipped) else Cosmetics.DefaultLook()
end

-- Ajoute des graines (fin de partie). breakdown = lignes de détail pour l'interface.
function BattlePassService.AwardSeeds(player, amount, breakdown, context)
	local profile = profiles[player]
	if not profile then
		return
	end
	local before = BattlePassService.GetTierIndex(profile.Seeds)
	profile.Seeds += amount
	profile.TotalSeeds += amount
	profile.SeedBalance += amount
	local after = BattlePassService.GetTierIndex(profile.Seeds)
	local items = grantRewards(player)
	remotes.SeedsAwarded:FireClient(player, {
		Amount = amount,
		Lines = breakdown,
		Total = profile.Seeds,
		TierBefore = before,
		TierAfter = after,
		Won = context and context.Won or false,
	})
	notifyUnlocks(player, items)
	sendProfile(player)
end

local function setPremium(player, value, reason)
	if premium[player] == value then
		return
	end
	premium[player] = value
	if value then
		local items = grantRewards(player)
		remotes.Unlocked:FireClient(player, items, reason or "Pass Premium débloqué !")
	end
	sendProfile(player)
end

---------------------------------------------------------------------------
-- Joueurs
---------------------------------------------------------------------------
local function loadPlayer(player)
	local data, ok = nil, true
	if store then
		for attempt = 1, 3 do
			ok = pcall(function()
				data = store:GetAsync(keyFor(player))
			end)
			if ok then
				break
			end
			task.wait(attempt)
		end
	end
	if not player.Parent then
		return
	end
	profiles[player] = reconcile(data)
	canSave[player] = ok
	if not ok then
		warn("[FleurPass] Chargement impossible pour " .. player.Name .. " : la session ne sera pas sauvegardée.")
	end

	if BP.GamePassId and BP.GamePassId > 0 then
		local owns = false
		pcall(function()
			owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, BP.GamePassId)
		end)
		premium[player] = owns
	end
	local okPolicy, policy = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	-- en cas d'erreur on bloque par prudence (sauf dans Studio)
	randomRestricted[player] = if okPolicy and policy then policy.ArePaidRandomItemsRestricted == true else not RunService:IsStudio()
	grantRewards(player) -- au cas où les paliers ont changé
	sendProfile(player)
	if onLookChanged then
		onLookChanged(player, BattlePassService.GetLook(player))
	end
end

function BattlePassService.Init(remoteTable, lookChangedCallback)
	remotes = remoteTable
	onLookChanged = lookChangedCallback

	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		premium[player] = nil
		canSave[player] = nil
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
		task.wait(if RunService:IsStudio() then 1 else 5)
	end)

	task.spawn(function()
		while true do
			task.wait(120) -- sauvegarde automatique
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)

	-- Équiper un objet du casier
	remotes.EquipCosmetic.OnServerEvent:Connect(function(player, typeName, id)
		local profile = profiles[player]
		if not profile or type(typeName) ~= "string" or type(id) ~= "string" then
			return
		end
		if not Cosmetics.Exists(typeName, id) or not profile.Owned[Cosmetics.Key(typeName, id)] then
			return
		end
		profile.Equipped[typeName] = id
		sendProfile(player)
		if onLookChanged then
			onLookChanged(player, BattlePassService.GetLook(player))
		end
	end)

	-- Ouvrir un sachet : utilise un sachet en stock, sinon paie avec le solde de graines
	local lastOpen = {}
	local rng = Random.new()
	remotes.OpenPack.OnServerEvent:Connect(function(player, packId)
		local profile = profiles[player]
		local pack = type(packId) == "string" and Cosmetics.GetPack(packId)
		if not profile or not pack then
			return
		end
		local now = os.clock()
		if lastOpen[player] and now - lastOpen[player] < 1 then
			return -- anti-spam
		end
		local fromStock = (profile.Packs[pack.Id] or 0) > 0
		if fromStock then
			profile.Packs[pack.Id] -= 1
		elseif profile.SeedBalance >= pack.Price then
			profile.SeedBalance -= pack.Price
		else
			remotes.PackResult:FireClient(player, { Error = "Pas assez de graines !" })
			return
		end
		lastOpen[player] = now

		local flower = Cosmetics.RollPack(pack, rng)
		local key = Cosmetics.Key("FlowerSkin", flower.Id)
		local duplicate = profile.Owned[key] == true
		local refund = 0
		if duplicate then
			refund = (Cosmetics.Rarities[flower.Rarity] or Cosmetics.Rarities.Commune).Refund
			profile.SeedBalance += refund
		else
			profile.Owned[key] = true
		end
		remotes.PackResult:FireClient(player, {
			PackId = pack.Id,
			FlowerId = flower.Id,
			Duplicate = duplicate,
			Refund = refund,
		})
		sendProfile(player)
		local rarity = Cosmetics.Rarities[flower.Rarity]
		if rarity and rarity.Order >= 6 then -- Mythique et plus : annonce à tout le serveur
			remotes.Unlocked:FireAllClients({}, string.format("🌸 %s a obtenu %s (%s) !", player.DisplayName, flower.Name, rarity.Label))
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastOpen[player] = nil
		randomRestricted[player] = nil
	end)

	-----------------------------------------------------------------------
	-- Boutique Robux : sachets (Developer Products)
	-----------------------------------------------------------------------
	local function grantProduct(player, product)
		local profile = profiles[player]
		profile.Packs[product.PackId] = (profile.Packs[product.PackId] or 0) + product.Count
		local pack = Cosmetics.GetPack(product.PackId)
		remotes.Unlocked:FireClient(player, {}, string.format("Merci ! %s ×%d ajouté(s) 🌸", pack.Name, product.Count))
		sendProfile(player)
	end

	remotes.BuyProduct.OnServerEvent:Connect(function(player, key)
		local product = type(key) == "string" and Config.GetProduct(key)
		if not product or not profiles[player] then
			return
		end
		if randomRestricted[player] then
			remotes.Unlocked:FireClient(player, {}, "Les sachets payants ne sont pas disponibles dans votre pays.")
			return
		end
		if product.ProductId ~= 0 then
			MarketplaceService:PromptProductPurchase(player, product.ProductId)
		elseif RunService:IsStudio() and Config.Shop.StudioFreeProducts then
			grantProduct(player, product) -- achat simulé (test Studio)
		else
			remotes.Unlocked:FireClient(player, {}, "Produit indisponible : ProductId non configuré.")
		end
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local product = Config.GetProductById(receipt.ProductId)
		if not product then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- produit inconnu de ce serveur
		end
		local profile = player and profiles[player]
		if not profile then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox réessaiera au prochain passage
		end
		if table.find(profile.Receipts, receipt.PurchaseId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- déjà crédité
		end
		if store and not canSave[player] then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- profil non fiable : on ne crédite pas
		end

		table.insert(profile.Receipts, receipt.PurchaseId)
		while #profile.Receipts > 50 do
			table.remove(profile.Receipts, 1)
		end
		profile.Packs[product.PackId] = (profile.Packs[product.PackId] or 0) + product.Count

		if store and not save(player) then
			-- échec de sauvegarde : on annule, Roblox renverra le reçu plus tard
			profile.Packs[product.PackId] -= product.Count
			table.remove(profile.Receipts, table.find(profile.Receipts, receipt.PurchaseId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local pack = Cosmetics.GetPack(product.PackId)
		remotes.Unlocked:FireClient(player, {}, string.format("Merci ! %s ×%d ajouté(s) 🌸", pack.Name, product.Count))
		sendProfile(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Achat du pass premium
	remotes.BuyPremium.OnServerEvent:Connect(function(player)
		if premium[player] then
			return
		end
		if BP.GamePassId and BP.GamePassId > 0 then
			MarketplaceService:PromptGamePassPurchase(player, BP.GamePassId)
		elseif RunService:IsStudio() and BP.StudioFreePremium then
			setPremium(player, true, "Pass Premium débloqué (mode test Studio)")
		else
			remotes.Unlocked:FireClient(player, {}, "Pass Premium indisponible : GamePassId non configuré.")
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if purchased and gamePassId == BP.GamePassId then
			setPremium(player, true, "Merci ! Pass Premium débloqué 🌸")
		end
	end)
end

return BattlePassService
