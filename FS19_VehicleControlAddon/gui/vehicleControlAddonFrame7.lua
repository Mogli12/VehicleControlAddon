VehicleControlAddonFrame7 = {}

local VehicleControlAddonFrame7_mt = Class(VehicleControlAddonFrame7, VehicleControlAddonFrame)

VehicleControlAddonFrame7.CONTROLS = {
    CONTAINER = "container"
}

function VehicleControlAddonFrame7:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame7.CONTROLS, nil, VehicleControlAddonFrame7_mt)
	return self
end