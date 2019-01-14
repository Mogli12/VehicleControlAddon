--
-- keyboardSteerMogli
-- This is the specialization for keyboardSteerMogli
--

--***************************************************************
source(Utils.getFilename("mogliBase.lua", g_currentModDirectory))
_G[g_currentModName..".mogliBase"].newClass( "keyboardSteerMogli" )
--***************************************************************

function keyboardSteerMogli.prerequisitesPresent(specializations)
	return true
end

function keyboardSteerMogli.registerEventListeners(vehicleType)
	for _,n in pairs( { "onLoad", "onPostLoad", "onUpdate", "onDraw", "onLeaveVehicle", "onReadStream", "onWriteStream", "saveToXMLFile", "onRegisterActionEvents" } ) do
		SpecializationUtil.registerEventListener(vehicleType, n, keyboardSteerMogli)
	end 
end 

KSMGlobals = {}
keyboardSteerMogli.snapAngles = { 5, 7.5, 15, 22.5, 45, 90 }
keyboardSteerMogli.gearRatios = { 0.120, 0.145, 0.176, 0.213, 0.259, 0.314, 0.381, 0.462, 0.560, 0.680, 0.824, 1.000 }
keyboardSteerMogli.factor30pi = 9.5492965855137201461330258023509
function keyboardSteerMogli.globalsReset( createIfMissing )
	KSMGlobals                     = {}
	KSMGlobals.cameraRotFactor     = 0
	KSMGlobals.cameraRotFactorRev  = 0
	KSMGlobals.cameraRotTime       = 0
  KSMGlobals.timer4Reverse       = 0
  KSMGlobals.limitThrottle       = 0
  KSMGlobals.snapAngle           = 0
  KSMGlobals.brakeForceFactor    = 0
  KSMGlobals.snapAngleHudX       = 0
  KSMGlobals.snapAngleHudY       = 0
  KSMGlobals.transmission        = 0
  KSMGlobals.launchGear          = 0
	KSMGlobals.clutchTimer         = 0
 	KSMGlobals.debugPrint          = false
	
-- defaults	
	KSMGlobals.adaptiveSteering    = false
  KSMGlobals.camOutsideRotation  = false
  KSMGlobals.camInsideRotation   = false
 	KSMGlobals.camReverseRotation  = false
 	KSMGlobals.camRevOutRotation   = false
	KSMGlobals.shuttleControl      = false	
	KSMGlobals.peekLeftRight       = false	
	
	local file
	file = keyboardSteerMogli.baseDirectory.."keyboardSteerMogliConfig.xml"
	if fileExists(file) then	
		keyboardSteerMogli.globalsLoad( file, "KSMGlobals", KSMGlobals )	
	else
		print("ERROR: NO GLOBALS IN "..file)
	end
	
	file = getUserProfileAppPath().. "modsSettings/keyboardSteerMogliConfig.xml"
	if fileExists(file) then	
		print('Loading "modsSettings/keyboardSteerMogliConfig.xml"...')
		keyboardSteerMogli.globalsLoad( file, "KSMGlobals", KSMGlobals )	
	elseif createIfMissing then
		keyboardSteerMogli.globalsCreate( file, "KSMGlobals", KSMGlobals, true )	
	end
	
	print("keyboardSteerMogli initialized");
end

keyboardSteerMogli.globalsReset(true)

function keyboardSteerMogli.debugPrint( ... )
	if KSMGlobals.debugPrint then
		print( ... )
	end
end

