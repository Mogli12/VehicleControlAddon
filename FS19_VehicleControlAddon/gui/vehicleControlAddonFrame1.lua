VehicleControlAddonFrame1 = {}

local VehicleControlAddonFrame1_mt = Class(VehicleControlAddonFrame1, VehicleControlAddonFrame)

VehicleControlAddonFrame1.CONTROLS = {
		VCACAMROTINSIDE = "vcaCamRotInside",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
--	 = "",
}

function VehicleControlAddonFrame1:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame1.CONTROLS, nil, VehicleControlAddonFrame1_mt)
	return self
end