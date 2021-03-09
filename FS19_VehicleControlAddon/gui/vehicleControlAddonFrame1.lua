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

function VehicleControlAddonFrame1:vcaUpdateMenuButtons()
	table.insert(self.menuButtonInfo, { inputAction = InputAction.vcaMenuAction3,
																			text        = g_i18n:getText( "vcaButtonSnapWidth" ),
																			callback    = self:vcaMakeCallback( VehicleControlAddonFrame1.onClickMagic ) } )
	table.insert(self.menuButtonInfo, { inputAction = InputAction.vcaMenuAction4,
																			text        = g_i18n:getText( "vcaButtonSnapOffset" ),
																			callback    = self:vcaMakeCallback( VehicleControlAddonFrame1.onClickSwap ) } )
end 

function VehicleControlAddonFrame1:onClickMagic( vehicle )
	local d, o, p = vehicle:vcaGetSnapDistance()
	vehicle:vcaSetState( "vcaSnapDistance", d )
	vehicle:vcaSetState( "vcaSnapOffset1", o )
	vehicle:vcaSetState( "vcaSnapOffset2", p )
	
	self.vcaElements.vcaSnapDistance.element:setText( vehicleControlAddon.vcaUIGetvcaSnapDistance( vehicle ) )
	self.vcaElements.vcaSnapOffset1.element:setText(  vehicleControlAddon.vcaUIGetvcaSnapOffset1(  vehicle ) ) 
	self.vcaElements.vcaSnapOffset2.element:setText(  vehicleControlAddon.vcaUIGetvcaSnapOffset2(  vehicle ) )
end 

function VehicleControlAddonFrame1:onClickSwap( vehicle )
	local o, p = vehicle.vcaSnapOffset2, vehicle.vcaSnapOffset1
	vehicle:vcaSetState( "vcaSnapOffset1", o )
	vehicle:vcaSetState( "vcaSnapOffset2", p )

	self.vcaElements.vcaSnapDistance.element:setText( vehicleControlAddon.vcaUIGetvcaSnapDistance( vehicle ) )
	self.vcaElements.vcaSnapOffset1.element:setText(  vehicleControlAddon.vcaUIGetvcaSnapOffset1(  vehicle ) ) 
	self.vcaElements.vcaSnapOffset2.element:setText(  vehicleControlAddon.vcaUIGetvcaSnapOffset2(  vehicle ) )
end 