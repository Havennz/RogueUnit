local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local VotesFolder = ReplicatedStorage:FindFirstChild("VotesFolder")

local InteractionService = Knit.CreateService({
	Name = "InteractionService",
	Client = {},
})

function InteractionService:InteractionsRules(rule, player)
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

function InteractionService:Interact(player1, player2)
	local RolesService = Knit.GetService("RolesService")
	local PlayersService = Knit.GetService("PlayersService")
	local VotesService = Knit.GetService("VotesService")
	local MainService = Knit.GetService("MainService")
	if player1 and player2 then
		local role1 = RolesService:GetRole(player1)
		local role2 = RolesService:GetRole(player2.Name)
		if not self:InteractionsRules("checkCooldown", player1) then
			if MainService.Game["Day"] == false then
				if
					PlayersService:GetAliveStat(player1) == false
					or PlayersService:GetAliveStat(player2.Name) == false
				then
					return
				end
				if role1 == "Werewolf" then
					-- Here you can add such features like medic protection
					if role1 ~= role2 then
						VotesService:AddVote(player2, "Werewolf")
						self:InteractionsRules("putInCooldown", player1)
						--self.Client["ChatController"]:Fire(player2, false)
					else
						warn("Werewolf can't kill another werewolf")
					end
				elseif role1 == "Medium" then
					warn(player1.Name .. " got the role: " .. role2 .. " of the player " .. player2.Name)
					PlayersService.Client["RevealRole"]:Fire(player1, player2.Name, role2)
					self:InteractionsRules("putInCooldown", player1)
					-- Add more elseifs to make new roles
				else
					warn("Villagers are not allowed to interact")
				end
			else
				if PlayersService:GetAliveStat(player1) == false then
					return
				end
				VotesService:AddVote(player2, "Normal")
				self:InteractionsRules("putInCooldown", player1)
			end
		end
	else
		warn("Something is wrong, Probably one of the players leaved in the middle of the interaction")
	end
end

function InteractionService.Client:PlayerInteraction(player1, player2Name)
	local player2 = Players:FindFirstChild(player2Name)
	if player1 and player2 then
		self.Server:Interact(player1, player2)
	end
end

function InteractionService:KnitStart() end

function InteractionService:KnitInit() end

return InteractionService
