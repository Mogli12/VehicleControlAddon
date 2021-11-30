
VehicleControlAddonMenu = {}

VehicleControlAddonMenu.CONTROLS = {
    "backButton",
    "magicButton",
    "swapButton",
}

local VehicleControlAddonMenu_mt = Class(VehicleControlAddonMenu, ScreenElement)

function VehicleControlAddonMenu.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or VehicleControlAddonMenu_mt)
	self.isCloseAllowed = true
	self.vcaElements = {}
	self.vcaIsDirty = true 
	self.vcaState = {}
	self:registerControls(VehicleControlAddonMenu.CONTROLS)
	self.isBackAllowed = false
	return self
end

function VehicleControlAddonMenu:copyAttributes(src)
	VehicleControlAddonMenu:superClass().copyAttributes(self, src)
	self.vcaElements = src.vcaElements
end

function VehicleControlAddonMenu:update(dt)
	VehicleControlAddonMenu:superClass().update(self, dt)
	
	self:vcaSetValues()
	self:vcaGetValues()
	self:vcaSetVisibility()
end

function VehicleControlAddonMenu:onCreate()
	local f = VehicleControlAddonMenu:superClass().onCreate 
	if type( f ) == "function" then 
		f(self)
	end 
end

function VehicleControlAddonMenu:onOpen()
	VehicleControlAddonMenu:superClass().onOpen(self)
	
	self.vcaInputEnabled = true  
	self:vcaGetValues( true ) 
	self:vcaSetVisibility( true )
	
	return false
end 

function VehicleControlAddonMenu:onClickBack()
	print("onClickBack")
	self:vcaSetValues( true )
	self.vcaInputEnabled = false  
	self:changeScreen(nil)
end 

function VehicleControlAddonMenu:vcaMakeCallback( func )
	if type( func) ~= "function" then 
		print("Warning [VehicleControlAddonMenu.vcaMakeCallback]: invalid function")
		return NO_CALLBACK
	end 
	
	return function()
		if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.spec_vcaUI ~= nil then 
			func( self, g_currentMission.controlledVehicle )
		else 
			print("Warning [VehicleControlAddonMenu.vcaMakeCallback]: invalid vehicle")
		end 
	end 
end 
	
function VehicleControlAddonMenu:vcaGetValues( force )
	if self.vcaState.vcaGetValues then 
		return 
	end 
	if     g_currentMission.controlledVehicle == nil
			or g_currentMission.controlledVehicle.spec_vcaUI == nil
			or g_currentMission.controlledVehicle.spec_vca == nil
			or not ( g_currentMission.controlledVehicle.spec_vca.isInitialized ) then 
		return 
	end 
	local vehicle = g_currentMission.controlledVehicle

	if not ( force or self.vcaIsDirty ) then 
		for name,s in pairs( self.vcaElements ) do
			local element = s.element
			if element.typeName == "textInput" and element.blockTime > 0 and element.isCapturingInput then
				local getter = vehicleControlAddon["vcaUIGet"..name]
				if type( getter ) == "function" then
					element:setText( getter( vehicle, false ) )
				end 
			end 
		end 
		return 
	end 
	
	self.vcaState.vcaGetValues = true 
	
	for name,s in pairs( self.vcaElements ) do

		if     s.parameter == "callback" then
			local getter = vehicleControlAddon["vcaUIDraw"..name]
			local texts  = getter( vehicle )
			s.element:setTexts(texts)
		elseif s.parameter == "list" or s.parameter == "list0" then
			if type( vehicle.spec_vcaUI[name] ) == "table" then
				s.element:setTexts(vehicle.spec_vcaUI[name])
			else
				s.element:setTexts({"<empty>"})
			end
		end

		local element = s.element
		
		local getter = nil							
		if     type( vehicleControlAddon["vcaUIGet"..name] ) == "function" then
			getter = vehicleControlAddon["vcaUIGet"..name]
		else
			getter = function( vehicle ) return vehicleControlAddon.vcaGetState( vehicle, name ) end
		end		
			
		if     getter == nil then
			print("Invalid UI element ID: "..tostring(name))
		elseif element.typeName == "text" then 
			element:setText( getter( vehicle, false ) )
		elseif element.typeName == "textInput" and not ( element.isCapturingInput ) then -- and ( force or self.vcaIsDirty )
			element:setText( getter( vehicle, true ) )
		else
			local value = getter( vehicle )
			
			if     value == nli then 
				print( "Value is nil: "..tostring(name) )
			elseif element.typeName == "checkedOption" then
				local b = value
				if s.parameter == "inverted" then
					b = not b
				end
				element:setIsChecked( b )
			elseif element.typeName == "multiTextOption" then
				local i = 1
				if     s.parameter == "percent10" then
					i = math.floor( value * 10 + 0.5 ) + 1
				elseif s.parameter == "percent5" then
					i = math.floor( value * 20 + 0.5 ) + 1
				elseif s.parameter == "list0" then
					i = value + 1
				elseif s.parameter == "bool" then 
					if value then i = 2 end
				else
					i = value 
				end
				element:setState( i )
			end
		end
	end 

	self.vcaState.vcaGetValues = false 

	self.vcaIsDirty = false 