function keyboardSteerMogli:ksmIsValidCam( index, createIfMissing )
	local i = Utils.getNoNil( index, self.spec_enterable.camIndex )
	
	if      self.spec_enterable            ~= nil 
			and self.spec_enterable.cameras    ~= nil 
			and i ~= nil 
			and self.spec_enterable.cameras[i] ~= nil 
			and self.spec_enterable.cameras[i].vehicle == self
			and self.spec_enterable.cameras[i].isRotatable then
		if self.ksmCameras[i] == nil then
			if createIfMissing then
				self.ksmCameras[i] = { rotation = keyboardSteerMogli.getDefaultRotation( self, i ),
															 rev      = keyboardSteerMogli.getDefaultReverse( self, i ),
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

function keyboardSteerMogli:onLoad(savegame)
	self.ksmDisabled      = false 
	self.ksmScaleFx       = keyboardSteerMogli.ksmScaleFx
	self.ksmSetState      = keyboardSteerMogli.mbSetState
	self.ksmIsValidCam    = keyboardSteerMogli.ksmIsValidCam
	self.ksmGetCurrentCamRot = keyboardSteerMogli.ksmGetCurrentCamRot

	keyboardSteerMogli.registerState( self, "ksmSteeringIsOn", KSMGlobals.adaptiveSteering )
	keyboardSteerMogli.registerState( self, "ksmShuttleCtrl",  KSMGlobals.shuttleControl )
	keyboardSteerMogli.registerState( self, "ksmPeekLeftRight",KSMGlobals.peekLeftRight )
	keyboardSteerMogli.registerState( self, "ksmShuttleFwd",   true )
	keyboardSteerMogli.registerState( self, "ksmCamFwd"      , true )
	keyboardSteerMogli.registerState( self, "ksmCameraIsOn"  , false, keyboardSteerMogli.ksmOnSetCamera )
	keyboardSteerMogli.registerState( self, "ksmReverseIsOn" , false, keyboardSteerMogli.ksmOnSetReverse )
	keyboardSteerMogli.registerState( self, "ksmExponent"    , 1    , keyboardSteerMogli.ksmOnSetFactor )
	keyboardSteerMogli.registerState( self, "ksmWarningText" , ""   , keyboardSteerMogli.ksmOnSetWarningText )
	keyboardSteerMogli.registerState( self, "ksmLimitThrottle",KSMGlobals.limitThrottle )
	keyboardSteerMogli.registerState( self, "ksmSnapAngle"   , KSMGlobals.snapAngle, keyboardSteerMogli.ksmOnSetSnapAngle )
	keyboardSteerMogli.registerState( self, "ksmSnapIsOn" ,    false, keyboardSteerMogli.ksmOnSetSnapIsOn )
	keyboardSteerMogli.registerState( self, "ksmInchingIsOn" , false )
	keyboardSteerMogli.registerState( self, "ksmNoAutoRotBack",false )
	keyboardSteerMogli.registerState( self, "ksmBrakeForce",   KSMGlobals.brakeForceFactor )
	keyboardSteerMogli.registerState( self, "ksmTransmission", keyboardSteerMogli.getDefaultTransmission( self ) )
	keyboardSteerMogli.registerState( self, "ksmMaxSpeed",     keyboardSteerMogli.getDefaultMaxSpeed( self ) )
	keyboardSteerMogli.registerState( self, "ksmGear",         0 )
	keyboardSteerMogli.registerState( self, "ksmRange",        0 )
	keyboardSteerMogli.registerState( self, "ksmNeutral",      false )
	keyboardSteerMogli.registerState( self, "ksmAutoShift",    false )
	keyboardSteerMogli.registerState( self, "ksmLimitSpeed",   true )
	keyboardSteerMogli.registerState( self, "ksmLaunchGear",   KSMGlobals.launchGear )
	keyboardSteerMogli.registerState( self, "ksmBOVVolume",    0, keyboardSteerMogli.ksmOnSetGearChanged )
	
	self.ksmFactor        = 1
	self.ksmReverseTimer  = 1.5 / KSMGlobals.timer4Reverse
	self.ksmMovingDir     = 0
	self.ksmLastFactor    = 0
	self.ksmWarningTimer  = 0
	self.ksmShifter7isR1  = nil 
	
	self.ksmCameras = {}
	
	for i,c in pairs(self.spec_enterable.cameras) do
		self:ksmIsValidCam( i, true )
	end

	if self.isClient then 
		if keyboardSteerMogli.snapOnSample == nil then 
			local fileName = Utils.getFilename( "GPS_on.ogg", keyboardSteerMogli.baseDirectory )
			keyboardSteerMogli.snapOnSample = createSample("AutoSteerOnSound")
			loadSample(keyboardSteerMogli.snapOnSample, fileName, false)
		end 
		
		if keyboardSteerMogli.snapOffSample == nil then 
			local fileName = Utils.getFilename( "GPS_off.ogg", keyboardSteerMogli.baseDirectory )
			keyboardSteerMogli.snapOffSample = createSample("AutoSteerOffSound")
			loadSample(keyboardSteerMogli.snapOffSample, fileName, false)
		end 
		
		if keyboardSteerMogli.bovSample == nil then 
			local fileName = Utils.getFilename( "blowOffVentil.ogg", keyboardSteerMogli.baseDirectory )
			keyboardSteerMogli.bovSample = createSample("keyboardSteerMogliBOVSample")
			loadSample(keyboardSteerMogli.bovSample, fileName, false)
		end 	
	end 	
	
	if keyboardSteerMogli.ovArrowUpWhite == nil then
		keyboardSteerMogli.ovArrowUpWhite   = createImageOverlay( Utils.getFilename( "arrow_up_white.dds",   keyboardSteerMogli.baseDirectory ))
		keyboardSteerMogli.ovArrowUpGray    = createImageOverlay( Utils.getFilename( "arrow_up_gray.dds",    keyboardSteerMogli.baseDirectory ))
		keyboardSteerMogli.ovArrowDownWhite = createImageOverlay( Utils.getFilename( "arrow_down_white.dds", keyboardSteerMogli.baseDirectory ))
		keyboardSteerMogli.ovArrowDownGray  = createImageOverlay( Utils.getFilename( "arrow_down_gray.dds",  keyboardSteerMogli.baseDirectory ))
		keyboardSteerMogli.ovHandBrakeUp    = createImageOverlay( Utils.getFilename( "hand_brake_up.dds",    keyboardSteerMogli.baseDirectory ))
		keyboardSteerMogli.ovHandBrakeDown  = createImageOverlay( Utils.getFilename( "hand_brake_down.dds",  keyboardSteerMogli.baseDirectory ))
	end 
end

function keyboardSteerMogli:onPostLoad(savegame)
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		local key     = savegame.key .."."..keyboardSteerMogli_Register.specName 
		local b, i, f
		
		keyboardSteerMogli.debugPrint("loading... ("..tostring(key)..")")
		
		b = getXMLBool(xmlFile, key.."#steering")
		keyboardSteerMogli.debugPrint("steering: "..tostring(b))
		if b ~= nil then 
			self:ksmSetState( "ksmSteeringIsOn", b )
		end 
		
		b = getXMLBool(xmlFile, key.."#shuttle")
		keyboardSteerMogli.debugPrint("shuttle: "..tostring(b))
		if b ~= nil then 
			self:ksmSetState( "ksmShuttleCtrl", b )
		end 
		
		b = getXMLBool(xmlFile, key.."#peek")
		keyboardSteerMogli.debugPrint("peek: "..tostring(b))
		if b ~= nil then 
			self:ksmSetState( "ksmPeekLeftRight", b )
		end 
		
		b = getXMLBool(xmlFile, key.."#autoShift")
		keyboardSteerMogli.debugPrint("autoShift: "..tostring(b))
		if b ~= nil then 
			self:ksmSetState( "ksmAutoShift", b )
		end 
		
		b = getXMLBool(xmlFile, key.."#limitSpeed")
		keyboardSteerMogli.debugPrint("limitSpeed: "..tostring(b))
		if b ~= nil then 
			self:ksmSetState( "ksmLimitSpeed", b )
		end 
		
		i = getXMLInt(xmlFile, key.."#exponent")
		keyboardSteerMogli.debugPrint("exponent: "..tostring(i))
		if i ~= nil then 
			self:ksmSetState( "ksmExponent", i )
		end 
		
		i = getXMLInt(xmlFile, key.."#throttle")
		keyboardSteerMogli.debugPrint("throttle: "..tostring(i))
		if i ~= nil then 
			self:ksmSetState( "ksmLimitThrottle", i )
		end 
		
		i = getXMLInt(xmlFile, key.."#snapAngle")
		keyboardSteerMogli.debugPrint("snapAngle: "..tostring(i))
		if i ~= nil then 
			self:ksmSetState( "ksmSnapAngle", i )
		end 
		
		f = getXMLFloat(xmlFile, key.."#brakeForce")
		keyboardSteerMogli.debugPrint("brakeForce: "..tostring(f))
		if f ~= nil then 
			self:ksmSetState( "ksmBrakeForce", f )
		end 
		
		i = getXMLInt(xmlFile, key.."#launchGear")
		keyboardSteerMogli.debugPrint("launchGear: "..tostring(i))
		if i ~= nil then 
			self:ksmSetState( "ksmLaunchGear", i )
		end 
		
		i = getXMLInt(xmlFile, key.."#transmission")
		keyboardSteerMogli.debugPrint("transmission: "..tostring(i))
		if i ~= nil then 
			self:ksmSetState( "ksmTransmission", i )
		end 
		
		f = getXMLFloat(xmlFile, key.."#maxSpeed")
		keyboardSteerMogli.debugPrint("maxSpeed: "..tostring(f))
		if f ~= nil then 
			self:ksmSetState( "ksmMaxSpeed", f )
		end 
				
		i = 0
		while true do 
			local cKey = string.format( "%s.camera(%d)", key, i )
			i = i + 1
			local j = getXMLInt(xmlFile, cKey.."#index")
			if j == nil then	
				break 
			end 
			if self:ksmIsValidCam( j, true ) then
				b = getXMLBool(xmlFile, cKey.."#rotation")
				keyboardSteerMogli.debugPrint("rotation["..tostring(j).."]: "..tostring(b))
				if b ~= nil then 
					self.ksmCameras[j].rotation = b
				end 
				
				b = getXMLBool(xmlFile, cKey.."#reverse")
				keyboardSteerMogli.debugPrint("reverse["..tostring(j).."]: "..tostring(b))
				if b ~= nil then 
					self.ksmCameras[j].rev = b
				end 
			end 
		end 
	end 
end 

function keyboardSteerMogli:saveToXMLFile(xmlFile, key)
	if self.ksmSteeringIsOn ~= nil and self.ksmSteeringIsOn ~= KSMGlobals.adaptiveSteering then
		setXMLBool(xmlFile, key.."#steering", self.ksmSteeringIsOn)
	end
	if self.ksmShuttleCtrl ~= nil and self.ksmShuttleCtrl ~= KSMGlobals.shuttleControl then
		setXMLBool(xmlFile, key.."#shuttle", self.ksmShuttleCtrl)
	end
	if self.ksmPeekLeftRight ~= nil and self.ksmPeekLeftRight ~= KSMGlobals.peekLeftRight then
		setXMLBool(xmlFile, key.."#peek", self.ksmPeekLeftRight)
	end
	if self.ksmAutoShift then
		setXMLBool(xmlFile, key.."#autoShift", self.ksmAutoShift)
	end
	if not self.ksmLimitSpeed then
		setXMLBool(xmlFile, key.."#limitSpeed", self.ksmLimitSpeed)
	end
	if self.ksmExponent ~= nil and math.abs( self.ksmExponent - 1 ) > 1E-3 then
		setXMLInt(xmlFile, key.."#exponent", self.ksmExponent)
	end
	if self.ksmLimitThrottle ~= nil and math.abs( self.ksmLimitThrottle - KSMGlobals.limitThrottle ) > 1E-3 then
		setXMLInt(xmlFile, key.."#throttle", self.ksmLimitThrottle)
	end
	if self.ksmSnapAngle ~= nil and math.abs( self.ksmSnapAngle - KSMGlobals.snapAngle ) > 1E-3 then
		setXMLInt(xmlFile, key.."#snapAngle", self.ksmSnapAngle)
	end
	if self.ksmBrakeForce ~= nil and math.abs( self.ksmBrakeForce - KSMGlobals.brakeForceFactor ) > 1E-3 then
		setXMLFloat(xmlFile, key.."#brakeForce", self.ksmBrakeForce)
	end
	if self.ksmLaunchGear ~= nil and math.abs( self.ksmLaunchGear - KSMGlobals.launchGear ) > 1E-3 then
		setXMLInt(xmlFile, key.."#launchGear", self.ksmLaunchGear)
	end
	if self.ksmTransmission ~= nil and math.abs( self.ksmTransmission - keyboardSteerMogli.getDefaultTransmission( self ) ) > 1E-3 then
		setXMLInt(xmlFile, key.."#transmission", self.ksmTransmission)
	end
	if self.ksmMaxSpeed ~= nil and math.abs( self.ksmMaxSpeed - keyboardSteerMogli.getDefaultMaxSpeed( self ) ) > 1E-3 then
		setXMLFloat(xmlFile, key.."#maxSpeed", self.ksmMaxSpeed)
	end
	
	local i = 0
	for j,b in pairs(self.ksmCameras) do
		local addI = true  
		local cKey = string.format( "%s.camera(%d)", key, i )
		if b.rotation ~= keyboardSteerMogli.getDefaultRotation( self, j ) then
			if addI then 
				addI = false 
				i = i + 1
				setXMLInt(xmlFile, cKey.."#index", j)
			end 
			setXMLBool(xmlFile, cKey.."#rotation", b.rotation)
		end
		if b.rev ~= keyboardSteerMogli.getDefaultReverse( self, j ) then
			if addI then 
				addI = false 
				i = i + 1
				setXMLInt(xmlFile, cKey.."#index", j)
			end 
			setXMLBool(xmlFile, cKey.."#reverse", b.rev)
		end
	end
end 

function keyboardSteerMogli:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	if isOnActiveVehicle then
		if self.ksmActionEvents == nil then 
			self.ksmActionEvents = {}
		else	
			self:clearActionEventsTable( self.ksmActionEvents )
		end 
		
		for _,actionName in pairs({ "ksmSETTINGS",  
                                "ksmUP",        
                                "ksmDOWN",      
                                "ksmLEFT",      
                                "ksmRIGHT",     
                                "ksmDIRECTION",     
                                "ksmFORWARD",     
                                "ksmREVERSE",
																"ksmNO_ARB",
																"ksmINCHING",
                                "ksmSNAP",
																"ksmGearUp",
																"ksmGearDown",
																"ksmRangeUp", 
																"ksmRangeDown",
																"ksmNeutral",
																"ksmShifter1",
																"ksmShifter2",
																"ksmShifter3",
																"ksmShifter4",
																"ksmShifter5",
																"ksmShifter6",
																"ksmShifter7",
																"ksmClutchKey",
																"AXIS_MOVE_SIDE_VEHICLE" }) do
																
			local isPressed = false 
			if     actionName == "AXIS_MOVE_SIDE_VEHICLE"
					or actionName == "ksmUP"
					or actionName == "ksmDOWN"
					or actionName == "ksmLEFT"
					or actionName == "ksmRIGHT" 
					or actionName == "ksmINCHING"
					or actionName == "ksmShifter1"
					or actionName == "ksmShifter2"
					or actionName == "ksmShifter3"
					or actionName == "ksmShifter4"
					or actionName == "ksmShifter5"
					or actionName == "ksmShifter6"
					or actionName == "ksmShifter7"
					or actionName == "ksmClutchKey"
					or actionName == "ksmNO_ARB" then 
				isPressed = true 
			end 
			
			local _, eventName = self:addActionEvent(self.ksmActionEvents, InputAction[actionName], self, keyboardSteerMogli.actionCallback, isPressed, true, false, true, nil);

		--local __, eventName = InputBinding.registerActionEvent(g_inputBinding, actionName, self, keyboardSteerMogli.actionCallback ,false ,true ,false ,true)
			if      g_inputBinding                   ~= nil 
					and g_inputBinding.events            ~= nil 
					and g_inputBinding.events[eventName] ~= nil
					and ( actionName == "ksmSETTINGS"
					   or ( self.ksmShuttleCtrl and actionName == "ksmDIRECTION" ) ) then 
				if isSelected then
					g_inputBinding.events[eventName].displayPriority = 1
				elseif  isOnActiveVehicle then
					g_inputBinding.events[eventName].displayPriority = 3
				end
			end
		end
	end
end

function keyboardSteerMogli:actionCallback(actionName, keyStatus, arg4, arg5, arg6)

	if actionName ~= "AXIS_MOVE_SIDE_VEHICLE" then 
		keyboardSteerMogli.debugPrint( 'keyboardSteerMogli:actionCallback( "'..tostring(actionName)..'", '..tostring(keyStatus)..' )' )
	end 
	
	if     actionName == "AXIS_MOVE_SIDE_VEHICLE" and math.abs( keyStatus ) > 0.05 then 
		self:ksmSetState( "ksmSnapIsOn", false )
	elseif actionName == "ksmUP"
			or actionName == "ksmDOWN"
			or actionName == "ksmLEFT"
			or actionName == "ksmRIGHT" then

		if not ( self.ksmPeekLeftRight ) then 
			if     actionName == "ksmUP" then
				self.ksmNewRotCursorKey = 0
			elseif actionName == "ksmDOWN" then
				self.ksmNewRotCursorKey = math.pi
			elseif actionName == "ksmLEFT" then
				if not ( self.ksmCamFwd ) then
					self.ksmNewRotCursorKey =  0.7*math.pi
				else 
					self.ksmNewRotCursorKey =  0.3*math.pi
				end 
			elseif actionName == "ksmRIGHT" then
				if not ( self.ksmCamFwd ) then
					self.ksmNewRotCursorKey = -0.7*math.pi
				else 
					self.ksmNewRotCursorKey = -0.3*math.pi
				end 
			end
			self.ksmPrevRotCursorKey  = nil 
		elseif keyStatus > 0 then 
			local i = self.spec_enterable.camIndex
			local r = nil
			if i ~= nil and self.spec_enterable.cameras[i].rotY and self.spec_enterable.cameras[i].origRotY ~= nil then 
				r = keyboardSteerMogli.normalizeAngle( self.spec_enterable.cameras[i].rotY - self.spec_enterable.cameras[i].origRotY )
			end

			if     actionName == "ksmUP" then
				if     r == nil then 
					self.ksmNewRotCursorKey = 0
				elseif math.abs( r ) < 0.1 * math.pi then
					self.ksmNewRotCursorKey = math.pi
				else 
					self.ksmNewRotCursorKey = 0
				end 
				self.ksmPrevRotCursorKey  = nil 
				r = nil
			elseif actionName == "ksmDOWN" then
				if     r == nil then 
					self.ksmNewRotCursorKey = nil
				elseif math.abs( r ) < 0.5 * math.pi then
					self.ksmNewRotCursorKey = math.pi
				else 
					self.ksmNewRotCursorKey = 0
				end 
			elseif actionName == "ksmLEFT" then
				if     r ~= nil and math.abs( r ) > 0.7 * math.pi then
					self.ksmNewRotCursorKey =  0.7*math.pi
				elseif r ~= nil and math.abs( r ) < 0.3 * math.pi then
					self.ksmNewRotCursorKey =  0.3*math.pi
				else 
					self.ksmNewRotCursorKey =  0.5*math.pi
				end 
			elseif actionName == "ksmRIGHT" then
				if     r ~= nil and math.abs( r ) > 0.7 * math.pi then
					self.ksmNewRotCursorKey = -0.7*math.pi
				elseif r ~= nil and math.abs( r ) < 0.3 * math.pi then
					self.ksmNewRotCursorKey = -0.3*math.pi
				else 
					self.ksmNewRotCursorKey = -0.5*math.pi
				end 
			end
			
			if self.ksmPrevRotCursorKey == nil and r ~= nil then 
				self.ksmPrevRotCursorKey = r 
			end 
		elseif self.ksmPrevRotCursorKey ~= nil then 
			self.ksmNewRotCursorKey  = self.ksmPrevRotCursorKey
			self.ksmPrevRotCursorKey = nil
		end
	elseif actionName == "ksmShifter1" 
			or actionName == "ksmShifter2" 
			or actionName == "ksmShifter3" 
			or actionName == "ksmShifter4" then
		if self.ksmShuttleCtrl and self.ksmTransmission >= 2 and self.ksmShifter7isR1 == nil then 
			self.ksmShifter7isR1 = true 
		end 
		-- G27/G29 shifter gears 1..4; go to neutral if released
		if self.ksmTransmission >= 2 then 
			local g
			if     actionName == "ksmShifter1" then
				g = 1
			elseif actionName == "ksmShifter2" then
				g = 2
			elseif actionName == "ksmShifter3" then
				g = 3
			elseif actionName == "ksmShifter4" then
				g = 4
			end 
			if self.ksmTransmission == 5 then 
				g = g + 6 
			end 
			
			if keyStatus > 0 then 
				self:ksmSetState( "ksmGear", g )
				self:ksmSetState( "ksmNeutral", false )
				self:ksmSetState( "ksmAutoShift", false )
				if self.ksmShuttleCtrl and self.ksmShifter7isR1 then
					self:ksmSetState( "ksmShuttleFwd", true )
				end
			else 
				self:ksmSetState( "ksmNeutral", true )
			end 
		end 
	elseif actionName == "ksmShifter5" then
		if self.ksmShuttleCtrl and self.ksmTransmission >= 2 and self.ksmShifter7isR1 == nil then 
			self.ksmShifter7isR1 = true 
		end 
		if self.ksmTransmission >= 4 then 
		-- G27/G29 shifter gear 5; go to neutral if released
			local g = 5
			if self.ksmTransmission == 5 then 
				g = g + 6 
			end 
			
			if keyStatus > 0 then 
				self:ksmSetState( "ksmGear", g )
				self:ksmSetState( "ksmNeutral", false )
				self:ksmSetState( "ksmAutoShift", false )
				if self.ksmShuttleCtrl and self.ksmShifter7isR1 then
					self:ksmSetState( "ksmShuttleFwd", true )
				end
			else 
				self:ksmSetState( "ksmNeutral", true )
			end 
		elseif self.ksmTransmission >= 2 and self.ksmTransmission <= 4 and keyStatus > 0 and self.ksmRange < 4 then 
		-- G27/G29 shift range down
			self:ksmSetState( "ksmRange", self.ksmRange + 1 )
		end 
	elseif actionName == "ksmShifter6" then
		if self.ksmShuttleCtrl and self.ksmTransmission >= 2 and self.ksmShifter7isR1 == nil then 
			self.ksmShifter7isR1 = true 
		end 
		if self.ksmTransmission >= 4 then 
		-- G27/G29 shifter gear 6; go to neutral if released
			local g = 6
			if self.ksmTransmission == 5 then 
				g = g + 6 
			end 
			
			if keyStatus > 0 then 
				self:ksmSetState( "ksmGear", g )
				self:ksmSetState( "ksmNeutral", false )
				self:ksmSetState( "ksmAutoShift", false )
				if self.ksmShuttleCtrl and self.ksmShifter7isR1 then 
					self:ksmSetState( "ksmShuttleFwd", true )
				end
			else 
				self:ksmSetState( "ksmNeutral", true )
			end 
		elseif self.ksmTransmission >= 2 and keyStatus > 0 and self.ksmRange > 1 then 
		-- G27/G29 shift range down
			self:ksmSetState( "ksmRange", self.ksmRange - 1 )
		end 
	elseif actionName == "ksmShifter7" then 
		if self.ksmShuttleCtrl and self.ksmTransmission >= 2 then 
			self.ksmShifter7isR1 = true 
		-- G27/G29 1st reverse gear; go to neutral if released
			if keyStatus > 0 then 
				local g = 1
				if self.ksmTransmission == 5 then 
					g = 6 
				end 
			
				self:ksmSetState( "ksmGear", g )
				self:ksmSetState( "ksmNeutral", false )
				self:ksmSetState( "ksmShuttleFwd", false )
				self:ksmSetState( "ksmAutoShift", false )
			else 
				self:ksmSetState( "ksmNeutral", true  )
			end 
		end
	elseif actionName == "ksmClutchKey" then
		self:ksmSetState("ksmNeutral", keyStatus > 0)
	elseif actionName == "ksmGearUp"    then
		if     self.ksmTransmission == 2
				or self.ksmTransmission == 3 then 
			if self.ksmGear < 4 then 
				self:ksmSetState( "ksmGear", self.ksmGear + 1 )
			end 
		elseif self.ksmTransmission == 4 then
			if self.ksmGear < 6 then 
				self:ksmSetState( "ksmGear", self.ksmGear + 1 )
			end 
		elseif self.ksmTransmission == 5 then
			if self.ksmGear < 12 then 
				self:ksmSetState( "ksmGear", self.ksmGear + 1 )
			end 
		end 
	elseif actionName == "ksmGearDown"  then 
		if     self.ksmTransmission == 2
				or self.ksmTransmission == 3
				or self.ksmTransmission == 4
				or self.ksmTransmission == 5 then
			if self.ksmGear > 1 then 
				self:ksmSetState( "ksmGear", self.ksmGear - 1 )
			end 
		end 
	elseif actionName == "ksmRangeUp"   then 
		if     self.ksmTransmission == 2
				or self.ksmTransmission == 3 then 
			if     self.ksmRange == 1 then 
				self:ksmSetState( "ksmRange", 2 )
				self:ksmSetState( "ksmGear", math.max( 1, self.ksmGear - 1 ) )
			elseif self.ksmRange == 2 then 
				self:ksmSetState( "ksmRange", 3 )
				self:ksmSetState( "ksmGear", math.max( 1, self.ksmGear - 2 ) )
			elseif self.ksmRange == 3 then 
				self:ksmSetState( "ksmRange", 4 )
				self:ksmSetState( "ksmGear", math.max( 1, self.ksmGear - 2 ) )
			end 
		elseif self.ksmTransmission == 4 then
			if self.ksmRange == 1 then 
				self:ksmSetState( "ksmRange", 2 )
				self:ksmSetState( "ksmGear", 1 )
			end 
		end 
	elseif actionName == "ksmRangeDown" then 
		if     self.ksmTransmission == 2
				or self.ksmTransmission == 3 then 
			if     self.ksmRange == 2 then 
				self:ksmSetState( "ksmRange", 1 )
				self:ksmSetState( "ksmGear", math.min( 4, self.ksmGear + 1 ) )
			elseif self.ksmRange == 3 then 
				self:ksmSetState( "ksmRange", 2 )
				self:ksmSetState( "ksmGear", math.min( 4, self.ksmGear + 2 ) )
			elseif self.ksmRange == 4 then 
				self:ksmSetState( "ksmRange", 3 )
				self:ksmSetState( "ksmGear", math.min( 4, self.ksmGear + 2 ) )
			end 
		elseif self.ksmTransmission == 4 then
			if self.ksmRange == 2 then 
				self:ksmSetState( "ksmRange", 1 )
				self:ksmSetState( "ksmGear", 6 )
			end 
		end 
	elseif actionName == "ksmINCHING" then 
		self:ksmSetState( "ksmInchingIsOn", keyStatus > 0 )
	elseif actionName == "ksmNO_ARB" then 
		self:ksmSetState( "ksmNoAutoRotBack", keyStatus > 0 )
	elseif actionName == "ksmDIRECTION" then
		self.ksmShifter7isR1 = false 
		self:ksmSetState( "ksmShuttleFwd", not self.ksmShuttleFwd )
	elseif actionName == "ksmFORWARD" then
		self.ksmShifter7isR1 = false 
		self:ksmSetState( "ksmShuttleFwd", true )
	elseif actionName == "ksmREVERSE" then
		self.ksmShifter7isR1 = false 
		self:ksmSetState( "ksmShuttleFwd", false )
	elseif actionName == "ksmSNAP" then
		self:ksmSetState( "ksmSnapIsOn", not self.ksmSnapIsOn )
 	elseif actionName == "ksmNeutral" then
		self:ksmSetState( "ksmNeutral", not self.ksmNeutral )
	elseif actionName == "ksmSETTINGS" then
		keyboardSteerMogli.ksmShowSettingsUI( self )
	end
end

function keyboardSteerMogli:onLeaveVehicle()
	self:ksmSetState( "ksmInchingIsOn", false )
	self:ksmSetState( "ksmNoAutoRotBack", false )
	self.ksmNewRotCursorKey  = nil
	self.ksmPrevRotCursorKey = nil
	self:ksmSetState( "ksmSnapIsOn", false )
	self.ksmLastSnapAngle = nil
end 

function keyboardSteerMogli:onUpdate(dt)

  if     self.spec_enterable         == nil
			or self.spec_enterable.cameras == nil then 
		self.ksmDisabled =true
		return 
	end
	
	local newRotCursorKey = self.ksmNewRotCursorKey
	local i               = self.spec_enterable.camIndex
	local requestedBack   = nil

	self.ksmNewRotCursorKey = nil

	if newRotCursorKey ~= nil then
		self.spec_enterable.cameras[i].rotY = keyboardSteerMogli.normalizeAngle( self.spec_enterable.cameras[i].origRotY + newRotCursorKey )
		if     math.abs( newRotCursorKey ) < 1e-4 then 
			requestedBack = false 
		elseif math.abs( newRotCursorKey - math.pi ) < 1e-4 then 
			requestedBack = true 
		end
	end
	
	if self.ksmShuttleCtrl then 
		if self.ksmReverserDirection == nil then 
			self.ksmReverserDirection = self.spec_drivable.reverserDirection
		end 
		if self.ksmShuttleFwd then 
			self.spec_drivable.reverserDirection = 1
		else 
			self.spec_drivable.reverserDirection = -1
		end 
	elseif self.ksmReverserDirection ~= nil then 
		self.spec_drivable.reverserDirection = self.ksmReverserDirection
	end 
	
	if self.ksmShuttleCtrl then 
		if self.ksmReverseDriveSample == nil then 
			self.ksmReverseDriveSample = self.spec_motorized.samples.reverseDrive 
		end 
		self.spec_motorized.samples.reverseDrive = nil 
	elseif self.ksmReverseDriveSample ~= nil then 
		self.spec_motorized.samples.reverseDrive = self.ksmReverseDriveSample
	end 
	
	if     self.spec_motorized.motor.lowBrakeForceScale == nil then
	elseif self:getIsVehicleControlledByPlayer() and self.ksmBrakeForce <= 0.99 then 
		if self.ksmLowBrakeForceScale == nil then 
			self.ksmLowBrakeForceScale                 = self.spec_motorized.motor.lowBrakeForceScale
		end 
		self.spec_motorized.motor.lowBrakeForceScale = self.ksmBrakeForce * self.ksmLowBrakeForceScale 
	elseif self.ksmLowBrakeForceScale ~= nil then  
		self.spec_motorized.motor.lowBrakeForceScale = self.ksmLowBrakeForceScale 
		self.ksmLowBrakeForceScale                   = nil
	end 
	
	if self.ksmMaxForwardSpeed == nil then 
		self.ksmMaxForwardSpeed  = self.spec_motorized.motor.maxForwardSpeed 
		self.ksmMaxBackwardSpeed = self.spec_motorized.motor.maxBackwardSpeed
	elseif self.ksmLimitSpeed then 
		self.spec_motorized.motor.maxForwardSpeed  = self.ksmMaxForwardSpeed 
		self.spec_motorized.motor.maxBackwardSpeed = self.ksmMaxBackwardSpeed
	else
		self.spec_motorized.motor.maxForwardSpeed  = self.ksmMaxSpeed 
		self.spec_motorized.motor.maxBackwardSpeed = self.ksmMaxSpeed 
	end 

	if self:getIsActive() and self.isServer then
		if      self.ksmShuttleCtrl then 
			local controlledVehicles = g_currentMission.controlledVehicles
			local isHudVisible = g_currentMission.hud:getIsVisible()
			if self.ksmShuttleFwd then
				self.ksmMovingDir = 1
			else
				self.ksmMovingDir = -1
			end
		elseif g_currentMission.missionInfo.stopAndGoBraking then
			local movingDirection = self.movingDirection * self.spec_drivable.reverserDirection
			if math.abs( self.lastSpeed ) < 0.000278 then
				movingDirection = 0
			end
				
			local maxDelta    = dt * self.ksmReverseTimer
			self.ksmMovingDir = self.ksmMovingDir + keyboardSteerMogli.mbClamp( movingDirection - self.ksmMovingDir, -maxDelta, maxDelta )
		else
			self.ksmMovingDir = Utils.getNoNil( self.nextMovingDirection * self.spec_drivable.reverserDirection )
		end
		
		
		if     self.ksmMovingDir < -0.5 then
			self:ksmSetState( "ksmCamFwd", false )
		elseif self.ksmMovingDir >  0.5 then
			self:ksmSetState( "ksmCamFwd", true )
		else
			fwd = self.ksmCamFwd
		end		
	end
	
	local axisSideLast    = self.ksmAxisSideLast
	local snapAngleLast   = self.ksmLastSnapAngle
	self.ksmAxisSideLast  = nil
	self.ksmLastSnapAngle = nil 
	
	if self.ksmNoAutoRotBack and self:getIsVehicleControlledByPlayer() then
		if self.ksmAutoRotateBackSpeed == nil then 
			self.ksmAutoRotateBackSpeed = self.autoRotateBackSpeed
		end 
		self:ksmSetState( "ksmSnapIsOn", false )
		self.autoRotateBackSpeed      = 0
	elseif self.ksmAutoRotateBackSpeed ~= nil then
		self.autoRotateBackSpeed      = self.ksmAutoRotateBackSpeed
		self.ksmAutoRotateBackSpeed   = nil 
	end 
	
	if self.isClient and self.ksmSnapIsOn then 
		if self:getIsVehicleControlledByPlayer() then 
			
			local lx,_,lz = localDirectionToWorld( self.components[1].node, 0, 0, 1 )			
			if lx*lx+lz*lz > 1e-6 then 
				local rot    = math.atan2( lx, lz )
				local d      = keyboardSteerMogli.snapAngles[self.ksmSnapAngle]
				
				if snapAngleLast == nil then  
					local target = 0
					local diff   = math.pi+math.pi
					if d == nil then 
						if self.ksmSnapAngle < 1 then 
							d = keyboardSteerMogli.snapAngles[1] 
						else 
							d = 90 
						end 
					end 
					for i=0,360,d do 
						local a = math.rad( i )
						local b = math.abs( keyboardSteerMogli.normalizeAngle( a - rot ) )
						if b < diff then 
							target = a 
							diff   = b
						end 
					end 
					
					self.ksmLastSnapAngle = keyboardSteerMogli.normalizeAngle( target )
				else 
					self.ksmLastSnapAngle = snapAngleLast 
				end 
				
				d = 0.5 * d 
				
				if d > 10 then d = 10 end 
				d = math.rad( d )
					
				local a = keyboardSteerMogli.mbClamp( keyboardSteerMogli.normalizeAngle( rot - self.ksmLastSnapAngle ) / d, -1, 1 ) 
				
				if self.ksmMovingDir < 0 then 
					a = -a 
				end 
				
				d = 0.002 * dt
				
				if axisSideLast == nil then 
					axisSideLast = self.spec_drivable.axisSideLast 
				end 
				
				self.spec_drivable.axisSide = axisSideLast + keyboardSteerMogli.mbClamp( a - axisSideLast, -d, d )
				
				self.ksmAxisSideLast = self.spec_drivable.axisSide
				
			--keyboardSteerMogli.debugPrint( string.format( "%4d° -> %4d° => %4d%% (%4d%%, %4d%%)",
			--															 math.deg( rot ), math.deg( self.ksmLastSnapAngle ),
			--															 a*100, self.spec_drivable.axisSide*100, axisSideLast*100 ) )				
			end 
		else 
			self:ksmSetState("ksmSnapIsOn", false ) 
		end 
	end 
	
	if      self:getIsActive() 
			and self.isClient 
--		and self.steeringEnabled 
			and self:ksmIsValidCam() then

		if     self.ksmLastCamIndex == nil 
				or self.ksmLastCamIndex ~= i then
				
			self:ksmSetState( "ksmCameraIsOn",  self.ksmCameras[i].rotation )
			self:ksmSetState( "ksmReverseIsOn", self.ksmCameras[i].rev )
			self.ksmLastCamIndex = self.spec_enterable.camIndex
			self.ksmCameras[i].zero       = self.spec_enterable.cameras[i].rotY
			self.ksmCameras[i].lastCamFwd = nil
			
		elseif  g_gameSettings:getValue("isHeadTrackingEnabled") 
				and isHeadTrackingAvailable() 
				and self.spec_enterable.cameras[i].isInside 
				and self.spec_enterable.cameras[i].headTrackingNode ~= nil then
				
			if requestedBack ~= nil then 
				self.ksmCamBack = requestedBack 
			end 
			
			if self.ksmReverseIsOn or self.ksmCamBack ~= nil then			
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
				if      self.ksmReverseIsOn
						and not ( self.ksmCamFwd ) then 
					targetBack = true 
				end 
				
				if self.ksmCamBack ~= nil then 
					if self.ksmCamBack == targetBack then 
						self.ksmCamBack = nil 
					else 
						targetBack = self.ksmCamBack 
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
			
		elseif self.ksmCameraIsOn 
				or self.ksmReverseIsOn then

			local pi2 = math.pi / 2
			local eps = 1e-6
			oldRotY = self.spec_enterable.cameras[i].rotY
			local diff = oldRotY - self.ksmCameras[i].last
			
			if self.ksmCameraIsOn then
				if newRotCursorKey ~= nil then
					self.ksmCameras[i].zero = keyboardSteerMogli.normalizeAngle( self.spec_enterable.cameras[i].origRotY + newRotCursorKey )
				else
					self.ksmCameras[i].zero = self.ksmCameras[i].zero + diff
				end
			else
				self.ksmCameras[i].zero = self.spec_enterable.cameras[i].rotY
			end
				
		--diff = math.abs( keyboardSteerMogli.ksmGetAbsolutRotY( self, i ) )
			local isRev = false
			local aRotY = keyboardSteerMogli.normalizeAngle( keyboardSteerMogli.ksmGetAbsolutRotY( self, i ) - self.spec_enterable.cameras[i].rotY + self.ksmCameras[i].zero )
			if -pi2 < aRotY and aRotY < pi2 then
				isRev = true
			end
			
			if self.ksmReverseIsOn then
				if     newRotCursorKey ~= nil then
				-- nothing
				elseif self.ksmCameras[i].lastCamFwd == nil or self.ksmCameras[i].lastCamFwd ~= self.ksmCamFwd then
					if isRev == self.ksmCamFwd then
						self.ksmCameras[i].zero = keyboardSteerMogli.normalizeAngle( self.ksmCameras[i].zero + math.pi )
						isRev = not isRev						
					end
				end
				self.ksmCameras[i].lastCamFwd = self.ksmCamFwd
			end
			
			local newRotY = self.ksmCameras[i].zero
			
			if self.ksmCameraIsOn then
				
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
				
				local g = self.ksmLastFactor
				self.ksmLastFactor = self.ksmLastFactor + keyboardSteerMogli.mbClamp( f - self.ksmLastFactor, -KSMGlobals.cameraRotTime*dt, KSMGlobals.cameraRotTime*dt )
				if math.abs( self.ksmLastFactor - g ) > 0.01 then
					f = self.ksmLastFactor
				else
					f = g
				end
				
				if isRev then
				--keyboardSteerMogli.debugPrint("reverse")
					newRotY = newRotY - self:ksmScaleFx( KSMGlobals.cameraRotFactorRev, 0.1, 3 ) * f				
				else
				--keyboardSteerMogli.debugPrint("forward")
					newRotY = newRotY + self:ksmScaleFx( KSMGlobals.cameraRotFactor, 0.1, 3 ) * f
				end	
				
			else
				self.ksmLastFactor = 0
			end

			self.spec_enterable.cameras[i].rotY = newRotY			
			
			if math.abs( keyboardSteerMogli.normalizeAngle( self.spec_enterable.cameras[i].rotY - newRotY ) ) > 0.5 * math.pi then
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
		
		self.ksmCameras[i].last = self.spec_enterable.cameras[i].rotY
	end	
	
	self.ksmWarningTimer = self.ksmWarningTimer - dt
	
	if      self:getIsActive()
			and self.ksmWarningText ~= nil
			and self.ksmWarningText ~= "" then
		if self.ksmWarningTimer <= 0 then
			self.ksmWarningText = ""
		end
	end	
	
--******************************************************************************************************************************************
-- adaptive steering 	
	if self.ksmSteeringIsOn and not ( self.ksmSnapIsOn ) and self:getIsVehicleControlledByPlayer() then 
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
		
		self.ksmRotSpeedFactor = keyboardSteerMogli.ksmScaleFx( self, f )
		
		for i,w in pairs( self.spec_wheels.wheels ) do 
			if w.rotSpeed ~= nil then 
				if w.ksmRotSpeed == nil then 
					w.ksmRotSpeed = w.rotSpeed 
				end 				
				w.rotSpeed = w.ksmRotSpeed * self.ksmRotSpeedFactor
			end 
			
			if w.rotSpeedNeg ~= nil then 
				if w.ksmRotSpeedNeg == nil then 
					w.ksmRotSpeedNeg = w.rotSpeedNeg 
				end 				
				w.rotSpeedNeg = w.ksmRotSpeedNeg * self.ksmRotSpeedFactor
			end 
		end 
	elseif self.ksmRotSpeedFactor ~= nil then
		for i,w in pairs( self.spec_wheels.wheels ) do 
			if w.ksmRotSpeed ~= nil and w.ksmRotSpeed ~= nil then 
				w.rotSpeed = w.ksmRotSpeed
			end 
			
			if w.rotSpeedNeg ~= nil and w.ksmRotSpeedNeg ~= nil then 
				w.rotSpeedNeg = w.ksmRotSpeedNeg
			end 
		end 
	
		self.ksmRotSpeedFactor = nil 
	end 
--******************************************************************************************************************************************

	if self.ksmInchingIsOn and self:getIsVehicleControlledByPlayer() and self.spec_drivable.cruiseControl.state == 1 then
		local limitThrottleRatio     = 0.75
		if self.ksmLimitThrottle < 11 then
			limitThrottleRatio     = 0.45 + 0.05 * self.ksmLimitThrottle
		else
			limitThrottleRatio     = 1.5 - 0.05 * self.ksmLimitThrottle
		end
		if self.ksmSpeedLimit == nil then 
			self.ksmSpeedLimit = self.spec_drivable.cruiseControl.speed
		end 
		self.spec_drivable.cruiseControl.speed = self.ksmSpeedLimit * limitThrottleRatio
	elseif self.ksmSpeedLimit ~= nil then 
		self.spec_drivable.cruiseControl.speed = self.ksmSpeedLimit
		self.ksmSpeedLimit = nil
	end 
--******************************************************************************************************************************************
	
	if self.isClient and self:getIsVehicleControlledByPlayer() and self:getIsEntered() then 
		if self.ksmShuttleCtrl and self.ksmReverseDriveSample ~= nil then 
			local notRev = self.ksmShuttleFwd or self.ksmNeutral
			if not g_soundManager:getIsSamplePlaying(self.ksmReverseDriveSample) and not notRev then
				g_soundManager:playSample(self.ksmReverseDriveSample)
			elseif notRev then
				g_soundManager:stopSample(self.ksmReverseDriveSample)
			end
		end
	end 	
	
end  

function keyboardSteerMogli:onDraw()
	setTextAlignment( RenderText.ALIGN_CENTER ) 
	setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_MIDDLE )
	setTextColor(1, 1, 1, 1) 
	
	local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
	local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.6
	local l = 0.025 * keyboardSteerMogli.getUiScale()

	if self:getIsVehicleControlledByPlayer() and not g_gui:getIsGuiVisible() then
		local w = 0.015 * keyboardSteerMogli.getUiScale()
		local h = w * g_screenAspectRatio
		if self.ksmShuttleCtrl then 
			if self.ksmShuttleFwd then
				if     self.ksmNeutral and self.ksmShifter7isR1 then 
				elseif self.ksmNeutral then 
					renderOverlay( keyboardSteerMogli.ovHandBrakeUp, x-0.5*w, y-0.5*h, w, h )
				elseif self.ksmShifter7isR1 then
					renderOverlay( keyboardSteerMogli.ovArrowUpGray, x-0.5*w, y-0.5*h, w, h )
				else 
					renderOverlay( keyboardSteerMogli.ovArrowUpWhite, x-0.5*w, y-0.5*h, w, h )
				end 
			else 
				if     self.ksmNeutral and self.ksmShifter7isR1 then 
				elseif self.ksmNeutral then 
					renderOverlay( keyboardSteerMogli.ovHandBrakeDown, x-0.5*w, y-0.5*h, w, h )
				elseif self.ksmShifter7isR1 then
					renderOverlay( keyboardSteerMogli.ovArrowDownGray, x-0.5*w, y-0.5*h, w, h )
				else 
					renderOverlay( keyboardSteerMogli.ovArrowDownWhite, x-0.5*w, y-0.5*h, w, h )
				end 
			end 
		elseif self.ksmNeutral then 
			renderText(x, y, l, "N")
		end 
	end 
	
	if self:getIsVehicleControlledByPlayer() and self.ksmTransmission >= 2 then 
		y = y + l * 1.2
		
		local gear = keyboardSteerMogli.getGearIndex( self.ksmTransmission, self.ksmGear, self.ksmRange )		
		local maxSpeed = 3.6 * keyboardSteerMogli.gearRatios[gear] * self.ksmMaxSpeed
		local text = ""
		
		if     self.ksmTransmission == 5 then 
		elseif self.ksmTransmission == 4 then 
			if self.ksmRange == 1 then 
				text = "L" 
			else 
				text = "H" 
			end 
		else 
			if     self.ksmRange == 1 then 
				text = "L" 
			elseif self.ksmRange == 2 then 
				text = "M" 
			elseif self.ksmRange == 3 then 
				text = "H" 
			else
				text = "S" 
			end 
		end 
		
		text = text .." "..string.format("%d %3.0f km/h",self.ksmGear, maxSpeed )
		renderText(x, y, l, text)
	end 
	
	if KSMGlobals.snapAngleHudX >= 0 then 
		x = KSMGlobals.snapAngleHudX
		y = KSMGlobals.snapAngleHudY
		setTextAlignment( RenderText.ALIGN_LEFT ) 
		setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
	else 
		y = y + l * 1.2
	end 
	
	local lx,_,lz = localDirectionToWorld( self.components[1].node, 0, 0, 1 )			
	if lx*lx+lz*lz > 1e-6 then 
		renderText(x, y, l, string.format( "%4.1f°", math.deg( math.pi - math.atan2( lx, lz ) )))
	end 
	
	y = y + l * 1.1	
	if self.ksmLastSnapAngle ~= nil then
		renderText(x, y, l, string.format( "%4.1f°", math.deg( math.pi - self.ksmLastSnapAngle )))
	end
	
	setTextAlignment( RenderText.ALIGN_LEFT ) 
	setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
