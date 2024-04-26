local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Observers = require(ReplicatedStorage.Packages.Observers)
local GameIsRunning = ReplicatedStorage:FindFirstChild("IsRunning")
--[[
    https://sleitnick.github.io/RbxObservers/docs/Observers/players
]]

local MainService = Knit.CreateService({
	Name = "MainService",
	Client = {},
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

function MainService:addPlayersToGame()
	local PlayersService = Knit.GetService("PlayersService")
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
		PlayersService:FireAllClients("PlayerAdded", player.userId)
	end
end

function MainService:ChangeTime()
	local PlayersService = Knit.GetService("PlayersService")
	local state = self.Game["Day"]
	if state then
		self.Game["Day"] = false
		PlayersService:FireAllClients("ChangeTime", "Night")
	else
		self.Game["Day"] = true
		PlayersService:FireAllClients("ChangeTime", "Day")
	end
end

function MainService:VerifyIfCanEnd(str)
	local PlayersService = Knit.GetService("PlayersService")
	local PlayersFolders = ServerStorage:FindFirstChild("PlayerData")
	local VillagersAccount = 0
	local WolfsAccount = 0
	for _, folder in pairs(PlayersFolders:GetChildren()) do
		if
			folder:GetAttribute("Role") == "Villager"
			or folder:GetAttribute("Role") == "Medium" and folder:GetAttribute("Alive") == true
		then
			VillagersAccount += 1
		elseif folder:GetAttribute("Role") == "Werewolf" and folder:GetAttribute("Alive") == true then
			WolfsAccount += 1
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
	PlayersService:FireAllClients("DoubleVerify")
end

function MainService:StartGame()
	local VotesService = Knit.GetService("VotesService")
	local PlayersService = Knit.GetService("PlayersService")
	local InteractionService = Knit.GetService("InteractionService")
	local RolesService = Knit.GetService("RolesService")

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
	RolesService:setRoles(self.PlayersInGame, self.Configurations["Werewolves"], self.Configurations["Mediuns"])
	while not self:VerifyIfCanEnd("bool") do
		PlayersService:makeACountDown(self.Configurations["TimeBetweenRounds"], true) -- Countdown to change to night
		if self:VerifyIfCanEnd("bool") then
			PlayersService:makeACountDown(self.Configurations["TimeBetweenRounds"], true)
			break
		end
		PlayersService:MuteHandler(false, "all")
		InteractionService:InteractionsRules("resetall", nil)
		VotesService:SetupVoting() -- Start listening for the new Voting
		PlayersService:FireAllClients("VotesHandler", "Enable", "Werewolf", nil)
		PlayersService:FireAllClients("EnableButtons")
		PlayersService:makeACountDown(self.Configurations["TimeBetweenRounds"], true) -- Countdown to change to day
		task.delay(1, function()
			PlayersService:MuteHandler(true, "all")
		end)
		VotesService:FinishVoting()
		PlayersService:FireAllClients("VotesHandler", "Disable", "Werewolf", nil)
		if self:VerifyIfCanEnd("bool") then
			break
		end
		VotesService:SetupVoting() -- Start listening for the new Voting
		PlayersService:FireAllClients("VotesHandler", "Enable", "Normal", nil)
		InteractionService:InteractionsRules("resetall", nil)
		PlayersService:makeACountDown(self.Configurations["TimeBetweenRounds"]) -- Time to talk
		VotesService:FinishVoting()
		PlayersService:FireAllClients("VotesHandler", "Disable", "Normal", nil)
		if self:VerifyIfCanEnd("bool") then
			break
		end
	end
	PlayersService:FireAllClients("ChatController", true)
	PlayersService:FireAllClients("EndMessage", string.format("%s has won the game", self:VerifyIfCanEnd("team")))
	GameIsRunning.Value = false
	PlayersService:makeACountDown(self.Configurations["TimeBetweenRounds"] * 2) -- Waiting before starting a new round
	PlayersService:FireAllClients("UpdatePlayerCount", "Erase")
	local players = Players:GetChildren()
	local playerCount = #players

	repeat
		task.wait(2)
		PlayersService:FireAllClients(
			"ChangeText",
			string.format("The game needs at least %d players to start", self.Configurations["PlayersToStart"])
		)
	until playerCount >= self.Configurations["PlayersToStart"]

	if playerCount >= self.Configurations["PlayersToStart"] then
		if GameIsRunning.Value == false then
			GameIsRunning.Value = true
			self:StartGame()
		else
			return
		end
	end
end

function MainService:KnitStart()
	local PlayersService = Knit.GetService("PlayersService")
	Observers.observePlayer(function(player)
		PlayersService:FireAllClients("UpdatePlayerCount")
		self.Game.PlayerCount += 1
		if self.Game.PlayerCount >= self.Configurations["PlayersToStart"] then
			if GameIsRunning.Value == false then
				GameIsRunning.Value = true
				self:StartGame()
			else
				return
			end
		else
			PlayersService:FireAllClients(
				"ChangeText",
				string.format("The game needs at least %d players to start", self.Configurations["PlayersToStart"])
			)
			-- Tell everyone that the game can't be started
		end

		return function()
			PlayersService:FireAllClients("UpdatePlayerCount")
			PlayersService:FireAllClients("RemovePlayer", player.Name)
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
