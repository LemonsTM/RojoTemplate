-- Original (PartCache) here https://devforum.roblox.com/t/partcache-for-all-your-quick-part-creation-needs/246641 by Xan_TheDragon
-- Forked by PenguinDevs

--[[
	BasePart Instances:
	Creating parts is laggy, especially if they are supposed to be there for a split second and/or need to be made frequently.
	This module aims to resolve this lag by pre-creating the parts and CFraming them to a location far away and out of sight.
	When necessary, the user can get one of these parts and CFrame it to where they need, then return it to the cache when they are done with it.
	
	According to someone instrumental in Roblox's backend technology, zeuxcg (https://devforum.roblox.com/u/zeuxcg/summary)...
		>> CFrame is currently the only "fast" property in that you can change it every frame without really heavy code kicking in. Everything else is expensive.
		
		- https://devforum.roblox.com/t/event-that-fires-when-rendering-finishes/32954/19
	
	This alone should ensure the speed granted by this module.
		
		
	HOW TO USE THIS MODULE:
	
	Look at the bottom of my thread for an API! https://devforum.roblox.com/t/partcache-for-all-your-quick-part-creation-needs/246641
--]]
local table = require(script:WaitForChild("Table"))

-----------------------------------------------------------
-------------------- MODULE DEFINITION --------------------
-----------------------------------------------------------

local InstanceCacheStatic = {}
InstanceCacheStatic.__index = InstanceCacheStatic
InstanceCacheStatic.__type = "InstanceCache" -- For compatibility with TypeMarshaller

-- TYPE DEFINITION: Instance Cache Instance
export type InstanceCache = {
	Open: {[number]: Instance},
	InUse: {[number]: Instance},
	CurrentCacheParent: Instance,
	Template: Instance,
	ExpansionSize: number
}

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------					

-- A CFrame that's really far away. Ideally. You are free to change this as needed.
local CF_REALLY_FAR_AWAY = CFrame.new(0, 10e8, 0)

-- Format params: methodName, ctorName
local ERR_NOT_INSTANCE = "Cannot statically invoke method '%s' - It is an instance method. Call it on an instance of this class created via %s"

-- Format params: paramName, expectedType, actualType
local ERR_INVALID_TYPE = "Invalid type for parameter '%s' (Expected %s, got %s)"

-----------------------------------------------------------
------------------------ UTILITIES ------------------------
-----------------------------------------------------------

--Similar to assert but warns instead of errors.
local function assertwarn(requirement: boolean, messageIfNotMet: string)
	if requirement == false then
		warn("[InstanceCache]: " .. messageIfNotMet)
	end
end

--Dupes an instance from the template.
local function MakeFromTemplate(template: Instance, currentCacheParent: Instance): Instance
	local instance: Instance = template:Clone()
	-- ^ Ignore W000 type mismatch between Instance and Instance. False alert.
	
	if instance:IsA("BasePart") then
		instance.CFrame = CF_REALLY_FAR_AWAY
		instance.Anchored = true
		instance.Parent = currentCacheParent
	elseif instance:IsA("GuiObject") then
		instance.Visible = false
	else
		instance.Parent = game.TestService
	end
	return instance
end

function InstanceCacheStatic.new(template: Instance, numPrecreatedInstances: number?, currentCacheParent: Instance?): InstanceCache
	local newNumPrecreatedInstances: number = numPrecreatedInstances or 5
	local newCurrentCacheParent: Instance = currentCacheParent or workspace
	
	--PrecreatedInstances value.
	--Same thing. Ensure it's a number, ensure it's not negative, warn if it's really huge or 0.
	assert(numPrecreatedInstances > 0, "[InstanceCache]: ".."PrecreatedInstances can not be negative!")
	assertwarn(numPrecreatedInstances ~= 0, "PrecreatedInstances is 0! This may have adverse effects when initially using the cache.")
	assertwarn(template.Archivable, "The template's Archivable property has been set to false, which prevents it from being cloned. It will temporarily be set to true.")
	
	local oldArchivable = template.Archivable
	template.Archivable = true
	local newTemplate: Instance = template:Clone()
	-- ^ Ignore W000 type mismatch between Instance and Instance. False alert.
	
	template.Archivable = oldArchivable
	template = newTemplate
	
	local object: InstanceCache = {
		Open = {},
		InUse = {},
		CurrentCacheParent = newCurrentCacheParent,
		Template = template,
		ExpansionSize = 10
	}
	setmetatable(object, InstanceCacheStatic)
	
	-- Below: Ignore type mismatch nil | number and the nil | Instance mismatch on the table.insert line.
	for _ = 1, newNumPrecreatedInstances do
		table.insert(object.Open, MakeFromTemplate(template, object.CurrentCacheParent))
	end
	object.Template.Parent = nil
	
	return object
	-- ^ Ignore mismatch here too