end

function keyboardSteerMogli:onReadStream(streamId, connection)

	self.ksmSteeringIsOn  = streamReadBool(streamId) 
  self.ksmCameraIsOn    = streamReadBool(streamId) 
  self.ksmReverseIsOn   = streamReadBool(streamId) 
  self.ksmCamFwd        = streamReadBool(streamId) 
  self.ksmShuttleCtrl   = streamReadBool(streamId) 
  self.ksmShuttleFwd    = streamReadBool(streamId) 
  self.ksmNeutral       = streamReadBool(streamId) 
	self.ksmExponent      = streamReadInt16(streamId)     
	self.ksmSnapAngle     = streamReadInt16(streamId)     
	
	self.ksmPeekLeftRight = streamReadBool(streamId) 
	self.ksmAutoShift     = streamReadBool(streamId) 
	self.ksmLimitSpeed    = streamReadBool(streamId) 
	self.ksmLimitThrottle = streamReadInt16(streamId) 
	self.ksmBrakeForce    = streamReadInt16(streamId) * 0.05
	self.ksmLaunchGear    = streamReadInt16(streamId)
	self.ksmTransmission  = streamReadInt16(streamId)
	self.ksmMaxSpeed      = streamReadFloat32(streamId)
	
end

function keyboardSteerMogli:onWriteStream(streamId, connection)

	streamWriteBool(streamId, self.ksmSteeringIsOn )
	streamWriteBool(streamId, self.ksmCameraIsOn )
	streamWriteBool(streamId, self.ksmReverseIsOn )
	streamWriteBool(streamId, self.ksmCamFwd )     
	streamWriteBool(streamId, self.ksmShuttleCtrl )     
	streamWriteBool(streamId, self.ksmShuttleFwd )     
	streamWriteBool(streamId, self.ksmNeutral )     
	streamWriteInt16(streamId,self.ksmExponent )     
	streamWriteInt16(streamId,self.ksmSnapAngle )     

	streamWriteBool(streamId,  self.ksmPeekLeftRight )
	streamWriteBool(streamId,  self.ksmAutoShift     )
	streamWriteBool(streamId,  self.ksmLimitSpeed    )
	streamWriteInt16(streamId, self.ksmLimitThrottle )
	streamWriteInt16(streamId, math.floor( 20 * self.ksmBrakeForce + 0.5 ) )
	streamWriteInt16(streamId, self.ksmLaunchGear    )
	streamWriteInt16(streamId, self.ksmTransmission  )
	streamWriteFloat32(streamId, self.ksmMaxSpeed    )

