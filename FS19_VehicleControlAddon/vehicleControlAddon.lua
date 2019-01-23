--
-- vehicleControlAddon
-- This is the specialization for vehicleControlAddon
--

--***************************************************************
source(Utils.getFilename("mogliBase.lua", g_currentModDirectory))
source(Utils.getFilename("vehicleControlAddonTransmissions.lua", g_currentModDirectory))
_G[g_currentModName..".mogliBase"].newClass( "vehicleControlAddon" )
--***************************************************************

function vehicleControlAddon.prerequisitesPresent(specializations)
	return true
end

function vehicleControlAddon.registerEventListeners(vehicleType)
	for _,n in pairs( { "onLoad", "onPostLoad", "onUpdate", "onDraw", "onLeaveVehicle", "onReadStream", "onWriteStream", "saveToXMLFile", "onRegisterActionEvents" } ) do
		SpecializationUtil.registerEventListener(vehicleType, n, vehicleControlAddon)
	end 
end 

VCAGlobals = {}
vehicleControlAddon.snapAngles = { 5, 7.5, 15, 22.5, 45, 90 }
vehicleControlAddon.factor30pi = 9.5492965855137201461330258023509
function vehicleControlAddon.globalsReset( createIfMissing )
	VCAGlobals                     = {}
	VCAGlobals.cameraRotFactor     = 0
	VCAGlobals.cameraRotFactorRev  = 0
	VCAGlobals.cameraRotTime       = 0
  VCAGlobals.timer4Reverse       = 0
  VCAGlobals.limitThrottle       = 0
  VCAGlobals.snapAngle           = 0
  VCAGlobals.brakeForceFactor    = 0
  VCAGlobals.snapAngleHudX       = 0
  VCAGlobals.snapAngleHudY       = 0
	VCAGlobals.drawHud             = false  
  VCAGlobals.transmission        = 0
  VCAGlobals.launchGear          = 0
	VCAGlobals.clutchTimer         = 0
 	VCAGlobals.debugPrint          = false
	
-- defaults	
	VCAGlobals.adaptiveSteering    = false
  VCAGlobals.camOutsideRotation  = false
  VCAGlobals.camInsideRotation   = false
 	VCAGlobals.camReverseRotation  = false
 	VCAGlobals.camRevOutRotation   = false
	VCAGlobals.shuttleControl      = false	
	VCAGlobals.peekLeftRight       = false	
	
	local file
	file = vehicleControlAddon.baseDirectory.."vehicleControlAddonConfig.xml"
	if fileExists(file) then	
		vehicleControlAddon.globalsLoad( file, "VCAGlobals", VCAGlobals )	
	else
		print("ERROR: NO GLOBALS IN "..file)
	end
	
	file = getUserProfileAppPath().. "modsSettings/FS19_VehicleControlAddon/vehicleControlAddonConfig.xml"
	if fileExists(file) then	
		print('Loading "'..file..'"...')
		vehicleControlAddon.globalsLoad( file, "VCAGlobals", VCAGlobals )	
	elseif createIfMissing then
		vehicleControlAddon.globalsCreate( file, "VCAGlobals", VCAGlobals, true )	
	end
	
	print("vehicleControlAddon initialized");
end

vehicleControlAddon.globalsReset(g_server ~= nil and g_client == nil)

function vehicleControlAddon.debugPrint( ... )
	if VCAGlobals.debugPrint then
		print( ... )
	end
end

function vehicleControlAddon:vcaIsValidCam( index, createIfMissing )
	local i = Utils.getNoNil( index, self.spec_enterable.camIndex )
	
	if      self.spec_enterable            ~= nil 
			and self.spec_enterable.cameras    ~= nil 
			and i ~= nil 
			and self.spec_enterable.cameras[i] ~= nil 
			and self.spec_enterable.cameras[i].vehicle == self
			and self.spec_enterable.cameras[i].isRotatable then
		if self.vcaCameras[i] == nil then
			if createIfMissing then
				self.vcaCameras[i] = { rotation = vehicleControlAddon.getDefaultRotation( self, i ),
															 rev      = vehicleControlAddon.getDefaultReverse( self, i ),
															 zero     = self.spec_enterable.cameras[i].rotY,
															 last     = self.spec_enterable.cameras[i].rotY }
			else
				return false
			end
		end
		return true
	end
	
	return false
end

--********************************************************************************************
-- functions for others mods 
function vehicleControlAddon:vcaExternalSetShuttleCtrl( value )
	if type( value ) == "boolean" then 
		self:vcaSetState( "vcaShuttleCtrl", value )
	end 
end 

function vehicleControlAddon:vcaExternalGetShuttleCtrl()
	return self.vcaShuttleCtrl 
end 

function vehicleControlAddon:vcaExternalSetMovingDirection( value )
	if type( value ) == "number" then 
		self:vcaSetState( "vcaExternalDir", value )
	end 
end 

function vehicleControlAddon:vcaExternalSetOverwriteBrakeForce( value )
	if value then 
		self:vcaSetState( "vcaBrakeForce", VCAGlobals.brakeForceFactor )
	else 
		self:vcaSetState( "vcaBrakeForce", 1 )
	end 
end 

function vehicleControlAddon:vcaExternalSetHideHud( value )
	if value then 
		self:vcaSetState( "vcaDrawHud", false )
	else 
		self:vcaSetState( "vcaDrawHud", true )
	end 
end 

function vehicleControlAddon:vcaExternalGetHudPosition()
	if not self.vcaDrawHud then 
		return 0, 0, 0, 0
	end 
	
	local l = 0.025 * vehicleControlAddon.getUiScale()

	-- since we use align center it is hard to estimate the correct size
	-- let's assume that it is 10 characters wide and 3.6 characters high	
	if VCAGlobals.snapAngleHudX >= 0 then 
		local x = VCAGlobals.snapAngleHudX
		local y = VCAGlobals.snapAngleHudY
		
		return x, y, x+10*l, y+3.4*l 
	end 
	
	local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
	local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.6
	
	return x-5*l, y+0.7*l, x+5*l, y+4.1*l 
end 
-- functions for others mods 
--********************************************************************************************

function vehicleControlAddon:onLoad(savegame)
	self.vcaDisabled         = false 
	self.vcaScaleFx          = vehicleControlAddon.vcaScaleFx
	self.vcaSetState         = vehicleControlAddon.mbSetState
	self.vcaIsValidCam       = vehicleControlAddon.vcaIsValidCam
	self.vcaGetCurrentCamRot = vehicleControlAddon.vcaGetCurrentCamRot
	
	--********************************************************************************************
	-- functions for others mods 
	self.vcaExternalSetShuttleCtrl         = vehicleControlAddon.vcaExternalSetShuttleCtrl
	self.vcaExternalGetShuttleCtrl         = vehicleControlAddon.vcaExternalGetShuttleCtrl
	self.vcaExternalSetMovingDirection     = vehicleControlAddon.vcaExternalSetMovingDirection
	self.vcaExternalSetOverwriteBrakeForce = vehicleControlAddon.vcaExternalSetOverwriteBrakeForce
	self.vcaExternalSetHideHud             = vehicleControlAddon.vcaExternalSetHideHud
	self.vcaExternalGetHudPosition         = vehicleControlAddon.vcaExternalGetHudPosition
	
	self.ksmExternalSetShuttleCtrl         = vehicleControlAddon.vcaExternalSetShuttleCtrl
	self.ksmExternalGetShuttleCtrl         = vehicleControlAddon.vcaExternalGetShuttleCtrl
	self.ksmExternalSetMovingDirection     = vehicleControlAddon.vcaExternalSetMovingDirection
	self.ksmExternalSetOverwriteBrakeForce = vehicleControlAddon.vcaExternalSetOverwriteBrakeForce
	self.ksmExternalSetHideHud             = vehicleControlAddon.vcaExternalSetHideHud
	self.ksmExternalGetHudPosition         = vehicleControlAddon.vcaExternalGetHudPosition	
	-- functions for others mods 
	--********************************************************************************************

	vehicleControlAddon.registerState( self, "vcaSteeringIsOn", VCAGlobals.adaptiveSteering )
	vehicleControlAddon.registerState( self, "vcaShuttleCtrl",  VCAGlobals.shuttleControl )
	vehicleControlAddon.registerState( self, "vcaPeekLeftRight",VCAGlobals.peekLeftRight )
	vehicleControlAddon.registerState( self, "vcaShuttleFwd",   true, vehicleControlAddon.vcaOnSetDirection )
	vehicleControlAddon.registerState( self, "vcaExternalDir",  0 )
	vehicleControlAddon.registerState( self, "vcaCamFwd"      , true )
	vehicleControlAddon.registerState( self, "vcaCameraIsOn"  , false, vehicleControlAddon.vcaOnSetCamera )
	vehicleControlAddon.registerState( self, "vcaReverseIsOn" , false, vehicleControlAddon.vcaOnSetReverse )
	vehicleControlAddon.registerState( self, "vcaExponent"    , 1    , vehicleControlAddon.vcaOnSetFactor )
	vehicleControlAddon.registerState( self, "vcaWarningText" , ""   , vehicleControlAddon.vcaOnSetWarningText )
	vehicleControlAddon.registerState( self, "vcaLimitThrottle",VCAGlobals.limitThrottle )
	vehicleControlAddon.registerState( self, "vcaSnapAngle"   , VCAGlobals.snapAngle, vehicleControlAddon.vcaOnSetSnapAngle )
	vehicleControlAddon.registerState( self, "vcaSnapIsOn" ,    false, vehicleControlAddon.vcaOnSetSnapIsOn )
	vehicleControlAddon.registerState( self, "vcaDrawHud" ,     VCAGlobals.drawHud )
	vehicleControlAddon.registerState( self, "vcaInchingIsOn" , false )
	vehicleControlAddon.registerState( self, "vcaNoAutoRotBack",false )
	vehicleControlAddon.registerState( self, "vcaBrakeForce",   VCAGlobals.brakeForceFactor )
	vehicleControlAddon.registerState( self, "vcaTransmission", vehicleControlAddon.getDefaultTransmission( self ) )
	vehicleControlAddon.registerState( self, "vcaMaxSpeed",     vehicleControlAddon.getDefaultMaxSpeed( self ) )
	vehicleControlAddon.registerState( self, "vcaGear",         0 ) --, vehicleControlAddon.vcaOnSetGear )
	vehicleControlAddon.registerState( self, "vcaRange",        0 ) --, vehicleControlAddon.vcaOnSetRange )
	vehicleControlAddon.registerState( self, "vcaNeutral",      false )
	vehicleControlAddon.registerState( self, "vcaAutoShift",    true )
	vehicleControlAddon.registerState( self, "vcaShifterIndex", 0 )
	vehicleControlAddon.registerState( self, "vcaShifterLH",    true )
	vehicleControlAddon.registerState( self, "vcaLimitSpeed",   true )
	vehicleControlAddon.registerState( self, "vcaLaunchGear",   VCAGlobals.launchGear )
	vehicleControlAddon.registerState( self, "vcaBOVVolume",    0, vehicleControlAddon.vcaOnSetGearChanged )
	vehicleControlAddon.registerState( self, "vcaKSIsOn",       true )
	vehicleControlAddon.registerState( self, "vcaKeepSpeed",    0 )
	vehicleControlAddon.registerState( self, "vcaKSToggle",     false )
	vehicleControlAddon.registerState( self, "vcaCCSpeed2",     10 )
	vehicleControlAddon.registerState( self, "vcaCCSpeed3",     15 )
	
	self.vcaFactor        = 1
	self.vcaReverseTimer  = 1.5 / VCAGlobals.timer4Reverse
	self.vcaMovingDir     = 0
	self.vcaLastFactor    = 0
	self.vcaWarningTimer  = 0
	self.vcaShifter7isR1  = nil 
	
	self.vcaCameras = {}
	
	for i,c in pairs(self.spec_enterable.cameras) do
		self:vcaIsValidCam( i, true )
	end

	if self.isClient then 
		if vehicleControlAddon.snapOnSample == nil then 
			local fileName = Utils.getFilename( "GPS_on.ogg", vehicleControlAddon.baseDirectory )
			vehicleControlAddon.snapOnSample = createSample("AutoSteerOnSound")
			loadSample(vehicleControlAddon.snapOnSample, fileName, false)
		end 
		
		if vehicleControlAddon.snapOffSample == nil then 
			local fileName = Utils.getFilename( "GPS_off.ogg", vehicleControlAddon.baseDirectory )
			vehicleControlAddon.snapOffSample = createSample("AutoSteerOffSound")
			loadSample(vehicleControlAddon.snapOffSample, fileName, false)
		end 
		
		if vehicleControlAddon.bovSample == nil then 
			local fileName = Utils.getFilename( "blowOffVentil.ogg", vehicleControlAddon.baseDirectory )
			vehicleControlAddon.bovSample = createSample("vehicleControlAddonBOVSample")
			loadSample(vehicleControlAddon.bovSample, fileName, false)
		end 	
	
		if vehicleControlAddon.ovArrowUpWhite == nil then
			vehicleControlAddon.ovArrowUpWhite   = createImageOverlay( Utils.getFilename( "arrow_up_white.dds",   vehicleControlAddon.baseDirectory ))
			vehicleControlAddon.ovArrowUpGray    = createImageOverlay( Utils.getFilename( "arrow_up_gray.dds",    vehicleControlAddon.baseDirectory ))
			vehicleControlAddon.ovArrowDownWhite = createImageOverlay( Utils.getFilename( "arrow_down_white.dds", vehicleControlAddon.baseDirectory ))
			vehicleControlAddon.ovArrowDownGray  = createImageOverlay( Utils.getFilename( "arrow_down_gray.dds",  vehicleControlAddon.baseDirectory ))
			vehicleControlAddon.ovHandBrakeUp    = createImageOverlay( Utils.getFilename( "hand_brake_up.dds",    vehicleControlAddon.baseDirectory ))
			vehicleControlAddon.ovHandBrakeDown  = createImageOverlay( Utils.getFilename( "hand_brake_down.dds",  vehicleControlAddon.baseDirectory ))
		end 
	end 	
