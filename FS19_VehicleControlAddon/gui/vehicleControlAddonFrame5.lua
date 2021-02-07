VehicleControlAddonFrame5 = {}

local VehicleControlAddonFrame5_mt = Class(VehicleControlAddonFrame5, VehicleControlAddonFrame)

VehicleControlAddonFrame5.CONTROLS = {
    CONTAINER = "container"
}

function VehicleControlAddonFrame5:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame5.CONTROLS, nil, VehicleControlAddonFrame5_mt)
	return self
end

function VehicleControlAddonFrame5:onFrameOpen()
	VehicleControlAddonFrame5:superClass().onFrameOpen(self)

	if vehicleControlAddonTransmissionBase.ownTransPresets == nil then 
		vehicleControlAddonTransmissionBase.loadOwnTransPresets()
		self:updateMenuButtons()
	end
end

function VehicleControlAddonFrame5:vcaUpdateMenuButtons()
	if vehicleControlAddonTransmissionBase.ownTransPresets ~= nil then 
		if #vehicleControlAddonTransmissionBase.ownTransPresets > 0 then 
			table.insert(self.menuButtonInfo, { inputAction = InputAction.MENU_EXTRA_2,
																					text        = g_i18n:getText( "vcaButtonLoadPreset" ),
																					callback    = self:vcaMakeCallback( VehicleControlAddonFrame5.onClickLoad ) } )
			table.insert(self.menuButtonInfo, { inputAction = InputAction.MENU_CANCEL,
																					text        = g_i18n:getText( "vcaButtonDelPreset" ),
																					callback    = self:vcaMakeCallback( VehicleControlAddonFrame5.onClickDelete ) } )
		end 
		
		if vehicleControlAddonTransmissionBase.ownTransPresetNextID < 100 then 
			table.insert(self.menuButtonInfo, { inputAction = InputAction.MENU_EXTRA_1,
																					text        = g_i18n:getText( "vcaButtonSavePreset" ),
																					callback    = self:vcaMakeCallback( VehicleControlAddonFrame5.onClickSave ) } )
		end
	end 
end 

function VehicleControlAddonFrame5:onClickLoad( vehicle )
	local dialog = g_gui:showDialog("vehicleControlAddonDialog1")
	if dialog ~= nil then 
		dialog.target:setTitle( g_i18n:getText( "vcaButtonLoadPreset" ) )
		dialog.target:setCallback( function(...) self:onClickLoadOK( vehicle, ... ) end )
	end 
end 

function VehicleControlAddonFrame5:onClickLoadOK( vehicle, state )

	local preset = vehicleControlAddonTransmissionBase.ownTransPresets[state]
	
	if preset == nil then return end 
	
	vehicle:vcaSetState( "vcaMaxSpeed"      , preset.maxSpeed    )
	vehicle:vcaSetState( "vcaOwnGearFactor" , preset.gearFactor  )
	vehicle:vcaSetState( "vcaOwnRangeFactor", preset.rangeFactor )
	vehicle:vcaSetState( "vcaOwnRange1st1st", preset.range1st1st )
	vehicle:vcaSetState( "vcaOwnGears"      , preset.gears       )
	vehicle:vcaSetState( "vcaOwnRanges"     , preset.ranges      )
	vehicle:vcaSetState( "vcaOwnGearTime"   , preset.gearTime    )
	vehicle:vcaSetState( "vcaOwnRangeTime"  , preset.rangeTime   )
	vehicle:vcaSetState( "vcaOwnAutoGears"  , preset.autoGears   )
	vehicle:vcaSetState( "vcaOwnAutoRange"  , preset.autoRange   )
	vehicle:vcaSetState( "vcaOwnSplitG27"   , preset.splitG27    )
	vehicle:vcaSetState( "vcaOwnRevRatio"   , preset.revRatio    )
	vehicle:vcaSetState( "vcaClutchMode"    , preset.clutchMode  )
	vehicle:vcaSetState( "vcaG27Mode"       , preset.g27Mode     )
	vehicle:vcaSetState( "vcaOwnRevGears"   , preset.revGears    )
	vehicle:vcaSetState( "vcaOwnRevRange"   , preset.revRange    )

	self:vcaGetValues( true ) 
end 

function VehicleControlAddonFrame5:onClickDelete( vehicle )
	local dialog = g_gui:showDialog("vehicleControlAddonDialog1")
	if dialog ~= nil then 
		dialog.target:setTitle( g_i18n:getText( "vcaButtonDelPreset" ) )
		dialog.target:setCallback( function(...) self:onClickDeleteOk( vehicle, ... ) end )
	end 
end 

function VehicleControlAddonFrame5:onClickDeleteOk( vehicle, state )

	local preset = vehicleControlAddonTransmissionBase.ownTransPresets[state]
	
	if preset ~= nil then 
		vehicleControlAddonTransmissionBase.ownTransPresets[state] = nil 
		vehicleControlAddonTransmissionBase.deleteOwnTransPreset( state )
		if state < vehicleControlAddonTransmissionBase.ownTransPresetNextID then 
			vehicleControlAddonTransmissionBase.ownTransPresetNextID = state 
		end 
	end

	self:updateMenuButtons()
end

function VehicleControlAddonFrame5:onClickSave( vehicle )
	local dialog = g_gui:showDialog("vehicleControlAddonDialog2")
	if dialog ~= nil then 
		dialog.target:setTitle( g_i18n:getText( "vcaButtonSavePreset" ) )
		dialog.target:setText( "own "..tostring(vehicleControlAddonTransmissionBase.ownTransPresetNextID)  )
		dialog.target:setCallback( function(...) self:onClickSaveOk( vehicle, ... ) end )
	end 
end 

function VehicleControlAddonFrame5:onClickSaveOk( vehicle, text )
	vehicleControlAddonTransmissionBase.saveOwnTransPreset( nil 
  																										  , text
                                                        , vehicle.vcaMaxSpeed   
                                                        , vehicle.vcaOwnGearFactor 
                                                        , vehicle.vcaOwnRangeFactor
                                                        , vehicle.vcaOwnRange1st1st
                                                        , vehicle.vcaOwnGears      
                                                        , vehicle.vcaOwnRanges     
                                                        , vehicle.vcaOwnGearTime   
                                                        , vehicle.vcaOwnRangeTime  
                                                        , vehicle.vcaOwnAutoGears  
                                                        , vehicle.vcaOwnAutoRange  
                                                        , vehicle.vcaOwnSplitG27   
                                                        , vehicle.vcaOwnRevRatio   
                                                        , vehicle.vcaClutchMode 
                                                        , vehicle.vcaG27Mode  
                                                        , vehicle.vcaOwnRevGears  
                                                        , vehicle.vcaOwnRevRange )

	self:updateMenuButtons()
end