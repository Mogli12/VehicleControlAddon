--
-- vehicleControlAddon
-- This is the specialization for vehicleControlAddon
--

vehicleControlAddon = {}

function vehicleControlAddon.formatNumber( n, d, f ) -- number, decimals, (optional) factor 
	if n == nil then 
		return "nil" 
	elseif type( n ) ~= "number" then 
		return "nan"
	end 
	
	if type( d ) ~= "number" then 
		d = 5 
	end 	
	if type( f ) == "number" then 
		n = n * f 
	end 

	local z = 1 
	local q = 1
	local s = 0
	local m = math.floor( n + 0.5 )
	local zd = 10^d
	local qd = 0.4999 * 0.1^d
	
	for i=1,d do 
		if math.abs( n - m ) < qd then 
			break 
		end 
		z = z * 10 
		q = q * 0.1 
		if math.abs( n * z ) > zd then 
			break
		end 
		m = q * math.floor( z * n + 0.5 )
		s = s + 1
	end 

	return string.format( string.format( "%%%d.%df", s + 3, s ), m )
end 

function vehicleControlAddon.listToString( list )
	local result = nil 
	for _,value in pairs( list ) do 
		if result == nil then 
			result = tostring( value )
		else 
			result = result ..', '..tostring( value ) 
		end 
	end 
	
	if result == nil then 
		return "" 
	end 
	return result 
end 

function vehicleControlAddon.trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function vehicleControlAddon.stringToList( text, fct )
	local list = {}
	if fct == nil then 
		fct = vehicleControlAddon.trim
	end 
	if text ~= nil then
		local start = 1;
		local splitStart, splitEnd = string.find(text, ",", start, true);
		while splitStart ~= nil do
			table.insert( list, fct( string.sub(text, start, splitStart-1 )))
			start = splitEnd + 1;
			splitStart, splitEnd = string.find(text, ",", start, true);
		end
		table.insert(list, fct( string.sub(text, start )))
	end
	
	return list;
end 		

--********************************
-- getUiScale
--********************************
function vehicleControlAddon.getUiScale()
	local uiScale = 1.0
	if g_gameSettings ~= nil and type( g_gameSettings.uiScale ) == "number" then
		uiScale = g_gameSettings.uiScale
	end
	return uiScale 
end
	
--********************************
-- getText
--********************************
function vehicleControlAddon.getText(id, default)
	if id == nil then
		return "nil";
	end;
	
	if g_i18n:hasText( id ) then
		return g_i18n:getText( id )
	end
	
	if default ~= nil then	
		return default 
	end
	
	return id
end;

--********************************
-- normalizeAngle
--********************************
function vehicleControlAddon.normalizeAngle( angle )
	local normalizedAngle = angle
	while normalizedAngle > math.pi do
		normalizedAngle = normalizedAngle - math.pi - math.pi
	end 
	while normalizedAngle <= -math.pi do
		normalizedAngle = normalizedAngle + math.pi + math.pi
	end
	return normalizedAngle
end

--********************************
-- normalizeAngleCam
--********************************
function vehicleControlAddon.normalizeAngleCam( angle )
	local normalizedAngle = angle
	while normalizedAngle > math.pi + math.pi do
		normalizedAngle = normalizedAngle - math.pi - math.pi
	end 
	while normalizedAngle <= 0 do
		normalizedAngle = normalizedAngle + math.pi + math.pi
	end
	return normalizedAngle
end

--********************************
-- mbClamp
--********************************
function vehicleControlAddon.mbClamp( v, minV, maxV )
	if v == nil then 
		return 
	end 
	if minV ~= nil and v <= minV then 
		return minV 
	end
	if maxV ~= nil and v >= maxV then 
		return maxV 
	end 
	return v 
end


vehicleControlAddon.snapAngles = { 1, 5, 15, 22.5, 45, 90 }
vehicleControlAddon.splitGearRatios = { 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95 }
vehicleControlAddon.factor30pi = 30/math.pi  -- RPM = rotSpeed * vehicleControlAddon.factor30pi
vehicleControlAddon.factorpi30 = math.pi/30  -- rotSpeed = RPM * vehicleControlAddon.factorpi30
vehicleControlAddon.speedRatioOpen       = 1000
vehicleControlAddon.speedRatioClosed0    = -1   -- maxSpeedRatio of diff of diffs
vehicleControlAddon.speedRatioClosed1    = 1.1  -- maxSpeedRatio of diff of wheels
vehicleControlAddon.speedRatioClosed2    = 1.2  -- at least 20% difference 
vehicleControlAddon.distributeTorqueOpen = false  
vehicleControlAddon.minTorqueRatio       = 0.3
vehicleControlAddon.snapRadius           = 10

vehicleControlAddon.colorActive          = { 0.0003, 0.5647, 0.9822, 1 }
vehicleControlAddon.colorInactive        = { 1, 1, 1, 1 }
vehicleControlAddon.colorNormal          = { 1, 1, 1, 1 }
vehicleControlAddon.colorWarning         = { 1, 1, 0, 1 }
vehicleControlAddon.colorError           = { 1, 0, 0, 1 }
vehicleControlAddon.colorBg              = { 0, 0, 0, 0.54 }

vehicleControlAddon.properties = {}
vehicleControlAddon.propertiesIndex = {}

vehicleControlAddon.steeringFalse = "false"
vehicleControlAddon.steeringTrue  = "true"
vehicleControlAddon.steeringSoft  = "soft"

vehicleControlAddon.shiftTimeDefault    = 0
vehicleControlAddon.shiftTimePowershift = 1
vehicleControlAddon.shiftTimeShort      = 2
vehicleControlAddon.shiftTimeMedium     = 3
vehicleControlAddon.shiftTimeLong       = 4

vehicleControlAddon.shiftTimes = { 0, 250, 500, 1000 } -- index like vehicleControlAddon.shiftTime...

function vehicleControlAddon.prerequisitesPresent(specializations)
	return true
end

function vehicleControlAddon.createState( name, global, default, propFunc, callback, savegame )
--print(tostring(name)..": "..tostring(global)..", "..tostring(default)..", "..type(propFunc)..", "..type(callback)..", "..tostring(savegame))

	if savegame == nil then savegame = true end 
	if default  == nil then
		if global ~= nil and VCAGlobals[global] ~= nil then 
			default = VCAGlobals[global]
		else 
			default = propFunc.emptyValue
		end 
	end 
	
	table.insert( vehicleControlAddon.propertiesIndex, name )
	vehicleControlAddon.properties[name] = { id       = table.getn(vehicleControlAddon.propertiesIndex),
																					 global   = global,
																					 default  = default,
																					 func     = propFunc,
																					 callback = callback,
																					 savegame = savegame }
end 

function vehicleControlAddon.createStates()
	vehicleControlAddon.createState( "steeringIsOn" , "adaptiveSteering"  , nil  , VCAValueType.string)
	vehicleControlAddon.createState( "peekLeftRight", "peekLeftRight"     , nil  , VCAValueType.bool  )
	vehicleControlAddon.createState( "isForward"    , nil                 , true , VCAValueType.bool, nil, false  )
	vehicleControlAddon.createState( "camRotInside" , "camInsideRotation" , nil  , VCAValueType.int16 )
	vehicleControlAddon.createState( "camRotOutside", "camOutsideRotation",nil  , VCAValueType.int16 )
	vehicleControlAddon.createState( "camRevInside" , nil, vehicleControlAddon.vcaGetDefRevI, VCAValueType.bool  )
	vehicleControlAddon.createState( "camRevOutside", "camRevOutRotation", nil  , VCAValueType.bool  )
	vehicleControlAddon.createState( "warningText"  , nil                , ""   , VCAValueType.string, vehicleControlAddon.vcaOnSetWarningText, false )
	vehicleControlAddon.createState( "limitThrottle", "limitThrottle"    , nil  , VCAValueType.int16 )
	vehicleControlAddon.createState( "snapAngle"    , "snapAngle"        , nil  , VCAValueType.int16 , vehicleControlAddon.vcaOnSetSnapAngle )
	vehicleControlAddon.createState( "snapDistance" , nil                , 0    , VCAValueType.float )
	vehicleControlAddon.createState( "snapOffset"   , nil                , 0    , VCAValueType.float )
	vehicleControlAddon.createState( "snapInvert"   , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "snapEvery90"  , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "snapLeft"     , nil                , 1    , VCAValueType.int16 )
	vehicleControlAddon.createState( "snapRight"    , nil                , 1    , VCAValueType.int16 )
	vehicleControlAddon.createState( "snapIsOn"     , nil                , false, VCAValueType.bool  , vehicleControlAddon.vcaOnSetSnapIsOn, false )
	vehicleControlAddon.createState( "snapDirection", nil                , 0    , VCAValueType.int16 , nil, false )
	vehicleControlAddon.createState( "pathRecording", nil                , false, VCAValueType.bool  , nil, false )
	vehicleControlAddon.createState( "snapPathID"   , nil                , 0    , VCAValueType.int16 )
	vehicleControlAddon.createState( "drawHud"      , "drawHud"          , nil  , VCAValueType.bool  )
	vehicleControlAddon.createState( "inchingIsOn"  , nil                , false, VCAValueType.bool  , nil, false )
	vehicleControlAddon.createState( "noAutoRotBack", nil                , false, VCAValueType.bool  , nil, false )
	vehicleControlAddon.createState( "noARBToggle"  , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "brakeForce"   , "brakeForceFactor" , nil  , VCAValueType.float )
	vehicleControlAddon.createState( "autoShift"    , nil                , false, VCAValueType.bool  ) --, vehicleControlAddon.vcaOnSetAutoShift )
	vehicleControlAddon.createState( "handbrake"    , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "speedLimiter" , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "ksIsOn"       , nil                , false, VCAValueType.bool  , nil, false ) --, vehicleControlAddon.vcaOnSetKSIsOn )
	vehicleControlAddon.createState( "ksIsActive"   , nil                , false, VCAValueType.bool  , nil, false ) --, vehicleControlAddon.vcaOnSetKSIsOn )
	vehicleControlAddon.createState( "keepSpeed"    , nil                , 0    , VCAValueType.float , nil, false )
	vehicleControlAddon.createState( "ksToggle"     , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "ccSpeed2"     , nil                , 10   , VCAValueType.float )
	vehicleControlAddon.createState( "ccSpeed3"     , nil                , 15   , VCAValueType.float )
	vehicleControlAddon.createState( "lastSnapAngle", nil                , 10   , VCAValueType.float ) --, vehicleControlAddon.vcaOnSetLastSnapAngle ) -- value should be between -pi and pi !!!
	vehicleControlAddon.createState( "lastSnapPosX" , nil                , 0    , VCAValueType.float )
	vehicleControlAddon.createState( "lastSnapPosZ" , nil                , 0    , VCAValueType.float )
	vehicleControlAddon.createState( "isEnteredMP"  , nil                , false, VCAValueType.bool  , nil, false )
	vehicleControlAddon.createState( "isBlocked"    , nil                , false, VCAValueType.bool  , nil, false )
	vehicleControlAddon.createState( "snapDraw"     , nil                , 1    , VCAValueType.int16 )
	vehicleControlAddon.createState( "workAreaDraw" , nil                , 0    , VCAValueType.int16 )
	vehicleControlAddon.createState( "snapFactor"   , nil                , 0    , VCAValueType.float , nil, false )
	vehicleControlAddon.createState( "hiredWorker2" , "hiredWorker2"     , nil  , VCAValueType.bool  )
	vehicleControlAddon.createState( "rotSpeedOut"  , "rotSpeedOut"      , nil  , VCAValueType.float )
	vehicleControlAddon.createState( "rotSpeedIn"   , "rotSpeedIn"       , nil  , VCAValueType.float )
	vehicleControlAddon.createState( "antiSlip"     , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "diffLockFront", nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "diffLockAWD"  , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "diffLockBack" , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "diffManual"   , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "diffLockSwap" , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "diffFrontAdv" , nil                , false, VCAValueType.bool  )
	vehicleControlAddon.createState( "idleThrottle" , "idleThrottle"     , nil  , VCAValueType.bool  )
	vehicleControlAddon.createState( "hasGearsAuto" , nil                , false, VCAValueType.bool  , nil, false )
	vehicleControlAddon.createState( "hasGearsIdle" , nil                , false, VCAValueType.bool  , nil, false )
	vehicleControlAddon.createState( "handThrottle" , nil                , 0    , VCAValueType.float , nil, false )
	vehicleControlAddon.createState( "minGearSpeed" , nil                , 0    , VCAValueType.float , nil, false )
	vehicleControlAddon.createState( "maxGearSpeed" , nil                , 0    , VCAValueType.float , nil, false )
																																			 
	vehicleControlAddon.createState( "splitGears"   , nil                , 0    , VCAValueType.int16 , vehicleControlAddon.vcaOnSetSplitGears )
	vehicleControlAddon.createState( "splitGearRatio",nil                , 7    , VCAValueType.int16 , vehicleControlAddon.vcaOnSetSplitGearRatio )
	vehicleControlAddon.createState( "gearSplitGear", nil                , 1    , VCAValueType.int16 , vehicleControlAddon.vcaOnSetGearSplitGear, false )
																																			 
	vehicleControlAddon.createState( "gearShiftTime", nil                , vehicleControlAddon.shiftTimeDefault, VCAValueType.int16 )
	vehicleControlAddon.createState( "grpShiftTime" , nil                , vehicleControlAddon.shiftTimeDefault, VCAValueType.int16 )

end 



function vehicleControlAddon.initSpecialization()
	vehicleControlAddon.initSpecializationDone = true 

	local schemaSavegame = Vehicle.xmlSchemaSavegame
	if schemaSavegame then 
		for name, prop in pairs( vehicleControlAddon.properties ) do 
			if prop.savegame then 
				schemaSavegame:register( prop.func.valueType, "vehicles.vehicle(?)." .. g_vehicleControlAddon.vcaSpecName .. "#".. name, "VehicleControlAddon: ".. name)
			end 
		end 
	end 
end 

function vehicleControlAddon.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad",                 vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad",             vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onPreUpdate",            vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate",               vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick",           vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate",           vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw",                 vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle",         vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle",         vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream",           vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream",          vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream",     vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream",    vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile",          vehicleControlAddon)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", vehicleControlAddon)
end 

function vehicleControlAddon.registerOverwrittenFunctions(vehicleType)
end

function vehicleControlAddon:mpDebugPrint( ... )
	if VCAGlobals.debugPrint or self == nil or not ( self.isClient ) then 
		print( ... )
	end 
end

local function debugFormat( ... )
	if VCAGlobals.debugPrint then 
		return string.format( ... )
	end 
	return ""
end 

function vehicleControlAddon:vcaIsValidCam( index )
	local i = Utils.getNoNil( index, self.spec_enterable.camIndex )
	
	if      self.spec_enterable            ~= nil 
			and self.spec_enterable.cameras    ~= nil 
			and i ~= nil 
			and self.spec_enterable.cameras[i] ~= nil 
			and self.spec_enterable.cameras[i].vehicle == self
			and self.spec_enterable.cameras[i].isRotatable then
		return true
	end
	
	return false
end

function vehicleControlAddon:vcaIsNonDefaultProp( name )
	if self.spec_vca == nil or self.spec_vca[name] == nil then 
		return false 
	end
	local d = self:vcaGetDefault( name )
	if     d == nil then 
		return false 
	elseif type( self.spec_vca[name] ) == "number" and type( d ) == "number" then 
		if math.abs( self.spec_vca[name] - d ) < 1e-4 then 
			return false 
		end 
		return true 
	elseif self.spec_vca[name] == d then 
		return false 
	end 
	return true  
end 

function vehicleControlAddon:vcaSetState( name, value, noEventSend )
	if self.spec_vca == nil then 
		return
	end 
	if value == nil then 
		return 
	end 
	local c, f
	local prop = vehicleControlAddon.properties[name]
	if prop == nil then 
		c = function( a, b ) return a==b end 
	else 
		c = prop.func.compare
		f = prop.callback
	end 
	if self.spec_vca[name] ~= nil and c( self.spec_vca[name], value ) then 
		return 
	end 
	local o = self.spec_vca[name]
	 
	if type( f ) == "function" then 
		f( self, o, value, noEventSend )
	else 
		self.spec_vca[name] = value
	end 
	
	if     noEventSend then 
	elseif not ( self.spec_vca.isInitialized )
			or vehicleControlAddon.properties[name] == nil
			or value == nil then 
	-- nothing 
		print("VCA MP error, name: "..tostring(name)..", value: "..tostring(value))
	elseif g_server ~= nil then
		g_server:broadcastEvent(vehicleControlAddonEvent.new(self,name,self.spec_vca[name]), nil, nil, self)
	else
		g_client:getServerConnection():sendEvent(vehicleControlAddonEvent.new(self,name,self.spec_vca[name]))
	end
end 

function vehicleControlAddon:vcaSetNewDefault( global, old, new, noEventSend )
	if self.spec_vca ~= nil and self.spec_vca.isInitialized then 
		for vn, vp in pairs( vehicleControlAddon.properties ) do
			if vp.global ~= nil and vp.global == global and self.spec_vca[vn] == old then 
				vcaDebugPrint( "Info: VCA new default value: name: "..tostring(global)..", old: "..tostring(old)..", new: "..tostring(new))
				self:vcaSetState( vn, new, noEventSend )		
			end 
		end 
	end 
end 

function vehicleControlAddon:vcaGetDefault( name )
	local prop = vehicleControlAddon.properties[name]
	if prop == nil or ( prop.default == nil and prop.global == nil ) then 
		return 
	end 
	if     prop.global ~= nil then 
		return VCAGlobals[prop.global]
	elseif type( prop.default ) == "function" then 
		return prop.default( self )
	end 
	return prop.default 
end 

function vehicleControlAddon:vcaGetState( name, default )
	if self.spec_vca == nil then 
		return
	end 
	if default and self.spec_vca[name] == nil then 
		return self:vcaGetDefault( name )
	end 
	return self.spec_vca[name]
end
	
function vehicleControlAddon:onLoad(savegame)
	
	self.spec_vca               = {}
	
	self.vcaNewState            = vehicleControlAddon.vcaNewState	
	self.vcaSetState            = vehicleControlAddon.vcaSetState
	self.vcaSetNewDefault       = vehicleControlAddon.vcaSetNewDefault
	self.vcaGetDefault          = vehicleControlAddon.vcaGetDefault
	self.vcaGetState            = vehicleControlAddon.vcaGetState
	self.vcaIsValidCam          = vehicleControlAddon.vcaIsValidCam
	self.vcaIsActive            = vehicleControlAddon.vcaIsActive
	self.vcaIsNonDefaultProp    = vehicleControlAddon.vcaIsNonDefaultProp
	self.vcaGetSteeringNode     = vehicleControlAddon.vcaGetSteeringNode
	self.vcaIsVehicleControlledByPlayer = vehicleControlAddon.vcaIsVehicleControlledByPlayer
	self.vcaGetShuttleCtrl      = vehicleControlAddon.vcaGetShuttleCtrl
	self.vcaGetAutoHold         = vehicleControlAddon.vcaGetAutoHold
	self.vcaGetIsReverse        = vehicleControlAddon.vcaGetIsReverse
	self.vcaGetDiffState        = vehicleControlAddon.vcaGetDiffState
	self.vcaHasDiffFront        = vehicleControlAddon.vcaHasDiffFront
	self.vcaHasDiffAWD          = vehicleControlAddon.vcaHasDiffAWD 
	self.vcaHasDiffBack         = vehicleControlAddon.vcaHasDiffBack 
	self.vcaSetSnapFactor       = vehicleControlAddon.vcaSetSnapFactor
	self.vcaGetCurrentSnapAngle = vehicleControlAddon.vcaGetCurrentSnapAngle
	self.vcaGetSnapWillInvert   = vehicleControlAddon.vcaGetSnapWillInvert
	self.vcaGetSnapIsInverted   = vehicleControlAddon.vcaGetSnapIsInverted
	self.vcaGetSnapDistance     = vehicleControlAddon.vcaGetSnapDistance
	self.vcaSetCruiseSpeed      = vehicleControlAddon.vcaSetCruiseSpeed
	self.vcaSpeedToString       = vehicleControlAddon.vcaSpeedToString
	self.vcaSetToolStateRec     = vehicleControlAddon.vcaSetToolStateRec
	
-- called by FS22_HeadlandManagement
	self.vcaSnapReverseLeft     = vehicleControlAddon.vcaSnapReverseLeft
	self.vcaSnapReverseRight    = vehicleControlAddon.vcaSnapReverseRight
-- called by FS22_HeadlandManagement

	for name,prop in pairs( vehicleControlAddon.properties ) do 
		self:vcaSetState( name, self:vcaGetDefault( name ), true )
	end 
	
	self.spec_vca.movingDir     = 0
	self.spec_vca.lastFactor    = 0
	self.spec_vca.warningTimer  = 0
	self.spec_vca.tickDt        = 16.667
	self.spec_vca.isEntered     = false
	self.spec_vca.keepCamRot    = false 
	self.spec_vca.kRToggleIn    = false 
	self.spec_vca.kRToggleOut   = false 
  self.spec_vca.snapDisabled  = false 
  self.spec_vca.snapPossible  = false 
  self.spec_vca.gpsProSeed    = false 
	self.spec_vca.snapNoDisableTimer = 0

	self.spec_vca.maxWheelSlip  = 0
	self.spec_vca.maxBrakePedal = 1
	self.spec_vca.maxThrottle   = 1
	self.spec_vca.maxThrottleT  = 0
	
	self.spec_vca.lasWheelSlip  = 0
	
	self.spec_vca.keepRotPressed   = false 
	self.spec_vca.inchingPressed   = false 
	self.spec_vca.keepSpeedPressed = false 		
	
	self.spec_vca.lastGearShiftTime = vehicleControlAddon.shiftTimeDefault
	self.spec_vca.lastGrpShiftTime  = vehicleControlAddon.shiftTimeDefault

	if self.isClient then 
		if vehicleControlAddon.snapOnSample == nil then 
			local fileName = Utils.getFilename( "ogg/GPS_on.ogg", g_vehicleControlAddon.vcaDirectory)
			vehicleControlAddon.snapOnSample = createSample("AutoSteerOnSound")
			loadSample(vehicleControlAddon.snapOnSample, fileName, false)
		end 
		
		if vehicleControlAddon.snapOffSample == nil then 
			local fileName = Utils.getFilename( "ogg/GPS_off.ogg", g_vehicleControlAddon.vcaDirectory)
			vehicleControlAddon.snapOffSample = createSample("AutoSteerOffSound")
			loadSample(vehicleControlAddon.snapOffSample, fileName, false)
		end 

		if vehicleControlAddon.ovDiffLockFront == nil then
			vehicleControlAddon.ovDiffLockFront  = createImageOverlay( Utils.getFilename( "dds/diff_front.dds",     g_vehicleControlAddon.vcaDirectory))
			vehicleControlAddon.ovDiffLockMid    = createImageOverlay( Utils.getFilename( "dds/diff_middle.dds",    g_vehicleControlAddon.vcaDirectory))
			vehicleControlAddon.ovDiffLockBack   = createImageOverlay( Utils.getFilename( "dds/diff_back.dds",      g_vehicleControlAddon.vcaDirectory))
			vehicleControlAddon.ovDiffLockFL     = createImageOverlay( Utils.getFilename( "dds/diff_wheels_fl.dds", g_vehicleControlAddon.vcaDirectory))
			vehicleControlAddon.ovDiffLockFR     = createImageOverlay( Utils.getFilename( "dds/diff_wheels_fr.dds", g_vehicleControlAddon.vcaDirectory))
			vehicleControlAddon.ovDiffLockRL     = createImageOverlay( Utils.getFilename( "dds/diff_wheels_rl.dds", g_vehicleControlAddon.vcaDirectory))
			vehicleControlAddon.ovDiffLockRR     = createImageOverlay( Utils.getFilename( "dds/diff_wheels_rr.dds", g_vehicleControlAddon.vcaDirectory))
			vehicleControlAddon.ovDiffLockBg     = createImageOverlay( Utils.getFilename( "dds/diff_bg.dds",        g_vehicleControlAddon.vcaDirectory))
			local r, g, b, a = unpack(vehicleControlAddon.colorBg)
			setOverlayColor( vehicleControlAddon.ovDiffLockBg, r, g, b, a )
			vehicleControlAddon.ovGearSpeedBg    = createImageOverlay( Utils.getFilename( "dds/gear_bg.dds",      g_vehicleControlAddon.vcaDirectory))
			setOverlayColor( vehicleControlAddon.ovGearSpeedBg, r, g, b, a )
			setOverlayUVs( vehicleControlAddon.ovGearSpeedBg, unpack( GuiUtils.getUVs( { 0, 0, 1024, 128 } ) ) )
			vehicleControlAddon.ovExtraTextBg    = createImageOverlay( Utils.getFilename( "dds/gear_bg.dds",      g_vehicleControlAddon.vcaDirectory))
			setOverlayColor( vehicleControlAddon.ovExtraTextBg, r, g, b, a )
			setOverlayUVs( vehicleControlAddon.ovExtraTextBg, unpack( GuiUtils.getUVs( { 0, 129, 1024, 256 } ) ) )
		end 
	end 
end

