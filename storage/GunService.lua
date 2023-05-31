local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local GunFireEvent = RemoteService:GetRemote('GunFire', 'RemoteEvent', false)

local GunConfigurationModule = ReplicatedModules.Data.GunConfiguration
local ProjectileServiceModule = ReplicatedModules.Services.ProjectileService

local SystemsContainer = {}

local ActiveGunCache = { }

-- // Module // --
local Module = {}

function Module:GetPlayerGunCache( LocalPlayer )
	if not ActiveGunCache[LocalPlayer] then
		ActiveGunCache[LocalPlayer] = {
			ActiveId = false,
			ActiveTool = false,
			ActiveConfig = false,
			Active = false,
			LastFireTick = 0,
			GunMaid = ReplicatedModules.Classes.Maid.New(),
		}
	end
	return ActiveGunCache[LocalPlayer]
end

function Module:WeldModelDescendantsToHandle( Model )
	local HandleInstance = Model:FindFirstChild('Handle')
	if not HandleInstance then
		return
	end

	local Descendants = Model:GetDescendants()
	table.insert(Descendants, Model)
	for _, descendant in ipairs( Descendants ) do
		if descendant:IsA('BasePart') and descendant ~= HandleInstance then
			local WeldConstraint = Instance.new('WeldConstraint')
			WeldConstraint.Name = HandleInstance.Name..'_'..descendant.Name
			WeldConstraint.Part0 = HandleInstance
			WeldConstraint.Part1 = descendant
			WeldConstraint.Parent = HandleInstance
		end
	end
end

function Module:PreprocessToolInstance( ToolInstance )
	local Descendants = ToolInstance:GetDescendants()
	table.insert(Descendants, ToolInstance)
	for _, descendant in ipairs( Descendants ) do
		if descendant:IsA('BasePart') then
			if descendant.Name == 'Handle' then
				descendant.Transparency = 1
			end
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
end

function Module:GetGunToolFromId( TargetGunId )
	for _, Tool in ipairs( ServerStorage.Assets.Guns:GetChildren() ) do
		-- if the configuration weapon id matches the target one, that is the tool we are searching for
		local GunId, _ = GunConfigurationModule:GetToolConfigurationId( Tool )
		if GunId and GunId == TargetGunId then
			return Tool
		end
	end
	return nil
end

function Module:UnequipGun( LocalPlayer )
	-- check if there is a weapon to unequip
	local GunCacheData = Module:GetPlayerGunCache( LocalPlayer )
	if not GunCacheData.ActiveId then
		return
	end

	-- unequip stuff
	GunCacheData.ActiveId = false
	GunCacheData.ActiveConfig = false
	GunCacheData.ActiveTool = false
	GunCacheData.GunMaid:Cleanup()
end

function Module:EquipGun( LocalPlayer, ToolInstance, GunId )
	-- unequip their current weapon
	Module:UnequipGun( LocalPlayer )

	-- backup statement to prevent nil values
	if not GunId then
		return
	end

	-- check if the tool is within the character model
	if not ToolInstance:IsDescendantOf(LocalPlayer.Character) then
		return
	end

	-- check for the weapon configuration
	local GunConfiguration = GunConfigurationModule:GetConfigFromId( GunId )
	if not GunConfiguration then
		return
	end

	-- equip their new weapon
	print('Gun Equipped: ', GunId)

	local GunCacheData = Module:GetPlayerGunCache( LocalPlayer )

	GunCacheData.GunMaid:Give(ToolInstance.Activated:Connect(function()
		GunCacheData.Active = true
	end))

	GunCacheData.GunMaid:Give(ToolInstance.Deactivated:Connect(function()
		GunCacheData.Active = false
	end))

	GunCacheData.GunMaid:Give(function()
		GunCacheData.Active = false
	end)

	GunCacheData.Active = false
	GunCacheData.ActiveId = GunId
	GunCacheData.ActiveTool = ToolInstance
	GunCacheData.ActiveConfig = GunConfiguration
end

function Module:GiveGunToPlayer( LocalPlayer, GunId, GunTool )
	-- check for actual gun configuration
	local GunConfiguration = GunConfigurationModule:GetConfigFromId( GunId )
	if not GunConfiguration then
		return
	end

	-- check for the tool
	GunTool = GunTool or Module:GetGunToolFromId( GunId )
	if not GunTool then
		return
	end

	-- check if they already have the tool in their character/backpack
	local ExistantTool = LocalPlayer.Character:FindFirstChild( GunTool.Name ) or LocalPlayer.Backpack:FindFirstChild( GunTool.Name )
	if ExistantTool then
		return
	end

	local GunCacheData = Module:GetPlayerGunCache(LocalPlayer)

	-- append to inventory
	GunTool = GunTool:Clone()
	Module:PreprocessToolInstance( GunTool )
	Module:WeldModelDescendantsToHandle( GunTool )
	GunTool.RequiresHandle = true
	GunTool.ManualActivationOnly = false
	GunTool.CanBeDropped = false
	GunTool.ToolTip = GunId

	GunTool:SetAttribute('CurrentAmmo', GunConfiguration.Ammo.MagazineSize )
	GunTool:SetAttribute('RemainingAmmo', GunConfiguration.Ammo.TotalCapacity )

	GunTool.Equipped:Connect(function()
		task.wait() -- delay for unequip functions
		Module:EquipGun( LocalPlayer, GunTool, GunId )
	end)

	GunTool.Unequipped:Connect(function()
		if GunCacheData.ActiveTool == GunId then
			Module:UnequipGun( LocalPlayer )
		end
	end)

	GunTool.Parent = LocalPlayer.Backpack

	return true
