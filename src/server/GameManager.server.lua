--[[
	La fleur au fusil — GameManager (Script serveur principal)
	Emplacement : ServerScriptService > FleurServer > GameManager

	Responsabilités :
	  * crée les RemoteEvents, les équipes, génère le potager ;
	  * gère joueurs, personnages, armes et bots de remplissage ;
	  * enchaîne les parties : Match à mort par équipe → Chacun pour soi →
	    Gun Game (premier à 200 touches), chacune en une ou plusieurs manches ;
	  * calcule les vainqueurs et les scores finaux (touches / pénalités / ratio).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))
local Modules = script.Parent:WaitForChild("Modules")
local MapBuilder = require(Modules:WaitForChild("MapBuilder"))
local ParticipantService = require(Modules:WaitForChild("ParticipantService"))
local CombatService = require(Modules:WaitForChild("CombatService"))
local WeaponFactory = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("WeaponFactory"))
local BattlePassService = require(Modules:WaitForChild("BattlePassService"))
local BotService = require(Modules:WaitForChild("BotService"))

local PS = ParticipantService

---------------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------------
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = Config.RemotesFolderName

local remotes = {}
for _, name in { "FireRequest", "PetalFired", "HitConfirm", "HitTaken", "KillFeed", "GameState", "Scoreboard", "Announce", "MatchResults", "MapVote", "Profile", "Unlocked", "SeedsAwarded", "EquipCosmetic", "BuyPremium", "OpenPack", "PackResult" } do
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	remotes[name] = r
end
remotes.GetState = Instance.new("RemoteFunction")
remotes.GetState.Name = "GetState"
remotes.GetState.Parent = remotesFolder
remotesFolder.Parent = ReplicatedStorage

---------------------------------------------------------------------------
-- Équipes & carte
---------------------------------------------------------------------------
local teamObjects = {}
for _, t in Config.Teams do
	local team = Teams:FindFirstChild(t.Name) or Instance.new("Team")
	team.Name = t.Name
	team.TeamColor = t.BrickColor
	team.AutoAssignable = false
	team.Parent = Teams
	teamObjects[t.Name] = team
end

MapBuilder.Build(Config.MapSelection.StartMap)
Players.RespawnTime = Config.Combat.RespawnTime

---------------------------------------------------------------------------
-- État de la partie (répliqué aux clients)
---------------------------------------------------------------------------
local currentMode = Config.Modes[Config.ModeRotation[1]]
local state = {
	Phase = "Waiting", -- Waiting | Intermission | Round | RoundEnd | MatchEnd
	ModeKey = "",
	ModeName = "",
	Objective = "",
	Teams = false,
	Round = 0,
	Rounds = 0,
	Target = 0,
	EndsAt = 0, -- workspace:GetServerTimeNow() de fin de phase
	TeamRoundHits = {},
	RoundsWon = {}, -- [clé] = { Label = ..., Wins = n }
	MapId = MapBuilder.GetCurrentMapId(),
	MapName = "",
	MapOptions = nil, -- { {Id, Name, Description}, ... } pendant le vote
	MapVotes = {}, -- [MapId] = nombre de voix
}
local mapInfo = Config.GetMap(state.MapId)
state.MapName = if mapInfo then mapInfo.Name else "Potager personnalisé"
local playerVotes = {} -- [Player] = MapId
local roundWinner = nil -- { Key, Label }

local function broadcastState()
	remotes.GameState:FireAllClients(state)
end

local function setPhase(phase, duration)
	state.Phase = phase
	state.EndsAt = workspace:GetServerTimeNow() + (duration or 0)
	broadcastState()
end

local function announce(text, duration)
	remotes.Announce:FireAllClients(text, duration or 3)
end

remotes.GetState.OnServerInvoke = function()
	return state, PS.Snapshot()
end

