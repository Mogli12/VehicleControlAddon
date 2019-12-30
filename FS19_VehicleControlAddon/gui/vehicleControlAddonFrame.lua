VehicleControlAddonFrame = {}

local VehicleControlAddonFrame_mt = Class(VehicleControlAddonFrame, TabbedMenuFrameElement)

VehicleControlAddonFrame.CONTROLS = {
    CONTAINER = "container",
		HELP = "vcaHelp",
}

function VehicleControlAddonFrame:new(menu, controls, target, customMt)
	local self = TabbedMenuFrameElement:new(target, customMt or VehicleControlAddonFrame_mt )
	self.menu = menu 
	self.controls = controls
	self.vcaElements = {}
	self.vcaIsDirty = true 
	allControls = {}
	for name,id in pairs(VehicleControlAddonFrame.CONTROLS) do 
		allControls[name] = id 
	end 
	if type(controls) == "table" then 
		for name,id in pairs(controls) do 
			allControls[name] = id 
		end 
	end 
	self:registerControls(allControls)
	return self
end

function VehicleControlAddonFrame:copyAttributes(src)
	VehicleControlAddonFrame:superClass().copyAttributes(self, src)

	self.menu = src.menu 
	self.controls = src.controls
	self.vcaElements = src.vcaElements
end
function VehicleControlAddonFrame:update(dt)
	VehicleControlAddonFrame:superClass().update(self, dt)

	self:vcaSetValues()
	self:vcaGetValues()
end

function VehicleControlAddonFrame:onFrameOpen()
	VehicleControlAddonFrame:superClass().onFrameOpen(self)

	self:vcaGetValues( true ) 
end 


function VehicleControlAddonFrame:onFrameClose()
	VehicleControlAddonFrame:superClass().onFrameClose(self)

--print("VCA frame close @"..tostring(g_currentMission.time))

	self:vcaSetValues( true )
end	
	
function VehicleControlAddonFrame:vcaGetValues( force )
	if not ( force or self.vcaIsDirty ) then 
		return 
	end 
	
--print("VCA frame get values @"..tostring(g_currentMission.time))
	
	if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.vcaUI ~= nil then 
		local vehicle = g_currentMission.controlledVehicle
		
		for name,s in pairs( self.vcaElements ) do

			if     s.parameter == "callback" then
				local getter = vehicleControlAddon["vcaUIDraw"..name]
				local texts  = getter( vehicle )
				s.element:setTexts(texts)
			elseif s.parameter == "list" or s.parameter == "list0" then
				if type( vehicle.vcaUI[name] ) == "table" then
					s.element:setTexts(vehicle.vcaUI[name])
				else
					s.element:setTexts({"<empty>"})
				end
			end

			local element = s.element
			
			local getter = nil							
			if     type( vehicleControlAddon["vcaUIGet"..name] ) == "function" then
				getter = vehicleControlAddon["vcaUIGet"..name]
			else
				getter = function( vehicle ) return vehicleControlAddon.mbGetState( vehicle, name ) end
			end		
			
			if     getter == nil then
				print("Invalid UI element ID: "..tostring(name))
			else
				local value = getter( vehicle )
				
				if     element.typeName == "checkedOption" then
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
				elseif element.typeName == "textInput" then 
					local t = tostring( value )
					element:setText( t )
				end
			end
		end
	end 

	self.vcaIsDirty = false 
end

function VehicleControlAddonFrame:vcaSetValues( force )
	if self.menu == nil then 
		print("VCA Frame: no menu")
		return 
	end 
	if not ( self.menu.vcaInputEnabled ) then 
	--print("VCA Frame not yet input enabled")
		return 
	end 

	if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.vcaIsLoaded then 
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
				getter = function( vehicle ) return vehicleControlAddon.mbGetState( vehicle, name ) end
			end		

			local setter
			if     type( vehicleControlAddon["vcaUISet"..name] ) == "function" then
				setter = vehicleControlAddon["vcaUISet"..name]
			else
				setter = function( vehicle, value ) vehicleControlAddon.mbSetState( vehicle, name, value ) end
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
			elseif element.typeName == "textInput" then 
				local t = element:getText()
				setter( vehicle, t )
			end
		end
	end 
end

function VehicleControlAddonFrame:onCreateSubElement( element, parameter )
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
		self.vcaElements[element.id] = { element=element, parameter=parameter }
	else	
		print("Error inserting UI element with ID: "..tostring(element.id))
	end			
end

