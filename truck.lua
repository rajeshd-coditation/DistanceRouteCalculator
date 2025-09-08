-- Truck profile for movers and packers
-- Simplified version based on OSRM car profile

-- Vehicle properties for trucks/vans
vehicle_height = 4.0  -- meters (typical moving truck height)
vehicle_width = 2.5   -- meters (typical moving truck width)
vehicle_length = 8.0  -- meters (typical moving truck length)

-- Weight restrictions (trucks are heavier)
maxweight = 7.5  -- tons (typical moving truck weight)

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

-- Function to process way data (simplified)
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
    
    -- Get base speed
    local forward_speed = get_speed(way, result, highway, nil)
    local backward_speed = forward_speed
    
    -- Apply truck speed reduction (10% slower than cars)
    forward_speed = forward_speed * 0.9
    backward_speed = backward_speed * 0.9
    
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