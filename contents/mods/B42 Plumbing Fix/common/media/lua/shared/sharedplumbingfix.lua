-- Author: Lightja 1/13/2025
-- This mod may be copied/edited/reuploaded by anyone for any reason with no preconditions.


customized_fluid_capacity_by_name = {
	["Bath"]=100,
	["Shower"]=100,
	["Espresso"]=20,
	["Coffee"]=5,
	["Tabletop Soda"]=20,
	["Bar Tap"]=10 
}
function ISPlumbItem:complete()
	if self.itemToPipe then
		print(string.format("[Lightja] Plumbing %s",tostring(self.itemToPipe)))
		if not self.itemToPipe:hasComponent(ComponentType.FluidContainer) then
			local f = ComponentType.FluidContainer:CreateComponent()
			f:setCapacity(20.0)
			local new_fluid_container_name = self.itemToPipe:getSprite():getProperties():Val("CustomName")
			local new_fluid_container_group_name = self.itemToPipe:getSprite():getProperties():Val("GroupName")
			if new_fluid_container_name then 
				f:setContainerName(self.itemToPipe:getSprite():getProperties():Val("CustomName")) 
				if customized_fluid_capacity_by_name[new_fluid_container_name] then f:setCapacity(customized_fluid_capacity_by_name[new_fluid_container_name]) end
			end
			if new_fluid_container_group_name and customized_fluid_capacity_by_name[new_fluid_container_group_name] then f:setCapacity(customized_fluid_capacity_by_name[new_fluid_container_group_name]) end
			GameEntityFactory.AddComponent(self.itemToPipe, true, f)
			if isClient() then 
				print(string.format("[Lightja]          %s sent command to add fluid container.",tostring(self.itemToPipe)))
				sendClientCommand(getSpecificPlayer(0), 'object', 'addWaterContainer', { x = self.itemToPipe:getX(), y = self.itemToPipe:getY(), z = self.itemToPipe:getZ(), index = self.itemToPipe:getObjectIndex() }) 
			-- else -- try reloading game before checking this as an issue, usually that fixes whatever would cause you to enable this. I think some error condition breaks fetch. May
				-- print(string.format("[Lightja]   ERROR: tried to add fluid container to %s from server. Sending anyways. YOLO!",tostring(self.itemToPipe)))
				-- sendClientCommand(getSpecificPlayer(0), 'object', 'addWaterContainer', { x = self.itemToPipe:getX(), y = self.itemToPipe:getY(), z = self.itemToPipe:getZ(), index = self.itemToPipe:getObjectIndex() }) 
			end
		end
		self.itemToPipe:getModData().canBeWaterPiped = false
		self.itemToPipe:setUsesExternalWaterSource(true)
		self.itemToPipe:transmitModData()
		self.itemToPipe:sendObjectChange('usesExternalWaterSource', { value = true })
		buildUtil.setHaveConstruction(self.itemToPipe:getSquare(), true);
	else
		print(string.format("[Lightja] invalid plumbing target %s",tostring(self.itemToPipe)))
		noise('sq is null or index is invalid')
	end

	return true;
end

if not ISTakeWaterAction.ogl_new then ISTakeWaterAction.ogl_new = ISTakeWaterAction.new end
function ISTakeWaterAction:new (character, item, waterObject, waterTaintedCL)
	if ISTakeWaterAction.ogl_new then return ISTakeWaterAction.ogl_new(self,character, item, waterObject, waterTaintedCL) end
end


if not ISTakeWaterAction.ogl_start then ISTakeWaterAction.ogl_start = ISTakeWaterAction.start end
function ISTakeWaterAction:start()
	self.actual_thirst = self.character:getStats():getThirst()
	if ISTakeWaterAction.ogl_start then ISTakeWaterAction.ogl_start(self) end
end

