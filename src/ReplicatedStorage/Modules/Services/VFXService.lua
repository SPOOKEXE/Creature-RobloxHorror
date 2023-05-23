local Debris = game:GetService('Debris')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')

local SystemsContainer = {}

local VFXFolder = Instance.new('Folder')
VFXFolder.Name = 'VFXContainer'
VFXFolder.Parent = workspace

local ROT_45_X = CFrame.Angles(math.rad(45), 0, 0)
local disappearTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine)

local IgnoreParams = RaycastParams.new()
IgnoreParams.FilterType = Enum.RaycastFilterType.Exclude
IgnoreParams.IgnoreWater = true

local function GetVFXIgnoreList()
	local IgnoreList = { VFXFolder }
	-- player characters
	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		if LocalPlayer.Character then
			table.insert(IgnoreList, LocalPlayer.Character)
		end
	end
	return IgnoreList
end

local function GetSpreadVector( DirectionCFrame, SpreadFactor )
	local RNG = Random.new()
	return DirectionCFrame * CFrame.Angles(0, 0, math.pi * 2 * RNG:NextNumber()) * CFrame.Angles(2 * RNG:NextNumber() * SpreadFactor, 0, 0)
end

local function GetObjectMass( Model )
	local Mass = 0
	for _, BasePart in ipairs( Model:GetDescendants() ) do
		if BasePart:IsA('BasePart') then
			Mass += BasePart:GetMass()
		end
	end
	return Mass

end

-- // Module // --
local Module = {}

function Module:CreateRockCrater( Position, CircularRockCount, Radius, Duration )
	assert( typeof(Position) == "Vector3", "Passed Position must be a Vector3." )

	CircularRockCount = CircularRockCount or 36
	Radius = Radius or 9
	Duration = Duration or 1

	local BLOCK_ROCKY_PART = ReplicatedAssets.Models.BlockyRock
	IgnoreParams.FilterDescendantsInstances = GetVFXIgnoreList()
	local RockInstances = { }

	-- generate rocks
	local ANGLE_STEP = (360 / CircularRockCount)
	for rockIndex = 0, CircularRockCount do
		-- find the circular offset from the center
		local angle = ANGLE_STEP * rockIndex
		local dirX = Radius * math.sin(angle)
		local dirY = Radius * math.cos(angle)
		local horizontalOffset = Vector3.new(dirX, -BLOCK_ROCKY_PART.Size.Y/2, dirY)

		-- get values for positioning
		local rockPosition = Position + horizontalOffset
		local verticalOffset = rockPosition + Vector3.new(0, 5, 0)

		-- raycast down to find rock y position
		local RayResult = workspace:Raycast( verticalOffset, Vector3.new(0, -8, 0), IgnoreParams )
		if not RayResult then
			continue
		end

		-- rock cframe
		local outwardDirection = CFrame.lookAt(rockPosition, rockPosition + horizontalOffset).LookVector
		local rockCFrame = CFrame.lookAt(RayResult.Position, RayResult.Position + outwardDirection)
		rockCFrame = rockCFrame * ROT_45_X

		-- create the rock
		local BlockRockInstance = BLOCK_ROCKY_PART:Clone()
		BlockRockInstance.Transparency = RayResult.Instance.Transparency
		BlockRockInstance.Color = RayResult.Instance.Color
		BlockRockInstance.Material = RayResult.Instance.Material
		BlockRockInstance.CFrame = rockCFrame - Vector3.new(0, 1, 0)
		BlockRockInstance.Size *= math.random(90, 110)/100
		BlockRockInstance.Parent = VFXFolder

		-- add to array for disappear tween after duration
		table.insert(RockInstances, BlockRockInstance)
	end

	-- rock disappearing after duration
	task.delay(Duration, function()
		for _, RockPart in ipairs( RockInstances ) do
			TweenService:Create( RockPart, disappearTweenInfo, {Transparency = 1} ):Play()
		end
	end)
end

