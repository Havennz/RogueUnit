local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local clientSideController = Knit.CreateController({
	Name = "clientSideController",
})

function clientSideController:KnitStart()
	local Humanoid: Humanoid = Player.Character:WaitForChild("Humanoid")
	if Humanoid then
		Humanoid.WalkSpeed = 0
	end

	local StarterGui = game:GetService("StarterGui")
	local Success
	while true do
		Success, x = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
		if Success then
			break
		else
			task.wait()
		end --No need to yield if the operation was successful.
	end
end

function clientSideController:KnitInit() end

return clientSideController
