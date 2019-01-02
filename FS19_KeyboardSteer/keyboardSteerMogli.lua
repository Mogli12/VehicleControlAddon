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
	for _,n in pairs( { "onLoad", "onPostLoad", "onUpdate", "onUpdateTick", "onDraw", "onLeaveVehicle", "onReadStream", "onWriteStream", "saveToXMLFile", "onRegisterActionEvents" } ) do
		SpecializationUtil.registerEventListener(vehicleType, n, keyboardSteerMogli)
	end 
end 

KSMGlobals = {}
keyboardSteerMogli.snapAngles = { 5, 7.5, 15, 22.5, 45, 90 }

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
	keyboardSteerMogli.registerState( self, "ksmShuttleIsOn",  KSMGlobals.shuttleControl )
	keyboardSteerMogli.registerState( self, "ksmPeekLeftRight",KSMGlobals.peekLeftRight )
	keyboardSteerMogli.registerState( self, "ksmShuttleFwd",   true )
	keyboardSteerMogli.registerState( self, "ksmCamFwd"      , true )
	keyboardSteerMogli.registerState( self, "ksmCameraIsOn"  , false, keyboardSteerMogli.ksmOnSetCamera )
	keyboardSteerMogli.registerState( self, "ksmReverseIsOn" , false, keyboardSteerMogli.ksmOnSetReverse )
	keyboardSteerMogli.registerState( self, "ksmExponent"    , 1    , keyboardSteerMogli.ksmOnSetFactor )
	keyboardSteerMogli.registerState( self, "ksmWarningText" , ""   , keyboardSteerMogli.ksmOnSetWarningText )
	keyboardSteerMogli.registerState( self, "ksmLimitThrottle",KSMGlobals.limitThrottle )
	keyboardSteerMogli.registerState( self, "ksmSnapAngle"   , KSMGlobals.snapAngle, keyboardSteerMogli.ksmOnSetSnapAngle )
	keyboardSteerMogli.registerState( self, "ksmSnapIsOn" ,    false )
	keyboardSteerMogli.registerState( self, "ksmInchingIsOn" , false )
	keyboardSteerMogli.registerState( self, "ksmNoAutoRotBack",false )
	keyboardSteerMogli.registerState( self, "ksmBrakeLights",  false )
	keyboardSteerMogli.registerState( self, "ksmBrakeForce",   KSMGlobals.brakeForceFactor )
	
	self.ksmFactor        = 1
	self.ksmReverseTimer  = 1.5 / KSMGlobals.timer4Reverse
	self.ksmMovingDir     = 0
	self.ksmLastFactor    = 0
	self.ksmWarningTimer  = 0
	
	self.ksmCameras = {}
	
	for i,c in pairs(self.spec_enterable.cameras) do
		self:ksmIsValidCam( i, true )
	end	
end

