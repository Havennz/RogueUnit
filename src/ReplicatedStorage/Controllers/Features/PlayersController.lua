local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")
local Exterior: Frame = MainGui.Frame
local Interior: Frame = Exterior.Frame
local Scrolling: ScrollingFrame = Interior.ScrollingFrame
local Classes = require(ReplicatedStorage.Shared.Classes)

local PlayersController = Knit.CreateController({
	Name = "PlayersController",
})

function PlayersController:RevealRole(name, role) -- Prior exploiter protection here
	for _, x: TextButton in pairs(Scrolling:GetChildren()) do
		if x:IsA("TextButton") and x.Name ~= "Template" and x.Name == name then
			if Classes[role] then
				x.Classe.TextColor3 = Classes[role]["NameColor"]
			end
			x.Classe.Text = role
		end
	end
end

function PlayersController:KillPlayer(playerName)
	for _, x in pairs(Scrolling:GetChildren()) do
		if x:IsA("TextButton") and x.Name == playerName then
			local DP = x:FindFirstChild("DeadDisplay")
			if DP then
				DP.Visible = true
			end
		end
	end
end

function PlayersController:ChatController(bool)
	local StarterGui = game:GetService("StarterGui")
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, bool)
end

function PlayersController:KnitStart()
	local PlayersService = Knit.GetService("PlayersService")
	PlayersService.KillPlayer:Connect(function(name)
		self:KillPlayer(name)
	end)

	PlayersService.RevealRole:Connect(function(name, role)
		self:RevealRole(name, role)
	end)

	PlayersService.ChatController:Connect(function(bool)
		self:ChatController(bool)
	end)
end

function PlayersController:KnitInit() end

return PlayersController