function vehicleControlAddon:onPostLoad(savegame)
	if self.spec_vca == nil then return end 

	if savegame ~= nil then
		if not ( vehicleControlAddon.initSpecializationDone ) then 
			print("Warning: calling vehicleControlAddon.initSpecialization during load")
			vehicleControlAddon.initSpecialization() 
		end 
		for name,prop in pairs( vehicleControlAddon.properties ) do 
			if prop.savegame then 
				local v = savegame.xmlFile:getValue(savegame.key .. "." .. g_vehicleControlAddon.vcaSpecName .. "#" .. name )
				if v ~= nil then 
					self:vcaSetState( name, v, true )
				end 
			end 
		end 
	end
	
	self.spec_vca.isForward = true  
	
	self.spec_vca.diffHasF = false 
	self.spec_vca.diffHasM = false 
	self.spec_vca.diffHas2 = false 
	self.spec_vca.diffHasB = false 
	self.spec_vca.wheelIndexFL = -1
	self.spec_vca.wheelIndexFR = -1
	self.spec_vca.wheelIndexRL = -1
	self.spec_vca.wheelIndexRR = -1
	
	if type( self.functionStatus ) == "function" and self:functionStatus("differential") then 
	-- TSX diffs ...
	elseif self.spec_crawlers ~= nil and #self.spec_crawlers.crawlers > 0 then 
	-- crawlers => not support as visible wheel will not turn in most cases
	elseif ( self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil )
			or ( self.numComponents == 2 and self.spec_crawlers ~= nil and #self.spec_crawlers.crawlers > 0 ) then 
	-- articulated axis 
		local spec       = self.spec_motorized
		local specWheels = self.spec_wheels
		local noPattern  = false 
		local rootNode1, rootNode2 
				
		if self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil then 
			local componentJoint = self.spec_articulatedAxis.componentJoint
			rootNode1 = self.components[componentJoint.componentIndices[1]].node
			rootNode2 = self.components[componentJoint.componentIndices[2]].node
		else 
		-- let's hope that the 2nd node is the front axle 
			rootNode1 = self.components[2].node 
			rootNode2 = self.components[1].node 
		end 
		
		local wx, wy, wz, lz1, lz2
		wx, wy, wz = getWorldTranslation(rootNode1)
		_,_, lz1 = worldToLocal(self:vcaGetSteeringNode(), wx, wy, wz)
		wx, wy, wz = getWorldTranslation(rootNode2)
		_,_, lz2 = worldToLocal(self:vcaGetSteeringNode(), wx, wy, wz)
		
		if lz1 > lz2 then 
			rootNode1, rootNode2 = rootNode2, rootNode1
		end 
		
		local function checkWheelsOfDiff( rootNode1, rootNode2, index, isWheel, depth )
			local d2 = 2 
			if type( depth ) == 'number' then 
				if depth > #spec.differentials then 
					print("VCA: found recursion in differential definition")
					noPattern = true 
					return false, false, false 
				end 
				d2 = depth + 1
			end 
			if isWheel then 
				local wheel    = self:getWheelFromWheelIndex( index )
				local rootNode = self:getParentComponent(wheel.repr)
				if     rootNode == rootNode1 then
					return true, false, true  
				elseif rootNode == rootNode2 then 
					return false, true, true 
				else 
					return false, false, false 
				end 
			else 				
				local diff = spec.differentials[index+1] 				
				local c11, c21, a1 = checkWheelsOfDiff( rootNode1, rootNode2, diff.diffIndex1, diff.diffIndex1IsWheel, d2 )
				local c12, c22, a2 = checkWheelsOfDiff( rootNode1, rootNode2, diff.diffIndex2, diff.diffIndex2IsWheel, d2 )				
				return c11 or c12, c21 or c22, a1 and a2 
			end 
		end 
		
		for k,differential in pairs(spec.differentials) do
			local c1, c2, all = checkWheelsOfDiff( rootNode1, rootNode2, k-1, false )
			if all and ( c1 or c2 ) then  

				local lx1, lx2 = nil, nil 
				if differential.diffIndex1IsWheel and differential.diffIndex2IsWheel then 
					local wx, wy, wz
					wx, wy, wz = getWorldTranslation( self:getWheelFromWheelIndex( differential.diffIndex1 ).node )
					lx1,_,_ = worldToLocal(self:vcaGetSteeringNode(), wx, wy, wz)
					wx, wy, wz = getWorldTranslation( self:getWheelFromWheelIndex( differential.diffIndex2 ).node )
					lx2,_,_ = worldToLocal(self:vcaGetSteeringNode(), wx, wy, wz)
				end 

				if c1 and c2 then 
					vcaDebugPrint("Diff. "..tostring(k-1).." is in the middle")
					differential.vcaMode = 'M' 
					self.spec_vca.diffHasM     = true 
				elseif c1 then 
					vcaDebugPrint("Diff. "..tostring(k-1).." is at the front")
					differential.vcaMode = 'F' 

					if self.spec_vca.diffHasF or lx1 == nil or lx2 == nil then 
						self.spec_vca.wheelIndexFL = -1
						self.spec_vca.wheelIndexFR = -1
					elseif lx1 > lx2 then 
						self.spec_vca.wheelIndexFL = differential.diffIndex1
						self.spec_vca.wheelIndexFR = differential.diffIndex2
					else
						self.spec_vca.wheelIndexFL = differential.diffIndex2
						self.spec_vca.wheelIndexFR = differential.diffIndex1 
					end 

					self.spec_vca.diffHasF     = true 
				else --if c2 then; is always true 
					vcaDebugPrint("Diff. "..tostring(k-1).." is at the back")
					differential.vcaMode = 'B' 

					if self.spec_vca.diffHasB or lx1 == nil or lx2 == nil then 
						self.spec_vca.wheelIndexRL = -1
						self.spec_vca.wheelIndexRR = -1
					elseif lx1 > lx2 then 
						self.spec_vca.wheelIndexRL = differential.diffIndex1
						self.spec_vca.wheelIndexRR = differential.diffIndex2
					else
						self.spec_vca.wheelIndexRL = differential.diffIndex2
						self.spec_vca.wheelIndexRR = differential.diffIndex1 
					end 

					self.spec_vca.diffHasB     = true 
				end 
			else 
				vcaDebugPrint("Diff. "..tostring(k-1).." is mixed: "..tostring(c1)..", "..tostring(c2)..", "..tostring(all))
				noPattern = true 
			end 
			differential.vcaTorqueRatio   = differential.torqueRatio
			differential.vcaMaxSpeedRatio = differential.maxSpeedRatio
			differential.vcaIndex         = k-1
		end 
		
		if noPattern then 
			self.spec_vca.diffHasF = false 
			self.spec_vca.diffHasM = false 
			self.spec_vca.diffHasB = false 
		end 
	else 
	-- hopefully, a normal vehicle 
		local spec = self.spec_motorized
		local noPattern  = false 
				
		local function getMinMaxRotSpeed( index, isWheel, depth ) 
			local d2 = 2 
			if type( depth ) == 'number' then 
				if depth > #spec.differentials then 
					print("VCA: found recursion in differential definition")
					noPattern = true 
					return 0, 0
				end 
				d2 = depth + 1
			end 
			if isWheel then 
				local wheel = self:getWheelFromWheelIndex( index )
				if not wheel.showSteeringAngle then 
					return 0, 0
				elseif wheel.rotSpeed == nil then 
					return 0, 0
				else 
					local r = math.abs( wheel.rotSpeed ) 
					return r, r 
				end 
			else 
				local diff = spec.differentials[index+1] 
				
				local rMin1, rMax1 = getMinMaxRotSpeed( diff.diffIndex1, diff.diffIndex1IsWheel, d2 )
				local rMin2, rMax2 = getMinMaxRotSpeed( diff.diffIndex2, diff.diffIndex2IsWheel, d2 )
				
				return math.min( rMin1, rMin2 ), math.max( rMax1, rMax2 )
			end 
		end 
		
		for k,differential in pairs(spec.differentials) do
			local rMin1, rMax1 = getMinMaxRotSpeed( k-1, false )
			
			local lx1, lx2 = nil, nil 
			if differential.diffIndex1IsWheel and differential.diffIndex2IsWheel then 
				local wx, wy, wz
				wx, wy, wz = getWorldTranslation( self:getWheelFromWheelIndex( differential.diffIndex1 ).node )
				lx1,_,_ = worldToLocal(self:vcaGetSteeringNode(), wx, wy, wz)
				wx, wy, wz = getWorldTranslation( self:getWheelFromWheelIndex( differential.diffIndex2 ).node )
				lx2,_,_ = worldToLocal(self:vcaGetSteeringNode(), wx, wy, wz)
			end 
			
			if    rMax1 < 0.1 then 
				differential.vcaMode = 'B' -- back axle, no steering

				if self.spec_vca.diffHasB or lx1 == nil or lx2 == nil then 
					self.spec_vca.wheelIndexRL = -1
					self.spec_vca.wheelIndexRR = -1
				elseif lx1 > lx2 then 
					self.spec_vca.wheelIndexRL = differential.diffIndex1
					self.spec_vca.wheelIndexRR = differential.diffIndex2
				else
					self.spec_vca.wheelIndexRL = differential.diffIndex2
					self.spec_vca.wheelIndexRR = differential.diffIndex1 
				end 

				self.spec_vca.diffHasB = true 

			elseif rMin1 > 0.1 then 
				differential.vcaMode = 'F' -- front axle, with steering

				if self.spec_vca.diffHasF or lx1 == nil or lx2 == nil then 
					self.spec_vca.wheelIndexFL = -1
					self.spec_vca.wheelIndexFR = -1
				elseif lx1 > lx2 then 
					self.spec_vca.wheelIndexFL = differential.diffIndex1
					self.spec_vca.wheelIndexFR = differential.diffIndex2
				else
					self.spec_vca.wheelIndexFL = differential.diffIndex2
					self.spec_vca.wheelIndexFR = differential.diffIndex1 
				end 

				self.spec_vca.diffHasF = true 

			elseif not differential.diffIndex1IsWheel and not differential.diffIndex2IsWheel then 
				differential.vcaMode = 'M' -- mid differential, between front and back
				self.spec_vca.diffHasM = true 
				
				local rMin1, rMax1 = getMinMaxRotSpeed( differential.diffIndex1, differential.diffIndex1IsWheel )
				local rMin2, rMax2 = getMinMaxRotSpeed( differential.diffIndex2, differential.diffIndex2IsWheel )
				if     rMin1 > 0.1 and rMax2 < 0.1 then 
					differential.vcaTorqueRatioOpen = 0
					self.spec_vca.diffHas2 = true 
				elseif rMin2 > 0.1 and rMax1 < 0.1 then 
					differential.vcaTorqueRatioOpen = 1 
					self.spec_vca.diffHas2 = true 
				end 
			else 
				differential.vcaMode = '-' -- bad 
				noPattern = true 
			end 
			differential.vcaTorqueRatio   = differential.torqueRatio
			differential.vcaMaxSpeedRatio = differential.maxSpeedRatio
			differential.vcaIndex         = k-1
		end 
		
		if noPattern then 
			self.spec_vca.diffHasF = false 
			self.spec_vca.diffHasM = false 
			self.spec_vca.diffHasB = false 
			self.spec_vca.diffHas2 = false 
		end 
	end
	
	self.spec_vca.isInitialized = true 				
end 

function vehicleControlAddon:saveToXMLFile(xmlFile, key, usedModNames)
	if not ( vehicleControlAddon.initSpecializationDone ) then 
		print("Warning: calling vehicleControlAddon.initSpecialization during save")
		vehicleControlAddon.initSpecialization() 
	end 

	for name,prop in pairs( vehicleControlAddon.properties ) do 
		if prop.savegame and self:vcaIsNonDefaultProp( name ) then 
			xmlFile:setValue(key .. "#" .. name, self.spec_vca[name])
		end 
	end 
end 

function vehicleControlAddon.isMPMaster()
	if g_vehicleControlAddon.isMP then 
		return g_currentMission.isMasterUser 
	end 
	return g_server ~= nil 
end 

function vehicleControlAddon:vcaSnapReverseLeft()
-- called by FS22_HeadlandManagement
	self:vcaSetState( "snapIsOn", true )
	if     self.spec_vca.snapDirection == 1 then
		self:vcaSetState( "snapDirection", 3 )
	elseif self.spec_vca.snapDirection == 2 then
		self:vcaSetState( "snapDirection", 4 )
	elseif self.spec_vca.snapDirection == 3 then
		self:vcaSetState( "snapDirection", 1 )
	elseif self.spec_vca.snapDirection == 4 then
		self:vcaSetState( "snapDirection", 2 )
	end 
	local l,r = self.spec_vca.snapLeft, self.spec_vca.snapRight 
	self:vcaSetState( "snapFactor", -self.spec_vca.snapFactor + l )
	self:vcaSetState( "snapLeft", r )
	self:vcaSetState( "snapRight", l )
	self.spec_vca.snapPosTimer = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
	self.spec_vca.snapNoDisableTimer = g_currentMission.time + 2000
end 

function vehicleControlAddon:vcaSnapReverseRight()
-- called by FS22_HeadlandManagement
	self:vcaSetState( "snapIsOn", true )
	if     self.spec_vca.snapDirection == 1 then
		self:vcaSetState( "snapDirection", 3 )
	elseif self.spec_vca.snapDirection == 2 then
		self:vcaSetState( "snapDirection", 4 )
	elseif self.spec_vca.snapDirection == 3 then
		self:vcaSetState( "snapDirection", 1 )
	elseif self.spec_vca.snapDirection == 4 then
		self:vcaSetState( "snapDirection", 2 )
	end 
	local l,r = self.spec_vca.snapLeft, self.spec_vca.snapRight 
	self:vcaSetState( "snapFactor", -self.spec_vca.snapFactor - r )
	self:vcaSetState( "snapLeft", r )
	self:vcaSetState( "snapRight", l )
	self.spec_vca.snapPosTimer = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
	self.spec_vca.snapNoDisableTimer = g_currentMission.time + 2000
end 

function vehicleControlAddon:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	self.spec_vca.activeActionEvents = nil 
	if self.spec_vca == nil then return end 
	
	if self.isClient and self:getIsActiveForInput(true, true) then
		if self.spec_vca.actionEvents == nil then 
			self.spec_vca.actionEvents = {}
		else	
			self:clearActionEventsTable( self.spec_vca.actionEvents )
		end 
		self.spec_vca.activeActionEvents = {}
		
		for _,actionName in pairs({ "vcaSETTINGS",  
																"vcaGLOBALS",  
                                "vcaUP",        
                                "vcaDOWN",      
                                "vcaLEFT",      
                                "vcaRIGHT",     
                                "vcaSnapUP",        
                                "vcaSnapDOWN",      
                                "vcaSnapLEFT",      
                                "vcaSnapRIGHT", 
																"vcaNO_ARB",
																"vcaINCHING",
																"vcaKEEPROT",
																"vcaKEEPROT2",
																"vcaKEEPSPEED",
																"vcaKEEPSPEED2",
																"vcaKSAXIS",
																"vcaSWAPSPEED",
                                "vcaSNAP",
                                "vcaSNAPPREV",
                                "vcaSNAPCONT",
                                "vcaSNAPNEXT",
																"vcaSNAPLEFT",
																"vcaSNAPRIGHT",
                                "vcaSNAPRESET",
                                "vcaSNAPDIST",
																"vcaDiffLockF",
																"vcaDiffLockM",
																"vcaDiffLockB",
																"vcaHandRpm",
																"vcaLowerF",
																"vcaLowerB",
																"vcaActivateF",
																"vcaActivateB",
																"vcaHandbrake",
																"vcaLimitSpeed",
																"vcaAutoShift",
																"vcaWORKAREA",
																"vcaSNAPPATH",
																"vcaGearSplitUp",
																"vcaGearSplitDown",
															}) do
																
			local addThis = InputAction[actionName] ~= nil   
			
			if actionName == "vcaGLOBALS" then 
				addThis = vehicleControlAddon.isMPMaster()
			end 
			
			if      addThis 
					and ( isOnActiveVehicle 
						or  actionName == "vcaUP"
						or  actionName == "vcaDOWN"
						or  actionName == "vcaLEFT"
						or  actionName == "vcaRIGHT"
						or  actionName == "vcaKEEPROT"
						or  actionName == "vcaSWAPSPEED") then 
				-- above actions are still active for hired worker
				local triggerKeyUp, triggerKeyDown, triggerAlways, isActive = false, true, false, true 
				if     actionName == "vcaUP"
						or actionName == "vcaDOWN"
						or actionName == "vcaLEFT"
						or actionName == "vcaRIGHT" 
						or actionName == "vcaNO_ARB"
						then 
					triggerKeyUp   = true 
				elseif actionName == "vcaKEEPSPEED" 
						or actionName == "vcaKEEPROT"
						or actionName == "vcaINCHING"
						or actionName == "vcaSnapDOWN"
						or actionName == "vcaSnapUP"
						or actionName == "vcaSnapLEFT"
						or actionName == "vcaSnapRIGHT"
						then 
					triggerKeyUp   = true 
					triggerKeyDown = false 
					triggerAlways  = true 
				elseif actionName == "vcaHandRpm" 
						or actionName == "vcaKSAXIS"
						then 
					triggerAlways  = true 
				end 
				
				if     actionName == "vcaSNAP"
						or actionName == "vcaSnapUP"     
						or actionName == "vcaSnapDOWN"     
						or actionName == "vcaSnapLEFT"    
						or actionName == "vcaSnapRIGHT"
						or actionName == "vcaSNAPPREV"
						or actionName == "vcaSNAPCONT"
						or actionName == "vcaSNAPNEXT"
						or actionName == "vcaSNAPLEFT"
						or actionName == "vcaSNAPRIGHT"
						or actionName == "vcaSNAPRESET"
						or actionName == "vcaSNAPDIST" 
						or actionName == "vcaKSAXIS"
						or actionName == "vcaDiffLockF"
						or actionName == "vcaDiffLockM"
						or actionName == "vcaDiffLockB"
						then 
					isActive = false 
				end 
				
				local _, eventName = self:addActionEvent(self.spec_vca.actionEvents, InputAction[actionName], self, vehicleControlAddon.actionCallback, triggerKeyUp, triggerKeyDown, triggerAlways, isActive, nil);

				if not isActive then 
					self.spec_vca.activeActionEvents[actionName] = false 
				end 
				
				if      g_inputBinding                   ~= nil 
						and g_inputBinding.events            ~= nil 
						and g_inputBinding.events[eventName] ~= nil
						and actionName == "vcaSETTINGS" then 
					if isSelected then
						g_inputBinding.events[eventName].displayPriority = 1
					elseif  isOnActiveVehicle then
						g_inputBinding.events[eventName].displayPriority = 4
					end
				end
			end
		end
		
	--vehicleControlAddon.updateActionEvents(self)
	end
end

function vehicleControlAddon:updateActionEvents()
	if self.spec_vca == nil or self.spec_vca.activeActionEvents == nil then  
		return 
	end 
	
	for actionName, wasActive in pairs( self.spec_vca.activeActionEvents ) do
		local actionEvent = nil
		if InputAction[actionName] ~= nil then 
			actionEvent = self.spec_vca.actionEvents[InputAction[actionName]]
		end 
		if actionEvent ~= nil then 
			local isActive = false 
			if     actionName == "vcaSNAP" then 
				isActive = not self.spec_vca.snapDisabled
			elseif actionName == "vcaSnapUP"     
					or actionName == "vcaSnapDOWN"     
					or actionName == "vcaSnapLEFT"    
					or actionName == "vcaSnapRIGHT"
					or actionName == "vcaSNAPPREV"
					or actionName == "vcaSNAPCONT"
					or actionName == "vcaSNAPNEXT"
					or actionName == "vcaSNAPLEFT"
					or actionName == "vcaSNAPRIGHT"
					or actionName == "vcaSNAPRESET"
					or actionName == "vcaSNAPDIST" 
					then 
				isActive = self.spec_vca.snapPossible 
			elseif actionName == "vcaKSAXIS" then 
				isActive = self.spec_vca.ksIsOn 
			elseif actionName == "vcaDiffLockF" then
				isActive = self:vcaHasDiffFront()
			elseif actionName == "vcaDiffLockM" then
				isActive = self:vcaHasDiffAWD()
			elseif actionName == "vcaDiffLockB" then
				isActive = self:vcaHasDiffBack()
			end 
			
			self.spec_vca.activeActionEvents[actionName] = isActive
			
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, isActive)
		end 
	end 
end 

function vehicleControlAddon:actionCallback(actionName, keyStatus, callbackState, isAnalog, isMouse, deviceCategory)
	
--vcaDebugPrint(actionName..", "..tostring(keyStatus))
	
	if     actionName == "vcaSnapDOWN"
			or actionName == "vcaSnapUP"
			or actionName == "vcaSnapLEFT"
			or actionName == "vcaSnapRIGHT"
			then  
		if self.spec_vca.actionTimer == nil then 
			self.spec_vca.actionTimer = {} 
		end 
		
		if keyStatus < 0.5 then 
			self.spec_vca.actionTimer[actionName] = nil 
			return 
		elseif self.spec_vca.actionTimer[actionName] == nil then 
			self.spec_vca.actionTimer[actionName] = g_currentMission.time + 500 
		elseif self.spec_vca.actionTimer[actionName] > g_currentMission.time then 
			return 
		else 
			self.spec_vca.actionTimer[actionName] = g_currentMission.time + 100
		end 
	end 
	
	if     actionName == "vcaKEEPROT" then 
		self.spec_vca.keepRotPressed   = keyStatus >= 0.5 			
	elseif actionName == "vcaKEEPROT2" then 
		
		local krToggle = "kRToggleOut"
		if self.spec_vca.camIsInside then 
			krToggle = "kRToggleIn"
		end 
		self.spec_vca[krToggle] = not self.spec_vca[krToggle] 
		self.spec_vca.keepCamRot = self.spec_vca[krToggle] 
			
	elseif actionName == "vcaINCHING" then 
		self.spec_vca.inchingPressed   = keyStatus >= 0.5 
	elseif actionName == "vcaKEEPSPEED" then 
		self.spec_vca.keepSpeedPressed = keyStatus >= 0.5 		
	elseif actionName == "vcaKEEPSPEED2" then 
		self:vcaSetState( "ksToggle", not self.spec_vca.ksToggle )
		if self.spec_vca.ksToggle then 
			self:vcaSetState( "keepSpeed", self.lastSpeed * 3600 )
			self:vcaSetState( "ksIsOn", true )
		else 
			self:vcaSetState( "ksIsOn", false )
		end 
	elseif actionName == "vcaLimitSpeed" then 
		self:vcaSetState( "speedLimiter", not self.spec_vca.speedLimiter)
		
	elseif actionName == "vcaUP"
			or actionName == "vcaDOWN"
			or actionName == "vcaLEFT"
			or actionName == "vcaRIGHT" then

		if not ( self.spec_vca.peekLeftRight ) then 
			if     actionName == "vcaUP" then
				self.spec_vca.newRotCursorKey = 0
			elseif actionName == "vcaDOWN" then
				self.spec_vca.newRotCursorKey = math.pi
			elseif actionName == "vcaLEFT" then
				if not ( self.spec_vca.isForward ) then
					self.spec_vca.newRotCursorKey =  0.7*math.pi
				else 
					self.spec_vca.newRotCursorKey =  0.3*math.pi
				end 
			elseif actionName == "vcaRIGHT" then
				if not ( self.spec_vca.isForward ) then
					self.spec_vca.newRotCursorKey = -0.7*math.pi
				else 
					self.spec_vca.newRotCursorKey = -0.3*math.pi
				end 
			end
			self.spec_vca.prevRotCursorKey  = nil 
		elseif keyStatus >= 0.5 then 
			local i = self.spec_enterable.camIndex
			local r = nil
			if i ~= nil and self.spec_enterable.cameras[i].rotY and self.spec_enterable.cameras[i].origRotY ~= nil then 
				r = vehicleControlAddon.normalizeAngle( self.spec_enterable.cameras[i].rotY - self.spec_enterable.cameras[i].origRotY )
			end

			if     actionName == "vcaUP" then
				if     r == nil then 
					self.spec_vca.newRotCursorKey = math.pi
				elseif math.abs( r ) < 0.3 then
					if     r < -0.1 then 
						self.spec_vca.newRotCursorKey = - math.pi
					elseif r >  0.1 then 
						self.spec_vca.newRotCursorKey = math.pi
					else                              
						self.spec_vca.newRotCursorKey = - math.pi
					end 
				else 
					self.spec_vca.newRotCursorKey = 0
				end 
				self.spec_vca.prevRotCursorKey  = nil 
				r = nil
			elseif actionName == "vcaDOWN" then
				if     r == nil then 
					self.spec_vca.newRotCursorKey = nil
				elseif math.abs( r ) < 0.5 * math.pi then
					if     r < -0.1 then 
						self.spec_vca.newRotCursorKey = - math.pi
					elseif r >  0.1 then 
						self.spec_vca.newRotCursorKey = math.pi
					else 
						self.spec_vca.newRotCursorKey = - math.pi
					end 
				else 
					self.spec_vca.newRotCursorKey = 0
				end 
			elseif actionName == "vcaLEFT" then
				if     r ~= nil and math.abs( r ) > 0.7 * math.pi then
					self.spec_vca.newRotCursorKey =  0.7*math.pi
				elseif r ~= nil and math.abs( r ) < 0.3 * math.pi then
					self.spec_vca.newRotCursorKey =  0.3*math.pi
				else 
					self.spec_vca.newRotCursorKey =  0.5*math.pi
				end 
			elseif actionName == "vcaRIGHT" then
				if     r ~= nil and math.abs( r ) > 0.7 * math.pi then
					self.spec_vca.newRotCursorKey = -0.7*math.pi
				elseif r ~= nil and math.abs( r ) < 0.3 * math.pi then
					self.spec_vca.newRotCursorKey = -0.3*math.pi
				else 
					self.spec_vca.newRotCursorKey = -0.5*math.pi
				end 
			end
			
			if self.spec_vca.prevRotCursorKey == nil and r ~= nil then 
				self.spec_vca.prevRotCursorKey = r 
			end 
		elseif self.spec_vca.prevRotCursorKey ~= nil then 
			self.spec_vca.newRotCursorKey  = self.spec_vca.prevRotCursorKey
			self.spec_vca.prevRotCursorKey = nil
		end
	elseif actionName == "vcaSWAPSPEED" then 
		local temp = self.spec_drivable.cruiseControl.speed
    self:vcaSetCruiseSpeed( self.spec_vca.ccSpeed2 )
		self:vcaSetState( "ccSpeed2", self.spec_vca.ccSpeed3 )
		self:vcaSetState( "ccSpeed3", temp )
	elseif actionName == "vcaNO_ARB" then 
		self:vcaSetState( "noAutoRotBack", keyStatus >= 0.5 )
		
	elseif  self.spec_vca.snapPossible
			and ( actionName == "vcaSnapLEFT" or actionName == "vcaSnapRIGHT" ) then
			
		self.spec_vca.snapPosTimer  = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
		
		local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )			
		local d = 0
		if lx*lx+lz*lz > 1e-6 then 
			d = math.atan2( lx, lz )
		end 
		local a  = self:vcaGetCurrentSnapAngle( d )
		local dx = math.sin( a )
		local dz = math.cos( a )			
		local fx = 0
		local fz = 0
		
		if     actionName == "vcaSnapLEFT"  then
			fx = 0.1 
		else
			fx = -0.1 
		end 

		self:vcaSetState( "lastSnapPosX", self.spec_vca.lastSnapPosX + fz * dx + fx * dz )
		self:vcaSetState( "lastSnapPosZ", self.spec_vca.lastSnapPosZ + fz * dz - fx * dx )
		
	elseif  self.spec_vca.snapPossible
			and actionName == "vcaSnapDOWN" then 
		self.spec_vca.snapPosTimer  = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
		self:vcaSetState( "lastSnapAngle", vehicleControlAddon.normalizeAngle( self.spec_vca.lastSnapAngle - math.rad(0.1*vehicleControlAddon.snapAngles[self.spec_vca.snapAngle])))
		self:vcaSetSnapFactor()
	elseif  self.spec_vca.snapPossible
			and actionName == "vcaSnapUP" then 
		self.spec_vca.snapPosTimer  = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
		self:vcaSetState( "lastSnapAngle", vehicleControlAddon.normalizeAngle( self.spec_vca.lastSnapAngle + math.rad(0.1*vehicleControlAddon.snapAngles[self.spec_vca.snapAngle])))
		self:vcaSetSnapFactor()
	elseif actionName == "vcaSNAPRESET" then
		self:vcaSetState( "lastSnapAngle", 10 )
		self:vcaSetState( "lastSnapPosX", 0 )
		self:vcaSetState( "lastSnapPosZ", 0 )
		self:vcaSetState( "snapIsOn", false )
		self:vcaSetState( "snapDirection", 0 )
		self.spec_vca.currentPath = nil 
	elseif actionName == "vcaSNAPDIST" then
		local d, o, p = self:vcaGetSnapDistance()
		self:vcaSetState( "snapDistance", d )
		self:vcaSetState( "snapOffset",   o )
		self:vcaSetState( "snapInvert",   p )
		self:vcaSetState( "warningText", vehicleControlAddon.getText("vcaDISTANCE", "Width")..": "..vehicleControlAddon.formatNumber( self.spec_vca.snapDistance ) )
		self.spec_vca.snapPosTimer = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
	elseif actionName == "vcaSNAP" then
		if false and ( self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil ) then 
			self:vcaSetState("warningText",vehicleControlAddon.getText("vcaSnapArtAxis", "VCA does not support articulated axis"))
		else 
			self:vcaSetState( "snapIsOn", not self.spec_vca.snapIsOn )
			if self.spec_vca.snapIsOn then 
				self:vcaSetState( "snapDirection", 0 )
			end 
			self:vcaSetSnapFactor()
		end 
	elseif actionName == "vcaSNAPPREV" 
			or actionName == "vcaSNAPNEXT" then
		if actionName == "vcaSNAPNEXT" then
			self:vcaSetState( "snapFactor", self.spec_vca.snapFactor + 1 )
		else 
			self:vcaSetState( "snapFactor", self.spec_vca.snapFactor - 1 )
		end 
		self.spec_vca.snapPosTimer = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
	elseif actionName == "vcaSNAPLEFT" then 
		self:vcaSnapReverseLeft()
	elseif actionName == "vcaSNAPRIGHT" then
		self:vcaSnapReverseRight()
	elseif actionName == "vcaSNAPCONT" then
		if  -4 <= self.spec_vca.lastSnapAngle and self.spec_vca.lastSnapAngle <= 4 and self.spec_vca.snapDistance >= 0.25 then 
			self:vcaSetState( "snapIsOn", true )
		end 
	elseif actionName == "vcaSETTINGS" then
		vehicleControlAddon.vcaShowSettingsUI( self )
	elseif actionName == "vcaAutoShift" then
		self:vcaSetState( "autoShift", not self.spec_vca.autoShift )
	elseif actionName == "vcaHandbrake" then
		self:vcaSetState( "handbrake", not self.spec_vca.handbrake )
	elseif actionName == "vcaDiffLockF" then
		if self:vcaIsVehicleControlledByPlayer() and self:vcaHasDiffFront() then
			self:vcaSetState( "diffLockFront", not self.spec_vca.diffLockFront )
		end 
	elseif actionName == "vcaDiffLockM" then
		if self:vcaIsVehicleControlledByPlayer() and self:vcaHasDiffAWD() then  
			self:vcaSetState( "diffLockAWD", not self.spec_vca.diffLockAWD )
		end 
	elseif actionName == "vcaDiffLockB" then
		if self:vcaIsVehicleControlledByPlayer() and self:vcaHasDiffBack() then
			self:vcaSetState( "diffLockBack", not self.spec_vca.diffLockBack )
		end 
	elseif actionName == "vcaKSAXIS" and self.spec_vca.ksIsOn then 
		if self.spec_vca.keepSpeedTemp == nil then 
			self.spec_vca.keepSpeedTemp = self.spec_vca.keepSpeed
		end 
		if     math.abs( self.spec_vca.keepSpeedTemp ) <  1 then 
			if     keyStatus > 0 then 
				self.spec_vca.keepSpeedTemp = 1 
			elseif keyStatus < 0 then 
				self.spec_vca.keepSpeedTemp = -1 
			end 
		elseif isAnalog then 
			self.spec_vca.keepSpeedTemp = self.spec_vca.keepSpeedTemp + keyStatus
		elseif math.abs( self.spec_vca.keepSpeedTemp ) <  5 then 
			self.spec_vca.keepSpeedTemp = 0.1 * math.floor( 10 * self.spec_vca.keepSpeedTemp + keyStatus + 0.5 )
		elseif math.abs( self.spec_vca.keepSpeedTemp ) < 10 then 
			self.spec_vca.keepSpeedTemp = 0.2 * math.floor(  5 * self.spec_vca.keepSpeedTemp + keyStatus + 0.5 )
		elseif math.abs( self.spec_vca.keepSpeedTemp ) < 20 then 
			self.spec_vca.keepSpeedTemp = 0.4 * math.floor(2.5 * self.spec_vca.keepSpeedTemp + keyStatus + 0.5 )
		elseif math.abs( self.spec_vca.keepSpeedTemp ) < 30 then 
			self.spec_vca.keepSpeedTemp = 0.5 * math.floor(  2 * self.spec_vca.keepSpeedTemp + keyStatus + 0.5 )
		else
			self.spec_vca.keepSpeedTemp = math.floor(self.spec_vca.keepSpeedTemp + keyStatus + 0.5 )
		end 
	elseif actionName == "vcaHandRpm" then 
		local h = 0
		if self.spec_vca.handThrottle ~= nil and self.spec_vca.handThrottle > 0 then 
			h = self.spec_vca.handThrottle
		end 
		
		if     isAnalog then 
			if keyStatus > 0.5 then 
				self.spec_vca.handRpmFullAxis = true 
			end 
			if self.spec_vca.handRpmFullAxis then 
				h = 0.5 * ( 1 + keyStatus ) 
			else 
				h = 1 + keyStatus
			end 
		else
			if      h <= 0
					and type ( self.getMotorRpmPercentage ) == "function"
					and ( keyStatus > 0.5 
						or  self.spec_vca.locHandRpmTime == nil 
						or  g_currentMission.time > self.spec_vca.locHandRpmTime + 2000 )
					then 
				h = vehicleControlAddon.mbClamp( self:getMotorRpmPercentage() )
			end 
			self.spec_vca.locHandRpmTime = g_currentMission.time
			
			if keyStatus > 0.5 then 
				h = math.min( 1, h + 0.0005 * self.spec_vca.tickDt )
			elseif keyStatus < 0.5 then 
				h = math.max( 0, h - 0.0005 * self.spec_vca.tickDt )
			end 
		end 
		
		self:vcaSetState( "handThrottle", vehicleControlAddon.mbClamp( h, 0, 1 ) )

		if not isAnalog then 
			if h <= 0 then 
				self:vcaSetState( "warningText", vehicleControlAddon.getText( "vcaHANDTHROTTLE", "" )..": off" )
			elseif  self.spec_motorized ~= nil 
					and self.spec_motorized.motor ~= nil 
					and self.spec_motorized.motor.maxRpm ~= nil 
					and self.spec_motorized.motor.maxRpm > 0 then 
				local r = self.spec_motorized.motor.minRpm + h * ( self.spec_motorized.motor.maxRpm - self.spec_motorized.motor.minRpm )
				self:vcaSetState( "warningText", string.format("%s: %4.0f %s", vehicleControlAddon.getText( "vcaHANDTHROTTLE", "" ), r, vehicleControlAddon.getText( "vcaValueRPM", "RPM"  ) ) )
			end 
		end 
	elseif actionName == "vcaWORKAREA" then 
		if self.spec_vca.workAreaDraw >= 2 then 
			self:vcaSetState( "workAreaDraw", 0 )
		else 
			self:vcaSetState( "workAreaDraw", self.spec_vca.workAreaDraw + 1 )
		end
	elseif actionName == "vcaSNAPPATH" then 
		self:vcaSetState( "pathRecording", not self.spec_vca.pathRecording )
  elseif actionName == "vcaLowerF" then 
		self:vcaSetToolStateRec( true, false, true, false )
  elseif actionName == "vcaLowerB" then 
		self:vcaSetToolStateRec( true, false, false, true )
  elseif actionName == "vcaActivateF" then 
		self:vcaSetToolStateRec( false, true, true, false )
  elseif actionName == "vcaActivateB" then 
		self:vcaSetToolStateRec( false, true, false, true )
  elseif actionName == "vcaGearSplitDown" and self.spec_vca.gearSplitGear > 1 then  
		self:vcaSetState( "gearSplitGear", self.spec_vca.gearSplitGear - 1 )
  elseif actionName == "vcaGearSplitUp" and self.spec_vca.gearSplitGear <= self.spec_vca.splitGears then  
		self:vcaSetState( "gearSplitGear", self.spec_vca.gearSplitGear + 1 )
	end
