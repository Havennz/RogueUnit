local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Classes = require(ReplicatedStorage.Shared.Classes)
local Themes = require(ReplicatedStorage.Shared.Themes)
local roundTimer = ReplicatedStorage:WaitForChild("roundTimer")
local VotesFolder = ReplicatedStorage:FindFirstChild("VotesFolder")
local Observers = require(ReplicatedStorage.Packages.Observers)

local PlayerGui = Player:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")
local Exterior: Frame = MainGui.Frame
local Interior: Frame = Exterior.Frame
local Scrolling: ScrollingFrame = Interior.ScrollingFrame

local ButtonConnections = {}

local clientSideController = Knit.CreateController({
	Name = "clientSideController",
})

function formatTime(seconds)
	local minutes = math.floor((seconds % 3600) / 60)
	local seconds = math.floor(seconds % 60)

	local minutesString = string.format("%02d", minutes)
	local secondsString = string.format("%02d", seconds)

	return minutesString .. ":" .. secondsString
end

function clientSideController:UpdateTimer()
	local Timer = MainGui.Frame.Timer
	local valor = roundTimer.Value
	if valor < 0 then
		valor = 0
	end

	Timer.Text = formatTime(valor)
end

function clientSideController:setupButtons(enabled)
	local MainService = Knit.GetService("MainService")

	if enabled == false then
		for _, x: RBXScriptConnection in pairs(ButtonConnections) do
			x:Disconnect()
		end
	else
		for _, x: TextButton in pairs(Scrolling:GetChildren()) do
			if x:IsA("TextButton") and x.Name ~= "Template" then
				local con = x.MouseButton1Click:Connect(function()
					MainService:PlayerInteraction(x.Name)
				end)
				table.insert(ButtonConnections, con)
			end
		end
	end
end

function clientSideController:ChangeText(text)
	local Timer = MainGui.Frame.Timer

	Timer.Text = text
end