end

function vehicleControlAddon:onPostLoad(savegame)
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		
		for t,specName in pairs({"zzzKeyboardSteerMogli",vehicleControlAddon_Register.specName }) do
			local key     = savegame.key .."."..specName
			local b, i, f
			
			vehicleControlAddon.debugPrint("loading... ("..tostring(key)..")")
			
			b = getXMLBool(xmlFile, key.."#steering")
			vehicleControlAddon.debugPrint("steering: "..tostring(b))
			if b ~= nil then 
				self:vcaSetState( "vcaSteeringIsOn", b )
			end 
			
			b = getXMLBool(xmlFile, key.."#shuttle")
			vehicleControlAddon.debugPrint("shuttle: "..tostring(b))
			if b ~= nil then 
				self:vcaSetState( "vcaShuttleCtrl", b )
			end 
			
			b = getXMLBool(xmlFile, key.."#peek")
			vehicleControlAddon.debugPrint("peek: "..tostring(b))
			if b ~= nil then 
				self:vcaSetState( "vcaPeekLeftRight", b )
			end 
			
			b = getXMLBool(xmlFile, key.."#autoShift")
			vehicleControlAddon.debugPrint("autoShift: "..tostring(b))
			if b ~= nil then 
				self:vcaSetState( "vcaAutoShift", b )
			end 
			
			b = getXMLBool(xmlFile, key.."#limitSpeed")
			vehicleControlAddon.debugPrint("limitSpeed: "..tostring(b))
			if b ~= nil then 
				self:vcaSetState( "vcaLimitSpeed", b )
			end 
			
			b = getXMLBool(xmlFile, key.."#keepSpeed")
			vehicleControlAddon.debugPrint("keepSpeed: "..tostring(b))
			if b ~= nil then 
				self:vcaSetState( "vcaKSToggle", b )
			end 
			
			i = getXMLInt(xmlFile, key.."#exponent")
			vehicleControlAddon.debugPrint("exponent: "..tostring(i))
			if i ~= nil then 
				self:vcaSetState( "vcaExponent", i )
			end 
			
			i = getXMLInt(xmlFile, key.."#throttle")
			vehicleControlAddon.debugPrint("throttle: "..tostring(i))
			if i ~= nil then 
				self:vcaSetState( "vcaLimitThrottle", i )
			end 
			
			i = getXMLInt(xmlFile, key.."#snapAngle")
			vehicleControlAddon.debugPrint("snapAngle: "..tostring(i))
			if i ~= nil then 
				self:vcaSetState( "vcaSnapAngle", i )
			end 
			
			f = getXMLFloat(xmlFile, key.."#brakeForce")
			vehicleControlAddon.debugPrint("brakeForce: "..tostring(f))
			if f ~= nil then 
				self:vcaSetState( "vcaBrakeForce", f )
			end 
			
			i = getXMLInt(xmlFile, key.."#launchGear")
			vehicleControlAddon.debugPrint("launchGear: "..tostring(i))
			if i ~= nil then 
				self:vcaSetState( "vcaLaunchGear", i )
			end 
			
			i = getXMLInt(xmlFile, key.."#transmission")
			vehicleControlAddon.debugPrint("transmission: "..tostring(i))
			if i ~= nil then 
				self:vcaSetState( "vcaTransmission", i )
			end 
			
			f = getXMLFloat(xmlFile, key.."#maxSpeed")
			vehicleControlAddon.debugPrint("maxSpeed: "..tostring(f))
			if f ~= nil then 
				self:vcaSetState( "vcaMaxSpeed", f )
			end 
					
			f = getXMLFloat(xmlFile, key.."#ccSpeed2")
			vehicleControlAddon.debugPrint("ccSpeed2: "..tostring(f))
			if f ~= nil then 
				self:vcaSetState( "vcaCCSpeed2", f )
			end 
					
			f = getXMLFloat(xmlFile, key.."#ccSpeed3")
			vehicleControlAddon.debugPrint("ccSpeed3: "..tostring(f))
			if f ~= nil then 
				self:vcaSetState( "vcaCCSpeed3", f )
			end 
					
			i = 0
			while true do 
				local cKey = string.format( "%s.camera(%d)", key, i )
				i = i + 1
				local j = getXMLInt(xmlFile, cKey.."#index")
				if j == nil then	
					break 
				end 
				if self:vcaIsValidCam( j, true ) then
					b = getXMLBool(xmlFile, cKey.."#rotation")
					vehicleControlAddon.debugPrint("rotation["..tostring(j).."]: "..tostring(b))
					if b ~= nil then 
						self.vcaCameras[j].rotation = b
					end 
					
					b = getXMLBool(xmlFile, cKey.."#reverse")
					vehicleControlAddon.debugPrint("reverse["..tostring(j).."]: "..tostring(b))
					if b ~= nil then 
						self.vcaCameras[j].rev = b
					end 
				end 
			end 
		end 
	end 
	
	self:vcaSetState( "vcaKSIsOn", self.vcaKSToggle )
end 

function vehicleControlAddon:saveToXMLFile(xmlFile, key)
	if self.vcaSteeringIsOn ~= nil and self.vcaSteeringIsOn ~= VCAGlobals.adaptiveSteering then
		setXMLBool(xmlFile, key.."#steering", self.vcaSteeringIsOn)
	end
	if self.vcaShuttleCtrl ~= nil and self.vcaShuttleCtrl ~= VCAGlobals.shuttleControl then
		setXMLBool(xmlFile, key.."#shuttle", self.vcaShuttleCtrl)
	end
	if self.vcaPeekLeftRight ~= nil and self.vcaPeekLeftRight ~= VCAGlobals.peekLeftRight then
		setXMLBool(xmlFile, key.."#peek", self.vcaPeekLeftRight)
	end
	if not self.vcaAutoShift then
		setXMLBool(xmlFile, key.."#autoShift", self.vcaAutoShift)
	end
	if not self.vcaLimitSpeed then
		setXMLBool(xmlFile, key.."#limitSpeed", self.vcaLimitSpeed)
	end
	if self.vcaKSToggle then
		setXMLBool(xmlFile, key.."#keepSpeed", self.vcaKSToggle)
	end
	if self.vcaExponent ~= nil and math.abs( self.vcaExponent - 1 ) > 1E-3 then
		setXMLInt(xmlFile, key.."#exponent", self.vcaExponent)
	end
	if self.vcaLimitThrottle ~= nil and math.abs( self.vcaLimitThrottle - VCAGlobals.limitThrottle ) > 1E-3 then
		setXMLInt(xmlFile, key.."#throttle", self.vcaLimitThrottle)
	end
	if self.vcaSnapAngle ~= nil and math.abs( self.vcaSnapAngle - VCAGlobals.snapAngle ) > 1E-3 then
		setXMLInt(xmlFile, key.."#snapAngle", self.vcaSnapAngle)
	end
	if self.vcaBrakeForce ~= nil and math.abs( self.vcaBrakeForce - VCAGlobals.brakeForceFactor ) > 1E-3 then
		setXMLFloat(xmlFile, key.."#brakeForce", self.vcaBrakeForce)
	end
	if self.vcaLaunchGear ~= nil and math.abs( self.vcaLaunchGear - VCAGlobals.launchGear ) > 1E-3 then
		setXMLInt(xmlFile, key.."#launchGear", self.vcaLaunchGear)
	end
	if self.vcaTransmission ~= nil and math.abs( self.vcaTransmission - vehicleControlAddon.getDefaultTransmission( self ) ) > 1E-3 then
		setXMLInt(xmlFile, key.."#transmission", self.vcaTransmission)
	end
	if self.vcaMaxSpeed ~= nil and math.abs( self.vcaMaxSpeed - vehicleControlAddon.getDefaultMaxSpeed( self ) ) > 1E-3 then
		setXMLFloat(xmlFile, key.."#maxSpeed", self.vcaMaxSpeed)
	end
	if self.vcaCCSpeed2 ~= nil and math.abs( self.vcaCCSpeed2 - 10 ) > 0.25 then
		setXMLFloat(xmlFile, key.."#ccSpeed2", self.vcaCCSpeed2)
	end
	if self.vcaCCSpeed3 ~= nil and math.abs( self.vcaCCSpeed3 - 10 ) > 0.25 then
		setXMLFloat(xmlFile, key.."#ccSpeed2", self.vcaCCSpeed3)
	end
	
	local i = 0
	for j,b in pairs(self.vcaCameras) do
		local addI = true  
		local cKey = string.format( "%s.camera(%d)", key, i )
		if b.rotation ~= vehicleControlAddon.getDefaultRotation( self, j ) then
			if addI then 
				addI = false 
				i = i + 1
				setXMLInt(xmlFile, cKey.."#index", j)
			end 
			setXMLBool(xmlFile, cKey.."#rotation", b.rotation)
		end
		if b.rev ~= vehicleControlAddon.getDefaultReverse( self, j ) then
			if addI then 
				addI = false 
				i = i + 1
				setXMLInt(xmlFile, cKey.."#index", j)
			end 
			setXMLBool(xmlFile, cKey.."#reverse", b.rev)
		end
	end
end 

function vehicleControlAddon:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	if isOnActiveVehicle then
		if self.vcaActionEvents == nil then 
			self.vcaActionEvents = {}
		else	
			self:clearActionEventsTable( self.vcaActionEvents )
		end 
		
		for _,actionName in pairs({ "vcaSETTINGS",  
                                "vcaUP",        
                                "vcaDOWN",      
                                "vcaLEFT",      
                                "vcaRIGHT",     
                                "vcaDIRECTION",     
                                "vcaFORWARD",     
                                "vcaREVERSE",
																"vcaNO_ARB",
																"vcaINCHING",
																"vcaKEEPSPEED",
																"vcaSWAPSPEED",
                                "vcaSNAP",
																"vcaGearUp",
																"vcaGearDown",
																"vcaRangeUp", 
																"vcaRangeDown",
																"vcaNeutral",
																"vcaShifter1",
																"vcaShifter2",
																"vcaShifter3",
																"vcaShifter4",
																"vcaShifter5",
																"vcaShifter6",
																"vcaShifter7",
																"vcaShifterLH",
																"AXIS_BRAKE_VEHICLE",
																"AXIS_ACCELERATE_VEHICLE",
																"AXIS_MOVE_SIDE_VEHICLE" }) do
																
			local isPressed = false 
			if     actionName == "AXIS_MOVE_SIDE_VEHICLE"
					or actionName == "AXIS_BRAKE_VEHICLE"
					or actionName == "AXIS_ACCELERATE_VEHICLE"
					or actionName == "vcaUP"
					or actionName == "vcaDOWN"
					or actionName == "vcaLEFT"
					or actionName == "vcaRIGHT" 
					or actionName == "vcaINCHING"
					or actionName == "vcaKEEPSPEED"
					or actionName == "vcaShifter1"
					or actionName == "vcaShifter2"
					or actionName == "vcaShifter3"
					or actionName == "vcaShifter4"
					or actionName == "vcaShifter5"
					or actionName == "vcaShifter6"
					or actionName == "vcaShifter7"
					or actionName == "vcaNO_ARB" then 
				isPressed = true 
			end 
			
			local _, eventName = self:addActionEvent(self.vcaActionEvents, InputAction[actionName], self, vehicleControlAddon.actionCallback, isPressed, true, false, true, nil);

		--local __, eventName = InputBinding.registerActionEvent(g_inputBinding, actionName, self, vehicleControlAddon.actionCallback ,false ,true ,false ,true)
			if      g_inputBinding                   ~= nil 
					and g_inputBinding.events            ~= nil 
					and g_inputBinding.events[eventName] ~= nil
					and ( actionName == "vcaSETTINGS"
					   or ( self.vcaShuttleCtrl and actionName == "vcaDIRECTION" ) ) then 
				if isSelected then
					g_inputBinding.events[eventName].displayPriority = 1
				elseif  isOnActiveVehicle then
					g_inputBinding.events[eventName].displayPriority = 3
				end
			end
		end
	end
end

vehicleControlAddon.transmissions = {}
vehicleControlAddon.transmissions[1] = vehicleControlAddonTransmissionIVT:new()
vehicleControlAddon.transmissions[2] = vehicleControlAddonTransmission4x4:new()
vehicleControlAddon.transmissions[3] = vehicleControlAddonTransmission4PS:new()
vehicleControlAddon.transmissions[4] = vehicleControlAddonTransmission2x6:new()
vehicleControlAddon.transmissions[5] = vehicleControlAddonTransmissionFPS:new()
vehicleControlAddon.transmissions[6] = vehicleControlAddonTransmission6PS:new()


