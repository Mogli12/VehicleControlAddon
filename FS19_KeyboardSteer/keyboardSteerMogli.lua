--
-- keyboardSteerMogli
-- This is the specialization for keyboardSteerMogli
--

--***************************************************************
source(Utils.getFilename("mogliBase.lua", g_currentModDirectory))
_G[g_currentModName..".mogliBase"].newClass( "keyboardSteerMogli" )
--***************************************************************

KSMGlobals = {}

function keyboardSteerMogli.globalsReset( createIfMissing )
	KSMGlobals                     = {}
	KSMGlobals.cameraRotFactor     = 0
	KSMGlobals.cameraRotFactorRev  = 0
	KSMGlobals.cameraRotTime       = 0
  KSMGlobals.timer4Reverse       = 0
  KSMGlobals.limitThrottle       = 0
 	KSMGlobals.debugPrint          = false
	
-- defaults	
	KSMGlobals.ksmSteeringIsOn  = false
  KSMGlobals.ksmCameraIsOn    = false
  KSMGlobals.ksmCamInsideIsOn = false
  KSMGlobals.ksmDrawIsOn      = false
	KSMGlobals.ksmReverseIsOn   = false
	KSMGlobals.enableAnalogCtrl = false
	
	local file
	file = keyboardSteerMogli.baseDirectory.."keyboardSteerMogliConfig.xml"
	if fileExists(file) then	
		keyboardSteerMogli.globalsLoad( file, "KSMGlobals", KSMGlobals )	
	else
		print("ERROR: NO GLOBALS IN "..file)
	end
	
	file = keyboardSteerMogli.modsDirectory.."keyboardSteerMogliConfig.xml"
	if fileExists(file) then	
		keyboardSteerMogli.globalsLoad( file, "KSMGlobals", KSMGlobals )	
	elseif createIfMissing then
		keyboardSteerMogli.globalsCreate()
	end
	
	print("keyboardSteerMogli initialized");
end

keyboardSteerMogli.globalsReset(false)

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

	keyboardSteerMogli.registerState( self, "ksmSteeringIsOn", false )
	keyboardSteerMogli.registerState( self, "ksmAnalogIsOn",   false )
	keyboardSteerMogli.registerState( self, "ksmShuttleIsOn",  true )
	keyboardSteerMogli.registerState( self, "ksmShuttleFwd",   true )
	keyboardSteerMogli.registerState( self, "ksmCamFwd"      , true )
	keyboardSteerMogli.registerState( self, "ksmCameraIsOn"  , false, keyboardSteerMogli.ksmOnSetCamera )
	keyboardSteerMogli.registerState( self, "ksmReverseIsOn" , false, keyboardSteerMogli.ksmOnSetReverse )
	keyboardSteerMogli.registerState( self, "ksmExponent"    , 1    , keyboardSteerMogli.ksmOnSetFactor )
	keyboardSteerMogli.registerState( self, "ksmWarningText" , ""   , keyboardSteerMogli.ksmOnSetWarningText )
	keyboardSteerMogli.registerState( self, "ksmLimitThrottle",KSMGlobals.limitThrottle )
	keyboardSteerMogli.registerState( self, "ksmLShiftPressed",false )
	
	self.ksmFactor        = 1
	self.ksmReverseTimer  = 1.5 / KSMGlobals.timer4Reverse
	self.ksmMovingDir     = 0
	self.ksmLastFactor    = 0
	self.ksmWarningTimer  = 0
	
	if KSMGlobals.ksmSteeringIsOn then
		self:ksmSetState( "ksmSteeringIsOn", true, true )
	end
	if KSMGlobals.enableAnalogCtrl then
		self:ksmSetState( "ksmAnalogIsOn", true, true )
	end
	
	self.ksmCameras = {}
	
	for i,c in pairs(self.spec_enterable.cameras) do
		self:ksmIsValidCam( i, true )
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
                                "ksmREVERSE" }) do
																

			local _, eventName = self:addActionEvent(self.ksmActionEvents, InputAction[actionName], self, keyboardSteerMogli.actionCallback, false, true, false, true, nil);

		--local __, eventName = InputBinding.registerActionEvent(g_inputBinding, actionName, self, keyboardSteerMogli.actionCallback ,false ,true ,false ,true)
			if     actionName == "ksmSETTINGS"
					or ( self.ksmShuttleIsOn and actionName == "ksmDIRECTION" ) then 
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
	if keyStatus > 0 then 
		if     actionName == "ksmDIRECTION" then
			self:ksmSetState( "ksmShuttleFwd", not self.ksmShuttleFwd )
		elseif actionName == "ksmFORWARD" then
			self:ksmSetState( "ksmShuttleFwd", true )
		elseif actionName == "ksmREVERSE" then
			self:ksmSetState( "ksmShuttleFwd", false )
		elseif actionName == "ksmUP" then
			self.ksmNewRotCursorKey = 0
		elseif actionName == "ksmDOWN" then
			self.ksmNewRotCursorKey = math.pi
		elseif actionName == "ksmLEFT" then
			self.ksmNewRotCursorKey = 0.3*math.pi
		elseif actionName == "ksmRIGHT" then
			self.ksmNewRotCursorKey = -0.3*math.pi
		elseif actionName == "ksmSETTINGS" then
			keyboardSteerMogli.ksmShowSettingsUI( self )
		end
	end
