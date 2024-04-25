local ChatService = game:GetService("Chat")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Packages = ReplicatedStorage.Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Observers = require(ReplicatedStorage.Packages.Observers)
local roundTimer = ReplicatedStorage:FindFirstChild("roundTimer")
local VotesFolder = ReplicatedStorage:FindFirstChild("VotesFolder")

local GameIsRunning = ReplicatedStorage:FindFirstChild("IsRunning")
--[[
    https://sleitnick.github.io/RbxObservers/docs/Observers/players
]]

local MainService = Knit.CreateService({
	Name = "MainService",
	Client = {
		PlayerAdded = Knit.CreateSignal(),
		ChangeTime = Knit.CreateSignal(),
		UpdateCountdown = Knit.CreateSignal(),
		UpdatePlayerCount = Knit.CreateSignal(),
		RemovePlayer = Knit.CreateSignal(),
		ChangeText = Knit.CreateSignal(),
		EnableButtons = Knit.CreateSignal(),
		ChatController = Knit.CreateSignal(),
		VotesHandler = Knit.CreateSignal(),
		KillPlayer = Knit.CreateSignal(),
		RevealRole = Knit.CreateSignal(),
		EndMessage = Knit.CreateSignal(),
		DoubleVerify = Knit.CreateSignal(),
	},
	PlayersInGame = {},
	Configurations = {
		["Werewolves"] = 0,
		["Mediuns"] = 0,
		["Villagers"] = 0,
		["PlayersToStart"] = 4, -- Se for menos de 4 jogadores o jogo acaba na primeira noite.
		["TimeBetweenRounds"] = 35,
		["GameStarted"] = false,
	},
	Game = {
		["Day"] = true,
		["PlayerCount"] = 0,
	},
})
--[[
	To Do:

	✅ Implement werewolf vote visibility: Allow werewolves to see who they are Voting to kill at night.
	✅Enable medium role functionality: Allow mediums to see the class (e.g., villager, werewolf) of their target player.
	✅Enable villager vote visibility: Allow villagers to see who they are Voting to kill during the day.
	✅Integrate morning Voting: Add a Voting system during the morning phase of the game.
	✅Implement game loop: Create a loop to manage the different phases (night, day) of the game and ensure it continues running until the end.
	✅Remove the player from the table PlayersInGame (Bug)
	✅Se empatar voto ninguém morre
	✅Werewolf tá podendo votar morto
]]

function MainService:GetAliveStat(playerName)
	local Folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(playerName)
	if Folder1 then
		return Folder1:GetAttribute("Alive")
	end
end

function MainService.Client:GetAlive(executor, plrName)
	return self.Server:GetAliveStat(plrName)
end

function MainService:GetRole(player1, player2Name)
	if player1 and player2Name then
		local Folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(player1.Name)
		local Folder2 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(player2Name)
		if Folder1 and Folder2 then
			local role1 = tostring(Folder1:GetAttribute("Role"))
			local role2 = tostring(Folder2:GetAttribute("Role"))

			if Folder1.Name == Folder2.Name then
				return role1
			else
				if role1 == "Werewolf" and role2 == "Werewolf" then
					return "Werewolf"
				else
					return "Unknown"
				end
			end
		else
			return "No role yet!"
		end
	else
		local name
		if typeof(player1) ~= "string" then
			name = player1.Name
		else
			name = player1
		end

		local Folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(name)
		return tostring(Folder1:GetAttribute("Role"))
	end
end

function MainService.Client:GetClass(player1, player2) -- Player1 é o player tentando acessar a role do player2
	local role
	role = self.Server:GetRole(player1, player2)
	return role
end

function MainService:SetupVoting()
	local function CleanupFolder()
		for _, x in pairs(VotesFolder:GetChildren()) do
			if x then
				x:Destroy()
			end
		end
	end

	CleanupFolder()

	for _, player in pairs(self.PlayersInGame) do
		local newFolder = Instance.new("Folder")
		newFolder.Name = player.Name
		newFolder:SetAttribute("NormalVotes", 0)
		newFolder:SetAttribute("WerewolfVotes", 0)
		newFolder.Parent = VotesFolder
	end
