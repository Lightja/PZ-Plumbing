-- Author: Lightja 1/13/2025
-- This mod may be copied/edited/reuploaded by anyone for any reason with no preconditions.

local function yeet(obj)
	-- local square = obj:getSquare()
	-- local x,y,z = square:getX(), square:getY(), square:getZ()
	-- print(string.format("[Lightja] yeeting %s from (%f,%f,%f)...",tostring(obj),x,y,z))
	obj:getSquare():transmitRemoveItemFromSquare(obj)
	-- obj:getSprite():Dispose()
	sledgeDestroy(obj)
end

local function get_translation_by_index(i)
	local translations = {
	    {0,  0, -1},  -- N
        {1, -1, -1},  -- NW
        {2, -1,  0},  -- W
        {3, -1,  1},  -- SW
        {4,  0,  1},  -- S
        {5,  1,  1},  -- SE
        {6,  1,  0},  -- E
        {7,  1, -1},  -- NE
        {8,  0,  0}   -- Max (8, 0, 0)
    }
	if i >= 1 and i <= 9 then
        return translations[i][2], translations[i][3]
    else return nil end
end

local function table_remove(t, item) 
	local found = false
	if item then for i, v in ipairs(t) do if v == item then table.remove(t, i); found = true break end end end
	if not found then print("[Lightja] WARNING: tried to remove non existent item from table.") end
end