function keyboardSteerMogli:onPostLoad(savegame)
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		local key     = savegame.key ..".keyboardSteerMogli"	
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
			self:ksmSetState( "ksmShuttleIsOn", b )
		end 
		
		b = getXMLBool(xmlFile, key.."#peek")
		keyboardSteerMogli.debugPrint("peek: "..tostring(b))
		if b ~= nil then 
			self:ksmSetState( "ksmPeekLeftRight", b )
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
	if self.ksmShuttleIsOn ~= nil and self.ksmShuttleIsOn ~= KSMGlobals.shuttleControl then
		setXMLBool(xmlFile, key.."#shuttle", self.ksmShuttleIsOn)
	end
	if self.ksmPeekLeftRight ~= nil and self.ksmPeekLeftRight ~= KSMGlobals.peekLeftRight then
		setXMLBool(xmlFile, key.."#peek", self.ksmPeekLeftRight)
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
																"AXIS_MOVE_SIDE_VEHICLE" }) do
																
			local isPressed = false 
			if     actionName == "AXIS_MOVE_SIDE_VEHICLE"
					or actionName == "ksmUP"
					or actionName == "ksmDOWN"
					or actionName == "ksmLEFT"
					or actionName == "ksmRIGHT" 
					or actionName == "ksmINCHING"
					or actionName == "ksmNO_ARB" then 
				isPressed = true 
			end 
			
			local _, eventName = self:addActionEvent(self.ksmActionEvents, InputAction[actionName], self, keyboardSteerMogli.actionCallback, isPressed, true, false, true, nil);

		--local __, eventName = InputBinding.registerActionEvent(g_inputBinding, actionName, self, keyboardSteerMogli.actionCallback ,false ,true ,false ,true)
			if      g_inputBinding                   ~= nil 
					and g_inputBinding.events            ~= nil 
					and g_inputBinding.events[eventName] ~= nil
					and ( actionName == "ksmSETTINGS"
					   or ( self.ksmShuttleIsOn and actionName == "ksmDIRECTION" ) ) then 
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
	elseif actionName == "ksmINCHING" then 
		self:ksmSetState( "ksmInchingIsOn", keyStatus > 0 )
	elseif actionName == "ksmNO_ARB" then 
		self:ksmSetState( "ksmNoAutoRotBack", keyStatus > 0 )
	elseif actionName == "ksmDIRECTION" then
		self:ksmSetState( "ksmShuttleFwd", not self.ksmShuttleFwd )
	elseif actionName == "ksmFORWARD" then
		self:ksmSetState( "ksmShuttleFwd", true )
	elseif actionName == "ksmREVERSE" then
		self:ksmSetState( "ksmShuttleFwd", false )
	elseif actionName == "ksmSNAP" then
		self:ksmSetState( "ksmSnapIsOn", not self.ksmSnapIsOn )
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
	
	self.ksmTickDt = dt 
	
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
	
	if self.ksmShuttleIsOn then 
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

	if self:getIsActive() and self.isServer then
		if      self.mrGbMS ~= nil
				and self.mrGbMS.IsOn then
			if self.ksmShuttleIsOn then 
				self:ksmSetState( "ksmShuttleIsOn", false )
			end
			if self.mrGbMS.ReverseActive then
				self.ksmMovingDir = -1
			else
				self.ksmMovingDir = 1
			end
		elseif  self.ksmShuttleIsOn then 
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
end 
	
local origSetBrakeLightsVisibility   = Lights.setBrakeLightsVisibility
local origSetReverseLightsVisibility = Lights.setReverseLightsVisibility
function Lights:setBrakeLightsVisibility( visibility, ... )
	if self.ksmShuttleIsOn then 
		return true 
	end 
	return origSetBrakeLightsVisibility( self, visibility, ... )
end 
function Lights:setReverseLightsVisibility( visibility, ... )
	if self.ksmShuttleIsOn then 
		return true 
	end 
	return origSetReverseLightsVisibility( self, visibility, ... )
end 

function keyboardSteerMogli:onUpdateTick(dt)
	if self.ksmShuttleIsOn and self.spec_lights ~= nil then 
		origSetBrakeLightsVisibility( self, self.ksmBrakeLights )
		origSetReverseLightsVisibility( self, not self.ksmShuttleFwd )
	end 	
end

function keyboardSteerMogli:onDraw()
	setTextAlignment( RenderText.ALIGN_CENTER ) 
	setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_MIDDLE )
	setTextColor(1, 1, 1, 1) 
	
	local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
	local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.6
	local l = 0.03 * keyboardSteerMogli.getUiScale()

	if self.ksmShuttleIsOn and self:getIsVehicleControlledByPlayer() and not g_gui:getIsGuiVisible() then
		if self.ksmShuttleFwd then
			renderText(x, y, l, "F")
		else
			renderText(x, y, l, "R")
		end
	end
	
	if KSMGlobals.snapAngleHudX >= 0 then 
		x = KSMGlobals.snapAngleHudX
		y = KSMGlobals.snapAngleHudY
		setTextAlignment( RenderText.ALIGN_LEFT ) 
		setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
	else 
		y = y + l * 1.1
	end 
	
	local lx,_,lz = localDirectionToWorld( self.components[1].node, 0, 0, 1 )			
	if lx*lx+lz*lz > 1e-6 then 
		renderText(x, y, l, string.format( "%4.1f°", math.deg( math.atan2( lx, lz ) + math.pi )))
	end 
	
	y = y + l * 1.1	
	if self.ksmLastSnapAngle ~= nil then
		renderText(x, y, l, string.format( "%4.1f°", math.deg( self.ksmLastSnapAngle + math.pi )))
	end
	
	setTextAlignment( RenderText.ALIGN_LEFT ) 
	setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
end

