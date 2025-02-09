--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISVerticalPlumbItem = ISBaseTimedAction:derive("ISVerticalPlumbItem");





local function do_vertical_plumbing(playerInv, sink)
	local function choose_and_remove_inventory_vpipe(playerInv, items)
		local  item_to_remove = ""
		if     items.metal_pipes > 0 then items.metal_pipes = items.metal_pipes - 1; item_to_remove = "Base.MetalPipe"
		elseif items.lead_pipes  > 0 then items.lead_pipes  = items.lead_pipes  - 1; item_to_remove = "Base.LeadPipe"
		end
		playerInv:RemoveOneOf(item_to_remove, true)
	end
	local function tally_inventory(playerInv) return {lead_pipes=playerInv:getCountTypeRecurse("LeadPipe"),metal_pipes=playerInv:getCountTypeRecurse("MetalPipe")}	end
	local items               = tally_inventory(playerInv)
	local num_vpipes_required = calculate_vpipes_required(sink)
	for i=1, num_vpipes_required do
		choose_and_remove_inventory_vpipe(playerInv, items)
	end
	generate_vpipes(sink)
end


function ISVerticalPlumbItem:isValid()
	return self.character:isEquipped(self.wrench);
--	return true;
end

function ISVerticalPlumbItem:update()
	self.character:faceThisObject(self.itemToPipe)

    self.character:setMetabolicTarget(Metabolics.MediumWork);
end

function ISVerticalPlumbItem:start()
	self.sound = self.character:playSound("RepairWithWrench")
	-- self:setActionAnim("Craft")
	self:setActionAnim(CharacterActionAnims.BuildLow);
	-- self:setActionAnim(CharacterActionAnims.Build);
	-- self:setActionAnim(CharacterActionAnims.DigTrowel);
	-- self:setActionAnim(CharacterActionAnims.Build);
end

function ISVerticalPlumbItem:stop()
	self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function ISVerticalPlumbItem:perform()
	self.character:stopOrTriggerSound(self.sound)

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

customized_fluid_capacity_by_name = {
	["Bath"]=100,
	["Shower"]=100,
	["Espresso"]=20,
	["Coffee"]=5,
	["Tabletop Soda"]=20,
	["Bar Tap"]=10
}
function ISVerticalPlumbItem:complete()
	if self.itemToPipe then
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
			-- else -- try reloading game before checking this as an issue, usually that fixes whatever would cause you to enable this. I think some error condition breaks fetch. 
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
		noise('sq is null or index is invalid')
	end
	local playerInv = self.character:getInventory()
	local sink = self.itemToPipe
	do_vertical_plumbing(playerInv,sink)
	return true;
end

function ISVerticalPlumbItem:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 1000
end

function ISVerticalPlumbItem:new(character, itemToPipe, wrench)
	local o = ISBaseTimedAction.new(self, character)
	o.character = character;
    o.itemToPipe = itemToPipe;
	o.wrench = wrench;
	o.maxTime = o:getDuration();
	return o;
end