end

function VehicleControlAddonMenu:vcaSetValues( force )
	if self.vcaState.vcaSetValues then 
		return 
	end 

	self.vcaState.vcaSetValues = true 

	if      g_currentMission.controlledVehicle ~= nil
			and g_currentMission.controlledVehicle.spec_vca ~= nil
			and g_currentMission.controlledVehicle.spec_vca.isInitialized then 
		local vehicle = g_currentMission.controlledVehicle
		
		for name,s in pairs( self.vcaElements ) do
		
			local element = s.element
			
			local getter
			if     force then 
				-- no dirty flag 
				getter = nil 
			elseif type( vehicleControlAddon["vcaUIGet"..name] ) == "function" then
				getter = vehicleControlAddon["vcaUIGet"..name]
			else
				getter = function( vehicle ) return vehicleControlAddon.vcaGetState( vehicle, name ) end
			end		

			local setter
			if     type( vehicleControlAddon["vcaUISet"..name] ) == "function" then
				setter = vehicleControlAddon["vcaUISet"..name]
			else
				setter = function( vehicle, value ) vehicleControlAddon.vcaSetState( vehicle, name, value ) end
			end
			
			-- dirty flag 
			if getter ~= nil and setter ~= nil then 
				local realSetter = setter 
				setter = function( vehicle, value ) 
					local v = getter( vehicle ) 
					if v == nil or value ~= v then 
					--print("VCA is dirty: "..tostring(name).." @"..tostring(g_currentMission.time))
						self.vcaIsDirty = true 
						realSetter( vehicle, value )
					end 
				end 
			end 
			
			if     setter == nil then
				print("Invalid UI element ID: "..tostring(name))
			elseif element.typeName == "checkedOption" then
				local b = element:getIsChecked()
				if s.parameter == "inverted" then
					b = not b
				end
			--print("SET: "..tostring(name)..": '"..tostring(b).."'")
				setter( vehicle, b )
			elseif element.typeName == "multiTextOption" then
				local i = element:getState()
				local value = i
				if     s.parameter == "percent10" then
					value = (i-1) * 0.1
				elseif s.parameter == "percent5" then
					value = (i-1) * 0.05
				elseif s.parameter == "list0" then
					value = i - 1
				elseif s.parameter == "bool" then 
					value = ( i > 1 )
				end
			--print("SET: "..tostring(name)..": '"..tostring(value).."'")
				
				setter( vehicle, value )
			elseif element.typeName == "textInput" and force then 
				local t = element:getText()
				setter( vehicle, t )
			end
		end
	end 
	
	self.vcaState.vcaSetValues = false 
end

function VehicleControlAddonMenu:vcaSetVisibility( force )
	if      g_currentMission.controlledVehicle ~= nil
			and g_currentMission.controlledVehicle.spec_vca ~= nil
			and g_currentMission.controlledVehicle.spec_vca.isInitialized then 
		local vehicle = g_currentMission.controlledVehicle
		
		for name,s in pairs( self.vcaElements ) do		
			local element = s.element
			if     type( vehicleControlAddon["vcaUIShow"..name] ) == "function" then
				local getter = vehicleControlAddon["vcaUIShow"..name]
				local disabled = true  
				if getter( vehicle ) then 
					disabled = false 
				end		
				if force or element.disabled ~= disabled then 
					element:setDisabled( disabled )
				end		
			end		
		end 
	end 
end 

function VehicleControlAddonMenu:vcaOnEnterPressed( element )
	self:vcaOnTextChanged( element, element:getText() )
end 

