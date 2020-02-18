VehicleControlAddonFrame5 = {}

local VehicleControlAddonFrame5_mt = Class(VehicleControlAddonFrame5, VehicleControlAddonFrame)

VehicleControlAddonFrame5.CONTROLS = {
    CONTAINER = "container"
}

function VehicleControlAddonFrame5:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame5.CONTROLS, nil, VehicleControlAddonFrame5_mt)
	return self
end