end 

function keyboardSteerMogli:getDefaultRotation( camIndex )
	if     self.spec_enterable.cameras           == nil
			or self.spec_enterable.cameras[camIndex] == nil then
		keyboardSteerMogli.debugPrint( "invalid camera" )
		return false
	elseif not ( self.spec_enterable.cameras[camIndex].isRotatable )
			or self.spec_enterable.cameras[camIndex].vehicle ~= self then
		keyboardSteerMogli.debugPrint( "fixed camera" )
		return false
	elseif self.spec_enterable.cameras[camIndex].isInside then
		keyboardSteerMogli.debugPrint( "camera is inside" )
		return KSMGlobals.camInsideRotation
	end
	
	return KSMGlobals.camOutsideRotation
end

function keyboardSteerMogli:getDefaultTransmission()
	if KSMGlobals.transmission <= 0 then 
		return 0
	elseif self.spec_combine ~= nil then 
		return 1
	end 
	return KSMGlobals.transmission
end 

function keyboardSteerMogli:getDefaultMaxSpeed()
	local m 
	local n = Utils.getNoNil( self.ksmMaxForwardSpeed, self.spec_motorized.motor.maxForwardSpeed )

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

function keyboardSteerMogli:getDefaultReverse( camIndex )
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
		
		return KSMGlobals.camReverseRotation 
	end
	
	return KSMGlobals.camRevOutRotation