function vehicleControlAddon:actionCallback(actionName, keyStatus)

	if actionName ~= "AXIS_MOVE_SIDE_VEHICLE" then 
		vehicleControlAddon.debugPrint( 'vehicleControlAddon:actionCallback( "'..tostring(actionName)..'", '..tostring(keyStatus)..' )' )
	end 
	
	if     actionName == "vcaGearUp"
			or actionName == "vcaGearDown"
			or actionName == "vcaRangeUp" 
			or actionName == "vcaRangeDown"
			or actionName == "vcaShifter1"
			or actionName == "vcaShifter2"
			or actionName == "vcaShifter3"
			or actionName == "vcaShifter4"
			or actionName == "vcaShifter5"
			or actionName == "vcaShifter6"
			or actionName == "vcaShifter7"
			or actionName == "vcaShifterLH" then 
		for i,handler in pairs(vehicleControlAddon.transmissions) do 
			if self.vcaTransmission == i then 
				handler:actionCallback( self, actionName, keyStatus )
			end 
		end 
		return 
	end 

	if     actionName == "AXIS_MOVE_SIDE_VEHICLE"  and math.abs( keyStatus ) > 0.05 then 
		self:vcaSetState( "vcaSnapIsOn", false )
	elseif actionName == "vcaUP"
			or actionName == "vcaDOWN"
			or actionName == "vcaLEFT"
			or actionName == "vcaRIGHT" then

		if not ( self.vcaPeekLeftRight ) then 
			if     actionName == "vcaUP" then
				self.vcaNewRotCursorKey = 0
			elseif actionName == "vcaDOWN" then
				self.vcaNewRotCursorKey = math.pi
			elseif actionName == "vcaLEFT" then
				if not ( self.vcaCamFwd ) then
					self.vcaNewRotCursorKey =  0.7*math.pi
				else 
					self.vcaNewRotCursorKey =  0.3*math.pi
				end 
			elseif actionName == "vcaRIGHT" then
				if not ( self.vcaCamFwd ) then
					self.vcaNewRotCursorKey = -0.7*math.pi
				else 
					self.vcaNewRotCursorKey = -0.3*math.pi
				end 
			end
			self.vcaPrevRotCursorKey  = nil 
		elseif keyStatus >= 0.5 then 
			local i = self.spec_enterable.camIndex
			local r = nil
			if i ~= nil and self.spec_enterable.cameras[i].rotY and self.spec_enterable.cameras[i].origRotY ~= nil then 
				r = vehicleControlAddon.normalizeAngle( self.spec_enterable.cameras[i].rotY - self.spec_enterable.cameras[i].origRotY )
			end

			if     actionName == "vcaUP" then
				if     r == nil then 
					self.vcaNewRotCursorKey = 0
				elseif math.abs( r ) < 0.1 * math.pi then
					self.vcaNewRotCursorKey = math.pi
				else 
					self.vcaNewRotCursorKey = 0
				end 
				self.vcaPrevRotCursorKey  = nil 
				r = nil
			elseif actionName == "vcaDOWN" then
				if     r == nil then 
					self.vcaNewRotCursorKey = nil
				elseif math.abs( r ) < 0.5 * math.pi then
					self.vcaNewRotCursorKey = math.pi
				else 
					self.vcaNewRotCursorKey = 0
				end 
			elseif actionName == "vcaLEFT" then
				if     r ~= nil and math.abs( r ) > 0.7 * math.pi then
					self.vcaNewRotCursorKey =  0.7*math.pi
				elseif r ~= nil and math.abs( r ) < 0.3 * math.pi then
					self.vcaNewRotCursorKey =  0.3*math.pi
				else 
					self.vcaNewRotCursorKey =  0.5*math.pi
				end 
			elseif actionName == "vcaRIGHT" then
				if     r ~= nil and math.abs( r ) > 0.7 * math.pi then
					self.vcaNewRotCursorKey = -0.7*math.pi
				elseif r ~= nil and math.abs( r ) < 0.3 * math.pi then
					self.vcaNewRotCursorKey = -0.3*math.pi
				else 
					self.vcaNewRotCursorKey = -0.5*math.pi
				end 
			end
			
			if self.vcaPrevRotCursorKey == nil and r ~= nil then 
				self.vcaPrevRotCursorKey = r 
			end 
		elseif self.vcaPrevRotCursorKey ~= nil then 
			self.vcaNewRotCursorKey  = self.vcaPrevRotCursorKey
			self.vcaPrevRotCursorKey = nil
		end
	elseif actionName == "vcaINCHING" then 
		self:vcaSetState( "vcaInchingIsOn", keyStatus >= 0.5 )
	elseif actionName == "vcaKEEPSPEED" then 
		local isPressed = keyStatus >= 0.5 
		if self.vcaKSToggle then 
			isPressed = not isPressed
		end 
		if isPressed then 
			self:vcaSetState( "vcaKeepSpeed", self.lastSpeed * 3600 )
			self:vcaSetState( "vcaKSIsOn", true )
		else 
			self:vcaSetState( "vcaKSIsOn", false )
		end 
	elseif actionName == "vcaSWAPSPEED" then 
		local temp = self.spec_drivable.cruiseControl.speed
		self:setCruiseControlMaxSpeed( self.vcaCCSpeed2 )
		self:vcaSetState( "vcaCCSpeed2", self.vcaCCSpeed3 )
		self:vcaSetState( "vcaCCSpeed3", temp )
	elseif actionName == "vcaNO_ARB" then 
		self:vcaSetState( "vcaNoAutoRotBack", keyStatus >= 0.5 )
	elseif actionName == "vcaDIRECTION" then
		self.vcaShifter7isR1 = false 
		self:vcaSetState( "vcaShuttleFwd", not self.vcaShuttleFwd )
	elseif actionName == "vcaFORWARD" then
		self.vcaShifter7isR1 = false 
		self:vcaSetState( "vcaShuttleFwd", true )
	elseif actionName == "vcaREVERSE" then
		self.vcaShifter7isR1 = false 
		self:vcaSetState( "vcaShuttleFwd", false )
	elseif actionName == "vcaSNAP" then
		self:vcaSetState( "vcaSnapIsOn", not self.vcaSnapIsOn )
 	elseif actionName == "vcaNeutral" then
		if self.vcaNeutral and self.vcaShifterIndex > 0 then 
			self:vcaSetState( "vcaShifterIndex", 0 )
		end 
		self:vcaSetState( "vcaNeutral", not self.vcaNeutral )
	elseif actionName == "vcaSETTINGS" then
		vehicleControlAddon.vcaShowSettingsUI( self )
	end
end

function vehicleControlAddon:onLeaveVehicle()
	self:vcaSetState( "vcaInchingIsOn", false )
	self:vcaSetState( "vcaNoAutoRotBack", false )
	self.vcaNewRotCursorKey  = nil
	self.vcaPrevRotCursorKey = nil
	self:vcaSetState( "vcaSnapIsOn", false )
	self:vcaSetState( "vcaShifterIndex", 0 )
	self:vcaSetState( "vcaKSIsOn", self.vcaKSToggle )
	self.vcaLastSnapAngle = nil
end 

function vehicleControlAddon:onUpdate(dt)

  if     self.spec_enterable         == nil
			or self.spec_enterable.cameras == nil then 
		self.vcaDisabled =true
		return 
	end
	
	local newRotCursorKey = self.vcaNewRotCursorKey
	local i               = self.spec_enterable.camIndex
	local requestedBack   = nil

	self.vcaNewRotCursorKey = nil

	if newRotCursorKey ~= nil then
		self.spec_enterable.cameras[i].rotY = vehicleControlAddon.normalizeAngle( self.spec_enterable.cameras[i].origRotY + newRotCursorKey )
		if     math.abs( newRotCursorKey ) < 1e-4 then 
			requestedBack = false 
		elseif math.abs( newRotCursorKey - math.pi ) < 1e-4 then 
			requestedBack = true 
		end
	end
	
	--*******************************************************************
	-- overwrite or reset some values 
	if self.vcaShuttleCtrl then 
		if     self.spec_reverseDriving  ~= nil then 
			if self.spec_reverseDriving.isReverseDriving then 
				self.vcaReverserDirection = -1 
			else
				self.vcaReverserDirection = 1 
			end 
		elseif self.vcaReverserDirection == nil then 
			self.vcaReverserDirection = self.spec_drivable.reverserDirection
		end 
		if self.vcaShuttleFwd then 
			self.spec_drivable.reverserDirection = 1
		else 
			self.spec_drivable.reverserDirection = -1
		end 
	elseif self.vcaReverserDirection ~= nil then 
		self.spec_drivable.reverserDirection = self.vcaReverserDirection
		self.vcaReverserDirection            = nil
	end 
	
	if self.vcaShuttleCtrl then 
		if self.vcaReverseDriveSample == nil then 
			self.vcaReverseDriveSample = self.spec_motorized.samples.reverseDrive 
		end 
		self.spec_motorized.samples.reverseDrive = nil 
	elseif self.vcaReverseDriveSample ~= nil then 
		self.spec_motorized.samples.reverseDrive = self.vcaReverseDriveSample
		self.vcaReverseDriveSample               = nil
	end 
	
	if     self.spec_motorized.motor.lowBrakeForceScale == nil then
	elseif self:getIsVehicleControlledByPlayer() and self.vcaBrakeForce <= 0.99 then 
		if self.vcaLowBrakeForceScale == nil then 
			self.vcaLowBrakeForceScale                 = self.spec_motorized.motor.lowBrakeForceScale
		end 
		self.spec_motorized.motor.lowBrakeForceScale = self.vcaBrakeForce * self.vcaLowBrakeForceScale 
	elseif self.vcaLowBrakeForceScale ~= nil then  
		self.spec_motorized.motor.lowBrakeForceScale = self.vcaLowBrakeForceScale 
		self.vcaLowBrakeForceScale                   = nil
	end 
	
	if not self.vcaLimitSpeed then 
		if self.vcaMaxForwardSpeed == nil then 
			self.vcaMaxForwardSpeed  = self.spec_motorized.motor.maxForwardSpeed 
			self.vcaMaxBackwardSpeed = self.spec_motorized.motor.maxBackwardSpeed
		end
		self.spec_motorized.motor.maxForwardSpeed  = self.vcaMaxSpeed 
		self.spec_motorized.motor.maxBackwardSpeed = self.vcaMaxSpeed 
	elseif self.vcaMaxForwardSpeed ~= nil then 
		self.spec_motorized.motor.maxForwardSpeed  = self.vcaMaxForwardSpeed 
		self.spec_motorized.motor.maxBackwardSpeed = self.vcaMaxBackwardSpeed
		self.vcaMaxForwardSpeed  = nil
		self.vcaMaxBackwardSpeed = nil
	end 

	if self.vcaNoAutoRotBack and self:getIsVehicleControlledByPlayer() then
		if self.vcaAutoRotateBackSpeed == nil then 
			self.vcaAutoRotateBackSpeed = self.autoRotateBackSpeed
		end 
		self:vcaSetState( "vcaSnapIsOn", false )
		self.autoRotateBackSpeed      = 0
	elseif self.vcaAutoRotateBackSpeed ~= nil then
		self.autoRotateBackSpeed      = self.vcaAutoRotateBackSpeed
		self.vcaAutoRotateBackSpeed   = nil 
	end 
	
	if self.vcaInchingIsOn and self:getIsVehicleControlledByPlayer() and not g_gui:getIsGuiVisible() and self.spec_drivable.cruiseControl.state == 1 then
		local limitThrottleRatio     = 0.75
		if self.vcaLimitThrottle < 11 then
			limitThrottleRatio     = 0.45 + 0.05 * self.vcaLimitThrottle
		else
			limitThrottleRatio     = 1.5 - 0.05 * self.vcaLimitThrottle
		end
		if self.vcaSpeedLimit == nil then 
			self.vcaSpeedLimit = self.spec_drivable.cruiseControl.speed
		end 
		self.spec_drivable.cruiseControl.speed = self.vcaSpeedLimit * limitThrottleRatio
	elseif self.vcaSpeedLimit ~= nil then 
		self.spec_drivable.cruiseControl.speed = self.vcaSpeedLimit
		self.vcaSpeedLimit = nil
	end 	
	-- overwrite or reset some values 
	--*******************************************************************
	

	if self:getIsActive() and self.isServer then
		if     self.vcaExternalDir > 0 then 
			self.vcaMovingDir = 1
		elseif self.vcaExternalDir < 0 then 
			self.vcaMovingDir = -1
		elseif self.vcaShuttleCtrl then 
			local controlledVehicles = g_currentMission.controlledVehicles
			local isHudVisible = g_currentMission.hud:getIsVisible()
			if self.vcaShuttleFwd then
				self.vcaMovingDir = 1
			else
				self.vcaMovingDir = -1
			end
		elseif g_currentMission.missionInfo.stopAndGoBraking then
			local movingDirection = self.movingDirection * self.spec_drivable.reverserDirection
			if math.abs( self.lastSpeed ) < 0.000278 then
				movingDirection = 0
			end
				
			local maxDelta    = dt * self.vcaReverseTimer
			self.vcaMovingDir = self.vcaMovingDir + vehicleControlAddon.mbClamp( movingDirection - self.vcaMovingDir, -maxDelta, maxDelta )
		else
			self.vcaMovingDir = Utils.getNoNil( self.nextMovingDirection * self.spec_drivable.reverserDirection )
		end
		
		
		if     self.vcaMovingDir < -0.5 then
			self:vcaSetState( "vcaCamFwd", false )
		elseif self.vcaMovingDir >  0.5 then
			self:vcaSetState( "vcaCamFwd", true )
		else
			fwd = self.vcaCamFwd
		end		
	end

	--*******************************************************************
	-- Snap Angle
	local axisSideLast    = self.vcaAxisSideLast
	local snapAngleLast   = self.vcaLastSnapAngle
	self.vcaAxisSideLast  = nil
	self.vcaLastSnapAngle = nil 
	
	if self.isClient and self.vcaSnapIsOn and self:getIsVehicleControlledByPlayer() and not g_gui:getIsGuiVisible() then 
		local lx,_,lz = localDirectionToWorld( self.components[1].node, 0, 0, 1 )			
		if lx*lx+lz*lz > 1e-6 then 
			local rot    = math.atan2( lx, lz )
			local d      = vehicleControlAddon.snapAngles[self.vcaSnapAngle]
			
			if snapAngleLast == nil then  
				local target = 0
				local diff   = math.pi+math.pi
				if d == nil then 
					if self.vcaSnapAngle < 1 then 
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
				
				self.vcaLastSnapAngle = vehicleControlAddon.normalizeAngle( target )
			else 
				self.vcaLastSnapAngle = snapAngleLast 
			end 
			
			d = 0.5 * d 
			
			if d > 10 then d = 10 end 
			d = math.rad( d )
				
			local a = vehicleControlAddon.mbClamp( vehicleControlAddon.normalizeAngle( rot - self.vcaLastSnapAngle ) / d, -1, 1 ) 
			if a < 0 then 
				a = 0.5 * ( a - a*a )
			else 
				a = 0.5 * ( a + a*a ) 
			end 
			
			if self.vcaMovingDir < 0 then 
				a = -a 
			end 
			
			if math.abs( a ) < 0.005 then 
				a = 0
			elseif math.abs( a ) < 0.05 then 
				if a < 0 then 
					a = -0.05
				else 
					a = 0.05
				end 
			end 
			
			d = 0.001 * dt
			
			if axisSideLast == nil then 
				axisSideLast = self.spec_drivable.axisSideLast 
			end 
			
			self.spec_drivable.axisSide = axisSideLast + vehicleControlAddon.mbClamp( a - axisSideLast, -d, d )

			
			self.vcaAxisSideLast = self.spec_drivable.axisSide
		end 
	end 
	
	--*******************************************************************
	-- Keep Speed 
	if self.isClient and self.vcaKSIsOn and self:getIsVehicleControlledByPlayer() and not g_gui:getIsGuiVisible() then
		if self.spec_drivable.cruiseControl.state > 0 then 
			self:vcaSetState( "vcaKeepSpeed", self.lastSpeed * 3600 * self.movingDirection  )
		elseif math.abs( self.spec_drivable.axisForward ) > 0.01 then 
			local f = 3.6 * math.max( -self.spec_motorized.motor.maxBackwardSpeed, self.lastSpeed * 1000 * self.movingDirection - 1 )
			local t = 3.6 * math.min(  self.spec_motorized.motor.maxForwardSpeed,  self.lastSpeed * 1000 * self.movingDirection + 1  )
			local a = self.spec_drivable.axisForward
			if     self.vcaReverserDirection ~= nil then 
				a = a * self.vcaReverserDirection
			elseif self.spec_drivable.reverserDirection ~= nil then 
				a = a * self.spec_drivable.reverserDirection
			end 
			self:vcaSetState( "vcaKeepSpeed", vehicleControlAddon.mbClamp( self.vcaKeepSpeed + a * 0.003 * dt, f, t ) )
		end 
	end 
	
	--*******************************************************************
	-- Camera Rotation
	if      self:getIsActive() 
			and self.isClient 
