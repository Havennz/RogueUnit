local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")
local Exterior: Frame = MainGui.Frame
local Interior: Frame = Exterior.Frame
local Scrolling: ScrollingFrame = Interior.ScrollingFrame
local Classes = require(ReplicatedStorage.Shared.Classes)
local Themes = require(ReplicatedStorage.Shared.Themes)
local roundTimer = ReplicatedStorage:WaitForChild("roundTimer")
local VotesFolder = ReplicatedStorage:FindFirstChild("VotesFolder")
local Observers = require(ReplicatedStorage.Packages.Observers)

local GUIController = Knit.CreateController({
	Name = "GUIController",
})

function formatTime(seconds)
	local minutes = math.floor((seconds % 3600) / 60)
	local seconds = math.floor(seconds % 60)

	local minutesString = string.format("%02d", minutes)
	local secondsString = string.format("%02d", seconds)

	return minutesString .. ":" .. secondsString
end

function GUIController:UpdateTimer()
	local Timer = MainGui.Frame.Timer
	local valor = roundTimer.Value
	if valor < 0 then
		valor = 0
	end

	Timer.Text = formatTime(valor)
end

function GUIController:WriteMessage(message)
	local endMessage = MainGui.Frame.WinScreen

	endMessage.Text = message
	endMessage.Visible = true
	task.delay(15, function()
		endMessage.Visible = false
	end)
end

function GUIController:setupButtons()
	local InteractionService = Knit.GetService("InteractionService")
	local PlayersService = Knit.GetService("PlayersService")

	for _, x: TextButton in pairs(Scrolling:GetChildren()) do
		if x:IsA("TextButton") and x.Name ~= "Template" then
			PlayersService:GetAlive(Player.Name):andThen(function(isAlive)
				if isAlive then
					x.MouseButton1Click:Connect(function()
						PlayersService:GetAlive(Player.Name):andThen(function(isAlive)
							if isAlive then
								InteractionService:PlayerInteraction(x.Name)
							end
						end)
					end)
				end
			end)
		end
	end
end

function GUIController:ChangeText(text)
	local Timer = MainGui.Frame.Timer

	Timer.Text = text
end

function GUIController:UpdatePlayers()
	local Timer = MainGui.Frame.PlayerCounter

	Timer.Text = (tostring(#Players:GetChildren()) .. "/8")
end

function GUIController:setGameState(str)
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

function GUIController:EnableVotations(type, bool)
	local PlayersService = Knit.GetService("PlayersService")
	local RolesService = Knit.GetService("RolesService")
	if bool == true then
		for _, x in pairs(Scrolling:GetChildren()) do
			if x:IsA("TextButton") and x.Name ~= "Template" then
				local TargetFolder = VotesFolder:FindFirstChild(x.Name)
				PlayersService:GetAlive(x.Name):andThen(function(isAlive)
					if isAlive == true then
						if type == "Werewolf" then
							RolesService:GetClass(Player.Name):andThen(function(Classe)
								if Classe == "Werewolf" then
									RolesService:GetClass(x.Name):andThen(function(Classe)
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

function GUIController:CleanupScrolling()
	for _, x in pairs(Scrolling:GetChildren()) do
		if x:IsA("TextButton") and x.Name ~= "Template" then
			x:Destroy()
		end
	end
end

function GUIController:VerifyIntegrity()
	for _, frame in pairs(Scrolling:GetChildren()) do
		if frame:IsA("TextButton") and frame.Name ~= "Template" then
			local playerFound = false
			for _, player in pairs(Players:GetPlayers()) do
				if frame.Name == player.Name then
					playerFound = true
					break
				end
			end
			if not playerFound then
				frame:Destroy()
			end
		end
	end
end

function GUIController:GetNewPlayer(userId)
	local TargetedPlayer = Players:GetPlayerByUserId(userId)
	local RolesService = Knit.GetService("RolesService")
	if Scrolling:FindFirstChild(TargetedPlayer.Name) then
		return -- Already found this specific player in the list, not adding
	end
	local Template = Scrolling.Template
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420
	local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
	local role
	RolesService:GetClass(TargetedPlayer.Name):andThen(function(Classe)
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
			end
			ClonedTemplate.Visible = true
		end
	end)
end

function GUIController:RemovePlayer(playerName)
	local target = Scrolling:FindFirstChild(playerName, true)
	if target then
		target:Destroy()
	end
end

function GUIController:KnitStart()
	local PlayersService = Knit.GetService("PlayersService")

	PlayersService.PlayerAdded:Connect(function(id)
		self:GetNewPlayer(id)
	end)

	PlayersService.ChangeTime:Connect(function(str)
		self:setGameState(str)
	end)

	PlayersService.UpdateCountdown:Connect(function()
		self:UpdateTimer()
	end)

	PlayersService.UpdatePlayerCount:Connect(function(type)
		if type == nil then
			self:UpdatePlayers()
		elseif type == "Erase" then
			self:CleanupScrolling()
		end
	end)

	PlayersService.RemovePlayer:Connect(function(playerName)
		self:RemovePlayer(playerName)
	end)

	PlayersService.ChangeText:Connect(function(str)
		self:ChangeText(str)
	end)

	PlayersService.EnableButtons:Connect(function(bool)
		self:setupButtons(bool)
	end)

	PlayersService.VotesHandler:Connect(function(type, version)
		if type == "Enable" then
			self:EnableVotations(version, true)
		elseif type == "Disable" then
			self:EnableVotations(version, false)
		end
	end)

	PlayersService.EndMessage:Connect(function(message)
		self:WriteMessage(message)
	end)

	PlayersService.DoubleVerify:Connect(function()
		self:VerifyIntegrity()
	end)
end

function GUIController:KnitInit() end

return GUIController