end

function vehicleControlAddon:vcaSetToolStateRec( lowered, active, front, back, forceState )

-- AttacherJoints:handleLowerImplementByAttacherJointIndex(attacherJointIndex, direction)
-- if direction == nil then direction = not attacherJoint.moveDown end


--  if self:getCanToggleTurnedOn() and self:getCanBeTurnedOn() then self:setIsTurnedOn(not self:getIsTurnedOn()) ...

	local newState  = forceState 
	local recursive = true 

	if self.spec_attacherJoints ~= nil then 
		vcaDebugPrint(tostring(self.configFileName)..": "..tostring(lowered)..", "..tostring(active)..", "..tostring(front)..", "..tostring(back)..", "..tostring(forceState))
	
		local spec = self.spec_attacherJoints
		for _,attachedImplement in pairs( spec.attachedImplements ) do 
			local jointDesc = spec.attacherJoints[attachedImplement.jointDescIndex]
			
			local doit = false 
			if front and back then 
				doit = true 
			else 
				local wx, wy, wz = getWorldTranslation(jointDesc.jointTransform)
				local lx, ly, lz = worldToLocal(self:vcaGetSteeringNode(), wx, wy, wz)
				
				if lz > 0 then 
					doit = front 
				else 
					doit = back 
				end 
			end 
			
			if doit and attachedImplement.object ~= nil then 
				local object = attachedImplement.object 
				
				if lowered then -- key V
					if newState == nil then 
						-- getIsLowered is overwritte by Pickup and Foldable 
						-- but getAllowsLowering is not overwritten 
						if     object:getAllowsLowering()
								or object.spec_pickup     ~= nil
								or ( object.spec_foldable ~= nil 
								 and object.spec_foldable.foldMiddleAnimTime ~= nil
								 and object:getIsFoldMiddleAllowed())
								then 
							newState = not object:getIsLowered()
						end 
					end 
					
					if newState ~= nil and object.setLoweredAll ~= nil then 
						object:setLoweredAll(newState, attachedImplement.jointDescIndex)
					end 
				end 
				
				if active then -- key B
					if object.spec_plow ~= nil then 
						-- rotate plow
						local spec = object.spec_plow
						if spec.rotationPart.turnAnimation ~= nil then
							if object:getIsPlowRotationAllowed() then
								object:setRotationMax(not spec.rotationMax)
								recursive = false 
							end
						end
					elseif object.getIsTurnedOn ~= nil then 
						-- turn on 
						if newState == nil then 
							newState = not object:getIsTurnedOn() 
						end 
						
						if object:getCanToggleTurnedOn() and object:getCanBeTurnedOn() then
							object:setIsTurnedOn(newState)
						end 
					end 
				end 
				
				if recursive then
					vehicleControlAddon.vcaSetToolStateRec( object, lowered, active, true, true, newState )
				end 
			end 
		end 
	end 
end 

function vehicleControlAddon:vcaSetSnapFactor()
	if 			self.spec_vca.snapDistance >= 0.25 
			and self.spec_vca.snapIsOn
			and -4 <= self.spec_vca.lastSnapAngle and self.spec_vca.lastSnapAngle <= 4 then 
		local wx,wy,wz = getWorldTranslation( self:vcaGetSteeringNode() )
		local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )			
		local d = 0
		if lx*lx+lz*lz > 1e-6 then 
			d = math.atan2( lx, lz )
		end 
		
		if type( self.spec_vca.currentPath ) == "table" and table.getn( self.spec_vca.currentPath ) > 1 then 
			local minT = nil
			local minS = nil
			local minI = nil
			local minP = nil 
			for indx,point in pairs( self.spec_vca.currentPath ) do 
				local sx = point[1]
				local sz = point[2]
				local a  = point[3]
				local l  = point[4]
				local dx = math.sin(a)
				local dz = math.cos(a)
				local t  = ( wx - sx ) * dx + ( wz - sz ) * dz 
				local s  = ( wx - sx ) * dz - ( wz - sz ) * dx 
				
				local p  = math.max( 0, math.min( t, l ))
				local px = sx + p * dx 
				local pz = sz + p * dz 
				local p2 = (wx - px)^2 + (wz - pz)^2
				
				if minP == nil or p2 <= minP then 
					minP = p2 
					minS = s 
					minT = t 
					minI = indx 
				end 
			end 
			
			print(tostring(minI).." ("..tostring(minT)..", "..tostring(minS)..", "..tostring(minP)..")")

			if minS ~= nil then 
				local i = math.floor( 0.5 - minS / self.spec_vca.snapDistance )
				self:vcaSetState( "snapFactor", i )
			end 
				
		else
			local curSnapAngle, _, curSnapOffset = self:vcaGetCurrentSnapAngle( d )
			local dx    = math.sin( curSnapAngle )
			local dz    = math.cos( curSnapAngle )			
			local distX = wx - self.spec_vca.lastSnapPosX
			local distZ = wz - self.spec_vca.lastSnapPosZ
			local i     = self.spec_vca.snapFactor
			local function getDistance(i) 
				return distX * dz - distZ * dx + i * self.spec_vca.snapDistance + curSnapOffset
			end 
			local dist  = getDistance(i)

			while dist+dist > self.spec_vca.snapDistance do 
				i     = i - 1
				dist  = getDistance(i)
			end 
			while dist+dist <-self.spec_vca.snapDistance do 
				i     = i + 1
				dist  = getDistance(i)
			end 			
			self:vcaSetState( "snapFactor", i )
		end 
	end 
end

function vehicleControlAddon:onEnterVehicle( isControlling )
	self:vcaSetState( "isEnteredMP", true )
	self:vcaSetState( "isBlocked", false )
	self:vcaSetState( "ksIsOn", self.spec_vca.ksToggle )
end 

function vehicleControlAddon:onLeaveVehicle()
	if self.spec_vca.isEntered then 
		self:vcaSetState( "noAutoRotBack", false )
		self.spec_vca.newRotCursorKey  = nil
		self.spec_vca.prevRotCursorKey = nil
		self:vcaSetState( "snapIsOn", false )
		self:vcaSetState( "inchingIsOn", false )
		self:vcaSetState( "ksIsOn", false )
		self:vcaSetState( "keepSpeed", 0 )
		self:vcaSetState( "isEnteredMP", false )
		self:vcaSetState( "isBlocked", false )
		self:vcaSetState( "isForward", true )
		self:vcaSetState( "handThrottle", 0 )
		self.spec_vca.movingDir     = 1
		self.spec_vca.keepCamRot    = false 
	end 

	self.spec_vca.isEntered  = false 
end 

function vehicleControlAddon:vcaCruiseNotEntered()
	if      self.spec_vca ~= nil
			and self.spec_vca.farmId ~= nil and self.spec_vca.farmId ~= 0
			and self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
		return true 
	end 
	return false 
end 


function vehicleControlAddon:vcaIsVehicleControlledByPlayer()
	if self:getIsVehicleControlledByPlayer() then 
		return true 
	end 
	if not self:getIsControlled() then 
		return false 
	end 
	if self.spec_globalPositioningSystem == nil then 
		return false 
	end 
	if self.spec_globalPositioningSystem.guidanceSteeringIsActive then 
		return true 
	end 
	return false 
end 

function vehicleControlAddon:vcaIsActive()
	if self.spec_vca ~= nil and self:getIsEntered() and self:vcaIsVehicleControlledByPlayer() then 
		return true 
	end 
	return false
end 

function vehicleControlAddon:vcaGetShuttleCtrl()
	if			self.spec_motorized ~= nil 
			and self.spec_motorized.motor ~= nil 
			and self.spec_motorized.motor.directionChangeMode == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL
			then 
		return true 
	end 
	return false  
end 

function vehicleControlAddon:vcaGetIsReverse()
	return not self.spec_vca.isForward
end 

function vehicleControlAddon:vcaHasDiffFront()
	if not ( self.spec_vca.diffManual and self.spec_vca.diffHasF ) then 
		return false 
	end 
	if not self.spec_vca.diffHas2     then 
		return true 
	elseif self.spec_vca.diffLockSwap then 
		return true 
	elseif self.spec_vca.diffLockAWD  then 
		return true 
	end 
	return false 
end 

function vehicleControlAddon:vcaHasDiffAWD()
	if not ( self.spec_vca.diffManual and self.spec_vca.diffHasM ) then 
		return false 
	end 
	return true 
end 
	
function vehicleControlAddon:vcaHasDiffBack()
	if not ( self.spec_vca.diffManual and self.spec_vca.diffHasB ) then 
		return false 
	end 
	if not self.spec_vca.diffHas2     then 
		return true 
	elseif not self.spec_vca.diffLockSwap then 
		return true 
	elseif self.spec_vca.diffLockAWD  then 
		return true 
	end 
	return false 
end 
		
function vehicleControlAddon:vcaGetDiffState()
	if not ( self.spec_vca ~= nil
			 and ( self:vcaIsVehicleControlledByPlayer() or ( self.spec_vca.hiredWorker2 and self:getIsActive() ) )
			 and self:getIsMotorStarted()
			 and self.spec_vca.diffManual ) then  
	-- hired worker or motor off 
		return 0, 0, 0
	elseif  not self.spec_vca.diffHasF 
			and not self.spec_vca.diffHasM 
			and not self.spec_vca.diffHasB then
	-- no diffs or not the standard pattern
		return 0, 0, 0 
	end 
	
	local f, m, b = 0, 0, 0
	
	if self:vcaHasDiffFront() then 
		if self.spec_vca.diffLockFront then 
			f = 2 
		else 
			f = 1 
		end 
	end 
	
	if self:vcaHasDiffBack() then 
		if self.spec_vca.diffLockBack then 
			b = 2 
		else 
			b = 1 
		end 
	end 
	
	if self:vcaHasDiffAWD() then 
		if self.spec_vca.diffLockAWD then 
			m = 2 
		else 
			m = 1
		end 
	end 
	
	return f, m, b
end 

--******************************************************************************************************************************************
-- ProSeed
function vehicleControlAddon:vcaGetHasGuidanceSystem( superFunc )
	if self ~= nil and self.spec_vca ~= nil and self.spec_vca.snapPossible then 
		return true 
	end 
	if superFunc ~= nil then 
		return superFunc( self )
	end 
	return false 
end 
function vehicleControlAddon:vcaGetGuidanceData( superFunc )
	if not ( self ~= nil and self.spec_vca ~= nil and self.spec_vca.snapPossible ) then 
		if superFunc ~= nil then 
			return superFunc( self )
		end 
		return
	end 

	local data = {}
	
  data.width            = 3
  data.offsetWidth      = 0
  data.movingDirection  = 1
  data.isReverseDriving = false
  data.movingForwards   = false
  data.snapDirectionMultiplier = 1
  data.alphaRad         = 0
  data.currentLane      = 0
	data.snapDirection    = { 0, 0, 0, 0 }
  data.driveTarget      = { 0, 0, 0, 0, 0 }
	data.width            = self.spec_vca.snapDistance

	local wx,wy,wz = getWorldTranslation( self:vcaGetSteeringNode() )
	local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )			
	local d = 0
	if lx*lx+lz*lz > 1e-6 then 
		d = math.atan2( lx, lz )
	end 
	if not self.spec_vca.snapIsOn then 
		d = math.atan2( lx, lz )
	elseif self.spec_vca.snapDirection == 1 then 
		d = self.spec_vca.lastSnapAngle 
	elseif self.spec_vca.snapDirection == 2 then 
		d = self.spec_vca.lastSnapAngle + 0.5 * math.pi 
	elseif self.spec_vca.snapDirection == 3 then 
		d = self.spec_vca.lastSnapAngle + math.pi 
	elseif self.spec_vca.snapDirection == 4 then 
		d = self.spec_vca.lastSnapAngle - 0.5 * math.pi 
	else
		d = math.atan2( lx, lz )
	end 
	local curSnapAngle, curSnapOffset1, curSnapOffset2 = self:vcaGetCurrentSnapAngle( d )
	local dx    = math.sin( curSnapAngle )
	local dz    = math.cos( curSnapAngle )			

	data.snapDirection = { dz, dx, self.spec_vca.lastSnapPosX, self.spec_vca.lastSnapPosZ }

	if self.spec_vca.snapIsOn then 
		data.currentLane = self.spec_vca.snapFactor
	else
		data.currentLane = 0
		if self.spec_vca.snapDistance >= 0.25 then 
			local distX = wx - self.spec_vca.lastSnapPosX
			local distZ = wz - self.spec_vca.lastSnapPosZ 	
			local dist  = distX * dz - distZ * dx + curSnapOffset2
			while dist+dist > self.spec_vca.snapDistance do 
				dist = dist - self.spec_vca.snapDistance
				data.currentLane = data.currentLane - 1 
			end 
			while dist+dist <-self.spec_vca.snapDistance do 
				dist = dist + self.spec_vca.snapDistance
				data.currentLane = data.currentLane + 1 
			end 
		end 
	end 
	
	return data 
end 

function vehicleControlAddon:onPreUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
--******************************************************************************************************************************************


	if      self.isClient
			and self.spec_vca.isEntered
			and self.spec_vca.snapIsOn
			and self.spec_drivable ~= nil
			and self:getIsActiveForInput(true, true)
			and self:getIsVehicleControlledByPlayer()
			and math.abs( self.spec_drivable.lastInputValues.axisSteer ) > 0.15
			and self.spec_vca.snapNoDisableTimer < g_currentMission.time then 
		self:vcaSetState( "snapIsOn", false )
	end 
	
	self.spec_vca.snapDisabled = false 
	self.spec_vca.snapPossible = false 
	if self.spec_globalPositioningSystem ~= nil and self.spec_globalPositioningSystem.guidanceIsActive then
		self.spec_vca.snapDisabled = true 
	elseif not self:vcaIsVehicleControlledByPlayer()
			or self.aiveAutoSteer then 
		self.spec_vca.snapDisabled = true 
	elseif  -4 <= self.spec_vca.lastSnapAngle and self.spec_vca.lastSnapAngle <= 4
			and self.spec_vca.snapDistance >= 0.25
			and vehicleControlAddon.snapAngles[self.spec_vca.snapAngle] ~= nil then 
		self.spec_vca.snapPossible = true 
	end 

	if self.spec_vca.snapDisabled and self.spec_vca.snapIsOn then
		self:vcaSetState( "snapIsOn", false )
	end 
	
--******************************************************************************************************************************************
-- adaptive steering 	
	local lastAxisSteer, lastAxisSteerTime1, lastAxisSteerTime2
	
	if self.spec_vca.lastAxisSteer ~= nil then 
		lastAxisSteer               = self.spec_vca.lastAxisSteer
		lastAxisSteerTime1          = self.spec_vca.lastAxisSteerTime1
		lastAxisSteerTime2          = self.spec_vca.lastAxisSteerTime2
		self.spec_vca.lastAxisSteer       = nil
		self.spec_vca.lastAxisSteerAnalog = nil
		self.spec_vca.lastAxisSteerDevice = nil
		self.spec_vca.lastAxisSteerTime1  = nil
		self.spec_vca.lastAxisSteerTime2  = nil
	end 
	
  local resetRotSpeed = true 

	if      self.isClient
			and self.getIsEntered  ~= nil and self:getIsEntered()
			and self.spec_drivable ~= nil
			and not ( FS19_TrailerAssist ~= nil 
						and FS19_TrailerAssist.trailerAssist ~= nil
						and type( FS19_TrailerAssist.trailerAssist.isActive ) == "function"
						and FS19_TrailerAssist.trailerAssist.isActive( self ) )
      and self:getIsActiveForInput(true, true)
      and self:getIsVehicleControlledByPlayer() then 
			
		local noARB = self.spec_vca.noARBToggle 
		local ana   = self.spec_drivable.lastInputValues.axisSteerIsAnalog 
		local dev   = self.spec_drivable.lastInputValues.axisSteerDeviceCategory 
		if      self.spec_drivable.lastInputValues.axisSteer == 0
				and self.spec_vca.lastAxisSteer ~= nil then 
			ana = self.spec_vca.lastAxisSteerAnalog
			dev = self.spec_vca.lastAxisSteerDevice
		end 
		if  not VCAGlobals.mouseAutoRotateBack
				and ana 
				and dev == InputDevice.CATEGORY.KEYBOARD_MOUSE then 
			noARB = true 
		end 
		if self.spec_vca.noAutoRotBack then 
			noARB = not noARB
		end 
		
		local rso = 1
		if not ( 0.49 < self.spec_vca.rotSpeedOut and self.spec_vca.rotSpeedOut < 0.51 ) then 
			rso = vehicleControlAddon.mbClamp( self.spec_vca.rotSpeedOut + self.spec_vca.rotSpeedOut, 0.01, 2 )
		end 
		local rsi = 1
		if math.abs( self.spec_vca.rotSpeedIn - self.spec_vca.rotSpeedOut ) > 0.01 then 
			rsi = vehicleControlAddon.mbClamp( self.spec_vca.rotSpeedIn + self.spec_vca.rotSpeedIn, 0.01, 2 ) / rso 
		end 
		
		if self.spec_vca.steeringIsOn == nil then 
			self.spec_vca.steeringIsOn = vehicleControlAddon.steeringFalse
		end 
		
		--********************************************************************
		-- Old, soft steering with reduced steering speed 
		if self.spec_vca.steeringIsOn == vehicleControlAddon.steeringSoft then 
			resetRotSpeed = false 
			local speed = math.abs( self.lastSpeed * 3600 )
			local f = 1
			if     speed <= 12.5 then 
				f = 2 - 0.8 * speed / 12.5
			elseif speed <= 25 then 
				f = 1.2 - 0.5 * ( speed - 12.5 ) / 12.5 
			elseif speed <= 50 then 
				f = 0.7 - 0.3 * ( speed - 25 ) / 25 
			elseif speed <= 100 then 
				f = 0.4 - 0.3 * ( speed - 50 ) / 50 
			else 
				f = 0.1
			end 
			
			self.spec_vca.rotSpeedFactor      = f
			self.spec_vca.autoRotateBackSpeed = self.autoRotateBackSpeed
			
			for i,w in pairs( self.spec_wheels.wheels ) do 
				local attr = "rotSpeed"
				if w.rotSpeedLimit ~= nil then
					attr = "rotSpeedDefault"
				end 

				if w[attr] ~= nil then 
					if w.vcaRotSpeed == nil then 
						w.vcaRotSpeed = w[attr]
					end 				
					w[attr] = w.vcaRotSpeed * self.spec_vca.rotSpeedFactor
				end 
	
				attr = "rotSpeedNeg" 
				if w.rotSpeedLimit ~= nil then
					attr = "rotSpeedNegDefault" 
				end 
	
				if w[attr] ~= nil then 
					if w.vcaRotSpeedNeg == nil then 
						w.vcaRotSpeedNeg = w[attr] 
					end 				
					w[attr] = w.vcaRotSpeedNeg * self.spec_vca.rotSpeedFactor
				end 
			end 
			
			if noARB then 
				self.autoRotateBackSpeed = 0 
			end 
		--********************************************************************
		-- adaptive steering
		elseif self.spec_vca.steeringIsOn == vehicleControlAddon.steeringTrue or noARB then 
			if lastAxisSteer == nil then 
				self.spec_vca.lastAxisSteer       = self.spec_drivable.lastInputValues.axisSteer 
				self.spec_vca.lastAxisSteerAnalog = self.spec_drivable.lastInputValues.axisSteerIsAnalog 
				self.spec_vca.lastAxisSteerDevice = self.spec_drivable.lastInputValues.axisSteerDeviceCategory
				lastAxisSteerTime1          = nil 
				lastAxisSteerTime2          = nil 
			else  
				self.spec_vca.lastAxisSteer       = lastAxisSteer
			end 
			
			if self.spec_drivable.lastInputValues.axisSteer ~= 0 then 
				self.spec_vca.lastAxisSteerAnalog = self.spec_drivable.lastInputValues.axisSteerIsAnalog 
				self.spec_vca.lastAxisSteerDevice = self.spec_drivable.lastInputValues.axisSteerDeviceCategory
			end 
			
			if VCAGlobals.analogSteering then 
				self.spec_vca.lastAxisSteerAnalog = false 
			end 

			local s = math.abs( self.lastSpeed * 3600 )
			
			if noARB or ( not self.spec_vca.lastAxisSteerAnalog and math.abs( self.spec_drivable.lastInputValues.axisSteer ) > 0.01 ) then 
				local f = dt * 0.0005
				if self.spec_vca.lastAxisSteerAnalog then 
					f = dt * 0.002
				elseif s < 1 then 
					f = dt * 0.001
				elseif ( self.spec_vca.lastAxisSteer > 0 and self.spec_drivable.lastInputValues.axisSteer < 0 )
						or ( self.spec_vca.lastAxisSteer < 0 and self.spec_drivable.lastInputValues.axisSteer > 0 ) then 
					f = rsi * dt * 0.002 * math.min( 1, 0.25 + math.abs( self.spec_vca.lastAxisSteer ) * 2 )	
				elseif not noARB then 
					if lastAxisSteerTime1 == nil then 
						self.spec_vca.lastAxisSteerTime1 = g_currentMission.time
					else 
						self.spec_vca.lastAxisSteerTime1 = lastAxisSteerTime1
					end 
					local tMax = 3000
					if s >= 60 then 
						tMax = 200 
					elseif s >= 10 then 
						tMax = 200 + 88 * ( 85 - s )
					end 
					f = dt * 1e-6 * vehicleControlAddon.mbClamp( g_currentMission.time - self.spec_vca.lastAxisSteerTime1, 25, tMax )
					if s < 21 then 
						f = math.max( f, dt * 5e-5 * ( 21 - s ) )
					end 
				else 
					f = dt * 0.001 * math.min( 1, 0.25 + math.abs( self.spec_vca.lastAxisSteer ) * 2 ) 
				end 
				f = f * rso
				self.spec_vca.lastAxisSteer = vehicleControlAddon.mbClamp( self.spec_vca.lastAxisSteer + f * self.spec_drivable.lastInputValues.axisSteer, -1, 1 )
			elseif self.spec_vca.lastAxisSteerAnalog then 
				self.spec_vca.lastAxisSteer = self.spec_drivable.lastInputValues.axisSteer 
			elseif s > 1 then 
				local a = 1
				local f = 0.0006
				if self.autoRotateBackSpeed ~= nil then 
					a = self.autoRotateBackSpeed 
				end 
				if s <= 26 then 
					a = a * ( s - 1 ) * 0.04 
				end
				if s <= 11 then
					f = math.max( ( 11 - s  ) * 0.1, f ) 
				end 

				if lastAxisSteerTime2 == nil then 
					self.spec_vca.lastAxisSteerTime2 = g_currentMission.time 
					a = 0
				else 
					self.spec_vca.lastAxisSteerTime2 = lastAxisSteerTime2
					a = a * vehicleControlAddon.mbClamp( f * ( g_currentMission.time - lastAxisSteerTime2 - 50 ), 0, 1 ) ^1.5
				end 
													
				if self.spec_vca.lastAxisSteer > 0 then 
					self.spec_vca.lastAxisSteer = math.max( 0, self.spec_vca.lastAxisSteer - dt * 0.001 * a )
				elseif self.spec_vca.lastAxisSteer < 0 then                                        
					self.spec_vca.lastAxisSteer = math.min( 0, self.spec_vca.lastAxisSteer + dt * 0.001 * a )
				end 
			end 
			
			self.spec_drivable.lastInputValues.axisSteer = self.spec_vca.lastAxisSteer
			self.spec_drivable.lastInputValues.axisSteerIsAnalog = true 
			self.spec_drivable.lastInputValues.axisSteerDeviceCategory = InputDevice.CATEGORY.UNKNOWN
		end 
	end 
	--********************************************************************
	-- Reset of old, soft steering with reduced steering speed 
	if resetRotSpeed and self.spec_vca.rotSpeedFactor ~= nil then
		for i,w in pairs( self.spec_wheels.wheels ) do 
			local attr = "rotSpeed"
			if w.rotSpeedLimit ~= nil then
				attr = "rotSpeedDefault"
			end 

			if w[attr] ~= nil and w.vcaRotSpeed ~= nil then 			
				w[attr] = w.vcaRotSpeed
				w.vcaRotSpeed = nil 
			end 
			
			attr = "rotSpeedNeg" 
			if w.rotSpeedLimit ~= nil then
				attr = "rotSpeedNegDefault" 
			end 
			
			if w[attr] ~= nil and w.vcaRotSpeedNeg ~= nil then 
				w[attr] = w.vcaRotSpeedNeg
				w.vcaRotSpeedNeg = nil
			end 
		end 
		self.spec_vca.rotSpeedFactor = nil
		self.autoRotateBackSpeed = self.spec_vca.autoRotateBackSpeed 
		self.spec_vca.autoRotateBackSpeed = nil 
	end 
	--********************************************************************

--******************************************************************************************************************************************

	if self.isServer then 
		self:vcaSetState( "hasGearsAuto", vehicleControlAddon.vcaUIShowautoShift( self ))
		self:vcaSetState( "hasGearsIdle", vehicleControlAddon.vcaUIShowidleThrottle( self ))
	end 
--******************************************************************************************************************************************
end

