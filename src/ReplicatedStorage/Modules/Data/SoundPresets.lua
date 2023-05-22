
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedAssets = ReplicatedStorage:WaitForChild('Assets')

local SoundsFolder = ReplicatedAssets.Sounds

-- // Module // --
local Module = {}

Module.Presets = {

	ArtilleryExplosion = {

		Explosion1 = {
			Delay = false,
			Properties = {
				Volume = 0.6,
				PlaybackSpeed = 0.9,
			},
		},

		FireballFinish = {
			Delay = 0.3,
			Properties = {
				Volume = 5,
			},
		},

	},

}

function Module:GetPresetFromId( presetId )
	return Module.Presets[ presetId ]
end

return Module
