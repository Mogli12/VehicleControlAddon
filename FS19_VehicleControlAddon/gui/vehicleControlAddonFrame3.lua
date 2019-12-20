
VehicleControlAddonFrame3 = {}

local VehicleControlAddonFrame3_mt = Class(VehicleControlAddonFrame3, VehicleControlAddonFrame)

VehicleControlAddonFrame3.CONTROLS = {
    CONTAINER = "container"
}

function VehicleControlAddonFrame3:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame3.CONTROLS, nil, VehicleControlAddonFrame3_mt)
	return self
end