end

function MainService:AddVote(Player, type)
	local target = VotesFolder:FindFirstChild(Player.Name)
	local voteType = type == "Werewolf" and "WerewolfVotes" or type == "Normal" and "NormalVotes"

	if target then
		local currentVotes = target:GetAttribute(voteType) or 0
		target:SetAttribute(voteType, currentVotes + 1)
	end
end

function MainService:FinishVoting()
	local Votes = {}

	local function CollectVoteInfo()
		-- Clear the Votes table only once at the beginning
		if #Votes == 0 then
			Votes = {}
		end

		for _, player in pairs(VotesFolder:GetChildren()) do
			local playerVotes = {}
			local wereVotes, normVotes = player:GetAttribute("WerewolfVotes"), player:GetAttribute("NormalVotes")
			playerVotes[player.Name] = { ["WerewolfVotes"] = wereVotes, ["NormalVotes"] = normVotes }
			table.insert(Votes, playerVotes)
		end
	end

	local function CheckTypeOfVoting()
		CollectVoteInfo()
		for _, playerVotes in pairs(Votes) do
			for playerName, votes in pairs(playerVotes) do
				if votes["WerewolfVotes"] > 0 then
					return "Werewolf"
				elseif votes["NormalVotes"] > 0 then
					return "Normal"
				end
			end
		end
		return "Nothing"
	end

	local typeOfVoting = CheckTypeOfVoting()

	local function MostVotedOfType(tipo)
		local mostVotedPlayers = {}
		local mostVotes = 0
		local hasVotes = false

		for _, playerVotes in pairs(Votes) do
			for playerName, votes in pairs(playerVotes) do
				local votesOfType = votes[tipo .. "Votes"] or 0 -- Se votes[tipo .. "Votes"] for nil, considera como 0
				if votesOfType > 0 then
					if votesOfType > mostVotes then
						mostVotes = votesOfType
						mostVotedPlayers = { playerName }
						hasVotes = true
					elseif votesOfType == mostVotes then
						table.insert(mostVotedPlayers, playerName)
						hasVotes = true
					end
				end
			end
		end

		if hasVotes then
			return mostVotedPlayers
		else
			return nil
		end
	end

	local MostVotedPlayerNames = MostVotedOfType(typeOfVoting)

	if typeOfVoting == "Werewolf" or typeOfVoting == "Normal" then
		if MostVotedPlayerNames and #MostVotedPlayerNames == 1 then
			local mostVotedPlayerName = MostVotedPlayerNames[1]
			local folder = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(mostVotedPlayerName)
			local player = game.Players:FindFirstChild(mostVotedPlayerName)
			if folder then
				self:FireAllClients("KillPlayer", mostVotedPlayerName)
				folder:SetAttribute("Alive", false)
				self:MuteHandler(false, "solo", mostVotedPlayerName)
				folder:Destroy()
			end
		elseif MostVotedPlayerNames and #MostVotedPlayerNames > 1 then
			-- Empate, não faz nada
		end
	end
end

function MainService:InteractionsRules(rule, player)
	if rule == "reset" then
		local folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(player.Name)
		if folder1 then
			folder1:SetAttribute("ActionCooldown", false)
		end
	elseif rule == "resetall" then
		for _, x in pairs(game.Players:GetPlayers()) do
			local folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(x.Name)
			if folder1 then
				folder1:SetAttribute("ActionCooldown", false)
			end
		end
	elseif rule == "putInCooldown" then
		local folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(player.Name)
		if folder1 then
			folder1:SetAttribute("ActionCooldown", true)
		end
	elseif rule == "checkCooldown" then
		local folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(player.Name)
		if folder1 then
			if folder1:GetAttribute("Alive") == false then
				return false
			end
			local att = folder1:GetAttribute("ActionCooldown")
			if not att then
				folder1:SetAttribute("ActionCooldown", false)
				return false
			end
			return att
		end
	end
end

