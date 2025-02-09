-- Author: Lightja 1/31/2025
-- This mod may be copied/edited/reuploaded by anyone for any reason with no preconditions.

--sprites organized by name & type for the purpose of generating piping objects for plumbing.


function direction_string(isoDirection) if not isoDirection then return "None" end; return direction_coords_string(isoDirection:dx(),isoDirection:dy()) end

local defaultsprite = "street_decoration_01_15" --manhole

local function square_xyz(square) return square:getX(),square:getY(),square:getZ() end

local pipe_sprite_types = {
	["industry_02_238"] = "vpipe",--vpipes
	["industry_02_239"] = "vpipe",
	["industry_02_247"] = "vpipe",
	["industry_02_243"] = "vpipe",
	["industry_02_236"] = "jpipe",--jpipes
	["industry_02_237"] = "jpipe",
	["industry_02_241"] = "jpipe",
	["industry_02_246"] = "jpipe",
	["industry_02_242"] = "jpipe",
	["industry_02_240"] = "jpipe",
	["industry_02_244"] = "jpipe",
	["industry_02_245"] = "jpipe",
	["industry_02_256"] = "valve",--valves
	["industry_02_257"] = "valve",
	["industry_02_258"] = "valve",
	["industry_02_259"] = "valve",
	["industry_02_224"] = "pipe",--pipes
	["industry_02_226"] = "pipe",
	["industry_02_230"] = "pipe",
	["industry_02_229"] = "pipe",
	["industry_02_260"] = "jpipesmall",--jpipesmall
	["industry_02_261"] = "jpipesmall",
	["industry_02_263"] = "jpipesmall",
	["industry_02_262"] = "jpipesmall",
	["industry_02_225"] = "cornerpipe",--cornerpipes
	["industry_02_233"] = "cornerpipe",
	["industry_02_229"] = "cornerpipe",
	["industry_02_228"] = "cornerpipe",
	["industry_02_227"] = "cornerpipe"
}

local calc_endpoint = {--[origin][direction]
	["NW"] = {["S"]="SW",["E"]="NE"},
	["SW"] = {["N"]="NW",["E"]="SE"},
	["SE"] = {["W"]="SW",["N"]="NE"},
	["NE"] = {["W"]="NW",["S"]="SE"}
}

local calc_new_square_dx_dy = {--[endpoint][direction]
	["NW"] = {["N"]={ 0,-1},["E"]={ 0, 0},["S"]={ 0, 0},["W"]={-1, 0}}, --NW to E/S is same square
	["SW"] = {["N"]={ 0, 0},["E"]={ 0, 0},["S"]={ 0, 1},["W"]={-1, 0}}, --SW to N/E is same square
	["SE"] = {["N"]={ 0, 0},["E"]={ 1, 0},["S"]={ 0, 1},["W"]={ 0, 0}}, --SE to N/W is same square
	["NE"] = {["N"]={ 0,-1},["E"]={ 1, 0},["S"]={ 0, 0},["W"]={ 0, 0}}, --NE to S/W is same square
}

local calc_new_square_origin = {--[endpoint][direction]
	["NW"] = {["N"]="SW",["E"]="NW",["S"]="NW",["W"]="NE"}, --NW to E/S is same square
	["SW"] = {["N"]="SW",["E"]="SW",["S"]="NW",["W"]="SE"}, --WW to N/E is same square
	["SE"] = {["N"]="SE",["E"]="SW",["S"]="NE",["W"]="SE"}, --SE to N/W is same square
	["NE"] = {["N"]="SE",["E"]="NW",["S"]="NE",["W"]="NE"}, --NE to S/W is same square
}

local vpipes = {
	["NW"] = "industry_02_238",
	["SW"] = "industry_02_247",
	["SE"] = "industry_02_239",
	["NE"] = "industry_02_243"
}

local vpipe_direction_options = {
	["NW"] = {["S"]=true,["E"]=true},
	["SW"] = {["N"]=true,["E"]=true},
	["SE"] = {["N"]=true,["W"]=true},
	["NE"] = {["S"]=true,["W"]=true},
}

