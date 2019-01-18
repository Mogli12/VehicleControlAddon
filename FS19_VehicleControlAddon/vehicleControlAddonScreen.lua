--***************************************************************
--
-- vehicleControlAddonScreen
-- 
-- version 2.200 by mogli (biedens)
--
--***************************************************************

--***************************************************************
source(Utils.getFilename("mogliScreen.lua", g_currentModDirectory))
_G[g_currentModName..".mogliScreen"].newClass( "vehicleControlAddonScreen", "vehicleControlAddon", "vca", "vcaUI" )
--***************************************************************

function vehicleControlAddonScreen:mogliScreenOnClose()
	if self.vehicle ~= nil then 
		self.vehicle:vcaSetState( "vcaKSIsOn", self.vehicle.vcaKSToggle )
	end 
end 