--		and self.steeringEnabled 
			and self:vcaIsValidCam() then

		if     self.vcaLastCamIndex == nil 
				or self.vcaLastCamIndex ~= i then
				
			self:vcaSetState( "vcaCameraIsOn",  self.vcaCameras[i].rotation )
			self:vcaSetState( "vcaReverseIsOn", self.vcaCameras[i].rev )
			self.vcaLastCamIndex = self.spec_enterable.camIndex
			self.vcaCameras[i].zero       = self.spec_enterable.cameras[i].rotY
			self.vcaCameras[i].lastCamFwd = nil
			
		elseif  g_gameSettings:getValue("isHeadTrackingEnabled") 
				and isHeadTrackingAvailable() 
				and self.spec_enterable.cameras[i].isInside 
				and self.spec_enterable.cameras[i].headTrackingNode ~= nil then
				
			if requestedBack ~= nil then 
				self.vcaCamBack = requestedBack 
			end 
			
			if self.vcaReverseIsOn or self.vcaCamBack ~= nil then			
				if self.spec_enterable.cameras[i].headTrackingMogliPF == nil then 
					local p = getParent( self.spec_enterable.cameras[i].headTrackingNode )
					self.spec_enterable.cameras[i].headTrackingMogliPF = createTransformGroup("headTrackingMogliPF")
					link( p, self.spec_enterable.cameras[i].headTrackingMogliPF )
					link( self.spec_enterable.cameras[i].headTrackingMogliPF, self.spec_enterable.cameras[i].headTrackingNode )
					setRotation( self.spec_enterable.cameras[i].headTrackingMogliPF, 0, 0, 0 )
					setTranslation( self.spec_enterable.cameras[i].headTrackingMogliPF, 0, 0, 0 )
					self.spec_enterable.cameras[i].headTrackingMogliPR = false 
				end 
				
				local targetBack = false 
				if self.vcaReverseIsOn and not ( self.vcaCamFwd ) then 
					targetBack = true 
				end 
				
				if self.vcaCamBack ~= nil then 
					if self.vcaCamBack == targetBack then 
						self.vcaCamBack = nil 
					else 
						targetBack = self.vcaCamBack 
					end 
				end
				
				if targetBack then 
					if not self.spec_enterable.cameras[i].headTrackingMogliPR then 
						self.spec_enterable.cameras[i].headTrackingMogliPR = true 
						setRotation( self.spec_enterable.cameras[i].headTrackingMogliPF, 0, math.pi, 0 )
					end 
				else 
					if self.spec_enterable.cameras[i].headTrackingMogliPR then 
						self.spec_enterable.cameras[i].headTrackingMogliPR = false  
						setRotation( self.spec_enterable.cameras[i].headTrackingMogliPF, 0, 0, 0 )
					end 
				end 
			end 
			
		elseif self.vcaCameraIsOn 
				or self.vcaReverseIsOn then

			local pi2 = math.pi / 2
			local eps = 1e-6
			oldRotY = self.spec_enterable.cameras[i].rotY
			local diff = oldRotY - self.vcaCameras[i].last
			
			if self.vcaCameraIsOn then
				if newRotCursorKey ~= nil then
					self.vcaCameras[i].zero = vehicleControlAddon.normalizeAngle( self.spec_enterable.cameras[i].origRotY + newRotCursorKey )
				else
					self.vcaCameras[i].zero = self.vcaCameras[i].zero + diff
				end
			else
				self.vcaCameras[i].zero = self.spec_enterable.cameras[i].rotY
			end
				
		--diff = math.abs( vehicleControlAddon.vcaGetAbsolutRotY( self, i ) )
			local isRev = false
			local aRotY = vehicleControlAddon.normalizeAngle( vehicleControlAddon.vcaGetAbsolutRotY( self, i ) - self.spec_enterable.cameras[i].rotY + self.vcaCameras[i].zero )
			if -pi2 < aRotY and aRotY < pi2 then
				isRev = true
			end
			
			if self.vcaReverseIsOn then
				if     newRotCursorKey ~= nil then
				-- nothing
				elseif self.vcaCameras[i].lastCamFwd == nil or self.vcaCameras[i].lastCamFwd ~= self.vcaCamFwd then
					if isRev == self.vcaCamFwd then
						self.vcaCameras[i].zero = vehicleControlAddon.normalizeAngle( self.vcaCameras[i].zero + math.pi )
						isRev = not isRev						
					end
				end
				self.vcaCameras[i].lastCamFwd = self.vcaCamFwd
			end
			
			local newRotY = self.vcaCameras[i].zero
			
			if self.vcaCameraIsOn then
				
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
				if self.rotatedTime < 0 then
					f = -f
				end
				
				local g = self.vcaLastFactor
				self.vcaLastFactor = self.vcaLastFactor + vehicleControlAddon.mbClamp( f - self.vcaLastFactor, -VCAGlobals.cameraRotTime*dt, VCAGlobals.cameraRotTime*dt )
				if math.abs( self.vcaLastFactor - g ) > 0.01 then
					f = self.vcaLastFactor
				else
					f = g
				end
				
				if isRev then
				--vehicleControlAddon.debugPrint("reverse")
					newRotY = newRotY - self:vcaScaleFx( VCAGlobals.cameraRotFactorRev, 0.1, 3 ) * f				
				else
				--vehicleControlAddon.debugPrint("forward")
					newRotY = newRotY + self:vcaScaleFx( VCAGlobals.cameraRotFactor, 0.1, 3 ) * f
				end	
				
			else
				self.vcaLastFactor = 0
			end

			self.spec_enterable.cameras[i].rotY = newRotY			
			
			if math.abs( vehicleControlAddon.normalizeAngle( self.spec_enterable.cameras[i].rotY - newRotY ) ) > 0.5 * math.pi then
				local camera = self.spec_enterable.cameras[i]
				if camera.positionSmoothingParameter > 0 then
					camera:updateRotateNodeRotation()
					local xlook,ylook,zlook = getWorldTranslation(camera.rotateNode)
					camera.lookAtPosition[1] = xlook
					camera.lookAtPosition[2] = ylook
					camera.lookAtPosition[3] = zlook
					local x,y,z = getWorldTranslation(camera.cameraPositionNode)
					camera.position[1] = x
					camera.position[2] = y
					camera.position[3] = z
					camera:setSeparateCameraPose()
				end
			end 			
		end
		
		self.vcaCameras[i].last = self.spec_enterable.cameras[i].rotY
	end	
	
	self.vcaWarningTimer = self.vcaWarningTimer - dt
	
	if      self:getIsActive()
			and self.vcaWarningText ~= nil
			and self.vcaWarningText ~= "" then
		if self.vcaWarningTimer <= 0 then
			self.vcaWarningText = ""
		end
	end	
	
--******************************************************************************************************************************************
-- adaptive steering 	
	if self.vcaSteeringIsOn and not ( self.vcaSnapIsOn ) and self:getIsVehicleControlledByPlayer() then 
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
		
		self.vcaRotSpeedFactor = vehicleControlAddon.vcaScaleFx( self, f )
		
		for i,w in pairs( self.spec_wheels.wheels ) do 
			if w.rotSpeed ~= nil then 
				if w.vcaRotSpeed == nil then 
					w.vcaRotSpeed = w.rotSpeed 
				end 				
				w.rotSpeed = w.vcaRotSpeed * self.vcaRotSpeedFactor
			end 
			
			if w.rotSpeedNeg ~= nil then 
				if w.vcaRotSpeedNeg == nil then 
					w.vcaRotSpeedNeg = w.rotSpeedNeg 
				end 				
				w.rotSpeedNeg = w.vcaRotSpeedNeg * self.vcaRotSpeedFactor
			end 
		end 
	elseif self.vcaRotSpeedFactor ~= nil then
		for i,w in pairs( self.spec_wheels.wheels ) do 
			if w.vcaRotSpeed ~= nil and w.vcaRotSpeed ~= nil then 
				w.rotSpeed = w.vcaRotSpeed
			end 
			
			if w.rotSpeedNeg ~= nil and w.vcaRotSpeedNeg ~= nil then 
				w.rotSpeedNeg = w.vcaRotSpeedNeg
			end 
		end 
	
		self.vcaRotSpeedFactor = nil 
	end 
	
--******************************************************************************************************************************************
-- Reverse driving sound
	if self.isClient and self:getIsVehicleControlledByPlayer() and self:getIsEntered() then 
		if self.vcaShuttleCtrl and self.vcaReverseDriveSample ~= nil then 
			local notRev = self.vcaShuttleFwd or self.vcaNeutral
			if not g_soundManager:getIsSamplePlaying(self.vcaReverseDriveSample) and not notRev then
				g_soundManager:playSample(self.vcaReverseDriveSample)
			elseif notRev then
				g_soundManager:stopSample(self.vcaReverseDriveSample)
			end
		end
	end 	
	
--******************************************************************************************************************************************
-- Simple fix if vcaMaxSpeed was cleared for unknown reasons on Dedi
	local somethingWentWrong = false 
	for _,n in pairs({ "vcaSteeringIsOn",
	                   "vcaShuttleCtrl", 
	                   "vcaPeekLeftRight",
	                   "vcaShuttleFwd",  
	                   "vcaExternalDir", 
	                   "vcaCamFwd"      ,
	                   "vcaCameraIsOn"  ,
	                   "vcaReverseIsOn" ,
	                   "vcaExponent"    ,
	                   "vcaWarningText" ,
	                   "vcaLimitThrottle",
	                   "vcaSnapAngle"   ,
	                   "vcaSnapIsOn" ,   
	                   "vcaDrawHud" ,    
	                   "vcaInchingIsOn" ,
	                   "vcaNoAutoRotBack",
	                   "vcaBrakeForce",  
	                   "vcaTransmission",
	                   "vcaMaxSpeed",    
	                   "vcaGear",        
	                   "vcaRange",       
	                   "vcaNeutral",     
	                   "vcaAutoShift",   
	                   "vcaShifterIndex",
	                   "vcaShifterLH",   
	                   "vcaLimitSpeed",  
	                   "vcaLaunchGear",  
	                   "vcaBOVVolume",   
	                   "vcaKSIsOn",      
	                   "vcaKeepSpeed",   
	                   "vcaKSToggle",    
	                   "vcaCCSpeed2",    
	                   "vcaCCSpeed3" }) do 
		if self[n] == nil then 
			print( "Error: someone cleared variable self."..n.."!!! self.isServer = "..tostring(self.isServer)..", self.isClient = "..tostring(self.isClient))
			if      self.vehicleControlAddonStateHandler ~= nil 
					and self.vehicleControlAddonStateHandler[n] ~= nil 
					and self.vehicleControlAddonStateHandler[n].default ~= nil then 
				self:vcaSetState( n, self.vehicleControlAddonStateHandler[n].default )
				print("Value was reset to default: '"..tostring(self[n]))
			end 
		end 
	end 
