local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local ChunkLoaderSettings = ReplicatedModules.Data.ChunkLoaderSettings
local QuadTreeClass = ReplicatedModules.Classes.QuadTree

local CurrentCamera = workspace.CurrentCamera

local SystemsContainer = {}

local RenderNodeQuadTree = false
local VisibleBoundaryRectangle = false
local QuadTreeMaidInstance = ReplicatedModules.Classes.Maid.New()

local RenderCacheFolder = Instance.new('Folder')
RenderCacheFolder.Name = 'RenderCacheFolder'
RenderCacheFolder.Parent = ReplicatedStorage

local NodeToInstanceArray = {}
local InstanceCache = {}

-- TODO: test this system with a large amount of nodes,
-- and see if it's worth it to use PivotTo to 'hide' the Instances
-- (especially on mobile / console)

--local SuperFarCFrameValue = CFrame.new(9e99, 9e99, 9e99)

-- // Module // --
local Module = {}

Module.RENDER_DISTANCE = ChunkLoaderSettings.DEFAULT_RENDER_DISTANCE
Module.UPDATE_INTERVAL = ChunkLoaderSettings.DEFAULT_UPDATE_INTERVAL

function Module:SetRenderDistance(distance)
	Module.RENDER_DISTANCE = distance
	if VisibleBoundaryRectangle then
		VisibleBoundaryRectangle.w = distance
		VisibleBoundaryRectangle.h = distance
	end
end

function Module:SetupNodeInstanceCache()
	for _, RenderNodePart in ipairs( CollectionService:GetTagged('RenderNodeInstances') ) do
		if NodeToInstanceArray[RenderNodePart] then
			continue
		end
		NodeToInstanceArray[RenderNodePart] = { }

		for _, Child in ipairs( RenderNodePart:GetChildren() ) do
			if (not Child:IsA('ObjectValue')) or Child.Name ~= 'PropsModel' then
				continue
			end

			local TargetInstance = Child.Value
			if not TargetInstance then
				warn('Render Node Part has no PropsModel Value: ' .. RenderNodePart:GetFullName())
				continue
			end

			if not InstanceCache[TargetInstance] then
				local CacheData = { Active = false }
				--[[if TargetInstance:IsA('PVInstance') then
					CacheData.PVOrigin = TargetInstance:GetPivot()
					TargetInstance:PivotTo( SuperFarCFrameValue )
				else]]
					CacheData.VisibleParent = TargetInstance.Parent
					TargetInstance.Parent = RenderCacheFolder
				--end
				InstanceCache[TargetInstance] = CacheData
			end

			if not table.find( NodeToInstanceArray[RenderNodePart], TargetInstance ) then
				table.insert( NodeToInstanceArray[RenderNodePart], TargetInstance )
			end
		end
	end
end

function Module:GetActiveQuadTreePointData()
	local PointData = {}

	for RenderNodePart, InstanceArray in pairs( NodeToInstanceArray ) do
		local NodeType = RenderNodePart:GetAttribute('RenderType')
		local NodePosition = RenderNodePart.Position

		if (not NodeType) or NodeType == 'RenderPoint' then
			local NodePoint = QuadTreeClass.Point.New(NodePosition.x, NodePosition.z)
			NodePoint._data = { ReferenceInstances = InstanceArray }
			table.insert(PointData, NodePoint)
		elseif NodeType == 'RenderRegion' then
			local NodeSize = RenderNodePart.Size
			local NodeRect = QuadTreeClass.Rectangle.New(NodePosition.X - NodeSize.X/2, NodePosition.Z - NodeSize.Z/2, NodeSize.X, NodeSize.Z)
			NodeRect._data = { ReferenceInstances = InstanceArray }
			table.insert(PointData, NodeRect)
		end
	end

	return PointData
end

function Module:EnableQuadTreeRenderer()
	RenderNodeQuadTree = QuadTreeClass.QuadTree.New({ capacity = 8, boundary = QuadTreeClass.Rectangle.New(0,0,4096,4096) })
	VisibleBoundaryRectangle = QuadTreeClass.Rectangle.New(0, 0, Module.RENDER_DISTANCE, Module.RENDER_DISTANCE)

	local NodePoints = Module:GetActiveQuadTreePointData()
	--print(NodePoints)
	RenderNodeQuadTree:InsertArray(NodePoints)

	local _t = time()
	-- whilst the renderer system is enabled
	QuadTreeMaidInstance:Give(RunService.Heartbeat:Connect(function()
		-- only update after the specified interval
		if time() - _t < Module.UPDATE_INTERVAL then
			return
		end
		_t = time()

		for _, Data in pairs(InstanceCache) do
			Data.Active = false
		end

		local CharacterCFrame = LocalPlayer.Character and LocalPlayer.Character:GetPivot()
		if CharacterCFrame then
			VisibleBoundaryRectangle.x = CharacterCFrame.X
			VisibleBoundaryRectangle.y = CharacterCFrame.Z
			local CharacterPoints = RenderNodeQuadTree:Query(VisibleBoundaryRectangle)
			-- any points that are visible to the character are active
			for _, point in ipairs( CharacterPoints ) do
				for _, ReferenceInstance in ipairs( point._data.ReferenceInstances ) do
					InstanceCache[ ReferenceInstance ].Active = true
				end
			end
		end

		VisibleBoundaryRectangle.x = CurrentCamera.CFrame.X
		VisibleBoundaryRectangle.y = CurrentCamera.CFrame.Z
		local CameraPoints = RenderNodeQuadTree:Query(VisibleBoundaryRectangle)
		-- any points that are visible to the camera are active
		for _, point in ipairs( CameraPoints ) do
			-- TODO: check if within FOV, otherwise do not set active
			for _, ReferenceInstance in ipairs( point._data.ReferenceInstances ) do
				InstanceCache[ ReferenceInstance ].Active = true
			end
		end

		-- parent all active replicants to the world, the others to the render cache folder
		for ReferenceInstance, Data in pairs(InstanceCache) do
			--[[if ReferenceInstance:IsA('PVInstance') then
				ReferenceInstance:PivotTo( Data.Active and Data.PVOrigin or SuperFarCFrameValue )
			else]]
				ReferenceInstance.Parent = Data.Active and Data.VisibleParent or RenderCacheFolder
			--end
		end
	end))

	-- when the renderer system is disabled;
	QuadTreeMaidInstance:Give(function()
		RenderNodeQuadTree = false
		VisibleBoundaryRectangle = false
		NodePoints = nil
		for ReferenceInstance, Data in pairs(InstanceCache) do
			Data.Active = false
			ReferenceInstance.Parent = Data.VisibleParent
			task.wait(0.025) --  prevent overloading
		end
	end)
end

function Module:DisableQuadTreeRenderer()
	QuadTreeMaidInstance:Cleanup()
end

function Module:Start()
	task.defer(function()
		Module:EnableQuadTreeRenderer()
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
	Module:SetupNodeInstanceCache()
end

return Module
