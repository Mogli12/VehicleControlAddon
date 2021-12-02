VehicleControlAddonConfig = {}
VehicleControlAddonConfig.CONTROLS = {
    "backButton",
    "saveButton",
}

local VehicleControlAddonConfig_mt = Class(VehicleControlAddonConfig, ScreenElement)

function VehicleControlAddonConfig.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or VehicleControlAddonConfig_mt)
	self.vcaBackup = {}
	for n,v in pairs( VCAGlobals ) do 
		self.vcaBackup[n] = v 
	end 
	self.isCloseAllowed = true
	self.vcaElements = {}
	self.vcaIsDirty = true 
	self.vcaState = {}
	self:registerControls(VehicleControlAddonConfig.CONTROLS)
	self.isBackAllowed = false
	return self
end

function VehicleControlAddonConfig:copyAttributes(src)
	VehicleControlAddonConfig:superClass().copyAttributes(self, src)
	self.vcaElements = src.vcaElements
end

function VehicleControlAddonConfig:update(dt)
	VehicleControlAddonConfig:superClass().update(self, dt)
	
	self:vcaSetValues()
	self:vcaGetValues()
end

function VehicleControlAddonConfig:onCreate()
	local f = VehicleControlAddonConfig:superClass().onCreate 
	if type( f ) == "function" then 
		f(self)
	end 
end

function VehicleControlAddonConfig:onOpen()
	VehicleControlAddonConfig:superClass().onOpen(self)
	
	for n,v in pairs( VCAGlobals ) do 
		self.vcaBackup[n] = v 
	end 
	
	self.vcaInputEnabled = true  
	self:vcaGetValues( true ) 
	
	return false
end 

function VehicleControlAddonConfig:onClickBack()
	self:vcaSetValues( true )
	self.vcaInputEnabled = false  
	self:vcaSetValues( true )
	self.vcaInputEnabled = false  

	local isDirty = false 
	for n,v in pairs( self.vcaBackup ) do 
		if v ~= nil and v ~= VCAGlobals[n] then 
			isDirty = true 
			local o = VCAGlobals[n]
			VCAGlobals[n] = v
			
			for _, vehicle in pairs(g_currentMission.vehicles) do
				if type( vehicle.vcaSetNewDefault ) == "function" then 
					vehicle:vcaSetNewDefault( n, o, v, true )
				end 
			end 
		end 
	end 
	
	if isDirty then 
		if g_server ~= nil then 
			g_server:broadcastEvent( vehicleControlAddonConfigEvent.new(false) )
		else 
			g_client:getServerConnection():sendEvent( vehicleControlAddonConfigEvent.new(false) )
		end 
	end 

	self:changeScreen(nil)
end 

function VehicleControlAddonConfig:vcaGetValues( force )
	if self.vcaState.vcaGetValues then 
		return 
	end 
	if not ( force or self.vcaIsDirty ) then 
		return 
	end 
	
	if force then 
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.6
		local l = getCorrectTextSize(0.02)
		y = y + l * 1.2
		self.vcaSnapAngleHudX = x 
		self.vcaSnapAngleHudY = y 
		
		self.vcaTexts = {}
		
		if self.vcaBackup.snapAngleHudX >= 0 then 
			x = self.vcaBackup.snapAngleHudX
		end 
		if self.vcaBackup.snapAngleHudY >= 0 then 
			y = self.vcaBackup.snapAngleHudY 
		end 
		self.vcaTexts.snapAngleHudX = string.format( "%d", math.floor( x * g_screenWidth  ) )
		self.vcaTexts.snapAngleHudY = string.format( "%d", math.floor( y * g_screenHeight ) )
	end 
	
	self.vcaState.vcaGetValues = true 
	
	local vehicle = g_currentMission.controlledVehicle

	for n,s in pairs( self.vcaElements ) do
		local element = s.element
		if self.vcaBackup[n] ~= nil then 
			local v = self.vcaBackup[n]
			if     s.parameter == "camRotation" then 
				element:setState( v + 1 )
			elseif s.parameter == "percent5" then 
				element:setState( math.floor( v * 20 + 0.5 ) + 1 )
			elseif s.parameter == "percent10" then 
				element:setState( math.floor( v * 10 + 0.5 ) + 1 )
			elseif element.typeName == "checkedOption" then 
				element:setIsChecked( v )
			elseif element.typeName == "textInput" and not ( element.isCapturingInput ) then 
				element:setText( self.vcaTexts[n] )
			end 
		end 
	end 
	
	self.vcaState.vcaGetValues = false 

	self.vcaIsDirty = false 
end

function VehicleControlAddonConfig:vcaSetValues( force )

	if self.vcaState.vcaSetValues then 
		return 
	end 

	self.vcaState.vcaSetValues = true 

	local isDirty = false 
	for n,s in pairs( self.vcaElements ) do
		local element = s.element
		local v = nil
		if self.vcaBackup[n] ~= nil then 
			if     s.parameter == "camRotation" then 
				v = element:getState() - 1
			elseif s.parameter == "percent5" then 
				v = 0.05 * ( element:getState() - 1 )
			elseif s.parameter == "percent10" then 
				v = 0.1  * ( element:getState() - 1 )
			elseif element.typeName == "checkedOption" then 
				v = element:getIsChecked()
			end 
			if v ~= nil and v ~= self.vcaBackup[n] then  
				self.vcaBackup[n] = v 
				isDirty = true 
			end 
		end 
	end 
	
	self.vcaState.vcaSetValues = false 
end

function VehicleControlAddonConfig:vcaOnEnterPressed( element )
	self:vcaOnTextChanged( element, element:getText() )
end 

function VehicleControlAddonConfig:vcaOnTextChanged( element, text )
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
	
	local n = tonumber( text ) 
	
	if     name == "snapAngleHudX" then 
		if n ~= nil and n >= 0 then 
			x = n / g_screenWidth
			if math.abs( self.vcaSnapAngleHudX - x ) * g_screenWidth < 1 then 
				self.vcaBackup.snapAngleHudX = -1 
				x = self.vcaSnapAngleHudX
			else 
				self.vcaBackup.snapAngleHudX = x 
			end 
		else 
			self.vcaBackup.snapAngleHudX = -1 
			x = self.vcaSnapAngleHudX
		end 
		self.vcaTexts.snapAngleHudX = string.format( "%d", math.floor( x * g_screenWidth  ) )
	elseif name == "snapAngleHudY" then 
		if n ~= nil and n >= 0 then 
			y = n / g_screenHeight
			if math.abs( self.vcaSnapAngleHudY - y ) * g_screenHeight < 1 then 
				self.vcaBackup.snapAngleHudY = -1 
				y = self.vcaSnapAngleHudY
			else 
				self.vcaBackup.snapAngleHudY = y 
			end 
		else 
			self.vcaBackup.snapAngleHudY = -1 
			y = self.vcaSnapAngleHudY
		end 
		self.vcaTexts.snapAngleHudY = string.format( "%d", math.floor( y * g_screenHeight ) )
	end 
	
	element:setText( self.vcaTexts[name] )
	
	self.vcaIsDirty = true 
	self.vcaState.vcaOnTextChanged = false 
end 

function VehicleControlAddonConfig:onCreateSubElement( element, parameter )
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
		elseif parameter == "camRotation" then
			element:setTexts(	{ vehicleControlAddon.getText("vcaValueOff", "OFF"), 
													vehicleControlAddon.getText("vcaValueLight", "LIGHT"), 
													vehicleControlAddon.getText("vcaValueNormal", "NORMAL"), 
													vehicleControlAddon.getText("vcaValueStrong", "STRONG"), 
												} )
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