function keyboardSteerMogli:onReadStream(streamId, connection)

	self.ksmSteeringIsOn  = streamReadBool(streamId) 
  self.ksmCameraIsOn    = streamReadBool(streamId) 
  self.ksmReverseIsOn   = streamReadBool(streamId) 
  self.ksmCamFwd        = streamReadBool(streamId) 
  self.ksmShuttleIsOn   = streamReadBool(streamId) 
  self.ksmShuttleFwd    = streamReadBool(streamId) 
	self.ksmExponent      = streamReadInt16(streamId)     
	self.ksmSnapAngle     = streamReadInt16(streamId)     
	
end

function keyboardSteerMogli:onWriteStream(streamId, connection)

	streamWriteBool(streamId, self.ksmSteeringIsOn )
	streamWriteBool(streamId, self.ksmCameraIsOn )
	streamWriteBool(streamId, self.ksmReverseIsOn )
	streamWriteBool(streamId, self.ksmCamFwd )     
	streamWriteBool(streamId, self.ksmShuttleIsOn )     
	streamWriteBool(streamId, self.ksmShuttleFwd )     
	streamWriteInt16(streamId,self.ksmExponent )     
	streamWriteInt16(streamId,self.ksmSnapAngle )     

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
function keyboardSteerMogli:ksmUpdateWheelsPhysics( superFunc, ... )
	local args   = { ... }
	local acceleration = Utils.getNoNil( args[3] )
	local brake = ( acceleration < 0 )
	
	self.ksmOldAcc       = args[3]
	self.ksmOldHandbrake = args[4]
	
	if self:getIsVehicleControlledByPlayer() then 
		if self.ksmShuttleIsOn then 
			if self:getIsMotorStarted() then 
				
				local lowSpeedBrake = -1
				if args[3] < 0 then 
					lowSpeedBrake = 1.389e-4 - args[3] * 6.944e-4 -- 0.5 .. 3
				end 
			
				if      self.spec_motorized.motor.maxGearRatio ~= nil 
						and self.spec_motorized.motor.maxGearRatio * self.spec_drivable.reverserDirection < 0 then 
					-- wrong direction and new transmission
					args[3] = 1
					args[4] = true 
					brake   = true 
				elseif  math.abs( args[2] ) < lowSpeedBrake then 
					-- braking at low speed
					args[3] = 0
					args[4] = true 
				elseif  self.spec_motorized.motor.maxGearRatio ~= nil then 
					-- no further processing for new transmission
				elseif  math.abs( args[2] ) < 0.0001 then
					-- low speed 
				elseif  self.movingDirection * self.spec_drivable.reverserDirection < 0 then 
					-- wrong direction and old transmission
					args[3] = 0
					args[4] = true 
					brake   = true 
				end 
			else 
				args[3] = 0
				args[4] = true
			end 		
		end 
		
		if args[3] ~= nil and self.spec_drivable.cruiseControl.state == 0 and self.ksmLimitThrottle ~= nil and self.ksmInchingIsOn ~= nil then 
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
				args[3] = args[3] * limitThrottleRatio
			end
		end
	end 
	
	self.ksmNewAcc       = args[3]
	self.ksmNewHandbrake = args[4]
	args[5] = true 
	
	local state, result = pcall( superFunc, self, unpack( args ) ) 
	if not ( state ) then
		print("Error in updateWheelsPhysics :"..tostring(result))
		self.ksmShuttleIsOn = false 
	end
	
	if self.ksmShuttleIsOn then 
		self:ksmSetState( "ksmBrakeLights", brake )
	end 
	
	return result 
end 
WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction( WheelsUtil.updateWheelsPhysics, keyboardSteerMogli.ksmUpdateWheelsPhysics )