function MainService:Interact(player1, player2)
	if player1 and player2 then
		local role1 = self:GetRole(player1)
		local role2 = self:GetRole(player2.Name)
		if not self:InteractionsRules("checkCooldown", player1) then
			warn(self.Game["Day"])
			if self.Game["Day"] == false then
				if self:GetAliveStat(player1) == false or self:GetAliveStat(player2.Name) == false then
					return
				end
				if role1 == "Werewolf" then
					-- Here you can add such features like medic protection
					if role1 ~= role2 then
						self:AddVote(player2, "Werewolf")
						self:InteractionsRules("putInCooldown", player1)
						--self.Client["ChatController"]:Fire(player2, false)
					else
						warn("Werewolf can't kill another werewolf")
					end
				elseif role1 == "Medium" then
					warn(player1.Name .. " got the role: " .. role2 .. " of the player " .. player2.Name)
					self.Client["RevealRole"]:Fire(player1, player2.Name, role2)
					self:InteractionsRules("putInCooldown", player1)
					-- Add more elseifs to make new roles
				else
					warn("Villagers are not allowed to interact")
				end
			else
				if self:GetAliveStat(player1) == false then
					return
				end
				print("Adding normal Votes to: " .. player2.Name)
				self:AddVote(player2, "Normal")
				self:InteractionsRules("putInCooldown", player1)
			end
		end
	else
		warn("Something is wrong, Probably one of the players leaved in the middle of the interaction")
	end
end

function MainService.Client:PlayerInteraction(player1, player2Name)
	local player2 = Players:FindFirstChild(player2Name)
	if player1 and player2 then
		self.Server:Interact(player1, player2)
	end
end

function MainService:FireAllClients(eventName, ...)
	for _, player in ipairs(Players:GetPlayers()) do
		self.Client[eventName]:Fire(player, ...)
	end
end

function MainService:addPlayersToGame()
	local playersInGame = self.PlayersInGame
	local newPlayers = {}
	local function tableContains(table, parameter)
		for _, value in pairs(table) do
			if value == parameter then
				return true
			end
		end
		return false
	end

	for _, player in ipairs(Players:GetChildren()) do
		if not tableContains(playersInGame, player) then
			table.insert(newPlayers, player)
		end
	end

	-- Add new players to the table and fire events in one loop
	for _, player in ipairs(newPlayers) do
		table.insert(playersInGame, player)
		self:FireAllClients("PlayerAdded", player.userId)
	end
end

function MainService:ChangeTime()
	local state = self.Game["Day"]
	if state then
		self.Game["Day"] = false
		self:FireAllClients("ChangeTime", "Night")
	else
		self.Game["Day"] = true
		self:FireAllClients("ChangeTime", "Day")
	end
end

function MainService:makeACountDown(secs, shouldChangeTime)
	roundTimer.Value = secs
	repeat
		task.wait(1)
		roundTimer.Value -= 1
		self:FireAllClients("UpdateCountdown")
		self:FireAllClients("UpdatePlayerCount")
	until roundTimer.Value <= 0

	if shouldChangeTime then
		self:ChangeTime()
	end
end

function shuffle(table)
	local currentIndex = #table
	for i = currentIndex - 1, 1, -1 do
		local randomIndex = math.random(1, i)
		table[i], table[randomIndex] = table[randomIndex], table[i]
	end
	return table
end

function MainService:GetAllies(player)
	local Allies = {}
	local Role = self:GetRole(player.Name)
	local Roles = ServerStorage:FindFirstChild("PlayerData")
	if Role == "Werewolf" and Roles then
		for _, x in pairs(Roles:GetChildren()) do
			if x:GetAttribute("Role") == Role then
				table.insert(Allies, x.Name)
			end
		end
		return Allies
	else
		return
	end
end

function MainService.Client:ReturnAllies(player)
	return self.Server:GetAllies(player)
end

