-- Truck profile for movers and packers
-- Based on OSRM car profile but optimized for commercial vehicles

-- Import the car profile as base
require("car")

-- Override vehicle properties for trucks/vans
vehicle_height = 4.0  -- meters (typical moving truck height)
vehicle_width = 2.5   -- meters (typical moving truck width)
vehicle_length = 8.0  -- meters (typical moving truck length)

-- Weight restrictions (trucks are heavier)
maxweight = 7.5  -- tons (typical moving truck weight)

-- Speed adjustments for commercial vehicles
-- Slightly slower speeds for safety and fuel efficiency
local truck_speed_multiplier = 0.9

-- Override speed function to apply truck multiplier
function get_speed(way, result, highway, max_speed)
    local speed = get_speed(way, result, highway, max_speed)
    if speed then
        return speed * truck_speed_multiplier
    end
    return speed
end

-- Prefer routes suitable for trucks
-- Avoid residential areas when possible
function process_way(way, result, relations)
    -- Call the base car profile first
    process_way(way, result, relations)
    
    -- Additional truck-specific processing
    local highway = way:get_value_by_key("highway")
    
    -- Prefer major roads for trucks
    if highway == "residential" then
        result.forward_speed = result.forward_speed * 0.8  -- Reduce speed on residential
        result.backward_speed = result.backward_speed * 0.8
    elseif highway == "primary" or highway == "trunk" or highway == "motorway" then
        result.forward_speed = result.forward_speed * 1.1  -- Slightly increase speed on major roads
        result.backward_speed = result.backward_speed * 1.1
    end
    
    -- Avoid very narrow roads
    local width = way:get_value_by_key("width")
    if width then
        local width_num = tonumber(width:match("([%d%.]+)"))
        if width_num and width_num < 3.0 then  -- Less than 3 meters wide
            result.forward_speed = result.forward_speed * 0.5
            result.backward_speed = result.backward_speed * 0.5
        end
    end
end

