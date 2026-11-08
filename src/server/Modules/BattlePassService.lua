--[[
	La fleur au fusil — Pass de saison, graines, casier (ModuleScript serveur)
	Emplacement : ServerScriptService > FleurServer > Modules > BattlePassService

	* Profil sauvegardé en DataStore : graines de la saison, objets possédés,
	  tenue équipée.
	* Les graines (gagnées en fin de partie selon les stats) font monter les
	  paliers : récompenses gratuites pour tous, premium si le joueur possède
	  le Game Pass (rétroactif si acheté en cours de saison).
	* Équipement des cosmétiques (vérifié : seulement les objets possédés).
	Sans accès DataStore (Studio sans « Enable Studio Access to API Services »),
	le profil fonctionne pour la session mais n'est pas sauvegardé.
]]

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
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
		Seeds = 0, -- graines de la saison en cours (progression du pass)
		TotalSeeds = 0, -- toutes saisons confondues
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
	end
	return profile
end

local function keyFor(player)
	return "Joueur_" .. player.UserId
end

local function save(player)
	local profile = profiles[player]
	if not store or not profile or not canSave[player] then
		return
	end
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function()
			return profile
		end)
	end)
	if not ok then
		warn("[FleurPass] Sauvegarde échouée pour " .. player.Name .. " : " .. tostring(err))
	end
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
		if reward and Cosmetics.Exists(reward.Type, reward.Id) then
			local key = Cosmetics.Key(reward.Type, reward.Id)
			if not profile.Owned[key] then
				profile.Owned[key] = true
				local item = Cosmetics.Get(reward.Type, reward.Id)
				table.insert(newItems, { Type = reward.Type, Id = reward.Id, Name = item.Name, Rarity = item.Rarity })
			end
		end
	end
	for _, tier in BP.Tiers do
		if profile.Seeds >= tier.Seeds then
			give(tier.Free)
			if premium[player] then
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
		Premium = premium[player] == true,
		Owned = owned,
		Equipped = profile.Equipped,
		Saved = store ~= nil and canSave[player] == true,
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
