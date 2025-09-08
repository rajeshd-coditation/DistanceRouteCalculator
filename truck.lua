-- Truck profile for movers and packers
-- Optimized for 32-foot moving trucks

-- Vehicle properties for 32-foot moving truck
vehicle_height = 4.0   -- meters (13.1 feet - typical moving truck height)
vehicle_width = 2.6    -- meters (8.5 feet - typical moving truck width)
vehicle_length = 9.8   -- meters (32 feet - standard moving truck length)

-- Weight restrictions for moving trucks
maxweight = 12.0  -- tons (typical 32-foot moving truck weight)

-- Function to get speed (simplified from car profile)
function get_speed(way, result, highway, max_speed)
    local speed = 0
    
    -- Base speed logic
    if highway == "motorway" then
        speed = 90
    elseif highway == "trunk" then
        speed = 85
    elseif highway == "primary" then
        speed = 70
    elseif highway == "secondary" then
        speed = 60
    elseif highway == "tertiary" then
        speed = 50
    elseif highway == "unclassified" then
        speed = 40
    elseif highway == "residential" then
        speed = 30
    elseif highway == "service" then
        speed = 20
    elseif highway == "track" then
        speed = 15
    else
        speed = 30  -- default
    end
    
    -- Apply max speed limit if specified
    if max_speed and max_speed > 0 then
        speed = math.min(speed, max_speed)
    end
    
    return speed
end

-- Function to process way data for 32-foot moving trucks
function process_way(way, result, relations)
    local highway = way:get_value_by_key("highway")
    
    if not highway then
        return
    end
    
    -- Skip non-drivable roads
    if highway == "footway" or highway == "cycleway" or highway == "path" or 
       highway == "steps" or highway == "pedestrian" or highway == "bridleway" then
        return
    end
    
    -- Skip roads that are too narrow for 32-foot trucks
    local width = way:get_value_by_key("width")
    if width then
        local width_num = tonumber(width:match("([%d%.]+)"))
        if width_num and width_num < 3.0 then  -- Less than 3 meters (10 feet) wide
            return  -- Skip this road entirely
        end
    end
    
    -- Check for height restrictions
    local maxheight = way:get_value_by_key("maxheight")
    if maxheight then
        local height_num = tonumber(maxheight:match("([%d%.]+)"))
        if height_num and height_num < 4.0 then  -- Less than 4 meters (13 feet) high
            return  -- Skip this road entirely
        end
    end
    
    -- Check for weight restrictions
    local maxweight_way = way:get_value_by_key("maxweight")
    if maxweight_way then
        local weight_num = tonumber(maxweight_way:match("([%d%.]+)"))
        if weight_num and weight_num < 12.0 then  -- Less than 12 tons
            return  -- Skip this road entirely
        end
    end
    
    -- Check for truck restrictions
    local access = way:get_value_by_key("access")
    if access == "no" or access == "private" then
        return  -- Skip restricted roads
    end
    
    local vehicle = way:get_value_by_key("vehicle")
    if vehicle == "no" then
        return  -- Skip roads where vehicles are not allowed
    end
    
    -- Get base speed
    local forward_speed = get_speed(way, result, highway, nil)
    local backward_speed = forward_speed
    
    -- Apply truck speed adjustments for 32-foot moving trucks
    if highway == "residential" then
        forward_speed = forward_speed * 0.8  -- 20% slower on residential (safety)
        backward_speed = backward_speed * 0.8
    elseif highway == "motorway" or highway == "trunk" or highway == "primary" then
        forward_speed = forward_speed * 0.95  -- 5% slower on major roads (fuel efficiency)
        backward_speed = backward_speed * 0.95
    else
        forward_speed = forward_speed * 0.9  -- 10% slower on other roads
        backward_speed = backward_speed * 0.9
    end
    
    -- Set the speeds
    result.forward_speed = forward_speed
    result.backward_speed = backward_speed
    
    -- Handle oneway roads
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