-- Tableau des scores, envoyé au plus 2 fois par seconde
local scoreboardDirty = true
PS.OnChanged(function()
	scoreboardDirty = true
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		if scoreboardDirty then
			scoreboardDirty = false
			remotes.Scoreboard:FireAllClients(PS.Snapshot(), state.TeamRoundHits)
		end
	end
end)

---------------------------------------------------------------------------
-- Équipes
---------------------------------------------------------------------------
local function isEnemy(a, b)
	if currentMode.Teams then
		return a.Team ~= b.Team
	end
	return true
end

local function teamCount(teamName)
	local n = 0
	for _, p in PS.All() do
		if p.Team == teamName then
			n += 1
		end
	end
	return n
end

local function smallestTeam()
	local a, b = Config.Teams[1].Name, Config.Teams[2].Name
	return if teamCount(a) <= teamCount(b) then a else b
end

local function addTeamMarker(model, teamName)
	local old = model:FindFirstChild("FleurBrassard")
	if old then
		old:Destroy()
	end
	if not teamName then
		return
	end
	local arm = model:FindFirstChild("LeftUpperArm") or model:FindFirstChild("Left Arm") or model:FindFirstChild("UpperTorso")
	if not arm then
		return
	end
	local band = Instance.new("Part")
	band.Name = "FleurBrassard"
	band.Size = arm.Size * Vector3.new(1.15, 0.35, 1.15)
	band.CFrame = arm.CFrame
	band.Color = teamObjects[teamName].TeamColor.Color
	band.Material = Enum.Material.Neon
	band.CanCollide = false
	band.CanQuery = false
	band.CanTouch = false
	band.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = band
	weld.Parent = band
	band.Parent = model
end

local function applyTeam(p, teamName)
	p.Team = teamName
	if p.Player then
		if teamName then
			p.Player.Team = teamObjects[teamName]
			p.Player.Neutral = false
		else
			p.Player.Team = nil
			p.Player.Neutral = true
		end
		if p.Model then
			addTeamMarker(p.Model, teamName)
		end
	else
		BotService.RefreshAppearance(p)
	end
end

local function assignAllTeams()
	if not currentMode.Teams then
		for _, p in PS.All() do
			applyTeam(p, nil)
		end
		return
	end
	-- humains d'abord (mélangés), puis bots, en alternance : équipes équilibrées
	local humans = PS.Humans()
	for i = #humans, 2, -1 do
		local j = math.random(1, i)
		humans[i], humans[j] = humans[j], humans[i]
	end
	local i = 0
	for _, list in { humans, PS.Bots() } do
		for _, p in list do
			applyTeam(p, Config.Teams[i % 2 + 1].Name)
			i += 1
		end
	end
end

---------------------------------------------------------------------------
-- Paliers d'arme (Gun Game)
---------------------------------------------------------------------------
local function setTier(p, tier)
	if p.Tier == tier then
		return
	end
	p.Tier = tier
	PS.Sync(p)
	if p.IsBot then
		BotService.UpdateTier(p)
	elseif p.Player then
		local tool = (p.Model and p.Model:FindFirstChild(Config.ToolName)) or p.Player.Backpack:FindFirstChild(Config.ToolName)
		if tool then
			WeaponFactory.SetTier(tool, tier, p.Look)
		end
	end
end