function vehicleControlAddon:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.spec_vca == nil then return end

	self.spec_vca.tickDt = self.spec_vca.tickDt + 0.05 * ( dt - self.spec_vca.tickDt )

	local lastIsEntered = self.spec_vca.isEntered

	if self.isClient and self.getIsEntered ~= nil and self:getIsControlled() and self:getIsEntered() then 
		self.spec_vca.isEntered = true
		self:vcaSetState( "isEnteredMP", true )

		local isBlocked = false 
		if     self.spec_drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
		elseif self.spec_vca.ksIsOn then 
		elseif g_gui.currentListener ~= nil then 
			if     ChatDialog ~= nil and g_gui.currentListener == g_gui.screens[ChatDialog] then 
				isBlocked = false  
			else
				isBlocked = true 
			end 
		end 
		self:vcaSetState( "isBlocked", isBlocked )
	else 
		self.spec_vca.isEntered = false 
	end 	

	if self.spec_vca.isEntered and self.spec_vca.cruiseControlStateIsPressed then 
		if     self.spec_vca.cruiseControlStateTimer == nil then 
			self.spec_vca.cruiseControlStateTimer = Drivable.CRUISECONTROL_FULL_TOGGLE_TIME
		elseif self.spec_vca.cruiseControlStateTimer >= 0   then 
			self.spec_vca.cruiseControlStateTimer = self.spec_vca.cruiseControlStateTimer - dt 
		else 
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_FULL)
		end 
	elseif self.spec_vca.cruiseControlStateTimer ~= nil then 
		if     self.spec_vca.cruiseControlStateTimer <= 0 and self.spec_drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_FULL then 
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_FULL)
		elseif self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
		else
			self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
		end 
		self.spec_vca.cruiseControlStateTimer = nil
	end 	
	self.spec_vca.cruiseControlStateIsPressed = nil 

	if self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then 
		self.spec_vca.farmId = self:getActiveFarm()
	else 
		self.spec_vca.farmId = nil 
	end 
	
	if self.spec_vca.isEntered then
		self.spec_vca.keepCamRot     = self.spec_vca.keepRotPressed 
		self.spec_vca.keepRotPressed = false 
		
		local krToggle = self.spec_vca.kRToggleOut
		if self.spec_vca.camIsInside then 
			krToggle = self.spec_vca.kRToggleIn 
		end 
		if krToggle then 
			self.spec_vca.keepCamRot = not self.spec_vca.keepCamRot
		end
		
		self:vcaSetState( "inchingIsOn", self.spec_vca.inchingPressed )

		local isPressed = self.spec_vca.keepSpeedPressed
		if self.spec_vca.ksToggle then 
			isPressed = not isPressed
		end 
		if isPressed and not self.spec_vca.ksIsOn then 
			self:vcaSetState( "keepSpeed", self.lastSpeed * 3600 )
		end 
		self:vcaSetState( "ksIsOn", isPressed )

	elseif not self.spec_vca.isEnteredMP then 
		self.spec_vca.keepCamRot = false 
		self:vcaSetState( "inchingIsOn", false )
		self:vcaSetState( "ksIsOn", false )
		self:vcaSetState( "ksIsActive", false )
		self:vcaSetState( "keepSpeed", 0 )
	end 

	self.spec_vca.keepRotPressed   = false 
	self.spec_vca.inchingPressed   = false 
	self.spec_vca.keepSpeedPressed = false 	
	
	--*******************************************************************
	if not ( self.spec_vca.isEntered ) then 
		self.spec_vca.warningText  = ""
		self.spec_vca.warningTimer = 0
	elseif self.spec_vca.warningTimer ~= nil and self.spec_vca.warningTimer > 0  then 
		self.spec_vca.warningTimer = self.spec_vca.warningTimer - dt
	elseif self.spec_vca.warningText ~= nil  and self.spec_vca.warningText ~= "" then
		self.spec_vca.warningText = ""
	end 
	
	local newRotCursorKey = self.spec_vca.newRotCursorKey
	local i               = self.spec_enterable.camIndex
	local lastWorldRotation = self.spec_vca.camRotWorld
			
	self.spec_vca.newRotCursorKey = nil
	self.spec_vca.camRotWorld     = nil
	
	if self.spec_vca.inchingIsOn and self.spec_vca.isEntered and self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE then
		local limitThrottleRatio     = 0.75
		if self.spec_vca.limitThrottle < 11 then
			limitThrottleRatio     = 0.45 + 0.05 * self.spec_vca.limitThrottle
		else
			limitThrottleRatio     = 1.5 - 0.05 * self.spec_vca.limitThrottle
		end
		if self.spec_vca.speedLimit == nil then 
			self.spec_vca.speedLimit = self:getCruiseControlSpeed()
		end 
		self:vcaSetCruiseSpeed( self.spec_vca.speedLimit * limitThrottleRatio )
	elseif self.spec_vca.speedLimit ~= nil then 
		self:vcaSetCruiseSpeed( self.spec_vca.speedLimit )
		self.spec_vca.speedLimit = nil
	end 	
	-- overwrite or reset some values 
	--*******************************************************************
	
	-- reduce automatic brake force above 1 m/s^2
	if self.spec_motorized ~= nil and self.spec_motorized.motor ~= nil and self.spec_motorized.motor.lowBrakeForceScale ~= nil then
		if self:getIsVehicleControlledByPlayer() and 0.99 < self.spec_vca.brakeForce and self.spec_vca.brakeForce < 1.01 then      
			if self.spec_vca.origLowBrakeForceScale == nil then 
				self.spec_vca.origLowBrakeForceScale      = self.spec_motorized.motor.lowBrakeForceScale
				self.spec_vca.origLowBrakeForceSpeedLimit = self.spec_motorized.motor.lowBrakeForceSpeedLimit
			end 			
			self.spec_motorized.motor.lowBrakeForceScale = self.spec_vca.origLowBrakeForceScale * self.spec_vca.brakeForce
			if self.spec_vca.brakeForce < 1 then 
				self.spec_motorized.motor.lowBrakeForceSpeedLimit = math.min( 1, self.spec_vca.origLowBrakeForceSpeedLimit )
			end 
		elseif self.spec_vca.origLowBrakeForceScale ~= nil then 
			self.spec_motorized.motor.lowBrakeForceScale      = self.spec_vca.origLowBrakeForceScale
			self.spec_motorized.motor.lowBrakeForceSpeedLimit = self.spec_vca.origLowBrakeForceSpeedLimit
			self.spec_vca.origLowBrakeForceScale              = nil 
			self.spec_vca.origLowBrakeForceSpeedLimit         = nil 
		end 
	end 
	
	--*******************************************************************
	-- moving direction
	local moveDir = self.movingDirection
	
	if self:getIsActive() and self.isServer then
		if math.abs( self:getLastSpeed() ) < 5 then 
			if self.spec_motorized ~= nil and self.spec_motorized.motor ~= nil then 
				local motor = self.spec_motorized.motor
				if     motor.currentDirection < 0 then 
					self:vcaSetState( "isForward", false )
				elseif motor.currentDirection > 0 then 
					self:vcaSetState( "isForward", true )
				end 
			end 
		elseif moveDir < 0 then 
			self:vcaSetState( "isForward", false )
		elseif moveDir > 0 then 
			self:vcaSetState( "isForward", true )
		end 
	end

	--*******************************************************************
	-- Keep Speed 
	if self.spec_vca.isEntered then 
		local doKeepSpeed = false 
		local doTMS       = false 

		if self.spec_vca.ksIsOn then 
			doKeepSpeed = true 
		elseif  self.spec_vca.speedLimiter
				and self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF
				and self.spec_drivable.axisForward >= 0
				and self:vcaGetShuttleCtrl()
				and not ( self.spec_vca.maxGearSpeed ~= 0 and not self.spec_motorized.motor:getUseAutomaticGearShifting() )
				then 
			doTMS = true 
		end 
	
		local keepSpeedTMS = self.spec_vca.keepSpeedTMS
		self.spec_vca.keepSpeedTMS = nil 
		
		if doKeepSpeed or doTMS then	
			local m
			if self:vcaGetShuttleCtrl() then
				m = self.spec_motorized.motor.currentDirection
			elseif self.lastSpeedReal * 3600 < 0.5 then 
				m = 0
			elseif moveDir < 0 then 
				m = -1 
			else
				m = 1
			end
			
			local sl  = self:getSpeedLimit(true)
			local slf = -math.min( sl, self.spec_drivable.cruiseControl.maxSpeedReverse )
			local slt =  math.min( sl, self.spec_drivable.cruiseControl.maxSpeed )
			if self:vcaGetShuttleCtrl() then 
				if m < 0 then 
					slt = 0 
				else 
					slf = 0 
				end 
			end 
			
			if self.spec_vca.maxGearSpeed ~= 0 and not self.spec_motorized.motor:getUseAutomaticGearShifting() and math.abs( self.spec_vca.keepSpeed ) > 0.5 then 
				if m < 0 then 
					slf = math.max( slf,-3.6 * self.spec_vca.maxGearSpeed )
					slt = math.min( slt,-3.6 * self.spec_vca.minGearSpeed )
				else 
					slf = math.max( slf, 3.6 * self.spec_vca.minGearSpeed )
					slt = math.min( slt, 3.6 * self.spec_vca.maxGearSpeed )
				end 
			end 
			
			if     self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then 
				if m < 0 then 
					self.spec_vca.keepSpeedTemp = slf
				else
					self.spec_vca.keepSpeedTemp = slt
				end 
				self:setCruiseControlState( Drivable.CRUISECONTROL_STATE_OFF )		
			elseif self.spec_drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then 		
				if m < 0 then 
					self.spec_vca.keepSpeedTemp = vehicleControlAddon.mbClamp( -self.spec_drivable.cruiseControl.speed, slf, slt )
				else 
					self.spec_vca.keepSpeedTemp = vehicleControlAddon.mbClamp(  self.spec_drivable.cruiseControl.speed, slf, slt )
				end 
				self:setCruiseControlState( Drivable.CRUISECONTROL_STATE_OFF )		
			end 

			local k = self.spec_vca.keepSpeed
			
			if self:vcaGetShuttleCtrl() then 
				if m < 0 then 
					k = -math.abs( k )
				else 
					k = math.abs( k )
				end 
			end 
			
			local setKsIsActive = true 
			
			if     doTMS then 
				local t = vehicleControlAddon.mbClamp( math.abs( self.spec_drivable.axisForward ), 0, 1 ) * math.min( sl, self.spec_drivable.cruiseControl.speed )
				
				local limitThrottleRatio     = 0.75
				local limitThrottleIfPressed = true
				if self.spec_vca.limitThrottle < 11 then
					limitThrottleIfPressed = false
					limitThrottleRatio     = 0.45 + 0.05 * self.spec_vca.limitThrottle
				else
					limitThrottleIfPressed = true
					limitThrottleRatio     = 1.5 - 0.05 * self.spec_vca.limitThrottle
				end
					
				if self.spec_vca.inchingIsOn == limitThrottleIfPressed then
					t = t * limitThrottleRatio
				end
				
				if keepSpeedTMS == nil then 
					keepSpeedTMS = self.lastSpeedReal * 3600 * moveDir
				end 
				
				if     ( moveDir > 0 and m < 0 )
						or ( moveDir < 0 and m > 0 ) then 
					self.spec_vca.keepSpeedTMS = nil 
					t = 0 
				else 
					local s  = self.lastSpeedReal * 3600
					local k = 0
					if m < 0 then 
						k  = math.max( 0, -keepSpeedTMS )
					else
						k  = math.max( 0, keepSpeedTMS )
					end
					local kp = math.max( s, k + dt * 0.020 )
					local km = math.min( s, k - dt * 0.002 )
					if km > sl then 
						km = math.min( s, k - dt * 0.020 )
						kp = math.max( sl, km )
					elseif self.spec_motorized.motor.smoothedLoadPercentage > 0.8 and s > 5 then 
						local f = 5 * self.spec_motorized.motor.smoothedLoadPercentage - 4 
						kp = math.min( s + dt * 0.020 * ( 1 - f ), kp )
					else 
						kp = math.min( s + 2, kp )
					end 
					
					t = vehicleControlAddon.mbClamp( t, km, kp )
					self.spec_vca.keepSpeedTMS = m * t 
				end 
				
				if t < 0.5 then 
					setKsIsActive = false 
				end 
				self:vcaSetState( "keepSpeed", m * t )
			elseif math.abs( self.spec_drivable.axisForward ) > 0.01 then 
				self.spec_vca.keepSpeedTemp = nil 
			
				local s = self.lastSpeedReal * 3600 * moveDir					
				local f = slf
				local t = slt
				local a = self.spec_drivable.axisForward
				local l = self.spec_motorized.motor:getSmoothLoadPercentage()
				
				-- joystick
				if     self:vcaGetShuttleCtrl() then 
					if not self.spec_vca.isForward then 
						a = -a 
					end 
				-- w/o shuttle control
				elseif self.spec_drivable.reverserDirection ~= nil then 
					a = a * self.spec_drivable.reverserDirection
				end 
				if     m > 0 then 
					if a > 0.01 then 
						f = math.max( f, 0.5, s )
						a = a * vehicleControlAddon.mbClamp( 1 - l, 0.2, 1 )
						t = math.min( t, math.max( k, s + 1 ) )
					else
						f = 0 
						t = math.min( t, s )
					end 
					if t < f then 
						t = f 
					end 
					self.spec_vca.lastKSStopTimer = g_currentMission.time + 2000 
				elseif m < 0 then
					if a < -0.01 then 
						t = math.min( t, -0.5, s )
						a = a * vehicleControlAddon.mbClamp( 1 - l, 0.2, 1 )
						f = math.max( f, math.min( k, s - 1 ) )
					else 
						t = 0 
						f = math.max( f, s )
					end 
					if f > t then 
						f = t 
					end 
					self.spec_vca.lastKSStopTimer = g_currentMission.time + 2000 
				elseif self.spec_vca.lastKSStopTimer == nil then 
					self.spec_vca.lastKSStopTimer = g_currentMission.time 
				elseif g_currentMission.time < self.spec_vca.lastKSStopTimer then 
					-- wait two seconds 
					f = 0
					t = 0
				end 
				
				if f < -sl then 
					f = -sl 
				end 
				if t > sl then	
					t = sl 
				end 
				
				self:vcaSetState( "keepSpeed", vehicleControlAddon.mbClamp( k + a * 0.01 * dt, f, t )  )
				self.spec_drivable.axisForward = 0
				
			else
				if self.spec_vca.keepSpeedTemp ~= nil then 		
					if not self:vcaGetShuttleCtrl() then 
						self.spec_vca.keepSpeedTemp = vehicleControlAddon.mbClamp( self.spec_vca.keepSpeedTemp, slf, slt )
					elseif m < 0 then 	
						self.spec_vca.keepSpeedTemp = vehicleControlAddon.mbClamp( -math.abs( self.spec_vca.keepSpeedTemp ), slf, slt )
					else 
						self.spec_vca.keepSpeedTemp = vehicleControlAddon.mbClamp( math.abs( self.spec_vca.keepSpeedTemp ), slf, slt )
					end 
					if math.abs( k - self.spec_vca.keepSpeedTemp ) < 0.1 then 
						k = self.spec_vca.keepSpeedTemp
						self.spec_vca.keepSpeedTemp = nil 
					else 
						local l = self.spec_motorized.motor:getSmoothLoadPercentage()
						local a = vehicleControlAddon.mbClamp( 1 - l, 0.2, 1 )
						k = k + vehicleControlAddon.mbClamp( self.spec_vca.keepSpeedTemp - k, -a * 0.01 * dt, a * 0.01 * dt )
					end 
				end 
				
				self:vcaSetState( "keepSpeed", vehicleControlAddon.mbClamp( k, slf, slt ) )
			end 
			self:vcaSetState( "ksIsActive", setKsIsActive )
		else 
			self.spec_vca.keepSpeedTemp = nil 
			self:vcaSetState( "ksIsActive", false )
		end 
	end 
	
	--*******************************************************************
	-- Camera Rotation
	if      self:getIsActive() 
			and self.isClient 
			and self.spec_vca ~= nil 
			and self:vcaIsVehicleControlledByPlayer()
			and self:vcaIsValidCam() then
			
		local camera  = self.spec_enterable.cameras[i]
		local rotIsOn = self.spec_vca.camRotOutside
		local revIsOn = self.spec_vca.camRevOutside 
		self.spec_vca.camIsInside   = false
		
		if camera.isInside then 
			self.spec_vca.camIsInside = true 

			if      g_gameSettings:getValue("isHeadTrackingEnabled") 
					and isHeadTrackingAvailable() 
					and camera.headTrackingNode ~= nil
					and not VCAGlobals.rotateHeadTracking then 
				rotIsOn = 0 
				revIsOn = false 
			else 
				rotIsOn = self.spec_vca.camRotInside
				revIsOn = self.spec_vca.camRevInside
			end 
		end 
		
		if self.spec_crabSteering ~= nil and rotIsOn > 0 then  
			local spec = self.spec_crabSteering
			if not ( spec.steeringModes == nil or spec.state == nil or spec.steeringModes[spec.state] == nil ) then 
				entry = spec.steeringModes[spec.state]
				local mode = 0
				if     entry.inputAction == nil then 
				-- do nothing  
				elseif entry.inputAction == "CRABSTEERING_ALLWHEEL" then 
					mode = 2
				elseif entry.inputAction == "CRABSTEERING_CRABLEFT"
						or entry.inputAction == "CRABSTEERING_CRABRIGHT" then 
					mode = 3
				end 
				if mode <= 0 then 
					if     entry.name == g_i18n:getText( "action_steeringModeAllWheel"   ) then 
						mode = 2
					elseif entry.name == g_i18n:getText( "action_steeringModeFrontWheel" ) then 
						mode = 1
					elseif entry.name == g_i18n:getText( "action_steeringModeCrabLeft"   ) then 
						mode = 3
					elseif entry.name == g_i18n:getText( "action_steeringModeCrabRight"  ) then 
						mode = 3
					end 
				end 
				if     mode == 2 then 
					rotIsOn = rotIsOn * 1.25 
				elseif mode == 3 then 
					rotIsOn = rotIsOn * 0.8 
				end 
			end 
		end 
		
	--vcaDebugPrint( "Cam: "..tostring(rotIsOn)..", "..tostring(revIsOn)..", "..tostring(self.spec_vca.lastCamIndex)..", "..tostring(self.spec_vca.lastCamFwd))

		if     self.spec_vca.lastCamIndex == nil 
				or self.spec_vca.lastCamIndex ~= i then
				
			if      self.spec_vca.lastCamIndex ~= nil
					and self.spec_vca.zeroCamRotY  ~= nil
					and self.spec_vca.lastCamRotY  ~= nil
					and self:vcaIsValidCam( self.spec_vca.lastCamIndex ) then
				local oldCam = self.spec_enterable.cameras[self.spec_vca.lastCamIndex]
				
				if (oldCam.resetCameraOnVehicleSwitch == nil and g_gameSettings:getValue("resetCamera")) or oldCam.resetCameraOnVehicleSwitch then
				-- camera is automatically reset
				elseif ( not oldCam.isInside and self.spec_vca.camRotOutside > 0 )
						or (     oldCam.isInside and self.spec_vca.camRotInside  > 0 ) then 
					oldCam.rotY = vehicleControlAddon.normalizeAngleCam( self.spec_vca.zeroCamRotY + oldCam.rotY - self.spec_vca.lastCamRotY )
				end 
			end 
				
			self.spec_vca.lastCamIndex = self.spec_enterable.camIndex
			self.spec_vca.zeroCamRotY  = camera.rotY
			self.spec_vca.lastCamRotY  = camera.rotY 
			self.spec_vca.lastCamFwd   = nil
			self.spec_vca.camRotWorld  = nil
			
			if self.spec_vca.camIsInside then 
				self.spec_vca.keepCamRot = self.spec_vca.kRToggleIn 
			else 
				self.spec_vca.keepCamRot = self.spec_vca.kRToggleOut 
			end 
						
		elseif rotIsOn > 0
				or revIsOn
				or self.spec_vca.keepCamRot
				or lastWorldRotation ~= nil
				or newRotCursorKey   ~= nil then 

			local pi2 = math.pi / 2
			local eps = 1e-6
			oldRotY = camera.rotY
			local diff = oldRotY - self.spec_vca.lastCamRotY
			
			if     self.spec_vca.keepCamRot then 
				self.spec_vca.camRotWorld = vehicleControlAddon.vcaGetRelativeYRotation(g_currentMission.terrainRootNode,self:vcaGetSteeringNode())
			elseif lastWorldRotation ~= nil then 
			-- reset to old rotation 	
			elseif newRotCursorKey ~= nil then
				self.spec_vca.zeroCamRotY = camera.origRotY + newRotCursorKey
			elseif rotIsOn > 0 then
				self.spec_vca.zeroCamRotY = self.spec_vca.zeroCamRotY + diff
			else
				self.spec_vca.zeroCamRotY = camera.rotY
			end
				
		--diff = math.abs( vehicleControlAddon.vcaGetAbsolutRotY( self, i ) )
			local isRev = false
			local aRotY = vehicleControlAddon.normalizeAngle( vehicleControlAddon.vcaGetAbsolutRotY( self, i ) - camera.rotY + self.spec_vca.zeroCamRotY )
			if -pi2 < aRotY and aRotY < pi2 then
				isRev = true
			end
			
			if revIsOn and not ( self.spec_vca.keepCamRot ) then
				if     newRotCursorKey ~= nil then
				-- nothing
				elseif self.spec_vca.lastCamFwd == nil or self.spec_vca.lastCamFwd ~= self.spec_vca.isForward then
					if isRev == self.spec_vca.isForward then
						if math.abs( self.spec_vca.zeroCamRotY - math.pi ) < 0.1 then 
							self.spec_vca.zeroCamRotY = 0
						elseif self.spec_vca.zeroCamRotY > math.pi+math.pi - 0.1 then 
							self.spec_vca.zeroCamRotY = math.pi
						elseif self.spec_vca.zeroCamRotY < 0.1 then 
							self.spec_vca.zeroCamRotY = math.pi
						elseif self.spec_vca.zeroCamRotY >= math.pi then 
							self.spec_vca.zeroCamRotY = self.spec_vca.zeroCamRotY - math.pi 
						else 
							self.spec_vca.zeroCamRotY = self.spec_vca.zeroCamRotY + math.pi 
						end 
						isRev = not isRev						
					end
				end
				self.spec_vca.lastCamFwd = self.spec_vca.isForward
			end
			
			local newRotY = self.spec_vca.zeroCamRotY
			
			if self.spec_vca.keepCamRot then 
				if newRotCursorKey ~= nil then
					newRotY = camera.origRotY + newRotCursorKey 
				else 
					newRotY = camera.rotY 
				end 
				if lastWorldRotation ~= nil then 
					newRotY = newRotY + ( self.spec_vca.camRotWorld - lastWorldRotation )
				end 
			elseif rotIsOn > 0 then
				
				local f = 0
				if     self.rotatedTime > 0 then
					f = self.rotatedTime / self.maxRotTime
				elseif self.rotatedTime < 0 then
					f = self.rotatedTime / self.minRotTime
				end
				if f < 0.1 then
					f = 0
				else
					f = 1.2345679 * ( f - 0.1 ) ^2 / 0.81
				--f = 1.1111111 * ( f - 0.1 )
				end
				f = f * 0.5 * rotIsOn
				if self.rotatedTime < 0 then
					f = -f
				end
				
				local g = self.spec_vca.lastFactor
				self.spec_vca.lastFactor = self.spec_vca.lastFactor + vehicleControlAddon.mbClamp( f - self.spec_vca.lastFactor, -VCAGlobals.cameraRotTime*dt, VCAGlobals.cameraRotTime*dt )
				if math.abs( self.spec_vca.lastFactor - g ) > 0.01 then
					f = self.spec_vca.lastFactor
				else
					f = g
				end
				
				if isRev then
					newRotY = newRotY - VCAGlobals.cameraRotFactorRev * f				
				else
					newRotY = newRotY + VCAGlobals.cameraRotFactor * f
				end	
				
			else
				self.spec_vca.lastFactor = 0
			end
			
			local spec_cabView = nil 
			if self["spec_FS22_CabView.cabView"] ~= nil then 
				spec_cabView = self["spec_FS22_CabView.cabView"]
			elseif self.spec_cabView ~= nil then 
				spec_cabView = self.spec_cabView 
			end 
			
			if not ( type( spec_cabView ) == "table" and camera.isInside ) then  
				camera.rotY = vehicleControlAddon.normalizeAngleCam( newRotY )	
			elseif spec_cabView.rotationOffset == nil then 
				camera.rotY = math.max( 0, math.min( newRotY, math.pi+math.pi ))
			else 
				local minRot = -0.1 * math.pi+spec_cabView.rotationOffset
				local maxRot =  2.1 * math.pi+spec_cabView.rotationOffset
				camera.rotY = math.max( minRot, math.min( newRotY, maxRot ))
			end 
		end
		
		self.spec_vca.lastCamRotY = camera.rotY
	elseif self.spec_vca.lastCamIndex ~= nil then 
		if self.spec_vca.zeroCamRotY and self:vcaIsValidCam( self.spec_vca.lastCamIndex ) then
			self.spec_enterable.cameras[self.spec_vca.lastCamIndex].rotY = self.spec_vca.zeroCamRotY 
		end 
		self.spec_vca.lastCamIndex = nil
		self.spec_vca.zeroCamRotY  = nil
		self.spec_vca.lastCamRotY  = nil
		self.spec_vca.lastCamFwd   = nil
		self.spec_vca.camIsInside  = nil
		self.spec_vca.keepCamRot   = false  
	end	

