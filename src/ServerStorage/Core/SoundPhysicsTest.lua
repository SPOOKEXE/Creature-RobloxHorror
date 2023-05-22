
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))

local VFXPresetService = ReplicatedCore.VFXPresetService

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

	task.defer(function()
		while true do
			task.wait(1)
			VFXPresetService:CreateArtilleryBlast( Vector3.new(0, 5, 0) )
		end
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
