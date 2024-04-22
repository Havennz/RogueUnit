local Classes = {
	["Werewolf"] = {
		["CanAnalyze"] = false,
		["CanSave"] = false,
		["CanKill"] = true,
		["NameColor"] = Color3.fromRGB(255, 62, 62),
	},
	["Medium"] = {
		["CanAnalyze"] = true,
		["CanSave"] = false,
		["CanKill"] = false,
		["NameColor"] = Color3.fromRGB(85, 210, 255),
	},
	["Villager"] = {
		["CanAnalyze"] = false,
		["CanSave"] = false,
		["CanKill"] = false,
		["NameColor"] = Color3.fromRGB(255, 199, 86),
	},
}

return Classes
