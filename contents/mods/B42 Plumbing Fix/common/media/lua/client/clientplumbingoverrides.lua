-- Author: Lightja 1/31/2025
-- This mod may be copied/edited/reuploaded by anyone for any reason with no preconditions.

--reused/copied local functions
local function predicateNotBroken(item) return not item:isBroken() end
local function getMoveableDisplayName(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end
		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

--extended functions
local fetch_specific_flow_multiplier = 2.12345
if not ISWorldObjectContextMenu.ogl_fetch then ISWorldObjectContextMenu.ogl_fetch = ISWorldObjectContextMenu.fetch end
ISWorldObjectContextMenu.fetch = function(v, player, doSquare)
	lightjaRefillFromPipedCollectors(v,fetch_specific_flow_multiplier)
	if ISWorldObjectContextMenu.ogl_fetch then ISWorldObjectContextMenu.ogl_fetch(v, player, doSquare) else print("[Lightja Plumbing] ERROR og fetch function not found. Functionality probably wont work.") end
	
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars
	local preWaterShutoff = getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 < getSandboxOptions():getOptionByName("WaterShutModifier"):getValue();
	local playerObj = getSpecificPlayer(player)
	local playerInv = playerObj:getInventory()
	if instanceof(v, "IsoClothingWasher") or instanceof(v, "IsoCombinationWasherDryer") then fetch.clothingDryer = v end
	if preWaterShutoff and playerInv and not playerInv:containsTypeEvalRecurse("PipeWrench", predicateNotBroken) and not playerInv:containsTagEvalRecurse("PipeWrench", predicateNotBroken) then return end
	local sprite = v:getSprite()
	local props = nil
	if sprite then props = sprite:getProperties() end
	-- print(string.format("[Lightja] prewater: %s - playerinv: %s - pipewrenchtype: %s - pipewrenchtag: %s",tostring(preWaterShutoff),tostring(playerInv),tostring(playerInv:containsTypeEvalRecurse("PipeWrench", predicateNotBroken)),tostring(playerInv:containsTagEvalRecurse("PipeWrench", predicateNotBroken))))

	if v and v:getSquare() and not v:getUsesExternalWaterSource() then
		if (v:hasModData() and v:getModData().canBeWaterPiped) 
		or (props and (props:Is("waterPiped") or props:getFlagsList():contains(IsoFlagType.waterPiped))) then
			-- print("[Lightja] found pipeable v")
			if preWaterShutoff then fetch.canBeWaterPiped = v else
			-- if preWaterShutoff then fetch.plumbable_fluid_container = v else
				local pipeable_collectors = lightja_find_collectors(v:getSquare())
				if #pipeable_collectors > 0 then 
					fetch.canBeWaterPiped = v 
					-- fetch.canBeWaterPiped:getModData().collectors = pipeable_collectors
				end
				-- if #pipeable_collectors > 0 then fetch.plumbable_fluid_container = v end
			end
		elseif fetch.storeWater and not fetch.storeWater:getUsesExternalWaterSource() then
			local water_amount = v:getSquare():getProperties():Val("waterAmount")-- v:getWaterAmount() is probably simpler
			if preWaterShutoff and water_amount and tonumber(water_amount) < 200 then 
				fetch.canBeWaterPiped = fetch.storeWater 
				-- fetch.plumbable_fluid_container = fetch.storeWater 
			else
				local pipeable_collectors = lightja_find_collectors(v:getSquare())
				if #pipeable_collectors > 0 then 
					fetch.canBeWaterPiped = fetch.storeWater
					-- fetch.canBeWaterPiped:getModData().collectors = pipeable_collectors
				end
				-- if #pipeable_collectors > 0 then fetch.plumbable_fluid_container = fetch.storeWater end
			end
		elseif is_tabletop_dispenser(v) then
			fetch.canEnableFluids = v
		end
	end
	if v and v:getSquare() then 
		local og_pipe = find_pipe_for_connection(v:getSquare())
		if og_pipe then fetch.connectable_pipe = v end
		if is_pipeable_object(v) then 
			print(string.format("[Lightja] found pipeable object %s",tostring(v)))
			fetch.pipeable_obj = v 
		else
			print(string.format("[Lightja] found unpipeable object %s",tostring(v)))
		end
	end
	
end

if not ISWorldObjectContextMenu.ogl_doDrinkWaterMenu then ISWorldObjectContextMenu.ogl_doDrinkWaterMenu = ISWorldObjectContextMenu.doDrinkWaterMenu end
ISWorldObjectContextMenu.doDrinkWaterMenu = function(object, player, context)
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars
	if fetch.clothingDryer or fetch.clothingWasher or fetch.comboWasherDryer or is_tabletop_dispenser(object) then return end
	if ISWorldObjectContextMenu.ogl_doDrinkWaterMenu then ISWorldObjectContextMenu.ogl_doDrinkWaterMenu(object, player, context) end
end

if not ISWorldObjectContextMenu.ogl_doFillWaterMenu then ISWorldObjectContextMenu.ogl_doFillWaterMenu = ISWorldObjectContextMenu.doFillWaterMenu end 
ISWorldObjectContextMenu.doFillWaterMenu = function(sink, playerNum, context)
	--hook for washing machine turn on/off
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars
	local machine = fetch.clothingDryer or fetch.clothingWasher or fetch.comboWasherDryer
	local fluid_container = nil
	if machine then fluid_container = machine:getFluidContainer() end
	if machine and fluid_container and getSpecificPlayer(playerNum):DistToSquared(machine:getX() + 0.5, machine:getY() + 0.5) then-- 
		local option = nil
		local machine_activated = sink:getModData().machine_activated or machine:isActivated()
		local is_combo_machine = machine.isModeDryer
		if machine_activated then
			local running_as_dryer = is_combo_machine and machine:isModeDryer() and machine:isActivated()
			if not running_as_dryer then
				option = context:addGetUpOption(getText("ContextMenu_Turn_Off"), worldobjects, ISWorldObjectContextMenu.onToggleClothingWasher, sink, playerNum)
			else
				option = context:addGetUpOption(getText("ContextMenu_Turn_Off"), worldobjects, ISWorldObjectContextMenu.onToggleClothingDryer, sink, playerNum)
			end
		else
			if is_combo_machine then
				option = context:addGetUpOption(getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingwasher"), worldobjects, ISWorldObjectContextMenu.onToggleClothingWasher, sink, playerNum)
			else
				option = context:addGetUpOption(getText("ContextMenu_Turn_On"), worldobjects, ISWorldObjectContextMenu.onToggleClothingWasher, sink, playerNum)
			end
			if not machine:getContainer():isPowered() 
			or (fluid_container and fluid_container:getAmount() < fluid_container:getCapacity() * 0.99) --new fluid system
			or (not fluid_container and machine:getWaterAmount() <= 0) then -- old water system
				option.notAvailable = true
				option.toolTip = ISWorldObjectContextMenu.addToolTip()
				option.toolTip:setVisible(false)
				option.toolTip:setName(getMoveableDisplayName(machine))
				if not machine:getContainer():isPowered() then option.toolTip.description = getText("IGUI_RadioRequiresPowerNearby") end
				if (fluid_container and fluid_container:getAmount() < fluid_container:getCapacity() * 0.99) 
				or (not fluid_container and machine:getWaterAmount() <= 0) then
					if option.toolTip.description ~= "" then
						option.toolTip.description = option.toolTip.description .. "\n" .. getText("IGUI_RequiresWaterSupply")
					else
						option.toolTip.description = getText("IGUI_RequiresWaterSupply")
					end
				end
			end
			if is_combo_machine then
				local option2 = context:addGetUpOption(getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingdryer"), worldobjects, ISWorldObjectContextMenu.onToggleClothingDryer, sink, playerNum)
				if not machine:getContainer():isPowered()  then
					option2.notAvailable = true
					option2.toolTip = ISWorldObjectContextMenu.addToolTip()
					option2.toolTip:setVisible(false)
					option2.toolTip:setName(getMoveableDisplayName(machine))
					option2.toolTip.description = getText("IGUI_RadioRequiresPowerNearby")
				end
			end
		end
	end
	if ISWorldObjectContextMenu.ogl_doFillWaterMenu and not machine then ISWorldObjectContextMenu.ogl_doFillWaterMenu(sink, playerNum, context) end
	if sink:getFluidContainer() and not machine then ISWorldObjectContextMenu.doWashClothingMenu(sink, playerNum, context) end
end

if not ISWorldObjectContextMenu.ogl_onWashingDryer then ISWorldObjectContextMenu.ogl_onWashingDryer = ISWorldObjectContextMenu.onWashingDryer end
function ISWorldObjectContextMenu.onWashingDryer(source, context, object, player)
	if instanceof(object, "IsoClothingDryer") then ISWorldObjectContextMenu.ogl_onWashingDryer(source, context, object, player); return end
	if object:getFluidContainer() then return end
	local has_water = object:getWaterAmount() > 0
	if not object:isActivated() and instanceof(object, "IsoClothingWasher") and not has_water then return end
	local machine = object
	local sink = object
	local is_combo_machine = instanceof(machine, "IsoCombinationWasherDryer")
	local option = nil
	local option2 = nil
	if machine:isActivated() then
		local running_as_dryer = is_combo_machine and machine:isModeDryer() and machine:isActivated()
		if not running_as_dryer then
			option = context:addGetUpOption(getText("ContextMenu_Turn_Off"), worldobjects, ISWorldObjectContextMenu.onToggleClothingWasher, sink, player)
		else
			option = context:addGetUpOption(getText("ContextMenu_Turn_Off"), worldobjects, ISWorldObjectContextMenu.onToggleClothingDryer, sink, player)
		end
	else
		if is_combo_machine then
			if has_water then 
				option = context:addGetUpOption(getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingwasher"), worldobjects, ISWorldObjectContextMenu.onToggleClothingWasher, sink, player)
				option2 = context:addGetUpOption(getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingdryer"), worldobjects, ISWorldObjectContextMenu.onToggleClothingDryer, sink, player)
			else
				option = context:addGetUpOption(getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingwasher"), worldobjects, ISWorldObjectContextMenu.onToggleClothingWasher, sink, player)
			end
		else
			option = context:addGetUpOption(getText("ContextMenu_Turn_On"), worldobjects, ISWorldObjectContextMenu.onToggleClothingWasher, sink, player)
		end
		if not machine:getContainer():isPowered()  then
			option.notAvailable = true
			option.toolTip = ISWorldObjectContextMenu.addToolTip()
			option.toolTip:setVisible(false)
			option.toolTip:setName(getMoveableDisplayName(machine))
			option.toolTip.description = getText("IGUI_RadioRequiresPowerNearby")
			if option2 then 
				option2.notAvailable = true
				option2.toolTip = ISWorldObjectContextMenu.addToolTip()
				option2.toolTip:setVisible(false)
				option2.toolTip:setName(getMoveableDisplayName(machine))
				option2.toolTip.description = getText("IGUI_RadioRequiresPowerNearby")
			end
		end
	end
end

if not ISFluidInfoUI.ogl_update then ISFluidInfoUI.ogl_update = ISFluidInfoUI.update end
function ISFluidInfoUI:update()
	if ISFluidInfoUI.ogl_update then ISFluidInfoUI.ogl_update(self) end
	if not self.last_update then self.last_update = getGameTime():getWorldAgeHours() end
	local elapsed_time = getGameTime():getWorldAgeHours() - self.last_update
	if elapsed_time > 0.0005 then --0.001 in-game hours = 0.075 sec at 1x, in theory. Feels like its actually a little longer, might be off on my calculation.
		local speed_factor = 1
		local flow_rate = self.owner:getModData().ui_flow_rate or (0.031 / speed_factor)
		lightjaRefillFromPipedCollectors(self.owner,flow_rate*speed_factor); 
		self.last_update = getGameTime():getWorldAgeHours(); 
	end
end

local SMALL_FONT_HEIGHT = getTextManager():getFontHeight(UIFont.Small)
local PADDING = 10
if not ISFluidInfoUI.ogl_createChildren then ISFluidInfoUI.ogl_createChildren = ISFluidInfoUI.createChildren end
function ISFluidInfoUI:createChildren()
	if ISFluidInfoUI.ogl_createChildren then ISFluidInfoUI.ogl_createChildren(self) end
	if not self.owner:getUsesExternalWaterSource() then return end
	local sink_data = self.owner:getModData()
	sink_data.fluids_ui_open = true
	local width = self.panel:getRight() + PADDING + 1
	local height = SMALL_FONT_HEIGHT
	local x = PADDING+1
	local y = self.btnClose:getBottom() + 2*(height)
	local slider = ISSliderPanel:new(x,y,width,height,self,self.update_flow_slider)
	self:addChild(slider)
	local label_width = getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_Open") .. "50%")
	x = (width / 2) + (label_width / 2) + PADDING + 1
	y = self.btnClose:getBottom() + (height)
	height = SMALL_FONT_HEIGHT
	local text = getText("IGUI_Open")
	local r,g,b,a = 1,1,1,1
	local left_aligned = false
	local label = ISLabel:new(x,y,height,text,r,g,b,a,UIFont.Small,left_aligned)
	self:addChild(label)
	slider.valueLabel = label
	local s_min, s_max = 0,100
	local s_step, s_shift = 0.1,0.1
	local ignore_current_value = true
	slider:setValues(s_min,s_max,s_step,s_shift, ignore_current_value)
	local do_update_trigger = false
	local current_value = 100 * (sink_data.ui_flow_rate or 0.031)
	slider:setCurrentValue(current_value,do_update_trigger)
end


if not ISFluidInfoUI.ogl_close then ISFluidInfoUI.ogl_close = ISFluidInfoUI.close end
function ISFluidInfoUI:close()
	if ISFluidInfoUI.ogl_close then ISFluidInfoUI.ogl_close(self) end
	self.owner:getModData().fluids_ui_open = false
    -- if self.player then
        -- local playerNum = self.player:getPlayerNum();
        -- if ISFluidInfoUI.players[playerNum] then
            -- ISFluidInfoUI.players[playerNum].x = self:getX();
            -- ISFluidInfoUI.players[playerNum].y = self:getY();
        -- end
    -- end
    -- self:setVisible(false);
    -- self:removeFromUIManager();
end

if not ISWorldObjectContextMenu.ogl_doWashClothingMenu then ISWorldObjectContextMenu.ogl_doWashClothingMenu = ISWorldObjectContextMenu.doWashClothingMenu end
ISWorldObjectContextMenu.doWashClothingMenu = function(sink, player, context)
	if is_tabletop_dispenser(sink) then return end
	if not sink:getFluidContainer() and ISWorldObjectContextMenu.ogl_doWashClothingMenu then ISWorldObjectContextMenu.ogl_doWashClothingMenu(sink, player, context); return end
	local function predicateCleaningLiquid(item)
		if not item then return false end
		return item:hasComponent(ComponentType.FluidContainer) and (item:getFluidContainer():contains(Fluid.Bleach) or item:getFluidContainer():contains(Fluid.CleaningLiquid)) and (item:getFluidContainer():getAmount() >= ZomboidGlobals.CleanBloodBleachAmount)
	end
	local playerObj = getSpecificPlayer(player)
	if sink:getSquare():getBuilding() ~= playerObj:getBuilding() then return end;
    local playerInv = playerObj:getInventory()
	local items = lightja_count_bandages(playerInv)
	local washYourself = false
	local washEquipment = false
	local washList = {}
	local soapList = {}
	local noSoap = true
	washYourself = ISWashYourself.GetRequiredWater(playerObj) > 0
	local barList = playerInv:getItemsFromType("Soap2", true)
	for i=0, barList:size() - 1 do
        local item = barList:get(i)
		table.insert(soapList, item)
	end
    local bottleList = playerInv:getAllEvalRecurse(predicateCleaningLiquid)
    for i=0, bottleList:size() - 1 do
        local item = bottleList:get(i)
        table.insert(soapList, item)
    end
	local clothingInventory = playerInv:getItemsFromCategory("Clothing")
	for i=0, clothingInventory:size() - 1 do
		local item = clothingInventory:get(i)
		if not item:isHidden() and (item:hasBlood() or item:hasDirt()) and not item:hasTag("BreakWhenWet") then
			if washEquipment == false then
				washEquipment = true
			end
			table.insert(washList, item)
		end
	end
    local weaponInventory = playerInv:getItemsFromCategory("Weapon")
    for i=0, weaponInventory:size() - 1 do
        local item = weaponInventory:get(i)
        if item:hasBlood() then
            if washEquipment == false then
                washEquipment = true
            end
            table.insert(washList, item)
        end
	end
	local clothingInventory = playerInv:getItemsFromCategory("Container")
	for i=0, clothingInventory:size() - 1 do
		local item = clothingInventory:get(i)
		if not item:isHidden() and (item:hasBlood() or item:hasDirt()) then
			washEquipment = true
			table.insert(washList, item)
		end
	end
	table.sort(washList, ISWorldObjectContextMenu.compareClothingBlood)
	if washYourself or washEquipment or #items > 0 then
		local mainOption = context:addOption(getText("ContextMenu_Wash"), nil, nil);
		local mainSubMenu = ISContextMenu:getNew(context)
		context:addSubMenu(mainOption, mainSubMenu)
		if #items > 0 then lightja_washbandagesmenu(items, sink, player, mainSubMenu) end
		local soapRemaining = 0;
		if soapList and #soapList >= 1 then
			soapRemaining = ISWashClothing.GetSoapRemaining(soapList)
		end
		local waterRemaining = sink:getFluidContainer():getAmount()
		if waterRemaining >= sink:getFluidContainer():getCapacity()/2.001 and sink:getUsesExternalWaterSource() then waterRemaining = 9999 end-- kluge assumes >= 50% capacity is a piped bathtub or shower, intentionally not doing the same for sinks to encourage washing in bath/sink
		if washYourself then
			local soapRequired = ISWashYourself.GetRequiredSoap(playerObj)
			local waterRequired = ISWashYourself.GetRequiredWater(playerObj)
			local option = mainSubMenu:addGetUpOption(getText("ContextMenu_Yourself"), playerObj, ISWorldObjectContextMenu.onFluidWashYourself, sink, soapList)
			local tooltip = ISWorldObjectContextMenu.addToolTip()
			if soapRemaining < soapRequired then
				tooltip.description = tooltip.description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
			else
				tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
			end
			tooltip.description = tooltip.description .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.min(waterRemaining, waterRequired)) .. " / " .. tostring(waterRequired)
			local visual = playerObj:getHumanVisual()
			local bodyBlood = 0
			local bodyDirt = 0
			for i=1,BloodBodyPartType.MAX:index() do
				local part = BloodBodyPartType.FromIndex(i-1)
				bodyBlood = bodyBlood + visual:getBlood(part)
				bodyDirt = bodyDirt + visual:getDirt(part)
			end
			if bodyBlood > 0 then
				tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(bodyBlood / BloodBodyPartType.MAX:index() * 100) .. " / 100"
			end
			if bodyDirt > 0 then
				tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(bodyDirt / BloodBodyPartType.MAX:index() * 100) .. " / 100"
			end
			option.toolTip = tooltip
			if waterRemaining < 1 then
				option.notAvailable = true
			end
		end
		if washEquipment then
			if #washList > 1 then
				local soapRequired = 0
				local waterRequired = 0
				for _,item in ipairs(washList) do
					soapRequired = soapRequired + ISWashClothing.GetRequiredSoap(item)
					waterRequired = waterRequired + ISWashClothing.GetRequiredWater(item)
				end
				local tooltip = ISWorldObjectContextMenu.addToolTip();
				if (soapRemaining < soapRequired) then
					tooltip.description = tooltip.description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
					noSoap = true;
				else
					tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
					noSoap = false;
				end
				tooltip.description = tooltip.description .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.min(waterRemaining, waterRequired)) .. " / " .. tostring(waterRequired)
				local option = mainSubMenu:addGetUpOption(getText("ContextMenu_WashAllClothing"), playerObj, ISWorldObjectContextMenu.onFluidWashClothing, sink, soapList, washList, nil,  noSoap);
				option.toolTip = tooltip;
				if (waterRemaining < waterRequired) then
					option.notAvailable = true;
				end
			end
			for i,item in ipairs(washList) do
				local soapRequired = ISWashClothing.GetRequiredSoap(item)
				local waterRequired = ISWashClothing.GetRequiredWater(item)
				local tooltip = ISWorldObjectContextMenu.addToolTip();
				if (soapRemaining < soapRequired) then
					tooltip.description = tooltip.description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
					noSoap = true;
				else
					tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
					noSoap = false;
				end
				tooltip.description = tooltip.description .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.min(waterRemaining, waterRequired)) .. " / " .. tostring(waterRequired)
				if (item:IsClothing() or item:IsInventoryContainer()) and (item:getBloodLevel() > 0) then
					tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel()) .. " / 100"
				end
				if item:IsWeapon() and (item:getBloodLevel() > 0) then
					tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel() * 100) .. " / 100"
				end
				if item:IsClothing() and item:getDirtyness() > 0 then
					tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(item:getDirtyness()) .. " / 100"
				end
				local option = mainSubMenu:addGetUpOption(getText("ContextMenu_WashClothing", item:getDisplayName()), playerObj, ISWorldObjectContextMenu.onFluidWashClothing, sink, soapList, nil, item, noSoap);
				
				if (waterRemaining < waterRequired) then
					tooltip.description = getText("UI_optionscreen_recommended") .. ":" .. getText("Fluid_Container_Bathtub") .. " " .. getText("ContextMenu_or") .. " " .. getText("Wall_Shower") .. "\r\n" .. sink:getFluidContainer():getContainerName() .. ":" .. getText("IGUI_Animal_UdderNotEnough") .. " (" .. tostring(waterRemaining) .. " " .. getText("Fluid_Of") .. " " .. tostring(waterRequired) .. ")" .. "\r\n" .. tooltip.description
				end
				option.toolTip = tooltip;
				if (waterRemaining < waterRequired) then
					option.notAvailable = true;
				end
			end
		end
	end
end

local TurnOnOff = {
	ClothingDryer = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:isActivated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleClothingDryer:new(getPlayer(), object))
            end
		end,
		getLabelText = function(object)
			if object:isActivated() then return getText("ContextMenu_Turn_Off")
			else return getText("ContextMenu_Turn_On") end
		end
	},
	ClothingWasher = {
		isPowered = function(object)
			-- local fluid_container = object:getFluidContainer()
			-- if (not fluid_container and object:getWaterAmount() <= 0) then return false end
			-- if (fluid_container and fluid_container:getAmount() < fluid_container:getCapacity() * 0.01) then return false end
			return (object:getContainer() and object:getContainer():isPowered()) or object:getModData().machine_activated or object:isActivated() or false
		end,
		isActivated = function(object)
			-- print(string.format("[Lightja] oldactive: %s - newactive: %s",tostring(not object:getFluidContainer() and object:isActivated()),tostring(object:getModData().machine_activated)))
			return (not object:getFluidContainer() and object:isActivated()) or object:getModData().machine_activated
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleClothingWasher:new(getPlayer(), object))
            end
		end,
		getLabelText = function(object)
			if (not object:getFluidContainer() and object:isActivated()) or object:getModData().machine_activated then return getText("ContextMenu_Turn_Off")
			else return getText("ContextMenu_Turn_On") end
		end
	},
	CombinationWasherDryer = {
		isPowered = function(object)
			return (object:getContainer() and object:getContainer():isPowered()) or object:getModData().machine_activated or object:isActivated() or false
		end,
		isActivated = function(object)
			return (object.isModeDryer and object:isModeDryer() and object:isActivated()) or object:getModData().machine_activated or (not object:getFluidContainer() and object:isActivated())
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
				if object.isModeDryer and object:isModeDryer() and object:isActivated() then 
					ISTimedActionQueue.add(ISToggleClothingDryer:new(getPlayer(), object))
				else
					ISTimedActionQueue.add(ISToggleClothingWasher:new(getPlayer(), object))
				end
            end
		end,
		getLabelText = function(object)
			local machine_data = object:getModData()
			if machine_data.machine_activated or object:isActivated() then return getText("ContextMenu_Turn_Off") end
			local fluid_container = object:getFluidContainer()
			if fluid_container and fluid_container:getAmount() > fluid_container:getCapacity() * 0.99 then
				return getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingwasher")
			else
				if fluid_container then
					return getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingwasher")
				else
					if object:isModeDryer() and object:getWaterAmount() == 0 then return getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingdryer") 
					else return getText("UI_PressAToStart").." "..getText("IGUI_ContainerTitle_clothingwasher") end
				end
			end
		end
	},
	Stove = {
		isPowered = function(object)
			return object:getContainer() and object:getContainer():isPowered() or false
		end,
		isActivated = function(object)
			return object:Activated()
		end,
		toggle = function(object)
            if object:getSquare() and luautils.walkAdj(getPlayer(), object:getSquare()) then
                ISTimedActionQueue.add(ISToggleStoveAction:new(getPlayer(), object))
            end
		end,
		getLabelText = function(object)
			if object:Activated() then return getText("ContextMenu_Turn_Off")
			else return getText("ContextMenu_Turn_On") end
		end
	}
}

