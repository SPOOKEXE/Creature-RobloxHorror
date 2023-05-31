local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local ProjectileServiceModule = ReplicatedModules.Services.ProjectileService
local VisualizersModule = ReplicatedModules.Utility.Visualizers

local SystemsContainer = {}

local beamProperties = { Color = ColorSequence.new(Color3.new(1,1,1)) }
local sharedOrigin = Vector3.new(0, 20, 0)

-- // Module // --
local Module = {}

function Module:SummonPreviewProjectile()
	local randomVelocity = Vector3.new( math.random(-40, 40), math.random(-20, 20), math.random(-40, 40))

	local projectileData = ProjectileServiceModule:CreateBulletProjectile(LocalPlayer, sharedOrigin, randomVelocity)
	projectileData.Lifetime = 4

	--[[projectileData:SetTerminatedFunction(function()
		VisualizersModule:Attachment(projectileData.Position, 1)
	end)]]

	local beamInstance = VisualizersModule:Beam(
		projectileData._initPosition,
		projectileData._initPosition + (projectileData._initVelocity * 0.01),
		false,
		beamProperties
	)

	projectileData:SetTerminatedFunction(function()
		beamInstance.Attachment0:Destroy()
		beamInstance.Attachment1:Destroy()
	end)

	local bounceCounter = 0
	projectileData:SetRayOnHitFunction( function()
		bounceCounter += 1
		if bounceCounter < 2 then
			return 2 -- bounce of the surface
		end
		return 3 -- 3 = stop at this point
	end )

	local LastPosition = projectileData._initPosition
	local timeElapsed = 0
	projectileData:SetUpdatedFunction(function(self, stepData)
		timeElapsed += stepData.DeltaTime
		if timeElapsed < 0.02 then
			return
		end
		timeElapsed = 0

		beamInstance.Attachment0.WorldPosition = LastPosition
		beamInstance.Attachment1.WorldPosition = stepData.AfterPosition
		LastPosition = stepData.AfterPosition
	end)
end

function Module:BouncyProjectileTest( ShooterCFrame )
	local data2 = ProjectileServiceModule:CreateBulletProjectile( LocalPlayer, ShooterCFrame.Position, ShooterCFrame.LookVector * 20 * math.random() )
	data2.Lifetime = 15
	data2:SetAcceleration( -Vector3.new( 0, workspace.Gravity * 0.15, 0 ) )
	local bounceCounter = 0
	data2:SetRayOnHitFunction( function()
		bounceCounter += 1
		if bounceCounter < 30 then
			return 2 -- bounce of the surface
		end
		return 3 -- 3 = stop at this point
	end)
end

function Module:PenetrationProjectileTest( ShooterCFrame )
	local data1 = ProjectileServiceModule:CreateBulletProjectile( LocalPlayer, ShooterCFrame.Position, ShooterCFrame.LookVector * 50 )
	data1:SetRayOnHitFunction( function()
		return 1
	end)
end

function Module:Start()
	--[[
		ProjectileServiceModule:SetGlobalTimeScale(0.1)
		ProjectileServiceModule:SetGlobalAcceleration( Vector3.new() )
		-- ProjectileServiceModule:SetStepIterations(4)
	]]

	task.defer(function()
		while true do
			task.wait(1)
			-- penetration test
			Module:PenetrationProjectileTest( workspace.Shoot1.CFrame )
			Module:PenetrationProjectileTest( workspace.Shoot2.CFrame )
			Module:PenetrationProjectileTest( workspace.Shoot3.CFrame )
			-- bouncing test
			Module:BouncyProjectileTest( workspace.Shoot4.CFrame )
			Module:BouncyProjectileTest( workspace.Shoot5.CFrame )
		end
	end)

	--[[task.defer(function()
		while true do
			task.wait(0.5)
			for _ = 1, 250 do
				Module:SummonPreviewProjectile()
			end
		end
	end)]]
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module