local vpipe_origin_by_sink_direction = {
	["N"] = "SW",
	["S"] = "NW",
	["E"] = "SW",
	["W"] = "NE"
}

local vpipe_alternate_origin_by_sink_direction = {
	["N"] = "SE",
	["S"] = "NE",
	["E"] = "NW",
	["W"] = "SE"
}

local function unwalled_directions(square)
	local cell = square:getCell()
	local x,y,z = square:getX(),square:getY(), square:getZ()
	local square_w = cell:getGridSquare(x-1, y  , z)
	local square_e = cell:getGridSquare(x+1, y  , z)
	local square_n = cell:getGridSquare(x  , y-1, z)
	local square_s = cell:getGridSquare(x  , y+1, z)
	local w_open = not (square:isWallTo(square_w) or square:isWindowTo(square_w))
	local e_open = not (square:isWallTo(square_e) or square:isWindowTo(square_e))
	local n_open = not (square:isWallTo(square_n) or square:isWindowTo(square_n))
	local s_open = not (square:isWallTo(square_s) or square:isWindowTo(square_s))
	return {["W"] = w_open, ["E"] = e_open, ["N"] = n_open, ["S"] = s_open}
end


local function create_vpipe(square, corner)
	if not vpipes[corner] then print("[Lightja] ERROR: invalid vpipe corner: %s. (Valid: NW,SW,SE,NE)",tostring(corner)); return end
	print(string.format("[Lightja] creating vertical pipe at %s corner of %s ",tostring(corner),square_string(square)))
	local new_pipe = IsoObject.new(square:getCell(), square, vpipes[corner])
	new_pipe:getModData().origin = corner
	square:AddSpecialObject(new_pipe)
	return new_pipe
end

local function create_pipe_data(pipe_obj, corner, direction)
	local pipe_data     = new_pipe:getModData()	
	pipe_data.origin    = corner
	pipe_data.direction = direction
	pipe_data.endpoint  = calc_endpoint[corner][direction]
	if not pipe_data.endpoint then print(string.format("[Lightja] ERROR! Failed sanity check at create_pipe_data, no valid endpoint for corner: '%s', direction: '%s'",tostring(corner),tostring(direction))) end
end

local jpipes = {
	["NW"] = {["S"]="industry_02_236",["E"]="industry_02_237"},
	["SW"] = {["N"]="industry_02_241",["E"]="industry_02_246"},
	["SE"] = {["W"]="industry_02_242",["N"]="industry_02_240"},
	["NE"] = {["W"]="industry_02_244",["S"]="industry_02_245"}
}
local function create_jpipe(square, corner, direction)
	if not jpipes[corner][direction] then print("[Lightja] ERROR: invalid jpipe corner: %s (Valid: NW,SW,SE,NE) or direction: %s (Valid: N,E,S,W)",tostring(corner),tostring(direction)); return end
	print(string.format("[Lightja] creating jpipe at %s corner of %s in direction %s",tostring(corner),square_string(square), tostring(direction)))
	local new_pipe = IsoObject.new(sprite.square:getCell(), sprite.square, jpipes[corner][direction])
	create_pipe_data(new_pipe, corner, direction)
	square:AddSpecialObject(new_pipe)
	return new_pipe
end

local valves = {
	["NW"] = {["S"]="industry_02_256",["E"]="industry_02_257"},
	["SW"] = {["N"]="industry_02_256",["E"]="industry_02_258"},
	["SE"] = {["W"]="industry_02_258",["N"]="industry_02_259"},
	["NE"] = {["W"]="industry_02_257",["S"]="industry_02_259"}
}
local function create_valve(square, corner, direction)
	if not valves[corner][direction] then print("[Lightja] ERROR: invalid jpipe corner: %s (Valid: NW,SW,SE,NE) or direction: %s (Valid: N,E,S,W)",tostring(corner),tostring(direction)); return end
	print(string.format("[Lightja] creating valve at %s corner of %s in direction %s",tostring(corner),square_string(square), tostring(direction)))
	local new_pipe = IsoObject.new(sprite.square:getCell(), sprite.square, valves[corner][direction])
	create_pipe_data(new_pipe, corner, direction)
	square:AddSpecialObject(new_pipe)
	return new_pipe
