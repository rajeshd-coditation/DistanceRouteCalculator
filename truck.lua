-- Truck profile for 32-foot moving trucks (movers and packers)
-- Optimized for real-world truck routing with proper restrictions

-- Vehicle properties for 32-foot moving truck
vehicle_height = 4.0   -- meters (13 feet)
vehicle_width = 2.6    -- meters (8.5 feet) 
vehicle_length = 9.8   -- meters (32 feet)
maxweight = 12.0       -- tons

-- Function to get base speed for different road types
function get_speed(way, result, highway, max_speed)
    local speed = 0
    
    if highway == "motorway" then
        speed = 80  -- Slower than cars on highways
    elseif highway == "trunk" then
        speed = 75
    elseif highway == "primary" then
        speed = 60  -- Much slower on primary roads
    elseif highway == "secondary" then
        speed = 50
    elseif highway == "tertiary" then
        speed = 40
    elseif highway == "unclassified" then
        speed = 30
    elseif highway == "residential" then
        speed = 25  -- Very slow in residential areas
    elseif highway == "service" then
        speed = 15
    elseif highway == "track" then
        speed = 10
    else
        speed = 25
    end
    
    if max_speed and max_speed > 0 then
        speed = math.min(speed, max_speed)
    end
    
    return speed
end

-- Function to process way data with truck-specific restrictions
function process_way(way, result, relations)
    local highway = way:get_value_by_key("highway")
    
    if not highway then
        return
    end
    
    -- Skip obvious non-drivable roads
    if highway == "footway" or highway == "cycleway" or highway == "path" or 
       highway == "steps" or highway == "pedestrian" or highway == "bridleway" then
        return
    end
    
    -- Skip very narrow roads (trucks need more space)
    local width = way:get_value_by_key("width")
    if width then
        local width_num = tonumber(width:match("([%d%.]+)"))
        if width_num and width_num < 3.0 then  -- Less than 3 meters wide
            return
        end
    end
    
    -- Skip roads with low height restrictions
    local maxheight = way:get_value_by_key("maxheight")
    if maxheight then
        local height_num = tonumber(maxheight:match("([%d%.]+)"))
        if height_num and height_num < 4.0 then  -- Less than 4 meters high
            return
        end
    end
    
    -- Skip roads with low weight restrictions
    local maxweight_way = way:get_value_by_key("maxweight")
    if maxweight_way then
        local weight_num = tonumber(maxweight_way:match("([%d%.]+)"))
        if weight_num and weight_num < 12.0 then  -- Less than 12 tons
            return
        end
    end
    
    -- Skip roads that explicitly prohibit trucks
    local access = way:get_value_by_key("access")
    if access == "no" or access == "private" then
        return
    end
    
    local vehicle = way:get_value_by_key("vehicle")
    if vehicle == "no" then
        return
    end
    
    local motor_vehicle = way:get_value_by_key("motor_vehicle")
    if motor_vehicle == "no" then
        return
    end
    
    -- Get base speed
    local forward_speed = get_speed(way, result, highway, nil)
    local backward_speed = forward_speed
    
    -- Apply truck speed penalty (trucks are slower)
    forward_speed = forward_speed * 0.85  -- 15% slower than cars
    backward_speed = backward_speed * 0.85
    
    -- Set speeds
    result.forward_speed = forward_speed
    result.backward_speed = backward_speed
    
    -- Handle oneway
    local oneway = way:get_value_by_key("oneway")
    if oneway == "yes" or oneway == "1" or oneway == "true" then
        result.backward_speed = -1
    elseif oneway == "-1" then
        result.forward_speed = -1
    end
end

-- Function to process node data
function process_node(node, result)
    return
end

-- Function to process turn restrictions
function process_turn(way, turn, result)
    return
end