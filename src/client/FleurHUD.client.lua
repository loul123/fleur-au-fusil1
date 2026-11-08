--[[
	La fleur au fusil — Interface de jeu (LocalScript)
	Emplacement : StarterPlayer > StarterPlayerScripts > FleurClient > FleurHUD

	* Bandeau : mode, manche, chrono, objectif, scores d'équipe.
	* Statistiques perso : touches, reçues, ratio, score, fleur (progression Gun Game).
	* Classement en direct (Tab pour l'agrandir), fil des éliminations,
	  annonces et écran de résultats en fin de partie.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("FleurShared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild(Config.RemotesFolderName)

local myId = "P" .. player.UserId
local state = { Phase = "Waiting", ModeName = "", Objective = "", Round = 0, Rounds = 0, EndsAt = 0, TeamRoundHits = {}, RoundsWon = {}, Teams = false, Target = 0 }
local scoreboard = {}

local FONT = Enum.Font.FredokaOne
local PANEL = Color3.fromRGB(35, 50, 30)

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

local function label(props, parent)
	local base = { BackgroundTransparency = 1, Font = FONT, TextColor3 = Color3.new(1, 1, 1), TextScaled = true }
	for k, v in props do
		base[k] = v
	end
	local l = make("TextLabel", base, parent)
	make("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(20, 30, 15) }, l)
	return l
end

local function panel(props, parent)
	local base = { BackgroundColor3 = PANEL, BackgroundTransparency = 0.25, BorderSizePixel = 0 }
	for k, v in props do
		base[k] = v
	end
	local f = make("Frame", base, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, f)
	return f
end

local gui = make("ScreenGui", { Name = "FleurHUD", ResetOnSpawn = false, IgnoreGuiInset = false, DisplayOrder = 4 }, player:WaitForChild("PlayerGui"))

---------------------------------------------------------------------------
-- Bandeau supérieur
---------------------------------------------------------------------------
local top = panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(460, 92) }, gui)
local modeLabel = label({ Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 4), Text = "La fleur au fusil" }, top)
local timerLabel = label({ Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 30), Text = "", TextColor3 = Color3.fromRGB(255, 235, 120) }, top)
local objectiveLabel = label({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 64), Text = "", TextColor3 = Color3.fromRGB(210, 230, 200) }, top)

local teamA = Config.Teams[1]
local teamB = Config.Teams[2]
local teamBar = make("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(460, 34), BackgroundTransparency = 1, Visible = false }, gui)
local teamAPanel = panel({ Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = teamA.BrickColor.Color }, teamBar)
local teamALabel = label({ Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), Text = "" }, teamAPanel)
local teamBPanel = panel({ Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0), BackgroundColor3 = teamB.BrickColor.Color }, teamBar)
local teamBLabel = label({ Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), Text = "" }, teamBPanel)

---------------------------------------------------------------------------
-- Stats perso (bas gauche)
---------------------------------------------------------------------------
local stats = panel({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.fromOffset(270, 112) }, gui)
local flowerLabel = label({ Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 6), Text = "✿ Pâquerette", TextXAlignment = Enum.TextXAlignment.Left }, stats)
local statsLabel = label({ Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 40), Text = "", TextXAlignment = Enum.TextXAlignment.Left }, stats)
local scoreLabel = label({ Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 66), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 235, 120) }, stats)
local progressBack = make("Frame", { Position = UDim2.new(0, 8, 1, -14), Size = UDim2.new(1, -16, 0, 6), BackgroundColor3 = Color3.fromRGB(20, 25, 15), BorderSizePixel = 0 }, stats)
local progressFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(140, 220, 90), BorderSizePixel = 0 }, progressBack)

---------------------------------------------------------------------------
-- Classement (droite)
---------------------------------------------------------------------------
local board = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(300, 40) }, gui)
label({ Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 6), Text = "Classement", TextXAlignment = Enum.TextXAlignment.Left }, board)
local boardHeader = label({ Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 30), Text = "", TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(190, 210, 180) }, board)
boardHeader.Text = "Touches  Reçues  Ratio  Score"
local boardRows = {}
local expanded = false

---------------------------------------------------------------------------
-- Annonces, fil d'éliminations, résultats
---------------------------------------------------------------------------
local announceLabel = label({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.32), Size = UDim2.fromOffset(700, 60), Text = "", TextTransparency = 1, TextColor3 = Color3.fromRGB(255, 240, 150) }, gui)
local announceToken = 0

local feed = make("Frame", { Position = UDim2.new(0, 12, 0, 150), Size = UDim2.fromOffset(320, 160), BackgroundTransparency = 1 }, gui)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Top }, feed)
local feedOrder = 0

