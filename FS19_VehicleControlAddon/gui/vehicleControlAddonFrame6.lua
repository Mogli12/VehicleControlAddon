VehicleControlAddonFrame6 = {}

local VehicleControlAddonFrame6_mt = Class(VehicleControlAddonFrame6, VehicleControlAddonFrame)

VehicleControlAddonFrame6.CONTROLS = {
    CONTAINER = "container"
}

function VehicleControlAddonFrame6:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame6.CONTROLS, nil, VehicleControlAddonFrame6_mt)
	return self
end