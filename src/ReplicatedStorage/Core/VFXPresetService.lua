
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local SoundPhysicsService = ReplicatedModules.Services.SoundPhysics
local VFXService = ReplicatedModules.Services.VFXService

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:CreateArtilleryBlast( Position )
	-- create vfx
	VFXService:CreateRockCrater( Position )
	VFXService:CreateFlyingRockDebrisWithTrail( Position )
	VFXService:CreateExplosionFireballParticles( Position )
	VFXService:CreateFlyingFireTrails( Position )
	-- play sounds
	SoundPhysicsService:PlayPresetEffect('ArtilleryExplosion', Position)
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module

