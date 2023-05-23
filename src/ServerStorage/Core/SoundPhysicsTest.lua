
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))

local VFXPresetService = ReplicatedCore.VFXPresetService

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

	task.defer(function()
		local DelayTimer = 2
		while true do
			task.wait(DelayTimer)
			VFXPresetService:CreateArtilleryBlast( Vector3.new(0, 1, 0) )
			DelayTimer = 3
		end
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