end

function keyboardSteerMogli:onUpdate(dt)

  if     self.spec_enterable         == nil
			or self.spec_enterable.cameras == nil then 
		self.ksmDisabled =true
		return 
	end
	
	self.ksmTickDt = dt 
	
	if      self.isClient
			and self:getIsVehicleControlledByPlayer() 
			and Input.isKeyPressed( Input.KEY_lshift ) then 
		self:ksmSetState( "ksmLShiftPressed", true )
	else 
		self:ksmSetState( "ksmLShiftPressed", false )
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
	
	if self.ksmShuttleIsOn then 
		if self.spec_motorized.motor.lowBrakeForceScale == nil then
		elseif self.ksmLowBrakeForceScale == nil then 
			self.ksmLowBrakeForceScale = self.spec_motorized.motor.lowBrakeForceScale
			self.ksmLowBrakeForceSpeedLimit = self.spec_motorized.motor.lowBrakeForceSpeedLimit 
		else 
			self.spec_motorized.motor.lowBrakeForceScale = 0.2 * self.ksmLowBrakeForceScale 
			self.spec_motorized.motor.lowBrakeForceSpeedLimit = 0
		end 
	elseif self.ksmLowBrakeForceScale ~= nil then 
		self.spec_motorized.motor.lowBrakeForceScale = self.ksmLowBrakeForceScale 
		self.spec_motorized.motor.lowBrakeForceSpeedLimit = self.ksmLowBrakeForceSpeedLimit
		self.ksmLowBrakeForceScale = nil
		self.ksmLowBrakeForceSpeedLimit = nil
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
						iRev = not isRev
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
				--print("reverse")
					newRotY = newRotY - self:ksmScaleFx( KSMGlobals.cameraRotFactorRev, 0.1, 3 ) * f				
				else
				--print("forward")
					newRotY = newRotY + self:ksmScaleFx( KSMGlobals.cameraRotFactor, 0.1, 3 ) * f
				end	
				
			else
				self.ksmLastFactor = 0
			end

			self.spec_enterable.cameras[i].rotY = newRotY			
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
	if self.ksmSteeringIsOn and self:getIsVehicleControlledByPlayer() then 
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

	if self.ksmLShiftPressed and self.spec_drivable.cruiseControl.state == 1 then
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

function keyboardSteerMogli:onReadStream(streamId, connection)

	self.ksmSteeringIsOn  = streamReadBool(streamId) 
  self.ksmCameraIsOn    = streamReadBool(streamId) 
  self.ksmReverseIsOn   = streamReadBool(streamId) 
  self.ksmCamFwd        = streamReadBool(streamId) 
	self.ksmExponent      = streamReadInt16(streamId)     
	
end