local results = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(620, 420), Visible = false, BackgroundTransparency = 0.1 }, gui)
local resultsTitle = label({ Size = UDim2.new(1, -20, 0, 36), Position = UDim2.fromOffset(10, 8), Text = "Résultats" }, results)
local resultsWinner = label({ Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 46), Text = "", TextColor3 = Color3.fromRGB(255, 235, 120) }, results)
local resultsBody = make("Frame", { Position = UDim2.fromOffset(16, 86), Size = UDim2.new(1, -32, 1, -130), BackgroundTransparency = 1 }, results)
make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, resultsBody)
label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(1, -20, 0, 30),
	Text = string.format("Score = touches×%d − reçues×%d, multiplié selon le ratio (×%.1f à ×%.1f)",
		Config.Scoring.HitPoints, Config.Scoring.PenaltyPoints, Config.Scoring.MinMultiplier, Config.Scoring.MaxMultiplier),
	TextColor3 = Color3.fromRGB(190, 210, 180) }, results)

---------------------------------------------------------------------------
-- Rendu
---------------------------------------------------------------------------
local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function myRow()
	for _, r in scoreboard do
		if r.Id == myId then
			return r
		end
	end
	return nil
end

local function teamColorOf(teamName)
	for _, t in Config.Teams do
		if t.Name == teamName then
			return t.BrickColor.Color
		end
	end
	return nil
end

local function renderTeams()
	teamBar.Visible = state.Teams and (state.Phase == "Round" or state.Phase == "RoundEnd")
	if not teamBar.Visible then
		return
	end
	local hits = state.TeamRoundHits or {}
	local won = state.RoundsWon or {}
	local function text(t)
		local w = won[t.Name] and won[t.Name].Wins or 0
		return string.format("%s  %d/%d  (manches : %d)", t.Name, hits[t.Name] or 0, state.Target, w)
	end
	teamALabel.Text = text(teamA)
	teamBLabel.Text = text(teamB)
end

local function renderStats()
	local r = myRow()
	local tier = Config.GetTier(player:GetAttribute("FleurTier") or Config.DefaultTier)
	flowerLabel.Text = "✿ " .. tier.Name
	flowerLabel.TextColor3 = tier.PetalColor
	if not r then
		statsLabel.Text = "Touches 0   Reçues 0   Ratio 0"
		scoreLabel.Text = "Score 0"
		progressFill.Size = UDim2.fromScale(0, 1)
		return
	end
	statsLabel.Text = string.format("Touches %d   Reçues %d   Ratio %.2f", r.Hits, r.Taken, r.Ratio)
	local mode = Config.Modes[state.ModeKey or ""]
	if mode and mode.TierEvery then
		local nextIn = mode.TierEvery - (r.RoundHits % mode.TierEvery)
		scoreLabel.Text = string.format("Score %d   •   %d/%d (fleur suivante : %d)", r.Score, r.RoundHits, state.Target, nextIn)
	else
		scoreLabel.Text = string.format("Score %d   •   manche : %d/%d", r.Score, r.RoundHits, state.Target)
	end
	progressFill.Size = UDim2.fromScale(math.clamp(r.RoundHits / math.max(1, state.Target), 0, 1), 1)
end