end

function keyboardSteerMogli:ksmScaleFx( fx, mi, ma )
	return keyboardSteerMogli.mbClamp( 1 + self.ksmFactor * ( fx - 1 ), mi, ma )
end

function keyboardSteerMogli:ksmGetCurrentCamRot()
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
	local a = keyboardSteerMogli.normalizeAngle( self.spec_enterable.cameras[i].rotY )
	print(math.deg(a))
	return a
end 

--******************************************************************************************************************************************
-- shuttle control and inching
function keyboardSteerMogli:ksmUpdateWheelsPhysics( superFunc, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking )
	local brake = ( acceleration < 0 )
	
	self.ksmOldAcc       = acceleration
	self.ksmOldHandbrake = doHandbrake

	if self:getIsVehicleControlledByPlayer() then 		
		if self.ksmShuttleCtrl then 
			if self.ksmShuttleFwd then 
				self.nextMovingDirection = 1 
			else 
				self.nextMovingDirection = -1 
			end 
			
			if not self:getIsMotorStarted() or g_gui:getIsGuiVisible() then 
				acceleration = 0
				doHandbrake  = true 
			elseif acceleration < 0 then 
				local lowSpeedBrake = 1.389e-4 - acceleration * 6.944e-4 -- 0.5 .. 3			
				if  math.abs( currentSpeed ) < lowSpeedBrake then 
					-- braking at low speed
					acceleration = 0
					doHandbrake  = true 
				end			
			end 
			if self.ksmNeutral then 
				if acceleration > 0 then 
					acceleration = 0 
				end 
			end 
		end 			
			
		if self.spec_drivable.cruiseControl.state == 0 and self.ksmLimitThrottle ~= nil and self.ksmInchingIsOn ~= nil then 
			local limitThrottleRatio     = 0.75
			local limitThrottleIfPressed = true
			if self.ksmLimitThrottle < 11 then
				limitThrottleIfPressed = false
				limitThrottleRatio     = 0.45 + 0.05 * self.ksmLimitThrottle
			else
				limitThrottleIfPressed = true
				limitThrottleRatio     = 1.5 - 0.05 * self.ksmLimitThrottle
			end
				
			if self.ksmInchingIsOn == limitThrottleIfPressed then
				acceleration = acceleration * limitThrottleRatio
			end
		end
	end 
	
	self.ksmNewAcc       = acceleration
	self.ksmNewHandbrake = doHandbrake
	stopAndGoBraking = true 
	
	local state, result = pcall( superFunc, self, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking ) 
	if not ( state ) then
		print("Error in updateWheelsPhysics :"..tostring(result))
		self.ksmShuttleCtrl = false 
	end
	
	if self.ksmShuttleCtrl then 
		self:setBrakeLightsVisibility( brake )
		self:setReverseLightsVisibility( not self.ksmShuttleFwd )
	end 
	
	return result 
end 
WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction( WheelsUtil.updateWheelsPhysics, keyboardSteerMogli.ksmUpdateWheelsPhysics )


--******************************************************************************************************************************************
-- increased minRPM
function keyboardSteerMogli:getRequiredMotorRpmRange( superFunc, ... )
	if      self.ksmMinRpm ~= nil 
			and self.ksmMaxRpm ~= nil then 
		return self.ksmMinRpm, self.ksmMaxRpm 
	end 
	return superFunc( self, ... )
end 

VehicleMotor.getRequiredMotorRpmRange = Utils.overwrittenFunction( VehicleMotor.getRequiredMotorRpmRange, keyboardSteerMogli.getRequiredMotorRpmRange )
--******************************************************************************************************************************************

function keyboardSteerMogli.getGearIndex( mode, gear, range )
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

