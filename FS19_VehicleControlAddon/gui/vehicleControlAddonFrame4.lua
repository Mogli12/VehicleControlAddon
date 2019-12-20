VehicleControlAddonFrame4 = {}

local VehicleControlAddonFrame4_mt = Class(VehicleControlAddonFrame4, VehicleControlAddonFrame)

VehicleControlAddonFrame4.CONTROLS = {
    CONTAINER = "container"
}

function VehicleControlAddonFrame4:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame4.CONTROLS, nil, VehicleControlAddonFrame4_mt)
	return self
end