if not ISTakeWaterAction.ogl_complete then ISTakeWaterAction.ogl_complete = ISTakeWaterAction.complete end
function ISTakeWaterAction:complete()
	-- print("[Lightja] ISTakeWaterAction:complete")
	if ISTakeWaterAction.ogl_complete then ISTakeWaterAction.ogl_complete(self) end
    if not self.fluidobject and instanceof(object, "IsoWorldInventoryObject") then self.waterObject:useWater(self.waterUnit)
    elseif not self.fluidobject and self.waterObject:useWater(self.waterUnit) > 0 then self.waterObject:transmitModData() end
    local newPoisonLevel;
	if self.item then
		local fluid = Fluid.Water;
	    if self.waterObject:isTaintedWater() and not self.fluidobject then fluid = Fluid.TaintedWater; end
		if self.fluidobject then
			fluid = self.waterObject:getFluidContainer():getPrimaryFluid()
			local fluid_item = self.item:getFluidContainer()
			if fluid_item then 
				fluid_item:transferFrom(self.waterObject:getFluidContainer(), self.endUsedDelta - self.startUsedDelta)
				local fluid_capacity = fluid_item:getCapacity()
				if fluid_item:getAmount() < fluid_capacity  * 0.99 then--chain refill for large containers
					lightjaRefillFromPipedCollectors(self.waterObject, self.waterObject:getFluidContainer():getCapacity())
					ISTimedActionQueue.add(ISTakeWaterAction:new(self.character, self.item, self.waterObject, self.waterObject:isTaintedWater()));
				else
					fluid_item:adjustAmount(fluid_capacity) 
				end
				if fluid ~= Fluid.TaintedWater and fluid_item:getSpecificFluidAmount(Fluid.TaintedWater) < 0.1 then fluid_item:adjustSpecificFluidAmount(Fluid.TaintedWater,0) end--kluge trying to fix weird reports of tainted water, probably can remove, I dont think this one mattered.
			else 
				if fluid ~= Fluid.TaintedWater then self.item:getModData().taintedWater = false end
				self.item:setUsedDelta(self.startUsedDelta + (self.endUsedDelta - self.startUsedDelta)); 
				if self.item:getCurrentUsesFloat() < 0.99 then--chain refill for large containers
					ISTimedActionQueue.add(ISTakeWaterAction:new(self.character, self.item, self.waterObject, self.waterObject:isTaintedWater()));
				else self.item:setUsedDelta(1)
				end
			end
		else
			if self.item:getFluidContainer() then 
				self.item:getFluidContainer():addFluid(fluid, (self.endUsedDelta - self.startUsedDelta));
			else 
				self.item:setUsedDelta(self.startUsedDelta + (self.endUsedDelta - self.startUsedDelta)); 
				if fluid ~= Fluid.TaintedWater then self.item:getModData().taintedWater = false end
			end
			if self.waterObject and self.waterObject:getFluidContainer() then self.waterObject:getFluidContainer():removeFluid(self.endUsedDelta); end
		end
        self.item:syncItemFields();
        sendItemStats(self.item)
    else
		local thirst = self.actual_thirst
        local new_thirst = thirst - ((self.waterUnit / 10) * (25/6)) --factor of 2 to match Drink (removed). Another factor of 25/6 to match Autodrink. Revisit when TIS patches this discrepancy.
		local water_adjustment = 0
		if new_thirst < 0 then water_adjustment = (new_thirst * -10) / ((25/6)) end
		if self.fluidobject then  self.waterObject:getFluidContainer():removeFluid(self.waterUnit - water_adjustment) end
		-- print(string.format("[Lightja] finishing drink action. waterneeded: %s waterunits: %f, water_adjustment: %f, thirst: %f, new_thirst: %f",tostring(self.waterNeeded), self.waterUnit, water_adjustment,thirst,new_thirst))
        self.character:getStats():setThirst(math.max(new_thirst, 0.0));
        syncPlayerStats(self.character, 0x00004000);
        local isTainted = (isServer() and self.waterTaintedCL) or self.waterObject:isTaintedWater()
        if isTainted then
            local bodyDamage	= self.character:getBodyDamage();
            local stats			= self.character:getStats();
            if bodyDamage:getPoisonLevel() < 20 and stats:getSickness() < 0.3 then
                newPoisonLevel = math.min(bodyDamage:getPoisonLevel() + 10 + self.waterUnit, 20);
                bodyDamage:setPoisonLevel(newPoisonLevel);
                sendDamage(self.character)
            end
        end
    end
	
	if LightjaRainManager and LightjaRainManager.UpdateCollector then LightjaRainManager.UpdateCollector(self.waterObject) end
    return true;
end

if not ISTakeWaterAction.ogl_isValid then ISTakeWaterAction.ogl_isValid = ISTakeWaterAction.isValid end
function ISTakeWaterAction:isValid()
	if self.fluidobject then lightjaRefillFromPipedCollectors(self.waterObject) end
	if ISTakeWaterAction.ogl_isValid then return ISTakeWaterAction.ogl_isValid(self) else print("[Lightja] Failed sanity check at ISTakeWaterAction:IsValid() - invalidating action"); return false end
end


