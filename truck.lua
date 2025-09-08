-- Truck profile for movers and packers
-- Essentially car.lua with minimal truck speed adjustments
-- This ensures it works reliably with all road types

-- Vehicle properties (for reference, not used in filtering)
vehicle_height = 4.0   -- meters
vehicle_width = 2.6    -- meters
vehicle_length = 9.8   -- meters
maxweight = 12.0       -- tons

-- Function to get speed (exactly like car.lua)
function get_speed(way, result, highway, max_speed)
    local speed = 0
    
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
        speed = 30
    end
    
    if max_speed and max_speed > 0 then
        speed = math.min(speed, max_speed)
    end
    
    return speed
end

-- Function to process way data (minimal changes from car.lua)
function process_way(way, result, relations)
    local highway = way:get_value_by_key("highway")
    
    if not highway then
        return
    end
    
    -- Only skip obvious non-drivable roads (same as car.lua)
    if highway == "footway" or highway == "cycleway" or highway == "path" or 
       highway == "steps" or highway == "pedestrian" or highway == "bridleway" then
        return
    end
    
    -- Get base speed (same as car.lua)
    local forward_speed = get_speed(way, result, highway, nil)
    local backward_speed = forward_speed
    
    -- Apply truck speed adjustment (only change from car.lua)
    forward_speed = forward_speed * 0.9  -- 10% slower than cars
    backward_speed = backward_speed * 0.9
    
    -- Set speeds
    result.forward_speed = forward_speed
    result.backward_speed = backward_speed
    
    -- Handle oneway (same as car.lua)
    local oneway = way:get_value_by_key("oneway")
    if oneway == "yes" or oneway == "1" or oneway == "true" then
        result.backward_speed = -1
    elseif oneway == "-1" then
        result.forward_speed = -1
    end
end

-- Function to process node data (same as car.lua)
function process_node(node, result)
    return
end

-- Function to process turn restrictions (same as car.lua)
function process_turn(way, turn, result)
    return
end