--overridden functions
function ISFluidContainerPanel:drawTextureIso(texture, x, y, a, r, g, b)
	if not (a and r and g and b) then a = 1; r = 1; g = 1; b = 1; end -- added for weird cases where I add a fluid container and these aren't set which results in spamming errors.
    if texture and texture:getWidthOrig() == 64 * 2 and texture:getHeightOrig() == 128 * 2 then
        ISUIElement.drawTexture(self, texture, x, y, a, r, g, b)
    else
        ISUIElement.drawTextureScaledUniform(self, texture, x, y, 2.0, a, r, g, b)
    end
end

function ISInventoryPage:toggleStove()--identical to vanilla, but needs the updated local TurnOnOff function above
	if UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return end
	local object = self.inventoryPane.inventory:getParent()
	if not object then return end
	local className = object:getObjectName()
	TurnOnOff[className].toggle(object)
end

function ISInventoryPage:syncToggleStove()
	if self.onCharacter then return end
	local isVisible = self.toggleStove:getIsVisible()
	local shouldBeVisible = false
	local containerButton
	local stove, className, label_text = nil, "",""
	if self.inventoryPane.inventory then
		stove = self.inventoryPane.inventory:getParent()
		if stove then
			lightjaRefillFromPipedCollectors(stove)
			className = stove:getObjectName()
			if TurnOnOff[className] and TurnOnOff[className].isPowered(stove) then shouldBeVisible = true end
		end
	end
	for _,cb in ipairs(self.backpacks) do
		if cb.inventory == self.inventoryPane.inventory then
			containerButton = cb
			break
		end
	end
	if not containerButton then
		shouldBeVisible = false
	end
	if isVisible ~= shouldBeVisible and getCore():getGameMode() ~= "Tutorial" then
		self.toggleStove:setVisible(shouldBeVisible)
	end
	if shouldBeVisible then
		label_text = TurnOnOff[className].getLabelText(stove)
		self.toggleStove:setTitle(label_text)
	end    
	local buttonOffset = 1 + (5-getCore():getOptionFontSizeReal())*2
    local textButtonOffset = buttonOffset * 3
	local label_width = getTextManager():MeasureStringX(UIFont.Small, label_text)
	self.toggleStove:setWidth(label_width + 10)
end
