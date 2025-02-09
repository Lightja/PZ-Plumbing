-- Author: Lightja 1/27/2025
-- This mod may be copied/edited/reuploaded by anyone for any reason with no preconditions.
-- lightjaplumbing_washingmachines

local function same_square(s1,s2)
	return math.floor(s1:getX()) == math.floor(s2:getX())
	   and math.floor(s1:getY()) == math.floor(s2:getY())
	   and math.floor(s1:getZ()) == math.floor(s2:getZ())
end

local function LoadWasher(isoObject)
	local machine_data = isoObject:getModData()
	local timer = machine_data.timer
	local machine_activated = machine_data.machine_activated
	local emitter = machine_data.emitter
	local square = isoObject:getSquare()
	local objindex = isoObject:getObjectIndex()
	local x,y,z = square:getX(), square:getY(), square:getZ()
	
	local found_match = false
	-- print(string.format("[Lightja] Loaded Washer. Timer: %s, Active: %s, Emitter: %s, Square: (%s,%s,%s) Index: %s, keyID: %s",tostring(timer),tostring(machine_activated),tostring(emitter),tostring(x),tostring(y),tostring(z),tostring(objindex),tostring(isoObject:getEntityNetID())))
	for i=1,#lightjaplumbing_washingmachines do
		local checked_machine = lightjaplumbing_washingmachines[i]
		local checked_data = checked_machine:getModData()
		local checksquare = checked_machine:getSquare()
		local cx,cy,cz = checksquare:getX(), checksquare:getY(), checksquare:getZ()
		-- if x == cx and y == cy and z == zy then
		if same_square(checksquare,square) then
			print(string.format("[Lightja] MATCH FOUND! loaded washer matches monitored washer at (%s,%s,%s) - swapping data... loaded emitter: %s, tracked emitter: %s",tostring(x),tostring(y),tostring(z),tostring(machine_data.emitter),tostring(checked_machine:getModData().emitter)))
			-- local checked_data = checked_machine:getModData()
			lightjaplumbing_washingmachines[i] = isoObject
			getWorld():setEmitterOwner(machine_data.emitter, isoObject)
			-- lightjaplumbing_washingmachines[i]:getModData().emitter = emitter
			isoObject:setModData(checked_data)
			-- print(string.format("[Lightja]              Updated emitter. New value: %s",tostring(checked_machine:getModData().emitter)))
			local tt_obj_data = isoObject:getModData()
			-- tt_obj_data.emitter = checked_machine:getModData().emitter
			local tt_timer, tt_machine_activated, tt_emitter = tt_obj_data.timer, tt_obj_data.machine_activated, tt_obj_data.emitter
			-- print(string.format("[Lightja]              Data - Timer:%s Active:%s Emitter:%s",tostring(tt_timer),tostring(tt_machine_activated),tostring(tt_emitter)))
			return
		else
			-- print(string.format("[Lightja] loaded washer at (%s,%s,%s) does not match checked square of monitored washer at (%s,%s,%s)",tostring(x),tostring(y),tostring(z),tostring(cx),tostring(cy),tostring(cz)))
		end
	end
end

local function LoadManhole(isoObject)
	if isoObject:getModData().is_hologram then
		if isoObject:getSquare() then isoObject:getSquare():transmitRemoveItemFromSquare(isoObject) end
		sledgeDestroy(isoObject)
	end
end



local PRIORITY = 6
--IsoCombinationWasherDryer
MapObjects.OnLoadWithSprite("appliances_laundry_01_0", LoadWasher, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_laundry_01_1", LoadWasher, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_laundry_01_2", LoadWasher, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_laundry_01_3", LoadWasher, PRIORITY)

--IsoClothingWasher
MapObjects.OnLoadWithSprite("appliances_laundry_01_4", LoadWasher, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_laundry_01_5", LoadWasher, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_laundry_01_6", LoadWasher, PRIORITY)
MapObjects.OnLoadWithSprite("appliances_laundry_01_7", LoadWasher, PRIORITY)

MapObjects.OnLoadWithSprite("street_decoration_01_15", LoadManhole, PRIORITY)