--******************************************************************************************************************************************
	if self.isServer and self:getIsActive() and self.spec_vca ~= nil and self.spec_vca.isInitialized then  
		if      self.spec_vca.diffManual 
				and not self.spec_vca.diffHasF
				and not self.spec_vca.diffHasM
				and not self.spec_vca.diffHasB then 
			self:vcaSetState( "diffManual", false )
		end 
	
		local spec = self.spec_motorized 
		local gearRatio = 0
		if spec.motor ~= nil and spec.motor.gearRatio ~= nil then 
			gearRatio = spec.motor.gearRatio
		end 
		
		if      VCAGlobals.turnOffAWDSpeed > 0
				and self.lastSpeed * 3600 > VCAGlobals.turnOffAWDSpeed
				and self:vcaIsVehicleControlledByPlayer() then 
			self:vcaSetState( "diffLockFront", false )
			self:vcaSetState( "diffLockBack",  false )
			if self.spec_vca.diffFrontAdv then  
				self:vcaSetState( "diffLockAWD", false )
			end 
		end 

		local f, m, b = self:vcaGetDiffState()
		
		local updateDiffs  = false 
		local vehicleSpeed = self.lastSpeedReal*1000*moveDir
		local avgWheelSpeed,n=0,0
		local minWheelSpeed, maxWheelSpeed
		
		self.spec_vca.debugS = debugFormat("%6.3f",vehicleSpeed)
		
		local function updateWheelSpeed( wheel )
			local s = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape) * wheel.radius 
			wheel.vcaNoPower = false 
			if wheel.vcaSpeed == nil then 
				wheel.vcaSpeed = s 
			else 
				wheel.vcaSpeed = wheel.vcaSpeed + 0.08 * ( s - wheel.vcaSpeed )
			end 
			self.spec_vca.debugS = self.spec_vca.debugS..debugFormat(", %6.3f",wheel.vcaSpeed)
			avgWheelSpeed = avgWheelSpeed + wheel.vcaSpeed
			n = n + 1 
			if minWheelSpeed == nil or minWheelSpeed > wheel.vcaSpeed then 
				minWheelSpeed = wheel.vcaSpeed 
			end 
			if maxWheelSpeed == nil or maxWheelSpeed < wheel.vcaSpeed then 
				maxWheelSpeed = wheel.vcaSpeed 
			end 
		end 
		
		for d,diff in pairs(spec.differentials) do 
			diff.vcaEnabled = 3 
			if diff.diffIndex1IsWheel then
				local wheel = self:getWheelFromWheelIndex( diff.diffIndex1 )
				updateWheelSpeed( wheel )
			end
			if diff.diffIndex2IsWheel then
				local wheel = self:getWheelFromWheelIndex( diff.diffIndex2 )
				updateWheelSpeed( wheel )
			end 
		end 					
			
		if n > 1 then avgWheelSpeed = avgWheelSpeed / n end 	
			
		if minWheelSpeed ~= nil and avgWheelSpeed ~= nil and maxWheelSpeed ~= nil then 
			self.spec_vca.debugS = self.spec_vca.debugS..debugFormat("\n%6.3f .. %6.3f .. %6.3f",minWheelSpeed, avgWheelSpeed, maxWheelSpeed)
		end 
		
		local ws = 0
		if     math.abs( vehicleSpeed ) < 0.1 then 
		elseif gearRatio > 0 and vehicleSpeed >  0.1 and maxWheelSpeed ~= nil and maxWheelSpeed > vehicleSpeed then 
			ws = maxWheelSpeed / vehicleSpeed - 1
		elseif gearRatio < 0 and vehicleSpeed < -0.1 and minWheelSpeed ~= nil and minWheelSpeed < vehicleSpeed then 
			ws = minWheelSpeed / vehicleSpeed - 1
		end 
		self.spec_vca.maxWheelSlip = self.spec_vca.maxWheelSlip + 0.04 * ( ws - self.spec_vca.maxWheelSlip )
		
		if minWheelSpeed == nil or minWheelSpeed < 1 then 
			minWheelSpeed = 1 
		end 
		if maxWheelSpeed == nil or maxWheelSpeed > -1 then 
			maxWheelSpeed = -1 
		end 

    local function getDiffSpeed(index)
			local speed1, speed2, diffOfWheels
			local diff = spec.differentials[index]
			if diff.diffIndex1IsWheel then
				local wheel = self:getWheelFromWheelIndex( diff.diffIndex1 )
				speed1 = wheel.vcaSpeed
				diffOfWheels = true  
			else
				local s1,s2 = getDiffSpeed(diff.diffIndex1+1);
				speed1 = (s1+s2)/2
				diffOfWheels = false  
			end
			if diff.diffIndex2IsWheel then
				local wheel = self:getWheelFromWheelIndex( diff.diffIndex2 )
				speed2 = wheel.vcaSpeed
			else
				local s1,s2 = getDiffSpeed(diff.diffIndex2+1);
				speed2 = (s1+s2)/2
				diffOfWheels = false 
			end
			return speed1,speed2,diffOfWheels
    end
		
		local function disableDiff( index, isWheel )
			if isWheel then
				local wheel = self:getWheelFromWheelIndex( index )
				wheel.vcaNoPower = true 
			else 
			--vcaDebugPrint( "Disabling diff(3) "..tostring(index) )
				local diff = spec.differentials[index+1]
				diff.vcaEnabled = 0
				disableDiff( diff.diffIndex1, diff.diffIndex1IsWheel ) 
				disableDiff( diff.diffIndex2, diff.diffIndex2IsWheel ) 
			end 
		end 

    local function getClosedTorqueRatio(r0, s1, s2, m0)
			local r = r0 
			local m = Utils.getNoNil( m0, vehicleControlAddon.speedRatioClosed1 )
			
			if gearRatio < 0 then 
				s1 = -s1
				s2 = -s2 
			end 
				
			if     s1 < 0.1389 and s2 < 0.1389 then 
			elseif not ( -0.2778 < s1 and s1 < 90 
			         and -0.2778 < s2 and s2 < 90 ) then 
				m = math.max( m, vehicleControlAddon.speedRatioClosed1 )
			elseif s1 < s2 then  
				q = ( math.max( s1, 0 ) / s2 ) 
				r =  1 - q * ( 1 - r )
				m = math.max( m, 1 + ( vehicleControlAddon.speedRatioClosed1 - 1 ) * ( 1 - q ) )
			elseif s2 < s1 then 
				q = ( math.max( s2, 0 ) / s1 ) 
				r = r * q
				m = math.max( m, 1 + ( vehicleControlAddon.speedRatioClosed1 - 1 ) * ( 1 - q ) )
			end 
			
			if math.abs( r - r0 ) < 0.05 then 
				r = r0 
			end 
							
			return r, m
		end
		
		local function setDiff( index, newState, torqueRatioOpen, advanceSpeed )
		
			-- torqueRatio = 1 => all power goes to 1st part 
			-- torqueRatio = 0 => all power goes to 2nd part 
		
			if index <= 0 then 
				return 0
			end 
			
			local diff  = spec.differentials[index]		
			
			if newState == nil or diff.vcaEnabled <= 0 then 
				newState = 0 
			end 
			
			local r, m   = diff.vcaTorqueRatio, diff.vcaMaxSpeedRatio
			local r1, r2 = vehicleControlAddon.minTorqueRatio, 1-vehicleControlAddon.minTorqueRatio
			
			if     newState == 1 then 
				if torqueRatioOpen ~= nil then 
					r = torqueRatioOpen
				end 

				if r1 <= r and r <= r2 then   
					local s1,s2 = getDiffSpeed(index)
					if self.spec_vca.antiSlip then 
						r = vehicleControlAddon.mbClamp( getClosedTorqueRatio( r, s1, s2 ), r1, r2 )	
					elseif vehicleControlAddon.distributeTorqueOpen then
						-- inverse torque ratio => put more torque on turning wheel
						r = vehicleControlAddon.mbClamp( getClosedTorqueRatio( r, s2, s1 ), r1, r2 )
          end 						
				end 				
				m = vehicleControlAddon.speedRatioOpen
			elseif newState == 2 then 			

				local s1,s2,dow = getDiffSpeed(index)
				
				if dow then 
					m = vehicleControlAddon.speedRatioClosed1
				elseif vehicleControlAddon.speedRatioClosed0 >= 0 then 
					m = vehicleControlAddon.speedRatioClosed0 
				end 
					
				-- advance speed by 7% (minus 2% error)
				if     torqueRatioOpen == nil or not self.spec_vca.diffFrontAdv then  
				elseif torqueRatioOpen > r2 then 
					m  = math.max( m, vehicleControlAddon.speedRatioClosed2 )
					s1 = s1 * 1.035
					s2 = s1 / 1.035
				elseif torqueRatioOpen < r1 then 
					m  = math.max( m, vehicleControlAddon.speedRatioClosed2 )
					s1 = s1 / 1.035
					s2 = s2 * 1.035
				end 
				
				r, m = getClosedTorqueRatio( r, s1, s2, m )
				r = vehicleControlAddon.mbClamp( r, r1, r2 )
			end 
			
			local ovr = "vcaOvrDT"..tostring(index) 
			if self[ovr] ~= nil and self[ovr] >= 0 then 
				r = self[ovr]
			end 
			local ovr = "vcaOvrDM"..tostring(index) 
			if self[ovr] ~= nil and self[ovr] >= 0 then 
				m = self[ovr] 
			end 
			
			if newState > 0 then 
				if     r > r2 then 
					if diff.diffIndex2IsWheel then
						r = r2
					else 
						r = 1
						diff.vcaEnabled = 1  						
						disableDiff( diff.diffIndex2, diff.diffIndex2IsWheel ) 
					end 
				elseif r < r1 then 
					if diff.diffIndex1IsWheel then                              
						r = r1
					else 
						r = 0
						diff.vcaEnabled = 2                            
						disableDiff( diff.diffIndex1, diff.diffIndex1IsWheel )
					end 			
				end 
				if m < 1 then 
					m = 1 
				end 
			end 			
			
			local eOld = ( r1 <= diff.torqueRatio and diff.torqueRatio <= r2 ) 
			local eNew = ( r1 <= r and r <= r2 )
			
			if     eOld ~= eNew then 
				diff.torqueRatio    = r 
				diff.maxSpeedRatio  = m
				updateDiffs        = true 
			elseif math.abs( diff.torqueRatio - r ) > 1e-3 or math.abs( diff.maxSpeedRatio - m ) > 1e-3 then 
				diff.torqueRatio   = r 
				diff.maxSpeedRatio = m
				if diff.vcaIndex ~= nil and diff.vcaIndex >= 0 then 
					updateDifferential( spec.motorizedNode, diff.vcaIndex, diff.torqueRatio, diff.maxSpeedRatio )
				end 
			end 
					
			return newState 
		end 
		
		local vanilla = false 
		if f <= 0 and m <= 0 and b <= 0 then 
			if self.spec_vca.diffHasF or self.spec_vca.diffHasM or self.spec_vca.diffHasB then
				for i=#spec.differentials,1,-1 do 
					setDiff( i, 0 )
				end 
			end 
		else 
			for i=#spec.differentials,1,-1 do 
				local diff = spec.differentials[i] 
				if     diff.vcaMode == 'M' then 
					local o = diff.vcaTorqueRatioOpen 
					if o ~= nil and self.spec_vca.diffLockSwap then 
						o = 1 - o 
					end 
					setDiff( i, m, o ) 
				elseif diff.vcaMode == 'B' then 
					setDiff( i, b ) 
				elseif diff.vcaMode == 'F' then 
					setDiff( i, f ) 
				else 
					setDiff( i, 0 )
				end 
			end 
		end 
				
		if updateDiffs then 		
			--re-create all diffs
			removeAllDifferentials( spec.motorizedNode ) 

			local diffMap = {}			
			local j = 0
			for i, differential in pairs(spec.differentials) do
				if     differential.vcaEnabled == 1 then 	
					if not differential.diffIndex1IsWheel then
						diffMap[i-1] = diffMap[differential.diffIndex1]
					else
						print("Error: VCA differential "..tostring(i-1).." is partly disabled ("..tostring(differential.vcaEnabled)..") but contains wheels")
					end 
				elseif differential.vcaEnabled == 2 then 
					if not differential.diffIndex2IsWheel then
						diffMap[i-1] = diffMap[differential.diffIndex2]
					else
						print("Error: VCA differential "..tostring(i-1).." is partly disabled ("..tostring(differential.vcaEnabled)..") but contains wheels")
					end 
				elseif differential.vcaEnabled == 3 then 
					diffMap[i-1] = j
					j = j + 1
				end 
			end 
			
			j = 0
			for i, differential in pairs(spec.differentials) do
				vcaDebugPrint("Diff "..tostring(i-1).." s: "..tostring(differential.vcaEnabled)
										..", v: "..tostring(differential.vcaMode)
										..", t: "..tostring(differential.torqueRatio)
										..", m: "..tostring(differential.maxSpeedRatio))
				if differential.vcaEnabled == 3 then 
					local diffIndex1 = differential.diffIndex1
					local diffIndex2 = differential.diffIndex2
					if differential.diffIndex1IsWheel then
						local wheel = self:getWheelFromWheelIndex(diffIndex1)
						diffIndex1 = wheel.wheelShape
					else 
						vcaDebugPrint("1: New index of "..tostring(diffIndex1).." is "..tostring(diffMap[diffIndex1]))
						diffIndex1 = diffMap[diffIndex1]
					end
					if differential.diffIndex2IsWheel then
						local wheel = self:getWheelFromWheelIndex(diffIndex2)
						diffIndex2 = wheel.wheelShape
					else 
						vcaDebugPrint("2: New index of "..tostring(diffIndex2).." is "..tostring(diffMap[diffIndex2]))
						diffIndex2 = diffMap[diffIndex2]
					end
					if diffIndex1 == nil or diffIndex2 == nil then 
						print("Error: VCA calculation of differential "..tostring(i-1)
																				.." failed: "..tostring(diffIndex1)
																							.. ", "..tostring(differential.diffIndex1)
																							.. ", "..tostring(differential.diffIndex1IsWheel)
																							.. ", "..tostring(diffIndex2)
																							.. ", "..tostring(differential.diffIndex2)
																							.. ", "..tostring(differential.diffIndex2IsWheel))
					else 
						differential.vcaIndex = j
						j = j + 1 
						addDifferential( spec.motorizedNode,
														 diffIndex1,
														 differential.diffIndex1IsWheel,
														 diffIndex2,
														 differential.diffIndex2IsWheel,
														 differential.torqueRatio,
														 differential.maxSpeedRatio )
					end 
				else 
					differential.vcaIndex = -1
				end 
			end
			self:updateMotorProperties()
		end 
		
		self.spec_vca.debugD = nil
		if VCAGlobals.debugPrint then 
			for i, differential in pairs(spec.differentials) do
				if self.spec_vca.debugD == nil then 
					self.spec_vca.debugD = ""
				else 
					self.spec_vca.debugD = self.spec_vca.debugD .. string.format("\n")
				end 

				local s1,s2 = getDiffSpeed(i)
				
				self.spec_vca.debugD = self.spec_vca.debugD .. string.format( "%d: (%d, %d, %s), speed: %6.3f, %6.3f => tr: %6.3f sr: %6.1f",
																													i, 
																													Utils.getNoNil( differential.vcaEnabled, -1 ),
																													Utils.getNoNil( differential.vcaIndex, -1 ),
																													Utils.getNoNil( differential.vcaMode, '?' ),
																													s1, s2,
																													differential.torqueRatio,
																													differential.maxSpeedRatio )
			end 
		end 
	end 
	
--******************************************************************************************************************************************
-- path recording 
	if not self.spec_vca.isEntered or self.spec_vca.snapIsOn then 
		self:vcaSetState( "pathRecording", false ) 
		self.spec_vca.prevPathRecording = nil 
	end 
	
	if self.spec_vca.pathRecording then 
		local wx,_,wz = getWorldTranslation( self:vcaGetSteeringNode() )
		if self.spec_vca.currentPath == nil or not ( self.spec_vca.prevPathRecording ) then 
			local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )			
			self.spec_vca.currentPath = {} 
			self.spec_vca.lastPathX = wx 
			self.spec_vca.lastPathZ = wz 
			self.spec_vca.lastPathA = math.atan2(lx,lz) 
		else 
			local dx = wx - self.spec_vca.lastPathX
			local dz = wz - self.spec_vca.lastPathZ
			local l2 = dx*dx + dz*dz
			if l2 >= 0.25 then 
				local a = math.atan2( dx, dz )
				local deltaA = math.abs( vehicleControlAddon.normalizeAngle( a - self.spec_vca.lastPathA ) )
				if l2 >= 25 or deltaA > 0.1309 then -- 90° divided by 12
					table.insert( self.spec_vca.currentPath, { self.spec_vca.lastPathX, self.spec_vca.lastPathZ, a, math.sqrt( l2 ) })
					self.spec_vca.lastPathX = wx 
					self.spec_vca.lastPathZ = wz 
					self.spec_vca.lastPathA = a 
				end
			end 
		end 
		self.spec_vca.prevPathRecording = true 
	elseif self.spec_vca.prevPathRecording and type( self.spec_vca.currentPath ) == "table" then 
		self.spec_vca.prevPathRecording = nil 
		local wx,_,wz = getWorldTranslation( self:vcaGetSteeringNode() )
		local dx = wx - self.spec_vca.lastPathX
		local dz = wz - self.spec_vca.lastPathZ
		local l2 = dx*dx + dz*dz
		if l2 >= 0.25 then 
			local a = math.atan2( dx, dz )
			table.insert( self.spec_vca.currentPath, { self.spec_vca.lastPathX, self.spec_vca.lastPathZ, a, math.sqrt( l2 ) })
		end
	end 

--******************************************************************************************************************************************
-- ProSeed 

	if self.spec_vca.snapPossible and not self.spec_vca.gpsProSeed then  
		self.spec_vca.gpsProSeed  = true 
		if self.getHasGuidanceSystem == nil then 
			self.getHasGuidanceSystem = vehicleControlAddon.vcaGetHasGuidanceSystem
		else 
			self.getHasGuidanceSystem = Utils.overwrittenFunction( self.getHasGuidanceSystem, vehicleControlAddon.vcaGetHasGuidanceSystem )
		end 
		if self.getGuidanceData == nil then 
			self.getGuidanceData = vehicleControlAddon.vcaGetGuidanceData
		else 
			self.getGuidanceData = Utils.overwrittenFunction( self.getGuidanceData,      vehicleControlAddon.vcaGetGuidanceData )
		end 
	end 	
	
--******************************************************************************************************************************************
-- time to shift 
	if     self.spec_motorized.motor.gearChangeTimeOrig == nil then 
		self.spec_vca.lastGearShiftTime = vehicleControlAddon.shiftTimeDefault

	elseif self.spec_vca.lastGearShiftTime ~= self.spec_vca.gearShiftTime then 
		self.spec_vca.lastGearShiftTime = self.spec_vca.gearShiftTime
		
		if self.spec_vca.origGearShiftTime == nil then 
			self.spec_vca.origGearShiftTime = self.spec_motorized.motor.gearChangeTimeOrig
		end
		
		local gearShiftTime = self.spec_vca.origGearShiftTime
		if self.spec_vca.gearShiftTime ~= vehicleControlAddon.shiftTimeDefault then 
			gearShiftTime = vehicleControlAddon.shiftTimes[self.spec_vca.gearShiftTime]
		end
		if gearShiftTime ~= nil then 
			self.spec_motorized.motor:setGearChangeTime( gearShiftTime )
		end 
	end 
			 
	if     self.spec_motorized.motor.groupType       == nil 
			or self.spec_motorized.motor.groupChangeTime == nil then 
		self.spec_vca.lastGrpShiftTime = vehicleControlAddon.shiftTimeDefault
		
	elseif self.spec_vca.lastGrpShiftTime ~= self.spec_vca.grpShiftTime then 
		self.spec_vca.lastGrpShiftTime = self.spec_vca.grpShiftTime
		
		if self.spec_vca.origGrpShiftTime == nil then 
			self.spec_vca.origGroupType    = self.spec_motorized.motor.groupType
			self.spec_vca.origGrpShiftTime = self.spec_motorized.motor.groupChangeTime
		end
		
		local groupType       = self.spec_vca.origGroupType
		local groupChangeTime = self.spec_vca.origGrpShiftTime
		if self.spec_vca.grpShiftTime ~= vehicleControlAddon.shiftTimeDefault then 
			groupChangeTime = vehicleControlAddon.shiftTimes[self.spec_vca.grpShiftTime]
			if groupChangeTime > 0 then 
				groupType = VehicleMotor.TRANSMISSION_TYPE.DEFAULT
			else 
				groupType = VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
			end 
		end
		if groupType ~= nil then 
			self.spec_motorized.motor.groupType = groupType
		end 
		if groupChangeTime ~= nil then 
			self.spec_motorized.motor.groupChangeTime = groupChangeTime
		end 
	end 

end  

function vehicleControlAddon:onUpdateTick( dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected )
	if self.isClient and isActiveForInputIgnoreSelection then
		vehicleControlAddon.updateActionEvents( self )
	end 
end 

function vehicleControlAddon:onPostUpdate( dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected ) 
	if self.isServer then 
		local minGearSpeed, maxGearSpeed = 0, 0
		if       self:getIsVehicleControlledByPlayer()
				and self.spec_motorized                     ~= nil 
				and self.spec_motorized.motor               ~= nil 	
				and self.spec_motorized.motorizedNode       ~= nil
				and next(self.spec_motorized.differentials) ~= nil
				and self:getIsMotorStarted()
				then 
			local motor = self.spec_motorized.motor 
			if (motor.backwardGears or motor.forwardGears) and motor.minGearRatio ~= 0 then
				local factor = math.pi / ( math.abs( motor.minGearRatio ) * 30 ) 
				minGearSpeed = motor.minRpm * factor
				maxGearSpeed = motor.maxRpm * factor
			end 
		end 
		self:vcaSetState( "minGearSpeed", minGearSpeed )
		self:vcaSetState( "maxGearSpeed", maxGearSpeed )
	end 
end 

function vehicleControlAddon:onDraw()

	if self.spec_vca.isEntered then

		if self.spec_vca.warningText ~= nil and self.spec_vca.warningText ~= "" then
			g_currentMission:addExtraPrintText( self.spec_vca.warningText )
		end		

		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.speedIndicatorRadiusY * 1.6
		local l = g_currentMission.inGameMenu.hud.speedMeter.gearTextSize --getCorrectTextSize(0.02)
		local w = 0.015 * vehicleControlAddon.getUiScale()
		local h = w * g_screenAspectRatio
		
		setTextAlignment( RenderText.ALIGN_CENTER ) 
		setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_MIDDLE )
		
		local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )			
		local d = 0
		if not self.spec_vca.snapIsOn then 
			d = math.atan2( lx, lz )
		elseif self.spec_vca.snapDirection == 1 then 
			d = self.spec_vca.lastSnapAngle 
		elseif self.spec_vca.snapDirection == 2 then 
			d = self.spec_vca.lastSnapAngle + 0.5 * math.pi 
		elseif self.spec_vca.snapDirection == 3 then 
			d = self.spec_vca.lastSnapAngle + math.pi 
		elseif self.spec_vca.snapDirection == 4 then 
			d = self.spec_vca.lastSnapAngle - 0.5 * math.pi 
		else
			d = math.atan2( lx, lz )
		end 
		local curSnapAngle, curSnapOffset1, curSnapOffset2 = self:vcaGetCurrentSnapAngle( d )
		
		if self.spec_vca.drawHud then 

			local posX   = g_currentMission.inGameMenu.hud.speedMeter.gearBg.overlay.x
			local posY   = g_currentMission.inGameMenu.hud.speedMeter.gearBg.overlay.y
			local width  = g_currentMission.inGameMenu.hud.speedMeter.gearBg.overlay.width 
			local height = g_currentMission.inGameMenu.hud.speedMeter.gearBg.overlay.height
			
			height = width * g_screenAspectRatio
			if height > posY then 
				height = posY 
				posY   = 0 
			else 
				posY   = 0.5 * ( posY - height  )
			end 
		
			local f, m, b = self:vcaGetDiffState()
			if f > 0 or m > 0 or b > 0 then
				local function getRenderColor( state )
					if     state == nil then 
						return 0,0,0,1
					elseif state == 0 then 
						return 0.35,0.35,0.35,1
					elseif state == 1 then 
						return 1,1,1,1
					elseif state == 2 then 
						return 0,1,0,1
					end 
					return 0,0,0,1
				end 
				
							
				setOverlayColor( vehicleControlAddon.ovDiffLockFront, getRenderColor( f ) )
				setOverlayColor( vehicleControlAddon.ovDiffLockMid  , getRenderColor( m ) )
				setOverlayColor( vehicleControlAddon.ovDiffLockBack , getRenderColor( b ) )
				
				local vehicleSpeed = math.max( self.lastSpeed * 1000, 0.277 )
				local function setWheelColor( idx, ov )
					local ws = nil 
					if      idx ~= nil
							and self.spec_wheels ~= nil
							and self.spec_wheels.wheels ~= nil
							and self.spec_wheels.wheels[idx] ~= nil
							and self.spec_wheels.wheels[idx].vcaSpeed   ~= nil 
							and self.spec_wheels.wheels[idx].vcaNoPower ~= nil 
							and self.spec_wheels.wheels[idx].vcaNoPower ~= true then 
						ws = self.spec_wheels.wheels[idx].vcaSpeed
						if self:vcaGetShuttleCtrl() then 
							if self.spec_motorized.motor.currentDirection < 0 then 
								ws = -ws 
							end 
						else 
							if self.movingDirection < 0 then 
								ws = -ws 
							end 
						end 
					end 
					local r,g,b = 0.35,0.35,0.35
					if ws ~= nil then 
						if     ws <= 1.05 * vehicleSpeed then 
							r = 1
							g = 1
							b = 1
						elseif 0  >= vehicleSpeed then 
						elseif ws >= 1.25 * vehicleSpeed then 
							r = 1
							g = 0 
							b = 0
						elseif ws >= 1.15 * vehicleSpeed then  
							r = 1
							g = 1 - 10 * ( ws / vehicleSpeed - 1.15 )
							b = 0
						else 
							r = 1
							g = 1 
							b = 1 - 10 * ( ws / vehicleSpeed - 1.05 )
						end 
					elseif not self.spec_vca.diffHas2 then 
						r = 0.7
						g = 0.7
						b = 0.7
					end 
					setOverlayColor( ov, r,g,b, 1 )
				end 
				
				setWheelColor( self.spec_vca.wheelIndexFL, vehicleControlAddon.ovDiffLockFL )
				setWheelColor( self.spec_vca.wheelIndexFR, vehicleControlAddon.ovDiffLockFR )
				setWheelColor( self.spec_vca.wheelIndexRL, vehicleControlAddon.ovDiffLockRL )
				setWheelColor( self.spec_vca.wheelIndexRR, vehicleControlAddon.ovDiffLockRR )
				
				renderOverlay( vehicleControlAddon.ovDiffLockBg    , posX, posY, width, height )
				local prevWidth = width 
				width = math.min( width, height / g_screenAspectRatio )
				posX = posX + 0.5 * ( prevWidth - width )
				renderOverlay( vehicleControlAddon.ovDiffLockFL   , posX, posY, width, height )
				renderOverlay( vehicleControlAddon.ovDiffLockFR   , posX, posY, width, height )
				renderOverlay( vehicleControlAddon.ovDiffLockRL   , posX, posY, width, height )
				renderOverlay( vehicleControlAddon.ovDiffLockRR   , posX, posY, width, height )
				renderOverlay( vehicleControlAddon.ovDiffLockFront, posX, posY, width, height )
				renderOverlay( vehicleControlAddon.ovDiffLockMid  , posX, posY, width, height )
				renderOverlay( vehicleControlAddon.ovDiffLockBack , posX, posY, width, height )
			else 
				local prevWidth = width 
				width = math.min( width, height / g_screenAspectRatio )
				posX = posX + 0.5 * ( prevWidth - width )
			end 
			
			setTextBold(false)

			if self.lastSpeed > 0.0003 then 
				local ws = 0
				if self.spec_vca.wheelSlip ~= nil then 
					ws = math.max( 0, math.min( math.floor( 100 * ( self.spec_vca.wheelSlip - 1 ) + 0.5 ), 100 ) )
				end 
				
				local g, b = 1, 1
				if     ws >= 25 then
					g = 0 
					b = 0 
				elseif ws >= 15 then 
					g = 1 - 0.1 * ( ws - 15 )
					b = 0
				elseif ws >=  5 then 
					g = 1 
					b = 1 - 0.1 * ( ws - 5 ) 
				end 
				setTextColor(1,g,b,1)
				
				if ws > 99 then 	
					renderText( 0.5 * ( posX + width + 1 ), posY + 0.5 * height, l, ">99%" )
				else 
					renderText( 0.5 * ( posX + width + 1 ), posY + 0.5 * height, l, string.format( "%2.0f%%", ws ) )
				end 
			end 

			setTextColor(unpack(vehicleControlAddon.colorNormal))

			width = g_currentMission.inGameMenu.hud.speedMeter.gaugeBackgroundElement.overlay.width * 0.6
			
			if height > 1.4 * l then 
				posY = posY + 0.5 * ( height - 1.4 * l )
				height = 1.4 * l
			end 
			
			if      self.spec_vca.minGearSpeed ~= nil
					and self.spec_vca.maxGearSpeed ~= nil
					and self.spec_vca.maxGearSpeed ~= 0
				--and self:getGearShiftMode()    ~= VehicleMotor.SHIFT_MODE_AUTOMATIC
				--and not self.spec_vca.autoShift 
					then 
				
				renderOverlay( vehicleControlAddon.ovGearSpeedBg, x - 0.5 * width, posY, width, height )

				if vehicleControlAddon.vcaUIShowautoShift( self ) then 
					if self.spec_vca.autoShift then 
						setTextColor(unpack(vehicleControlAddon.colorInactive))
					else
						setTextColor(unpack(vehicleControlAddon.colorActive))
					end 
				else 
					setTextColor(unpack(vehicleControlAddon.colorActive))
				end 

				setTextBold(true)
				
				local suffix = ""
				if     self.spec_vca.splitGears < 1 then 
				elseif self.spec_vca.splitGears < 3 then 
				-- 2 or 3 powershift gears 
					if self.spec_vca.gearSplitGear <= 1 then 
						suffix = " Lo"
					elseif self.spec_vca.gearSplitGear > self.spec_vca.splitGears then 
						suffix = " Hi"
					else 
						suffix = " Me"
					end 
				elseif self.spec_vca.splitGears < 4 then 
					if     self.spec_vca.gearSplitGear <= 1 then 
						suffix = " I"
					elseif self.spec_vca.gearSplitGear <= 2 then 
						suffix = " II"
					elseif self.spec_vca.gearSplitGear <= 3 then 
						suffix = " III"
					else 
						suffix = " IV"
					end 
				else 
					suffix = string.format( " (%d)", self.spec_vca.gearSplitGear )
				end 
					
				renderText( x, posY + 0.55 * height, height * 0.7142857,
										self:vcaSpeedToString( self.spec_vca.minGearSpeed, "%5.1f", true ).." .. "..self:vcaSpeedToString( self.spec_vca.maxGearSpeed, "%5.1f" )..suffix)
			elseif vehicleControlAddon.vcaUIShowautoShift( self ) then  
				renderOverlay( vehicleControlAddon.ovGearSpeedBg, x - 0.5 * width, posY, width, height )
			end 			
			
			setTextColor(unpack(vehicleControlAddon.colorNormal))
			setTextBold(false)
		
		--if VCAGlobals.snapAngleHudX >= 0 then
		--	x = VCAGlobals.snapAngleHudX
		--	setTextAlignment( RenderText.ALIGN_LEFT ) 
		--end 
		--if VCAGlobals.snapAngleHudY >= 0 then
		--	y = VCAGlobals.snapAngleHudY
		--	setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
		--else 
				y = y + l * 1.2
		--end 
			
			local text = ""
			if self.spec_vca.keepCamRot then 
				if text ~= "" then text = text ..", " end 
				text = text .. "keep rot."
			end 
			if self.spec_vca.ksIsOn then 
				if text ~= "" then text = text ..", " end 
				text = text .. "keep speed"
			elseif  self.spec_vca.speedLimiter 
					and self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then 
				if text ~= "" then text = text ..", " end 
				text = text .. "speed limiter"
			end 
			if self.spec_vca.inchingIsOn then 
				if text ~= "" then text = text ..", " end 
				text = text .. "inching"
			end 
			
			local i = 0
			if ( self.spec_vca.ksIsOn or self.spec_vca.ksIsActive ) and self.spec_drivable.cruiseControl.state == 0 then 
				i = i + 1 
			end 
			if self.spec_vca.snapPossible then 
				i = i + 1 
			end 