end

function Module:GiveAllGunsToPlayer( LocalPlayer )
	for GunId, _ in pairs( GunConfigurationModule.Configuration ) do
		Module:GiveGunToPlayer( LocalPlayer, GunId )
	end
end

function Module:GiveEveryGunToolToPlayer( LocalPlayer )
	for _, Tool in ipairs( ServerStorage.Assets.Guns:GetChildren() ) do
		local GunId, _ = GunConfigurationModule:GetToolConfigurationId( Tool )
		if GunId then
			Module:GiveGunToPlayer( LocalPlayer, GunId, Tool )
		end
	end
end

function Module:GetActiveGunAmmo(LocalPlayer)
	local PlayerGunCache = Module:GetPlayerGunCache(LocalPlayer)
	return PlayerGunCache.ActiveTool and PlayerGunCache.ActiveTool:GetAttribute('CurrentAmmo') or -1
end

function Module:OnGunFire( LocalPlayer, HandlePosition, FireDirection )
	local ActiveAmmoValue = Module:GetActiveGunAmmo( LocalPlayer )
	if ActiveAmmoValue <= 0 then
		return
	end

	local PlayerGunCache = Module:GetPlayerGunCache(LocalPlayer)
	if time() < PlayerGunCache.LastFireTick then
		return
	end

	PlayerGunCache.ActiveTool:SetAttribute('CurrentAmmo', ActiveAmmoValue - 1)

	local NextTick = time() + (1/PlayerGunCache.ActiveConfig.Firing.Firerate)
	PlayerGunCache.LastFireTick = NextTick

	local DirectionCFrame = CFrame.lookAt( HandlePosition, HandlePosition + FireDirection )

	local DamageDict = PlayerGunCache.ActiveConfig.Damage

	local function OnProjectileHitCallback(projectile, raycastResult)
		if not raycastResult then
			return
		end

		local Humanoid = ProjectileServiceModule:GetHumanoidFromRaycast( raycastResult.Instance, (LocalPlayer.Character or workspace) )
		if not Humanoid then
			return
		end
		Humanoid.Health -= (DamageDict[raycastResult.Instance.Name] or DamageDict.Default)
	end

	for _ = 1, PlayerGunCache.ActiveConfig.Firing.BulletsCount do
		local randomCFrameAngle = GunConfigurationModule:GetSpreadAngle(PlayerGunCache.ActiveConfig.Firing.Spread)
		local BulletCFrame = (DirectionCFrame * randomCFrameAngle)

		local VelocityVector = BulletCFrame.LookVector.Unit * PlayerGunCache.ActiveConfig.Firing.Velocity
		local serverResolver = ProjectileServiceModule:CreateBulletProjectile( LocalPlayer, BulletCFrame.Position, VelocityVector )
		serverResolver:OnProjectileHit(OnProjectileHitCallback)
	end
end

function Module:OnPlayerAdded( LocalPlayer )
	-- if they have spawned already, give them the weapons
	if LocalPlayer.Character then
		--Module:GiveAllGunsToPlayer( LocalPlayer )
		Module:GiveEveryGunToolToPlayer( LocalPlayer )
	end

	-- now each time they spawn, give them the weapons
	LocalPlayer.CharacterAdded:Connect(function()
		--Module:GiveAllGunsToPlayer( LocalPlayer )
		Module:GiveEveryGunToolToPlayer( LocalPlayer )
	end)
end

function Module:OnPlayerRemoving( LocalPlayer )
	Module:UnequipGun( LocalPlayer )
end

function Module:Start()
	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		task.defer(function()
			Module:OnPlayerAdded( LocalPlayer )
		end)
	end

	Players.PlayerAdded:Connect(function( LocalPlayer )
		Module:OnPlayerAdded( LocalPlayer )
	end)

	Players.PlayerRemoving:Connect(function( LocalPlayer )
		Module:OnPlayerRemoving( LocalPlayer )
	end)

	GunFireEvent.OnServerEvent:Connect(function( LocalPlayer, PosX, PosY, PosZ, LookX, LookY, LookZ )
		local HandlePosition = Vector3.new( PosX, PosY, PosZ ) / 1000
		local FiringDirection = Vector3.new( LookX, LookY, LookZ ) / 1000
		Module:OnGunFire( LocalPlayer, HandlePosition, FiringDirection )
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module

