--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISFluidWashYourself = ISBaseTimedAction:derive("ISFluidWashYourself");

function ISFluidWashYourself:getDuration()
	if self.character:isTimedActionInstant() then return 1 end
	local source_water_amount = 0
	if self.sink:getFluidContainer() then source_water_amount = self.sink:getFluidContainer():getAmount() else source_water_amount = self.sink:getWaterAmount() end
	local waterUnits = math.min(ISWashYourself.GetRequiredWater(self.character), source_water_amount);
	if not self.soaps then return waterUnits * 126 else return waterUnits * 70 end
end

function ISFluidWashYourself:complete()
	local visual = self.character:getHumanVisual()
	local waterUsed = 0
	for i=1,BloodBodyPartType.MAX:index() do
		local part = BloodBodyPartType.FromIndex(i-1)
		if self:washPart(visual, part) then
			waterUsed = waterUsed + 1
			if self.soaps then self.character:getBodyDamage():setUnhappynessLevel(self.character:getBodyDamage():getUnhappynessLevel() - 2); end
			if (not self.sink:getFluidContainer() and waterUsed >= self.sink:getWaterAmount()) or (self.sink:getFluidContainer() and waterUsed >= self.sink:getFluidContainer():getAmount()) then break end
		end
	end
	self:removeAllMakeup()
	sendHumanVisual(self.character)
	if self.sink:getFluidContainer() then 
		self.sink:getFluidContainer():removeFluid(waterUsed)
		lightjaRefillFromPipedCollectors(self.sink)
	elseif instanceof(self.sink, "IsoWorldInventoryObject") then self.sink:useWater(waterUsed)
	elseif self.sink:useWater(waterUsed) > 0 then self.sink:transmitModData() end
	return true
end

--below is the same as ISWashYourself

function ISFluidWashYourself:isValid()
	return true;
end

function ISFluidWashYourself:update()
	self.character:faceThisObjectAlt(self.sink)
    self.character:setMetabolicTarget(Metabolics.LightDomestic);
end

function ISFluidWashYourself:start()
	self:setActionAnim("WashFace")
	self:setOverrideHandModels(nil, nil)
	self.sound = self.character:playSound("WashYourself")
	self.character:reportEvent("EventWashClothing");
end

function ISFluidWashYourself:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
end

function ISFluidWashYourself:stop()
	self:stopSound()
    ISBaseTimedAction.stop(self);
end

function ISFluidWashYourself:washPart(visual, part)
	if visual:getBlood(part) + visual:getDirt(part) <= 0 then
		return false
	end
	if visual:getBlood(part) > 0 then
		-- Soap is used for blood but not for dirt.
		for _,soap in ipairs(self.soaps) do
			if soap:getCurrentUses() > 0 then
				soap:UseAndSync()
				break
			end
		end
	end
	visual:setBlood(part, 0)
	visual:setDirt(part, 0)
	return true
end

function ISFluidWashYourself:removeAllMakeup()
	local item = self.character:getWornItem("MakeUp_FullFace");
	self:removeMakeup(item);
	item = self.character:getWornItem("MakeUp_Eyes");
	self:removeMakeup(item);
	item = self.character:getWornItem("MakeUp_EyesShadow");
	self:removeMakeup(item);
	item = self.character:getWornItem("MakeUp_Lips");
	self:removeMakeup(item);
end

function ISFluidWashYourself:removeMakeup(item)
	if item then
		self.character:removeWornItem(item);
		self.character:getInventory():Remove(item);
	end
end

function ISFluidWashYourself.GetRequiredSoap(character)
	local units = 0
	local visual = character:getHumanVisual()
	for i=1,BloodBodyPartType.MAX:index() do
		local part = BloodBodyPartType.FromIndex(i-1)
		-- Soap is used for blood but not for dirt.
		if visual:getBlood(part) > 0 then
			units = units + 1
		end
	end
	return units
end

function ISFluidWashYourself.GetRequiredWater(character)
	local units = 0
	local visual = character:getHumanVisual()
	for i=1,BloodBodyPartType.MAX:index() do
		local part = BloodBodyPartType.FromIndex(i-1)
		if visual:getBlood(part) + visual:getDirt(part) > 0 then
			units = units + 1
		end
	end
	return units
end

function ISFluidWashYourself:perform()
	self:stopSound()
	self.character:resetModelNextFrame();
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISFluidWashYourself:new(character, sink, soaps)
	print("test")
	local o = ISBaseTimedAction.new(self, character)
	o.sink = sink;
	o.soaps = soaps;
	o.useSoap = (ISFluidWashYourself.GetRequiredSoap(character) <= ISWashClothing.GetSoapRemaining(soaps))
	o.maxTime = o:getDuration();
	o.forceProgressBar = true;
	return o;
end