end  

function vehicleControlAddon:onDraw()
	if self:getIsVehicleControlledByPlayer() and not g_gui:getIsGuiVisible() then
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.6
		local l = 0.025 * vehicleControlAddon.getUiScale()
		
		setTextAlignment( RenderText.ALIGN_CENTER ) 
		setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_MIDDLE )
		setTextColor(1, 1, 1, 1) 
		
		self.vcaDebugT = nil 
		if self.vcaTransmission ~= nil then 
			local t = vehicleControlAddon.transmissions[self.vcaTransmission]
			if t ~= nil then 
				self.vcaDebugT = "I: "..tostring(self.vcaTransmission)
											.." T: "..tostring(t:getName())
											.." G: "..tostring(t.numberOfGears)
											.." R: "..tostring(t.numberOfRanges)
			end 
		end 

		if self.vcaShuttleCtrl or self.vcaTransmission ~= nil and self.vcaTransmission >= 2 then  
			setTextAlignment( RenderText.ALIGN_CENTER ) 
			setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_MIDDLE )
			setTextColor(1, 1, 1, 1) 
			
			if vehicleControlAddon.ovArrowUpWhite ~= nil then
				local w = 0.015 * vehicleControlAddon.getUiScale()
				local h = w * g_screenAspectRatio
				if self.vcaShuttleCtrl then 
					if self.vcaShuttleFwd then
						if     self.vcaNeutral and self.vcaShifterIndex > 0 then 
						elseif self.vcaNeutral then 
							renderOverlay( vehicleControlAddon.ovHandBrakeUp, x-0.5*w, y-0.5*h, w, h )
						elseif self.vcaShifter7isR1 and self.vcaShifterIndex > 0 then
							renderOverlay( vehicleControlAddon.ovArrowUpGray, x-0.5*w, y-0.5*h, w, h )
						else 
							renderOverlay( vehicleControlAddon.ovArrowUpWhite, x-0.5*w, y-0.5*h, w, h )
						end 
					else 
						if     self.vcaNeutral and self.vcaShifterIndex > 0 then 
						elseif self.vcaNeutral then 
							renderOverlay( vehicleControlAddon.ovHandBrakeDown, x-0.5*w, y-0.5*h, w, h )
						elseif self.vcaShifter7isR1 and self.vcaShifterIndex > 0 then
							renderOverlay( vehicleControlAddon.ovArrowDownGray, x-0.5*w, y-0.5*h, w, h )
						else 
							renderOverlay( vehicleControlAddon.ovArrowDownWhite, x-0.5*w, y-0.5*h, w, h )
						end 
					end 
				elseif self.vcaNeutral then 
					renderText(x, y, l, "N")
				end 
			end 
		end 
		
		if self.vcaDrawHud then 
			if VCAGlobals.snapAngleHudX >= 0 then 
				x = VCAGlobals.snapAngleHudX
				y = VCAGlobals.snapAngleHudY
				setTextAlignment( RenderText.ALIGN_LEFT ) 
				setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
			else 
				y = y + l * 1.2
			end 
			
			if self.vcaTransmission >= 2 then 
				local transmission = vehicleControlAddon.transmissions[self.vcaTransmission]
				local gear  = transmission:getRatioIndex( self.vcaGear, self.vcaRange )		
				local ratio = transmission:getGearRatio( gear )
				local maxSpeed = 0
				local text 
				local l2    = l
				if gear ~= nil and ratio ~= nil and self.vcaMaxSpeed ~= nil then 
					maxSpeed = 3.6 * ratio * self.vcaMaxSpeed
					text = transmission:getGearText( self.vcaGear, self.vcaRange )	
					
					if     self.vcaShifterIndex ==7 then 
						if self.vcaShifterLH then 
							text = "R+ ("..text..")"
						else 
							text = "R- ("..text..")" 
						end 
						l2 = l * 0.8
					elseif self.vcaShifterIndex > 0 then 
						if self.vcaShifterLH then 
							text = tostring(self.vcaShifterIndex).."+ ("..text..")"
						else 
							text = tostring(self.vcaShifterIndex).."- ("..text..")" 
						end 				
						l2 = l * 0.8
					end 
				else 
					text = "nil"
				end 
				
				text = text .." "..string.format("%3.0f km/h",maxSpeed )
				renderText(x, y, l2, text)
				y = y + l * 1.2	
			end 

			local lx,_,lz = localDirectionToWorld( self.components[1].node, 0, 0, 1 )			
			local d = 0
			if lx*lx+lz*lz > 1e-6 then 
				d = math.deg( math.pi - math.atan2( lx, lz ) )
			end 
			if self.vcaLastSnapAngle ~= nil then 
				renderText(x, y, l, string.format( "%4.1f° / %4.1f°", math.deg( math.pi - self.vcaLastSnapAngle ),d))
				y = y + l * 1.2	
			else
				renderText(x, y, l, string.format( "%4.1f°", d))
				y = y + l * 1.2	
			end
			
			if self.vcaKSIsOn and self.spec_drivable.cruiseControl.state == 0 then 
				renderText(x, y, l, string.format( "%5.1f km/h",self.vcaKeepSpeed))
				y = y + l * 1.2	
			end

		end 
	
		setTextAlignment( RenderText.ALIGN_LEFT ) 
		setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
	end 
end

function vehicleControlAddon:onReadStream(streamId, connection)

	self.vcaSteeringIsOn  = streamReadBool(streamId) 
  self.vcaCameraIsOn    = streamReadBool(streamId) 
  self.vcaReverseIsOn   = streamReadBool(streamId) 
  self.vcaCamFwd        = streamReadBool(streamId) 
  self.vcaShuttleCtrl   = streamReadBool(streamId) 
  self.vcaShuttleFwd    = streamReadBool(streamId) 
  self.vcaNeutral       = streamReadBool(streamId) 
  self.vcaDrawHud       = streamReadBool(streamId) 
	self.vcaExternalDir   = streamReadInt16(streamId)     
	self.vcaExponent      = streamReadInt16(streamId)     
	self.vcaSnapAngle     = streamReadInt16(streamId)     
	
	self.vcaPeekLeftRight = streamReadBool(streamId) 
	self.vcaAutoShift     = streamReadBool(streamId) 
	self.vcaLimitSpeed    = streamReadBool(streamId) 
	self.vcaLimitThrottle = streamReadInt16(streamId) 
	self.vcaBrakeForce    = streamReadInt16(streamId) * 0.05
	self.vcaLaunchGear    = streamReadInt16(streamId)
	self.vcaTransmission  = streamReadInt16(streamId)
	self.vcaMaxSpeed      = streamReadFloat32(streamId)
	
end

function vehicleControlAddon:onWriteStream(streamId, connection)

	streamWriteBool(streamId, self.vcaSteeringIsOn )
	streamWriteBool(streamId, self.vcaCameraIsOn )
	streamWriteBool(streamId, self.vcaReverseIsOn )
	streamWriteBool(streamId, self.vcaCamFwd )     
	streamWriteBool(streamId, self.vcaShuttleCtrl )     
	streamWriteBool(streamId, self.vcaShuttleFwd )     
	streamWriteBool(streamId, self.vcaNeutral )     
	streamWriteBool(streamId, self.vcaDrawHud )     
	streamWriteInt16(streamId,self.vcaExternalDir )     
	streamWriteInt16(streamId,self.vcaExponent )     
	streamWriteInt16(streamId,self.vcaSnapAngle )     
	streamWriteBool(streamId,  self.vcaPeekLeftRight )
	streamWriteBool(streamId,  self.vcaAutoShift     )
	streamWriteBool(streamId,  self.vcaLimitSpeed    )
	streamWriteInt16(streamId, self.vcaLimitThrottle )
	streamWriteInt16(streamId, math.floor( 20 * self.vcaBrakeForce + 0.5 ) )
	streamWriteInt16(streamId, self.vcaLaunchGear    )
	streamWriteInt16(streamId, self.vcaTransmission  )
	streamWriteFloat32(streamId, self.vcaMaxSpeed    )

end 

function vehicleControlAddon:getDefaultRotation( camIndex )
	if     self.spec_enterable.cameras           == nil
			or self.spec_enterable.cameras[camIndex] == nil then
		vehicleControlAddon.debugPrint( "invalid camera" )
		return false
	elseif not ( self.spec_enterable.cameras[camIndex].isRotatable )
			or self.spec_enterable.cameras[camIndex].vehicle ~= self then
		vehicleControlAddon.debugPrint( "fixed camera" )
		return false
	elseif self.spec_enterable.cameras[camIndex].isInside then
		vehicleControlAddon.debugPrint( "camera is inside" )
		return VCAGlobals.camInsideRotation
	end
	
	return VCAGlobals.camOutsideRotation
end

function vehicleControlAddon:getDefaultTransmission()
	if VCAGlobals.transmission <= 0 then 
		return 0
	elseif self.spec_combine ~= nil then 
		return 1
	end 
	return VCAGlobals.transmission
end 

function vehicleControlAddon:getDefaultMaxSpeed()
	local m 
	local n = Utils.getNoNil( self.vcaMaxForwardSpeed, self.spec_motorized.motor.maxForwardSpeed )

	if     n <= 7.5 then 
	--25.2 km/h
		m = 7
	elseif n <= 9 then 
	--32 km/h
		m = 8.889
	elseif n <= 12.223 then 
	--43 km/h
		m = 11.944
	elseif n <= 14.723 then 
	--58 km/h for vehicles up to 53 km/h
		m = 16.111
	elseif n <= 21 then 
	--73.5 km/h for vehicles up to 63 km/h
		m = n * 7 / 6
	else
	--120 km/h for vehicles with 90 km/h max speed
		m = n * 4 / 3
	end 
	return math.max( m, n )
end 

function vehicleControlAddon:getDefaultReverse( camIndex )
	if     self.spec_enterable.cameras           == nil
			or self.spec_enterable.cameras[camIndex] == nil then
		return false
	elseif not ( self.spec_enterable.cameras[camIndex].isRotatable )
			or self.spec_enterable.cameras[camIndex].vehicle ~= self then
		return false
	elseif self.spec_enterable.cameras[camIndex].isInside then 
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
		
		return VCAGlobals.camReverseRotation 
	end
	
	return VCAGlobals.camRevOutRotation
end

function vehicleControlAddon:vcaScaleFx( fx, mi, ma )
	return vehicleControlAddon.mbClamp( 1 + self.vcaFactor * ( fx - 1 ), mi, ma )
end

function vehicleControlAddon:vcaGetCurrentCamRot()
	if self.spec_enterable == nil then 
		return 0
	end
	local i = self.spec_enterable.camIndex
	if     i == nil 
			or self.spec_enterable.cameras == nil 
			or self.spec_enterable.cameras[i] == nil
			or self.spec_enterable.cameras[i].rotY == nil then 
		return 0
	end 
	local a = vehicleControlAddon.normalizeAngle( self.spec_enterable.cameras[i].rotY )
	print(math.deg(a))
	return a
end 