end

-- Gets an instance from the cache, or creates one if no more are available.
function InstanceCacheStatic:GetInstance(): Instance
	assert(getmetatable(self) == InstanceCacheStatic, "[InstanceCache]: "..ERR_NOT_INSTANCE:format("GetInstance", "InstanceCache.new"))
	
	if #self.Open == 0 then
		warn("[InstanceCache]: ".."No instances available in the cache! Creating [" .. self.ExpansionSize .. "] new instance(s) - this amount can be edited by changing the ExpansionSize property of the InstanceCache instance... (This cache now contains a grand total of " .. tostring(#self.Open + #self.InUse + self.ExpansionSize) .. " instances.)")
		for i = 1, self.ExpansionSize, 1 do
			table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
		end
	end
	local instance = self.Open[#self.Open]
	self.Open[#self.Open] = nil
	table.insert(self.InUse, instance)
	return instance
end

-- Returns a instance to the cache.
function InstanceCacheStatic:ReturnInstance(instance: Instance)
	assert(getmetatable(self) == InstanceCacheStatic, "[InstanceCache]: "..ERR_NOT_INSTANCE:format("ReturnInstance", "InstanceCache.new"))
	
	local index = table.indexOf(self.InUse, instance)
	if index ~= nil then
		table.remove(self.InUse, index)
		table.insert(self.Open, instance)
		if instance:IsA("BasePart") then
			instance.CFrame = CF_REALLY_FAR_AWAY
			instance.Anchored = true
		elseif instance:IsA("GuiObject") then
			instance.Visible = false
		else
			instance.Parent = game.TestService
		end
	else
		error("Attempted to return instance \"" .. instance.Name .. "\" (" .. instance:GetFullName() .. ") to the cache, but it's not in-use! Did you call this on the wrong instance?")
	end
end

-- Sets the parent of all cached instance.
function InstanceCacheStatic:SetCacheParent(newParent: Instance)
	assert(getmetatable(self) == InstanceCacheStatic, "[InstanceCache]: "..ERR_NOT_INSTANCE:format("SetCacheParent", "InstanceCache.new"))
	assert(newParent:IsDescendantOf(workspace) or newParent == workspace, "[InstanceCache]: ".."Cache parent is not a descendant of Workspace! Instances should be kept where they will remain in the visible world.")
	
	self.CurrentCacheParent = newParent
	for i = 1, #self.Open do
		self.Open[i].Parent = newParent
	end
	for i = 1, #self.InUse do
		self.InUse[i].Parent = newParent
	end
end

-- Adds numInstances more instances to the cache.
function InstanceCacheStatic:Expand(numInstances: number): ()
	assert(getmetatable(self) == InstanceCacheStatic, "[InstanceCache]: "..ERR_NOT_INSTANCE:format("Expand", "InstanceCache.new"))
	if numInstances == nil then
		numInstances = self.ExpansionSize
	end
	
	for i = 1, numInstances do
		table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
	end
end

-- Destroys this cache entirely. Use this when you don't need this cache object anymore.
function InstanceCacheStatic:Dispose()
	assert(getmetatable(self) == InstanceCacheStatic, "[InstanceCache]: "..ERR_NOT_INSTANCE:format("Dispose", "InstanceCache.new"))
	for i = 1, #self.Open do
		self.Open[i]:Destroy()
	end
	for i = 1, #self.InUse do
		self.InUse[i]:Destroy()
	end
	self.Template:Destroy()
	self.Open = {}
	self.InUse = {}
	self.CurrentCacheParent = nil
	
	self.GetInstance = nil
	self.ReturnInstance = nil
	self.SetCacheParent = nil
	self.Expand = nil
	self.Dispose = nil
end

return InstanceCacheStatic