lightjaplumbing_oldwashingmachines = {}
lightjaplumbing_washingmachines = {}
local function lightjaplumbing_removewashingmachine(machine)
	local function lightjaTableRemove(t, item) 
		local found = false
		if item then for i, v in ipairs(t) do if v == item then table.remove(t, i); found = true break end end end
		if not found then print("[Lightja] WARNING: tried to remove washing machine that was not in the list of tracked machines") end
	end
	-- print("[Lightja] removing washing machine from the list.")
	lightjaTableRemove(lightjaplumbing_washingmachines, machine)
	if #lightjaplumbing_washingmachines == 0 then Events.EveryOneMinute.Remove(lightjaplumbing_updatewashingmachines) end
end


local function lightjaplumbing_stopwashingmachine(machine)
	local machine_data = machine:getModData()
	machine_data.timer = 0; 
	machine_data.ForceStop = true
	machine_data.machine_activated = false
end

local function updateWasherSoundAndState(machine)
	local machine_data = machine:getModData()
	if not machine:getContainer():isPowered() then 
		if machine:getObjectIndex() == -1 then -- unloaded
			-- print(string.format("[Lightja] skipping unloaded washing machine at square (%s,%s)... emitter: %s, keyID: %s",tostring(machine:getSquare():getX()),tostring(machine:getSquare():getY()),tostring(machine_data.emitter),machine:getEntityNetID()))
			return 
		end 
		machine_data.inactive_minutes = machine_data.inactive_minutes + 1
		if machine_data.inactive_minutes < 3 then--may not be needed, leaving for this build since its working.
			-- print(string.format("[Lightja] skipping unpowered washing machine... inactive_minutes: %s",tostring(machine_data.inactive_minutes)))
			return
		else
			-- print(string.format("[Lightja] removing unpowered washing machine... inactive_minutes: %s",tostring(machine_data.inactive_minutes)))
			lightjaplumbing_stopwashingmachine(machine)
		end
	end
	if (machine_data.machine_activated and machine_data.timer > 0) or machine:isActivated() then
		if not isServer() then
			if machine_data.timer and machine_data.timer > 0 then
				local worldinstance = getWorld()
				local m_x, m_y, m_z = machine:getX() + 0.5F, machine:getY() + 0.5F, machine:getZ()
				if machine_data.emitter and not machine_data.emitter:isPlaying("ClothingWasherRunning") then
					if machine_data.soundInstance ~= -1 then
						machine_data.emitter:restart(machine_data.soundInstance)
					else 
						machine_data.emitter:stopAll()
						machine_data.emitter = worldinstance:getFreeEmitter(m_x, m_y, m_z)
						worldinstance:setEmitterOwner(machine_data.emitter, machine)
						machine_data.soundInstance = machine_data.emitter:playSoundLoopedImpl("ClothingWasherRunning");
					end
				elseif not machine_data.emitter then
					machine_data.emitter = worldinstance:getFreeEmitter(m_x, m_y, m_z);
					worldinstance:setEmitterOwner(machine_data.emitter, machine)
					machine_data.soundInstance = machine_data.emitter:playSoundLoopedImpl("ClothingWasherRunning");
				end
				local container = machine:getContainer()
				local container_empty = container and container:getItems() and container:getItems():isEmpty()
				local washer_loaded = 0
				if not container_empty then washer_loaded = 1 end
				machine_data.emitter:setParameterValueByName(machine_data.soundInstance,"ClothingWasherLoaded",washer_loaded)
			end
		end
		if not isClient() and machine_data.timer > 0 then 
			getWorldSoundManager():addSoundRepeating(machine, machine:getX(), machine:getY(), machine:getZ(), 10, 10, false) 
		end
	else
		print(string.format("[Lightja] Ending washing machine cycle. timer:%s, active:%s, activated:%s",tostring(machine_data.timer),tostring(machine_data.machine_activated),tostring(machine:isActivated())))
		machine_data.machine_activated = false
		machine_data.timer = 0
		local start_dryer_cycle = machine.setModeDryer and not machine_data.ForceStop and machine:getContainer():isPowered()
		if machine_data.emitter then	
			machine_data.emitter:stopAll()
			if not start_dryer_cycle and not machine_data.ForceStop then machine_data.soundInstance = machine_data.emitter:playSoundImpl("ClothingWasherFinished", machine) 
			elseif not start_dryer_cycle and machine_data.ForceStop then machine_data.soundInstance = machine_data.emitter:playSoundImpl("ClothingDryerFinished", machine) 
			end
		else
			print("[Lightja] WARNING: no sound emitter detected when turning off washing machine.... Unable to find existing sound emitter...")
		end
		lightjaplumbing_removewashingmachine(machine)
		if start_dryer_cycle then machine:setModeDryer(); machine:setActivated(true) end
	end
end


