VehicleControlAddonFrame2 = {}

local VehicleControlAddonFrame2_mt = Class(VehicleControlAddonFrame2, VehicleControlAddonFrame)

VehicleControlAddonFrame2.CONTROLS = {
    CONTAINER = "container",
}

function VehicleControlAddonFrame2:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame2.CONTROLS, nil, VehicleControlAddonFrame2_mt)
	return self
end