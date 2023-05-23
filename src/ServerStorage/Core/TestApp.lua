
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))

local VFXPresetService = ReplicatedCore.VFXPresetService

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

	--[[task.defer(function()
		local DelayTimer = 2
		while true do
			task.wait(DelayTimer)
			VFXPresetService:CreateArtilleryBlast( Vector3.new(0, 1, 0) )
			DelayTimer = 3
		end
	end)]]

	task.defer(function()
		local DelayTimer = 2
		while true do
			task.wait(DelayTimer)
			for _ = 1, 4 do
				local Pos = Vector3.new( math.random(-16, 16), 1, math.random(-16, 16) )
				VFXPresetService:CreateArtilleryBlast( Pos )
			end
			DelayTimer = 4
		end
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