function MainService:setRoles()
	local playersInGame = self.PlayersInGame
	local wolfsAmount = self.Configurations["Werewolves"]
	local mediunsAmount = self.Configurations["Mediuns"]
	local Roles = ServerStorage:FindFirstChild("PlayerData") or Instance.new("Folder", ServerStorage)
	Roles.Name = "PlayerData"
	for _, x in pairs(Roles:GetChildren()) do
		x:Destroy()
	end
	shuffle(playersInGame)
	-- Assign werewolf roles
	for i = 1, wolfsAmount do
		local assigned = false
		for _, player in pairs(playersInGame) do
			if not Roles:FindFirstChild(player.Name) then
				warn("Were: " .. player.Name)
				local fold = Instance.new("Folder")
				fold.Name = player.Name
				fold:SetAttribute("Role", "Werewolf")
				fold.Parent = Roles
				assigned = true
				break
			end
		end
		if not assigned then
			shuffle(playersInGame)
		end
	end

	-- Assign medium roles
	for i = 1, mediunsAmount do
		local assigned = false
		for _, player in pairs(playersInGame) do
			if not Roles:FindFirstChild(player.Name) then
				warn("Med: " .. player.Name)
				local fold = Instance.new("Folder")
				fold.Name = player.Name
				fold:SetAttribute("Role", "Medium")
				fold.Parent = Roles
				assigned = true
				break
			end
		end
		if not assigned then
			shuffle(shuffle(playersInGame))
		end
	end

	-- Assign villager roles to remaining players
	for _, player in pairs(playersInGame) do
		if not Roles:FindFirstChild(player.Name) then
			warn("Villager: " .. player.Name)
			local fold = Instance.new("Folder")
			fold.Name = player.Name
			fold:SetAttribute("Role", "Villager")
			fold.Parent = Roles
		end
	end

	for _, folder in pairs(Roles:GetChildren()) do
		folder:SetAttribute("Alive", true)
	end
end

function MainService:VerifyIfCanEnd(str)
	local PlayersFolders = ServerStorage:FindFirstChild("PlayerData")
	local VillagersAccount = 0
	local WolfsAccount = 0
	for _, folder in pairs(PlayersFolders:GetChildren()) do
		if
			folder:GetAttribute("Role") == "Villager"
			or folder:GetAttribute("Role") == "Medium" and folder:GetAttribute("Alive") == true
		then
			warn("Villager: " .. folder.Name)
			VillagersAccount += 1
		elseif folder:GetAttribute("Role") == "Werewolf" and folder:GetAttribute("Alive") == true then
			WolfsAccount += 1
			warn("Wolf: " .. folder.Name)
		end
	end

	if str == "bool" then
		if WolfsAccount == 0 or WolfsAccount >= VillagersAccount then
			return true
		else
			return false
		end
	elseif str == "team" then
		if WolfsAccount == 0 then
			return "Villagers"
		elseif WolfsAccount >= VillagersAccount then
			return "Werewolves"
		end
	end
	self:FireAllClients("DoubleVerify")
end

function MainService:MuteHandler(bool, type, playerName)
	local folder = ServerStorage:WaitForChild("PlayerData")
	if type == "all" then
		for _, x in pairs(folder:GetChildren()) do
			local player = game.Players:FindFirstChild(x.Name)
			if player and x:GetAttribute("Alive") == true then
				MainService.Client["ChatController"]:Fire(player, bool)
			end
		end
	else
		local player = game.Players:FindFirstChild(playerName)
		if player then
			MainService.Client["ChatController"]:Fire(player, bool)
		end
	end
end

