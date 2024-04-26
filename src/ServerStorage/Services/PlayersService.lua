local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local roundTimer = ReplicatedStorage:FindFirstChild("roundTimer")
local Observers = require(ReplicatedStorage.Packages.Observers)
local GameIsRunning = ReplicatedStorage:FindFirstChild("IsRunning")

local PlayersService = Knit.CreateService({
	Name = "PlayersService",
	Client = {
		EnableButtons = Knit.CreateSignal(),
		ChatController = Knit.CreateSignal(),
		VotesHandler = Knit.CreateSignal(),
		KillPlayer = Knit.CreateSignal(),
		RevealRole = Knit.CreateSignal(),
		EndMessage = Knit.CreateSignal(),
		DoubleVerify = Knit.CreateSignal(),
		PlayerAdded = Knit.CreateSignal(),
		ChangeTime = Knit.CreateSignal(),
		UpdateCountdown = Knit.CreateSignal(),
		UpdatePlayerCount = Knit.CreateSignal(),
		RemovePlayer = Knit.CreateSignal(),
		ChangeText = Knit.CreateSignal(),
	},
})

function PlayersService:MuteHandler(bool, type, playerName)
	local folder = ServerStorage:WaitForChild("PlayerData")
	if type == "all" then
		for _, x in pairs(folder:GetChildren()) do
			local player = game.Players:FindFirstChild(x.Name)
			if player and x:GetAttribute("Alive") == true then
				PlayersService.Client["ChatController"]:Fire(player, bool)
			end
		end
	else
		local player = game.Players:FindFirstChild(playerName)
		if player then
			PlayersService.Client["ChatController"]:Fire(player, bool)
		end
	end
end

function PlayersService:makeACountDown(secs, shouldChangeTime)
	local MainService = Knit.GetService("MainService")
	roundTimer.Value = secs
	repeat
		task.wait(1)
		roundTimer.Value -= 1
		self:FireAllClients("UpdateCountdown")
		self:FireAllClients("UpdatePlayerCount")
	until roundTimer.Value <= 0

	if shouldChangeTime then
		MainService:ChangeTime()
	end
end

function PlayersService:addPlayersToGame()
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

function PlayersService:FireAllClients(eventName, ...)
	for _, player in ipairs(Players:GetPlayers()) do
		self.Client[eventName]:Fire(player, ...)
	end
end

function PlayersService:GetAliveStat(playerName)
	local Folder1 = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(playerName)
	if Folder1 then
		return Folder1:GetAttribute("Alive")
	end
end

function PlayersService.Client:GetAlive(executor, plrName)
	return self.Server:GetAliveStat(plrName)
end

function PlayersService:KnitStart() end

function PlayersService:KnitInit() end

return PlayersService
