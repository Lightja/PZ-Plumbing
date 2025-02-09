-- Author: Lightja 1/31/2025
-- This mod may be copied/edited/reuploaded by anyone for any reason with no preconditions.


function direction_coords_string(X, Y)
    local directions = {
        { 0, -1, "N" },
        { 1, -1, "NE"},
        { 1,  0, "E" },
        { 1,  1, "SE"},
        { 0,  1, "S" },
        {-1,  1, "SW"},
        {-1,  0, "W" },
        {-1, -1, "NW"},
        { 0,  0, "Origin"}
    }
    for _, direction in ipairs(directions) do
        if direction[1] == X and direction[2] == Y then
            return direction[3]
        end
    end
end


function square_string(isoSquare) return string.format("(%s,%s,%s)",tostring(isoSquare:getX()),tostring(isoSquare:getY()),tostring(isoSquare:getZ())) end

local function create_sprite(player, sprite)
	-- print(string.format("[Lightja] creating sprite %s%s",tostring(sprite.name),tostring(sprite.num)))
	local new_pipe = IsoObject.new(sprite.square:getCell(), sprite.square, sprite.name..tostring(sprite.num))
	new_pipe:getModData().is_hologram = true
	square:AddSpecialObject(new_pipe)
end

local function lightja_makeplayerdirtyfortest()
	local player = getSpecificPlayer(0)
    for i=0,16 do
        local type = BodyPartType.FromIndex(i);
		player:addDirt(BloodBodyPartType.FromIndex(i), nil, false);
        player:addBlood(BloodBodyPartType.FromIndex(i), false, true, false);
	end
end

local function lightja_unplumbfortest()
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars
	local obj = fetch.storeWater or fetch.fluidcontainer or fetch.Lightja_storeWater or fetch.Lightja_fluidcontainer
	if obj then	obj:setUsesExternalWaterSource(false) end
end

local function lightja_enablewatertest()
	getSandboxOptions():set("WaterShutModifier",9999)
end

local function lightja_disablewatertest()
	getSandboxOptions():set("WaterShutModifier",0)
end

local function lightja_enablepowertest()
	getSandboxOptions():set("ElecShutModifier",9999)
end

local function lightja_settestcheats(player)
	player:setGodMod(true)
	player:setGodMod(false)
	player:setInvisible(false)
	player:setBuildCheat(true)
	player:setMovablesCheat(true)
	player:setUnlimitedCarry(true)
	player:setFastMoveCheat(true)
	player:setUnlimitedEndurance(true)
	player:setZombiesDontAttack(true)
	player:setNoClip(true)
	player:setTimedActionInstantCheat(false)
	player:setFastMoveCheat(true)
end

local function lightja_restoredeletedtestitems()
	local player = getSpecificPlayer(0)
	local playerInv = player:getInventory()
	local player_data = player:getModData()
	local deleted_items_list = player_data.lightja_test_deleted_items
	if deleted_items_list == nil then return end
	for i = 1, #deleted_items_list do
		local new_item = instanceItem(deleted_items_list[i])
		if new_item then playerInv:addItem(new_item) else print(string.format("[Lightja] ERROR: failed to restore deleted test item %s.",tostring(deleted_items_list[i]))) end
	end
end

local function lightja_unequipitemfortest(player, unequipped_item)
	print(string.format("[Lightja] attempting to unequip item %s for test",tostring(unequipped_item)))
	player:removeWornItem(unequipped_item)
	if instanceof(unequipped_item, "HandWeapon") and unequipped_item:canBeActivated() then
		unequipped_item:setActivated(false)
	end
	if unequipped_item == player:getPrimaryHandItem() then
		if (unequipped_item:isTwoHandWeapon() or unequipped_item:isRequiresEquippedBothHands()) and unequipped_item == player:getSecondaryHandItem() then
			player:setSecondaryHandItem(nil);
		end
		player:setPrimaryHandItem(nil);
	end
		if unequipped_item == player:getSecondaryHandItem() then
		if (unequipped_item:isTwoHandWeapon() or unequipped_item:isRequiresEquippedBothHands()) and unequipped_item == player:getPrimaryHandItem() then
			player:setPrimaryHandItem(nil);
		end
		player:setSecondaryHandItem(nil);
	end
	sendEquip(player)
	triggerEvent("OnClothingUpdated", player)
	if isClient() then
		ISInventoryPage.renderDirty = true
	end
end

local function lightja_equipitemfortest(player, equipped_item)
	if (instanceof(equipped_item, "InventoryContainer") or equipped_item:hasTag("Wearable")) and equipped_item:canBeEquipped() ~= "" then
		player:removeFromHands(equipped_item);
		player:setWornItem(equipped_item:canBeEquipped(), equipped_item);
	elseif equipped_item:getCategory() == "Clothing" then
		if equipped_item:getBodyLocation() ~= "" then
			player:setWornItem(equipped_item:getBodyLocation(), equipped_item);
		end
	end
end

local function lightja_deleteallplayeritemsfortest()
	local player = getSpecificPlayer(0)
	local playerInv = player:getInventory()
	local removed_items = {}
	local player_items = playerInv:getItems()
	for i=1, player_items:size() do
		local player_item = player_items:get(i-1)
		if player_item then
			if player:isEquipped(player_item) then 
				lightja_unequipitemfortest(player,player_item)
				print(string.format("[Lightja] detected equipped item %s for test",tostring(player_item)))
			end
			table.insert(removed_items,player_item)
		else
			print("[Lightja] skipped deleting nil item for test...")
		end
	end
	for i=1, #removed_items do
		playerInv:DoRemoveItem(removed_items[i])
		print(string.format("[Lightja] deleted %s for test",tostring(removed_items[i])))
	end
	local old_deleted_items = player:getModData().lightja_test_deleted_items
	if old_deleted_items == nil or #old_deleted_items < #removed_items then player:getModData().lightja_test_deleted_items = removed_items end
end

local function lightja_createtropicalstormtest()
	if isClient() then
		getClimateManager():transmitStopWeather();
	else
		getClimateManager():stopWeatherAndThunder()
	end
	local clim = getWorld():getClimateManager();
	if clim then
		clim:triggerCustomWeatherStage(8,48);
	end
end

