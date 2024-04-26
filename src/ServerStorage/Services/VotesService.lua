local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local VotesFolder = ReplicatedStorage:FindFirstChild("VotesFolder")

local VotesService = Knit.CreateService({
	Name = "VotesService",
	Client = {},
})

function VotesService:SetupVoting()
	local MainService = Knit.GetService("MainService")
	local function CleanupFolder()
		for _, x in pairs(VotesFolder:GetChildren()) do
			if x then
				x:Destroy()
			end
		end
	end

	CleanupFolder()

	for _, player in pairs(MainService.PlayersInGame) do
		local newFolder = Instance.new("Folder")
		newFolder.Name = player.Name
		newFolder:SetAttribute("NormalVotes", 0)
		newFolder:SetAttribute("WerewolfVotes", 0)
		newFolder.Parent = VotesFolder
	end
end

function VotesService:AddVote(Player, type)
	local target = VotesFolder:FindFirstChild(Player.Name)
	local voteType = type == "Werewolf" and "WerewolfVotes" or type == "Normal" and "NormalVotes"

	if target then
		local currentVotes = target:GetAttribute(voteType) or 0
		target:SetAttribute(voteType, currentVotes + 1)
	end
end

function VotesService:FinishVoting()
	local PlayersService = Knit.GetService("PlayersService")
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
				PlayersService:FireAllClients("KillPlayer", mostVotedPlayerName)
				folder:SetAttribute("Alive", false)
				PlayersService:MuteHandler(false, "solo", mostVotedPlayerName)
				folder:Destroy()
			end
		elseif MostVotedPlayerNames and #MostVotedPlayerNames > 1 then
			-- Empate, não faz nada
		end
	end
end

function VotesService:KnitStart() end

function VotesService:KnitInit() end

return VotesService