--******************************************************************************************************************************************
-- shuttle control and inching
function vehicleControlAddon:vcaUpdateWheelsPhysics( superFunc, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking )
	local lightsBackup = self.spec_lights
	local brake        = ( acceleration < -0.1 )
	
	self.vcaOldAcc       = acceleration
	self.vcaOldHandbrake = doHandbrake

	if self:getIsVehicleControlledByPlayer() then 		
		if self.vcaKSIsOn and self.spec_drivable.cruiseControl.state == 0 then 
			if math.abs( self.vcaKeepSpeed ) < 1 then 
				acceleration = 0
				handbrake    = true 
			else 
				self.spec_motorized.motor:setSpeedLimit( math.min( self:getSpeedLimit(true), math.abs(self.vcaKeepSpeed) ) )
				if self.vcaShuttleCtrl then 
					acceleration = 1
					brake        = false 
					if self.vcaShifterIndex <= 0 then 
						self:vcaSetState( "vcaShuttleFwd", (self.vcaKeepSpeed>0) )
					elseif self.vcaShuttleFwd ~= (self.vcaKeepSpeed>0) then 
						acceleration = 0
						handbrake    = true 
					end 
				elseif self.vcaKeepSpeed > 0 then 
					acceleration = self.spec_drivable.reverserDirection
					self.nextMovingDirection = 1
				else
					acceleration = -self.spec_drivable.reverserDirection
					self.nextMovingDirection = 1
				end 
			end 
		end 
	
		if self.vcaShuttleCtrl then 
			if self.vcaShuttleFwd then 
				self.nextMovingDirection = 1 
			else 
				self.nextMovingDirection = -1 
			end 
			
			if not self:getIsMotorStarted() then 
				acceleration = 0
				doHandbrake  = true 
			elseif g_gui:getIsGuiVisible() and self.spec_drivable.cruiseControl.state == 0 then 
				acceleration = 0
				doHandbrake  = true 
			elseif acceleration < -0.01 then 
				local lowSpeedBrake = 1.389e-4 - acceleration * 6.944e-4 -- 0.5 .. 3			
				if  math.abs( currentSpeed ) < lowSpeedBrake then 
					-- braking at low speed
					acceleration = 0
					doHandbrake  = true 
				end			
			elseif acceleration < 0 then 
				acceleration = 0				
			end 
			if self.vcaNeutral then 
				if acceleration > 0 then 
					acceleration = 0 
				end 
			end 
			if      self.spec_motorized.motor.vcaAutoStop
					and acceleration < 0.1 then 
				doHandbrake  = true 
			end		
		end 			
			
		if self.spec_drivable.cruiseControl.state == 0 and self.vcaLimitThrottle ~= nil and self.vcaInchingIsOn ~= nil and math.abs( acceleration ) > 0.01 then 
			local limitThrottleRatio     = 0.75
			local limitThrottleIfPressed = true
			if self.vcaLimitThrottle < 11 then
				limitThrottleIfPressed = false
				limitThrottleRatio     = 0.45 + 0.05 * self.vcaLimitThrottle
			else
				limitThrottleIfPressed = true
				limitThrottleRatio     = 1.5 - 0.05 * self.vcaLimitThrottle
			end
				
			if self.vcaInchingIsOn == limitThrottleIfPressed then
				acceleration = acceleration * limitThrottleRatio
			end
		end
	end 
	
	self.vcaNewAcc       = acceleration
	self.vcaNewHandbrake = doHandbrake
	stopAndGoBraking = true 
	
	if self.vcaShuttleCtrl then 
		self.spec_lights = nil
	end 
	
	local state, result = pcall( superFunc, self, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking ) 
	if not ( state ) then
		print("Error in updateWheelsPhysics :"..tostring(result))
		self.spec_lights = lightsBackup
		self.vcaShuttleCtrl  = false 
		self.vcaTransmission = 0 
	end
	
	if self.vcaShuttleCtrl then 
		self.spec_lights = lightsBackup
		if type( self.setBrakeLightsVisibility ) == "function" then 
			self:setBrakeLightsVisibility( brake )
		end 
		if type( self.setReverseLightsVisibility ) == "function" then 
			self:setReverseLightsVisibility( not self.vcaShuttleFwd )
		end 
	end 
	
	return result 
end 
WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction( WheelsUtil.updateWheelsPhysics, vehicleControlAddon.vcaUpdateWheelsPhysics )


--******************************************************************************************************************************************
-- increased minRPM
function vehicleControlAddon:getRequiredMotorRpmRange( superFunc, ... )
	if      self.vcaMinRpm ~= nil 
			and self.vcaMaxRpm ~= nil then 
		return self.vcaMinRpm, self.vcaMaxRpm 
	end 
	return superFunc( self, ... )
end 

VehicleMotor.getRequiredMotorRpmRange = Utils.overwrittenFunction( VehicleMotor.getRequiredMotorRpmRange, vehicleControlAddon.getRequiredMotorRpmRange )
--******************************************************************************************************************************************

function vehicleControlAddon.getGearIndex( mode, gear, range )
	local index 
	if     mode <= 1 then 
		index = 0
	elseif mode >= 5 then 
		index = gear 
	elseif mode >= 4 then 
		index = gear 
		if range >= 2 then 
			index = index + 6 
		end 
	elseif range <= 1 then 
		index = gear 
	elseif range == 2 then 
		index = gear + 2
	elseif range == 3 then 
		index = gear + 5
	else 
		index = gear + 8 
	end 
	return index 
end

function vehicleControlAddon:vcaUpdateGear( superFunc, acceleratorPedal, dt )
	
	local lastMinRpm  = Utils.getNoNil( self.vcaMinRpm, self.minRpm )
	local lastMaxRpm  = Utils.getNoNil( self.vcaMaxRpm, self.maxRpm )
	local lastFakeRpm = Utils.getNoNil( self.vcaFakeRpm,self.equalizedMotorRpm ) 
	self.vcaMinRpm    = nil 
	self.vcaMaxRpm    = nil 
	self.vcaFakeRpm   = nil
	local speed       = math.abs( self.vehicle.lastSpeedReal ) *3600
	local motorPtoRpm = math.min(PowerConsumer.getMaxPtoRpm(self.vehicle)*self.ptoMotorRpmRatio, self.maxRpm)
		
	if not ( self.vehicle:getIsVehicleControlledByPlayer() 
			 and ( self.vehicle.vcaTransmission ~= nil	
					or self.vehicle.vcaNeutral ) ) then 
		return superFunc( self, acceleratorPedal, dt )
	end 

	local fwd, curBrake
	local lastFwd  = Utils.getNoNil( self.vcaLastFwd )
	if self.vehicle.vcaShuttleCtrl then 
		fwd      = self.vehicle.vcaShuttleFwd 
		curBrake = math.max( 0, -self.vehicle.vcaOldAcc )
	elseif acceleratorPedal < 0 then 
		fwd      = false 
		curBrake = 0
	elseif acceleratorPedal > 0 then 
		fwd      = true 
		curBrake = 0
	else
		fwd      = lastFwd
		curBrake = Utils.getNoNil( self.vcaLastRealBrake, 0 )
	end 
	self.vcaLastFwd = fwd
	
	local newAcc = acceleratorPedal
	if fwd then 
		if newAcc < 0 then 
			newAcc = 0
		end 
		if self.vehicle.movingDirection < 0 then 
			speed = -speed 
		end 
	else 
		if newAcc > 0 then 
			newAcc = 0 
		end 
		if self.vehicle.movingDirection > 0 then 
			speed = -speed 
		end 
	end 
	if g_gui:getIsGuiVisible() and self.vehicle.spec_drivable.cruiseControl.state == 0 then 
		newAcc = 0
	end 
	
	--****************************************
