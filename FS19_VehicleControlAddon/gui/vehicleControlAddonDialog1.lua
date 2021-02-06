VehicleControlAddonDialog1 = {}

VehicleControlAddonDialog1.CONTROLS = {
    "title",
    "presets",
}

local VehicleControlAddonDialog1_mt = Class(VehicleControlAddonDialog1, DialogElement)

function VehicleControlAddonDialog1:new(target, custom_mt)
    local self = DialogElement:new(target, custom_mt or VehicleControlAddonDialog1_mt)

    self:registerControls(VehicleControlAddonDialog1.CONTROLS)
		
		self.vcaCallback = NO_CALLBACK 

    return self
end

function VehicleControlAddonDialog1:onClickOk(...)
	print( "OK pressed")
	self.vcaCallback( self.presets:getState() )
	self:close()
	return false -- event used
end 

function VehicleControlAddonDialog1:setTitle( title )
	self.title:setText( title )
end 

function VehicleControlAddonDialog1:setCallback( func )
	self.vcaCallback = func 
	
	local texts = {}
	for i,preset in pairs( vehicleControlAddonTransmissionBase.ownTransPresets ) do 
		texts[i] = string.format( "%d: ", preset.index )..preset.name
	end 
	
	self.presets:setTexts( texts )
end 