local lightja_test_items = {
	"Base.PipeWrench",
	"Base.PipeWrench",
	"Base.Multitool",
	"Base.Multitool",
	"Base.LeadPipe",
	"Base.LeadPipe",
	"Base.LeadPipe",
	"Base.LeadPipe",
	"Base.LeadPipe",
	"Base.PenMultiColor",
	"Base.PenMultiColor",
	"Base.BallPeenHammer",
	"Base.BallPeenHammer",
	"Base.Sledgehammer",
	"Base.Sledgehammer",
	"Moveables.lighting_outdoor_01_49",
	"Moveables.lighting_outdoor_01_49",
	"Base.PopBottle",
	"Base.PopBottle",
	"Base.BucketEmpty",
	"Base.BucketEmpty",
	"Base.BucketEmpty",
	"Base.Mov_ChromeSink",
	"Base.Mov_ChromeSink",
	"Moveables.constructedobjects_01_45",
	"Moveables.constructedobjects_01_45",
	"Moveables.carpentry_02_124",
	"Moveables.carpentry_02_124",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.RippedSheetsDirty",
	"Base.Torch",
	"Base.Battery",
	"Base.WristWatch_Left_DigitalBlack",
}
local lightja_test_clothes = {
	"Base.LongJohns",
	"Base.Hat_ShemaghFull",
}
local function lightja_giveplayeritemsfortest()
	local player = getSpecificPlayer(0)
	local playerInv = player:getInventory()
	for i = 1, #lightja_test_items do
		local new_item = instanceItem(lightja_test_items[i])
		if new_item then playerInv:addItem(new_item) else print(string.format("[Lightja] ERROR: failed to generate test item %s.",tostring(lightja_test_items[i]))) end
	end
	for i = 1, #lightja_test_clothes do
		local new_item = instanceItem(lightja_test_clothes[i])
		if new_item then 
			playerInv:addItem(new_item) 
			lightja_equipitemfortest(player, new_item)
		else print(string.format("[Lightja] ERROR: failed to generate test clothing item %s.",tostring(lightja_test_clothes[i]))) end
	end
end

local function lightja_init_test()
	lightja_enablepowertest()
	local player = getSpecificPlayer(0)--getPlayer() probably better
	lightja_settestcheats(player)
	player:getStats():setThirst(1)
	lightja_createtropicalstormtest()
	lightja_deleteallplayeritemsfortest()
	lightja_giveplayeritemsfortest()
	lightja_makeplayerdirtyfortest()
end

local function lightja_teleportroof()
	local player = getPlayer()
	local checkedsquare = player:getSquare()
	local checkedcell = checkedsquare:getCell()
	local x,y,z = checkedsquare:getX(), checkedsquare:getY(), checkedsquare:getZ()
	local found_outside = false
	local num_checks = 0
	print(string.format("[Lightja]  cell max z: %s",checkedcell:getMaxZ()))
	while (not found_outside or checkedcell:getMaxZ() <= 0) and num_checks < 1000 do
		num_checks = num_checks + 1
		if checkedsquare:isOutside() then found_outside = true
		else 
			z = z + 1
			checkedsquare = checkedsquare:getCell():getGridSquare(x, y, z);
			checkedcell = checkedsquare:getCell()
		end
	end
	player:setZ(z)
end
local function lightja_teleportgnd() getPlayer():setZ(0) end
local function lightja_teleportb() getPlayer():setZ(-1) end

local function add_unique_option(context, label, player, func, arg)
	if not context:getOptionFromName(label) then 
		context:addOption(label, player, func, arg)
	else
		print(string.format("[LightjaPlumbing] Skipped adding debug option %s", tostring(label)))
	end
end


local function get_fetch_item_data()--"fetch" is the function that gathers data on clicked objects
	local function to_bin(bool) if bool then return tostring("1") else return tostring("0") end end
	ISWorldObjectContextMenu.fetchVars = ISWorldObjectContextMenu.fetchVars or {}
	local fetch = ISWorldObjectContextMenu.fetchVars
	local obj = fetch.storeWater or fetch.fluidcontainer or fetch.item
	if not obj then print("[Lightja] ERROR! Failed sanity check at get_fetch_item_direction. fetch.item was, but should not be nil") end
	local obj_name = obj:getObjectName()
	local direction = obj:getFacing()
	local dir_string = direction_string(direction)
	local square = obj:getSquare()
	local cell = square:getCell()
	local x,y,z = square:getX(),square:getY(), square:getZ()
	local square_w = cell:getGridSquare(x-1, y  , z)
	local square_e = cell:getGridSquare(x+1, y  , z)
	local square_n = cell:getGridSquare(x  , y-1, z)
	local square_s = cell:getGridSquare(x  , y+1, z)
	local wall_w = to_bin(square:isWallTo(square_w) or square:isWindowTo(square_w))
	local wall_e = to_bin(square:isWallTo(square_e) or square:isWindowTo(square_e))
	local wall_n = to_bin(square:isWallTo(square_n) or square:isWindowTo(square_n))
	local wall_s = to_bin(square:isWallTo(square_s) or square:isWindowTo(square_s))	
	print(string.format("[Lightja] Fetch object (%s) at %s facing: %s Walls: %s, AdvPb: %s, AdvPbMenuDisabled: %s",tostring(obj_name),square_string(square),tostring(dir_string),wall_string,tostring(advanced_plumbing_enabled()),tostring(advanced_plumbing_context_menu_disabled())))
end


function lightjaplumbing_debugcontextmenu(player, context, worldobjects, test)
	lightjatest = context:getOptionFromName("LIGHTJATEST")
	local lightjatestmenu = nil
	if lightjatest then
		lightjatestmenu = context:getSubMenu(lightjatest.subOption)
	else
		lightjatest = context:addOption("LIGHTJATEST", nil, nil)
		lightjatestmenu = ISContextMenu:getNew(context)
		context:addSubMenu(lightjatest, lightjatestmenu)
	end
	add_unique_option(lightjatestmenu,"DELETEALL+START", player, lightja_init_test)
	add_unique_option(lightjatestmenu,"TELEPORTROOF", player, lightja_teleportroof)
	add_unique_option(lightjatestmenu,"TELEPORT Z 0", player, lightja_teleportgnd)
	add_unique_option(lightjatestmenu,"TELEPORT Z-1", player, lightja_teleportb)
	add_unique_option(lightjatestmenu,"MAKE STORM", player, lightja_createtropicalstormtest)
	add_unique_option(lightjatestmenu,"MAKE DIRTY", player, lightja_makeplayerdirtyfortest)
	add_unique_option(lightjatestmenu,"WATER:ON", player, lightja_enablewatertest)
	add_unique_option(lightjatestmenu,"WATER:OFF", player, lightja_disablewatertest)
	add_unique_option(lightjatestmenu,"RESTORE", player, lightja_restoredeletedtestitems)
	add_unique_option(lightjatestmenu,"UNPLUMB", player, lightja_unplumbfortest)
	add_unique_option(lightjatestmenu,"GENERATEHELPERS", player, generate_plumbing_placement_helpers, player:getSquare())
	add_unique_option(lightjatestmenu,"GETDATA", player, get_fetch_item_data)
	add_unique_option(lightjatestmenu,"PLUMBOPTIONS", player, do_plumbing_options_window)
	
	-- lightja_debugdisplay300sprites(player, context, worldobjects, test, "INDUSTRY SPRITES", "industry_02_")
	-- lightja_debugdisplay300sprites(player, context, worldobjects, test, "STREET SPRITES", "street_decoration_01_")
end

--unused functions
local function lightjaPrintArray(array)
	for i=1,array:size() do
		print(string.format("[Lightja] %s: %s",tostring(i), tostring(array:get(i-1))))
	end
end 