end

local jpipessmall = {
	["NW"] = {["S"]="industry_02_260",["E"]="industry_02_261"},
	["SW"] = {["E"]="industry_02_263"},
	["NE"] = {["S"]="industry_02_262"}
}
local function create_jpipesmall(square, corner, direction)
	if not jpipessmall[corner][direction] then print("[Lightja] ERROR: invalid jpipe corner: %s (Valid: NW,SW,SE,NE) or direction: %s (Valid: N,E,S,W)",tostring(corner),tostring(direction)); return end
	print(string.format("[Lightja] creating jpipesmall at %s corner of %s in direction %s",tostring(corner),square_string(square), tostring(direction)))
	local new_pipe = IsoObject.new(sprite.square:getCell(), sprite.square, jpipessmall[corner][direction])
	create_pipe_data(new_pipe, corner, direction)
	square:AddSpecialObject(new_pipe)
	return new_pipe
end

local pipes = {
	["NW"] = {["S"]="industry_02_224",["E"]="industry_02_226"},
	["SW"] = {["N"]="industry_02_224",["E"]="industry_02_230"},
	["SE"] = {["W"]="industry_02_230",["N"]="industry_02_229"},
	["NE"] = {["W"]="industry_02_226",["S"]="industry_02_229"}
}
local function create_pipe(square, corner, direction)
	if not pipes[corner][direction] then print("[Lightja] ERROR: invalid jpipe corner: %s (Valid: NW,SW,SE,NE) or direction: %s (Valid: N,E,S,W)",tostring(corner),tostring(direction)); return end
	print(string.format("[Lightja] creating jpipesmall at %s corner of %s in direction %s",tostring(corner),square_string(square), tostring(direction)))
	local new_pipe = IsoObject.new(sprite.square:getCell(), sprite.square, pipes[corner][direction])
	create_pipe_data(new_pipe, corner, direction)
	square:AddSpecialObject(new_pipe)
	return new_pipe
end

local is_inverse_cornerpipe = {["industry_02_233"] = true}
local cornerpipes = {
	["NW"] = "industry_02_225", --inverse: industry_02_233
	["SW"] = "industry_02_227",
	["SE"] = "industry_02_228",
	["NE"] = "industry_02_229"
}
local function create_cornerpipe(square, corner)
	if not cornerpipes[corner] then print("[Lightja] ERROR: invalid vpipe corner: %s. (Valid: NW,SW,SE,NE)",tostring(corner)); return end
	print(string.format("[Lightja] creating vertical pipe at %s corner of %s ",tostring(corner),square_string(square)))
	local new_pipe = IsoObject.new(sprite.square:getCell(), sprite.square, cornerpipes[corner])
	new_pipe:getModData().origin = corner
	square:AddSpecialObject(new_pipe)
	return new_pipe
end

function find_pipes_in_square(square)
	local pipe_objects = {}
	local objects = square:getObjects()
	for i=1,objects:size() do
		local obj = objects:get(i-1)
		if obj and obj:getSprite() and pipe_sprite_types[obj:getSprite():getName()] then table.insert(pipe_objects,obj) end
	end
	return pipe_objects
end

function find_vpipe_in_square(square)
	local pipe_objects = {}
	local objects = square:getObjects()
	for i=1,objects:size() do
		local obj = objects:get(i-1)
		if obj and obj:getSprite() and pipe_sprite_types[obj:getSprite():getName()]=="vpipe" then return obj end
	end
end

function find_pipe_for_connection(square)
	local pipe_objects = find_pipes_in_square(square)
	if #pipe_objects == 1 then return pipe_objects[i] 
	elseif #pipe_objects == 0 then return nil end
	for i=1, #pipe_objects do
		if not pipe_objects[i].getModData().next_pipe then return pipe_objects[i] end
	end
	-- print(string.format("[Lightja] ERROR! Failed sanity check at find_pipe_for_connection, found more than one pipe, but all are connected."))
end