-- ovExtraTextBg
			if i > 0 or text ~= "" then  
				local ovY = y 
				local ovH = l * 1.2 * i + 0.4 * l
				if text ~= "" then 
					ovY = ovY - l * 0.75
					ovH = ovH + l * 0.75
				end 
				renderOverlay( vehicleControlAddon.ovExtraTextBg, x - 0.5 * width, ovY, width, ovH )
			end 
			
			if text ~= "" then 
				renderText(x, y, 0.75*l, text)
			end
			y = y + l * 0.9	
			
			if ( self.spec_vca.ksIsOn or self.spec_vca.ksIsActive ) and self.spec_drivable.cruiseControl.state == 0 then 
				renderText(x, y, l, self:vcaSpeedToString( Utils.getNoNil( self.spec_vca.keepSpeedTMS, Utils.getNoNil( self.spec_vca.keepSpeedTemp, self.spec_vca.keepSpeed ) ) / 3.6, "%5.1f" ))
				y = y + l * 1.2	
			end
		
			if not self:getIsVehicleControlledByPlayer() or self.spec_vca.snapDisabled then
			elseif self.spec_vca.snapIsOn then 
				setTextColor(unpack(vehicleControlAddon.colorActive))
				if self.spec_vca.snapDistance >= 0.25 then 
					renderText(x, y, l, string.format( "%4.1f° / %4.1fm", math.deg( math.pi - curSnapAngle ), self.spec_vca.snapDistance))
				else
					renderText(x, y, l, string.format( "%4.1f° / %4.1f°", math.deg( math.pi - curSnapAngle ), math.deg( math.pi - d )))
				end 
				y = y + l * 1.2	
			elseif -4 <= self.spec_vca.lastSnapAngle and self.spec_vca.lastSnapAngle <= 4 and not ( self.aiveAutoSteer ) then 
				setTextColor(unpack(vehicleControlAddon.colorInactive)) 
				renderText(x, y, l, string.format( "%4.1f° / %4.1f°", math.deg( math.pi - curSnapAngle ), math.deg( math.pi - d )))
				y = y + l * 1.2	
			end
			setTextColor(unpack(vehicleControlAddon.colorNormal)) 
			
		end 
		
		if not ( self.spec_vca.snapIsOn ) and self.spec_vca.drawSnapIsOn == nil then 
		-- leave vcaDrawSnapIsOn nil 
		elseif self.spec_vca.snapIsOn and not ( -4 <= self.spec_vca.lastSnapAngle and self.spec_vca.lastSnapAngle <= 4 ) then 
		-- start new 
			self.spec_vca.snapPosTimer  = 20000
			self.spec_vca.drawSnapIsOn  = true 
		else 
			if     self.spec_vca.snapIsOn and self.spec_vca.drawSnapIsOn == nil  then 
				self.spec_vca.snapPosTimer  = math.max( Utils.getNoNil( self.spec_vca.snapPosTimer , 0 ), 3000 )
			elseif self.spec_vca.snapIsOn and not ( self.spec_vca.drawSnapIsOn ) then 
				self.spec_vca.snapDrawTimer = 3000
			elseif self.spec_vca.drawSnapIsOn and not ( self.spec_vca.snapIsOn ) then 
				self.spec_vca.snapDrawTimer = 20000
			end 
			self.spec_vca.drawSnapIsOn = self.spec_vca.snapIsOn
		end 
		
		local snapDraw = false
		
		if not self.spec_vca.snapPossible then 
			self.spec_vca.snapDrawTimer = nil
			self.spec_vca.snapPosTimer  = nil 
			self.spec_vca.drawSnapIsOn  = nil 
		elseif self.spec_vca.snapPosTimer ~= nil then 
			snapDraw = true
		elseif self.spec_vca.snapDraw <= 0 then 
			self.spec_vca.snapDrawTimer = nil
			self.spec_vca.snapPosTimer  = nil 
		elseif self.spec_vca.snapDraw == 2 or self.spec_vca.snapDraw >= 4 then 
			snapDraw = true 
		elseif self.spec_vca.snapDrawTimer ~= nil then 
			if math.abs( self.lastSpeedReal ) * 3600 > 1 or self.spec_vca.snapDrawTimer > 3000 then 
				self.spec_vca.snapDrawTimer = self.spec_vca.snapDrawTimer - self.spec_vca.tickDt 
			end 
			if self.spec_vca.snapDrawTimer < 0 then 
				self.spec_vca.snapDrawTimer = nil 
			else 
				snapDraw = true 
			end 
		end 		
				
		if snapDraw then
			local wx,wy,wz = getWorldTranslation( self:vcaGetSteeringNode() )
			
			local dx    = math.sin( curSnapAngle )
			local dz    = math.cos( curSnapAngle )			
			local distX = wx - self.spec_vca.lastSnapPosX
			local distZ = wz - self.spec_vca.lastSnapPosZ 	
			
			local dist  = distX * dz - distZ * dx + curSnapOffset2

			local r, g, b, a = unpack(vehicleControlAddon.colorInactive)
			if self.spec_vca.snapIsOn then 
				dist = dist + self.spec_vca.snapFactor * self.spec_vca.snapDistance
				r, g, b, a = unpack(vehicleControlAddon.colorActive)

				if math.abs( dist ) > 1 then 
					if self.spec_vca.snapPosTimer == nil or self.spec_vca.snapPosTimer < 1000 then 
						self.spec_vca.snapPosTimer = 1000
					end
				end 
			elseif self.spec_vca.snapDistance >= 0.25 then 
				while dist+dist > self.spec_vca.snapDistance do 
					dist = dist - self.spec_vca.snapDistance
				end 
				while dist+dist <-self.spec_vca.snapDistance do 
					dist = dist + self.spec_vca.snapDistance
				end 
			end 

			setTextAlignment( RenderText.ALIGN_CENTER ) 
			setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
				
			local text = {'|','»»»»»»»»»»»»»»»»'}
			if not self.spec_vca.snapIsOn or self.spec_vca.snapDirection <1 then 
				text = {'|','------------------'}
			end 
			local xMax = 1 
			if ( self.spec_vca.snapDraw == 1 or self.spec_vca.snapDraw == 3 ) and self.spec_vca.snapIsOn and self.spec_vca.snapPosTimer == nil then 
				xMax = 0 
			end 
			for x=-xMax,xMax do 
				for zi=-1,2,0.2 do
					local z = 10 
					if self.spec_reverseDriving  ~= nil and self.spec_reverseDriving.isReverseDriving then			
						if zi < 1 then 
							z = z - 20 * zi 
						else 
							z = z - 10 * zi * zi
						end 
					else 
						if zi < 1 then 
							z = z + 20 * zi 
						else 
							z = z + 20 * zi * zi
						end 
					end 
					local fx = 0
					if x ~= 0 then 
						fx = x * 0.5 * self.spec_vca.snapDistance + curSnapOffset1
						setTextColor(r,g,b, 0.5*a) 
					else
						setTextColor(r,g,b, a) 
					end
					local px = wx - dist * dz - fx * dz + z * dx 
					local pz = wz + dist * dx + fx * dx + z * dz 
					local py = getTerrainHeightAtWorldPos( g_currentMission.terrainRootNode, px, 0, pz ) 
					
					local a = 0
					for _,t in pairs(text) do
						if self.spec_vca.snapDraw > 2 then 
							renderText3D( px,py+0.5,pz, 0,curSnapAngle-a,0, 0.52, t )
							renderText3D( px,py+1.0,pz, 0,curSnapAngle-a,0, 0.52, t )
							renderText3D( px,py+1.5,pz, 0,curSnapAngle-a,0, 0.52, t )
						else 
							renderText3D( px,py,pz, 0,curSnapAngle-a,0, 0.52, t )
						end 
						if self.spec_reverseDriving  ~= nil and self.spec_reverseDriving.isReverseDriving then			
							a = -0.5*math.pi 
						else 
							a =  0.5*math.pi 
						end 
					end 
				end  
			end 
			dx, dz = -dz, dx
		end 
		
		if self.spec_vca.snapPosTimer ~= nil then 
			self.spec_vca.snapPosTimer = self.spec_vca.snapPosTimer - self.spec_vca.tickDt 
			if self.spec_vca.snapPosTimer < 0 then 
				self.spec_vca.snapPosTimer = nil 
			end 
		end 
		
		if      self.spec_vca.workAreaDraw > 0
				and not self.spec_vca.snapIsOn
				and not snapDraw then 
			local wx,wy,wz = getWorldTranslation( self:vcaGetSteeringNode() )
			
			local dx    = lx
			local dz    = lz			
			local angle = math.atan2( lx, lz )

			local r, g, b, a = unpack(vehicleControlAddon.colorActive)
			setTextColor(r,g,b, a) 
			setTextAlignment( RenderText.ALIGN_CENTER ) 
			setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
				
			local text = {'|','------------------'}

			for x=-1,1 do 
				for zi=0,1,0.2 do
					local z = 0 
					if self.spec_reverseDriving  ~= nil and self.spec_reverseDriving.isReverseDriving then			
						z = z - 20 * zi 
					else 
						z = z + 20 * zi 

					end 
					local fx = 0
					if x ~= 0 then 
						fx = x * 0.5 * self.spec_vca.snapDistance + curSnapOffset1
					end
					local px = wx - fx * dz + z * dx 
					local pz = wz + fx * dx + z * dz 
					local py = getTerrainHeightAtWorldPos( g_currentMission.terrainRootNode, px, 0, pz ) 
					
					local a = 0
					for _,t in pairs(text) do
						renderText3D( px,py,pz, 0,angle-a,0, 0.52, t )
						if self.spec_vca.workAreaDraw > 1 then 
							renderText3D( px,py+0.5,pz, 0,angle-a,0, 0.52, t )
							renderText3D( px,py+1.0,pz, 0,angle-a,0, 0.52, t )
							renderText3D( px,py+1.5,pz, 0,angle-a,0, 0.52, t )
						end 
						if self.spec_reverseDriving  ~= nil and self.spec_reverseDriving.isReverseDriving then			
							a = -0.5*math.pi 
						else 
							a =  0.5*math.pi 
						end 
					end 
				end  
			end 
			dx, dz = -dz, dx
		end 
		
		if type( self.spec_vca.currentPath ) == "table" then 
			local r, g, b, a = unpack(vehicleControlAddon.colorActive)
			setTextColor(r,g,b, a) 
			setTextAlignment( RenderText.ALIGN_CENTER ) 
			setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )

			for indx, point in pairs( self.spec_vca.currentPath ) do 
				local px    = point[1]
				local pz    = point[2]			
				local angle = point[3]
				local dx    = math.sin(angle)
				local dz    = math.cos(angle)			
				local py    = getTerrainHeightAtWorldPos( g_currentMission.terrainRootNode, px, 0, pz ) 
				
				local a = 0
				for _,t in pairs({string.format("%d",indx),">>>>>"}) do
					renderText3D( px,py,pz, 0,angle-a,0, 0.52, t )
					if self.spec_reverseDriving  ~= nil and self.spec_reverseDriving.isReverseDriving then			
						a = -0.5*math.pi 
					else 
						a =  0.5*math.pi 
					end 
				end 
			end
		end 

		setTextAlignment( RenderText.ALIGN_LEFT ) 
		setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
		setTextColor(1, 1, 1, 1) 
	end 	
end


function vehicleControlAddon:onReadStream(streamId, connection)

	self.spec_vca.diffHasF = streamReadBool( streamId )
	self.spec_vca.diffHasM = streamReadBool( streamId )
	self.spec_vca.diffHasB = streamReadBool( streamId )
	
	for i,name in pairs( vehicleControlAddon.propertiesIndex ) do 
		local prop = vehicleControlAddon.properties[name]
		self:vcaSetState( name, prop.func.streamRead( streamId ), true )
	end 
	
end

function vehicleControlAddon:onWriteStream(streamId, connection)

	streamWriteBool( streamId, self.spec_vca.diffHasF )
	streamWriteBool( streamId, self.spec_vca.diffHasM )
	streamWriteBool( streamId, self.spec_vca.diffHasB )

	for i,name in pairs( vehicleControlAddon.propertiesIndex ) do 
		local prop = vehicleControlAddon.properties[name]
		prop.func.streamWrite( streamId , self:vcaGetState( name, true ) )
	end 

end 

function vehicleControlAddon:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		if streamReadBool(streamId) then
			local wheelSlip = streamReadUInt8(streamId)
			if wheelSlip <= 0 then 
				self.spec_vca.wheelSlip = nil 
			else 
				self.spec_vca.wheelSlip = 1 + wheelSlip / 255
			end 
		end 
	end 
end

function vehicleControlAddon:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local wheelSlip = 0
		if self.spec_vca ~= nil and self.spec_vca.wheelSlip ~= nil and self.spec_vca.wheelSlip > 1 then  
			wheelSlip = math.max( 0, math.min( math.floor( ( self.spec_vca.wheelSlip - 1 ) * 255 + 0.5 ), 255 ) )
		end 
		if self.spec_vca ~= nil and wheelSlip ~= self.spec_vca.lastWheelSlip then 
			self.spec_vca.lastWheelSlip = wheelSlip
			streamWriteBool(streamId, true )
			streamWriteUInt8(streamId, wheelSlip )
		else 
			streamWriteBool(streamId, false )
		end 
	end
end

function vehicleControlAddon:vcaGetSteeringNode()
	local n
	if type( self.getAIRootNode ) == "function" then 
		n = self:getAIRootNode()
		if n ~= nil then 
			return n
		end 
	end 
	if self.steeringAxleNode ~= nil and self.steeringAxleNode ~= 0 then 
		return self.steeringAxleNode
	end 
	return self.components[1].node  
end 

function vehicleControlAddon:vcaGetCurrentSnapAngle(curRot)

	if self.spec_vca.lastSnapAngle == nil or curRot == nil then 
		return 0 
	end
	
	local a = self.spec_vca.lastSnapAngle
	local o = self.spec_vca.snapOffset
	local p = o 
	local d = 0
	local e = - ( self.spec_vca.snapOffset + self.spec_vca.snapOffset )
	if self.spec_vca.snapInvert then 
		e = 0 
		if not self:vcaGetSnapWillInvert() then 
			p = -o 
		elseif self:vcaGetSnapIsInverted() then 
			o = -o 
			p =  o
		end 
	end 
	local c = curRot 
	local f = math.pi * 0.5 -- 0.5 for 180° and 0.25 for 90°
	local i = 0
	local r = false 
	if self.spec_vca.snapEvery90 then 
		f = f * 0.5 
	end 

	while a - c <= -f do 
		a = a + f+f
		i = i + 1 
		if not self.spec_vca.snapEvery90 then  
			d,e = e,d
			o,p = p,o
		elseif r then 
			r = false 
			d,e = e,d
			o,p = p,o
		else 
			r = true 
		end 
	end 
	while a - c > f do 
		a = a - f-f
		i = i - 1 
		if not self.spec_vca.snapEvery90 then  
			d,e = e,d
			o,p = p,o
		elseif r then 
			r = false 
			d,e = e,d
			o,p = p,o
		else 
			r = true 
		end 
	end

	return a, o, d, i
end 

function vehicleControlAddon.getRelativeTranslation( refNode, node )
	local wx, wy, wz = getWorldTranslation( node )
	return worldToLocal( refNode, wx, wy, wz )
end

function vehicleControlAddon.getDistance( refNode, leftMarker, rightMarker, iMinX, iMaxX )
	local lx, ly, lz = vehicleControlAddon.getRelativeTranslation( refNode, leftMarker )
	local rx, ry, rz = vehicleControlAddon.getRelativeTranslation( refNode, rightMarker )
	vcaDebugPrint(string.format( "(%5.2f, %5.2f, %5.2f) / (%5.2f, %5.2f, %5.2f)", lx, ly, lz, rx, ry, rz ))
	
	if iMinX ~= nil and iMaxX ~= nil then 
		return math.min( lx, rx, iMinX ), math.max( lx, rx, iMaxX )
	end 
	
	return math.min( lx, rx ), math.max( lx, rx )
end

function vehicleControlAddon:vcaGetSnapWillInvert()
	if     SpecializationUtil.hasSpecialization(AIVehicle, self.specializations) then
		for _, implement in ipairs(self:getAttachedAIImplements()) do
			if      SpecializationUtil.hasSpecialization( Plow, implement.object.specializations) 
					and implement.object.spec_plow.rotationPart.turnAnimation ~= nil then
				return true 
			end 
		end 
	end 
	return false
end 

function vehicleControlAddon:vcaGetSnapIsInverted()
	if SpecializationUtil.hasSpecialization(AIVehicle, self.specializations) then
		for _, implement in ipairs(self:getAttachedAIImplements()) do
			if implement.object:getAIInvertMarkersOnTurn( true ) then
				return true 
			end 
		end 
	end 
	return false
end 

function vehicleControlAddon:vcaGetSnapDistance()
	local minX, maxX
	
	if     SpecializationUtil.hasSpecialization(AIVehicle, self.specializations) then
		for _, implement in ipairs(self:getAttachedAIImplements()) do
			local leftMarker, rightMarker, backMarker, _ = implement.object:getAIMarkers()
			if implement.object.steeringAxleNode ~= nil and leftMarker ~= nil and rightMarker  ~= nil then 
				minX, maxX = vehicleControlAddon.getDistance( implement.object.steeringAxleNode, leftMarker, rightMarker, minX, maxX )
				local object = implement.object
				
				for i=1,10 do
					if object == nil or type( object.getAttacherVehicle ) ~= "function" then 
						break 
					end 
					local parent = object:getAttacherVehicle()
					if parent == nil or type( parent.getAttacherJointDescFromObject ) ~= "function" then 
						break 
					end 
					local jointDesc = parent:getAttacherJointDescFromObject( implement.object )
					if jointDesc == nil then  
						break 
					end 
					
					local vx, vy, vz = vehicleControlAddon.getRelativeTranslation( self:vcaGetSteeringNode(), jointDesc.jointTransform )
					local ix, iy, iz = vehicleControlAddon.getRelativeTranslation( implement.object.steeringAxleNode, jointDesc.jointTransform )
				--vcaDebugPrint( string.format("SnapDistance: (%5.2f, %5.2f); %5.2f; %5.2f", minX, maxX, vx, ix))
					minX = minX + vx - ix 
					maxX = maxX + vx - ix 

				--local m1, m2 = vehicleControlAddon.getDistance( self:vcaGetSteeringNode(), leftMarker, rightMarker, minX, maxX )
				--vcaDebugPrint( string.format("SnapDistance: (%5.2f, %5.2f); (%5.2f, %5.2f)", minX, maxX, m1, m2))
					
					if self.id == parent.id then 
						break 
					end 
					
					object = parent 
				end 
			end
		end
	end 
	
	if SpecializationUtil.hasSpecialization(AIImplement, self.specializations) then
		local leftMarker, rightMarker, backMarker, _ = self:getAIMarkers()
		if self:vcaGetSteeringNode() ~= nil and leftMarker ~= nil and rightMarker  ~= nil then 
			minX, maxX = vehicleControlAddon.getDistance( self:vcaGetSteeringNode(), leftMarker, rightMarker, minX, maxX )
		end
	end
	
	if minX ~= nil and maxX ~= nil then 
		local d = 0.1 * math.floor( 10 * ( maxX - minX ) + 0.5 )
		local o = 0.1 * math.floor(  5 * ( maxX + minX ) + 0.5 )
		local p = self:vcaGetSnapWillInvert()
		if p and self:vcaGetSnapIsInverted() then 
			o = -o 
		end 
		return d, -o, p
	end 
	
	return 0, 0, false 
end

function vehicleControlAddon:vcaSetCruiseSpeed( speed )
	local spec = self.spec_drivable 
	spec.cruiseControl.speed = speed
	spec.lastInputValues.cruiseControlValue = 0
	if spec.cruiseControl.speed ~= spec.cruiseControl.speedSent then
		if     not ( self.spec_vca.isInitialized )
			--or not ( g_vehicleControlAddon.isMP ) 
				then 
		elseif g_server ~= nil then
			g_server:broadcastEvent(SetCruiseControlSpeedEvent.new(self, spec.cruiseControl.speed, spec.cruiseControl.speedReverse), nil, nil, self)
		else
			g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent.new(self, spec.cruiseControl.speed, spec.cruiseControl.speedReverse))
		end
		spec.cruiseControl.speedSent = spec.cruiseControl.speed
	end
end 

function vehicleControlAddon:vcaGetDefRevI()
	if not ( VCAGlobals.camReverseRotation ) then 
		return false 
	end 
	
	if self.attacherJoints ~= nil then
		for _,a in pairs( self.attacherJoints ) do
			if a.jointType == JOINTTYPE_SEMITRAILER then
				return false
			end
		end
	end

	if SpecializationUtil.hasSpecialization(Combine, self.specializations) then
		return false
	end 
	
	return true 
end

--******************************************************************************************************************************************
function vehicleControlAddon:vcaUpdateVehiclePhysics( superFunc, axisForward, axisSide, doHandbrake, dt )
	if self.spec_vca == nil then return superFunc( self, axisForward, axisSide, doHandbrake, dt ) end 
	
	--*******************************************************************
	-- Snap Angle
	local axisSideLast       = self.spec_vca.axisSideLast
	local lastSnapAngleTimer = self.spec_vca.snapAngleTimer
	self.spec_vca.axisSideLast     = nil
	self.spec_vca.snapAngleTimer   = nil
	self.spec_vca.lastSnapIsOn     = self.spec_vca.snapIsOn 
	
	local lastPathIndex = self.spec_vca.lastPathIndex 
	local lastPathAngle = self.spec_vca.lastPathAngle
	self.spec_vca.lastPathIndex = nil
	self.spec_vca.lastPathAngle = nil
	
	if self.spec_vca.snapIsOn then 
		if not ( self.spec_vca.isEnteredMP ) then
			self:vcaSetState( "snapIsOn", false )
		elseif self:getIsAIActive() then 
			self:vcaSetState( "snapIsOn", false )
		end 
	end 
	
	if self.spec_vca.snapIsOn then 
		local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )		
		local wx,_,wz = getWorldTranslation( self:vcaGetSteeringNode() )
		
		if lx*lx+lz*lz > 1e-6 then 
			local rot    = math.atan2( lx, lz )
			local d      = vehicleControlAddon.snapAngles[self.spec_vca.snapAngle]
			
			if not ( -4 <= self.spec_vca.lastSnapAngle and self.spec_vca.lastSnapAngle <= 4 ) then 
				if self:getIsVehicleControlledByPlayer() then 
					self.spec_vca.snapPosTimer = 20000
				end 

				self:vcaSetState( "lastSnapPosX", wx )
				self:vcaSetState( "lastSnapPosZ", wz )
				local target = 0
				local diff   = math.pi+math.pi
				if d == nil then 
					if self.spec_vca.snapAngle < 1 then 
						d = vehicleControlAddon.snapAngles[1] 
					else 
						d = 90 
					end 
				end 
				for i=0,360,d do 
					local a = math.rad( i )
					local b = math.abs( vehicleControlAddon.normalizeAngle( a - rot ) )
					if b < diff then 
						target = a 
						diff   = b
					end 
				end 
				
				self:vcaSetState( "lastSnapAngle", vehicleControlAddon.normalizeAngle( target ) )
				self:vcaSetState( "snapFactor", 0 )
			end 
			
			local tx = self.spec_vca.lastSnapPosX
			local tz = self.spec_vca.lastSnapPosZ
			local rot2 = rot 
			local setDir = false 
			if     self.spec_vca.snapDirection == 1 then 
				rot2 = self.spec_vca.lastSnapAngle 
			elseif self.spec_vca.snapDirection == 2 then 
				rot2 = self.spec_vca.lastSnapAngle + 0.5 * math.pi 
			elseif self.spec_vca.snapDirection == 3 then 
				rot2 = self.spec_vca.lastSnapAngle + math.pi 
			elseif self.spec_vca.snapDirection == 4 then 
				rot2 = self.spec_vca.lastSnapAngle - 0.5 * math.pi 
			else 
				setDir = true 
			end 
			
			local curSnapAngle, _, curSnapOffset = self:vcaGetCurrentSnapAngle( rot2 )
		
			if setDir then 
				delta = vehicleControlAddon.normalizeAngle( curSnapAngle - self.spec_vca.lastSnapAngle ) / math.pi 
				if     -0.25 <= delta and delta <=  0.25 then 
					self:vcaSetState( "snapDirection", 1 )
				elseif  0.25 <= delta and delta <=  0.75 then 
					self:vcaSetState( "snapDirection", 2 )
				elseif -0.75 <= delta and delta <= -0.25 then 
					self:vcaSetState( "snapDirection", 4 )
				else 
					self:vcaSetState( "snapDirection", 3 )
				end 
				print("VCA snap direction: "..tostring(delta).." => "..tostring(self.spec_vca.snapDirection))
			end 
			
			if vehicleControlAddon.snapCurve == nil then 
				vehicleControlAddon.snapCurve = AnimCurve.new(linearInterpolator1)

				local kf = {{x=0.01, y=0.01},
										{x=0.02, y=0.02},
										{x=0.05, y=0.08},
										{x=0.10, y=0.25},
										{x=0.12, y=0.42},
										{x=0.15, y=0.52},
										{x=0.20, y=0.66},
										{x=0.30, y=0.82},
										{x=0.40, y=0.95},
										{x=0.50, y=1.07},
										{x=0.60, y=1.18},
										{x=0.80, y=1.40},
										{x=0.90, y=1.50}}

				local iMax = table.getn( kf )

				vehicleControlAddon.snapCurve:addKeyframe({-math.pi*0.5,time=-1 }) 
				for i=iMax,1,-1 do 
					vehicleControlAddon.snapCurve:addKeyframe({-kf[i].y, time=-kf[i].x})
				end 
				vehicleControlAddon.snapCurve:addKeyframe({0 ,time=0})
				for i=1,iMax,1 do 
					vehicleControlAddon.snapCurve:addKeyframe({kf[i].y, time=kf[i].x})
				end 
				vehicleControlAddon.snapCurve:addKeyframe({ math.pi*0.5,time=1 })   
			end 
			
			local diffR = 0

			if type( self.spec_vca.currentPath ) == "table" and table.getn( self.spec_vca.currentPath ) > 1 then 
				
				local minP = nil 
				local minT = nil
				local minS = nil
				local minI = nil 
				local minA = nil 
				if lastPathIndex == nil then 
					lastPathIndex = 1 
				end 
				
				local debugOut = ""
				
				local i = table.getn( self.spec_vca.currentPath )
				local pdx = self.spec_vca.currentPath[i][1] - self.spec_vca.currentPath[1][1]
				local pdz = self.spec_vca.currentPath[i][2] - self.spec_vca.currentPath[1][2]
				local pdl = pdx*pdx + pdz*pdz 
				if pdl > 1 then 
					pdl = math.sqrt( pdl )
					pdx = pdx / pdl 
					pdz = pdz / pdl 
				else 
					pdx = math.sin( self.spec_vca.currentPath[1][3] )
					pdz = math.cos( self.spec_vca.currentPath[1][3] )
				end 
					 
				for indx=1,table.getn( self.spec_vca.currentPath ) do 
					local point = self.spec_vca.currentPath[indx]
					local sx = point[1]
					local sz = point[2]
					local a  = point[3]
					local l  = point[4]
					local dx = math.sin(a)
					local dz = math.cos(a)
					
					sx = sx - ( curSnapOffset + self.spec_vca.snapFactor * self.spec_vca.snapDistance ) * pdz 
					sz = sz + ( curSnapOffset + self.spec_vca.snapFactor * self.spec_vca.snapDistance ) * pdx 
					
					local da = vehicleControlAddon.mbClamp( vehicleControlAddon.normalizeAngle( a - rot ), -0.5*math.pi, 0.5 * math.pi)
					
					local vx = vehicleControlAddon.snapRadius * (1-math.cos( da )) * lx + math.sin( da ) * lz
					local vz = vehicleControlAddon.snapRadius * (1-math.cos( da )) * lz - math.sin( da ) * lx
					
					local t  = ( wx - sx + vx ) * dx + ( wz - sz + vz ) * dz 
					local s2 = ( wx - sx + vx ) * dz - ( wz - sz + vz ) * dx 
					local s  = ( wx - sx ) * dz - ( wz - sz ) * dx 
					
			--	t = t - vehicleControlAddon.snapRadius
					
					local t2 = 0
					if indx > 1 and t < 0 then 
						t2 = t 
					elseif indx < table.getn( self.spec_vca.currentPath ) and t > l then  
						t2 = t - l 
					end 
					local p2 = s2^2 + t2^2			
					
					
				--debugOut = debugOut .. tostring(indx)..", "..tostring(t2)..", "..tostring(s)..", "..tostring(p2)..";  "
					
					if minP == nil or ( p2 <= minP and t2 <= 0 ) then  
						minP = p2 
						minS = s 
						minT = t 
						minA = a
						minI = indx 
					end 
				end 
				
			--print(tostring(minI).." ("..tostring(minT)..", "..tostring(minS)..", "..tostring(minP)..")")
			--print(debugOut)
				
				self.spec_vca.lastPathIndex = minI  
				
				if minA ~= nil and minS ~= nil then 
					if lastPathAngle == nil then 
						self.spec_vca.lastPathAngle = minA 
					else 
						self.spec_vca.lastPathAngle = lastPathAngle + 0.08 * ( minA - lastPathAngle )
					end 
					diffR = rot - self.spec_vca.lastPathAngle
					
					if not self.spec_vca.isForward then
						diffR	= -diffR
					end 
					local dist  = minS
					local d2    = vehicleControlAddon.mbClamp( dist / vehicleControlAddon.snapRadius, -1, 1 )
					local alpha = vehicleControlAddon.snapCurve:get( d2 )
					diffR = diffR + alpha				
				end 
			
			else 
		
				diffR = rot - curSnapAngle
				if not self.spec_vca.isForward then
					diffR	= -diffR
				end 

				do
					local dx    = math.sin( curSnapAngle )
					local dz    = math.cos( curSnapAngle )			
					local distX = wx - tx
					local distZ = wz - tz 			
					local dist  = curSnapOffset + distX * dz - distZ * dx + self.spec_vca.snapFactor * self.spec_vca.snapDistance
					local d2    = vehicleControlAddon.mbClamp( dist / vehicleControlAddon.snapRadius, -1, 1 )
					local alpha = vehicleControlAddon.snapCurve:get( d2 )
					diffR = diffR + alpha				
				end 
			end 
			
			local a = vehicleControlAddon.mbClamp( vehicleControlAddon.normalizeAngle( diffR ) * 6, -1, 1 )

			if self.spec_reverseDriving  ~= nil and self.spec_reverseDriving.isReverseDriving then
				a = -a 
			end

			local d
			d = 0.0002 * dt * ( 2 + math.min( 18, self.lastSpeed * 3600 ) )
			
			if axisSideLast == nil then 
				axisSideLast = axisSide
			end 
			
			axisSide = axisSideLast + vehicleControlAddon.mbClamp( a - axisSideLast, -d, d )
		end 
		
		self.spec_vca.snapAngleTimer = 400 
		self.spec_vca.axisSideLast   = axisSide
	elseif axisSideLast ~= nil and lastSnapAngleTimer ~= nil and lastSnapAngleTimer > dt then  
		f = 0.0025 * lastSnapAngleTimer
		axisSide = f * axisSideLast + ( 1 - f ) * axisSide 
			
		self.spec_vca.snapAngleTimer = lastSnapAngleTimer - dt 
		self.spec_vca.axisSideLast   = axisSideLast
	end 				
	
