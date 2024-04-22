local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Services = ServerStorage.Services

for _, module in pairs(Services:GetDescendants()) do
	if module:IsA("ModuleScript") and string.match(module.Name, "Service$") then
		require(module)
	end
end

Knit.Start():catch(warn)