local has_clean_version = {
	["Base.BandageDirty"]="Base.Bandage", 
	["Base.LeatherStripsDirty"]="Base.LeatherStrips", 
	["Base.DenimStripsDirty"]="Base.DenimStrips", 
	["Base.RippedSheetsDirty"]="Base.RippedSheets",
	["Base.DenimStripsDirtyBundle"]="Base.DenimStripsBundle",
	["Base.LeatherStripsDirtyBundle"]="Base.LeatherStripsBundle",
	["Base.RippedSheetsDirtyBundle"]="Base.RippedSheetsBundle"
}
function lightjaplumbing_updatewashingmachines()--washing machine java logic automatically turns them off when they dont have water, which doesnt work with the new fluid system, so I have to re-implement the washer logic in lua to avoid this condition. It will be a lot easier to just use :SetActivated() when the update function is fixed for the new fluids.
	local function clean_clothing_item(machine_data, washer_item)
		local dirt_level = washer_item:getDirtyness() or 0
		dirt_level = math.max(dirt_level - machine_data.progress_per_min, machine_data.minimumDirt)
		local coveredParts = BloodClothingType.getCoveredParts(washer_item:getBloodClothingType())
		if coveredParts then 
			for j=0,coveredParts:size()-1 do
				local blood_level_part = washer_item:getBlood(coveredParts:get(j))
				local dirt_level_part = washer_item:getDirt(coveredParts:get(j))
				if blood_level_part > machine_data.minimumBlood then 
					blood_level_part = math.max(machine_data.minimumBlood, blood_level_part - machine_data.progress_per_min)
					washer_item:setBlood(coveredParts:get(j), blood_level_part)
				end
				if dirt_level_part > machine_data.minimumDirt then
					dirt_level_part = math.max(machine_data.minimumDirt, dirt_level_part - machine_data.progress_per_min)
					washer_item:setDirt(coveredParts:get(j), dirt_level_part)
				end
			end
		end
		washer_item:setDirtyness(dirt_level)
		washer_item:setWetness(99)--99 instead of 100 because that keeps the UI from flashing a different item name (Soaked) for ~1-2 sec and this method only updates every 10 minutes.
	end
	local function clean_item(washer_item_container, machine_data, washer_item)
		local item_data = washer_item:getModData()
		if washer_item.IsClothing or washer_item.IsInventoryContainer then
			local blood_level = washer_item:getBloodLevel() or 0
			blood_level = math.max(blood_level - machine_data.progress_per_min, machine_data.minimumBlood)
			washer_item:setBloodLevel(blood_level)
			if washer_item.IsClothing and washer_item:IsClothing() then
				clean_clothing_item(machine_data, washer_item)
			end
		end
		if item_data.CleanVersion then 
			item_data.CleaningProgress = item_data.CleaningProgress + machine_data.progress_per_min
			if item_data.CleaningProgress > 50 then
				local new_item = instanceItem(item_data.CleanVersion)
				washer_item_container:DoRemoveItem(washer_item)
				washer_item_container:addItem(new_item)
			end
		end
	end
	local function monitor_old_version_washer_for_cycle_switchover(machine)
		if not machine:getContainer():isPowered() or machine:getModData().ForceStop then 
			-- print("[Lightja] removing unpowered or stopped washing machine...")
			lightjaplumbing_removewashingmachine(machine)
		elseif machine.isModeWasher and machine:isModeWasher() and not machine:isActivated() then
			machine:setModeDryer()
			machine:setActivated(true); 
			machine:sendObjectChange("washer.dryer")
			lightjaplumbing_removewashingmachine(machine)
		elseif not machine:isActivated() or (machine.isModeDryer and machine:isModeDryer()) then
			lightjaplumbing_removewashingmachine(machine)
		end
	end
	--start of function execution
	for _, machine in ipairs(lightjaplumbing_washingmachines) do
		-- print("[Lightja]          checking washing machine...")
		local machine_data = machine:getModData()
		if machine_data.fluid_container then 
			updateWasherSoundAndState(machine)
			if machine and machine_data.machine_activated and machine:getObjectIndex() ~= -1 then
				local washer_fluid_container = machine:getFluidContainer()
				local washer_item_container = machine:getContainer()
				local washer_items = washer_item_container:getItems()
				washer_fluid_container:removeFluid(washer_fluid_container:getCapacity() / machine_data.cycle_duration_min)
				for i=1, washer_items:size() do
					local washer_item = washer_items:get(i-1)
					local item_data = washer_item:getModData()
					if has_clean_version[washer_item:getFullType()] then 
						item_data.CleanVersion = has_clean_version[washer_item:getFullType()]; 
						if item_data.CleaningProgress == nil then item_data.CleaningProgress = 0 end
						
					end
				end
				for i=1, washer_items:size() do
					clean_item(washer_item_container, machine_data, washer_items:get(i-1))
				end
				machine_data.timer = machine_data.timer - 1
			end
		else
			monitor_old_version_washer_for_cycle_switchover(machine)
		end
	end