-- handbrake
	if self.vehicle.vcaNeutral then 
		local rpm = math.max( self.minRpm, motorPtoRpm )
		local acc = math.abs( newAcc )
		local add = self.maxRpm - self.minRpm
		newAcc = 0
				
		if self.vehicle.vcaShuttleCtrl and self.vehicle.vcaOldAcc ~= nil then 
			acc =  self.vehicle.vcaOldAcc
		end
			
		if acc > 0 then 
			rpm = rpm + acc * ( self.maxRpm - rpm )
		end 
		
		if lastFakeRpm == nil then 
			lastFakeRpm = self.equalizedMotorRpm 
		end 
		self.vcaFakeRpm   = vehicleControlAddon.mbClamp( rpm, lastFakeRpm - 0.001 * dt * add, lastFakeRpm + 0.001 * dt * add )		
		self.vcaFakeTimer = 500 
	elseif self.vcaFakeTimer ~= nil then 
		if lastFakeRpm == nil then
			self.vcaFakeTimer = nil 
		else 
			local add = self.maxRpm - self.minRpm	
			self.vcaFakeRpm   = vehicleControlAddon.mbClamp( self.equalizedMotorRpm, lastFakeRpm - 0.001 * dt * add, lastFakeRpm + 0.001 * dt * add )	
			self.vcaFakeTimer = self.vcaFakeTimer - dt 
			if self.vcaFakeTimer <= 0 then 
				self.vcaFakeTimer = nil 
			end 
		end 
	end 
	
	local curAcc      = math.abs( newAcc )
	
	local transmission = vehicleControlAddon.transmissions[self.vehicle.vcaTransmission]
	
	if transmission == nil or not self.vehicle:getIsMotorStarted() or dt < 0 then 
		self.vcaClutchTimer   = nil
		self.vcaAutoDownTimer = nil
		self.vcaAutoUpTimer   = nil
		self.vcaAutoLowTimer  = nil
		self.vcaBrakeTimer    = nil
		self.vcaLoad          = nil
		self.vcaIncreaseRpm   = nil
		self.vcaAutoStop      = nil
	elseif self.vehicle.vcaTransmission == 1 then 
	--****************************************	
	-- IVT
		if motorPtoRpm > 0 then 
			newMinRpm = math.max( self.minRpm, motorPtoRpm * 0.95 )
			newMaxRpm = math.min( self.maxRpm, motorPtoRpm * 1.05 )
		else 
			newMinRpm = self.minRpm
			newMaxRpm = self.maxRpm
		end 
					
		if speed > 2 then 
			self.vcaIncreaseRpm = g_currentMission.time + 1000 
		end 
		
		local minReducedRpm = math.min( math.max( newMinRpm, 0.5*math.min( 2200, self.maxRpm ) ), newMaxRpm )
		if self.vehicle.spec_combine ~= nil then 
			minReducedRpm = math.min( math.max( newMinRpm, 0.8*math.min( 2200, self.maxRpm ) ), newMaxRpm )
		end 
		
		if speed > 0.5 and self.vcaIncreaseRpm ~= nil and g_currentMission.time < self.vcaIncreaseRpm  then 
			newMinRpm = minReducedRpm
		end
		minReducedRpm = minReducedRpm + 0.1 * self.maxRpm
			
		if self.vehicle.spec_combine == nil and self.vehicle.vcaLimitThrottle ~= nil and self.vehicle.vcaInchingIsOn ~= nil then 
				
			if self.vehicle.spec_drivable.cruiseControl.state == 0 then
					
				local limitThrottleRatio     = 0.75
				local limitThrottleIfPressed = true
				if self.vehicle.vcaLimitThrottle < 11 then
					limitThrottleIfPressed = false
					limitThrottleRatio     = 0.45 + 0.05 * self.vehicle.vcaLimitThrottle
				else
					limitThrottleIfPressed = true
					limitThrottleRatio     = 1.5 - 0.05 * self.vehicle.vcaLimitThrottle
				end
						
				if self.vehicle.vcaInchingIsOn == limitThrottleIfPressed then 
					newMaxRpm = math.max( minReducedRpm, math.min( newMaxRpm, self.maxRpm * limitThrottleRatio ) )
				end 
			end 
			
			local lowLoad = false 
			if     self.vcaChangeTime ~= nil and g_currentMission.time < self.vcaChangeTime + 5500 then
			elseif self.vehicle.spec_motorized.actualLoadPercentage < 0.5 then 	
				lowLoad = true 
			else 
				local l = ( self.vehicle.spec_motorized.actualLoadPercentage - 0.5 ) * 2
				if         fwd and self.differentialRotAcceleration > l and self.differentialRotAccelerationSmoothed > l then 
					lowLoad = true 
				elseif not fwd and self.differentialRotAcceleration <-l and self.differentialRotAccelerationSmoothed <-l then 
					lowLoad = true 
				end 
			end 
			
			if lowLoad then 
				local minRatio = self.minForwardGearRatio
				if not fwd then 
					minRatio     = self.minBackwardGearRatio
				end 
				local wheelRpm = (speed + 1 )/3.6 * vehicleControlAddon.factor30pi
				local newRpm   = wheelRpm * minRatio 
				if newRpm < minReducedRpm then 
					newRpm = minReducedRpm 
				end 
				if newRpm < newMaxRpm then 
					if self.vehicle.spec_motorized.actualLoadPercentage < 0.75 then 
						newMaxRpm = newRpm 
					else 
						newMaxRpm = newRpm + 4 * ( self.vehicle.spec_motorized.actualLoadPercentage - 0.75 ) * ( newMaxRpm - newRpm )
					end 
				end 
			else 
				newMinRpm = math.min( newMaxRpm, 0.72 * self.maxRpm )
			end 
		end 
		
		local deltaS, deltaF
		deltaS = self:getMaxRpm() * 0.0001 * dt
		deltaF = self:getMaxRpm() * 0.0002 * dt
		self.vcaMinRpm = vehicleControlAddon.mbClamp( newMinRpm, lastMinRpm - deltaS, math.max( lastMinRpm, self.lastRealMotorRpm + deltaF ) )
		self.vcaMaxRpm = vehicleControlAddon.mbClamp( newMaxRpm, math.max( lastMaxRpm, self.lastRealMotorRpm ) - deltaS, lastMaxRpm + deltaS )
		
		self.minGearRatio = self.maxRpm / ( self.vehicle.vcaMaxSpeed * vehicleControlAddon.factor30pi )
		self.maxGearRatio = 250 
		
		if not fwd then 
			self.minGearRatio = -self.minGearRatio
			self.maxGearRatio = -self.maxGearRatio
		end 
		
		if     curAcc > 0.1 then 
			self.vcaAutoStop = false 
		elseif lastFwd ~= fwd then 
			self.vcaAutoStop = true
		elseif speed < 3.6 and curBrake > 0.1 then 
			self.vcaAutoStop = true
		end 
				
		return newAcc

	elseif transmission ~= nil then 
	--****************************************	
	-- 4x4 / 4x4 PS / 2x6 / FPS 
	
		self.vcaMinRpm = self.minRpm
		self.vcaMaxRpm = self.maxRpm
		
		local initGear = transmission:initGears( self.vehicle ) 
				
		local isNeutral = self.vehicle.vcaNeutral 
									 or ( g_gui:getIsGuiVisible() and self.vehicle.spec_drivable.cruiseControl.state == 0 )
		               or self.vcaClutchTimer == nil 
									 or lastFwd ~= fwd 
									 or ( curAcc == 0 and curBrake > 0.1 )
		if     curAcc > 0.1 then 
			self.vcaAutoStop = false 
		elseif lastFwd ~= fwd then 
			self.vcaAutoStop = true
		end 
		if self.vcaAutoStop then 
			isNeutral = true 
		end 
		
		if self.gearChangeTimer == nil then 
			self.gearChangeTimer = 0
		elseif self.gearChangeTimer > 0 then 
			self.gearChangeTimer = self.gearChangeTimer - dt 
		end 
		if isNeutral then 
			self.vcaClutchTimer = VCAGlobals.clutchTimer 
			self.vcaAutoDownTimer = 0
			self.vcaAutoUpTimer   = VCAGlobals.clutchTimer
		elseif self.vcaClutchTimer > 0 then 
			self.vcaClutchTimer = self.vcaClutchTimer - dt
		end 
		if self.vcaLoad == nil or self.vcaLoad < self.vehicle.spec_motorized.actualLoadPercentage then 
			self.vcaLoad = self.vehicle.spec_motorized.actualLoadPercentage
		elseif curBrake >= 0.5 then 
		-- simulate high load for immediate down shift
			self.vcaLoad = 1
		elseif self.gearChangeTimer <= 0 then 
			self.vcaLoad = self.vcaLoad + 0.03 * ( self.vehicle.spec_motorized.actualLoadPercentage - self.vcaLoad )
		end 
						
		local gear  = transmission:getRatioIndex( self.vehicle.vcaGear, self.vehicle.vcaRange )		
		local ratio = transmission:getGearRatio( gear )
		if ratio == nil then 
			print("Error in vehicleControlAddonTransmission: ratio is nil")
			gear  = 1	
			ratio = 0.3
		end 
		local maxSpeed  = ratio * self.vehicle.vcaMaxSpeed 
		local wheelRpm  = self.vehicle.lastSpeedReal * 1000 * self.maxRpm / maxSpeed 
		local clutchRpm = wheelRpm
		local slip      = 0
		if self.gearChangeTimer <= 0 and not isNeutral then 
			clutchRpm = self.differentialRotSpeed * self.minGearRatio * vehicleControlAddon.factor30pi
			if clutchRpm > 0 or wheelRpm > 0 then 
				slip = ( clutchRpm - wheelRpm ) / math.max( clutchRpm, wheelRpm )
			else 
				slip = 1
			end 
		end 
		if self.vehicle.vcaSlip == nil then 
			self.vehicle.vcaSlip = 0 
		end 
		self.vehicle.vcaSlip = self.vehicle.vcaSlip + 0.05 * ( slip - self.vehicle.vcaSlip )
		
		self.vehicle.vcaDebugR = string.format("g: %2d, r: %5.3f, s: %5.1f, m: %4.0f, w: %4.0f, c: %4.0f",
																	gear, ratio, maxSpeed*3.6,
																	self.lastRealMotorRpm, wheelRpm, clutchRpm )
		
		
		--****************************************
		-- no automatic shifting during gear shift or if clutch is open
		if self.vcaAutoDownTimer == nil then 
			self.vcaAutoDownTimer = 0
		elseif self.vcaAutoDownTimer > 0 then 
			self.vcaAutoDownTimer = self.vcaAutoDownTimer - dt 
		end 		
		if self.vcaAutoUpTimer == nil then 
			self.vcaAutoUpTimer = VCAGlobals.clutchTimer
		elseif self.vcaAutoUpTimer > 0 then 
			self.vcaAutoUpTimer = self.vcaAutoUpTimer - dt 
		end 
		if self.vcaAutoLowTimer == nil then 
			self.vcaAutoLowTimer = 5000
		elseif self.vcaAutoLowTimer > 0 then 
			self.vcaAutoLowTimer = self.vcaAutoLowTimer - dt 
		end 
		if self.gearChangeTimer > 0 and self.vcaAutoDownTimer < 1000 then 
			self.vcaAutoDownTimer = 1000 
		end 
		
		if     self.vcaAutoStop then 
			self.vcaBrakeTimer = nil
		elseif curBrake >= 0.1 then 
			if self.vcaBrakeTimer == nil then  
				self.vcaBrakeTimer = 0
			else 
				self.vcaBrakeTimer = self.vcaBrakeTimer + dt
			end 
		elseif self.vcaBrakeTimer ~= nil then 
			self.vcaBrakeTimer = self.vcaBrakeTimer - dt
			if self.vcaBrakeTimer < 0 then 
				self.vcaBrakeTimer = nil
			end 
		end 

			-- no automatic shifting#
		if self.vcaClutchTimer > 0 and self.vcaAutoUpTimer < 500 then 
			self.vcaAutoUpTimer = 500 
		end 
		if self.gearChangeTimer > 0 and self.vcaAutoUpTimer < 1000 then 
			self.vcaAutoUpTimer = 1000 
		end 
		if curBrake >= 0.1 and self.vcaBrakeTimer ~= nil and self.vcaBrakeTimer > 500 then 
			self.vcaAutoDownTimer = 0
		end 
		if curAcc < 0.1 and curBrake < 0.1 and self.vcaAutoDownTimer < 3000 then  
			self.vcaAutoDownTimer = 3000 
		end 
		if self.gearChangeTimer > 0 and self.vcaAutoDownTimer < 1000 then 
			self.vcaAutoDownTimer = 1000 
		end 
		if curAcc < 0.1 and self.vcaAutoUpTimer < 1000 then 
			self.vcaAutoUpTimer = 1000 
		end 
		if self.vcaClutchTimer > 0 and self.vcaAutoUpTimer < 500 then 
			self.vcaAutoUpTimer = 500 
		end 
		if self.vcaLoad < 0.8 then 
			self.vcaAutoLowTimer = 5000 
		end 
		if curAcc < 0.1 and self.vcaAutoLowTimer < 2000 then 
			self.vcaAutoLowTimer = 2000
		end 
		if maxSpeed > 1.5 * self:getSpeedLimit() and self.vcaAutoDownTimer > 1000 then
			self.vcaAutoDownTimer = 1000
		end 
		
		local setLaunchGear = ( initGear or lastFwd ~= fwd or self.vehicle.vcaNeutral or self.vcaAutoStop )
		local newGear  = gear 
		if initGear then 
			newGear = self.vehicle.vcaLaunchGear
		elseif  self.vehicle.vcaAutoShift 
				and gear > self.vehicle.vcaLaunchGear
				and setLaunchGear
				and not ( self.vcaSetLaunchGear ) then 
			if self.vehicle.vcaShifterIndex <= 0 then 
				newGear = self.vehicle.vcaLaunchGear
			end 
		elseif self.vehicle.vcaAutoShift and self.gearChangeTimer <= 0 and not self.vehicle.vcaNeutral and self.vehicle.vcaShifterIndex <= 0 then
			local m1 = self.minRpm * 1.1
			local m4 = self.maxRpm * 0.975
			local m2 = math.min( m4, m1 / 0.72 )
			local m3 = math.max( m1, m4 * 0.72 )
			local autoMinRpm = m1 + self.vcaLoad * ( m3 - m1 )
			local autoMaxRpm = m3 + self.vcaLoad * ( m4 - m3 )
			if motorPtoRpm > 0 then 
				autoMaxRom = math.min( m4, motorPtoRpm * 1.101363 )
				autoMinRpm = math.max( m1, autoMaxRom * 0.8 )
			end 
					
			if clutchRpm > m4 and self.vcaAutoUpTimer > 0 then
				self.vcaAutoUpTimer = 0
			end 
			if self.vcaClutchTimer <= 0 and wheelRpm < m1 and gear > self.vehicle.vcaLaunchGear and self.vcaAutoDownTimer > 500 then 
				self.vcaAutoDownTimer = 500
			end 
			
			local lowGear = self.vehicle.vcaLaunchGear 
			if self.vcaAutoLowTimer <= 0 and self.vcaLoad > 0.8 then 
				lowGear = math.floor( lowGear * ( 1 - self.vcaLoad ) )
			end 
			
			local searchUp   = ( clutchRpm > autoMaxRpm and self.vcaAutoUpTimer  <= 0 )
			local searchDown = ( wheelRpm < autoMinRpm and self.vcaAutoDownTimer <= 0 )
			
			if isNeutral then
				searchDown = true
				searchUp   = false 
				lowGear    = self.vehicle.vcaLaunchGear
			end 
			
			gearlist = {}
			if searchUp or searchDown then 
				for i=1,transmission:getNumberOfRatios() do 
					if ( i < gear and searchDown and i >= lowGear ) or ( searchUp and i > gear )  then 
						table.insert( gearlist, i )
					end 
				end 
			end 
			
			if #gearlist > 0 then 
				local d = 0
				if wheelRpm < autoMinRpm then 
					d = autoMinRpm - wheelRpm
				end 
				if clutchRpm > autoMaxRpm then 
					d = math.max( d, clutchRpm - autoMaxRpm )
				end 
				d = d - 1
				local d1 = d
				local rr = wheelRpm
				for _,i in pairs( gearlist ) do 
					local rpm = wheelRpm * ratio / transmission:getGearRatio( i )
					local d2 = 0
					if rpm < autoMinRpm then 
						d2 = autoMinRpm - rpm
					end 
					rpm = clutchRpm * ratio / transmission:getGearRatio( i )
					if rpm > autoMaxRpm then 
						d2 = math.max( d2, rpm - autoMaxRpm )
					end 
					if d2 < d or ( d2 == d and searchUp ) then 
						newGear = i 
						d = d2
						rr = rpm
					end 
				end 
				
				self.vehicle.vcaDebugA = string.format( "%3.0f%%; %3.0f%%; %4.0f..%4.0f; %4.0f -> %4.0f; %d -> %d; %5.0f -> %5.0f",
																								curAcc*100,self.vcaLoad*100,autoMinRpm,autoMaxRpm,wheelRpm, rr,gear,newGear,d1,d )
			end 
		end

		self.vcaSetLaunchGear = setLaunchGear
		
		if gear ~= newGear then 
			if self.vehicle.vcaDebugA ~= nil then 
				vehicleControlAddon.debugPrint( g_currentMission.time.."; "..self.vehicle.vcaDebugA )
			end 
			
			local g, r = transmission:getBestGearRangeFromIndex( self.vehicle.vcaGear, self.vehicle.vcaRange, newGear )
			self.vehicle:vcaSetState( "vcaGear",  g )
			self.vehicle:vcaSetState( "vcaRange", r )
			
			gear     = transmission:getRatioIndex( g, r ) 
			ratio    = transmission:getGearRatio( gear )
			maxSpeed = ratio * self.vehicle.vcaMaxSpeed 
			wheelRpm = self.vehicle.lastSpeedReal * 1000 * self.maxRpm / maxSpeed 
		end 
		
		self.vehicle:vcaSetState("vcaBOVVolume",0)
		if not isNeutral then 
			local gearTime  = transmission.changeTimeGears
			local rangeTime = transmission.changeTimeRanges
			if gearTime < 1 then	
				gearTime = -1 
			end 
			if rangeTime < 1 then 
				rangeTime = -1
			end 
			
			if self.vcaLastRange ~= nil and self.vehicle.vcaRange ~= self.vcaLastRange and self.gearChangeTimer < rangeTime then 
				self.gearChangeTimer = rangeTime
				if self.vcaGearIndex ~= nil and self.vcaGearIndex < gear and rangeTime > 0 then 
					self.vehicle:vcaSetState("vcaBOVVolume",self.vcaLoad)
				end 
			end 
			if self.vcaLastGear ~= nil and self.vehicle.vcaGear ~= self.vcaLastGear and self.gearChangeTimer < gearTime then 
				self.gearChangeTimer = gearTime
				if self.vcaGearIndex ~= nil and self.vcaGearIndex < gear and gearTime > 0 then 
					self.vehicle:vcaSetState("vcaBOVVolume",self.vcaLoad)
				end 
			end 
		end 
		
		if self.vcaGearIndex ~= nil and self.vcaGearIndex ~= gear then 
			if gear > self.vcaGearIndex then 
				self.vcaAutoUpTimer	  = math.max( self.vcaAutoUpTimer	 , 500  + self.gearChangeTimer * 2 )
				self.vcaAutoDownTimer = math.max( self.vcaAutoDownTimer, 3000 + self.gearChangeTimer )
			else                                    
				self.vcaAutoUpTimer	  = math.max( self.vcaAutoUpTimer	 , 3000 + self.gearChangeTimer * 2 )
				self.vcaAutoDownTimer = math.max( self.vcaAutoDownTimer, 500  + self.gearChangeTimer )
			end
		else
			if wheelRpm < self.minRpm * 1.05 then 
				if isNeutral and curAcc < 0.1 then 
					self.vcaAutoStop = true 
				elseif not ( self.vcaAutoStop ) then 
					curAcc = 1
				end 
			end 
		end 
		
		self.vcaGearIndex = gear
		self.vcaLastGear  = self.vehicle.vcaGear
		self.vcaLastRange = self.vehicle.vcaRange
		
		self.minGearRatio = self.maxRpm / ( maxSpeed * vehicleControlAddon.factor30pi )
		self.maxGearRatio = self.minGearRatio 
				
		if self.gearChangeTimer > 0 then 
			newAcc              = 0
			self.minGearRatio   = 1
			self.maxGearRatio   = 250
			self.vcaClutchTimer = VCAGlobals.clutchTimer
			self.vcaMinRpm      = math.max( self.minRpm, self.lastRealMotorRpm - 0.004 * dt * ( self.maxRpm - self.minRpm ), motorPtoRpm )
			self.vcaMaxRpm      = self.vcaMinRpm
		elseif self.vcaClutchTimer > 0 then 
			if math.abs( self.gearRatio ) < self.minGearRatio * 1.1 and wheelRpm >= self.minRpm then 
				self.vcaClutchTimer = 0
			else
				local f = self.vcaClutchTimer / VCAGlobals.clutchTimer
				self.maxGearRatio = self.minGearRatio + f * ( self.maxForwardGearRatio - self.minGearRatio )
				if self.vcaFakeRpm ~= nil then 
					self.vcaMinRpm  = self.vcaFakeRpm
					self.vcaMaxRpm  = self.vcaFakeRpm
				else 
					self.vcaMinRpm  = math.max( self.minRpm, motorPtoRpm * 0.95, math.min( self.maxRpm, wheelRpm ) )
					self.vcaMaxRpm  = math.max( motorPtoRpm * 1.05, self.minRpm + f * ( self.maxRpm - self.minRpm ), self.lastRealMotorRpm - 0.004 * dt * ( self.maxRpm - self.minRpm ) )
				end 
			end 
		end  
		
		if not fwd then 
			self.minGearRatio = -self.minGearRatio
			self.maxGearRatio = -self.maxGearRatio
		end 
		
		return newAcc
	end 
	