local function renderBoard()
	for _, row in boardRows do
		row:Destroy()
	end
	table.clear(boardRows)
	local maxRows = if expanded then 16 else 6
	local count = math.min(#scoreboard, maxRows)
	for i = 1, count do
		local r = scoreboard[i]
		local row = make("Frame", { Position = UDim2.fromOffset(8, 50 + (i - 1) * 24), Size = UDim2.new(1, -16, 0, 22),
			BackgroundColor3 = teamColorOf(r.Team) or Color3.fromRGB(70, 90, 60),
			BackgroundTransparency = if r.Id == myId then 0.2 else 0.65, BorderSizePixel = 0 }, board)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
		label({ Size = UDim2.new(0.45, 0, 1, -4), Position = UDim2.fromOffset(6, 2), TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.format("%d. %s%s", i, if r.IsBot then "🌱" else "", r.Name) }, row)
		label({ Size = UDim2.new(0.55, -8, 1, -4), Position = UDim2.new(0.45, 0, 0, 2), TextXAlignment = Enum.TextXAlignment.Right,
			Text = string.format("%d   %d   %.1f   %d", r.Hits, r.Taken, r.Ratio, r.Score) }, row)
		table.insert(boardRows, row)
	end
	board.Size = UDim2.fromOffset(300, 56 + count * 24)
end

local function renderAll()
	modeLabel.Text = if state.ModeName ~= "" then state.ModeName else "La fleur au fusil"
	objectiveLabel.Text = state.Objective or ""
	renderTeams()
	renderStats()
	renderBoard()
	if state.Phase == "Intermission" or state.Phase == "Round" then
		results.Visible = false
	end
end

local function announce(text, duration)
	announceToken += 1
	local token = announceToken
	announceLabel.Text = text
	announceLabel.TextTransparency = 0
	announceLabel.Size = UDim2.fromOffset(760, 70)
	TweenService:Create(announceLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(700, 60) }):Play()
	task.delay(duration or 3, function()
		if token == announceToken then
			TweenService:Create(announceLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		end
	end)
end

local function addFeed(text)
	feedOrder += 1
	local entry = panel({ Size = UDim2.new(1, 0, 0, 24), LayoutOrder = -feedOrder, BackgroundTransparency = 0.4 }, feed)
	label({ Size = UDim2.new(1, -12, 1, -4), Position = UDim2.fromOffset(6, 2), Text = text, TextXAlignment = Enum.TextXAlignment.Left }, entry)
	local children = {}
	for _, c in feed:GetChildren() do
		if c:IsA("Frame") then
			table.insert(children, c)
		end
	end
	if #children > 6 then
		table.sort(children, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		children[#children]:Destroy()
	end
	task.delay(7, function()
		if entry.Parent then
			entry:Destroy()
		end
	end)
end

local function showResults(data)
	for _, c in resultsBody:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	resultsTitle.Text = "Résultats — " .. (data.ModeName or "")
	resultsWinner.Text = "Victoire : " .. (data.WinnerLabel or "?") .. "   •   MVP : " .. (data.MVP or "—")
	local header = label({ Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 0, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "#   Nom                                  Touches   Reçues   Ratio   Score final", TextColor3 = Color3.fromRGB(190, 210, 180) }, resultsBody)
	header.TextScaled = false
	header.TextSize = 16
	if data.TeamTotals then
		local i = 0
		for name, t in data.TeamTotals do
			i += 1
			local l = label({ Size = UDim2.new(1, 0, 0, 22), LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Left,
				Text = string.format("Équipe %s : %d touches, %d reçues, score %d", name, t.Hits, t.Taken, t.Score),
				TextColor3 = teamColorOf(name) or Color3.new(1, 1, 1) }, resultsBody)
			l.TextScaled = false
			l.TextSize = 18
		end
	end
	for i, r in data.Rows or {} do
		if i > 10 then
			break
		end
		local row = make("Frame", { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 10 + i,
			BackgroundColor3 = teamColorOf(r.Team) or Color3.fromRGB(70, 90, 60),
			BackgroundTransparency = if r.Id == myId then 0.2 else 0.6, BorderSizePixel = 0 }, resultsBody)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
		label({ Size = UDim2.new(0.55, 0, 1, -4), Position = UDim2.fromOffset(6, 2), TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.format("%d.  %s%s", i, if r.IsBot then "🌱 " else "", r.Name) }, row)
		label({ Size = UDim2.new(0.45, -8, 1, -4), Position = UDim2.new(0.55, 0, 0, 2), TextXAlignment = Enum.TextXAlignment.Right,
			Text = string.format("%d     %d     %.2f     %d", r.Hits, r.Taken, r.Ratio, r.Score) }, row)
	end
	results.Visible = true
end

---------------------------------------------------------------------------
-- Réseau
---------------------------------------------------------------------------
remotes:WaitForChild("GameState").OnClientEvent:Connect(function(s)
	state = s
	renderAll()
end)

remotes:WaitForChild("Scoreboard").OnClientEvent:Connect(function(rows, teamHits)
	scoreboard = rows
	if teamHits then
		state.TeamRoundHits = teamHits
	end
	renderAll()
end)

remotes:WaitForChild("Announce").OnClientEvent:Connect(announce)

remotes:WaitForChild("KillFeed").OnClientEvent:Connect(function(shooterName, victimName, flowerName)
	addFeed(string.format("%s ✿ %s  (%s)", shooterName, victimName, flowerName))
end)

remotes:WaitForChild("MatchResults").OnClientEvent:Connect(showResults)

player:GetAttributeChangedSignal("FleurTier"):Connect(renderStats)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Tab then
		expanded = not expanded
		renderBoard()
	end
end)

task.spawn(function()
	local ok, s, rows = pcall(function()
		return remotes:WaitForChild("GetState"):InvokeServer()
	end)
	if ok and s then
		state = s
		scoreboard = rows or {}
		renderAll()
	end
end)

-- Chronomètre
RunService.Heartbeat:Connect(function()
	local remaining = (state.EndsAt or 0) - workspace:GetServerTimeNow()
	local phase = state.Phase
	if phase == "Waiting" then
		timerLabel.Text = "En attente de joueurs…"
	elseif phase == "Intermission" then
		timerLabel.Text = "Début dans " .. formatTime(remaining)
	elseif phase == "Round" then
		local roundText = if (state.Rounds or 1) > 1 then string.format("Manche %d/%d   ", state.Round, state.Rounds) else ""
		timerLabel.Text = roundText .. formatTime(remaining)
	elseif phase == "RoundEnd" then
		timerLabel.Text = "Manche suivante dans " .. formatTime(remaining)
	elseif phase == "MatchEnd" then
		timerLabel.Text = "Partie terminée — " .. formatTime(remaining)
	end
end)

renderAll()