--******************************************************************************************************************************************
-- increased minRPM
function keyboardSteerMogli:getRequiredMotorRpmRange( superFunc, ... )
	local minRpm, maxRpm = superFunc( self, ... )

	self.ksmOrigMinRpm = minRpm
	self.ksmOrigMaxRpm = maxRpm
	local speed = math.abs( self.vehicle.lastSpeedReal ) *3600
	
	if self.vehicle.ksmShuttleIsOn then 
		if speed > 2 then 
			self.ksmIncreaseRpm = g_currentMission.time + 1000 
		end 
	elseif self.ksmIncreaseRpm ~= nil then 
		self.ksmIncreaseRpm = nil 
	end 
	
	local minReducedRpm = math.min( math.max( minRpm, 0.5*math.min( 2200, self.maxRpm ) ), maxRpm )
	if self.vehicle.spec_combine ~= nil then 
		minReducedRpm = math.min( math.max( minRpm, 0.8*math.min( 2200, self.maxRpm ) ), maxRpm )
	end 
	
	if speed > 0.5 and self.ksmIncreaseRpm ~= nil and g_currentMission.time < self.ksmIncreaseRpm  then 
		minRpm = minReducedRpm
	end
	minReducedRpm = minReducedRpm + 0.1 * maxRpm
	
	if self.vehicle.spec_combine == nil and self.vehicle.ksmLimitThrottle ~= nil and self.vehicle.ksmInchingIsOn ~= nil then 
		
		if self.maxRpm ~= nil and self.vehicle.spec_drivable.cruiseControl.state == 0 then
			
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
				maxRpm = math.max( minReducedRpm, math.min( maxRpm, self.maxRpm * limitThrottleRatio ) )
			end 
		end 
		
		local lowLoad = false 
		if self.vehicle.ksmShuttleIsOn then
			if     self.ksmChangeTime ~= nil and g_currentMission.time < self.ksmChangeTime + 5500 then
			elseif self.vehicle.spec_motorized.actualLoadPercentage < 0.5 then 	
				lowLoad = true 
			else 
				local l = ( self.vehicle.spec_motorized.actualLoadPercentage - 0.5 ) * 2
				if     self.gearRatio > 0 and self.differentialRotAcceleration > l and self.differentialRotAccelerationSmoothed > l then 
					lowLoad = true 
				elseif self.gearRatio < 0 and self.differentialRotAcceleration <-l and self.differentialRotAccelerationSmoothed <-l then 
					lowLoad = true 
				end 
			end 
		end 
		
		if lowLoad then 
			local minRatio = self.minForwardGearRatio
			if not self.vehicle.ksmShuttleFwd then 
				minRatio     = self.minBackwardGearRatio
			end 
			local wheelRpm = (speed + 1 )/3.6 * 60 / (math.pi+math.pi)
			local newRpm   = wheelRpm * minRatio 
			if newRpm < minReducedRpm then 
				newRpm = minReducedRpm 
			end 
			if newRpm < maxRpm then 
				if self.vehicle.spec_motorized.actualLoadPercentage < 0.75 then 
					maxRpm = newRpm 
				else 
					maxRpm = newRpm + 4 * ( self.vehicle.spec_motorized.actualLoadPercentage - 0.75 ) * ( maxRpm - newRpm )
				end 
			end 
		end 
	end 
	
	if speed > 0.5 and self.vehicle.ksmShuttleIsOn and self.vehicle.ksmTickDt ~= nil then 
		if self.ksmLastMinRpm == nil or self.ksmLastMaxRpm == nil then 
			self.ksmLastMinRpm = self.lastRealMotorRpm 
			self.ksmLastMaxRpm = self.lastRealMotorRpm 
		end 
		local deltaS, deltaF
		deltaS = self:getMaxRpm() * 0.0001 * self.vehicle.ksmTickDt
		deltaF = self:getMaxRpm() * 0.0002 * self.vehicle.ksmTickDt
		minRpm = keyboardSteerMogli.mbClamp( minRpm, self.ksmLastMinRpm - deltaS, math.max( self.ksmLastMinRpm, self.lastRealMotorRpm + deltaF ) )
		maxRpm = keyboardSteerMogli.mbClamp( maxRpm, math.max( self.ksmLastMaxRpm, self.lastRealMotorRpm ) - deltaS, self.ksmLastMaxRpm + deltaS )
		self.ksmLastMinRpm = minRpm 
		self.ksmLastMaxRpm = maxRpm 
	elseif self.ksmLastMinRpm ~= nil or self.ksmLastMaxRpm ~= nil then 
		self.ksmLastMinRpm = nil 
		self.ksmLastMaxRpm = nil 
	end 
	
	return minRpm, maxRpm 
end 

VehicleMotor.getRequiredMotorRpmRange = Utils.overwrittenFunction( VehicleMotor.getRequiredMotorRpmRange, keyboardSteerMogli.getRequiredMotorRpmRange )
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