local clockwise90 = {
    ["NW"] = "NE",
    ["NE"] = "SE",
    ["SE"] = "SW",
    ["SW"] = "NW"
}
local num_vpipe_corners = {
    ["Bath"] = 4,
    ["Shower"] = 4
}

function make_plumbing_pipe(og_pipe, direction)
    assert(og_pipe and direction and og_pipe:getSprite(), string.format("[Lightja] ERROR! Failed sanity check at make_plumbing_pipe, one or more input is nil. og_pipe: %s, direction: %s (or sprite)",tostring(og_pipe),tostring(direction)))
	-- if not og_pipe or not direction or not og_pipe:getSprite() then print() end
	local og_pipe_data = og_pipe:getModData()
	local og_square = og_pipe:getSquare()
	if og_pipe_data.alt_origin then --vpipe to jpipe
		create_pipe_data(og_pipe, og_pipe_data.origin, direction)
		og_pipe_data.alt_origin = nil
		og_pipe:setSpriteFromName(jpipes[og_pipe_data.origin][direction])
		return
	end
	local og_endpoint = og_pipe_data.endpoint or og_pipe_data.origin
	local dx,dy = calc_new_square_dx_dy[og_endpoint][direction]
	local new_origin = calc_new_square_origin[og_endpoint][direction]
	local new_square = nil
	if dx == 0 and dy == 0 then new_square = og_square 
	else
		local x,y,z = square_xyz(og_square)
		new_square = og_square:getCell():getGridSquare(x + dx, y + dy, z)
		local new_pipe = create_pipe(new_square,new_origin,direction)
		og_pipe_data.next_pipe = new_pipe
	end
end

function get_vertical_plumbing(square)
    assert(square, string.format("[Lightja] ERROR! Failed sanity check at get_vertical_plumbing, square was nil."))
	-- if not square then print(string.format("[Lightja] ERROR! Failed sanity check at get_vertical_plumbing, square was nil.")); return end
	if instanceof(square, "IsoObject") then square = square:getSquare() end
	local cell = square:getCell()
	local found_outside_or_collector = false
	local num_checks = 0
	local x,y,z = square:getX(), square:getY(), square:getZ()
	local sink_to_collector_plumbing_data = {}
	local checkedsquare = square
	while (not found_outside_or_collector or cell:getMaxZ() <= 0) and num_checks <= 128 do
		local floor_data  = {}
		floor_data.square = checkedsquare
		floor_data.vpipe  = find_vpipe_in_square(checkedsquare)
		table.insert(sink_to_collector_plumbing_data, floor_data)
		z = z + 1
		checkedsquare = checkedsquare:getCell():getGridSquare(x, y, z)
		cell = checkedsquare:getCell()
		found_outside_or_collector = checkedsquare:isOutside() or lightja_find_collector_in_square(checkedsquare)
	end
	return sink_to_collector_plumbing_data
end

function generate_vpipes(sink)
    assert(sink and sink:getSprite() and sink:getSprite():getProperties(), string.format("[Lightja] ERROR! Failed assert at generate_vpipes, sink, its sprite or its properties was nil."))
	local sink_direction = direction_string(sink:getFacing())
	local origin = vpipe_origin_by_sink_direction[sink_direction]
    local num_possible_origins = num_vpipe_corners[sink:getSprite():getProperties():Val("CustomName")]
    local alt_origin = vpipe_alternate_origin_by_sink_direction[sink_direction]
    if num_possible_origins == 4 then alt_origin = clockwise90[origin] end
	local vertical_plumbing_data = get_vertical_plumbing(sink)
	for i=1, #vertical_plumbing_data do
		local square = vertical_plumbing_data[i].square
		if not vertical_plumbing_data[i].vpipe then
			local new_vpipe = create_vpipe(square, origin)
			new_vpipe:getModData().alt_origin = alt_origin
		end
	end
end

function calculate_vpipes_required(sink)
	local num_vpipes = 0
	local vertical_plumbing_data = get_vertical_plumbing(sink)
	for i=1, #vertical_plumbing_data do
		if not vertical_plumbing_data[i].vpipe then
			num_vpipes = num_vpipes + 1
		end
	end
	return num_vpipes