function Module:CreateFlyingRockDebris( Position, Count, Speed, Size, Direction, Spread )
	assert( typeof(Position) == "Vector3", "Passed Position must be a Vector3." )

	Count = Count or 12
	Speed = Speed or 40
	Size = Size or Vector3.new(1.15, 1.15, 1.15)
	Direction = Direction or Vector3.new(0, 1, 0)
	Spread = Spread or 0.4

	local RockDirectionCF = CFrame.lookAt( Position, Position + Direction.Unit )
	local BLOCK_ROCKY_PART = ReplicatedAssets.Models.BlockyRock:Clone()
	BLOCK_ROCKY_PART.Anchored = false
	BLOCK_ROCKY_PART.CanCollide = true
	BLOCK_ROCKY_PART.CanTouch = false
	BLOCK_ROCKY_PART.CanQuery = false
	BLOCK_ROCKY_PART.Massless = true

	local RayResult = workspace:Raycast( Position + Vector3.new(0, 3, 0), Vector3.new(0, -8, 0), IgnoreParams )
	if RayResult then
		BLOCK_ROCKY_PART.Transparency = RayResult.Instance.Transparency
		BLOCK_ROCKY_PART.Color = RayResult.Instance.Color
		BLOCK_ROCKY_PART.Material = RayResult.Instance.Material
	end

	local WeightMultiplier = workspace.Gravity / (1/BLOCK_ROCKY_PART:GetMass())
	local RockSpeed = math.min(Speed * WeightMultiplier, Speed + 30)

	local RockInstances = {}
	for _ = 1, Count do
		local DirectionVector = GetSpreadVector( RockDirectionCF, Spread ).LookVector

		local BlockRockInstance = BLOCK_ROCKY_PART:Clone()
		BlockRockInstance.Position = RayResult and RayResult.Position or Position
		BlockRockInstance.Size = Size
		BlockRockInstance.Velocity = DirectionVector * RockSpeed
		BlockRockInstance.Parent = VFXFolder
		table.insert(RockInstances, BlockRockInstance)
	end

	BLOCK_ROCKY_PART:Destroy()
	task.delay(3.5, function()
		for _, RockPart in ipairs( RockInstances ) do
			TweenService:Create(RockPart, disappearTweenInfo, {Transparency = 1, Size = Vector3.zero }):Play()
		end
	end)

	return RockInstances
end

function Module:CreateFlyingRockDebrisWithTrail(...)
	-- create all the block instances
	local RockInstances = Module:CreateFlyingRockDebris(...)

	-- clone all the particles in each rock
	local ParticleEffects = { }
	for _, RockInstance in ipairs( RockInstances ) do
		local Att0 = Instance.new('Attachment')
		Att0.Position = Vector3.new(0, 0.2, 0)
		Att0.Parent = RockInstance
		local Att1 = Instance.new('Attachment')
		Att1.Position = Vector3.new(0, -0.2, 0)
		Att1.Parent = RockInstance
		local Effect = ReplicatedAssets.Effects.DustTrail:Clone()
		Effect.Attachment0 = Att0
		Effect.Attachment1 = Att1
		Effect.Parent = RockInstance
		table.insert( ParticleEffects, Effect )
	end

	-- after the delay, disable the particles
	task.delay(1.7, function()
		for _, Effect in ipairs( ParticleEffects ) do
			Effect.Enabled = false
		end
	end)
end

function Module:CreateFlyingFireTrails( Position, Count, Speed, Direction, Spread )
	assert( typeof(Position) == "Vector3", "Passed Position must be a Vector3." )

	Count = Count or 6
	Speed = Speed or 30
	Direction = Direction or Vector3.new(0, 1, 0)
	Spread = Spread or 0.4

end

function Module:CreateExplosionFireballParticles( Position )
	-- create the particle attachment
	local Att0 = Instance.new('Attachment')
	Att0.WorldPosition = Position
	Att0.Parent = workspace.Terrain
	-- explosion fireball particle emitter
	local ExplosionFireball = ReplicatedAssets.Effects.ExplosionFireball:Clone()
	ExplosionFireball.Parent = Att0
	ExplosionFireball:Emit(10)
	-- debris the particle emitter
	Debris:AddItem(Att0, ExplosionFireball.Lifetime.Max)
end

return Module