-- remember and restore cruise control state when accelerating
	local ccState = nil
	local limit,_ = self:getSpeedLimit(true)
	local speed   = math.min( limit, self.lastSpeed * 3600 )
	local spec    = self.spec_drivable
	if      self.spec_vca ~= nil
			and self:vcaIsVehicleControlledByPlayer()
			and spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF
			and ( self:vcaGetShuttleCtrl() or self.movingDirection > 0 )
			and axisForward > 0 then 
		ccState = spec.cruiseControl.state
		spec.cruiseControl.state = Drivable.CRUISECONTROL_STATE_OFF
		self:getMotor():setSpeedLimit( limit )
	end 
	
	local lastBrakeCruiseSpeed = self.spec_vca.brakeCruiseSpeed
	self.spec_vca.brakeCruiseSpeed = nil 
	
	if ccState ~= nil and spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then
		if speed > 3 then 
			self.spec_vca.brakeCruiseSpeed       = speed
			spec.cruiseControl.speedInterpolated = speed
		end 
	elseif speed > 3 and self.spec_vca.idleThrottle and spec.cruiseControl.speedInterpolated ~= nil then  
		if lastBrakeCruiseSpeed == nil then   
			self.spec_vca.brakeCruiseSpeed = speed
		else 
			self.spec_vca.brakeCruiseSpeed = math.min( limit, speed + 1, math.max( spec.cruiseControl.speedInterpolated, lastBrakeCruiseSpeed - 0.003 * dt ) )
		end 
		spec.cruiseControl.speedInterpolated = self.spec_vca.brakeCruiseSpeed
	end 
	
	local res = { superFunc( self, axisForward, axisSide, doHandbrake, dt ) }
	
	if ccState ~= nil and spec.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF then 
		self:setCruiseControlState(ccState)
	end 
	
	return unpack( res )

end 

Drivable.updateVehiclePhysics = Utils.overwrittenFunction( Drivable.updateVehiclePhysics, vehicleControlAddon.vcaUpdateVehiclePhysics )
--******************************************************************************************************************************************
-- shuttle control and inching
function vehicleControlAddon:vcaUpdateWheelsPhysics( superFunc, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking )

	if not ( self.spec_vca ~= nil and self.spec_vca.isInitialized ) then  
		return superFunc( self, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking )
	end 
	
	local lastWheelSlip        = self.spec_vca.wheelSlip
	self.spec_vca.wheelSlip    = nil

	self.spec_vca.oldAcc       = acceleration
	self.spec_vca.oldHandbrake = doHandbrake
	
	local lastKSBrakeTime = self.spec_vca.ksBrakeTime
	self.spec_vca.ksBrakeTime = nil 
	local lastIdleThrottleTime = self.spec_vca.idleThrottleTime
	self.spec_vca.idleThrottleTime = nil 
	local lastAccAntiSlip = self.spec_vca.maxAccAntiSlip
	self.spec_vca.maxAccAntiSlip = nil 
	
	if self:vcaIsVehicleControlledByPlayer() then
		if self.spec_vca.ksIsActive then 
			if self:vcaGetShuttleCtrl() or self.spec_vca.keepSpeed > 0 then 
				if acceleration < -0.1 then 
					if lastKSBrakeTime == nil then 
						self.spec_vca.ksBrakeTime = g_currentMission.time 
					else 
						self.spec_vca.ksBrakeTime = lastKSBrakeTime
					end 
				end 
			elseif self.spec_vca.keepSpeed < 0 then 
				if acceleration > 0.1 then 
					if lastKSBrakeTime == nil then 
						self.spec_vca.ksBrakeTime = g_currentMission.time 
					else 
						self.spec_vca.ksBrakeTime = lastKSBrakeTime
					end 
				end 
			end 
		end 

		local motor = self.spec_motorized.motor 
		
		
		local wheelSlip  = 1
		local speedMS    = self.lastSpeedReal * 1000
		local wheelSpeed = motor.differentialRotSpeed
		if motor.maxGearRatio < 0 then 
			wheelSpeed = -wheelSpeed
		end 
		if wheelSpeed > speedMS and speedMS > 0.3 then 
			wheelSlip = wheelSpeed / speedMS 
		end 
		if lastWheelSlip == nil then 
			lastWheelSlip = 1
		end 
		self.spec_vca.wheelSlip = lastWheelSlip + 0.03 * ( wheelSlip - lastWheelSlip )
	
		if not self:getIsMotorStarted() then 
			acceleration = 0
			doHandbrake = true 
		elseif self.spec_vca.handbrake then  
			acceleration = 0
			doHandbrake = true 		
		elseif self.spec_drivable.cruiseControl.state > 0 then 

		elseif self.spec_vca.ksIsOn and math.abs( self.spec_vca.keepSpeed ) < 0.5 then 
			acceleration = 0
			doHandbrake  = true 
		elseif self.spec_vca.ksIsActive and ( self.spec_vca.ksBrakeTime == nil or g_currentMission.time < self.spec_vca.ksBrakeTime + 1000 ) then 
			self.spec_motorized.motor:setSpeedLimit( math.min( self:getSpeedLimit(true), math.abs(self.spec_vca.keepSpeed) ) )
			if self:vcaGetShuttleCtrl() then 
				acceleration = 1
			elseif self.spec_vca.keepSpeed > 0 then 
				acceleration = self.spec_drivable.reverserDirection
				self.nextMovingDirection = 1
			else
				acceleration = -self.spec_drivable.reverserDirection
				self.nextMovingDirection = -1
			end 
			self.spec_vca.oldAcc = acceleration
		elseif self.spec_vca.isBlocked and self.spec_vca.isEnteredMP then
			acceleration = 0
			doHandbrake  = true 
		end 
			
		if self.spec_drivable.cruiseControl.state == 0 and self.spec_vca.limitThrottle ~= nil and self.spec_vca.inchingIsOn ~= nil and math.abs( acceleration ) > 0.01 then 
			local limitThrottleRatio     = 0.75
			local limitThrottleIfPressed = true
			if self.spec_vca.limitThrottle < 11 then
				limitThrottleIfPressed = false
				limitThrottleRatio     = 0.45 + 0.05 * self.spec_vca.limitThrottle
			else
				limitThrottleIfPressed = true
				limitThrottleRatio     = 1.5 - 0.05 * self.spec_vca.limitThrottle
			end
				
			if self.spec_vca.inchingIsOn == limitThrottleIfPressed then
				acceleration   = acceleration   * limitThrottleRatio
				self.spec_vca.oldAcc = self.spec_vca.oldAcc * limitThrottleRatio
			end
		end
		
		self.spec_vca.useIdleThrottle = false 
		
		if      self.spec_vca.idleThrottle 
				and not doHandbrake
				and self.spec_motorized       ~= nil 
				and self.spec_motorized.motor ~= nil 	
				and self.spec_motorized.motorizedNode ~= nil
				and next(self.spec_motorized.differentials) ~= nil
				then 
			local motor = self.spec_motorized.motor 
			local m = motor.currentDirection
			if self:vcaGetShuttleCtrl() then 
				m = 1 
			end 
			
			local noAutoBrake = false 
			if      motor.gearShiftMode           == VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH
					and motor.manualClutchValue       <  0.9 then 
				noAutoBrake     = true 
			elseif motor.stallTimer               >  0 then 
				noAutoBrake     = true 
			elseif math.abs( self.lastSpeedReal ) >= motor.lowBrakeForceSpeedLimit
					or math.abs( acceleration )       >= 0.001 then 
				noAutoBrake     = true 
			elseif self:vcaGetShuttleCtrl() and lastIdleThrottleTime ~= nil and self.spec_vca.isEnteredMP and not self.spec_vca.isBlocked then 
				self.spec_vca.idleThrottleTime = lastIdleThrottleTime
				if g_currentMission.time < lastIdleThrottleTime then 
					noAutoBrake   = true 
				end 
			end 

			local hasSlippingWheel = false 
			do --if self.lastSpeed > 0.0005 then 
				local f = 1
				if     self.rotatedTime == nil
						or self.minRotTime  == nil
						or self.maxRotTime  == nil then 
				elseif self.rotatedTime < 0 and self.minRotTime < 0 then 
					f = f + 4 * self.rotatedTime / self.minRotTime
				elseif self.rotatedTime > 0 and self.maxRotTime > 0 then 
					f = f + 4 * self.rotatedTime / self.maxRotTime
				end 
				local vehicleSpeed = self.lastSpeed * 1000 + math.max( f * self.lastSpeed * 100, 1 )
				for _,w in pairs( self.spec_wheels.wheels ) do 
					if      w.vcaSpeed   ~= nil 
							and w.vcaNoPower ~= nil 
							and w.vcaNoPower ~= true then 
						local ws = w.vcaSpeed
						if self:vcaGetShuttleCtrl() then 
							if self.spec_motorized.motor.currentDirection < 0 then 
								ws = -ws 
							end 
						else 
							if self.movingDirection < 0 then 
								ws = -ws 
							end 
						end 
						if ws > vehicleSpeed then 
							hasSlippingWheel = true 
						end 
					end 
				end 
			end 
			
			if      self:getIsMotorStarted()
					and ( ( m > 0 and acceleration > -0.01 ) or ( m < 0 and acceleration < 0.01 ) )
					and (motor.backwardGears or motor.forwardGears) 
					and motor.gearRatio ~= 0 
					and motor.maxGearRatio ~= 0 
					and noAutoBrake then

				self.spec_vca.useIdleThrottle  = true 
				self.spec_vca.idleThrottleTime = g_currentMission.time + 2000

				local rpmRange  = motor.maxRpm - motor.minRpm
				local minRpm    = vehicleControlAddon.mbClamp( vehicleControlAddon.origGetMaxPtoRpm( self ) * motor.ptoMotorRpmRatio, motor.minRpm, motor.maxRpm )
				if self.spec_vca.handThrottle > 0 then 
				-- hand throttle overrides PTO RPM
					minRpm        = motor.minRpm + vehicleControlAddon.mbClamp( self.spec_vca.handThrottle, 0, 1 ) * rpmRange
				end 													
				local diffRpm   = motor.differentialRotSpeed * 30 / math.pi
				local motorRpm  = math.abs( diffRpm * motor.gearRatio )
				local clutchRpm = math.abs( diffRpm * motor.maxGearRatio )
				local delta     = vehicleControlAddon.mbClamp( 1 - self.spec_vca.handThrottle, 0, 0.1 )
				
				-- accelerate
				local function getClutchMinAcc()
					if     clutchRpm >= minRpm then 
						return 0 
					elseif delta < 1e-3 then 
						return 1
					else
						return math.min( 1, ( 1 - clutchRpm / minRpm ) / delta )
					end 
				end 
				local function getMotorMaxAcc()
					local maxRpm = 0.95 * minRpm + 0.05 * motor.maxRpm
					if     motorRpm >= maxRpm then 
						return 0 
					elseif motorRpm <= minRpm then 
						return 1 
					else 
						return ( maxRpm - motorRpm ) / ( maxRpm - minRpm )
					end 
				end 
				
				local change = false 
				local acc    = math.abs( acceleration )
				local maxRpm = math.max( minRpm, motor.minRpm + vehicleControlAddon.mbClamp( acc - 0.02, 0.2, 1 ) * rpmRange )
				if 0 < acc and acc < 1 and motorRpm > maxRpm then 
					if motorRpm >= maxRpm + 0.04 * rpmRange then 
					  acc      = 0
					else 
					  acc      = math.min( acc, 1 - 25 * ( motorRpm - maxRpm ) / rpmRange )
					end 
					change     = true 
				end 
				local minAcc = math.min( getClutchMinAcc(), getMotorMaxAcc() )
				if math.abs( self.lastSpeedReal ) < motor.lowBrakeForceSpeedLimit then 
					minAcc     = math.max( 0.0015, minAcc )
				end 
				if acc < minAcc then 
					acc        = minAcc
					change     = true 
				end 

				if change and self.spec_wheels ~= nil and self.spec_wheels.wheels ~= nil and hasSlippingWheel then 
					acc = math.min( acc, minAcc )
				end 
				
				local speed = math.abs( self.lastSpeedReal )
				if 0.01 < speed and speed <= motor.lowBrakeForceSpeedLimit and acc <= 0.0015 then 
					acc    = - math.max( 0.0015, motor.lowBrakeForceScale ) 
					change = true 
				end 
				
				if change then 
					acceleration = m * acc
				end 
			elseif  self:getIsMotorStarted()
					and self:vcaGetShuttleCtrl()
					and acceleration > -0.01 
					and motor.backwardGears == nil and motor.forwardGears == nil  
					and noAutoBrake then
			-- turn off automatic brake in WheelsUtil:updateWheelsPhysics 
			-- you have to push the brake for at least one sceond below lowBrakeForceSpeedLimit, i.e. 3.6 km/h
				self.spec_vca.idleThrottleTime = g_currentMission.time + 1000
				local speed = math.abs( self.lastSpeedReal )
				if 0.01 < speed and speed <= motor.lowBrakeForceSpeedLimit and math.abs( acceleration ) <= 0.0015 then 
					acceleration = - math.max( 0.0015, motor.lowBrakeForceScale )
				end 
			end 
			
			if      self:getIsMotorStarted()
					and ( ( m > 0 and acceleration > -0.01 ) or ( m < 0 and acceleration < 0.01 ) )
					and self.spec_vca.antiSlip
					and noAutoBrake then
				if lastAccAntiSlip == nil then 
					lastAccAntiSlip = 1
				end 
				--local lastAccAntiSlip = self.spec_vca.maxAccAntiSlip
				if hasSlippingWheel then 
					self.spec_vca.maxAccAntiSlip = math.max( 0.1, lastAccAntiSlip - 0.001 * dt )
				else 
					self.spec_vca.maxAccAntiSlip = math.min( 1.0, lastAccAntiSlip + 0.001 * dt )
				end 
				if m > 0 then 
					acceleration = math.min( acceleration, self.spec_vca.maxAccAntiSlip )
				else 
					acceleration = math.min( acceleration, -self.spec_vca.maxAccAntiSlip )
				end 
			end 
		end
	end 
	
	self.spec_vca.newAcc       = acceleration
	self.spec_vca.newHandbrake = doHandbrake
	
	local state, result = pcall( superFunc, self, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking ) 
	if not ( state ) then
		print("Error in updateWheelsPhysics :"..tostring(result))
		return 
	end
	
	return result 
end 
WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction( WheelsUtil.updateWheelsPhysics, vehicleControlAddon.vcaUpdateWheelsPhysics )
--******************************************************************************************************************************************
function vehicleControlAddon:vcaGetSmoothedAccBrake( superFunc, acceleratorPedal, brakePedal, dt )
	if      self          ~= nil 
			and self.spec_vca ~= nil 
			and self.spec_vca.isInitialized
			and self:vcaIsVehicleControlledByPlayer()
			and next(self.spec_motorized.differentials) ~= nil
			and ( self.spec_vca.handbrake 
				or  self.spec_vca.isBlocked 
				or  ( self.spec_vca.ksIsOn and math.abs( self.spec_vca.keepSpeed ) < 0.5 ) )
			then 
		return superFunc( self, 0, 1, dt )
	end 
	return superFunc( self, acceleratorPedal, brakePedal, dt )
end 
WheelsUtil.getSmoothedAcceleratorAndBrakePedals = Utils.overwrittenFunction( WheelsUtil.getSmoothedAcceleratorAndBrakePedals, vehicleControlAddon.vcaGetSmoothedAccBrake )

--******************************************************************************************************************************************
function vehicleControlAddon.vcaMotorGetSpeedLimit( motor, superFunc, ... )
	local self  = motor.vehicle 
	local limit = superFunc( motor, ... )
	
	
	if self ~= nil and self.spec_vca ~= nil then 
		if      self.spec_vca.speedLimiter 
				and self:vcaIsVehicleControlledByPlayer()
				and self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF
				and not self.spec_vca.ksIsActive then 
			limit = math.min( limit, self.spec_drivable.cruiseControl.speed )
		end
		if self.spec_vca.wheelSlip ~= nil then 
			limit = self.spec_vca.wheelSlip * limit
		end 
	end 
	return limit
end 
VehicleMotor.getSpeedLimit = Utils.overwrittenFunction( VehicleMotor.getSpeedLimit, vehicleControlAddon.vcaMotorGetSpeedLimit )

--******************************************************************************************************************************************
function vehicleControlAddon.vcaGetManualClutchPedal( motor, superFunc, ... )
	local self = motor.vehicle 
	if      self          ~= nil 
			and self.spec_vca ~= nil 
			and self.spec_vca.isInitialized
			and self:vcaIsVehicleControlledByPlayer()
			and next(self.spec_motorized.differentials) ~= nil
			and ( self.spec_vca.handbrake 
				or  self.spec_vca.isBlocked 
				or  ( self.spec_vca.ksIsOn and math.abs( self.spec_vca.keepSpeed ) < 0.5 ) )
			then 
		return 1
	end 
	return superFunc( motor, ... )
end 
VehicleMotor.getManualClutchPedal = Utils.overwrittenFunction( VehicleMotor.getManualClutchPedal, vehicleControlAddon.vcaGetManualClutchPedal )

--******************************************************************************************************************************************
--******************************************************************************************************************************************
function vehicleControlAddon:getCruiseControlState( superFunc )
	if self.spec_vca ~= nil and self.spec_vca.ksIsOn and math.abs( self.spec_vca.keepSpeed ) >= 0.5 then  
		return Drivable.CRUISECONTROL_STATE_ACTIVE 
	end 
	return superFunc( self )
end 
Drivable.getCruiseControlState = Utils.overwrittenFunction( Drivable.getCruiseControlState, vehicleControlAddon.getCruiseControlState )


function vehicleControlAddon:newActionEventCruiseControlState( superFunc, actionName, inputValue, callbackState, isAnalog )
	if self.spec_vca ~= nil and self.spec_vca.isEntered then 
		self.spec_vca.cruiseControlStateIsPressed = true
		self.spec_drivable.lastInputValues.cruiseControlState = 0
		return 
	end 
	
	superFunc( self, actionName, inputValue, callbackState, isAnalog )
end 
Drivable.actionEventCruiseControlState = Utils.overwrittenFunction( Drivable.actionEventCruiseControlState, vehicleControlAddon.newActionEventCruiseControlState )

function vehicleControlAddon:getCruiseControlSpeed( superFunc )
	if      self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF
			and self.spec_vca ~= nil 
			and self.spec_vca.ksIsOn 
			and math.abs( self.spec_vca.keepSpeed ) >= 0.5 then  
		return self.spec_vca.keepSpeed
	end 
	return superFunc( self )
end 
Drivable.getCruiseControlSpeed = Utils.overwrittenFunction( Drivable.getCruiseControlSpeed, vehicleControlAddon.getCruiseControlSpeed ) 

function vehicleControlAddon:getAccelerationAxis( superFunc )
	if self.spec_vca ~= nil and self.spec_vca.handThrottle > 0 then 
		return math.max( superFunc( self ), self.spec_vca.handThrottle )
	end 
	return superFunc( self )
end 
Drivable.getAccelerationAxis   = Utils.overwrittenFunction( Drivable.getAccelerationAxis,   vehicleControlAddon.getAccelerationAxis )

function vehicleControlAddon:getCruiseControlAxis( superFunc )
	if      self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_OFF
			and self.spec_vca ~= nil 
			and self.spec_vca.ksIsOn 
			and math.abs( self.spec_vca.keepSpeed ) >= 0.5 then  
		return 1
	end 
	return superFunc( self )
end 
Drivable.getCruiseControlAxis  = Utils.overwrittenFunction( Drivable.getCruiseControlAxis,  vehicleControlAddon.getCruiseControlAxis )

--******************************************************************************************************************************************
--******************************************************************************************************************************************


function vehicleControlAddon:vcaIsHydraulicSamplePlaying()
	if self == nil then 
		return false 
	end 
	
	if self.spec_cylindered ~= nil then 
		local spec = self.spec_cylindered
		if spec.movingToolNeedsSound or spec.movingPartNeedsSound then 
			return true 
		end 
	end 
	
	if self.spec_foldable ~= nil and self.spec_foldable.foldAnimTime ~= nil then 
		local spec = self.spec_foldable
		if 0.01 < spec.foldAnimTime and spec.foldAnimTime < 0.99 and ( spec.foldMiddleAnimTime == nil or math.abs( spec.foldAnimTime - spec.foldMiddleAnimTime ) > 0.01 ) then 
			return true 
		end 
	end 
	
	if self.spec_dischargeable ~= nil then
		local spec = self.spec_dischargeable
		if     spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_OBJECT
				or spec.currentDischargeState == Dischargeable.DISCHARGE_STATE_GROUND then 
			return true
		end 
	end 
	
	if self.spec_trailer ~= nil then
		local spec = self.spec_trailer
		if self.spec_trailer.tipState == Trailer.TIPSTATE_OPENING then
			return true
		end 	
	end 	
	
	if self.spec_attacherJoints ~= nil and type( self.spec_attacherJoints.attachedImplements ) == "table" then  
		local spec = self.spec_attacherJoints
		for _,implement in pairs( self.spec_attacherJoints.attachedImplements ) do 
			local jointDesc = spec.attacherJoints[implement.jointDescIndex]
			
			if jointDesc == nil or implement.object == nil then 
				return false 
			end 
			
			if      not implement.object.spec_attachable.isHardAttached
					and not implement.attachingIsInProgress 
					and jointDesc ~= nil 
					and jointDesc.allowsLowering and self:getIsActive()
					and not jointDesc.moveDown 
					and math.abs(jointDesc.moveAlpha - jointDesc.upperAlpha) > 0.05 then 
				return true 
			elseif vehicleControlAddon.vcaIsHydraulicSamplePlaying( implement.object ) then 
				return true 
			end 
		end 
	end 
	
	return false 
end 

--******************************************************************************************************************************************
-- hand RPM via PowerConsumer.getMaxPtoRpm (only in neutral)
vehicleControlAddon.origGetMaxPtoRpm = PowerConsumer.getMaxPtoRpm
PowerConsumer.getMaxPtoRpm = function ( self, ... )
	if     self.spec_vca              == nil
			or self.spec_motorized        == nil 
			or self.spec_motorized.motor  == nil 
			or not self.spec_vca.isInitialized 
			or self.spec_motorized.motor.ptoMotorRpmRatio == nil
			or self.spec_motorized.motor.ptoMotorRpmRatio <= 0
			then 
		return vehicleControlAddon.origGetMaxPtoRpm( self, ... )
	end 
	
	if self.spec_vca.useIdleThrottle then 
	-- do not increase RPM while driving
		return 0 
	end 
	
	local motor = self.spec_motorized.motor 
	
	local r0 = vehicleControlAddon.origGetMaxPtoRpm( self, ... )
	
	if self.spec_vca.handbrake and self.spec_vca.oldAcc ~= nil and self.spec_vca.oldAcc > 0 then 
		r0 = math.max( r0, ( motor.minRpm + self.spec_vca.oldAcc * ( motor.maxRpm - motor.minRpm ) ) / motor.ptoMotorRpmRatio )
	end 

	local r1 = r0
	
	if self.spec_vca.handThrottle > 0 then
	-- hand throttle overrides PTO RPM
		r1 = ( motor.minRpm + vehicleControlAddon.mbClamp( self.spec_vca.handThrottle, 0, 1 ) * ( motor.maxRpm - motor.minRpm ) ) / motor.ptoMotorRpmRatio
	elseif self.spec_vca.idleThrottle and vehicleControlAddon.vcaIsHydraulicSamplePlaying( self ) then 
	-- extra RPM for hydraulics
		r1 = math.max( r0, ( motor.minRpm + 0.2 * ( motor.maxRpm - motor.minRpm ) ) / motor.ptoMotorRpmRatio )
	end 
	
	return r1
end 