end

function validate_vpipes(square)
	local vertical_plumbing_data = get_vertical_plumbing(square)
	for i=1, #vertical_plumbing_data do if not vertical_plumbing_data[i].vpipe then return false end end
	return true
end

local function nudge_vpipe(sink, vpipe)
	if not vpipe then print("[Lightja] ERROR! Failed sanity check at nudge_vpipe. Tried to nudge a nil vpipe."); return end
	local vpipe_data = vpipe:getModData()
	local new_origin = vpipe_data.alt_origin
	print(string.format("[Lightja] nudging vpipe %s (%s) into %s (%s)",tostring(vpipes[vpipe_data.origin]),tostring(vpipe_data.origin),tostring(vpipes[new_origin]),tostring(vpipe_data.alt_origin)))

	vpipe_data.alt_origin = vpipe_data.origin
	vpipe_data.origin = new_origin
    if num_vpipe_corners[sink:getSprite():getProperties():Val("CustomName")] == 4 then vpipe_data.alt_origin = clockwise90[vpipe_data.origin] end
	vpipe:setSpriteFromName(vpipes[new_origin])
end

function nudge_vpipes(player, sink)
	local vertical_plumbing_data = get_vertical_plumbing(sink:getSquare())
	for i=1, #vertical_plumbing_data do
		nudge_vpipe(sink, vertical_plumbing_data[i].vpipe)
	end
end

function toggle_pipe_visibility(player, pipe)
    --doesnt work
	if not instanceof(pipe, "IsoObject") then pipe = find_vpipe_in_square(pipe) end
	local pipe_data = pipe:getModData()
	local sprite = pipe:getSprite()
	if not pipe_data.is_hidden then 
		print(string.format("[Lightja] hiding pipe (current alpha %s)",tostring(pipe:getAlpha())))
		 -- pipe:setAlpha(0,0)
		 -- pipe:setAlpha(1,0)
		 -- pipe:setAlpha(2,0)
		 -- pipe:setAlpha(3,0)
		 -- pipe:setAlphaAndTarget(player,0);  
		 -- pipe:getSprite():setTintMod(ColorInfo.new(1,1,1,-1))
		 -- sprite:setTintMod(ColorInfo.new(1,1,1,0))
        -- pipe:getProperties():Set(IsoFlagType.invisible)
        -- pipe:setOverlaySpriteColor(1,1,1,0)
		pipe:getSprite():getProperties():UnSet(IsoFlagType.transparentW)
		pipe:getSprite():getProperties():UnSet(IsoFlagType.transparentN)
        -- pipe:setAlphaForced(1)
		pipe:setAlphaAndTarget(0)
        pipe_data.is_hidden = true
	else print(string.format("[Lightja] unhiding pipe. (current alpha %s)",tostring(pipe:getAlpha())))
		-- pipe:setAlpha(1)
		-- pipe:setAlphaAndTarget(player,1);  
		 -- pipe:getSprite():setTintMod(ColorInfo.new(1,1,1,1))
		 -- pipe:setAlpha(0,1)
		 -- pipe:setAlpha(1,1)
		 -- pipe:setAlpha(2,1)
		 -- pipe:setAlpha(3,1)
		 -- sprite:setTintMod(ColorInfo.new(1,1,1,1))
		-- pipe:getProperties():UnSet(IsoFlagType.invisible)
		-- pipe:setOverlaySpriteColor(1,1,1,1)

		pipe:getSprite():getProperties():Set(IsoFlagType.transparentW)
		pipe:getSprite():getProperties():Set(IsoFlagType.transparentN)
        pipe:setAlphaAndTarget(1)
		pipe_data.is_hidden = false;  end
end

-- IsoFlagType.invisible
-- IsoFlagType.trans
-- IsoFlagType.solidtrans
-- IsoFlagType.transparentW
-- IsoFlagType.transparentN
-- IsoFlagType.forceRender
-- IsoFlagType.WallWTrans
-- IsoFlagType.WallNTransdd