function MainService:StartGame()
	local PlayersFolders = ServerStorage:FindFirstChild("PlayerData")
	if PlayersFolders then
		PlayersFolders:Destroy()
	end
	local players = Players:GetChildren()
	local playerCount = #players
	local Mediuns
	local werewolfAmount
	self.Configurations["Werewolves"] = 0
	self.Configurations["Mediuns"] = 0
	if playerCount >= 3 and playerCount < 7 then
		werewolfAmount = 1
		Mediuns = 1
	elseif playerCount >= 7 and playerCount <= 15 then
		werewolfAmount = 2
		Mediuns = 1
	elseif playerCount > 15 then
		werewolfAmount = 3
		Mediuns = 1
	else
		if RunService:IsStudio() then
			werewolfAmount = 1
			Mediuns = 1
		else
			return
		end
	end
	-- Setup
	self.PlayersInGame = {} -- Limpa se ainda não foi limpo
	self.Configurations["Werewolves"] = werewolfAmount
	self.Configurations["Mediuns"] = Mediuns
	self:addPlayersToGame()
	self:setRoles()
	while not self:VerifyIfCanEnd("bool") do
		warn("Can End: " .. tostring(self:VerifyIfCanEnd("bool")))
		self:makeACountDown(self.Configurations["TimeBetweenRounds"], true) -- Countdown to change to night
		if self:VerifyIfCanEnd("bool") then
			self:makeACountDown(self.Configurations["TimeBetweenRounds"], true)
			break
		end
		self:MuteHandler(false, "all")
		self:InteractionsRules("resetall", nil)
		self:SetupVoting() -- Start listening for the new Voting
		self:FireAllClients("VotesHandler", "Enable", "Werewolf", nil)
		self:FireAllClients("EnableButtons", true)
		self:makeACountDown(self.Configurations["TimeBetweenRounds"], true) -- Countdown to change to day
		task.delay(1, function()
			self:MuteHandler(true, "all")
		end)
		self:FinishVoting()
		self:FireAllClients("VotesHandler", "Disable", "Werewolf", nil)
		if self:VerifyIfCanEnd("bool") then
			break
		end
		self:SetupVoting() -- Start listening for the new Voting
		self:FireAllClients("VotesHandler", "Enable", "Normal", nil)
		self:InteractionsRules("resetall", nil)
		self:makeACountDown(self.Configurations["TimeBetweenRounds"]) -- Time to talk
		self:FinishVoting()
		self:FireAllClients("VotesHandler", "Disable", "Normal", nil)
		if self:VerifyIfCanEnd("bool") then
			break
		end
	end
	self:FireAllClients("ChatController", true)
	self:FireAllClients("EndMessage", string.format("%s has won the game", self:VerifyIfCanEnd("team")))
	warn("Game Ended.")
	GameIsRunning.Value = false
	self:makeACountDown(self.Configurations["TimeBetweenRounds"] * 2) -- Waiting before starting a new round
	self:FireAllClients("UpdatePlayerCount", "Erase")
	local players = Players:GetChildren()
	local playerCount = #players

	repeat
		task.wait(2)
		self:FireAllClients(
			"ChangeText",
			string.format("The game needs at least %d players to start", self.Configurations["PlayersToStart"])
		)
	until playerCount >= self.Configurations["PlayersToStart"]

	if playerCount >= self.Configurations["PlayersToStart"] then
		if GameIsRunning.Value == false then
			GameIsRunning.Value = true
			warn("Game Restarted")
			self:StartGame()
		else
			return
		end
	end
end

function MainService:KnitStart()
	Observers.observePlayer(function(player)
		self:FireAllClients("UpdatePlayerCount")
		self.Game.PlayerCount += 1
		if self.Game.PlayerCount >= self.Configurations["PlayersToStart"] then
			if GameIsRunning.Value == false then
				GameIsRunning.Value = true
				warn("Game Started")
				self:StartGame()
			else
				return
			end
		else
			self:FireAllClients(
				"ChangeText",
				string.format("The game needs at least %d players to start", self.Configurations["PlayersToStart"])
			)
			-- Tell everyone that the game can't be started
		end

		return function()
			self:FireAllClients("UpdatePlayerCount")
			self:FireAllClients("RemovePlayer", player.Name)
			local PlayersFolders = ServerStorage:FindFirstChild("PlayerData")
			local targetedFolder = PlayersFolders:FindFirstChild(player.Name)
			if targetedFolder then
				targetedFolder:Destroy()
			end
			self.Game.PlayerCount -= 1
			local index = table.find(self.PlayersInGame, player)
			if index then
				table.remove(self.PlayersInGame, index)
			end
		end
	end)
end

function MainService:KnitInit() end

return MainService