local pending_objects_to_delete = {}
local function future_delete_handler()
	local been_deleted = {}
	for i=1,#pending_objects_to_delete do
		local obj = pending_objects_to_delete[i]
		if obj then
			local minutes = obj.minutes_waited
			local wait_duration_mins = 60
			if minutes >= wait_duration_mins then 
				-- print(string.format("[Lightja] future delete handler is deleting %s after 30 minutes pending (%s) and removing it from the list. Total list size %d",tostring(obj.object),tostring(obj.minutes_waited),#pending_objects_to_delete))
				table.insert(been_deleted, obj)
				yeet(obj.object)--theres also a load handler function in the server file for the manhole sprite to be sure unloaded objects get removed when they load back in.
				if #pending_objects_to_delete == 0 then Events.EveryTenMinutes.Remove(future_delete_handler) end
			else
				-- print(string.format("[Lightja] future delete handler is skipping %s until minutes_waited (%s) reaches %f minutes. (total items: %d)",tostring(obj),tostring(minutes),wait_duration_mins,#pending_objects_to_delete))
				obj.minutes_waited = minutes + 10
			end
		end
	end
	for i=1, #been_deleted do
		table_remove(pending_objects_to_delete, been_deleted[i])
	end
end

local function delete_obj_in_future(obj)
	local square = obj:getSquare()
	local x,y,z = square:getX(), square:getY(), square:getZ()
	-- print(string.format("[Lightja] marked %s for delete after 30 minutes pending at (%f,%f,%f)",tostring(obj),x,y,z))
	table.insert(pending_objects_to_delete,{object=obj, minutes_waited=0})
	if #pending_objects_to_delete == 1 then Events.EveryTenMinutes.Add(future_delete_handler) end
end

local function create_temp_obj(sprite)
	local new_obj = IsoObject.new(sprite.square:getCell(), sprite.square, sprite.name..tostring(sprite.num))
	new_obj:getModData().is_hologram = true
	sprite.square:AddSpecialObject(new_obj)
	new_obj:setCustomColor(0.5,0.5,1,0.01)
	-- new_obj:setAlpha(0.6)
	-- new_obj:getSprite():ChangeTintMod(ColorInfo.new(0.3,0.3,1,0.5))--  {r=0.3,b=1,g=0.3,a=0.5})
	-- print(string.format("[Lightja] creating temp sprite %s%s (%s) at (%f,%f,%f)",tostring(sprite.name),tostring(sprite.num),tostring(new_pipe),x,y,z))
	delete_obj_in_future(new_obj)
end

function generate_plumbing_placement_helpers(player,square)
	local x,y,z = square:getX(), square:getY(), square:getZ()
	local found_outside = false
	local num_checks = 0
	local checkedsquare = square
	local checkedcell = checkedsquare:getCell()
	while (not found_outside or checkedcell:getMaxZ() <= 0) and num_checks < 1000 do
		num_checks = num_checks + 1
		if checkedsquare:isOutside() then found_outside = true
		else 
			z = z + 1
			checkedsquare = checkedsquare:getCell():getGridSquare(x, y, z);
			checkedcell = checkedsquare:getCell()
		end
	end
	for i=1,9 do
		local t_x, t_y = get_translation_by_index(i)
		checkedsquare = checkedsquare:getCell():getGridSquare(x + t_x, y + t_y, z)
		if checkedsquare:getFloor() then
			local sprite = {name="street_decoration_01_",num=15,square=checkedsquare}
			create_temp_obj(sprite)
		end
	end
end

local function lightjaCoordString(square)
	return string.format("(%s, %s, %s)",tostring(square:getX()),tostring(square:getY()),tostring(square:getZ()))
end

local function predicateNotBroken(item) return not item:isBroken() end

--should probably use this more to refactor things around a little bit, and to make it easier to add checks later where needed.
function is_pipeable_object(sink)
	if not sink or not sink:getSquare() then return false end
	local sprite = sink:getSprite()
	if not sprite then return false end
	local props = sprite:getProperties()
	if not props then return false end
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars
	return sink:getModData().canBeWaterPiped
		   or props:Is("waterPiped")
		   or props:getFlagsList():contains(IsoFlagType.waterPiped)
		   or (fetch.storeWater and fetch.storeWater == sink)
end

local function predicatePlumbingAdhesive(item)
	return item:hasTag("Tape") or item:hasTag("FiberglassTape") or item:hasTag("Glue") or item:hasTag("Epoxy")
end

local function getMoveableDisplayName(obj)--copied local function from vanilla WorldObjectContextMenu
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

local function check_for_pipe_wrench(playerInv) return playerInv:containsTypeEvalRecurse("PipeWrench", predicateNotBroken) or playerInv:containsTagEvalRecurse("PipeWrench", predicateNotBroken) end

--IGUI_CraftingWindow_Build = "Build",

function lightja_find_collector_in_square(checkedsquare)
	if not checkedsquare then return end
	local checkedobjects = checkedsquare:getObjects()
	for i=1,checkedobjects:size() do
		local checked_object = checkedobjects:get(i-1)
		if checked_object:getSprite():getProperties():Is("IsWaterCollector") then 
			-- print(string.format("[Lightja] found pipeable collector at %s",lightjaCoordString(checkedsquare)))
			return checked_object 
		end
	end
	-- print(string.format("[Lightja] !! No pipeable collector at %s",lightjaCoordString(checkedsquare)))
end

function lightja_find_collectors(checkedsquare)
	local function lightja_find_collectors_in_3x3grid(checkedcell, x, y, z)
		local pipeablecollectors = {}
		for i=1,9 do
			local t_x, t_y = get_translation_by_index(10 - i)--reverse order because index 9 is (0,0) (directly above), this mattered more before I changed it to drain equally
			local overheadsquare = checkedcell:getGridSquare(x + t_x, y + t_y, z);
			local overhead_collector = lightja_find_collector_in_square(overheadsquare)
			if overhead_collector and overhead_collector:getFluidContainer() then table.insert(pipeablecollectors,overhead_collector) end
		end
		return pipeablecollectors
	end
	if not checkedsquare then return end
	local x,y,z = checkedsquare:getX(), checkedsquare:getY(), checkedsquare:getZ()
	local checkedcell = checkedsquare:getCell()
	local pipeablecollectors = lightja_find_collectors_in_3x3grid(checkedcell, x, y, z + 1)
	-- print(string.format("[Lightja] pipeablecollectors in 3x3 grid directly above player: %s (size: %s)",tostring(pipeablecollectors),tostring(#pipeablecollectors)))
	if #pipeablecollectors == 0 then --none found 1 floor up, look for first outdoor square then search out from there
		-- print(string.format("[Lightja] no collectors found in 3x3 directly above sink. Looking for outdoor tile above... z: %s, maxz: %s",tostring(z),tostring(checkedcell:getMaxZ())))
		local found_outside = false
		z = z + 2
		local max_z = checkedcell:getMaxZ()
		while not found_outside and (z < max_z or max_z == 0) do
			local overheadsquare = checkedcell:getGridSquare(x, y, z)
			-- if overheadsquare then print(string.format("[Lightja] checking overheadsquare at %s...",lightjaCoordString(overheadsquare))) else print(string.format("[Lightja] no square found at (%s,%s,%s)",tostring(x),tostring(y),tostring(z))) end
			if overheadsquare and overheadsquare:isOutside() then 
				pipeablecollectors = lightja_find_collectors_in_3x3grid(checkedcell, x, y, z)
				found_outside = true 
				-- print(string.format("[Lightja] found outside tile at %s",lightjaCoordString(overheadsquare)))
			end
			z = z + 1
		end
	end
	return pipeablecollectors
end

local function do_horizontal_plumbing_menu(player, sink)
	
end

--unused atm, should use to refactor areas where this is repeatedly declared
function is_pre_water_shutoff() return getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 < getSandboxOptions():getOptionByName("WaterShutModifier"):getValue() end

local function add_unavailable_tooltip(option, option_label, reason_label)
	option.notAvailable = true;
	local tooltip = ISWorldObjectContextMenu.addToolTip()
	tooltip:setName(option_label);
	tooltip.description = reason_label;
	option.toolTip = tooltip;
end

local function add_vertical_plumbing_tooltip(playerInv, option, plumb_obj_label, sink, has_pipe_wrench)
	local function tally_inventory(playerInv) return {lead_pipes =playerInv:getCountTypeRecurse("LeadPipe"),metal_pipes=playerInv:getCountTypeRecurse("MetalPipe")}	end
	local function has_pipe(items, num_pipes_required)
		return items.metal_pipes + items.lead_pipes >= num_pipes_required
	end
	--start of function execution
	if not has_pipe_wrench then 
		add_unavailable_tooltip(option, plumb_obj_label, getText("Tooltip_NeedWrench", getItemName("Base.PipeWrench")))
	else
		local items = tally_inventory(playerInv)
		local num_vpipes_required = calculate_vpipes_required(sink)
		if not has_pipe(items, num_vpipes_required) then
			local need_pipes_string = getText("Tooltip_NeedWrench", tostring(num_vpipes_required).."x ("..getItemName("Base.MetalPipe").." or "..getItemName("Base.LeadPipe")..")")
			add_unavailable_tooltip(option, plumb_obj_label, need_pipes_string)
		end
	end
end

local function start_vplumbing(worldobjects, player, sink)
	local playerObj = getSpecificPlayer(player)
	local wrench = playerObj:getInventory():getFirstTypeEvalRecurse("PipeWrench", predicateNotBroken) or playerObj:getInventory():getFirstTagEvalRecurse("PipeWrench", predicateNotBroken);
	ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), wrench, true)
	ISTimedActionQueue.add(ISVerticalPlumbItem:new(playerObj, sink, wrench));
end

local function lightjaplumbing_contextmenu(player, context, worldobjects, test)

	local function calc_z_distance(sink, collector)
		if not collector:getSquare() or not sink:getSquare() then print("[Lightja] ERROR failed sanity check at lightjaplumbing_contextmenu.calc_z_distance"); return 99 end --shouldnt happen
		return math.max(1,collector:getSquare():getZ() - sink:getSquare():getZ())
	end
	--start of function execution
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars	
	local playerObj = getSpecificPlayer(player)
	local playerInv = playerObj:getInventory()
	if isDebugEnabled() then 
		lightjaplumbing_debugcontextmenu(playerObj, context, worldobjects, test) 
	end
	if fetch.plumbable_fluid_container then--unused, might use this to add requirements end
		local obj_data = fetch.plumbable_fluid_container:getModData()
		if test == true then return true end
		local collectors = nil
		if obj_data.collectors then 
			collectors = obj_data.collectors
		else 
			collectors = lightja_find_collectors(fetch.plumbable_fluid_container:getSquare())
		end
		local name = getMoveableDisplayName(fetch.plumbable_fluid_container) or "";
		local option = context:addGetUpOption(getText("ContextMenu_PlumbItem", name), worldobjects, ISWorldObjectContextMenu.onPlumbItem, player, fetch.plumbable_fluid_container)
		local items = lightjaplumbing_tally_inventory(playerInv)
		local z_dist = calc_z_distance(fetch.plumbable_fluid_container, collectors[1])
		local has_pipe_wrench = check_for_pipe_wrench(playerInv)
		local has_pipe = has_pipe(items, z_dist)
		local has_adhesive = has_adhesive(items, z_dist)
		if not has_adhesive then
			option.notAvailable = true;
			local tooltip = ISWorldObjectContextMenu.addToolTip()
			tooltip:setName(getText("ContextMenu_PlumbItem", name))
			tooltip.description = string.format("Only have %s of %s required adhesive",tostring(items.adhesive_units),tostring(z_dist-1));--need to add to tooltip_EN to make it translateable, i think its moddable?
			option.toolTip = tooltip;
		end
		if not has_pipe then
			option.notAvailable = true;
			local tooltip = ISWorldObjectContextMenu.addToolTip()
			tooltip:setName(getText("ContextMenu_PlumbItem", name));
			tooltip.description = string.format("Only have %s of %s required pipe items",tostring(items.total_pipes),tostring(z_dist));--need to add to tooltip_EN to make it translateable, i think its moddable?
			option.toolTip = tooltip;
		end
		if not has_pipe_wrench then
			option.notAvailable = true;
			local tooltip = ISWorldObjectContextMenu.addToolTip()
			tooltip:setName(getText("ContextMenu_PlumbItem", name));
			tooltip.description = getText("Tooltip_NeedWrench", getItemName("Base.PipeWrench"));
			option.toolTip = tooltip;
		end
	elseif fetch.canEnableFluids then
		local name = getMoveableDisplayName(fetch.canEnableFluids) or "";
		local option = context:addGetUpOption(getText("UI_mods_ModEnable").." "..getText("IGUI_PlayerClimate_Fluids"), worldobjects, ISWorldObjectContextMenu.onPlumbItem, player, fetch.canEnableFluids);
		local has_pipe_wrench = check_for_pipe_wrench(playerInv)
		option.toolTip = ISToolTip:new()
		option.toolTip:setName(getText("IGUI_Install")..": "..getText("Fluid_Container_Dispenser").." "..getText("Fluid_Container_FluidContainer"))
		option.toolTip.description = getText("Tooltip_NeedWrench", getItemName("Base.PipeWrench")).."\n"..getText("UI_modselector_incompatibleWith").." "..getText("Fluid_Container_Collector");
		if not has_pipe_wrench then option.notAvailable = true end
	end
end
Events.OnPreFillWorldObjectContextMenu.Add(lightjaplumbing_contextmenu)
local function lightjaplumbing_postcontextmenu(player, context, worldobjects, test)
	print(string.format("[Lightja] post context menu..."))
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars
	local playerInv = getSpecificPlayer(player):getInventory()
	local has_pipe_wrench = check_for_pipe_wrench(playerInv)
	if fetch.pipeable_obj then
		local water_obj = fetch.item
		print(string.format("[Lightja]     Found unplumbable object and player has pipe wrench!usesExternalWaterSource: %s",tostring(fetch.pipeable_obj:getUsesExternalWaterSource())))
		local unpiped_plumbable_obj_without_detected_collectors = not fetch.pipeable_obj:getUsesExternalWaterSource() and not fetch.fluidcontainer and not fetch.canBeWaterPiped and has_pipe_wrench
		if unpiped_plumbable_obj_without_detected_collectors then
			print(string.format("[Lightja]         Found unplumbable object without collectors and player has pipe wrench!"))
			local obj_label = getMoveableDisplayName(fetch.pipeable_obj)
			if not context:getOptionFromName(obj_label) then obj_label = getText("ContextMenu_Walk_to") end
			if not context:getOptionFromName(obj_label) then obj_label = getText("ContextMenu_SitGround") end
			print(string.format("[Lightja]         unplumbed sink fetched! obj_label: %s",tostring(obj_label)))
			local plumb_item_option_label = getText("ContextMenu_PlumbItem", "")
			local plumb_item_option = context:insertOptionBefore(obj_label, plumb_item_option_label, player, nil)
			plumb_item_option.notAvailable = true
			local plumb_item_menu = ISContextMenu:getNew(context)
			context:addSubMenu(plumb_item_option, plumb_item_menu)
			local plumbing_helper_option_label = getText("IGUI_DesignationZone_RoofArea")..getText("IGUI_Map_Scale").." "..getText("IGUI_Map_TabLocations").." ("..getText("IGUI_Sleep_OneHour")..")"
			plumb_item_menu:addOption(plumbing_helper_option_label,player,generate_plumbing_placement_helpers,fetch.pipeable_obj:getSquare())
		end
	end
	if fetch.pipeable_obj and advanced_plumbing_enabled() then
		local obj_needs_pipes             = not fetch.pipeable_obj:getUsesExternalWaterSource() or not validate_vpipes(fetch.pipeable_obj)
		local obj_has_pipeable_collectors = #lightja_find_collectors(fetch.pipeable_obj:getSquare()) > 0
		local obj_needs_pipes_unplumbed   = obj_needs_pipes and not fetch.pipeable_obj:getUsesExternalWaterSource()
		local obj_needs_pipes_plumbed     = obj_needs_pipes and not obj_needs_pipes_unplumbed
		local obj_has_pipes_plumbed       = fetch.pipeable_obj:getUsesExternalWaterSource() and validate_vpipes(fetch.pipeable_obj)
		local obj_label       = getMoveableDisplayName(fetch.pipeable_obj)
		local plumb_obj_label = "ADV:"..getText("ContextMenu_PlumbItem", obj_label)
		local plumbing_option = context:getOptionFromName(plumb_obj_label)
		local water_option    = context:getOptionFromName(obj_label)
		if not water_option then 
			local obj_label_group = fetch.pipeable_obj:getSprite():getProperties():Val("CustomName")
			water_option = context:getOptionFromName(obj_label_group)
			if not water_option then return end
		end
		local water_menu      = context:getSubMenu(water_option.subOption)
		assert(water_menu, string.format("[Lightja] pipeable object found, option matching %s or %s found, but no submenu found.",tostring(obj_label),tostring(obj_label_group)))
		if plumbing_option and not is_pre_water_shutoff() then context:removeOptionByName(plumb_obj_label) end
		if obj_needs_pipes then
			local vertical_plumbing_option = water_menu:addGetUpOption(plumb_obj_label, worldobjects, start_vplumbing, player, fetch.pipeable_obj)
			add_vertical_plumbing_tooltip(playerInv, vertical_plumbing_option, plumb_obj_label, fetch.pipeable_obj, has_pipe_wrench)
		end
		if has_pipe_wrench then
			water_menu:addGetUpOption(plumb_obj_label.."(H)", worldobjects, do_horizontal_plumbing_menu, player, fetch.pipeable_obj)
			local nudge_pipes_label = getText("Fluid_Swap").. " " ..getText("IGUI_CharacterDebug_Position")
			water_menu:addOption(nudge_pipes_label, player, nudge_vpipes, fetch.pipeable_obj)
			local toggle_pipe_visibility_label = getText("Fluid_Swap").. " " ..getText("IGUI_SearchMode_Tip_Visibility_Title")
			water_menu:addOption(toggle_pipe_visibility_label, player, toggle_pipe_visibility, fetch.pipeable_obj:getSquare())
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(lightjaplumbing_postcontextmenu)

--IGUI_SearchMode_Tip_Visibility_Title
--Fluid_Swap = "Switch",
--IGUI_CharacterDebug_Position = "Position",
-- Fluid_Container_Collector = "Rain Collector",

function ISFluidInfoUI:update_flow_slider(value, slider)
	slider.valueLabel:setName(string.format("%s: %d%%",getText("IGUI_Open"), value))
	local sink_data = self.owner:getModData()
	sink_data.ui_flow_rate = value / 100
end

local tabletop_fluid = {
	["Espresso"]=true,
	["Coffee"]=true,
	["Tabletop Soda"]=true,
	["Bar Tap"]=true
}
function is_tabletop_dispenser(item)
	local sprite = item:getSprite()
	if sprite then
		local props = sprite:getProperties()
		if props then
			return props:Is("IsTableTop") and tabletop_fluid[props:Val("GroupName")]
		end
	end
	return false
end

function lightjaRefillFromPipedCollectors(sink, flow_multiplier)
	local fetch_specific_flow_multiplier = 2.12345
	local invalid_transfer_reason = {--CanTransfer alone doesnt work well for this because I want to ignore certain reasons like source/dest being empty/full under certain cases. Full/empty statuses get handled manually through the function, so I dont care about those for this.
		[Translator.getFluidText("Fluid_Reason_Source_Null")]=true,--other checks probably suffice, but kept for safety
		[Translator.getFluidText("Fluid_Reason_Target_Null")]=true,--other checks probably suffice, but kept for safety
		[Translator.getFluidText("Fluid_Reason_Target_Filter")]=true,--these are the two I care about
		[Translator.getFluidText("Fluid_Reason_Target_Locked")]=true --these are the two I care about
	}
	local function lightjaTallyCollectors(sink_fluid_container, available_collectors)
		collectors_data = {}
		for _, collector_obj in ipairs(available_collectors) do
			local projected_transfer_result = FluidContainer.GetTransferReason(collector_obj:getFluidContainer(), sink_fluid_container, false)
			-- print(string.format("[Lightja] projected transfer result: %s - %s",tostring(projected_transfer_result),tostring(invalid_transfer_reason[projected_transfer_result])))
			if not invalid_transfer_reason[projected_transfer_result] and collector_obj:getFluidContainer():getAmount() > 0 then
				local collector_data = {}
				collector_data.fluid_container = collector_obj:getFluidContainer()
				collector_data.remaining_volume = collector_data.fluid_container:getAmount()
				collector_data.capacity = collector_data.fluid_container:getCapacity()
				collector_data.collector = collector_obj
				collector_data.fluid_container = collector_obj:getFluidContainer()
				collector_data.amount_to_transfer = 0
				-- print(string.format("[Lightja] Volume: %s, Capacity: %s, amount_to_transfer: %s",tostring(collector_data.remaining_volume),tostring(collector_data.capacity),tostring(collector_data.amount_to_transfer)))
				table.insert(collectors_data,collector_data)
			-- else
				-- print(string.format("[Lightja] skipped collector in tally because %s - %s",tostring(projected_transfer_result),tostring(invalid_transfer_reason[projected_transfer_result])))
			end
		end
		return collectors_data
	end
	local function lightjaCalculateFluidTransfers(sink_fluid_container, collectors_data, max_transfer_volume)
		local volume_calculated = 0
		local num_checks = 0 -- safety measure against infinite loops, havent actually hit one.
		while volume_calculated < max_transfer_volume * 0.99 and num_checks < 100 do
			num_checks = num_checks + 1
			local num_collectors = 0
			for _, collector_data in ipairs(collectors_data) do
				local projected_transfer_result = FluidContainer.GetTransferReason(sink_fluid_container,collector_data.fluid_container, false)
			-- print(string.format("[Lightja] projected transfer result: %s - %s",tostring(projected_transfer_result),tostring(invalid_transfer_reason[projected_transfer_result])))
				if collector_data.remaining_volume > 0.01 and not invalid_transfer_reason[projected_transfer_result] then num_collectors = num_collectors + 1 end--else print(string.format("[Lightja] skipped collector because %s",tostring(projected_transfer_result))) end
			end
			if num_collectors == 0 then num_collectors = 1 end
			local transfer_volume_per = max_transfer_volume / num_collectors
			for _, collector_data in ipairs(collectors_data) do
				if collector_data.remaining_volume > 0.01 and collector_data.remaining_volume < transfer_volume_per then transfer_volume_per = collector_data.remaining_volume end
			end
			for _, collector_data in ipairs(collectors_data) do
				collector_data.amount_to_transfer = collector_data.amount_to_transfer + math.min(transfer_volume_per, collector_data.remaining_volume)
				collector_data.remaining_volume = collector_data.remaining_volume - collector_data.amount_to_transfer
				volume_calculated = volume_calculated + transfer_volume_per
				-- print(string.format("[Lightja] found %s units of fluid to pipe from collector, primary fluid %s",tostring(collector_data.amount_to_transfer),tostring(collector_data.fluid_container:getPrimaryFluid())))
			end
		end
		return collectors_data
	end
	local function is_all_water(fluid_container)
		local total_liquid = fluid_container:getAmount()
		local water_amount = fluid_container:getSpecificFluidAmount(Fluid.Water) + fluid_container:getSpecificFluidAmount(Fluid.TaintedWater)
		return (total_liquid - water_amount) < 0.1
	end
	local function remaining_filter_units(sink)--would like to add, but probably unpopular
		return 9999
		-- return filter_units sink:getModData().waterFilterUnits or 0
	end
	local function use_filter(sink, amount)--would like to add, but probably unpopular
		return
		-- local sink_data = sink:getModData()
		-- local current_units = sink_data.waterFilterUnits or 0
		-- sink_data.waterFilterUnits = math.max(0,sink_data.waterFilterUnits - amount)
	end
	--start of function execution
	if flow_multiplier == fetch_specific_flow_multiplier and sink:getModData().fluids_ui_open == true then return end
	if flow_multiplier == nil then flow_multiplier = 1 end
	local fluid_container = sink:getFluidContainer()
	local sink_square = sink:getSquare()
	if sink and sink_square and fluid_container and sink:getUsesExternalWaterSource() and not is_tabletop_dispenser(sink) then--maybe its fine to allow plumbable dispensers?
		if fluid_container:isFull() then return end
		local capacity = fluid_container:getCapacity()
		local cur_volume = fluid_container:getAmount()
		local max_transfer_volume = 1 * flow_multiplier
		local container_name = fluid_container:getContainerName()
		if container_name == "Bath" or container_name == "Shower" then fluid_container:setCapacity(100.0) end--added 1/17/2025 to fix capacity for people who already plumbed baths, but should eventually remove since it's pointless in the happy path
		if container_name == "ComboWasherDryer" or container_name == "WashingMachine" then max_transfer_volume = capacity
		elseif cur_volume < (capacity / 2) then 
			max_transfer_volume = math.max(max_transfer_volume,((capacity / 2) - cur_volume)) 
		end
		local transferred_volume = 0
		if cur_volume < capacity then
			local preWaterShutoff = getGameTime():getWorldAgeHours() / 24 + (getSandboxOptions():getTimeSinceApo() - 1) * 30 < getSandboxOptions():getOptionByName("WaterShutModifier"):getValue();
			local amount_remaining = capacity - cur_volume
			local available_collectors = lightja_find_collectors(sink_square)
			if #available_collectors == 0 and preWaterShutoff then 
				-- print("[Lightja] refilling from water line because there are no collectors.")
				fluid_container:addFluid(Fluid.Water, max_transfer_volume)
				return
			end
			local collectors_data = lightjaTallyCollectors(fluid_container,available_collectors)
			if #collectors_data == 0 and preWaterShutoff then 
				-- print("[Lightja] refilling from water line because collectors are empty.")
				fluid_container:addFluid(Fluid.Water, max_transfer_volume)
				return
			end
			collectors_data = lightjaCalculateFluidTransfers(fluid_container, collectors_data, max_transfer_volume)
			for _, donor in ipairs(collectors_data) do
				local donor_total_fluid_amount = donor.fluid_container:getAmount()
				local donor_water_amount = donor.fluid_container:getSpecificFluidAmount(Fluid.Water) + donor.fluid_container:getSpecificFluidAmount(Fluid.TaintedWater)
				local xfer_amount = donor.amount_to_transfer
				transferred_volume = transferred_volume + xfer_amount
				if is_all_water(donor.fluid_container) and remaining_filter_units(sink) > 0 then
					-- print(string.format("[Lightja] collector piping %s units of (purified) tainted water",tostring(xfer_amount)))
					if remaining_filter_units(sink) > xfer_amount then
						if not donor.fluid_container:isEmpty() then 
							fluid_container:addFluid(Fluid.Water, xfer_amount)
							donor.fluid_container:removeFluid(xfer_amount)
							if LightjaRainManager and LightjaRainManager.UpdateCollector then LightjaRainManager.UpdateCollector(donor.collector) end
							use_filter(sink, xfer_amount)
						end
					else--Should be impossible currently. Can be used to add functionality surrounding water filters as a required item for purification
						print(string.format("[Lightja] ERROR failed sanity check at lightjaCalculateFluidTransfers, tried to use unfiltered tainted water."))
						local filtered_xfer_amount = remaining_filter_units(sink)
						local unfiltered_xfer_amount = xfer_amount - filtered_xfer_amount
						use_filter(sink, filtered_xfer_amount)
						fluid_container:addFluid(Fluid.Water, filtered_xfer_amount)
						fluid_container:addFluid(Fluid.Water, unfiltered_xfer_amount)--should be changed to tainted water if filter is added
					end
				else
					fluid_container:transferFrom(donor.collector:getFluidContainer(), xfer_amount)--ref to donor.fluid_container?
					if LightjaRainManager and LightjaRainManager.UpdateCollector then LightjaRainManager.UpdateCollector(donor.collector) end
				end
				cur_volume = cur_volume + xfer_amount
				if cur_volume >= capacity * 0.99 then 
					-- print(string.format("[Lightja] cur_volume of %s is 99+ percent of capacity (%s) - capping container off",tostring(cur_volume),tostring(capacity)))
					fluid_container:adjustAmount(fluid_container:getCapacity()) 
				end
			end
		end
	end
end

CleanBandages = CleanBandages or {}
function CleanBandages.onClean(playerObj, bandage_data) 
	local recipe = getScriptManager():getCraftRecipe("Base.CleanBandage")
	if not bandage_data or not bandage_data.items then return end
	for _, itemdata in ipairs(bandage_data.items) do 
		for i=1, itemdata.qty do 
			ISTimedActionQueue.add(ISWashBandage:new(playerObj, itemdata.item, bandage_data.waterObject, recipe)) 
		end 
	end
end

function lightja_count_bandages(playerInv)
	local items = {}
	local num_bandages = playerInv:getCountTypeRecurse("Base.BandageDirty")
	local num_denim     = playerInv:getCountTypeRecurse("Base.DenimStripsDirty")
	local num_leather    = playerInv:getCountTypeRecurse("Base.LeatherStripsDirty")
	local num_rags  = playerInv:getCountTypeRecurse("Base.RippedSheetsDirty")
	if num_bandages > 0 then table.insert(items,{item="Base.BandageDirty", qty=num_bandages}) end
	if num_denim > 0     then table.insert(items,{item="Base.DenimStripsDirty", qty=num_denim}) end
	if num_leather > 0    then table.insert(items,{item="Base.LeatherStripsDirty", qty=num_leather}) end
	if num_rags > 0  then table.insert(items,{item="Base.RippedSheetsDirty", qty=num_rags}) end
	-- print(string.format("[Lightja] item types counted: %s - Bnd: %s, Rag: %s, Dnm: %s, Lth: %s",tostring(#items),tostring(num_bandages),tostring(num_rags),tostring(num_denim),tostring(num_leather)))
	return items
end

function lightja_washbandagesmenu(items, sink, player, context)
	local available_water = 0
	local fluid_capacity = 0
	local fluid_container = sink:getFluidContainer()
	if fluid_container then 
		available_water = fluid_container:getSpecificFluidAmount(Fluid.Water) 
		fluid_capacity = fluid_container:getCapacity()
	else available_water = sink:getWaterAmount() 
	end
	if available_water >= fluid_capacity/2 and sink:getUsesExternalWaterSource() then available_water = 9999 end --kluge: assume there is infinite water to pipe if >50% full, the default minimum fill. Calculation too expensive, timed action isValid will prevent overuse of fluid
	if available_water < 1 then return end
	local playerObj = getSpecificPlayer(player)
	local playerInv = playerObj:getInventory()
	local items = lightja_count_bandages(playerInv)
	if #items == 0 then return end
	local total_count = 0
	for _, item in ipairs(items) do total_count = total_count + tonumber(item.qty) end
	local tainted_water = false
	local tooltip = nil
	local notAvailable = false
	local recipe = getScriptManager():getRecipe("Base.Clean Bandage")
	if (sink:getFluidContainer() and sink:getFluidContainer():getAmount() - available_water > 0.1) or sink:isTaintedWater() then tainted_water = true end
	if tainted_water and getSandboxOptions():getOptionByName("EnableTaintedWaterText"):getValue() then
		tooltip = ISWorldObjectContextMenu.addToolTip()
		tooltip.description =  " <RGB:1,0.5,0.5> " .. getText("Tooltip_item_TaintedWater")
		tooltip.maxLineWidth = 512
		notAvailable = true
	end
	local option_text = getText("ContextMenu_CleanBandageEtc") .. "(" .. tostring(math.min(total_count,math.floor(available_water)))
	-- if total_count > math.floor(available_water) then option_text = option_text .. " of " .. tostring(total_count) end
	option_text = option_text .. ")"
	local bandage_data = {waterObject=sink, items=items, available_water=available_water}
	local option = context:addActionsOption(option_text, CleanBandages.onClean, bandage_data)
	option.toolTip = tooltip
	option.notAvailable = notAvailable
end

ISWorldObjectContextMenu.onFluidWashYourself = function(playerObj, sink, soapList)--identical to onWashYourself except the timed action
	if not sink:getSquare() or not luautils.walkAdj(playerObj, sink:getSquare(), true) then
		return
	end
	ISTimedActionQueue.add(ISFluidWashYourself:new(playerObj, sink, soapList));
end

ISWorldObjectContextMenu.onFluidWashClothing = function(playerObj, sink, soapList, washList, singleClothing, noSoap)--identical to onWashClothing except the timed action
	if not sink:getSquare() or not luautils.walkAdj(playerObj, sink:getSquare(), true) then
		return
	end
	if not washList then
		washList = {};
		table.insert(washList, singleClothing);
	end
	for i,item in ipairs(washList) do
		local bloodAmount = 0
		local dirtAmount = 0
		if instanceof(item, "Clothing") then
			if BloodClothingType.getCoveredParts(item:getBloodClothingType()) then
				local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
				for j=0, coveredParts:size()-1 do
					local thisPart = coveredParts:get(j)
					bloodAmount = bloodAmount + item:getBlood(thisPart)
				end
			end
			if item:getDirtyness() > 0 then
				dirtAmount = dirtAmount + item:getDirtyness()
			end
		else
			bloodAmount = bloodAmount + item:getBloodLevel()
		end
		ISTimedActionQueue.add(ISFluidWashClothing:new(playerObj, sink, soapList, item, bloodAmount, dirtAmount, noSoap))
	end
end


