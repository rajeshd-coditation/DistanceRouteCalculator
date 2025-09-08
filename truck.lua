-- Truck profile for movers and packers
-- Based on OSRM car profile but optimized for commercial vehicles

-- Vehicle properties for trucks/vans
vehicle_height = 4.0  -- meters (typical moving truck height)
vehicle_width = 2.5   -- meters (typical moving truck width)
vehicle_length = 8.0  -- meters (typical moving truck length)

-- Weight restrictions (trucks are heavier)
maxweight = 7.5  -- tons (typical moving truck weight)

-- Speed adjustments for commercial vehicles
local truck_speed_multiplier = 0.9

-- Function to get speed with truck adjustments
function get_speed(way, result, highway, max_speed)
    local speed = 0
    
    -- Base speed logic (simplified from car profile)
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
    else
        speed = 30  -- default
    end
    
    -- Apply truck speed multiplier
    speed = speed * truck_speed_multiplier
    
    -- Apply max speed limit if specified
    if max_speed and max_speed > 0 then
        speed = math.min(speed, max_speed)
    end
    
    return speed
end

-- Function to process way data
function process_way(way, result, relations)
    local highway = way:get_value_by_key("highway")
    
    if not highway then
        return
    end
    
    -- Get base speed
    local forward_speed = get_speed(way, result, highway, nil)
    local backward_speed = forward_speed
    
    -- Apply truck-specific adjustments
    if highway == "residential" then
        forward_speed = forward_speed * 0.8  -- Reduce speed on residential
        backward_speed = backward_speed * 0.8
    elseif highway == "primary" or highway == "trunk" or highway == "motorway" then
        forward_speed = forward_speed * 1.1  -- Slightly increase speed on major roads
        backward_speed = backward_speed * 1.1
    end
    
    -- Avoid very narrow roads
    local width = way:get_value_by_key("width")
    if width then
        local width_num = tonumber(width:match("([%d%.]+)"))
        if width_num and width_num < 3.0 then  -- Less than 3 meters wide
            forward_speed = forward_speed * 0.5
            backward_speed = backward_speed * 0.5
        end
    end
    
    -- Set the speeds
    result.forward_speed = forward_speed
    result.backward_speed = backward_speed
    
    -- Set as oneway if appropriate
    local oneway = way:get_value_by_key("oneway")
    if oneway == "yes" or oneway == "1" or oneway == "true" then
        result.backward_speed = -1
    elseif oneway == "-1" then
        result.forward_speed = -1
    end
end

-- Function to process node data
function process_node(node, result)
    -- Basic node processing for trucks
    return
end

-- Function to process turn restrictions
function process_turn(way, turn, result)
    -- Basic turn processing for trucks
    return
end

