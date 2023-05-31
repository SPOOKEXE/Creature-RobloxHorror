
local function SetProperties( Parent, properties )
	if typeof(Parent) ~= "nil" and typeof(properties) == 'table' then
		for k,v in pairs(properties) do
			Parent[k] = v
		end
	end
	return Parent
end

local function CreateAnimationsFromBase(Overwrite)
	return SetProperties({
		Equipped = 'rbxassetid://0',
		Idled = 'rbxassetid://0',
		Walk = 'rbxassetid://0',
		Ran = 'rbxassetid://0',
		Unequip = 'rbxassetid://0',

		Aimed = 'rbxassetid://0',
		Reload = 'rbxassetid://0',
		Inspect = 'rbxassetid://0',
		Shoot = 'rbxassetid://0',
	}, Overwrite)
end

local function CreateSoundsFromBase(Overwrite)
	return SetProperties({
		Equip = -1,
		Unequip = -1,
		Aim = -1,
		Reload = -1,
		Shoot = -1,
	}, Overwrite)
end

local function FromConfigTemplate( override )
	return SetProperties({
		Type = 'NULL',

		-- Bullet Damage
		Damage = {
			Head = 6,
			UpperTorso = 4,
			LowerTorso = 4,
			Default = 2,
		},

		Firing = {
			Velocity = 400, -- Studs / Second
			Spread = 0.025,
			Firerate = 10, -- Bullets/second
			BulletsCount = 100, -- Bullets in each shot
		},

		-- Gun Ammo
		Ammo = {
			MagazineSize = 1500,
			TotalCapacity = 12000,
			ReloadTime = 2,
		},

		Sounds = CreateSoundsFromBase(),
		Animations = CreateAnimationsFromBase(),
	}, override)
end

-- // Module // --
local Module = {}

Module.Configuration = {
	Pistol_1 = FromConfigTemplate({
		Type = 'Gun',
	}),

	Pistol_2 = FromConfigTemplate({
		Type = 'Gun',
	}),

	Pistol_3 = FromConfigTemplate({
		Type = 'Gun',
	}),

	['S&W_Model_O5'] = FromConfigTemplate({
		Type = 'Gun',
	}),

	PX50_Silenced = FromConfigTemplate({
		Type = 'Gun',
	}),

	PX50S = FromConfigTemplate({
		Type = 'Gun',
	}),

	PX50 = FromConfigTemplate({
		Type = 'Gun',
	}),

	PM18 = FromConfigTemplate({
		Type = 'Gun',
	}),

	PF18 = FromConfigTemplate({
		Type = 'Gun',
	}),

	['FLNT-57'] = FromConfigTemplate({
		Type = 'Gun',
	}),

	--[[MELEE_ID = FromConfigTemplate({
		Type = 'Melee',
	}),]]
}

function Module:GetSpreadAngle(spread_value)
	local RNG = Random.new()
	return
		CFrame.Angles(0, 0, math.pi * 2 * RNG:NextNumber())
		* CFrame.Angles(2 * RNG:NextNumber() * spread_value, 0, 0)
end

function Module:GetConfigFromId( GunId )
	return Module.Configuration[ GunId ]
end

function Module:GetToolConfigurationId( ToolInstance )
	local Configuration = ToolInstance:IsA('Tool') and ToolInstance:FindFirstChild('Config')
	local GunId = Configuration and Configuration:GetAttribute('GunId')
	return GunId, GunId and Module:GetConfigFromId( GunId )
end

return Module
