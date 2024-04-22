local ChatService = game:GetService("Chat")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Packages = ReplicatedStorage.Packages
local Utils = require(ReplicatedStorage.Shared.Utils)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Observers = require(ReplicatedStorage.Packages.Observers)
local roundTimer = ReplicatedStorage:FindFirstChild("roundTimer")
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
	},
	PlayersInGame = {},
	Configurations = {
		["Werewolfs"] = 0,
		["Mediuns"] = 0,
		["Villagers"] = 0,
	},
	Game = {
		["Day"] = true,
		["PlayerCount"] = 0,
	},
})

function MainService:GetRole(name)
	local Folder = ServerStorage:WaitForChild("PlayerData"):FindFirstChild(name)
	if Folder then
		return tostring(Folder:GetAttribute("Role"))
	else
		return "No role yet!"
	end
end

function MainService.Client:GetClass(x, player)
	local role
	if x.Name == player then
		role = self.Server:GetRole(player)
	else
		role = "Unknown"
	end
	return role
end

function MainService:FireAllClients(eventName, ...)
	for _, player in ipairs(Players:GetPlayers()) do
		self.Client[eventName]:Fire(player, ...)
	end
end

function MainService:addPlayersToGame()
	local playersInGame = self.PlayersInGame
	local newPlayers = {}

	for _, player in ipairs(Players:GetChildren()) do
		if not playersInGame[player] then
			table.insert(newPlayers, player)
		end
	end

	-- Add new players to the table and fire events in one loop
	for _, player in ipairs(newPlayers) do
		table.insert(playersInGame, player)
		playersInGame[player] = true -- Mark player as added
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

function MainService:makeACountDown(secs)
	roundTimer.Value = secs
	repeat
		task.wait(1)
		roundTimer.Value -= 1
		self:FireAllClients("UpdateCountdown")
		self:FireAllClients("UpdatePlayerCount")
	until roundTimer.Value <= 0

	self:ChangeTime()
end

function shuffle(table)
	local currentIndex = #table
	for i = currentIndex - 1, 1, -1 do
		local randomIndex = math.random(1, i)
		table[i], table[randomIndex] = table[randomIndex], table[i]
	end
	return table
end

function MainService:setRoles()
	local playersInGame = self.PlayersInGame
	local wolfsAmount = self.Configurations["Werewolfs"]
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
		for _, player in ipairs(playersInGame) do
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
		for _, player in ipairs(playersInGame) do
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
	for _, player in ipairs(playersInGame) do
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

function MainService:StartGame()
	local players = Players:GetChildren()
	local playerCount = #players
	local Mediuns
	local werewolfAmount
	self.Configurations["Werewolfs"] = 0
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
	self.PlayersInGame = {} -- Limpa se ainda não foi limpo
	self.Configurations["Werewolfs"] = werewolfAmount
	self.Configurations["Mediuns"] = Mediuns
	self:addPlayersToGame()
	self:setRoles()
	self:makeACountDown(40)
end

function MainService:KnitStart()
	Observers.observePlayer(function(player)
		self:FireAllClients("UpdatePlayerCount")
		self.Game.PlayerCount += 1
		if self.Game.PlayerCount >= 2 then
			self:StartGame()
		end

		return function()
			self:FireAllClients("UpdatePlayerCount")
			self:FireAllClients("RemovePlayer", player.Name)
			self.Game.PlayerCount -= 1
		end
	end)
end
function MainService:KnitInit() end

return MainService