--******************************************************************************************************************************************
-- limit maxRpm in case of inching 
function vehicleControlAddon:vcaGetRequiredMotorRpmRange( superFunc, ... )
	local lastIncreaseRpm = -1 
	if self.vcaIncreaseRpm ~= nil then 
		lastIncreaseRpm = self.vcaIncreaseRpm
	end 
	local lastMinRpm = self.minRpm 
	if self.vcaMinRpm ~= nil then 
		lastMinRpm = self.vcaMinRpm
	end 
	local lastMaxRpm = self.maxRpm
	if self.vcaMaxRpm ~= nil then 
		lastMaxRpm = self.vcaMaxRpm
	end 
	local lastSpeedFactor = self.vcaSpeedFactor
	
	self.vcaIncreaseRpm = nil 
	self.vcaMinRpm      = nil 
  self.vcaMaxRpm      = nil 
	self.vcaSpeedFactor = nil 


	if not ( self.vehicle ~= nil 
			 and self.vehicle.spec_vca ~= nil 
			 and self.vehicle.spec_vca.idleThrottle
			 and self.vehicle.spec_vca.oldAcc ~= nil
			 and self.vehicle.spec_vca.tickDt ~= nil
			 and self.currentDirection ~= nil 
			 and self.manualClutchValue < 0.1
			 and next(self.vehicle.spec_motorized.differentials) ~= nil
			) then 
		return superFunc( self, ... )
	end 
	
	local m = 1
	if not self.vehicle:vcaGetShuttleCtrl() and self.currentDirection < 0 then 
		m = -1 
	end 
	local curAcc = math.max( 0, m * self.vehicle.spec_vca.oldAcc )
	local curBrake = math.max( 0, -m * self.vehicle.spec_vca.oldAcc )
	
	local rpmRange = self.maxRpm - self.minRpm
	local minRpm, maxRpm = self.minRpm, self.maxRpm
	local motorPtoRpm = math.min(PowerConsumer.getMaxPtoRpm(self.vehicle) * self.ptoMotorRpmRatio, self.maxRpm)
	
	local speed = self.vehicle:getLastSpeed()

	lastMinRpm = vehicleControlAddon.mbClamp( lastMinRpm, minRpm, maxRpm )
	lastMaxRpm = vehicleControlAddon.mbClamp( lastMaxRpm, minRpm, maxRpm )
	
	if self.backwardGears or self.forwardGears or self.vehicle.spec_vca.useIdleThrottle then  
		-- standard transmission 
		maxRpm = self.maxRpm 
		if motorPtoRpm > self.minRpm and not self.vehicle.spec_vca.useIdleThrottle then 
			-- increase RPM in neutral
			minRpm = motorPtoRpm
		end 
	else
		-- variable transmission
		
		local function getRequiredRpmAtSpeedLimit(ratio)
			local speedLimit = math.min(self.vehicle:getSpeedLimit(true), self.vehicle.lastSpeedReal * 3600 + 1 )

			if self.vehicle:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_ACTIVE then
				speedLimit = math.min(speedLimit, self.vehicle:getCruiseControlSpeed())
			end

			speedLimit = ratio > 0 and math.min(speedLimit, self.maxForwardSpeed * 3.6) or math.min(speedLimit, self.maxBackwardSpeed * 3.6)

			return speedLimit / 3.6 * 30 / math.pi * math.abs(ratio)
		end			
					
		local speedMinRpm  = getRequiredRpmAtSpeedLimit( self.minGearRatio )
		local peakPowerRpm = self.peakMotorPowerRotSpeed * 30 / math.pi

		if motorPtoRpm > self.minRpm then 
			-- variable transmission and fixed RPM 
			if self.smoothedLoadPercentage > 0.9 then 	
				-- reduce maxRpm under full load
				local f = 10 * self.smoothedLoadPercentage - 9
				motorPtoRpm = motorPtoRpm - 0.07 * f * rpmRange 
				maxRpm = vehicleControlAddon.mbClamp( math.max( motorPtoRpm + 0.07 * rpmRange, speedMinRpm ), self.minRpm, self.maxRpm )
			end 
			minRpm = vehicleControlAddon.mbClamp( motorPtoRpm, self.minRpm, self.maxRpm )
		else 
			-- variable transmission and variable RPM; e.g. Fendt TMS
	
			local idleRpm = math.min( math.max( minRpm, self.minRpm + 0.1 * rpmRange ), maxRpm )

			if self.vehicle.spec_combine ~= nil then 
				-- increase RPM for combine
				if     speed  > 2   then 
					-- not stopped => increase RPM
					self.vcaIncreaseRpm = math.max( lastIncreaseRpm, g_currentMission.time + 5000 )
				elseif curAcc > 0.1 then 
					-- accelerating => increase RPM for a short time 
					self.vcaIncreaseRpm = math.max( lastIncreaseRpm, g_currentMission.time + 2000 )
				elseif lastIncreaseRpm > g_currentMission.time then 
					self.vcaIncreaseRpm = lastIncreaseRpm
				end 

				idleRpm = math.min( math.max( minRpm, self.minRpm + 0.6 * rpmRange ), maxRpm )
			else
				if speed  > 2   then 
					-- not stopped => increase RPM
					self.vcaIncreaseRpm = math.max( lastIncreaseRpm, g_currentMission.time + 2000 )
				elseif curAcc > 0.1 then 
					-- accelerating => increase RPM 
					self.vcaIncreaseRpm = math.max( lastIncreaseRpm, g_currentMission.time + 1000 )
				elseif lastIncreaseRpm > g_currentMission.time then 
					self.vcaIncreaseRpm = lastIncreaseRpm
				end 
			end 
			
			local function vehicleHasActiveWorkArea( self )
				if self.spec_turnOnVehicle ~= nil and self.spec_turnOnVehicle.isTurnedOn then 
					return true 
				end
				if self.spec_workArea ~= nil and type( self.spec_workArea.workAreas ) == "table" then 
					for _,w in pairs( self.spec_workArea.workAreas ) do 
						if self:getIsWorkAreaActive(w) then 	
							return true 
						end 
					end 
				end 
				if self.spec_attacherJoints ~= nil and type( self.spec_attacherJoints.attachedImplements ) == "table" then 
					for _,implement in pairs( self.spec_attacherJoints.attachedImplements ) do 
						if implement.object ~= nil and vehicleHasActiveWorkArea( implement.object ) then 
							return true 
						end 
					end 
				end 
				return false 
			end 
			
			local hasActiveWorkArea = false 
			if vehicleHasActiveWorkArea( self.vehicle ) then 
				hasActiveWorkArea     = true 
				self.vcaActiveWATimer = g_currentMission.time + 1000
			elseif self.vcaActiveWATimer == nil then 
			elseif g_currentMission.time < self.vcaActiveWATimer then 
				hasActiveWorkArea     = true 
			else 
				self.vcaActiveWATimer = nil 
			end 	
		
			if hasActiveWorkArea then 
				idleRpm = math.min( math.max( minRpm, self.minRpm + 0.4 * rpmRange ), maxRpm )
			end 		
			if self.smoothedLoadPercentage > 0.8 then 	
				idleRpm = math.min( maxRpm,math.max( minRpm, idleRpm, peakPowerRpm - 0.1 * rpmRange ) )
			end 
			
			if self.smoothedLoadPercentage > 0.9 then 	
			-- reduce maxRpm under full load
				local f = 10 * self.smoothedLoadPercentage - 9
				maxRpm  = math.min( maxRpm,math.max( minRpm, idleRpm, peakPowerRpm - 0.1 * f * rpmRange, speedMinRpm ) )
			else
				local r = self.maxRpm 
				if self.smoothedLoadPercentage < 0.7 then 
				-- reduce maxRpm for best efficiency
					r = speedMinRpm
				end 
				maxRpm = math.min( maxRpm, math.max( minRpm, idleRpm + 0.1 * rpmRange, r ) )
			end 
			
			if self.vcaIncreaseRpm ~= nil and g_currentMission.time < self.vcaIncreaseRpm then 
				minRpm = math.max( minRpm, math.min( idleRpm, maxRpm ) )
			end		
		end 
	end 
	
	local r = nil 
	if self.vehicle.lastSpeedReal > 0.001 then 
		local sf = self:getNonClampedMotorRpm() / self.vehicle.lastSpeedReal
		if lastSpeedFactor == nil then 
			self.vcaSpeedFactor = sf 
		else 
			self.vcaSpeedFactor = lastSpeedFactor + 0.01 * ( sf - lastSpeedFactor )
			r = self.vcaSpeedFactor * self.vehicle.lastSpeedReal
		end 
	end 
	
	local smooth = self.vehicle.spec_vca.tickDt * rpmRange
	if self.backwardGears or self.forwardGears or self.vehicle.spec_vca.useIdleThrottle then  
		smooth = smooth * 0.0005
	else 
		smooth = smooth * 0.0001
		if r ~= nil then 
			local m1, m2 = minRpm, maxRpm
			minRpm = math.max( m1, math.min( self:getNonClampedMotorRpm() - self.vehicle.spec_vca.tickDt * 0.00025 * rpmRange, r, m2 ) )
			maxRpm = math.min( m2, math.max( self:getNonClampedMotorRpm() + self.vehicle.spec_vca.tickDt * 0.00025 * rpmRange, r, m1 ) )
		end 
	end 
	
	if r == nil then 
		minRpm = vehicleControlAddon.mbClamp( minRpm, lastMinRpm - smooth, lastMinRpm + smooth )
		maxRpm = vehicleControlAddon.mbClamp( maxRpm, lastMaxRpm - smooth, lastMaxRpm + smooth )
	else 
		minRpm = vehicleControlAddon.mbClamp( minRpm, math.min( lastMinRpm - smooth, r ), lastMinRpm + smooth )
		maxRpm = vehicleControlAddon.mbClamp( maxRpm, lastMaxRpm - smooth, math.max( lastMaxRpm + smooth, r ) )
	end 
	
	self.vcaMinRpm = minRpm 
	self.vcaMaxRpm = maxRpm 
	
	return minRpm, maxRpm
end

VehicleMotor.getRequiredMotorRpmRange = Utils.overwrittenFunction( VehicleMotor.getRequiredMotorRpmRange, vehicleControlAddon.vcaGetRequiredMotorRpmRange )

--******************************************************************************************************************************************

function vehicleControlAddon:vcaGetGearToDisplay( superFunc )
	if      self.vehicle          ~= nil        
			and self.vehicle.spec_vca ~= nil 
			and self.vehicle.spec_vca.handbrake 
			then 
		if self.backwardGears or self.forwardGears then
			return "P", false, false, nil, nil, nil, nil, false 
		else 
			return "P", false, false, "R", "D", nil, nil, false 
		end 
	end
	return superFunc( self )
end 

VehicleMotor.getGearToDisplay = Utils.overwrittenFunction( VehicleMotor.getGearToDisplay, vehicleControlAddon.vcaGetGearToDisplay )

--******************************************************************************************************************************************
--
function vehicleControlAddon:vcaGetLastModulatedMotorRpm( superFunc, ... )
	if not ( self.vehicle ~= nil 
			 and self.vehicle.spec_vca ~= nil 
			 and self.vehicle.spec_vca.idleThrottle
			 and self.lastRealMotorRpm ~= nil 
			 and (self.backwardGears or self.forwardGears)
			 and next(self.vehicle.spec_motorized.differentials) ~= nil
			) then 
		return superFunc( self, ... )
	end 
	return self.lastRealMotorRpm
end 

VehicleMotor.getLastModulatedMotorRpm = Utils.overwrittenFunction( VehicleMotor.getLastModulatedMotorRpm, vehicleControlAddon.vcaGetLastModulatedMotorRpm )

--******************************************************************************************************************************************
-- overwrite automatic shifting to make it local per vehicle
vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGearShifting = VehicleMotor.getUseAutomaticGearShifting
VehicleMotor.getUseAutomaticGearShifting = function( self, ... )
	if vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGearShifting( self, ... ) then 
		return true 
	end 
	
	if      self.vehicle          ~= nil	
			and self.vehicle.spec_vca ~= nil 
			and self.vehicle.spec_vca.isInitialized
			and self.vehicle.spec_vca.autoShift then 
		return true 
	end 
	return vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGearShifting( self, ... )
end 
--******************************************************************************************************************************************

vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGroupShifting = VehicleMotor.getUseAutomaticGroupShifting
VehicleMotor.getUseAutomaticGroupShifting = function ( self, ... )
	if vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGroupShifting( self, ... ) then 
		return true 
	end 
	
	if      self.vehicle          ~= nil	
			and self.vehicle.spec_vca ~= nil 
			and self.vehicle.spec_vca.isInitialized
			and self.vehicle.spec_vca.autoShift then 
		return true 
	end 
	return vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGroupShifting( self, ... )
end 
--******************************************************************************************************************************************
function vehicleControlAddon:vcaGetGearRatioMultiplier( superFunc, ... )
	if      self.vehicle          ~= nil	
			and self.vehicle.spec_vca ~= nil 
			and self.vehicle.spec_vca.isInitialized
			and self.vehicle.spec_vca.splitGears > 0 
			and self.vehicle.spec_vca.gearSplitGear <= self.vehicle.spec_vca.splitGears
			then 
		local r = superFunc( self, ... )
		local g = self.vehicle.spec_vca.gearSplitGear
		local q = vehicleControlAddon.splitGearRatios[self.vehicle.spec_vca.splitGearRatio]
		if q == nil then q = 0.8 end 
		while g <= self.vehicle.spec_vca.splitGears do 
			r = r / q
			g = g + 1 
		end 
		return r
	end 
	return superFunc( self, ... )
end 

VehicleMotor.getGearRatioMultiplier = Utils.overwrittenFunction( VehicleMotor.getGearRatioMultiplier, vehicleControlAddon.vcaGetGearRatioMultiplier )
--******************************************************************************************************************************************

function vehicleControlAddon:vcaOnSetSnapAngle( old, new, noEventSend )
	if new < 1 then 
		self.spec_vca.snapAngle = 1 
	elseif new > table.getn( vehicleControlAddon.snapAngles ) then 
		self.spec_vca.snapAngle = table.getn( vehicleControlAddon.snapAngles ) 
	else 
		self.spec_vca.snapAngle = new 
	end 
end 

function vehicleControlAddon:vcaOnSetSnapIsOn( old, new, noEventSend )
	self.spec_vca.snapIsOn = new 
	
  if      ( old == nil or new ~= old ) then 
		if self.isClient and self:vcaIsActive() then
			if new and vehicleControlAddon.snapOnSample ~= nil then
				playSample(vehicleControlAddon.snapOnSample, 1, 0.2, 0, 0, 0)
			elseif not new and vehicleControlAddon.snapOffSample ~= nil then
				playSample(vehicleControlAddon.snapOffSample, 1, 0.2, 0, 0, 0)
			end 
		end 
		
		if self.isServer and new and self.spec_vca.snapDistance < 0.1 then
			local d, o, p = self:vcaGetSnapDistance()
			if d < 0.1 then 
				d = 1
				o = 0
				p = false 
			end 
			self:vcaSetState( "snapDistance", d, noEventSend )
			self:vcaSetState( "snapOffset", o, noEventSend )
			self:vcaSetState( "snapInvert", p, noEventSend )
		end
	elseif new and self.isClient and self:vcaIsActive() and vehicleControlAddon.snapOnSample ~= nil then
		playSample(vehicleControlAddon.snapOnSample, 1, 0.2, 0, 0, 0)
	end 
end 

function vehicleControlAddon:vcaOnSetKSIsOn( old, new, noEventSend )
	self.spec_vca.ksIsOn = new 
end 

function vehicleControlAddon:vcaOnSetLastSnapAngle( old, new, noEventSend )
	self.spec_vca.lastSnapAngle = new 
end 


function vehicleControlAddon:vcaOnSetWarningText( old, new, noEventSend )
	self.spec_vca.warningText  = new
  self.spec_vca.warningTimer = 4000
end

function vehicleControlAddon:vcaOnSetSplitGears( old, new, noEventSend )
	if type( new ) == "number" and 0 <= new and new <= 3 then  
		self.spec_vca.splitGears = new 
	else 
		self.spec_vca.splitGears = 0 
	end 
	
	self:vcaSetState( "gearSplitGear", self.spec_vca.splitGears + 1, noEventSend )
end 

function vehicleControlAddon:vcaOnSetSplitGearRatio( old, new, noEventSend )
	if type( new ) == "number" and vehicleControlAddon.splitGearRatios[new] ~= nil then 
		self.spec_vca.splitGearRatio = new 
	else 
		self.spec_vca.splitGearRatio = 1 
	end 

	if      self.spec_vca.isInitialized 
			and self.spec_vca.splitGears > 0
			and self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil
			and self.spec_motorized.motor.currentGears ~= nil then 
		self.spec_motorized.motor:applyTargetGear()
	end 
end 

function vehicleControlAddon:vcaOnSetGearSplitGear( old, new, noEventSend )
	g = math.max( 1, Utils.getNoNil( self.spec_vca.splitGears, 0 ) + 1 )
	if type( new ) ~= "number" or new < 1 then  
		self.spec_vca.gearSplitGear = 1
	elseif new > g then 
		self.spec_vca.gearSplitGear = g
	else 
		self.spec_vca.gearSplitGear = new 
	end 
	
	if      old ~= nil
			and new ~= nil 
			and old ~= new 
			and self.spec_vca.isInitialized 
			and self.spec_vca.splitGears > 0
			and self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil
			and self.spec_motorized.motor.currentGears ~= nil then 
			
		self.spec_motorized.motor:applyTargetGear()
		
		if new > old then 
			self.spec_motorized.motor.loadPercentageChangeCharge = 1
		end 
		
		if self.isClient and not g_soundManager:getIsSamplePlaying(self.spec_motorized.samples.gearGroupChange) then
			g_soundManager:playSample(self.spec_motorized.samples.gearGroupChange)
		end
	end 
end 

function vehicleControlAddon:vcaGetAbsolutRotY( camIndex )
	if     self.spec_enterable.cameras == nil
			or self.spec_enterable.cameras[camIndex] == nil then
		return 0
	end
  return vehicleControlAddon.vcaGetRelativeYRotation( self.spec_enterable.cameras[camIndex].cameraNode, self:vcaGetSteeringNode() )
end

function vehicleControlAddon.vcaGetRelativeYRotation(root,node)
	if root == nil or node == nil then
		return 0
	end
	local x, y, z = worldDirectionToLocal(node, localDirectionToWorld(root, 0, 0, 1))
	local dot = z
	local len = 0
	if math.abs( z ) < 1e-6 then 
		len = math.abs( x )
	elseif math.abs( x ) < 1e-6 then 
		len = math.abs( z ) 
	else 
		len = math.sqrt( x*x + z*z )
	end 
	dot = dot / len
	local angle = math.acos(dot)
	if x < 0 then
		angle = -angle
	end
	return angle
end

function vehicleControlAddon.vcaSpeedInt2Ext( speed )
	if not ( type( speed ) == "number" ) then 
		return -1
	end 
	local s = speed * 3.6 
	if g_gameSettings.useMiles then 
		s = s * 0.621371
	end 
	return s --0.1 * math.floor( 10 * s + 0.5 )
end 
function vehicleControlAddon.vcaSpeedExt2Int( speed )
	if not ( type( speed ) == "number" ) then 
		return -1
	end 
	local s = speed / 3.6 
	if g_gameSettings.useMiles then 
		s = s / 0.621371
	end 
	return s
end 
function vehicleControlAddon:vcaSpeedToString( speed, numberFormat, noUnit )
	if speed == nil then	
		return "nil" 
	end 
	local s = vehicleControlAddon.vcaSpeedInt2Ext( speed )
	local f = numberFormat
	if f == nil then 
		if     math.abs( s ) < 0.995 then 
			f = "%4.2f"
		elseif math.abs( s ) < 9.95 then 
			f = "%3.1f" 
		else 
			f = "%3.0f"
		end 
	end 
	if noUnit then 
		return string.format( f, s )
	end 
	local u = "km/h" 
	if g_gameSettings.useMiles then 
		u = "mph"
	end 
	return string.format( f, s ).." "..u 	
end 


function vehicleControlAddon:vcaShowSettingsUI()

	if g_gui:getIsGuiVisible() then
		return 
	end

	self.spec_vcaUI = {}
	
	self.spec_vcaUI.steeringIsOn  = { vehicleControlAddon.getText("vcaValueOff", "OFF"), 
																		vehicleControlAddon.getText("vcaValueStrong", "STRONG"), 
																		vehicleControlAddon.getText("vcaValueLight", "LIGHT"), 
																	}
	
	self.spec_vcaUI.camRotInside  = { vehicleControlAddon.getText("vcaValueOff", "OFF"), 
																		vehicleControlAddon.getText("vcaValueLight", "LIGHT"), 
																		vehicleControlAddon.getText("vcaValueNormal", "NORMAL"), 
																		vehicleControlAddon.getText("vcaValueStrong", "STRONG"), 
																	}
	self.spec_vcaUI.camRotOutside   = self.spec_vcaUI.camRotInside																
	self.spec_vcaUI.limitThrottle   = {}
	self.spec_vcaUI.snapRight = { }
	for i=1,20 do
	  self.spec_vcaUI.limitThrottle[i] = string.format("%3d %% / %3d %%", 45 + 5 * math.min( i, 11 ), 150 - 5 * math.max( i, 10 ), true )
		self.spec_vcaUI.snapRight[i] = tostring(i)
	end
	self.spec_vcaUI.snapAngle = {}
	for i,v in pairs( vehicleControlAddon.snapAngles ) do 
		self.spec_vcaUI.snapAngle[i] = string.format( "%3d°", v )
	end 
	self.spec_vcaUI.snapLeft  = self.spec_vcaUI.snapRight
	
	self.spec_vcaUI.brakeForce_V = { 0, 0.01, 0.02, 0.05, 0.10, 0.15, 0.2, 0.25, 0.4, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2 }
	self.spec_vcaUI.brakeForce = {}
	for i,e in pairs( self.spec_vcaUI.brakeForce_V ) do
		self.spec_vcaUI.brakeForce[i] = string.format("%3.0f %%", 100 * e )
	end
	
	self.spec_vcaUI.snapDraw = { vehicleControlAddon.getText("vcaValueNever", "NEVER"), 
														 vehicleControlAddon.getText("vcaValueInactive", "INACTIVE"), 
														 vehicleControlAddon.getText("vcaValueAlways", "ALWAYS"), 
														 vehicleControlAddon.getText("vcaValueInactiveH", "INACTIVE HIGH"), 
														 vehicleControlAddon.getText("vcaValueAlwaysH", "ALWAYS HIGH"), 
													 }
	
	if self.spec_vca.snapDistance < 0.1 then
		local d, o, p = self:vcaGetSnapDistance()
		self:vcaSetState( "snapDistance", d )
		self:vcaSetState( "snapOffset", o )
		self:vcaSetState( "snapInvert", p )
	end	
	
	if g_vehicleControlAddonMenu ~= nil then 
		if g_vehicleControlAddonMenu.vcaElements.diffManual ~= nil then 
			local disabled = false 
			if not self.spec_vca.diffHasF and not self.spec_vca.diffHasM and not self.spec_vca.diffHasB then 
				disabled = true 
			end 
			g_vehicleControlAddonMenu.vcaElements.diffManual.element:setDisabled( disabled )
		end 
		
		if g_vehicleControlAddonMenu.vcaElements.diffFrontAdv ~= nil then 
			g_vehicleControlAddonMenu.vcaElements.diffFrontAdv.element:setDisabled( not self.spec_vca.diffHasM )
		end 
		
		if g_vehicleControlAddonMenu.vcaElements.diffLockSwap ~= nil then 
			local disabled = false 
			if not self.spec_vca.diffHasF and not self.spec_vca.diffHasM and not self.spec_vca.diffHasB then 
				disabled = true 
			end 
			g_vehicleControlAddonMenu.vcaElements.diffLockSwap.element:setDisabled( disabled )
		end 
	end 
	
	self.spec_vcaUI.splitGears    = { vehicleControlAddon.getText("vcaValueOff", "OFF"), "Lo / HI", "Lo / Me / Hi", "I, II, III, IV" }
	self.spec_vcaUI.splitGearRatio = {} 
	for i,e in pairs( vehicleControlAddon.splitGearRatios ) do
		self.spec_vcaUI.splitGearRatio[i] = string.format("%2.0f %%", 100 * e )
	end

	
	self.spec_vcaUI.gearShiftTime = { string.format("%4d ms (d)",Utils.getNoNil( self.spec_vca.origGearShiftTime, Utils.getNoNil( self.spec_motorized.motor.gearChangeTimeOrig, 0 ) ) ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[1] ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[2] ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[3] ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[4] ) }
	self.spec_vcaUI.grpShiftTime  = { string.format("%4d ms (d)",Utils.getNoNil( self.spec_vca.origGrpShiftTime, Utils.getNoNil( self.spec_motorized.motor.groupChangeTime, 0 ) ) ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[1] ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[2] ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[3] ),
																		string.format("%4d ms",vehicleControlAddon.shiftTimes[4] ) }
	
	g_gui:showDialog( "vehicleControlAddonMenu", true )	
end

function vehicleControlAddon:vcaUIGetsteeringIsOn()
	if     self.spec_vca.steeringIsOn == nil then 
		return 1
	elseif self.spec_vca.steeringIsOn == vehicleControlAddon.steeringTrue then 
		return 2
	elseif self.spec_vca.steeringIsOn == vehicleControlAddon.steeringSoft then 
		return 3
	end
	return 1
end

function vehicleControlAddon:vcaUISetsteeringIsOn( value )
	if     value == 2 then 
		self:vcaSetState( "steeringIsOn", vehicleControlAddon.steeringTrue)
	elseif value == 3 then 
		self:vcaSetState( "steeringIsOn", vehicleControlAddon.steeringSoft)
	else 
		self:vcaSetState( "steeringIsOn", vehicleControlAddon.steeringFalse)
	end 
end 

function vehicleControlAddon:vcaUIGetbrakeForce()
	local d = 2
	local j = 4
	for i,e in pairs( self.spec_vcaUI.brakeForce_V ) do
		if math.abs( e - self.spec_vca.brakeForce ) < d then
			d = math.abs( e - self.spec_vca.brakeForce )
			j = i
		end
	end
	return j
end

function vehicleControlAddon:vcaUISetbrakeForce( value )
	if self.spec_vcaUI.brakeForce_V[value] ~= nil then
		self:vcaSetState( "brakeForce", self.spec_vcaUI.brakeForce_V[value] )
	end
end

function vehicleControlAddon:vcaUIGetsnapDistance()
	return vehicleControlAddon.formatNumber( self.spec_vca.snapDistance )
end 
function vehicleControlAddon:vcaUISetsnapDistance( value )
	local v = tonumber( value )
	if value == "" then 
		v = 0 
	end 
	if type( v ) == "number" then 
		if v < 0.1 then 
			local d, o, p = self:vcaGetSnapDistance()
			self:vcaSetState( "snapDistance", d )
			self:vcaSetState( "snapOffset", o )
			self:vcaSetState( "snapInvert", p )
		else 
			self:vcaSetState( "snapDistance", v )
		end 
	end 
end 

function vehicleControlAddon:vcaUIGetsnapOffset()
	return vehicleControlAddon.formatNumber( self.spec_vca.snapOffset )
end 
function vehicleControlAddon:vcaUISetsnapOffset( value )
	local v = tonumber( value )
	if type( v ) == "number" then 
		self:vcaSetState( "snapOffset", v )
	end 
end 

function vehicleControlAddon:vcaUIGetsnapLeft()
	if     self.spec_vca.snapLeft <=  1 then 
		return 1 
	elseif self.spec_vca.snapLeft <= 20 then 
		return self.spec_vca.snapLeft
	else 
		return 20
	end
end 
function vehicleControlAddon:vcaUIGetsnapRight()
	if     self.spec_vca.snapRight <=  1 then 
		return 1 
	elseif self.spec_vca.snapRight <= 20 then 
		return self.spec_vca.snapRight
	else 
		return 20
	end
end 

function vehicleControlAddon:vcaUIShowdiffManual()
	if     self.spec_vca.diffHasF 
			or self.spec_vca.diffHasM 
			or self.spec_vca.diffHasB then
		return true 
	end 
	return false 
end 

function vehicleControlAddon:vcaUIShowdiffFrontAdv()
	if self.spec_vca.diffManual and self.spec_vca.diffHasM then 
		return true 
	end 
	return false 
end 

function vehicleControlAddon:vcaUIShowdiffLockSwap()
	if      self.spec_vca.diffManual
			and self.spec_vca.diffHasF 
			and self.spec_vca.diffHasB then
		return true 
	end 
	return false 
end 

function vehicleControlAddon:vcaUIShowhiredWorker2()
	if not self.spec_vca.diffManual then 
		return false 
	elseif self.spec_vca.diffHasF 
			or self.spec_vca.diffHasM 
			or self.spec_vca.diffHasB then
		return true 
	end 
	return false 
end 

function vehicleControlAddon:vcaUIShowautoShift()
	if not self.isServer then 
		return self.spec_vca.hasGearsAuto
	end 
	if      self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil 	
			and self.spec_motorized.motorizedNode ~= nil
			and next(self.spec_motorized.differentials) ~= nil
			then 
		local motor = self.spec_motorized.motor 
		if not (motor.backwardGears or motor.forwardGears) then 
			return false 
		elseif vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGearShifting( motor ) and vehicleControlAddon.vcaVehicleMotorGetUseAutomaticGroupShifting( motor ) then 
			return false 
		end 
		return true
	end 
	return false
end 

function vehicleControlAddon:vcaUIShowidleThrottle()
	if not self.isServer then 
		return self.spec_vca.hasGearsIdle
	end 
	if      self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil 	
			and self.spec_motorized.motorizedNode ~= nil
			and next(self.spec_motorized.differentials) ~= nil
			then 
		local motor = self.spec_motorized.motor 
	--if motor.gearShiftMode ~= VehicleMotor.SHIFT_MODE_MANUAL_CLUTCH and (motor.backwardGears or motor.forwardGears) then
	--if (motor.backwardGears or motor.forwardGears) then
			return true 
	--end 
	end 
	return false
end 

function vehicleControlAddon:vcaUIShowrotSpeedIn()
	return self.spec_vca.steeringIsOn == vehicleControlAddon.steeringTrue
end 

function vehicleControlAddon:vcaUIShowrotSpeedOut()
	return self.spec_vca.steeringIsOn == vehicleControlAddon.steeringTrue
end 
 
function vehicleControlAddon:vcaUIShowsplitGears()
	if      self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil 	
			and self.spec_motorized.motorizedNode ~= nil
			and next(self.spec_motorized.differentials) ~= nil
			then 
		local motor = self.spec_motorized.motor 
		if not (motor.backwardGears or motor.forwardGears) then 
			return false 
		end
		return true
	end 
	return false
end 

function vehicleControlAddon:vcaUIShowsplitGearRatio()
	if      self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil 	
			and self.spec_motorized.motorizedNode ~= nil
			and next(self.spec_motorized.differentials) ~= nil
			then 
		return self.spec_vca.splitGears > 0
	end 
	return false
end 
function vehicleControlAddon:vcaUIShowgearShiftTime()
	if      self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil 	
			and self.spec_motorized.motorizedNode ~= nil
			and next(self.spec_motorized.differentials) ~= nil
			then 
		local motor = self.spec_motorized.motor 
		if not (motor.backwardGears or motor.forwardGears) then 
			return false 
		end
		return true
	end 
	return false
end 

function vehicleControlAddon:vcaUIShowgrpShiftTime() 
	if      self.spec_motorized       ~= nil 
			and self.spec_motorized.motor ~= nil 	
			and self.spec_motorized.motorizedNode ~= nil
			and next(self.spec_motorized.differentials) ~= nil
			then 
		local motor = self.spec_motorized.motor 
		if not (motor.gearGroups) then 
			return false 
		end
		return true
	end 
	return false
end 
 
vehicleControlAddon.createStates()