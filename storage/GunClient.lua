local RunService = game:GetService('RunService')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalMouse = LocalPlayer:GetMouse()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local GunFireEvent = RemoteService:GetRemote('GunFire', 'RemoteEvent', false)

local GunConfigurationModule = ReplicatedModules.Data.GunConfiguration

local SystemsContainer = {}

local WHITELISTED_LIMBS = { 'LeftHand', 'LeftLowerArm', 'LeftUpperArm', 'RightHand', 'RightLowerArm', 'RightUpperArm', 'Left Arm', 'Right Arm' }

local ActiveGunData = { GunId = false, Tool = false, Config = false, }
local GunMaidInstance = ReplicatedModules.Classes.Maid.New()

-- // Module // --
local Module = {}

function Module:HasGunEquipped()
	return ActiveGunData.GunId ~= false
end

function Module:GetCurrentGunAmmo()
	return ActiveGunData.Tool and ActiveGunData.Tool:GetAttribute('CurrentAmmo') or -1
end

function Module:UpdateLocalLimbModifier()
	local ActiveCharacterInstance = LocalPlayer.Character
	if not ActiveCharacterInstance then
		return
	end

	for _, basePart in ipairs(ActiveCharacterInstance:GetChildren()) do
		if basePart:IsA('BasePart') and table.find(WHITELISTED_LIMBS, basePart.Name) then
			basePart.LocalTransparencyModifier = 0
		end
	end
end

function Module:GetGunPosition()
	local HandleInstance = ActiveGunData.Tool and ActiveGunData.Tool:FindFirstChild('Handle')
	return HandleInstance and HandleInstance.Position
end

function Module:StartGunFireLoop()
	local Interval = (1 / ActiveGunData.Config.Firing.Firerate)

	while Module:HasGunEquipped() and ActiveGunData.Active do
		local CurrentAmmo = Module:GetCurrentGunAmmo()
		if CurrentAmmo <= 0 then
			break
		end

		local HandlePosition = Module:GetGunPosition()
		if HandlePosition then
			local FireDirection = CFrame.lookAt( HandlePosition, LocalMouse.Hit.Position).LookVector * 1000
			HandlePosition *= 1000
			GunFireEvent:FireServer(
				math.floor(HandlePosition.X), math.floor(HandlePosition.Y), math.floor(HandlePosition.Z),
				math.floor(FireDirection.X), math.floor(FireDirection.Y), math.floor(FireDirection.Z)
			)
		end
		task.wait( Interval )
	end
end

function Module:OnGunEquipped( ToolInstance, GunId, GunConfig )
	if not ToolInstance then
		print('Gun Unequipped - ', ActiveGunData.GunId)
	end
	ActiveGunData.Tool = ToolInstance
	ActiveGunData.GunId = GunId
	ActiveGunData.Config = GunConfig
	ActiveGunData.Active = false
	if ToolInstance then
		print('Gun Equipped - ', GunId)

		GunMaidInstance:Give(ToolInstance.Activated:Connect(function()
			ActiveGunData.Active = true
			Module:StartGunFireLoop()
		end))

		GunMaidInstance:Give(ToolInstance.Deactivated:Connect(function()
			ActiveGunData.Active = false
		end))

		GunMaidInstance:Give(ToolInstance.Unequipped:Connect(function()
			ActiveGunData.Active = false
		end))
	end
end

function Module:OnCharacterAdded( CharacterInstance )
	CharacterInstance.ChildAdded:Connect(function( ToolInstance )
		task.wait()
		if ToolInstance:IsA('Tool') then
			local GunId, GunConfig = GunConfigurationModule:GetToolConfigurationId( ToolInstance )
			if not GunId then
				return
			end
			Module:OnGunEquipped( ToolInstance, GunId, GunConfig )
		end
	end)

	CharacterInstance.ChildRemoved:Connect(function( ToolInstance )
		if ToolInstance:IsA('Tool') then
			Module:OnGunEquipped( false, false, false )
		end
	end)
end

function Module:Start()
	if LocalPlayer.Character then
		task.defer(function()
			Module:OnCharacterAdded( LocalPlayer.Character )
		end)
	end

	LocalPlayer.CharacterAdded:Connect(function(CharacterInstance)
		Module:OnCharacterAdded( CharacterInstance )
	end)

	RunService.RenderStepped:Connect(function()
		if Module:HasGunEquipped() then
			Module:UpdateLocalLimbModifier()
		end
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module

