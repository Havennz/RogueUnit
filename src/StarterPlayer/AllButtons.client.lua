-- Made by Alec (Miratie) 2022

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Menu = script.Parent

-- Tabela para armazenar os debounces
local cooldowns = {}

-- Função para animar o botão quando o mouse entra
local function onButtonHoverIn(button)
	button = button.Parent
	-- Verifica se há um debounce ativo para o botão
	if cooldowns[button] then
		return
	end
	local scale = 1.1
	-- Cria o debounce para o botão
	cooldowns[button] = true

	-- Configuração de animação
	local originalSize = button.Size
	local newSize = UDim2.new(
		originalSize.X.Scale * scale,
		originalSize.X.Offset,
		originalSize.Y.Scale * scale,
		originalSize.Y.Offset
	)
	local tweenInfo = TweenInfo.new(0.1)

	-- Animação de crescimento
	local tween = TweenService:Create(button, tweenInfo, { Size = newSize })
	tween:Play()

	-- Escuta o evento de mouse saindo do botão para retornar ao tamanho original
	local mouseLeaveConn
	mouseLeaveConn = button.MouseLeave:Connect(function()
		-- Animação de retorno ao tamanho original
		TweenService:Create(button, tweenInfo, { Size = originalSize }):Play()

		-- Remove o debounce e desconecta o evento de mouse
		cooldowns[button] = nil
		mouseLeaveConn:Disconnect()
	end)
end

function arredondar(numero, casas)
	local formato = string.format("%%.%df", casas)
	return tonumber(string.format(formato, numero))
end

local function onButtonHoverInForSmallButtons(button)
	local nomeTratado = button.Parent.Name:gsub("%d+", "")
	-- Verifica se há um debounce ativo para o botão
	if cooldowns[button] then
		return
	end

	local scale = 1.1

	-- Cria o debounce para o botão
	cooldowns[button] = true

	-- Configuração de animação
	local originalSize = button.Size
	local originalPosition = button.Position
	local newSize = UDim2.new(
		originalSize.X.Scale * scale,
		originalSize.X.Offset * scale,
		originalSize.Y.Scale * scale,
		originalSize.Y.Offset * scale
	)
	local sizeDifference = newSize - originalSize
	local newPosition = originalPosition

	if nomeTratado ~= "Container" then
		newPosition = UDim2.new(
			originalPosition.X.Scale - sizeDifference.X.Scale / 2,
			originalPosition.X.Offset - sizeDifference.X.Offset / 2,
			originalPosition.Y.Scale - sizeDifference.Y.Scale / 2,
			originalPosition.Y.Offset - sizeDifference.Y.Offset / 2
		)
	end

	local tweenInfo = TweenInfo.new(0.1)

	-- Animação de crescimento
	local tween = TweenService:Create(button, tweenInfo, { Size = newSize, Position = newPosition })
	tween:Play()

	-- Escuta o evento de mouse saindo do botão para retornar ao tamanho original
	local mouseLeaveConn
	mouseLeaveConn = button.MouseLeave:Connect(function()
		-- Animação de retorno ao tamanho original
		TweenService:Create(button, tweenInfo, { Size = originalSize, Position = originalPosition }):Play()

		-- Remove o debounce e desconecta o evento de mouse
		cooldowns[button] = nil
		mouseLeaveConn:Disconnect()
	end)
end

local function findImageButtons(model)
	local imageButtons = {}

	for _, x in pairs(model:GetDescendants()) do
		if x:IsA("Frame") or x:IsA("ImageButton") or x:IsA("TextButton") or x:IsA("ImageLabel") then
			local attCount = x:GetAttributes()
			if attCount["Frame"] then
				table.insert(imageButtons, x)
			end
		end
	end
	return imageButtons
end

function SetupEverything()
	local Buttons = findImageButtons(Menu)

	local function checkIfIsLarge(button)
		local is = false

		for _, x in pairs(button:GetChildren()) do
			if x:IsA("BoolValue") then
				is = true
			end
		end
		return is
	end

	for _, button: Frame in ipairs(Buttons) do
		if checkIfIsLarge(button) == true then
			button.MouseEnter:Connect(function()
				onButtonHoverIn(button)
			end)
		else
			button.MouseEnter:Connect(function()
				onButtonHoverInForSmallButtons(button)
			end)
		end
	end
end

SetupEverything()
