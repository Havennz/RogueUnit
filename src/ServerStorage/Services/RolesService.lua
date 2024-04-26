local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local VotesFolder = ReplicatedStorage:FindFirstChild("VotesFolder")

local RolesService = Knit.CreateService({
	Name = "RolesService",
	Client = {},
})

function shuffle(table)
	local currentIndex = #table
	for i = currentIndex - 1, 1, -1 do
		local randomIndex = math.random(1, i)
		table[i], table[randomIndex] = table[randomIndex], table[i]
	end
	return table
end

function RolesService:GetRole(player1, player2Name)
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

function RolesService.Client:GetClass(player1, player2) -- Player1 é o player tentando acessar a role do player2
	local role
	role = self.Server:GetRole(player1, player2)
	return role
end

function RolesService:setRoles(playersTable, wolfAmount, mediunsAmount)
	local playersInGame = playersTable
	local wolfsAmount = wolfAmount
	local mediunsAmount = mediunsAmount
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

function RolesService:GetAllies(player)
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

function RolesService.Client:ReturnAllies(player)
	return self.Server:GetAllies(player)
end

function RolesService:KnitStart() end

function RolesService:KnitInit() end

return RolesService
