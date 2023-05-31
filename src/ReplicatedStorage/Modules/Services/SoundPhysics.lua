
local Debris = game:GetService('Debris')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')

local SoundsFolder = ReplicatedAssets.Sounds

local DataModule = require(script.Parent.Parent.Data)
local SoundPresetsData = DataModule.SoundPresets

local MaterialDampeningValues = {
	Default = 0.8, -- 20% reduction
}

local SCATTER_RAY_COUNT = 4

local RayDirectionVectors = { } do
	local function map(value, istart, istop, ostart, ostop)
		return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
	end
	local N_POINTS_CIRCUMFERENCE = 8
	for i = 1, N_POINTS_CIRCUMFERENCE do
		local lon = map(i, 0, N_POINTS_CIRCUMFERENCE, -math.pi, math.pi)
		for j = 1, N_POINTS_CIRCUMFERENCE do
			local lat = map(j, 0, N_POINTS_CIRCUMFERENCE, -math.pi, math.pi)
			local x = math.sin(lon) * math.cos(lat)
			local y = math.sin(lon) * math.sin(lat)
			local z = math.cos(lon)
			table.insert(RayDirectionVectors, Vector3.new(x, y, z))
		end
	end
end

local function GetMaterialDampenValue( MaterialName )
	return MaterialDampeningValues[ MaterialName ] or MaterialDampeningValues.Default
end

local function GetReflectionDirectionVectors( Normal )
	local Vectors = {}
	for _, Vec3 in ipairs( RayDirectionVectors ) do
		if Vec3:Dot( Normal ) > 0 then
			table.insert(Vectors, Vec3)
		end
	end
	return Vectors
end

local function SetProperties( TargetInstance, Properties )
	if typeof(Properties) == "table" then
		for propName, propValue in pairs( Properties ) do
			TargetInstance[ propName ] = propValue
		end
	end
	return TargetInstance
end

local function CreateSoundCloneAttachment( SoundInstance, Position )
	SoundInstance = SoundInstance:Clone()
	local Attachment = Instance.new('Attachment')
	Attachment.Name = time()
	Attachment.Visible = true
	Attachment.WorldPosition = Position
	Attachment.Parent = workspace.Terrain
	return SoundInstance, Attachment
end

--[[local function RecursiveRaycast( SoundInstance, SoundData, Position, RayDirection, RaycastParam, Depth )
	RaycastParam = RaycastParam or RaycastParams.new()
	Depth = Depth or 1
	if Depth > 4 then
		return
	end

	local RayResult = workspace:Raycast( Position, RayDirection, RaycastParam )
	if RayResult then
		-- dampen volume
		SoundInstance.Volume *= GetMaterialDampenValue( RayResult.Material )
		-- hit something, reflect waves after dampening
		local ReflectionVectors = GetReflectionDirectionVectors( RayResult.Normal )
		for _, Direction in ipairs( ReflectionVectors ) do
			task.defer(RecursiveRaycast, SoundInstance, SoundData, RayResult.Position, Direction, RaycastParam, Depth + 1)
		end
	end
end]]

-- // Module // --
local Module = {}

function Module:GetMaterialDampeningValue( MaterialName )
	return GetMaterialDampenValue( MaterialName )
end

function Module:RecursiveSoundWaveRaycast( Position, Direction, SoundInstance, SoundData )

end

function Module:PlaySoundData( SoundInstance, SoundData, Position )
	-- clone the sound instance and set properties
	local CloneSound, Attachment = CreateSoundCloneAttachment( SoundInstance, Position )
	SetProperties(CloneSound, SoundData.Properties)
	-- if we need to delay, delay it
	local DebrisDuration = 1 + SoundInstance.TimeLength
	if SoundData.Delay and SoundData.Delay > 0 then
		-- increment debris timer
		DebrisDuration = DebrisDuration + SoundData.Delay
		-- delay before playing
		task.delay( SoundData.Delay, function()
			CloneSound:Play()
		end)
	else -- otherwise play the sound
		CloneSound:Play()
	end
	-- add debris
	Debris:AddItem(Attachment, DebrisDuration)
end

function Module:PlayPresetEffect( PresetId, Position )

	local PresetIdConfig = SoundPresetsData:GetPresetFromId('ArtilleryExplosion')
	assert( typeof(PresetIdConfig) == "table", "Preset config does not exist for preset of id "..tostring(PresetId) )

	-- for each sound in the preset
	for SoundName, SoundData in pairs( PresetIdConfig ) do
		-- find the sound instance
		local SoundInstance = SoundsFolder:FindFirstChild( SoundName )
		if not SoundInstance then
			error('Cannot find sound for preset data, '..SoundName)
		end
		-- play that preset sound
		Module:PlaySoundData( SoundInstance, SoundData, Position )
	end
end

return Module
