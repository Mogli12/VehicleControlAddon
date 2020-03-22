VehicleControlAddonFrame4 = {}

local VehicleControlAddonFrame4_mt = Class(VehicleControlAddonFrame4, VehicleControlAddonFrame)

VehicleControlAddonFrame4.CONTROLS = {
    CONTAINER = "container"
}

function VehicleControlAddonFrame4:new(menu)
	local self = VehicleControlAddonFrame:new(menu, VehicleControlAddonFrame4.CONTROLS, nil, VehicleControlAddonFrame4_mt)
	self.vcaBackup = {}
	for n,v in pairs( VCAGlobals ) do 
		self.vcaBackup[n] = v 
	end 
	return self
end

function VehicleControlAddonFrame4:vcaGetValues( force )
	if self.vcaState.vcaGetValues then 
		return 
	end 
	if not ( force or self.vcaIsDirty ) then 
		return 
	end 
	
	self.vcaState.vcaGetValues = true 
	
	local vehicle = g_currentMission.controlledVehicle
	
	if force then 
		for n,v in pairs( VCAGlobals ) do 
			self.vcaBackup[n] = v 
		end 
	end 

	for name,s in pairs( self.vcaElements ) do
		local element = s.element
		if name:sub(1,4) == "VCA_" then 
			local n = name:sub(5)
		--if force then print(n..': '..tostring(VCAGlobals[n])) end 
			if VCADefaults[n] ~= nil then 
				local v = VCAGlobals[n]
				if     n == "transmission" then 
					if force and vehicle ~= nil then 
						element:setTexts( vehicle.vcaUI.vcaTransmission )
					end 
					element:setState( v + 1 )
				elseif n == "hiredWorker" then 
					if force and vehicle ~= nil then 
						element:setTexts( vehicle.vcaUI.vcaHiredWorker )
					end 
					element:setState( v + 1 )
				elseif n == "g27Mode" then 
					if force and vehicle ~= nil then 
						element:setTexts( vehicle.vcaUI.vcaG27Mode )
					end 
					element:setState( v + 1 )
				elseif n == "brakeForceFactor" then 
					element:setState( math.floor( v * 20 + 0.5 ) + 1 )
				elseif VCADefaults[n].tp == "bool" then 
					element:setIsChecked( v )
				end 
			end 
		end 
	end 
	
	self.vcaState.vcaGetValues = false 

	self.vcaIsDirty = false 
end

function VehicleControlAddonFrame4:vcaSetValues( force )
	if self.menu == nil then 
		print("VCA Frame: no menu")
		return 
	end 
	if not ( self.menu.vcaInputEnabled ) then 
	--print("VCA Frame not yet input enabled")
		return 
	end 
	if self.vcaState.vcaSetValues then 
		return 
	end 

	self.vcaState.vcaSetValues = true 

	local isDirty = false 
	for name,s in pairs( self.vcaElements ) do
		local element = s.element
		if name:sub(1,4) == "VCA_" then 
			local n = name:sub(5)
			local v = nil
			if VCADefaults[n] ~= nil then 
				if     n == "transmission" then 
					v = element:getState() - 1
				elseif n == "hiredWorker" then 
					v = element:getState() - 1
				elseif n == "g27Mode" then 
					v = element:getState() - 1
				elseif n == "brakeForceFactor" then 
					v = 0.05 * ( element:getState() - 1 )
				elseif VCADefaults[n].tp == "bool" then 
					v = element:getIsChecked()
				end 
				if v ~= nil then 
					VCAGlobals[n] = v 
					if v ~= VCADefaults[n].v then 
						isDirty = true 
					end 
				end 
			end 
		end 
	end 
	
	local isDirty2 = false 
	if force then 
		for n,v in pairs( VCAGlobals ) do 
			if not vehicleControlAddon.mbCompare( self.vcaBackup[n], v ) then 
			--print( n..': "'..tostring( self.vcaBackup[n] )..'" ~= "'..tostring( v )..'"' )
				isDirty2 = true 
			end 
		end 
	end 
	if isDirty2 and ( isDirty or fileExists( vehicleControlAddon._globals_.fileUsr ) ) then 
		vehicleControlAddon.globalsCreateNew()
	end 
	
	self.vcaState.vcaSetValues = false 
end

function VehicleControlAddonFrame4:vcaOnEnterPressed( element )
	self:vcaOnTextChanged( element, element:getText() )
end 

function VehicleControlAddonFrame4:vcaOnTextChanged( element, text )
	if self.vcaState.vcaOnTextChanged or self.vcaState.vcaGetValues then
		return 
	end 
	
	if element == nil then
		print("Invalid element: <nil>")
		return
	end 
	
	if element.id == nil or element.typeName == nil or element.typeName ~= "textInput" then 
		print("Invalid element: '"..tostring(element.id).."'")
		return
	end 
	
	self.vcaState.vcaOnTextChanged = true  
	
	local name = element.id
	
	
	self.vcaIsDirty = true 
	self.vcaState.vcaOnTextChanged = false 
end 