end

if not ISToggleClothingWasher.ogl_complete then ISToggleClothingWasher.ogl_complete = ISToggleClothingWasher.complete end
function ISToggleClothingDryer:complete()
	if not self.object then return false end
	if instanceof(self.object, "IsoCombinationWasherDryer") and not self.object:isModeDryer() then
		-- print("set combo machine to dryer state")
		self.object:setModeDryer()
	end
	self.object:setActivated(not self.object:isActivated())
	self.object:sendObjectChange("dryer.state")
	return true
end

-- if not ISToggleClothingWasher.ogl_complete then ISToggleClothingWasher.ogl_complete = ISToggleClothingWasher.complete end
function ISToggleClothingWasher:complete()
	if not self.object then return false end
	local washer_fluid_container = self.object:getFluidContainer()
	if washer_fluid_container ~= nil then
		local machine_data = self.object:getModData()
		if machine_data.machine_activated then lightjaplumbing_stopwashingmachine(self.object); updateWasherSoundAndState(self.object)
		elseif self.object:isActivated() then  self.object:setActivated(false); self.object:sendObjectChange("washer.state")
		else
			local washer_blood_amount = washer_fluid_container:getSpecificFluidAmount(Fluid.Blood)
			local washer_water_amount = washer_blood_amount + washer_fluid_container:getSpecificFluidAmount(Fluid.Water) + washer_fluid_container:getSpecificFluidAmount(Fluid.TaintedWater) -- count blood as water for cleaning dirt since it adds blood
			local washer_volume = washer_fluid_container:getAmount()
			local washer_capacity = washer_fluid_container:getCapacity()
			if washer_volume < washer_fluid_container:getCapacity() * 0.99 then -- if theres not enough water, start as dryer for combo machines
				if self.object.isModeDryer then  self.object:setModeDryer(); self.object:setActivated(true); self.object:sendObjectChange("dryer.state") end
			end
			local percent_blood =    ((washer_blood_amount/washer_volume)) * 100 
			local percent_nonwater = (1 - (washer_water_amount/washer_volume)) * 100
			-- print(string.format("[Lightja] activating clothing washing machine... percent_blood: %s, percent_nonwater: %s",tostring(percent_blood),tostring(percent_nonwater)))
			if self.object.isModeDryer and self.object:isModeDryer() then
				self.object:setModeWasher()
			end
			machine_data.machine_activated = true
			machine_data.timer = 90
			machine_data.cycle_duration_min = 90
			machine_data.effectiveness_mod = 1--temp unused
			machine_data.progress_per_min = (100/machine_data.cycle_duration_min) * machine_data.effectiveness_mod --90 minute cycle to complete wash, might have reasons to tweak this value.
			machine_data.minimumDirt = percent_nonwater or 0
			machine_data.minimumBlood = percent_blood or 0
			machine_data.fluid_container = washer_fluid_container
			machine_data.washer_capacity = washer_fluid_container:getCapacity()
			machine_data.ForceStop = false
			machine_data.soundInstance = -1
			machine_data.inactive_minutes = 0
			-- print("[Lightja] added new style washer to the list")
			table.insert(lightjaplumbing_washingmachines,self.object)
			washer_fluid_container:removeFluid(washer_capacity)
			updateWasherSoundAndState(self.object)
			if #lightjaplumbing_washingmachines == 1 then Events.EveryOneMinute.Add(lightjaplumbing_updatewashingmachines) end
		end
	else--old water system
		local is_combo_machine = self.object.isModeDryer
		local is_dryer = self.object.isModeDryer and self.object:isModeDryer()
		local is_active = self.object:isActivated()
		local machine_data = self.object:getModData()
		if is_active then 
			machine_data.ForceStop = true
			-- print("[Lightja] toggling already active old washer, setting ForceStop to true...")
		end
		if not is_active then 
			machine_data.ForceStop = false
			table.insert(lightjaplumbing_washingmachines,self.object)
			-- print("[Lightja] added newly started old style washer to the list")
			if #lightjaplumbing_washingmachines == 1 then Events.EveryOneMinute.Add(lightjaplumbing_updatewashingmachines) end
		end
		if is_dryer then
			self.object:setModeWasher()
		end
		self.object:setActivated(not is_active)
		self.object:sendObjectChange("washer.state")
	end
	return true
end