function keyboardSteerMogli:ksmUpdateGear( superFunc, acceleratorPedal, dt )
	
	local lastMinRpm  = Utils.getNoNil( self.ksmMinRpm, self.minRpm )
	local lastMaxRpm  = Utils.getNoNil( self.ksmMaxRpm, self.maxRpm )
	local lastFakeRpm = Utils.getNoNil( self.ksmFakeRpm,self.equalizedMotorRpm ) 
	self.ksmMinRpm    = nil 
	self.ksmMaxRpm    = nil 
	self.ksmFakeRpm   = nil
	
	if not ( self.vehicle:getIsVehicleControlledByPlayer() 
			and ( self.vehicle.ksmTransmission ~= nil	
				 or self.vehicle.ksmNeutral ) ) then 
		return superFunc( self, acceleratorPedal, dt )
	end 

	local fwd, curBrake
	local lastFwd  = Utils.getNoNil( self.ksmLastFwd )
	if self.vehicle.ksmShuttleCtrl then 
		fwd = self.vehicle.ksmShuttleFwd 
		curBrake = math.max( 0, -self.vehicle.ksmOldAcc )
	elseif acceleratorPedal < 0 then 
		fwd = false 
		curBrake = 0
	elseif acceleratorPedal > 0 then 
		fwd = true 
		curBrake = 0
	else
		fwd = lastFwd
		curBrake = Utils.getNoNil( self.ksmLastRealBrake, 0 )
	end 
	self.ksmLastFwd = fwd
	
	local newAcc       = acceleratorPedal
	if fwd then 
		if newAcc < 0 then 
			newAcc = 0
		end 
	else 
		if newAcc > 0 then 
			newAcc = 0 
		end 
	end 
	if g_gui:getIsGuiVisible() then
		newAcc = 0
	end 
	
	--****************************************