function clientSideController:UpdatePlayers()
	local Timer = MainGui.Frame.PlayerCounter

	Timer.Text = (tostring(#Players:GetChildren()) .. "/8")
end

function clientSideController:KillPlayer(playerName)
	for _, x in pairs(Scrolling:GetChildren()) do
		if x:IsA("TextButton") and x.Name == playerName then
			local DP = x:FindFirstChild("DeadDisplay")
			if DP then
				DP.Visible = true
			end
		end
	end
end

function clientSideController:ChatController(bool)
	PlayerGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, bool)
end

function clientSideController:setGameState(str)
	local Text1 = Exterior:WaitForChild("Timer")
	local Text2 = Exterior:WaitForChild("PlayerCounter")

	local exteriorColor = Themes[str]["ExteriorColor"]
	local interiorColor = Themes[str]["InteriorColor"]
	local deepColor = Themes[str]["DeepColor"]
	local buttonColor = Themes[str]["ButtonColor"]
	local nameColor = Themes[str]["NameColor"]
	local textColor = Themes[str]["TextColor"]

	local function applyColor(target, property, color)
		local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local colorTween = TweenService:Create(target, tweenInfo, { [property] = color })
		colorTween:Play()
	end

	applyColor(Exterior, "BackgroundColor3", exteriorColor)
	applyColor(Interior, "BackgroundColor3", interiorColor)
	applyColor(Scrolling, "BackgroundColor3", deepColor)
	applyColor(Text1, "TextColor3", textColor)
	applyColor(Text2, "TextColor3", textColor)

	for _, button: TextButton in pairs(Scrolling:GetChildren()) do
		if button:IsA("TextButton") then
			applyColor(button, "BackgroundColor3", buttonColor)
			applyColor(button.TextLabel, "BackgroundColor3", nameColor)
		end
	end
end

function clientSideController:EnableVotations(type, bool)
	local MainService = Knit.GetService("MainService")

	if bool == true then
		for _, x in pairs(Scrolling:GetChildren()) do
			if x:IsA("TextButton") and x.Name ~= "Template" then
				local TargetFolder = VotesFolder:FindFirstChild(x.Name)
				MainService:GetAlive(x.Name):andThen(function(isAlive)
					print(isAlive)
					if isAlive == true then
						if type == "Werewolf" then
							MainService:GetClass(Player.Name):andThen(function(Classe)
								if Classe == "Werewolf" then
									MainService:GetClass(x.Name):andThen(function(Classe)
										local role = Classe
										if role ~= "Werewolf" then
											Observers.observeAttribute(TargetFolder, "WerewolfVotes", function(value)
												x.Votes.Text = "Werewolf Votes: " .. tostring(value)
												return function() end
											end)
											x.Votes.Visible = true
										end
									end)
								end
							end)
						elseif type == "Normal" then
							Observers.observeAttribute(TargetFolder, "NormalVotes", function(value)
								x.Votes.Text = "Votes: " .. tostring(value)
								return function() end
							end)
							x.Votes.Visible = true
						end
					end
				end)
			end
		end
	else
		for _, x in pairs(Scrolling:GetChildren()) do
			if x:IsA("TextButton") and x.Name ~= "Template" then
				x.Votes.Visible = false
			end
		end
	end
end

function clientSideController:GetNewPlayer(userId)
	local MainService = Knit.GetService("MainService")
	local TargetedPlayer = Players:GetPlayerByUserId(userId)

	if Scrolling:FindFirstChild(TargetedPlayer.Name) then
		return -- Already found this specific player in the list, not adding
	end
	local Template = Scrolling.Template
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420
	local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
	local role
	MainService:GetClass(TargetedPlayer.Name):andThen(function(Classe)
		role = Classe
		if Scrolling:FindFirstChild(TargetedPlayer.Name) then
			return
		else
			local ClonedTemplate = Template:Clone()
			ClonedTemplate.TextLabel.Text = TargetedPlayer.Name
			ClonedTemplate.Name = TargetedPlayer.Name
			ClonedTemplate.ImageLabel.Image = content
			ClonedTemplate.Parent = Scrolling
			ClonedTemplate.Classe.Text = tostring(role) or "Unknown"
			if Classes[role] then
				-- Classes[role] exists, it's safe to access its properties
				ClonedTemplate.Classe.TextColor3 = Classes[role]["NameColor"]
			else
				-- Handle the case where role is not a valid class
				print("Warning: Invalid role:", role)
			end
			ClonedTemplate.Visible = true
		end
	end)
end

function clientSideController:RemovePlayer(playerName)
	local target = Scrolling:FindFirstChild(playerName, true)
	if target then
		target:Destroy()
	end
end

function clientSideController:KnitStart()
	local MainService = Knit.GetService("MainService")
	MainService.PlayerAdded:Connect(function(id)
		self:GetNewPlayer(id)
	end)

	MainService.ChangeTime:Connect(function(str)
		self:setGameState(str)
	end)

	MainService.UpdateCountdown:Connect(function()
		self:UpdateTimer()
	end)

	MainService.UpdatePlayerCount:Connect(function()
		self:UpdatePlayers()
	end)

	MainService.RemovePlayer:Connect(function(playerName)
		self:RemovePlayer(playerName)
	end)

	MainService.ChangeText:Connect(function(str)
		self:ChangeText(str)
	end)

	MainService.EnableButtons:Connect(function(bool)
		self:setupButtons(bool)
	end)

	MainService.ChatController:Connect(function(bool)
		self:ChatController(bool)
	end)

	MainService.VotesHandler:Connect(function(type, version)
		if type == "Enable" then
			self:EnableVotations(version, true)
		elseif type == "Disable" then
			self:EnableVotations(version, false)
		end
	end)

	MainService.KillPlayer:Connect(function(name)
		self:KillPlayer(name)
	end)
end

function clientSideController:KnitInit() end

return clientSideController