function VehicleControlAddonMenu:vcaOnTextChanged( element, text )
	if self.vcaState.vcaOnTextChanged or self.vcaState.vcaGetValues then
		return 
	end 
	
	print( "onEnterPressed: "..tostring( element.id ).." isCapturingInput: "..tostring( element.isCapturingInput ) )
	
	if element == nil then
		print("Invalid element: <nil>")
		return
	end 
	
	if element.id == nil or element.typeName == nil or element.typeName ~= "textInput" then 
		print("Invalid element: '"..tostring(element.id).."'")
		return
	end 
	
	self.vcaState.vcaOnTextChanged = true  
	
	local vehicle = g_currentMission.controlledVehicle
	local name = element.id
	
	local setter
	if     type( vehicleControlAddon["vcaUISet"..name] ) == "function" then
		setter = vehicleControlAddon["vcaUISet"..name]
	else
		setter = function( vehicle, value ) vehicleControlAddon.vcaSetState( vehicle, name, value ) end
	end
	
	if     setter == nil then
		print("Invalid UI element ID: "..tostring(name))
	else 
		setter( vehicle, text )
	end 
	
	self.vcaIsDirty = true 
	self.vcaState.vcaOnTextChanged = false 
end 

function VehicleControlAddonMenu:onCreateSubElement( element, parameter )
	if element == nil or element.typeName == nil then 
		print("Invalid element.typeName: <nil>")
		return
	end 
	local checked = true
	if element.id == nil then
		checked = false
	end
	if     element.typeName == "multiTextOption" then
		if     parameter == nil 
				or parameter == "bool" then
			parameter = "bool"
		--if table.getn(element.texts) ~= 2 then 
		--	element:setTexts({g_i18n:getText("ui_off"), g_i18n:getText("ui_on")})
		--end 
		elseif parameter == "list"
				or parameter == "list0" then
			element:setTexts({"vehicle is <nil>"})
		elseif parameter == "percent10" then
			local texts = {}
			for i=0,10 do
				table.insert( texts, string.format("%d%%",i*10) )
			end
			element:setTexts(texts)
		elseif parameter == "percent5" then
			local texts = {}
			for i=0,20 do
				table.insert( texts, string.format("%d%%",i*5) )
			end
			element:setTexts(texts)
		elseif parameter == "callback" then
			if type( vehicleControlAddon["vcaUIDraw"..element.id] ) == "function" then
				element:setTexts({"vehicle is <nil>"})
			else
				print("Invalid MultiTextOptionElement callback: ".."vcaUIDraw"..tostring(element.id))
				checked = false
			end
		else
			print("Invalid MultiTextOptionElement parameter: "..tostring(parameter))
			checked = false
		end
	end
	if checked then
		self.vcaElements[element.id] = { element=element, parameter=Utils.getNoNil( parameter, "" ) }
	else	
		print("Error inserting UI element with ID: "..tostring(element.id))
	end			
end


function VehicleControlAddonMenu:onClickMagic( )
	if      g_currentMission.controlledVehicle ~= nil
			and g_currentMission.controlledVehicle.spec_vca ~= nil
			and g_currentMission.controlledVehicle.spec_vca.isInitialized then 
		local vehicle = g_currentMission.controlledVehicle
		local d, o, p = vehicle:vcaGetSnapDistance()
		vehicle:vcaSetState( "snapDistance", d )
		vehicle:vcaSetState( "snapOffset1", o )
		vehicle:vcaSetState( "snapOffset2", p )
		
		self.vcaElements.snapDistance.element:setText( vehicleControlAddon.vcaUIGetsnapDistance( vehicle ) )
		self.vcaElements.snapOffset1.element:setText(  vehicleControlAddon.vcaUIGetsnapOffset1(  vehicle ) ) 
		self.vcaElements.snapOffset2.element:setText(  vehicleControlAddon.vcaUIGetsnapOffset2(  vehicle ) )
	end 
end 

function VehicleControlAddonMenu:onClickSwap( )
	if      g_currentMission.controlledVehicle ~= nil
			and g_currentMission.controlledVehicle.spec_vca ~= nil
			and g_currentMission.controlledVehicle.spec_vca.isInitialized then 
		local vehicle = g_currentMission.controlledVehicle
		local o, p = vehicle.spec_vca.snapOffset2, vehicle.spec_vca.snapOffset1
		vehicle:vcaSetState( "snapOffset1", o )
		vehicle:vcaSetState( "snapOffset2", p )

		self.vcaElements.snapDistance.element:setText( vehicleControlAddon.vcaUIGetsnapDistance( vehicle ) )
		self.vcaElements.snapOffset1.element:setText(  vehicleControlAddon.vcaUIGetsnapOffset1(  vehicle ) ) 
		self.vcaElements.snapOffset2.element:setText(  vehicleControlAddon.vcaUIGetsnapOffset2(  vehicle ) )
	end 
end 