-- handbrake
	if self.vehicle.ksmNeutral then 
		newAcc = 0
	
		local rpm = self.minRpm 
		local acc = 0
		local add = self.maxRpm - self.minRpm
			
		if     self.vehicle.ksmOldAcc == nil then 
		elseif self.vehicle.ksmShuttleCtrl then 
			acc =  self.vehicle.ksmOldAcc
		elseif self.vehicle.nextMovingDirection > 0 then 
			acc =  self.vehicle.ksmOldAcc
		elseif self.vehicle.nextMovingDirection < 0 then 
			acc = -self.vehicle.ksmOldAcc
		end
			
		if acc > 0 then 
			rpm = self.minRpm + acc * add
		end 
		
		if lastFakeRpm == nil then 
			lastFakeRpm = self.equalizedMotorRpm 
		end 
		self.ksmFakeRpm   = keyboardSteerMogli.mbClamp( rpm, lastFakeRpm - 0.001 * dt * add, lastFakeRpm + 0.001 * dt * add )		
		self.ksmFakeTimer = 500 
	elseif self.ksmFakeTimer ~= nil then 
		if lastFakeRpm == nil then
			self.ksmFakeTimer = nil 
		else 
			local add = self.maxRpm - self.minRpm	
			self.ksmFakeRpm   = keyboardSteerMogli.mbClamp( self.equalizedMotorRpm, lastFakeRpm - 0.001 * dt * add, lastFakeRpm + 0.001 * dt * add )	
			self.ksmFakeTimer = self.ksmFakeTimer - dt 
			if self.ksmFakeTimer <= 0 then 
				self.ksmFakeTimer = nil 
			end 
		end 
	end 
	
	local speed       = math.abs( self.vehicle.lastSpeedReal ) *3600
	local motorPtoRpm = math.min(PowerConsumer.getMaxPtoRpm(self.vehicle)*self.ptoMotorRpmRatio, self.maxRpm)
	
	if     self.vehicle.ksmTransmission == 1 then 
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
			self.ksmIncreaseRpm = g_currentMission.time + 1000 
		end 
		
		local minReducedRpm = math.min( math.max( newMinRpm, 0.5*math.min( 2200, self.maxRpm ) ), newMaxRpm )
		if self.vehicle.spec_combine ~= nil then 
			minReducedRpm = math.min( math.max( newMinRpm, 0.8*math.min( 2200, self.maxRpm ) ), newMaxRpm )
		end 
		
		if speed > 0.5 and self.ksmIncreaseRpm ~= nil and g_currentMission.time < self.ksmIncreaseRpm  then 
			newMinRpm = minReducedRpm
		end
		minReducedRpm = minReducedRpm + 0.1 * self.maxRpm
			
		if self.vehicle.spec_combine == nil and self.vehicle.ksmLimitThrottle ~= nil and self.vehicle.ksmInchingIsOn ~= nil then 
				
			if self.vehicle.spec_drivable.cruiseControl.state == 0 then
					
				local limitThrottleRatio     = 0.75
				local limitThrottleIfPressed = true
				if self.vehicle.ksmLimitThrottle < 11 then
					limitThrottleIfPressed = false
					limitThrottleRatio     = 0.45 + 0.05 * self.vehicle.ksmLimitThrottle
				else
					limitThrottleIfPressed = true
					limitThrottleRatio     = 1.5 - 0.05 * self.vehicle.ksmLimitThrottle
				end
						
				if self.vehicle.ksmInchingIsOn == limitThrottleIfPressed then 
					newMaxRpm = math.max( minReducedRpm, math.min( newMaxRpm, self.maxRpm * limitThrottleRatio ) )
				end 
			end 
			
			local lowLoad = false 
			if     self.ksmChangeTime ~= nil and g_currentMission.time < self.ksmChangeTime + 5500 then
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
				local wheelRpm = (speed + 1 )/3.6 * 60 / (math.pi+math.pi)
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
		self.ksmMinRpm = keyboardSteerMogli.mbClamp( newMinRpm, lastMinRpm - deltaS, math.max( lastMinRpm, self.lastRealMotorRpm + deltaF ) )
		self.ksmMaxRpm = keyboardSteerMogli.mbClamp( newMaxRpm, math.max( lastMaxRpm, self.lastRealMotorRpm ) - deltaS, lastMaxRpm + deltaS )
		
		self.minGearRatio = self.maxRpm / ( self.vehicle.ksmMaxSpeed * keyboardSteerMogli.factor30pi )
		self.maxGearRatio = 250 
		
		if not fwd then 
			self.minGearRatio = -self.minGearRatio
			self.maxGearRatio = -self.maxGearRatio
		end 
		
		return newAcc

	elseif self.vehicle.ksmTransmission == 2 
			or self.vehicle.ksmTransmission == 3 
			or self.vehicle.ksmTransmission == 4 
			or self.vehicle.ksmTransmission == 5 then 
	--****************************************	
	-- 4x4 / 4x4 PS / 2x6 / FPS 
	
		self.ksmMinRpm = self.minRpm
		self.ksmMaxRpm = self.maxRpm
		
		local initGear = false 
		local maxGear  = 4
		local maxRange = 4
		if     self.vehicle.ksmTransmission == 5 then 
			maxGear  = 12
			maxRange = 1
		elseif self.vehicle.ksmTransmission == 4 then 
			maxGear  = 6
			maxRange = 2
		end  
		if     self.vehicle.ksmGear == 0 then 
			initGear = true 
			self.vehicle:ksmSetState( "ksmGear", 1 )
			self.vehicle:ksmSetState( "ksmRange", maxRange )			
		elseif self.vehicle.ksmGear < 1 then 
			initGear = true 
			self.vehicle:ksmSetState( "ksmGear", 1 )
		elseif self.vehicle.ksmGear > maxGear then 
			initGear = true 
			self.vehicle:ksmSetState( "ksmGear", maxGear )
		end 
		if     self.vehicle.ksmRange < 1 then   
			initGear = true 
			self.vehicle:ksmSetState( "ksmRange", 1 )
		elseif self.vehicle.ksmRange > maxRange then 
			initGear = true 
			self.vehicle:ksmSetState( "ksmRange", maxRange )
		end 
				
		local isNeutral = self.vehicle.ksmNeutral 
									 or g_gui:getIsGuiVisible()
		               or self.ksmClutchTimer == nil 
									 or lastFwd ~= fwd 
									 or ( newAcc == 0 and curBrake > 0.1 )
		if     newAcc > 0.1 then 
			self.ksmAutoStop = false 
		elseif lastFwd ~= fwd then 
			self.ksmAutoStop = true
		end 
		if self.ksmAutoStop then 
			isNeutral = true 
		end 
		
		if self.gearChangeTimer == nil then 
			self.gearChangeTimer = 0
		elseif self.gearChangeTimer > 0 then 
			self.gearChangeTimer = self.gearChangeTimer - dt 
		end 
		if isNeutral then 
			self.ksmClutchTimer = KSMGlobals.clutchTimer 
			self.ksmAutoDownTimer = 0
			self.ksmAutoUpTimer   = KSMGlobals.clutchTimer
		elseif self.ksmClutchTimer > 0 then 
			self.ksmClutchTimer = self.ksmClutchTimer - dt
		end 
		if self.ksmLoad == nil or self.ksmLoad < self.vehicle.spec_motorized.actualLoadPercentage then 
			self.ksmLoad = self.vehicle.spec_motorized.actualLoadPercentage
		elseif curBrake >= 0.5 then 
		-- simulate high load for immediate down shift
			self.ksmLoad = 1
		elseif self.gearChangeTimer <= 0 then 
			self.ksmLoad = self.ksmLoad + 0.03 * ( self.vehicle.spec_motorized.actualLoadPercentage - self.ksmLoad )
		end 
						
		local gear      = keyboardSteerMogli.getGearIndex( self.vehicle.ksmTransmission, self.vehicle.ksmGear, self.vehicle.ksmRange )		
		local ratio     = keyboardSteerMogli.gearRatios[gear]
		local maxSpeed  = ratio * self.vehicle.ksmMaxSpeed 
		local wheelRpm  = self.vehicle.lastSpeedReal * 1000 * self.maxRpm / maxSpeed 
		local clutchRpm = wheelRpm
		local slip      = 0
		if self.gearChangeTimer <= 0 and not isNeutral then 
			clutchRpm = self.differentialRotSpeed * self.minGearRatio * keyboardSteerMogli.factor30pi
			if clutchRpm > 0 or wheelRpm > 0 then 
				slip = ( clutchRpm - wheelRpm ) / math.max( clutchRpm, wheelRpm )
			else 
				slip = 1
			end 
		end 
		if self.vehicle.ksmSlip == nil then 
			self.vehicle.ksmSlip = 0 
		end 
		self.vehicle.ksmSlip = self.vehicle.ksmSlip + 0.05 * ( slip - self.vehicle.ksmSlip )
		
		--****************************************
		-- no automatic shifting during gear shift or if clutch is open
		if self.ksmAutoDownTimer == nil then 
			self.ksmAutoDownTimer = 0
		elseif self.ksmAutoDownTimer > 0 then 
			self.ksmAutoDownTimer = self.ksmAutoDownTimer - dt 
		end 		
		if self.ksmAutoUpTimer == nil then 
			self.ksmAutoUpTimer = KSMGlobals.clutchTimer
		elseif self.ksmAutoUpTimer > 0 then 
			self.ksmAutoUpTimer = self.ksmAutoUpTimer - dt 
		end 
		if self.ksmAutoLowTimer == nil then 
			self.ksmAutoLowTimer = 5000
		elseif self.ksmAutoLowTimer > 0 then 
			self.ksmAutoLowTimer = self.ksmAutoLowTimer - dt 
		end 
		if self.gearChangeTimer > 0 and self.ksmAutoDownTimer < 1000 then 
			self.ksmAutoDownTimer = 1000 
		end 
		
		if     self.ksmAutoStop then 
			self.ksmBrakeTimer = nil
		elseif curBrake >= 0.1 then 
			if self.ksmBrakeTimer == nil then  
				self.ksmBrakeTimer = 0
			else 
				self.ksmBrakeTimer = self.ksmBrakeTimer + dt
			end 
		elseif self.ksmBrakeTimer ~= nil then 
			self.ksmBrakeTimer = self.ksmBrakeTimer - dt
			if self.ksmBrakeTimer < 0 then 
				self.ksmBrakeTimer = nil
			end 
		end 

			-- no automatic shifting#
		if self.ksmClutchTimer > 0 and self.ksmAutoUpTimer < 500 then 
			self.ksmAutoUpTimer = 500 
		end 
		if self.gearChangeTimer > 0 and self.ksmAutoUpTimer < 1000 then 
			self.ksmAutoUpTimer = 1000 
		end 
		if curBrake >= 0.1 and self.ksmBrakeTimer ~= nil and self.ksmBrakeTimer > 500 then 
			self.ksmAutoDownTimer = 0
		end 
		if newAcc < 0.1 and curBrake < 0.1 and self.ksmAutoDownTimer < 3000 then  
			self.ksmAutoDownTimer = 3000 
		end 
		if self.gearChangeTimer > 0 and self.ksmAutoDownTimer < 1000 then 
			self.ksmAutoDownTimer = 1000 
		end 
		if newAcc < 0.1 and self.ksmAutoUpTimer < 1000 then 
			self.ksmAutoUpTimer = 1000 
		end 
		if self.ksmClutchTimer > 0 and self.ksmAutoUpTimer < 500 then 
			self.ksmAutoUpTimer = 500 
		end 
		if self.ksmLoad < 0.8 then 
			self.ksmAutoLowTimer = 5000 
		end 
		if newAcc < 0.1 and self.ksmAutoLowTimer < 2000 then 
			self.ksmAutoLowTimer = 2000
		end 
		if maxSpeed > 1.5 * self:getSpeedLimit() and self.ksmAutoDownTimer > 1000 then
			self.ksmAutoDownTimer = 1000
		end 
		
		local newGear  = gear 
		if initGear then 
			newGear = self.vehicle.ksmLaunchGear
		elseif  self.vehicle.ksmAutoShift 
				and gear > self.vehicle.ksmLaunchGear
				and ( lastFwd ~= fwd or self.vehicle.ksmNeutral or self.ksmAutoStop ) then 
			newGear = self.vehicle.ksmLaunchGear
		elseif self.vehicle.ksmAutoShift and self.gearChangeTimer <= 0 and not self.vehicle.ksmNeutral then 
			local m1 = self.minRpm * 1.1
			local m4 = self.maxRpm * 0.975
			local m2 = math.min( m4, m1 / 0.72 )
			local m3 = math.max( m1, m4 * 0.72 )
			local autoMinRpm = m1 + self.ksmLoad * ( m3 - m1 )
			local autoMaxRpm = m3 + self.ksmLoad * ( m4 - m3 )
			if motorPtoRpm > 0 then 
				autoMaxRom = math.min( m4, motorPtoRpm * 1.101363 )
				autoMinRpm = math.max( m1, autoMaxRom * 0.8 )
			end 
					
			if clutchRpm > m4 and self.ksmAutoUpTimer > 0 then
				self.ksmAutoUpTimer = 0
			end 
			if self.ksmClutchTimer <= 0 and wheelRpm < m1 and gear > self.vehicle.ksmLaunchGear and self.ksmAutoDownTimer > 500 then 
				self.ksmAutoDownTimer = 500
			end 
			
			local lowGear = self.vehicle.ksmLaunchGear 
			if self.ksmAutoLowTimer <= 0 and self.ksmLoad > 0.8 then 
				lowGear = math.floor( lowGear * ( 1 - self.ksmLoad ) )
			end 
			
			local searchUp   = ( clutchRpm > autoMaxRpm and self.ksmAutoUpTimer  <= 0 )
			local searchDown = ( wheelRpm < autoMinRpm and self.ksmAutoDownTimer <= 0 )
			
			if isNeutral then
				searchDown = true
				searchUp   = false 
				lowGear    = self.vehicle.ksmLaunchGear
			end 
			
			if searchUp or searchDown then 
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
				for i,r in pairs( keyboardSteerMogli.gearRatios ) do 
					if ( i < gear and searchDown and i >= lowGear ) or ( searchUp and i > gear )  then 
						local rpm = wheelRpm * ratio / r 
						local d2 = 0
						if rpm < autoMinRpm then 
							d2 = autoMinRpm - rpm
						end 
						rpm = clutchRpm * ratio / r 
						if rpm > autoMaxRpm then 
							d2 = math.max( d2, rpm - autoMaxRpm )
						end 
						if d2 < d or ( d2 == d and searchUp ) then 
							newGear = i 
							d = d2
							rr = rpm
						end 
					end 
				end 
				
				self.vehicle.ksmDebug = string.format("%3.0f%%; %3.0f%%; %4.0f..%4.0f; %4.0f -> %4.0f; %d -> %d; %5.0f -> %5.0f",
																							newAcc*100,self.ksmLoad*100,autoMinRpm,autoMaxRpm,wheelRpm, rr,gear,newGear,d1,d)
			end 
		end 
		
		if gear ~= newGear then 
			if self.vehicle.ksmDebug ~= nil then 
				keyboardSteerMogli.debugPrint( g_currentMission.time.."; "..self.vehicle.ksmDebug )
			end 
			
			if     self.vehicle.ksmTransmission == 5 then 
				self.vehicle:ksmSetState( "ksmGear",  newGear )
				self.vehicle:ksmSetState( "ksmRange", 1 )
			elseif self.vehicle.ksmTransmission == 4 then 
				if newGear <= 6 then 
					self.vehicle:ksmSetState( "ksmGear",  newGear )
					self.vehicle:ksmSetState( "ksmRange", 1 )
				else 
					self.vehicle:ksmSetState( "ksmGear",  newGear-6 )
					self.vehicle:ksmSetState( "ksmRange", 2 )
				end 
			else 
				if     newGear == 1 then 
					self.vehicle:ksmSetState( "ksmGear",  1 )
					self.vehicle:ksmSetState( "ksmRange", 1 )
				elseif newGear == 2 then 
					self.vehicle:ksmSetState( "ksmGear",  1 )
					self.vehicle:ksmSetState( "ksmRange", 1 )
				elseif newGear == 3 then 
					if self.vehicle.ksmRange == 1 then 
						self.vehicle:ksmSetState( "ksmGear",  3 )
						self.vehicle:ksmSetState( "ksmRange", 1 )
					else 
						self.vehicle:ksmSetState( "ksmGear",  1 )
						self.vehicle:ksmSetState( "ksmRange", 2 )
					end 
				elseif newGear == 4 then 
					if self.vehicle.ksmRange == 1 then 
						self.vehicle:ksmSetState( "ksmGear",  4 )
						self.vehicle:ksmSetState( "ksmRange", 1 )
					else 
						self.vehicle:ksmSetState( "ksmGear",  2 )
						self.vehicle:ksmSetState( "ksmRange", 2 )
					end 
				elseif newGear == 5 then 
					self.vehicle:ksmSetState( "ksmGear",  3 )
					self.vehicle:ksmSetState( "ksmRange", 2 )
				elseif newGear == 6 then 
					if self.vehicle.ksmRange <= 2 then 
						self.vehicle:ksmSetState( "ksmGear",  4 )
						self.vehicle:ksmSetState( "ksmRange", 2 )
					else 
						self.vehicle:ksmSetState( "ksmGear",  1 )
						self.vehicle:ksmSetState( "ksmRange", 3 )
					end 
				elseif newGear == 7 then 
					self.vehicle:ksmSetState( "ksmGear",  2 )
					self.vehicle:ksmSetState( "ksmRange", 3 )
				elseif newGear == 8 then 
					self.vehicle:ksmSetState( "ksmGear",  3 )
					self.vehicle:ksmSetState( "ksmRange", 3 )
				elseif newGear == 9 then 
					if self.vehicle.ksmRange <= 3 then 
						self.vehicle:ksmSetState( "ksmGear",  4 )
						self.vehicle:ksmSetState( "ksmRange", 3 )
					else 
						self.vehicle:ksmSetState( "ksmGear",  1 )
						self.vehicle:ksmSetState( "ksmRange", 4 )
					end 
				elseif newGear == 10 then 
					self.vehicle:ksmSetState( "ksmGear",  2 )
					self.vehicle:ksmSetState( "ksmRange", 4 )
				elseif newGear == 11 then 
					self.vehicle:ksmSetState( "ksmGear",  3 )
					self.vehicle:ksmSetState( "ksmRange", 4 )
				elseif newGear == 12 then 
					self.vehicle:ksmSetState( "ksmGear",  4 )
					self.vehicle:ksmSetState( "ksmRange", 4 )
				else 
					newGear = gear 
				end 
			end
			
			gear     = newGear 
			ratio    = keyboardSteerMogli.gearRatios[gear]
			maxSpeed = ratio * self.vehicle.ksmMaxSpeed 
			wheelRpm = self.vehicle.lastSpeedReal * 1000 * self.maxRpm / maxSpeed 
		end 
		
		self.vehicle:ksmSetState("ksmBOVVolume",0)
		if not isNeutral then 
			local gearTime  = -1
			local rangeTime = -1
			
			if     self.vehicle.ksmTransmission == 2 then 
				gearTime  = 750
				rangeTime = 1000 
			elseif self.vehicle.ksmTransmission == 3 then 
				gearTime  = -1
				rangeTime = 750 
			elseif self.vehicle.ksmTransmission == 4 then 
				gearTime  = 750
				rangeTime = 1000 
			elseif self.vehicle.ksmTransmission == 5 then
				gearTime  = -1
				rangeTime = -1
			end 
			
			if self.ksmLastRange ~= nil and self.vehicle.ksmRange ~= self.ksmLastRange and self.gearChangeTimer < rangeTime then 
				self.gearChangeTimer = rangeTime
				if self.ksmGearIndex ~= nil and self.ksmGearIndex < gear and rangeTime > 0 then 
					self.vehicle:ksmSetState("ksmBOVVolume",self.ksmLoad)
				end 
			end 
			if self.ksmLastGear ~= nil and self.vehicle.ksmGear ~= self.ksmLastGear and self.gearChangeTimer < gearTime then 
				self.gearChangeTimer = gearTime
				if self.ksmGearIndex ~= nil and self.ksmGearIndex < gear and gearTime > 0 then 
					self.vehicle:ksmSetState("ksmBOVVolume",self.ksmLoad)
				end 
			end 
		end 
		
		if self.ksmGearIndex ~= nil and self.ksmGearIndex ~= gear then 
			if gear > self.ksmGearIndex then 
				self.ksmAutoUpTimer	  = math.max( self.ksmAutoUpTimer	 , 500  + self.gearChangeTimer * 2 )
				self.ksmAutoDownTimer = math.max( self.ksmAutoDownTimer, 3000 + self.gearChangeTimer )
			else                                    
				self.ksmAutoUpTimer	  = math.max( self.ksmAutoUpTimer	 , 3000 + self.gearChangeTimer * 2 )
				self.ksmAutoDownTimer = math.max( self.ksmAutoDownTimer, 500  + self.gearChangeTimer )
			end
		else
			if wheelRpm < self.minRpm * 1.05 then 
				if isNeutral and newAcc < 0.1 then 
					self.ksmAutoStop = true 
				elseif not ( self.ksmAutoStop ) then 
					newAcc = 1
				end 
			end 
		end 
		
		self.ksmGearIndex = gear
		self.ksmLastGear  = self.vehicle.ksmGear
		self.ksmLastRange = self.vehicle.ksmRange
		
		self.minGearRatio = self.maxRpm / ( maxSpeed * keyboardSteerMogli.factor30pi )
		self.maxGearRatio = self.minGearRatio 
				
		if self.gearChangeTimer > 0 then 
			newAcc              = 0
			self.minGearRatio   = 1
			self.maxGearRatio   = 250
			self.ksmClutchTimer = KSMGlobals.clutchTimer
			self.ksmMinRpm      = math.max( self.minRpm, self.lastRealMotorRpm - 0.004 * dt * ( self.maxRpm - self.minRpm ), motorPtoRpm )
			self.ksmMaxRpm      = self.ksmMinRpm
		elseif self.ksmClutchTimer > 0 then 
			if math.abs( self.gearRatio ) < self.minGearRatio * 1.1 and wheelRpm >= self.minRpm then 
				self.ksmClutchTimer = 0
			else
				local f = self.ksmClutchTimer / KSMGlobals.clutchTimer
				self.maxGearRatio = self.minGearRatio + f * ( self.maxForwardGearRatio - self.minGearRatio )
				if self.ksmFakeRpm ~= nil then 
					self.ksmMinRpm  = self.ksmFakeRpm
					self.ksmMaxRpm  = self.ksmFakeRpm
				else 
					self.ksmMinRpm  = math.max( self.minRpm, motorPtoRpm * 0.95, math.min( self.maxRpm, wheelRpm ) )
					self.ksmMaxRpm  = math.max( motorPtoRpm * 1.05, self.minRpm + f * ( self.maxRpm - self.minRpm ), self.lastRealMotorRpm - 0.004 * dt * ( self.maxRpm - self.minRpm ) )
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

