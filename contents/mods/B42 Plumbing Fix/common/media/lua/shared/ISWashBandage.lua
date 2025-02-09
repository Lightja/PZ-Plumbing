--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISWashBandage = ISBaseTimedAction:derive("ISWashBandage")

local has_clean_version = {
	["Base.BandageDirty"]="Base.Bandage", 
	["Base.LeatherStripsDirty"]="Base.LeatherStrips", 
	["Base.DenimStripsDirty"]="Base.DenimStrips", 
	["Base.RippedSheetsDirty"]="Base.RippedSheets",
	["Base.DenimStripsDirtyBundle"]="Base.DenimStripsBundle",
	["Base.LeatherStripsDirtyBundle"]="Base.LeatherStripsBundle",
	["Base.RippedSheetsDirtyBundle"]="Base.RippedSheetsBundle"
}
function ISWashBandage:waitToStart()
	self.character:faceThisObject(self.waterObject)
	return self.character:shouldBeTurning()
end

function ISWashBandage:update()
	self.item:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.waterObject)
end

function ISWashBandage:stop()
	self:stopSound()
	self.item:setJobDelta(0.0)
	ISBaseTimedAction.stop(self)
end

function ISWashBandage:perform()
	self:stopSound()
	self.item:setJobDelta(0.0)
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISWashBandage:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ISWashBandage:new(character, item, waterObject, recipe)
	local o = ISBaseTimedAction.new(self, character)
	if o.character:isTimedActionInstant() then o.maxTime = 1; end
	o.playerInv = character:getInventory()
	o.itemname = item
	o.result = has_clean_version[item]
	o.waterObject = waterObject
	o.recipe = recipe
	o.maxTime = o:getDuration()
	print("queued cleanbandage")
	return o
end    	

function ISWashBandage:start()
	self.item = self.playerInv:getFirstTypeRecurse(self.itemname)
	self.item:setJobType(self.recipe:getName())
	self:setActionAnim("Craft")
	self.sound = self.character:playSound("FirstAidCleanRag")
end

function ISWashBandage:getDuration()
	if self.character:isTimedActionInstant() then return 1; end
	return self.recipe:getTime()
end

function ISWashBandage:complete()
	local primary = self.character:isPrimaryHandItem(self.item)
	local secondary = self.character:isSecondaryHandItem(self.item)
	self.character:getInventory():Remove(self.playerInv:getFirstTypeRecurse(self.itemname))
	local item = self.character:getInventory():AddItem(self.result)
	sendReplaceItemInContainer(self.character:getInventory(), self.item, item)
	if primary then self.character:setPrimaryHandItem(item) end
	if secondary then self.character:setSecondaryHandItem(item) end
	sendEquip(self.character)
	if self.waterObject:getFluidContainer() then 
		self.waterObject:getFluidContainer():removeFluid(1)
		lightjaRefillFromPipedCollectors(self.waterObject,0.07)
	elseif self.waterObject:useWater(1) > 0 then self.waterObject:transmitModData() end
	return true;
end

function ISWashBandage:isValid()
	if self.playerInv:getCountTypeRecurse(self.itemname) == 0 then return false end
	return (self.waterObject:getWaterAmount() >= 1 or (self.waterObject:getFluidContainer() and self.waterObject:getFluidContainer():getAmount() >= 1)) 
end

