VehicleControlAddonDialog2 = {}

VehicleControlAddonDialog2.CONTROLS = {
    "title",
    "input",
}

local VehicleControlAddonDialog2_mt = Class(VehicleControlAddonDialog2, DialogElement)

function VehicleControlAddonDialog2:new(target, custom_mt)
    local self = DialogElement:new(target, custom_mt or VehicleControlAddonDialog2_mt)

    self:registerControls(VehicleControlAddonDialog2.CONTROLS)
		
		self.vcaCallback = NO_CALLBACK 

    return self
end

function VehicleControlAddonDialog2:onClickOk(...)
	self.vcaCallback( self.input:getText() )
	self:close()
	return false -- event used
end 

function VehicleControlAddonDialog2:setTitle( title )
	self.title:setText( title )
end 
function VehicleControlAddonDialog2:setText( text )
	self.input:setText( text )
end 
function VehicleControlAddonDialog2:setCallback( func )
	self.vcaCallback = func 
end 