--****************************************
-- standard / IVT
	if      self.minForwardGearRatio  ~= nil 
			and self.maxForwardGearRatio  ~= nil 
			and self.minBackwardGearRatio ~= nil 
			and self.maxBackwardGearRatio ~= nil then 
		if fwd then 
			self.minGearRatio = self.minForwardGearRatio
			self.maxGearRatio = self.maxForwardGearRatio
		else 
			self.minGearRatio = -self.minBackwardGearRatio
			self.maxGearRatio = -self.maxBackwardGearRatio
		end 
	end 
	
	return newAcc
end 

VehicleMotor.updateGear = Utils.overwrittenFunction( VehicleMotor.updateGear, vehicleControlAddon.vcaUpdateGear )

function vehicleControlAddon:vcaSmoothAcc( acceleratorPedal, brakePedal, dt )
	self.vcaLastRealAcc   = acceleratorPedal
	self.vcaLastRealBrake = brakePedal 
end 

VehicleMotor.getSmoothedAcceleratorAndBrakePedals = Utils.appendedFunction( VehicleMotor.getSmoothedAcceleratorAndBrakePedals, vehicleControlAddon.vcaSmoothAcc )
--******************************************************************************************************************************************

function vehicleControlAddon:vcaGetEqualizedMotorRpm( superFunc ) 
	if self.vcaFakeRpm ~= nil then 
		return self.vcaFakeRpm
	end 
	return superFunc( self )
end 

VehicleMotor.getEqualizedMotorRpm = Utils.overwrittenFunction( VehicleMotor.getEqualizedMotorRpm, vehicleControlAddon.vcaGetEqualizedMotorRpm )
--******************************************************************************************************************************************

function vehicleControlAddon:vcaGetMotorAppliedTorque( superFunc ) 
	if self.vehicle.vcaTransmission ~= nil and self.vehicle.vcaTransmission > 1 and self.gearChangeTimer > 0 then 
		return 0
	end 
	return superFunc( self )
end 

VehicleMotor.getMotorAppliedTorque = Utils.overwrittenFunction( VehicleMotor.getMotorAppliedTorque, vehicleControlAddon.vcaGetMotorAppliedTorque )
--******************************************************************************************************************************************


function vehicleControlAddon:vcaOnSetCamera( old, new, noEventSend ) 
	self.vcaCameraIsOn = new
	if self:vcaIsValidCam() then
		self.vcaCameras[self.spec_enterable.camIndex].rotation = new
		if new and not ( old ) then
			self.vcaCameras[self.spec_enterable.camIndex].zero = self.spec_enterable.cameras[self.spec_enterable.camIndex].origRotY
			self.vcaCameras[self.spec_enterable.camIndex].last = self.spec_enterable.cameras[self.spec_enterable.camIndex].rotY
			self.vcaCameras[self.spec_enterable.camIndex].lastCamFwd = nil
		end
	end
end

function vehicleControlAddon:vcaOnSetReverse( old, new, noEventSend ) 
	self.vcaReverseIsOn = new
	if self:vcaIsValidCam() then
		self.vcaCameras[self.spec_enterable.camIndex].rev = new
		self.vcaCameras[self.spec_enterable.camIndex].lastCamFwd = nil
	end
end

function vehicleControlAddon:vcaOnSetFactor( old, new, noEventSend )
	self.vcaExponent = new
	self.vcaFactor   = 1.1 ^ new
end

function vehicleControlAddon:vcaOnSetSnapAngle( old, new, noEventSend )
	if new < 1 then 
		self.vcaSnapAngle = 1 
	elseif new > table.getn( vehicleControlAddon.snapAngles ) then 
		self.vcaSnapAngle = table.getn( vehicleControlAddon.snapAngles ) 
	else 
		self.vcaSnapAngle = new 
	end 
end 

function vehicleControlAddon:vcaOnSetSnapIsOn( old, new, noEventSend )
	self.vcaSnapIsOn = new 
	
  if      ( old == nil or new ~= old )
			and self.isClient
			and self:getIsEntered()
			and self:getIsVehicleControlledByPlayer() then
		if new and vehicleControlAddon.snapOnSample ~= nil then
      playSample(vehicleControlAddon.snapOnSample, 1, 0.2, 0, 0, 0)
		elseif not new and vehicleControlAddon.snapOffSample ~= nil then
      playSample(vehicleControlAddon.snapOffSample, 1, 0.2, 0, 0, 0)
		end 
	end 
end 

function vehicleControlAddon:vcaOnSetDirection( old, new, noEventSend )
	if self.vcaShuttleCtrl then 
		self.vcaShuttleFwd = new 
		if self.vcaKSIsOn then 
			local sign = 1
			if not self.vcaShuttleFwd then 
				sign = -1 
			end 
			self:vcaSetState( "vcaKeepSpeed", sign * math.abs( self.vcaKeepSpeed ), noEventSend )
		end 
	end 
end 

function vehicleControlAddon:vcaOnSetGearChanged( old, new, noEventSend )
	if      ( old == nil or new > old )
			and self.isClient
			and self:getIsEntered()
			and self:getIsVehicleControlledByPlayer()
			and vehicleControlAddon.bovSample ~= nil then 
		local v = 0.2 * new 
		if isSamplePlaying( vehicleControlAddon.bovSample ) then
			setSampleVolume( vehicleControlAddon.bovSample, v )
		else 
			playSample( vehicleControlAddon.bovSample, 1, v, 0, 0, 0)
		end 
	end 
	self.vcaBOVVolume = new 
end 

function vehicleControlAddon:vcaOnSetGear( old, new, noEventSend )
	print("vcaOnSetGear: "..string(old).."->"..tostring(new))
	self.vcaGear = new 
	printCallstack()
end
 
function vehicleControlAddon:vcaOnSetRange( old, new, noEventSend )
	print("vcaOnSetRange: "..string(old).."->"..tostring(new))
	self.vcaRange = new 
	printCallstack()
end

function vehicleControlAddon:vcaOnSetWarningText( old, new, noEventSend )
	self.vcaWarningText  = new
  self.vcaWarningTimer = 2000
end

function vehicleControlAddon:vcaGetAbsolutRotY( camIndex )
	if     self.spec_enterable.cameras == nil
			or self.spec_enterable.cameras[camIndex] == nil then
		return 0
	end
  return vehicleControlAddon.vcaGetRelativeYRotation( self.spec_enterable.cameras[camIndex].cameraNode, self.spec_wheels.steeringCenterNode )
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



function vehicleControlAddon:vcaShowSettingsUI()
	if g_gui:getIsGuiVisible() then
		return 
	end
	if g_vehicleControlAddonScreen == nil then
		-- settings screen
		g_vehicleControlAddonScreen = vehicleControlAddonScreen:new()
		for n,t in pairs( vehicleControlAddon_Register.mogliTexts ) do
			g_vehicleControlAddonScreen.mogliTexts[n] = t
		end
		g_gui:loadGui(vehicleControlAddon_Register.g_currentModDirectory .. "vehicleControlAddonScreen.xml", "vehicleControlAddonScreen", g_vehicleControlAddonScreen)	
		g_vehicleControlAddonScreen:setTitle( "vcaVERSION" )
	end

	self.vcaUI = {}
	self.vcaUI.vcaExponent_V = { -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5 }
	self.vcaUI.vcaExponent = {}
	for i,e in pairs( self.vcaUI.vcaExponent_V ) do
		self.vcaUI.vcaExponent[i] = string.format("%3.0f %%", 100 * ( 1.1 ^ e ), true )
	end
	self.vcaUI.vcaLimitThrottle   = {}
	for i=1,20 do
	  self.vcaUI.vcaLimitThrottle[i] = string.format("%3d %% / %3d %%", 45 + 5 * math.min( i, 11 ), 150 - 5 * math.max( i, 10 ), true )
	end
	self.vcaUI.vcaSnapAngle = {}
	for i,v in pairs( vehicleControlAddon.snapAngles ) do 
		self.vcaUI.vcaSnapAngle[i] = string.format( "%3d°", v )
	end 
	self.vcaUI.vcaBrakeForce_V = { 0, 0.05, 0.10, 0.15, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 }
	self.vcaUI.vcaBrakeForce = {}
	for i,e in pairs( self.vcaUI.vcaBrakeForce_V ) do
		self.vcaUI.vcaBrakeForce[i] = string.format("%3.0f %%", 100 * e )
	end
	self.vcaUI.vcaTransmission = { "off" }
	for _,transmission in pairs(vehicleControlAddon.transmissions) do 
		table.insert( self.vcaUI.vcaTransmission, transmission:getName() )
	end 
	
	local m = vehicleControlAddon.getDefaultMaxSpeed( self )
	self.vcaUI.vcaMaxSpeed_V = { 7, 8.889, 11.944, 16.111, 25, 33.333, 50 }
	local found = -1 
	for i,v in pairs(self.vcaUI.vcaMaxSpeed_V) do
		if math.abs( m-v ) < 1 then 
			self.vcaUI.vcaMaxSpeed_V[i] = m 
			found = 0
			break 
		elseif v > m and found < 0 then 
			found = i 
		end 
	end 
	if found < 0 then 
		table.insert( self.vcaUI.vcaMaxSpeed_V, m ) 
	elseif found > 0 then 
		table.insert( self.vcaUI.vcaMaxSpeed_V, found, m ) 
	end 
	self.vcaUI.vcaMaxSpeed = {}
	for i,v in pairs(self.vcaUI.vcaMaxSpeed_V) do
		self.vcaUI.vcaMaxSpeed[i] = string.format( "%3.0f km/h", v*3.6 )
	end
	self.vcaUI.vcaLaunchGear = {}
	local transmission = vehicleControlAddon.transmissions[self.vcaTransmission]
	if transmission ~= nli then 
		for i=1,transmission:getNumberOfRatios() do
			self.vcaUI.vcaLaunchGear[i] = string.format( "%3.0f km/h", transmission:getGearRatio( i )*3.6*self.vcaMaxSpeed )
		end 
	end 
	
	
	g_vehicleControlAddonScreen:setVehicle( self )
	g_gui:showGui( "vehicleControlAddonScreen" )
end

function vehicleControlAddon:vcaUIGetvcaExponent()
	for i,e in pairs( self.vcaUI.vcaExponent_V ) do
		if math.abs( e - self.vcaExponent ) < 0.5 then
			return i
		end
	end
	return 7
end

function vehicleControlAddon:vcaUISetvcaExponent( value )
	if self.vcaUI.vcaExponent_V[value] ~= nil then
		self:vcaSetState( "vcaExponent", self.vcaUI.vcaExponent_V[value] )
	end
end

function vehicleControlAddon:vcaUIGetvcaBrakeForce()
	local d = 2
	local j = 4
	for i,e in pairs( self.vcaUI.vcaBrakeForce_V ) do
		if math.abs( e - self.vcaBrakeForce ) < d then
			d = math.abs( e - self.vcaBrakeForce )
			j = i
		end
	end
	return j
end

function vehicleControlAddon:vcaUISetvcaBrakeForce( value )
	if self.vcaUI.vcaBrakeForce_V[value] ~= nil then
		self:vcaSetState( "vcaBrakeForce", self.vcaUI.vcaBrakeForce_V[value] )
	end
end

function vehicleControlAddon:vcaUIGetvcaMaxSpeed()
	local d, j
	for i,e in pairs( self.vcaUI.vcaMaxSpeed_V ) do
		local f = math.abs( e - self.vcaMaxSpeed )
		if d == nil or d > f then 
			d = f 
			j = i 
		end
	end
	return j
end

function vehicleControlAddon:vcaUISetvcaMaxSpeed( value )
	if self.vcaUI.vcaMaxSpeed_V[value] ~= nil then
		self:vcaSetState( "vcaMaxSpeed", self.vcaUI.vcaMaxSpeed_V[value] )
	end
end