---------------------------------------------------------------------------
-- Bots de remplissage
---------------------------------------------------------------------------
local function desiredBotCount()
	if not Config.Bots.Enabled then
		return 0
	end
	return math.clamp(Config.Bots.FillTo - #Players:GetPlayers(), 0, Config.Bots.MaxBots)
end

local function rebalanceBots()
	local desired = desiredBotCount()
	local bots = PS.Bots()
	while #bots > desired do
		-- retirer un bot de l'équipe la plus nombreuse
		local victim = bots[#bots]
		if currentMode.Teams then
			local a, b = Config.Teams[1].Name, Config.Teams[2].Name
			local bigger = if teamCount(a) > teamCount(b) then a else b
			for _, bot in bots do
				if bot.Team == bigger then
					victim = bot
				end
			end
		end
		BotService.RemoveBot(victim)
		bots = PS.Bots()
	end
	while #bots < desired do
		BotService.AddBot()
		bots = PS.Bots()
	end
end

BotService.Init(PS, CombatService, {
	Map = MapBuilder,
	IsEnemy = isEnemy,
	OnCreated = function(p)
		p.Team = if currentMode.Teams then smallestTeam() else nil
	end,
	OnSpawned = function(p)
		if p.Model then
			addTeamMarker(p.Model, if currentMode.Teams then p.Team else nil)
		end
	end,
})

---------------------------------------------------------------------------
-- Joueurs
---------------------------------------------------------------------------
local function onCharacterAdded(player, character)
	local p = PS.GetByPlayer(player)
	if not p then
		return
	end
	character:SetAttribute("FleurId", p.Id)
	character:SetAttribute("FleurTier", p.Tier)
	p.Model = character

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.MaxHealth = Config.Combat.MaxHealth
	humanoid.Health = Config.Combat.MaxHealth
	if Config.Map.CharacterScale ~= 1 then
		pcall(function()
			character:ScaleTo(Config.Map.CharacterScale)
		end)
	end
	p.Alive = true
	humanoid.Died:Connect(function()
		if p.Model == character then
			p.Alive = false
		end
	end)

	-- arme : retire d'éventuels doublons puis équipe automatiquement
	for _, container in { player.Backpack, character } do
		local old = container:FindFirstChild(Config.ToolName)
		if old then
			old:Destroy()
		end
	end
	local tool = WeaponFactory.Create(p.Tier, p.Look)
	tool.Parent = player.Backpack
	task.defer(function()
		if humanoid.Health > 0 and tool.Parent == player.Backpack then
			humanoid:EquipTool(tool)
		end
	end)

	task.defer(addTeamMarker, character, if currentMode.Teams then p.Team else nil)
end

---------------------------------------------------------------------------
-- Cosmétiques (skins d'arme / fleur, animation des pétales)
---------------------------------------------------------------------------
local function applyLook(player, look)
	local p = PS.GetByPlayer(player)
	if not p then
		return -- le participant prendra la tenue chargée à sa création
	end
	p.Look = look
	player:SetAttribute("FleurWeaponSkin", look.WeaponSkin)
	player:SetAttribute("FleurFlower", look.FlowerSkin)
	player:SetAttribute("FleurEffect", look.PetalEffect)

	-- remplace l'arme actuelle par une arme au nouveau skin
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local equipped = character and character:FindFirstChild(Config.ToolName)
	local stored = player.Backpack:FindFirstChild(Config.ToolName)
	if not equipped and not stored then
		return
	end
	if equipped then
		equipped:Destroy()
	end
	if stored then
		stored:Destroy()
	end
	local tool = WeaponFactory.Create(p.Tier, look)
	tool.Parent = player.Backpack
	if equipped and humanoid and humanoid.Health > 0 then
		humanoid:EquipTool(tool)
	end
end

BattlePassService.Init(remotes, applyLook)

local function onPlayerAdded(player)
	local p = PS.AddPlayer(player)
	p.Look = BattlePassService.GetLook(player)
	player:SetAttribute("FleurWeaponSkin", p.Look.WeaponSkin)
	player:SetAttribute("FleurFlower", p.Look.FlowerSkin)
	player:SetAttribute("FleurEffect", p.Look.PetalEffect)
	applyTeam(p, if currentMode.Teams then smallestTeam() else nil)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	rebalanceBots()
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local p = PS.GetByPlayer(player)
	if p then
		PS.Remove(p.Id)
	end
	task.defer(rebalanceBots)
end)

---------------------------------------------------------------------------
-- Vote de carte
---------------------------------------------------------------------------
local function recountVotes()
	local counts = {}
	for player, mapId in playerVotes do
		if player.Parent then
			counts[mapId] = (counts[mapId] or 0) + 1
		end
	end
	state.MapVotes = counts
end

remotes.MapVote.OnServerEvent:Connect(function(player, mapId)
	if state.Phase ~= "Intermission" or not state.MapOptions or typeof(mapId) ~= "string" then
		return
	end
	for _, option in state.MapOptions do
		if option.Id == mapId then
			playerVotes[player] = mapId
			recountVotes()
			broadcastState()
			return
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerVotes[player] = nil
end)

local mapRotationIndex = 0

local function pickMapOptions()
	local pool = {}
	for _, m in Config.Maps do
		if m.Id ~= state.MapId then
			table.insert(pool, m)
		end
	end
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local options = {}
	for i = 1, math.min(Config.MapSelection.Choices, #pool) do
		local m = pool[i]
		table.insert(options, { Id = m.Id, Name = m.Name, Description = m.Description })
	end
	return options
end

local function chooseNextMap()
	local selection = Config.MapSelection.Mode
	if selection == "Rotation" then
		mapRotationIndex = mapRotationIndex % #Config.Maps + 1
		return Config.Maps[mapRotationIndex].Id
	elseif selection == "Random" or not state.MapOptions or #state.MapOptions == 0 then
		local pool = state.MapOptions or Config.Maps
		return pool[math.random(1, #pool)].Id
	end
	-- Vote : le plus de voix gagne, égalité tirée au sort
	local best, bestVotes = {}, -1
	for _, option in state.MapOptions do
		local v = state.MapVotes[option.Id] or 0
		if v > bestVotes then
			best, bestVotes = { option.Id }, v
		elseif v == bestVotes then
			table.insert(best, option.Id)
		end
	end
	return best[math.random(1, #best)]
end

local function loadMap(mapId)
	local loaded = MapBuilder.Build(mapId)
	MapBuilder.ConfigureSpawns(currentMode.Teams)
	local info = Config.GetMap(loaded)
	state.MapId = loaded
	state.MapName = if info then info.Name else "Potager personnalisé"
end

local function isFiniteVector(v)
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

remotes.FireRequest.OnServerEvent:Connect(function(player, origin, direction)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end
	if not isFiniteVector(origin) or not isFiniteVector(direction) then
		return
	end
	local p = PS.GetByPlayer(player)
	if p then
		CombatService.TryFire(p, origin, direction)
	end
end)

---------------------------------------------------------------------------
-- Touches : objectifs de manche et progression Gun Game
---------------------------------------------------------------------------
CombatService.OnHit(function(shooter, victim, eliminated)
	if state.Phase ~= "Round" then
		return
	end
	if currentMode.Teams and shooter.Team then
		state.TeamRoundHits[shooter.Team] = (state.TeamRoundHits[shooter.Team] or 0) + 1
		if not roundWinner and state.TeamRoundHits[shooter.Team] >= currentMode.TargetPerRound then
			roundWinner = { Key = shooter.Team, Label = "Les " .. shooter.Team }
		end
	elseif not roundWinner and shooter.RoundHits >= currentMode.TargetPerRound then
		roundWinner = { Key = shooter.Id, Label = shooter.Name }
	end

	if currentMode.TierEvery then
		local tier = math.min(#Config.WeaponTiers, math.floor(shooter.RoundHits / currentMode.TierEvery) + 1)
		if tier > shooter.Tier then
			setTier(shooter, tier)
			if shooter.Player then
				remotes.Announce:FireClient(shooter.Player, "Nouvelle fleur : " .. Config.GetTier(tier).Name .. " !", 2)
			end
		end
	end
	scoreboardDirty = true
end)

---------------------------------------------------------------------------
-- Déroulement des parties
---------------------------------------------------------------------------
local function respawnEveryone()
	CombatService.ClearProjectiles()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			player:LoadCharacter()
		end)
	end
	BotService.RespawnAll()
end

local function decideRoundByScore()
	if currentMode.Teams then
		local a, b = Config.Teams[1].Name, Config.Teams[2].Name
		local ha, hb = state.TeamRoundHits[a] or 0, state.TeamRoundHits[b] or 0
		if ha == hb then
			return nil
		end
		local w = if ha > hb then a else b
		return { Key = w, Label = "Les " .. w }
	end
	local best, bestHits, tie = nil, -1, false
	for _, p in PS.All() do
		if p.RoundHits > bestHits then
			best, bestHits, tie = p, p.RoundHits, false
		elseif p.RoundHits == bestHits then
			tie = true
		end
	end
	if not best or tie or bestHits <= 0 then
		return nil
	end
	return { Key = best.Id, Label = best.Name }
end

local function buildResults()
	local rows = PS.Snapshot()
	local results = { ModeName = currentMode.DisplayName, Rows = rows, TeamTotals = nil, WinnerLabel = "Égalité" }

	-- vainqueur de la partie : plus de manches gagnées, puis meilleur score
	local bestKey, bestWins = nil, 0
	local tie = false
	for key, info in state.RoundsWon do
		if info.Wins > bestWins then
			bestKey, bestWins, tie = key, info.Wins, false
		elseif info.Wins == bestWins then
			tie = true
		end
	end

	if currentMode.Teams then
		local totals = {}
		for _, t in Config.Teams do
			totals[t.Name] = { Hits = 0, Taken = 0, Score = 0 }
		end
		for _, r in rows do
			if r.Team and totals[r.Team] then
				totals[r.Team].Hits += r.Hits
				totals[r.Team].Taken += r.Taken
				totals[r.Team].Score += r.Score
			end
		end
		results.TeamTotals = totals
		if bestKey and not tie then
			results.WinnerLabel = state.RoundsWon[bestKey].Label
			results.WinnerKey = bestKey
		else
			local a, b = Config.Teams[1].Name, Config.Teams[2].Name
			if totals[a].Score ~= totals[b].Score then
				results.WinnerKey = if totals[a].Score > totals[b].Score then a else b
				results.WinnerLabel = "Les " .. results.WinnerKey
			end
		end
	else
		if bestKey and not tie then
			results.WinnerLabel = state.RoundsWon[bestKey].Label
			results.WinnerKey = bestKey
		elseif rows[1] then
			results.WinnerLabel = rows[1].Name
			results.WinnerKey = rows[1].Id
		end
	end
	results.MVP = rows[1] and rows[1].Name or "—"
	results.MVPId = rows[1] and rows[1].Id
	return results
end

-- Graines de fin de partie, selon les statistiques et la victoire
local function awardSeeds(results)
	for _, p in PS.Humans() do
		local player = p.Player
		if player and player.Parent then
			local final, ratio = Config.ComputeScore(p.Hits, p.Taken)
			local won = results.WinnerKey ~= nil
				and ((currentMode.Teams and p.Team == results.WinnerKey) or p.Id == results.WinnerKey)
			local amount, lines = Config.ComputeSeeds({
				Won = won,
				Hits = p.Hits,
				Taken = p.Taken,
				FinalScore = final,
				Ratio = ratio,
				IsMVP = results.MVPId == p.Id,
			}, BattlePassService.HasPremium(player))
			BattlePassService.AwardSeeds(player, amount, lines, { Won = won })
		end
	end
end

local function runMatch(modeKey)
	currentMode = Config.Modes[modeKey]
	state.ModeKey = modeKey
	state.ModeName = currentMode.DisplayName
	state.Teams = currentMode.Teams
	state.Rounds = currentMode.Rounds
	state.Round = 0
	state.Target = currentMode.TargetPerRound
	state.RoundsWon = {}
	state.TeamRoundHits = {}
	if currentMode.TierEvery then
		state.Objective = string.format(currentMode.Description, currentMode.TierEvery, currentMode.TargetPerRound)
	else
		state.Objective = string.format(currentMode.Description, currentMode.TargetPerRound)
	end

	CombatService.Enabled = false
	CombatService.TeamsEnabled = currentMode.Teams
	BotService.SetActive(false)
	MapBuilder.ConfigureSpawns(currentMode.Teams)
	rebalanceBots()
	assignAllTeams()
	PS.ResetMatch()
	for _, p in PS.All() do
		p.Tier = -1 -- force la recoloration
		setTier(p, Config.DefaultTier)
	end

	-- Intermission : vote de la prochaine carte
	table.clear(playerVotes)
	state.MapVotes = {}
	state.MapOptions = if MapBuilder.IsGenerated() and Config.MapSelection.Mode == "Vote" then pickMapOptions() else nil
	announce("Prochaine partie : " .. currentMode.DisplayName, 5)
	setPhase("Intermission", Config.IntermissionTime)
	task.wait(Config.IntermissionTime)

	if MapBuilder.IsGenerated() then
		loadMap(chooseNextMap())
	end
	state.MapOptions = nil
	table.clear(playerVotes)
	broadcastState()

	local winsNeeded = math.floor(currentMode.Rounds / 2) + 1
	for round = 1, currentMode.Rounds do
		if #Players:GetPlayers() == 0 then
			break
		end
		state.Round = round
		state.TeamRoundHits = {}
		for _, t in Config.Teams do
			state.TeamRoundHits[t.Name] = 0
		end
		roundWinner = nil
		PS.ResetRound()
		respawnEveryone()
		task.wait(0.5)

		CombatService.Enabled = true
		BotService.SetActive(true)
		announce((if currentMode.Rounds > 1 then ("Manche " .. round .. " — ") else "") .. state.MapName .. " — À vos fleurs !", 3)
		setPhase("Round", currentMode.RoundTime)

		local deadline = os.clock() + currentMode.RoundTime
		while os.clock() < deadline and not roundWinner and #Players:GetPlayers() > 0 do
			task.wait(0.1)
		end

		CombatService.Enabled = false
		BotService.SetActive(false)
		CombatService.ClearProjectiles()

		local winner = roundWinner or decideRoundByScore()
		if winner then
			local entry = state.RoundsWon[winner.Key] or { Label = winner.Label, Wins = 0 }
			entry.Wins += 1
			state.RoundsWon[winner.Key] = entry
			announce(winner.Label .. " remporte" .. (if currentMode.Teams then "nt" else "") .. " la manche !", 4)
		else
			announce("Manche nulle !", 4)
		end

		local decided = winner and state.RoundsWon[winner.Key].Wins >= winsNeeded
		if round < currentMode.Rounds and not decided then
			setPhase("RoundEnd", Config.RoundBreakTime)
			task.wait(Config.RoundBreakTime)
		end
		if decided then
			break
		end
	end

	local results = buildResults()
	remotes.MatchResults:FireAllClients(results)
	awardSeeds(results)
	announce("Victoire : " .. results.WinnerLabel, 5)
	setPhase("MatchEnd", Config.ResultsTime)
	task.wait(Config.ResultsTime)
end

---------------------------------------------------------------------------
-- Boucle principale
---------------------------------------------------------------------------
task.spawn(function()
	local rotationIndex = 0
	while true do
		if #Players:GetPlayers() == 0 then
			state.Phase = "Waiting"
			BotService.SetActive(false)
			repeat
				task.wait(1)
			until #Players:GetPlayers() > 0
			task.wait(2) -- laisse le temps au personnage d'apparaître
		end
		rotationIndex = rotationIndex % #Config.ModeRotation + 1
		local ok, err = pcall(runMatch, Config.ModeRotation[rotationIndex])
		if not ok then
			warn("[FleurAuFusil] Erreur pendant la partie : " .. tostring(err))
			task.wait(3)
		end
	end
end)
