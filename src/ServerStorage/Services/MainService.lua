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
	},
	PlayersInGame = {},
	Configurations = {
		["Werewolfs"] = 0,
		["Mediuns"] = 0,
		["Villagers"] = 0,
		["PlayersToStart"] = 2,
		["TimeBetweenRounds"] = 15,
		["GameStarted"] = false,
	},
	Game = {
		["Day"] = true,
		["PlayerCount"] = 0,
	},
})
--[[
	To Do:

	Implement werewolf vote visibility: Allow werewolves to see who they are voting to kill at night.
	Enable medium role functionality: Allow mediums to see the class (e.g., villager, werewolf) of their target player.
	Enable villager vote visibility: Allow villagers to see who they are voting to kill during the day.
	Integrate morning voting: Add a voting system during the morning phase of the game.
	Implement game loop: Create a loop to manage the different phases (night, day) of the game and ensure it continues running until the end.
	Remove the player from the table PlayersInGame (Bug)
]]

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

function MainService:SetupVotation()
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
		warn(self:InteractionsRules("checkCooldown", player1))
		if not self:InteractionsRules("checkCooldown", player1) then
			if role1 == "Werewolf" then
				-- Here you can add such features like medic protection
				if role1 ~= role2 then
					warn(player1.Name .. " Voted to Kill " .. player2.Name)
					self:AddVote(player2, "Werewolf")
					self:InteractionsRules("putInCooldown", player1)
					--self.Client["ChatController"]:Fire(player2, false)
				else
					warn("Werewolf can't kill another werewolf")
				end
			elseif role1 == "Medium" then
				warn(player1.Name .. " got the role: " .. role2 .. " of the player " .. player2.Name)
				self:InteractionsRules("putInCooldown", player1)
				-- Add more elseifs to make new roles
			else
				warn("Villagers are not allowed to interact")
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

function MainService:VerifyIfCanEnd()
	local PlayersFolders = ServerStorage:FindFirstChild("PlayerData")
	local VillagersAccount = 0
	local WolfsAccount = 0
	for _, folder in pairs(PlayersFolders:GetChildren()) do
		if folder:GetAttribute("Role") == "Villager" or folder:GetAttribute("Role") == "Medium" then
			VillagersAccount += 1
		elseif folder:GetAttribute("Role") == "Werewolf" then
			WolfsAccount += 1
		end
	end

	if WolfsAccount == 0 or WolfsAccount >= VillagersAccount then
		return true
	else
		return false
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
	-- Setup
	self.PlayersInGame = {} -- Limpa se ainda não foi limpo
	self.Configurations["Werewolfs"] = werewolfAmount
	self.Configurations["Mediuns"] = Mediuns
	self:addPlayersToGame()
	self:setRoles()

	while self:VerifyIfCanEnd() do
		self:makeACountDown(self.Configurations["TimeBetweenRounds"]) -- Countdown to change to night
		self:FireAllClients("EnableButtons", true) -- Buttons activated in the night
		self:InteractionsRules("resetall", nil)
		self:SetupVotation()
		self:FireAllClients("VotesHandler", "Enable", "Werewolf", nil)
		-- Handle votation
		self:makeACountDown(self.Configurations["TimeBetweenRounds"]) -- Countdown to change to day
		self:FireAllClients("VotesHandler", "Disable", "Werewolf", nil)
		self:FireAllClients("EnableButtons", false) -- Buttons Deactivated in the dayTime
		self:SetupVotation()
		self:FireAllClients("VotesHandler", "Enable", "Normal", nil)
		-- Handle Votation
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
				string.format("The game need at least %d players", self.Configurations["PlayersToStart"])
			)
			-- Tell everyone that the game can't be started
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