local function lightjaPrintProperties(props)
	if not props then return end
	local names = props:getPropertyNames()
	local tags = props:getFlagsList()
	for i=1, names:size() do
		print(string.format("[Lightja] property %s: %s - %s",tostring(i), tostring(names:get(i-1)), tostring(props:Val(names:get(i-1))) ))
	end
	for i=1, tags:size() do
		print(string.format("[Lightja] tag %s: %s",tostring(i), tostring(tags:get(i-1)) ))
	end
end

added_handlers = added_handlers or {}
local function add_event_handler_unique(event, handler)
    if not added_handlers[handler] then
        event.Add(handler)
        added_handlers[handler] = true
        print(string.format("[LightjaPlumbing] Handler added: %s", tostring(handler)))
    else
        print(string.format("[LightjaPlumbing] Skipped duplicate handler: %s", tostring(handler)))
    end
end

local function lightja_debugdisplay300sprites(player, context, worldobjects, test, label, sprite)--mostly useless now that I know how tilezed and the brush tool work, but keeping because sunk cost fallacy
	local pipeoption = context:addOption(label, nil, nil)
	local pipemenu = ISContextMenu:getNew(context)
	context:addSubMenu(pipeoption, pipemenu)
	local option000x     = pipemenu:addOption("000", nil, nil)
	local option000xmenu = ISContextMenu:getNew(pipemenu)
	pipemenu:addSubMenu(option000x,option000xmenu)
	local option100x     = pipemenu:addOption("100", nil, nil)
	local option100xmenu = ISContextMenu:getNew(pipemenu)
	pipemenu:addSubMenu(option100x,option100xmenu)
	local option200x     = pipemenu:addOption("200", nil, nil)
	local option200xmenu = ISContextMenu:getNew(pipemenu)
	pipemenu:addSubMenu(option200x,option200xmenu)
	local option00     = option000xmenu:addOption("00", nil, nil)
	local option10     = option000xmenu:addOption("10", nil, nil)
	local option20     = option000xmenu:addOption("20", nil, nil)
	local option30     = option000xmenu:addOption("30", nil, nil)
	local option40     = option000xmenu:addOption("40", nil, nil)
	local option50     = option000xmenu:addOption("50", nil, nil)
	local option60     = option000xmenu:addOption("60", nil, nil)
	local option70     = option000xmenu:addOption("70", nil, nil)
	local option80     = option000xmenu:addOption("80", nil, nil)
	local option90     = option000xmenu:addOption("90", nil, nil)
	local option00menu = ISContextMenu:getNew(option000xmenu)
	local option10menu = ISContextMenu:getNew(option000xmenu)
	local option20menu = ISContextMenu:getNew(option000xmenu)
	local option30menu = ISContextMenu:getNew(option000xmenu)
	local option40menu = ISContextMenu:getNew(option000xmenu)
	local option50menu = ISContextMenu:getNew(option000xmenu)
	local option60menu = ISContextMenu:getNew(option000xmenu)
	local option70menu = ISContextMenu:getNew(option000xmenu)
	local option80menu = ISContextMenu:getNew(option000xmenu)
	local option90menu = ISContextMenu:getNew(option000xmenu)
	option000xmenu:addSubMenu(option00,option00menu)
	option000xmenu:addSubMenu(option10,option10menu)
	option000xmenu:addSubMenu(option20,option20menu)
	option000xmenu:addSubMenu(option30,option30menu)
	option000xmenu:addSubMenu(option40,option40menu)
	option000xmenu:addSubMenu(option50,option50menu)
	option000xmenu:addSubMenu(option60,option60menu)
	option000xmenu:addSubMenu(option70,option70menu)
	option000xmenu:addSubMenu(option80,option80menu)
	option000xmenu:addSubMenu(option90,option90menu)
	add_unique_option(option00menu, "0", player, create_sprite, {name=sprite,square=player:getSquare(), num=0})
	add_unique_option(option00menu, "1", player, create_sprite, {name=sprite,square=player:getSquare(), num=1})
	add_unique_option(option00menu, "2", player, create_sprite, {name=sprite,square=player:getSquare(), num=2})
	add_unique_option(option00menu, "3", player, create_sprite, {name=sprite,square=player:getSquare(), num=3})
	add_unique_option(option00menu, "4", player, create_sprite, {name=sprite,square=player:getSquare(), num=4})
	add_unique_option(option00menu, "5", player, create_sprite, {name=sprite,square=player:getSquare(), num=5})
	add_unique_option(option00menu, "6", player, create_sprite, {name=sprite,square=player:getSquare(), num=6})
	add_unique_option(option00menu, "7", player, create_sprite, {name=sprite,square=player:getSquare(), num=7})
	add_unique_option(option00menu, "8", player, create_sprite, {name=sprite,square=player:getSquare(), num=8})
	add_unique_option(option00menu, "9", player, create_sprite, {name=sprite,square=player:getSquare(), num=9})
	add_unique_option(option10menu, "10", player, create_sprite, {name=sprite,square=player:getSquare(), num=10})
	add_unique_option(option10menu, "11", player, create_sprite, {name=sprite,square=player:getSquare(), num=11})
	add_unique_option(option10menu, "12", player, create_sprite, {name=sprite,square=player:getSquare(), num=12})
	add_unique_option(option10menu, "13", player, create_sprite, {name=sprite,square=player:getSquare(), num=13})
	add_unique_option(option10menu, "14", player, create_sprite, {name=sprite,square=player:getSquare(), num=14})
	add_unique_option(option10menu, "15", player, create_sprite, {name=sprite,square=player:getSquare(), num=15})
	add_unique_option(option10menu, "16", player, create_sprite, {name=sprite,square=player:getSquare(), num=16})
	add_unique_option(option10menu, "17", player, create_sprite, {name=sprite,square=player:getSquare(), num=17})
	add_unique_option(option10menu, "18", player, create_sprite, {name=sprite,square=player:getSquare(), num=18})
	add_unique_option(option10menu, "19", player, create_sprite, {name=sprite,square=player:getSquare(), num=19})
	add_unique_option(option20menu, "20", player, create_sprite, {name=sprite,square=player:getSquare(), num=20})
	add_unique_option(option20menu, "21", player, create_sprite, {name=sprite,square=player:getSquare(), num=21})
	add_unique_option(option20menu, "22", player, create_sprite, {name=sprite,square=player:getSquare(), num=22})
	add_unique_option(option20menu, "23", player, create_sprite, {name=sprite,square=player:getSquare(), num=23})
	add_unique_option(option20menu, "24", player, create_sprite, {name=sprite,square=player:getSquare(), num=24})
	add_unique_option(option20menu, "25", player, create_sprite, {name=sprite,square=player:getSquare(), num=25})
	add_unique_option(option20menu, "26", player, create_sprite, {name=sprite,square=player:getSquare(), num=26})
	add_unique_option(option20menu, "27", player, create_sprite, {name=sprite,square=player:getSquare(), num=27})
	add_unique_option(option20menu, "28", player, create_sprite, {name=sprite,square=player:getSquare(), num=28})
	add_unique_option(option20menu, "29", player, create_sprite, {name=sprite,square=player:getSquare(), num=29})
	add_unique_option(option30menu, "30", player, create_sprite, {name=sprite,square=player:getSquare(), num=30})
	add_unique_option(option30menu, "31", player, create_sprite, {name=sprite,square=player:getSquare(), num=31})
	add_unique_option(option30menu, "32", player, create_sprite, {name=sprite,square=player:getSquare(), num=32})
	add_unique_option(option30menu, "33", player, create_sprite, {name=sprite,square=player:getSquare(), num=33})
	add_unique_option(option30menu, "34", player, create_sprite, {name=sprite,square=player:getSquare(), num=34})
	add_unique_option(option30menu, "35", player, create_sprite, {name=sprite,square=player:getSquare(), num=35})
	add_unique_option(option30menu, "36", player, create_sprite, {name=sprite,square=player:getSquare(), num=36})
	add_unique_option(option30menu, "37", player, create_sprite, {name=sprite,square=player:getSquare(), num=37})
	add_unique_option(option30menu, "38", player, create_sprite, {name=sprite,square=player:getSquare(), num=38})
	add_unique_option(option30menu, "39", player, create_sprite, {name=sprite,square=player:getSquare(), num=39})
	add_unique_option(option40menu, "40", player, create_sprite, {name=sprite,square=player:getSquare(), num=40})
	add_unique_option(option40menu, "41", player, create_sprite, {name=sprite,square=player:getSquare(), num=41})
	add_unique_option(option40menu, "42", player, create_sprite, {name=sprite,square=player:getSquare(), num=42})
	add_unique_option(option40menu, "43", player, create_sprite, {name=sprite,square=player:getSquare(), num=43})
	add_unique_option(option40menu, "44", player, create_sprite, {name=sprite,square=player:getSquare(), num=44})
	add_unique_option(option40menu, "45", player, create_sprite, {name=sprite,square=player:getSquare(), num=45})
	add_unique_option(option40menu, "46", player, create_sprite, {name=sprite,square=player:getSquare(), num=46})
	add_unique_option(option40menu, "47", player, create_sprite, {name=sprite,square=player:getSquare(), num=47})
	add_unique_option(option40menu, "48", player, create_sprite, {name=sprite,square=player:getSquare(), num=48})
	add_unique_option(option40menu, "49", player, create_sprite, {name=sprite,square=player:getSquare(), num=49})
	add_unique_option(option50menu, "50", player, create_sprite, {name=sprite,square=player:getSquare(), num=50})
	add_unique_option(option50menu, "51", player, create_sprite, {name=sprite,square=player:getSquare(), num=51})
	add_unique_option(option50menu, "52", player, create_sprite, {name=sprite,square=player:getSquare(), num=52})
	add_unique_option(option50menu, "53", player, create_sprite, {name=sprite,square=player:getSquare(), num=53})
	add_unique_option(option50menu, "54", player, create_sprite, {name=sprite,square=player:getSquare(), num=54})
	add_unique_option(option50menu, "55", player, create_sprite, {name=sprite,square=player:getSquare(), num=55})
	add_unique_option(option50menu, "56", player, create_sprite, {name=sprite,square=player:getSquare(), num=56})
	add_unique_option(option50menu, "57", player, create_sprite, {name=sprite,square=player:getSquare(), num=57})
	add_unique_option(option50menu, "58", player, create_sprite, {name=sprite,square=player:getSquare(), num=58})
	add_unique_option(option50menu, "59", player, create_sprite, {name=sprite,square=player:getSquare(), num=59})
	add_unique_option(option60menu, "60", player, create_sprite, {name=sprite,square=player:getSquare(), num=60})
	add_unique_option(option60menu, "61", player, create_sprite, {name=sprite,square=player:getSquare(), num=61})
	add_unique_option(option60menu, "62", player, create_sprite, {name=sprite,square=player:getSquare(), num=62})
	add_unique_option(option60menu, "63", player, create_sprite, {name=sprite,square=player:getSquare(), num=63})
	add_unique_option(option60menu, "64", player, create_sprite, {name=sprite,square=player:getSquare(), num=64})
	add_unique_option(option60menu, "65", player, create_sprite, {name=sprite,square=player:getSquare(), num=65})
	add_unique_option(option60menu, "66", player, create_sprite, {name=sprite,square=player:getSquare(), num=66})
	add_unique_option(option60menu, "67", player, create_sprite, {name=sprite,square=player:getSquare(), num=67})
	add_unique_option(option60menu, "68", player, create_sprite, {name=sprite,square=player:getSquare(), num=68})
	add_unique_option(option60menu, "69", player, create_sprite, {name=sprite,square=player:getSquare(), num=69})
	add_unique_option(option70menu, "70", player, create_sprite, {name=sprite,square=player:getSquare(), num=70})
	add_unique_option(option70menu, "71", player, create_sprite, {name=sprite,square=player:getSquare(), num=71})
	add_unique_option(option70menu, "72", player, create_sprite, {name=sprite,square=player:getSquare(), num=72})
	add_unique_option(option70menu, "73", player, create_sprite, {name=sprite,square=player:getSquare(), num=73})
	add_unique_option(option70menu, "74", player, create_sprite, {name=sprite,square=player:getSquare(), num=74})
	add_unique_option(option70menu, "75", player, create_sprite, {name=sprite,square=player:getSquare(), num=75})
	add_unique_option(option70menu, "76", player, create_sprite, {name=sprite,square=player:getSquare(), num=76})
	add_unique_option(option70menu, "77", player, create_sprite, {name=sprite,square=player:getSquare(), num=77})
	add_unique_option(option70menu, "78", player, create_sprite, {name=sprite,square=player:getSquare(), num=78})
	add_unique_option(option70menu, "79", player, create_sprite, {name=sprite,square=player:getSquare(), num=79})
	add_unique_option(option10menu, "80", player, create_sprite, {name=sprite,square=player:getSquare(), num=80})
	add_unique_option(option80menu, "81", player, create_sprite, {name=sprite,square=player:getSquare(), num=81})
	add_unique_option(option80menu, "82", player, create_sprite, {name=sprite,square=player:getSquare(), num=82})
	add_unique_option(option80menu, "83", player, create_sprite, {name=sprite,square=player:getSquare(), num=83})
	add_unique_option(option80menu, "84", player, create_sprite, {name=sprite,square=player:getSquare(), num=84})
	add_unique_option(option80menu, "85", player, create_sprite, {name=sprite,square=player:getSquare(), num=85})
	add_unique_option(option80menu, "86", player, create_sprite, {name=sprite,square=player:getSquare(), num=86})
	add_unique_option(option80menu, "87", player, create_sprite, {name=sprite,square=player:getSquare(), num=87})
	add_unique_option(option80menu, "88", player, create_sprite, {name=sprite,square=player:getSquare(), num=88})
	add_unique_option(option80menu, "89", player, create_sprite, {name=sprite,square=player:getSquare(), num=89})
	add_unique_option(option90menu, "90", player, create_sprite, {name=sprite,square=player:getSquare(), num=90})
	add_unique_option(option90menu, "91", player, create_sprite, {name=sprite,square=player:getSquare(), num=91})
	add_unique_option(option90menu, "92", player, create_sprite, {name=sprite,square=player:getSquare(), num=92})
	add_unique_option(option90menu, "93", player, create_sprite, {name=sprite,square=player:getSquare(), num=93})
	add_unique_option(option90menu, "94", player, create_sprite, {name=sprite,square=player:getSquare(), num=94})
	add_unique_option(option90menu, "95", player, create_sprite, {name=sprite,square=player:getSquare(), num=95})
	add_unique_option(option90menu, "96", player, create_sprite, {name=sprite,square=player:getSquare(), num=96})
	add_unique_option(option90menu, "97", player, create_sprite, {name=sprite,square=player:getSquare(), num=97})
	add_unique_option(option90menu, "98", player, create_sprite, {name=sprite,square=player:getSquare(), num=98})
	add_unique_option(option90menu, "99", player, create_sprite, {name=sprite,square=player:getSquare(), num=99})
	local option100     = option100xmenu:addOption("100", nil, nil)
	local option110     = option100xmenu:addOption("110", nil, nil)
	local option120     = option100xmenu:addOption("120", nil, nil)
	local option130     = option100xmenu:addOption("130", nil, nil)
	local option140     = option100xmenu:addOption("140", nil, nil)
	local option150     = option100xmenu:addOption("150", nil, nil)
	local option160     = option100xmenu:addOption("160", nil, nil)
	local option170     = option100xmenu:addOption("170", nil, nil)
	local option180     = option100xmenu:addOption("180", nil, nil)
	local option190     = option100xmenu:addOption("190", nil, nil)
	local option100menu = ISContextMenu:getNew(option100xmenu)
	local option110menu = ISContextMenu:getNew(option100xmenu)
	local option120menu = ISContextMenu:getNew(option100xmenu)
	local option130menu = ISContextMenu:getNew(option100xmenu)
	local option140menu = ISContextMenu:getNew(option100xmenu)
	local option150menu = ISContextMenu:getNew(option100xmenu)
	local option160menu = ISContextMenu:getNew(option100xmenu)
	local option170menu = ISContextMenu:getNew(option100xmenu)
	local option180menu = ISContextMenu:getNew(option100xmenu)
	local option190menu = ISContextMenu:getNew(option100xmenu)
	option100xmenu:addSubMenu(option100,option100menu)
	option100xmenu:addSubMenu(option110,option110menu)
	option100xmenu:addSubMenu(option120,option120menu)
	option100xmenu:addSubMenu(option130,option130menu)
	option100xmenu:addSubMenu(option140,option140menu)
	option100xmenu:addSubMenu(option150,option150menu)
	option100xmenu:addSubMenu(option160,option160menu)
	option100xmenu:addSubMenu(option170,option170menu)
	option100xmenu:addSubMenu(option180,option180menu)
	option100xmenu:addSubMenu(option190,option190menu)
	add_unique_option(option100menu, "100", player, create_sprite, {name=sprite,square=player:getSquare(), num=100})
	add_unique_option(option100menu, "101", player, create_sprite, {name=sprite,square=player:getSquare(), num=101})
	add_unique_option(option100menu, "102", player, create_sprite, {name=sprite,square=player:getSquare(), num=102})
	add_unique_option(option100menu, "103", player, create_sprite, {name=sprite,square=player:getSquare(), num=103})
	add_unique_option(option100menu, "104", player, create_sprite, {name=sprite,square=player:getSquare(), num=104})
	add_unique_option(option100menu, "105", player, create_sprite, {name=sprite,square=player:getSquare(), num=105})
	add_unique_option(option100menu, "106", player, create_sprite, {name=sprite,square=player:getSquare(), num=106})
	add_unique_option(option100menu, "107", player, create_sprite, {name=sprite,square=player:getSquare(), num=107})
	add_unique_option(option100menu, "108", player, create_sprite, {name=sprite,square=player:getSquare(), num=108})
	add_unique_option(option100menu, "109", player, create_sprite, {name=sprite,square=player:getSquare(), num=109})
	add_unique_option(option110menu, "110", player, create_sprite, {name=sprite,square=player:getSquare(), num=110})
	add_unique_option(option110menu, "111", player, create_sprite, {name=sprite,square=player:getSquare(), num=111})
	add_unique_option(option110menu, "112", player, create_sprite, {name=sprite,square=player:getSquare(), num=112})
	add_unique_option(option110menu, "113", player, create_sprite, {name=sprite,square=player:getSquare(), num=113})
	add_unique_option(option110menu, "114", player, create_sprite, {name=sprite,square=player:getSquare(), num=114})
	add_unique_option(option110menu, "115", player, create_sprite, {name=sprite,square=player:getSquare(), num=115})
	add_unique_option(option110menu, "116", player, create_sprite, {name=sprite,square=player:getSquare(), num=116})
	add_unique_option(option110menu, "117", player, create_sprite, {name=sprite,square=player:getSquare(), num=117})
	add_unique_option(option110menu, "118", player, create_sprite, {name=sprite,square=player:getSquare(), num=118})
	add_unique_option(option110menu, "119", player, create_sprite, {name=sprite,square=player:getSquare(), num=119})
	add_unique_option(option120menu, "120", player, create_sprite, {name=sprite,square=player:getSquare(), num=120})
	add_unique_option(option120menu, "121", player, create_sprite, {name=sprite,square=player:getSquare(), num=121})
	add_unique_option(option120menu, "122", player, create_sprite, {name=sprite,square=player:getSquare(), num=122})
	add_unique_option(option120menu, "123", player, create_sprite, {name=sprite,square=player:getSquare(), num=123})
	add_unique_option(option120menu, "124", player, create_sprite, {name=sprite,square=player:getSquare(), num=124})
	add_unique_option(option120menu, "125", player, create_sprite, {name=sprite,square=player:getSquare(), num=125})
	add_unique_option(option120menu, "126", player, create_sprite, {name=sprite,square=player:getSquare(), num=126})
	add_unique_option(option120menu, "127", player, create_sprite, {name=sprite,square=player:getSquare(), num=127})
	add_unique_option(option120menu, "128", player, create_sprite, {name=sprite,square=player:getSquare(), num=128})
	add_unique_option(option120menu, "129", player, create_sprite, {name=sprite,square=player:getSquare(), num=129})
	add_unique_option(option130menu, "130", player, create_sprite, {name=sprite,square=player:getSquare(), num=130})
	add_unique_option(option130menu, "131", player, create_sprite, {name=sprite,square=player:getSquare(), num=131})
	add_unique_option(option130menu, "132", player, create_sprite, {name=sprite,square=player:getSquare(), num=132})
	add_unique_option(option130menu, "133", player, create_sprite, {name=sprite,square=player:getSquare(), num=133})
	add_unique_option(option130menu, "134", player, create_sprite, {name=sprite,square=player:getSquare(), num=134})
	add_unique_option(option130menu, "135", player, create_sprite, {name=sprite,square=player:getSquare(), num=135})
	add_unique_option(option130menu, "136", player, create_sprite, {name=sprite,square=player:getSquare(), num=136})
	add_unique_option(option130menu, "137", player, create_sprite, {name=sprite,square=player:getSquare(), num=137})
	add_unique_option(option130menu, "138", player, create_sprite, {name=sprite,square=player:getSquare(), num=138})
	add_unique_option(option130menu, "139", player, create_sprite, {name=sprite,square=player:getSquare(), num=139})
	add_unique_option(option140menu, "140", player, create_sprite, {name=sprite,square=player:getSquare(), num=140})
	add_unique_option(option140menu, "141", player, create_sprite, {name=sprite,square=player:getSquare(), num=141})
	add_unique_option(option140menu, "142", player, create_sprite, {name=sprite,square=player:getSquare(), num=142})
	add_unique_option(option140menu, "143", player, create_sprite, {name=sprite,square=player:getSquare(), num=143})
	add_unique_option(option140menu, "144", player, create_sprite, {name=sprite,square=player:getSquare(), num=144})
	add_unique_option(option140menu, "145", player, create_sprite, {name=sprite,square=player:getSquare(), num=145})
	add_unique_option(option140menu, "146", player, create_sprite, {name=sprite,square=player:getSquare(), num=146})
	add_unique_option(option140menu, "147", player, create_sprite, {name=sprite,square=player:getSquare(), num=147})
	add_unique_option(option140menu, "148", player, create_sprite, {name=sprite,square=player:getSquare(), num=148})
	add_unique_option(option140menu, "149", player, create_sprite, {name=sprite,square=player:getSquare(), num=149})
	add_unique_option(option150menu, "150", player, create_sprite, {name=sprite,square=player:getSquare(), num=150})
	add_unique_option(option150menu, "151", player, create_sprite, {name=sprite,square=player:getSquare(), num=151})
	add_unique_option(option150menu, "152", player, create_sprite, {name=sprite,square=player:getSquare(), num=152})
	add_unique_option(option150menu, "153", player, create_sprite, {name=sprite,square=player:getSquare(), num=153})
	add_unique_option(option150menu, "154", player, create_sprite, {name=sprite,square=player:getSquare(), num=154})
	add_unique_option(option150menu, "155", player, create_sprite, {name=sprite,square=player:getSquare(), num=155})
	add_unique_option(option150menu, "156", player, create_sprite, {name=sprite,square=player:getSquare(), num=156})
	add_unique_option(option150menu, "157", player, create_sprite, {name=sprite,square=player:getSquare(), num=157})
	add_unique_option(option150menu, "158", player, create_sprite, {name=sprite,square=player:getSquare(), num=158})
	add_unique_option(option150menu, "159", player, create_sprite, {name=sprite,square=player:getSquare(), num=159})
	add_unique_option(option160menu, "160", player, create_sprite, {name=sprite,square=player:getSquare(), num=160})
	add_unique_option(option160menu, "161", player, create_sprite, {name=sprite,square=player:getSquare(), num=161})
	add_unique_option(option160menu, "162", player, create_sprite, {name=sprite,square=player:getSquare(), num=162})
	add_unique_option(option160menu, "163", player, create_sprite, {name=sprite,square=player:getSquare(), num=163})
	add_unique_option(option160menu, "164", player, create_sprite, {name=sprite,square=player:getSquare(), num=164})
	add_unique_option(option160menu, "165", player, create_sprite, {name=sprite,square=player:getSquare(), num=165})
	add_unique_option(option160menu, "166", player, create_sprite, {name=sprite,square=player:getSquare(), num=166})
	add_unique_option(option160menu, "167", player, create_sprite, {name=sprite,square=player:getSquare(), num=167})
	add_unique_option(option160menu, "168", player, create_sprite, {name=sprite,square=player:getSquare(), num=168})
	add_unique_option(option160menu, "169", player, create_sprite, {name=sprite,square=player:getSquare(), num=169})
	add_unique_option(option170menu, "170", player, create_sprite, {name=sprite,square=player:getSquare(), num=170})
	add_unique_option(option170menu, "171", player, create_sprite, {name=sprite,square=player:getSquare(), num=171})
	add_unique_option(option170menu, "172", player, create_sprite, {name=sprite,square=player:getSquare(), num=172})
	add_unique_option(option170menu, "173", player, create_sprite, {name=sprite,square=player:getSquare(), num=173})
	add_unique_option(option170menu, "174", player, create_sprite, {name=sprite,square=player:getSquare(), num=174})
	add_unique_option(option170menu, "175", player, create_sprite, {name=sprite,square=player:getSquare(), num=175})
	add_unique_option(option170menu, "176", player, create_sprite, {name=sprite,square=player:getSquare(), num=176})
	add_unique_option(option170menu, "177", player, create_sprite, {name=sprite,square=player:getSquare(), num=177})
	add_unique_option(option170menu, "178", player, create_sprite, {name=sprite,square=player:getSquare(), num=178})
	add_unique_option(option170menu, "179", player, create_sprite, {name=sprite,square=player:getSquare(), num=179})
	add_unique_option(option110menu, "180", player, create_sprite, {name=sprite,square=player:getSquare(), num=180})
	add_unique_option(option180menu, "181", player, create_sprite, {name=sprite,square=player:getSquare(), num=181})
	add_unique_option(option180menu, "182", player, create_sprite, {name=sprite,square=player:getSquare(), num=182})
	add_unique_option(option180menu, "183", player, create_sprite, {name=sprite,square=player:getSquare(), num=183})
	add_unique_option(option180menu, "184", player, create_sprite, {name=sprite,square=player:getSquare(), num=184})
	add_unique_option(option180menu, "185", player, create_sprite, {name=sprite,square=player:getSquare(), num=185})
	add_unique_option(option180menu, "186", player, create_sprite, {name=sprite,square=player:getSquare(), num=186})
	add_unique_option(option180menu, "187", player, create_sprite, {name=sprite,square=player:getSquare(), num=187})
	add_unique_option(option180menu, "188", player, create_sprite, {name=sprite,square=player:getSquare(), num=188})
	add_unique_option(option180menu, "189", player, create_sprite, {name=sprite,square=player:getSquare(), num=189})
	add_unique_option(option190menu, "190", player, create_sprite, {name=sprite,square=player:getSquare(), num=190})
	add_unique_option(option190menu, "191", player, create_sprite, {name=sprite,square=player:getSquare(), num=191})
	add_unique_option(option190menu, "192", player, create_sprite, {name=sprite,square=player:getSquare(), num=192})
	add_unique_option(option190menu, "193", player, create_sprite, {name=sprite,square=player:getSquare(), num=193})
	add_unique_option(option190menu, "194", player, create_sprite, {name=sprite,square=player:getSquare(), num=194})
	add_unique_option(option190menu, "195", player, create_sprite, {name=sprite,square=player:getSquare(), num=195})
	add_unique_option(option190menu, "196", player, create_sprite, {name=sprite,square=player:getSquare(), num=196})
	add_unique_option(option190menu, "197", player, create_sprite, {name=sprite,square=player:getSquare(), num=197})
	add_unique_option(option190menu, "198", player, create_sprite, {name=sprite,square=player:getSquare(), num=198})
	add_unique_option(option190menu, "199", player, create_sprite, {name=sprite,square=player:getSquare(), num=199})
	local option200     = option200xmenu:addOption("200", nil, nil)
	local option210     = option200xmenu:addOption("210", nil, nil)
	local option220     = option200xmenu:addOption("220", nil, nil)
	local option230     = option200xmenu:addOption("230", nil, nil)
	local option240     = option200xmenu:addOption("240", nil, nil)
	local option250     = option200xmenu:addOption("250", nil, nil)
	local option260     = option200xmenu:addOption("260", nil, nil)
	local option270     = option200xmenu:addOption("270", nil, nil)
	local option280     = option200xmenu:addOption("280", nil, nil)
	local option290     = option200xmenu:addOption("290", nil, nil)
	local option200menu = ISContextMenu:getNew(option200xmenu)
	local option210menu = ISContextMenu:getNew(option200xmenu)
	local option220menu = ISContextMenu:getNew(option200xmenu)
	local option230menu = ISContextMenu:getNew(option200xmenu)
	local option240menu = ISContextMenu:getNew(option200xmenu)
	local option250menu = ISContextMenu:getNew(option200xmenu)
	local option260menu = ISContextMenu:getNew(option200xmenu)
	local option270menu = ISContextMenu:getNew(option200xmenu)
	local option280menu = ISContextMenu:getNew(option200xmenu)
	local option290menu = ISContextMenu:getNew(option200xmenu)
	option200xmenu:addSubMenu(option200,option200menu)
	option200xmenu:addSubMenu(option210,option210menu)
	option200xmenu:addSubMenu(option220,option220menu)
	option200xmenu:addSubMenu(option230,option230menu)
	option200xmenu:addSubMenu(option240,option240menu)
	option200xmenu:addSubMenu(option250,option250menu)
	option200xmenu:addSubMenu(option260,option260menu)
	option200xmenu:addSubMenu(option270,option270menu)
	option200xmenu:addSubMenu(option280,option280menu)
	option200xmenu:addSubMenu(option290,option290menu)
	add_unique_option(option200menu, "200", player, create_sprite, {name=sprite,square=player:getSquare(), num=200})
	add_unique_option(option200menu, "201", player, create_sprite, {name=sprite,square=player:getSquare(), num=201})
	add_unique_option(option200menu, "202", player, create_sprite, {name=sprite,square=player:getSquare(), num=202})
	add_unique_option(option200menu, "203", player, create_sprite, {name=sprite,square=player:getSquare(), num=203})
	add_unique_option(option200menu, "204", player, create_sprite, {name=sprite,square=player:getSquare(), num=204})
	add_unique_option(option200menu, "205", player, create_sprite, {name=sprite,square=player:getSquare(), num=205})
	add_unique_option(option200menu, "206", player, create_sprite, {name=sprite,square=player:getSquare(), num=206})
	add_unique_option(option200menu, "207", player, create_sprite, {name=sprite,square=player:getSquare(), num=207})
	add_unique_option(option200menu, "208", player, create_sprite, {name=sprite,square=player:getSquare(), num=208})
	add_unique_option(option200menu, "209", player, create_sprite, {name=sprite,square=player:getSquare(), num=209})
	add_unique_option(option210menu, "210", player, create_sprite, {name=sprite,square=player:getSquare(), num=210})
	add_unique_option(option210menu, "211", player, create_sprite, {name=sprite,square=player:getSquare(), num=211})
	add_unique_option(option210menu, "212", player, create_sprite, {name=sprite,square=player:getSquare(), num=212})
	add_unique_option(option210menu, "213", player, create_sprite, {name=sprite,square=player:getSquare(), num=213})
	add_unique_option(option210menu, "214", player, create_sprite, {name=sprite,square=player:getSquare(), num=214})
	add_unique_option(option210menu, "215", player, create_sprite, {name=sprite,square=player:getSquare(), num=215})
	add_unique_option(option210menu, "216", player, create_sprite, {name=sprite,square=player:getSquare(), num=216})
	add_unique_option(option210menu, "217", player, create_sprite, {name=sprite,square=player:getSquare(), num=217})
	add_unique_option(option210menu, "218", player, create_sprite, {name=sprite,square=player:getSquare(), num=218})
	add_unique_option(option210menu, "219", player, create_sprite, {name=sprite,square=player:getSquare(), num=219})
	add_unique_option(option220menu, "220", player, create_sprite, {name=sprite,square=player:getSquare(), num=220})
	add_unique_option(option220menu, "221", player, create_sprite, {name=sprite,square=player:getSquare(), num=221})
	add_unique_option(option220menu, "222", player, create_sprite, {name=sprite,square=player:getSquare(), num=222})
	add_unique_option(option220menu, "223", player, create_sprite, {name=sprite,square=player:getSquare(), num=223})
	add_unique_option(option220menu, "224", player, create_sprite, {name=sprite,square=player:getSquare(), num=224})
	add_unique_option(option220menu, "225", player, create_sprite, {name=sprite,square=player:getSquare(), num=225})
	add_unique_option(option220menu, "226", player, create_sprite, {name=sprite,square=player:getSquare(), num=226})
	add_unique_option(option220menu, "227", player, create_sprite, {name=sprite,square=player:getSquare(), num=227})
	add_unique_option(option220menu, "228", player, create_sprite, {name=sprite,square=player:getSquare(), num=228})
	add_unique_option(option220menu, "229", player, create_sprite, {name=sprite,square=player:getSquare(), num=229})
	add_unique_option(option230menu, "230", player, create_sprite, {name=sprite,square=player:getSquare(), num=230})
	add_unique_option(option230menu, "231", player, create_sprite, {name=sprite,square=player:getSquare(), num=231})
	add_unique_option(option230menu, "232", player, create_sprite, {name=sprite,square=player:getSquare(), num=232})
	add_unique_option(option230menu, "233", player, create_sprite, {name=sprite,square=player:getSquare(), num=233})
	add_unique_option(option230menu, "234", player, create_sprite, {name=sprite,square=player:getSquare(), num=234})
	add_unique_option(option230menu, "235", player, create_sprite, {name=sprite,square=player:getSquare(), num=235})
	add_unique_option(option230menu, "236", player, create_sprite, {name=sprite,square=player:getSquare(), num=236})
	add_unique_option(option230menu, "237", player, create_sprite, {name=sprite,square=player:getSquare(), num=237})
	add_unique_option(option230menu, "238", player, create_sprite, {name=sprite,square=player:getSquare(), num=238})
	add_unique_option(option230menu, "239", player, create_sprite, {name=sprite,square=player:getSquare(), num=239})
	add_unique_option(option240menu, "240", player, create_sprite, {name=sprite,square=player:getSquare(), num=240})
	add_unique_option(option240menu, "241", player, create_sprite, {name=sprite,square=player:getSquare(), num=241})
	add_unique_option(option240menu, "242", player, create_sprite, {name=sprite,square=player:getSquare(), num=242})
	add_unique_option(option240menu, "243", player, create_sprite, {name=sprite,square=player:getSquare(), num=243})
	add_unique_option(option240menu, "244", player, create_sprite, {name=sprite,square=player:getSquare(), num=244})
	add_unique_option(option240menu, "245", player, create_sprite, {name=sprite,square=player:getSquare(), num=245})
	add_unique_option(option240menu, "246", player, create_sprite, {name=sprite,square=player:getSquare(), num=246})
	add_unique_option(option240menu, "247", player, create_sprite, {name=sprite,square=player:getSquare(), num=247})
	add_unique_option(option240menu, "248", player, create_sprite, {name=sprite,square=player:getSquare(), num=248})
	add_unique_option(option240menu, "249", player, create_sprite, {name=sprite,square=player:getSquare(), num=249})
	add_unique_option(option250menu, "250", player, create_sprite, {name=sprite,square=player:getSquare(), num=250})
	add_unique_option(option250menu, "251", player, create_sprite, {name=sprite,square=player:getSquare(), num=251})
	add_unique_option(option250menu, "252", player, create_sprite, {name=sprite,square=player:getSquare(), num=252})
	add_unique_option(option250menu, "253", player, create_sprite, {name=sprite,square=player:getSquare(), num=253})
	add_unique_option(option250menu, "254", player, create_sprite, {name=sprite,square=player:getSquare(), num=254})
	add_unique_option(option250menu, "255", player, create_sprite, {name=sprite,square=player:getSquare(), num=255})
	add_unique_option(option250menu, "256", player, create_sprite, {name=sprite,square=player:getSquare(), num=256})
	add_unique_option(option250menu, "257", player, create_sprite, {name=sprite,square=player:getSquare(), num=257})
	add_unique_option(option250menu, "258", player, create_sprite, {name=sprite,square=player:getSquare(), num=258})
	add_unique_option(option250menu, "259", player, create_sprite, {name=sprite,square=player:getSquare(), num=259})
	add_unique_option(option260menu, "260", player, create_sprite, {name=sprite,square=player:getSquare(), num=260})
	add_unique_option(option260menu, "261", player, create_sprite, {name=sprite,square=player:getSquare(), num=261})
	add_unique_option(option260menu, "262", player, create_sprite, {name=sprite,square=player:getSquare(), num=262})
	add_unique_option(option260menu, "263", player, create_sprite, {name=sprite,square=player:getSquare(), num=263})
	add_unique_option(option260menu, "264", player, create_sprite, {name=sprite,square=player:getSquare(), num=264})
	add_unique_option(option260menu, "265", player, create_sprite, {name=sprite,square=player:getSquare(), num=265})
	add_unique_option(option260menu, "266", player, create_sprite, {name=sprite,square=player:getSquare(), num=266})
	add_unique_option(option260menu, "267", player, create_sprite, {name=sprite,square=player:getSquare(), num=267})
	add_unique_option(option260menu, "268", player, create_sprite, {name=sprite,square=player:getSquare(), num=268})
	add_unique_option(option260menu, "269", player, create_sprite, {name=sprite,square=player:getSquare(), num=269})
	add_unique_option(option270menu, "270", player, create_sprite, {name=sprite,square=player:getSquare(), num=270})
	add_unique_option(option270menu, "271", player, create_sprite, {name=sprite,square=player:getSquare(), num=271})
	add_unique_option(option270menu, "272", player, create_sprite, {name=sprite,square=player:getSquare(), num=272})
	add_unique_option(option270menu, "273", player, create_sprite, {name=sprite,square=player:getSquare(), num=273})
	add_unique_option(option270menu, "274", player, create_sprite, {name=sprite,square=player:getSquare(), num=274})
	add_unique_option(option270menu, "275", player, create_sprite, {name=sprite,square=player:getSquare(), num=275})
	add_unique_option(option270menu, "276", player, create_sprite, {name=sprite,square=player:getSquare(), num=276})
	add_unique_option(option270menu, "277", player, create_sprite, {name=sprite,square=player:getSquare(), num=277})
	add_unique_option(option270menu, "278", player, create_sprite, {name=sprite,square=player:getSquare(), num=278})
	add_unique_option(option270menu, "279", player, create_sprite, {name=sprite,square=player:getSquare(), num=279})
	add_unique_option(option280menu, "280", player, create_sprite, {name=sprite,square=player:getSquare(), num=280})
	add_unique_option(option280menu, "281", player, create_sprite, {name=sprite,square=player:getSquare(), num=281})
	add_unique_option(option280menu, "282", player, create_sprite, {name=sprite,square=player:getSquare(), num=282})
	add_unique_option(option280menu, "283", player, create_sprite, {name=sprite,square=player:getSquare(), num=283})
	add_unique_option(option280menu, "284", player, create_sprite, {name=sprite,square=player:getSquare(), num=284})
	add_unique_option(option280menu, "285", player, create_sprite, {name=sprite,square=player:getSquare(), num=285})
	add_unique_option(option280menu, "286", player, create_sprite, {name=sprite,square=player:getSquare(), num=286})
	add_unique_option(option280menu, "287", player, create_sprite, {name=sprite,square=player:getSquare(), num=287})
	add_unique_option(option280menu, "288", player, create_sprite, {name=sprite,square=player:getSquare(), num=288})
	add_unique_option(option280menu, "289", player, create_sprite, {name=sprite,square=player:getSquare(), num=289})
	add_unique_option(option290menu, "290", player, create_sprite, {name=sprite,square=player:getSquare(), num=290})
	add_unique_option(option290menu, "291", player, create_sprite, {name=sprite,square=player:getSquare(), num=291})
	add_unique_option(option290menu, "292", player, create_sprite, {name=sprite,square=player:getSquare(), num=292})
	add_unique_option(option290menu, "293", player, create_sprite, {name=sprite,square=player:getSquare(), num=293})
	add_unique_option(option290menu, "294", player, create_sprite, {name=sprite,square=player:getSquare(), num=294})
	add_unique_option(option290menu, "295", player, create_sprite, {name=sprite,square=player:getSquare(), num=295})
	add_unique_option(option290menu, "296", player, create_sprite, {name=sprite,square=player:getSquare(), num=296})
	add_unique_option(option290menu, "297", player, create_sprite, {name=sprite,square=player:getSquare(), num=297})
	add_unique_option(option290menu, "298", player, create_sprite, {name=sprite,square=player:getSquare(), num=298})
	add_unique_option(option290menu, "299", player, create_sprite, {name=sprite,square=player:getSquare(), num=299})
end