function keyboardSteerMogli:onWriteStream(streamId, connection)

	streamWriteBool(streamId, self.ksmSteeringIsOn )
	streamWriteBool(streamId, self.ksmCameraIsOn )
	streamWriteBool(streamId, self.ksmReverseIsOn )
	streamWriteBool(streamId, self.ksmCamFwd )     
	streamWriteInt16(streamId,self.ksmExponent )     

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
	elseif  KSMGlobals.ksmCamInsideIsOn 
			and self.spec_enterable.cameras[camIndex].isInside then
		keyboardSteerMogli.debugPrint( "camera is inside" )
		return true
	end
	keyboardSteerMogli.debugPrint( "other camera: "..tostring(KSMGlobals.ksmCameraIsOn) )
	return KSMGlobals.ksmCameraIsOn
end

function keyboardSteerMogli:getDefaultReverse( camIndex )
	if     self.spec_enterable.cameras           == nil
			or self.spec_enterable.cameras[camIndex] == nil then
		return false
	elseif not ( self.spec_enterable.cameras[camIndex].isRotatable )
			or self.spec_enterable.cameras[camIndex].vehicle ~= self then
		return false
	elseif  self.spec_enterable.cameras[camIndex].isInside
			and SpecializationUtil.hasSpecialization(Combine, self.specializations) then
		return false
	end
	
	if self.attacherJoints ~= nil then
		for _,a in pairs( self.attacherJoints ) do
			if a.jointType == JOINTTYPE_SEMITRAILER then
				return false
			end
		end
	end
	
	return KSMGlobals.ksmReverseIsOn
end

function keyboardSteerMogli:ksmScaleFx( fx, mi, ma )
	return keyboardSteerMogli.mbClamp( 1 + self.ksmFactor * ( fx - 1 ), mi, ma )
end


--******************************************************************************************************************************************
-- shuttle control and inching
function keyboardSteerMogli:ksmUpdateWheelsPhysics( superFunc, ... )
	local backup2 = self.spec_drivable.reverserDirection
	local args   = { ... }
	local acceleration = Utils.getNoNil( args[3] )
	local brake = ( acceleration < 0 )
	
	self.ksmOldAcc       = args[3]
	self.ksmOldHandbrake = args[4]
	
	if self.ksmShuttleIsOn and self:getIsVehicleControlledByPlayer() then 
		if self:getIsMotorStarted() then 
			if self.ksmShuttleFwd then 
				self.spec_drivable.reverserDirection = 1
			else 
				self.spec_drivable.reverserDirection = -1
			end 
		
			if     math.abs( args[2] ) < 0.0004 and args[3] < 0 then 
				args[3] = 0
				args[4] = 1
			elseif math.abs( args[2] ) < 0.0001 then
			elseif self.movingDirection * self.spec_drivable.reverserDirection < 0 then 
				args[3] = 0
				args[4] = 1
				brake   = true 
			end 
		else 
			args[3] = 0
			args[4] = 1
		end 		
	end 
	
	if args[3] ~= nil and self.spec_drivable.cruiseControl.state == 0 then 
		local limitThrottleRatio     = 0.75
		local limitThrottleIfPressed = true
		if self.ksmLimitThrottle < 11 then
			limitThrottleIfPressed = false
			limitThrottleRatio     = 0.45 + 0.05 * self.ksmLimitThrottle
		else
			limitThrottleIfPressed = true
			limitThrottleRatio     = 1.5 - 0.05 * self.ksmLimitThrottle
		end
			
		if self.ksmLShiftPressed == limitThrottleIfPressed then
			args[3] = args[3] * limitThrottleRatio
		end
	end
	
	self.ksmNewAcc       = args[3]
	self.ksmNewHandbrake = args[4]
	
	local state, result = pcall( superFunc, self, unpack( args ) ) 
	if not ( state ) then
		print("Error in updateWheelsPhysics :"..tostring(result))
		self.ksmShuttleIsOn = false 
	end
	
	g_currentMission.missionInfo.stopAndGoBraking = backup1
	self.spec_drivable.reverserDirection          = backup2
	
	if self.ksmShuttleIsOn then 
		self:setBrakeLightsVisibility( brake )
		self:setReverseLightsVisibility( not self.ksmShuttleFwd )
	end 
	
	return result 