VehicleMotor.updateGear = Utils.overwrittenFunction( VehicleMotor.updateGear, keyboardSteerMogli.ksmUpdateGear )

function keyboardSteerMogli:ksmSmoothAcc( acceleratorPedal, brakePedal, dt )
	self.ksmLastRealAcc   = acceleratorPedal
	self.ksmLastRealBrake = brakePedal 
end 

VehicleMotor.getSmoothedAcceleratorAndBrakePedals = Utils.appendedFunction( VehicleMotor.getSmoothedAcceleratorAndBrakePedals, keyboardSteerMogli.ksmSmoothAcc )
--******************************************************************************************************************************************

function keyboardSteerMogli:ksmGetEqualizedMotorRpm( superFunc ) 
	if self.ksmFakeRpm ~= nil then 
		return self.ksmFakeRpm
	end 
	return superFunc( self )
end 

VehicleMotor.getEqualizedMotorRpm = Utils.overwrittenFunction( VehicleMotor.getEqualizedMotorRpm, keyboardSteerMogli.ksmGetEqualizedMotorRpm )
--******************************************************************************************************************************************

function keyboardSteerMogli:ksmGetMotorAppliedTorque( superFunc ) 
	if self.vehicle.ksmTransmission ~= nil and self.vehicle.ksmTransmission > 1 and self.gearChangeTimer > 0 then 
		return 0
	end 
	return superFunc( self )
end 

VehicleMotor.getMotorAppliedTorque = Utils.overwrittenFunction( VehicleMotor.getMotorAppliedTorque, keyboardSteerMogli.ksmGetMotorAppliedTorque )
--******************************************************************************************************************************************


function keyboardSteerMogli:ksmOnSetCamera( old, new, noEventSend ) 
	self.ksmCameraIsOn = new
	if self:ksmIsValidCam() then
		self.ksmCameras[self.spec_enterable.camIndex].rotation = new
		if new and not ( old ) then
			self.ksmCameras[self.spec_enterable.camIndex].zero = self.spec_enterable.cameras[self.spec_enterable.camIndex].origRotY
			self.ksmCameras[self.spec_enterable.camIndex].last = self.spec_enterable.cameras[self.spec_enterable.camIndex].rotY
			self.ksmCameras[self.spec_enterable.camIndex].lastCamFwd = nil
		end
	end
end

function keyboardSteerMogli:ksmOnSetReverse( old, new, noEventSend ) 
	self.ksmReverseIsOn = new
	if self:ksmIsValidCam() then
		self.ksmCameras[self.spec_enterable.camIndex].rev = new
		self.ksmCameras[self.spec_enterable.camIndex].lastCamFwd = nil
	end
end

function keyboardSteerMogli:ksmOnSetFactor( old, new, noEventSend )
	self.ksmExponent = new
	self.ksmFactor   = 1.1 ^ new
end

function keyboardSteerMogli:ksmOnSetSnapAngle( old, new, noEventSend )
	if new < 1 then 
		self.ksmSnapAngle = 1 
	elseif new > table.getn( keyboardSteerMogli.snapAngles ) then 
		self.ksmSnapAngle = table.getn( keyboardSteerMogli.snapAngles ) 
	else 
		self.ksmSnapAngle = new 
	end 
end 

function keyboardSteerMogli:ksmOnSetSnapIsOn( old, new, noEventSend )
	self.ksmSnapIsOn = new 
	
  if      ( old == nil or new ~= old )
			and self.isClient
			and self:getIsEntered()
			and self:getIsVehicleControlledByPlayer() then
		if new and keyboardSteerMogli.snapOnSample ~= nil then
      playSample(keyboardSteerMogli.snapOnSample, 1, 0.2, 0, 0, 0)
		elseif not new and keyboardSteerMogli.snapOffSample ~= nil then
      playSample(keyboardSteerMogli.snapOffSample, 1, 0.2, 0, 0, 0)
		end 
	end 
end 

function keyboardSteerMogli:ksmOnSetGearChanged( old, new, noEventSend )
	if      ( old == nil or new > old )
			and self.isClient
			and self:getIsEntered()
			and self:getIsVehicleControlledByPlayer()
			and keyboardSteerMogli.bovSample ~= nil then 
		local v = 0.2 * new 
		if isSamplePlaying( keyboardSteerMogli.bovSample ) then
			setSampleVolume( keyboardSteerMogli.bovSample, v )
		else 
			playSample( keyboardSteerMogli.bovSample, 1, v, 0, 0, 0)
		end 
	end 
	self.ksmBOVVolume = new 
end 

function keyboardSteerMogli:ksmOnSetWarningText( old, new, noEventSend )
	self.ksmWarningText  = new
  self.ksmWarningTimer = 2000
end

function keyboardSteerMogli:ksmGetAbsolutRotY( camIndex )
	if     self.spec_enterable.cameras == nil
			or self.spec_enterable.cameras[camIndex] == nil then
		return 0
	end
  return keyboardSteerMogli.ksmGetRelativeYRotation( self.spec_enterable.cameras[camIndex].cameraNode, self.spec_wheels.steeringCenterNode )
end

function keyboardSteerMogli.ksmGetRelativeYRotation(root,node)
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



function keyboardSteerMogli:ksmShowSettingsUI()
	if g_gui:getIsGuiVisible() then
		return 
	end
	if g_keyboardSteerMogliScreen == nil then
		-- settings screen
		g_keyboardSteerMogliScreen = keyboardSteerMogliScreen:new()
		for n,t in pairs( keyboardSteerMogli_Register.mogliTexts ) do
			g_keyboardSteerMogliScreen.mogliTexts[n] = t
		end
		g_gui:loadGui(keyboardSteerMogli_Register.g_currentModDirectory .. "keyboardSteerMogliScreen.xml", "keyboardSteerMogliScreen", g_keyboardSteerMogliScreen)	
		g_keyboardSteerMogliScreen:setTitle( "ksmVERSION" )
	end

	self.ksmUI = {}
	self.ksmUI.ksmExponent_V = { -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5 }
	self.ksmUI.ksmExponent = {}
	for i,e in pairs( self.ksmUI.ksmExponent_V ) do
		self.ksmUI.ksmExponent[i] = string.format("%3.0f %%", 100 * ( 1.1 ^ e ), true )
	end
	self.ksmUI.ksmLimitThrottle   = {}
	for i=1,20 do
	  self.ksmUI.ksmLimitThrottle[i] = string.format("%3d %% / %3d %%", 45 + 5 * math.min( i, 11 ), 150 - 5 * math.max( i, 10 ), true )
	end
	self.ksmUI.ksmSnapAngle = {}
	for i,v in pairs( keyboardSteerMogli.snapAngles ) do 
		self.ksmUI.ksmSnapAngle[i] = string.format( "%3d°", v )
	end 
	self.ksmUI.ksmBrakeForce_V = { 0, 0.05, 0.10, 0.15, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1 }
	self.ksmUI.ksmBrakeForce = {}
	for i,e in pairs( self.ksmUI.ksmBrakeForce_V ) do
		self.ksmUI.ksmBrakeForce[i] = string.format("%3.0f %%", 100 * e )
	end
	self.ksmUI.ksmTransmission = { "off", "IVT", "4x4", "4x4 Powershift", "2x6", "FPS" }
	
	local m = keyboardSteerMogli.getDefaultMaxSpeed( self )
	self.ksmUI.ksmMaxSpeed_V = { 7, 8.889, 11.944, 16.111, 25, 33.333, 50 }
	local found = -1 
	for i,v in pairs(self.ksmUI.ksmMaxSpeed_V) do
		if math.abs( m-v ) < 1 then 
			self.ksmUI.ksmMaxSpeed_V[i] = m 
			found = 0
			break 
		elseif v > m and found < 0 then 
			found = i 
		end 
	end 
	if found < 0 then 
		table.insert( self.ksmUI.ksmMaxSpeed_V, m ) 
	elseif found > 0 then 
		table.insert( self.ksmUI.ksmMaxSpeed_V, found, m ) 
	end 
	self.ksmUI.ksmMaxSpeed = {}
	for i,v in pairs(self.ksmUI.ksmMaxSpeed_V) do
		self.ksmUI.ksmMaxSpeed[i] = string.format( "%3.0f km/h", v*3.6 )
	end
	self.ksmUI.ksmLaunchGear = {}
	for i,v in pairs(keyboardSteerMogli.gearRatios) do
		self.ksmUI.ksmLaunchGear[i] = string.format( "%3.0f km/h", v*3.6*self.ksmMaxSpeed )
	end 
	g_keyboardSteerMogliScreen:setVehicle( self )
	g_gui:showGui( "keyboardSteerMogliScreen" )
end

function keyboardSteerMogli:ksmUIGetksmExponent()
	for i,e in pairs( self.ksmUI.ksmExponent_V ) do
		if math.abs( e - self.ksmExponent ) < 0.5 then
			return i
		end
	end
	return 7
end

function keyboardSteerMogli:ksmUISetksmExponent( value )
	if self.ksmUI.ksmExponent_V[value] ~= nil then
		self:ksmSetState( "ksmExponent", self.ksmUI.ksmExponent_V[value] )
	end
end

function keyboardSteerMogli:ksmUIGetksmBrakeForce()
	local d = 2
	local j = 4
	for i,e in pairs( self.ksmUI.ksmBrakeForce_V ) do
		if math.abs( e - self.ksmBrakeForce ) < d then
			d = math.abs( e - self.ksmBrakeForce )
			j = i
		end
	end
	return j
end

function keyboardSteerMogli:ksmUISetksmBrakeForce( value )
	if self.ksmUI.ksmBrakeForce_V[value] ~= nil then
		self:ksmSetState( "ksmBrakeForce", self.ksmUI.ksmBrakeForce_V[value] )
	end
end

function keyboardSteerMogli:ksmUIGetksmMaxSpeed()
	local d, j
	for i,e in pairs( self.ksmUI.ksmMaxSpeed_V ) do
		local f = math.abs( e - self.ksmMaxSpeed )
		if d == nil or d > f then 
			d = f 
			j = i 
		end
	end
	return j
end

function keyboardSteerMogli:ksmUISetksmMaxSpeed( value )
	if self.ksmUI.ksmMaxSpeed_V[value] ~= nil then
		self:ksmSetState( "ksmMaxSpeed", self.ksmUI.ksmMaxSpeed_V[value] )
	end
end