end 
WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction( WheelsUtil.updateWheelsPhysics, keyboardSteerMogli.ksmUpdateWheelsPhysics )


--******************************************************************************************************************************************
-- increased minRPM
function keyboardSteerMogli:getRequiredMotorRpmRange( superFunc, ... )
	local minRpm, maxRpm = superFunc( self, ... )
	
	if self.vehicle.ksmShuttleIsOn then 
		if self.vehicle.lastSpeed > 5.56e-4 then 
			self.ksmIncreaseRpm = g_currentMission.time + 1000 
		end 
	elseif self.ksmIncreaseRpm ~= nil then 
		self.ksmIncreaseRpm = nil 
	end 
	local minReducedRpm = math.min( math.max( minRpm, 0.62*math.min( 2100, self.vehicle.spec_motorized.motor.maxRpm ) ), maxRpm )
	if self.ksmIncreaseRpm ~= nil and g_currentMission.time < self.ksmIncreaseRpm  then 
		minRpm = minReducedRpm
	end
	
	if self.maxRpm ~= nil then
		local limitThrottleRatio     = 0.75
		local limitThrottleIfPressed = true
		if self.vehicle.ksmLimitThrottle < 11 then
			limitThrottleIfPressed = false
			limitThrottleRatio     = 0.45 + 0.05 * self.vehicle.ksmLimitThrottle
		else
			limitThrottleIfPressed = true
			limitThrottleRatio     = 1.5 - 0.05 * self.vehicle.ksmLimitThrottle
		end
				
		if self.vehicle.ksmLShiftPressed == limitThrottleIfPressed then 
			maxRpm = math.max( minReducedRpm, math.min( maxRpm, self.maxRpm * limitThrottleRatio ) )
		end 
	end 
	
	if self.vehicle.ksmShuttleIsOn and self.vehicle.spec_motorized.actualLoadPercentage < 0.9 then 
		local maxSpeed = math.abs( self.vehicle.lastSpeedReal * 3600 ) + 1
		local minRatio = self.vehicle.spec_motorized.motor.minForwardGearRatio
		if not self.vehicle.ksmShuttleFwd then 
			minRatio     = self.vehicle.spec_motorized.motor.minBackwardGearRatio
		end 
		local wheelRpm = maxSpeed/3.6 * 60 / (math.pi+math.pi)
		local newRpm   = wheelRpm * minRatio 
		maxRpm = keyboardSteerMogli.mbClamp( newRpm, minReducedRpm, maxRpm )
	end 
	
	if self.vehicle.ksmShuttleIsOn and self.vehicle.ksmTickDt ~= nil then 
		local delta = self.vehicle.spec_motorized.motor.maxRpm * 0.0002 * self.vehicle.ksmTickDt
		if self.ksmLastMinRpm ~= nil and self.ksmLastMaxRpm ~= nil then 
			minRpm = keyboardSteerMogli.mbClamp( minRpm, self.ksmLastMinRpm - delta, self.vehicle.spec_motorized.motor.lastRealMotorRpm + delta )
			maxRpm = keyboardSteerMogli.mbClamp( maxRpm, self.vehicle.spec_motorized.motor.lastRealMotorRpm - delta, self.ksmLastMaxRpm + delta )
		end 
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
		return
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

for n,f in pairs(keyboardSteerMogli) do 
	keyboardSteerMogli.origDrivable = {}
	local g = Drivable[n]
	if type(f)=="function" and type(g)=="function" then 
		keyboardSteerMogli.origDrivable = g
		print("keyboardSteerMogli:"..tostring(n))
		Drivable[n] = function( self, ... )
			local r = { g( self, ... ) }
			if not ( self.ksmDisabled ) then 
				local s,m = pcall( f, self, ... )
				if not ( s ) then
					print("Error in "..n.." :"..tostring(m))
					self.ksmDisabled = true 
				end			
			end			
			return unpack( r )
		end
	end 
end 
