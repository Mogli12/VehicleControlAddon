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
 	KSMGlobals.debugPrint          = false
	
-- defaults	
  KSMGlobals.ksmCameraIsOn    = false
  KSMGlobals.ksmCamInsideIsOn = false
  KSMGlobals.ksmDrawIsOn      = false
	KSMGlobals.ksmReverseIsOn   = false
	
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

	keyboardSteerMogli.registerState( self, "ksmShuttleIsOn",  true )
	keyboardSteerMogli.registerState( self, "ksmShuttleFwd",   true )
	keyboardSteerMogli.registerState( self, "ksmCamFwd"      , true )
	keyboardSteerMogli.registerState( self, "ksmCameraIsOn"  , false, keyboardSteerMogli.ksmOnSetCamera )
	keyboardSteerMogli.registerState( self, "ksmReverseIsOn" , false, keyboardSteerMogli.ksmOnSetReverse )
	keyboardSteerMogli.registerState( self, "ksmExponent"    , 1    , keyboardSteerMogli.ksmOnSetFactor )
	keyboardSteerMogli.registerState( self, "ksmWarningText" , ""   , keyboardSteerMogli.ksmOnSetWarningText )
	
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

function keyboardSteerMogli.ksmClamp( v, minV, maxV )
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

function keyboardSteerMogli:onUpdate(dt)

  if     self.spec_enterable         == nil
			or self.spec_enterable.cameras == nil then 
		self.ksmDisabled =true return 
	end

	local newRotCursorKey = nil
	local i               = self.spec_enterable.camIndex
	local requestedBack   = nil

	lastInput = self.ksmLastInput
	self.ksmLastInput = nil

	if self.spec_enterable.isEntered and self.isClient and self:getIsActive() then
		if     Input.isKeyPressed( Input.KEY_lshift ) then 
			if     Input.isKeyPressed( Input.KEY_up ) then
				self.ksmLastInput = 11
			elseif Input.isKeyPressed( Input.KEY_down ) then
				self.ksmLastInput = 12
			elseif Input.isKeyPressed( Input.KEY_space ) then
				self.ksmLastInput = 13
			end
		elseif Input.isKeyPressed( Input.KEY_rshift ) then 
			if     Input.isKeyPressed( Input.KEY_up )    then
				self.ksmLastInput = 21
			elseif Input.isKeyPressed( Input.KEY_down )  then
				self.ksmLastInput = 22
			elseif Input.isKeyPressed( Input.KEY_left )  then
				self.ksmLastInput = 23
			elseif Input.isKeyPressed( Input.KEY_right ) then
				self.ksmLastInput = 24
			end
		elseif Input.isKeyPressed( Input.KEY_rctrl ) then 
			if     Input.isKeyPressed( Input.KEY_space ) then
				self.ksmLastInput = 31
			end
		elseif Input.isKeyPressed( Input.KEY_lctrl ) then 
		elseif Input.isKeyPressed( Input.KEY_ralt ) then 
		elseif Input.isKeyPressed( Input.KEY_lalt ) then 
		else 
			if     Input.isKeyPressed( Input.KEY_space ) then
				self.ksmLastInput = 1
			end
		end 

		if     self.ksmLastInput == nil then 
		elseif lastInput ~= nil and self.ksmLastInput == lastInput then 	
		elseif self.ksmLastInput == 1 then
			self:ksmSetState( "ksmShuttleFwd", not self.ksmShuttleFwd )
		elseif self.ksmLastInput == 11 then
			self:ksmSetState( "ksmCameraIsOn", not self.ksmCameraIsOn )
			g_currentMission:showBlinkingWarning( "Camera rotaion = "..tostring(self.ksmCameraIsOn)  , 2000 )
		elseif self.ksmLastInput == 12 then
			self:ksmSetState( "ksmReverseIsOn", not self.ksmReverseIsOn )
			g_currentMission:showBlinkingWarning( "Camera reversal = "..tostring(self.ksmReverseIsOn), 2000 )
		elseif self.ksmLastInput == 13 then
			self:ksmSetState( "ksmShuttleIsOn", not self.ksmShuttleIsOn )
			g_currentMission:showBlinkingWarning( "Shuttle control = "..tostring(self.ksmShuttleIsOn), 2000 )
		elseif self.ksmLastInput == 21 then
			newRotCursorKey = 0
			requestedBack = false
		elseif self.ksmLastInput == 22 then
			newRotCursorKey = math.pi
			requestedBack = true
		elseif self.ksmLastInput == 23 then
			newRotCursorKey = 0.3*math.pi
		elseif self.ksmLastInput == 24 then
			newRotCursorKey = -0.3*math.pi
		elseif self.ksmLastInput == 31 then
		--keyboardSteerMogli.ksmShowSettingsUI( self )
		end
		
		if newRotCursorKey ~= nil then
			self.spec_enterable.cameras[i].rotY = keyboardSteerMogli.normalizeAngle( self.spec_enterable.cameras[i].origRotY + newRotCursorKey )
		end
	end
	
	if self.ksmShuttleIsOn then 
		if self.spec_motorized.motor.lowBrakeForceScale == nil then
		elseif self.ksmLowBrakeForceScale == nil then 
			self.ksmLowBrakeForceScale = self.spec_motorized.motor.lowBrakeForceScale
		else 
			self.spec_motorized.motor.lowBrakeForceScale = 0.1 * self.ksmLowBrakeForceScale 
		end 
	elseif self.ksmLowBrakeForceScale ~= nil then 
		self.spec_motorized.motor.lowBrakeForceScale = self.ksmLowBrakeForceScale 
		self.ksmLowBrakeForceScale = nil
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
			self.ksmMovingDir = self.ksmMovingDir + keyboardSteerMogli.ksmClamp( movingDirection - self.ksmMovingDir, -maxDelta, maxDelta )
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
				self.ksmLastFactor = self.ksmLastFactor + keyboardSteerMogli.ksmClamp( f - self.ksmLastFactor, -KSMGlobals.cameraRotTime*dt, KSMGlobals.cameraRotTime*dt )
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
end

function keyboardSteerMogli:onReadStream(streamId, connection)

  self.ksmCameraIsOn    = streamReadBool(streamId) 
  self.ksmReverseIsOn   = streamReadBool(streamId) 
  self.ksmCamFwd        = streamReadBool(streamId) 
	self.ksmExponent      = streamReadInt16(streamId)     
	
end

function keyboardSteerMogli:onWriteStream(streamId, connection)

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
	return keyboardSteerMogli.ksmClamp( 1 + self.ksmFactor * ( fx - 1 ), mi, ma )
end

function keyboardSteerMogli:ksmUpdateWheelsPhysics( superFunc, dt, currentSpeed, acceleration, doHandbrake, requiredDriveMode )
	local outAcc = acceleration
	local brake  = doHandbrake
	
	if      self.ksmShuttleIsOn
			and ( self.mrGbMS == nil or not ( self.mrGbMS.IsOn ) )
			and self:getIsVehicleControlledByPlayer() then 
		if self.ksmShuttleFwd then 
			if self.movingDirection <= 0 and ( self.lastSpeed >= 0.0001 or acceleration < 0 ) then 
				outAcc = 0 
				brake  = 1 
			end 
		else 
			if self.movingDirection >= 0 and ( self.lastSpeed >= 0.0001 or acceleration < 0 ) then 
				outAcc = 0 
				brake  = 1 
			else 
				outAcc = -outAcc 
			end 
		end 
		if self.lastSpeed < 0.0001 then 
			self.hasStopped = true
		end
	end 
	
	superFunc( self, dt, currentSpeed, outAcc, brake, requiredDriveMode ) 
	
	if self.ksmShuttleIsOn then 
		self:setBrakeLightsVisibility( acceleration < 0 )
	end 
end 


WheelsUtil.updateWheelsPhysics = Utils.overwrittenFunction( WheelsUtil.updateWheelsPhysics, keyboardSteerMogli.ksmUpdateWheelsPhysics )


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
	self.ksmUI = {}
	self.ksmUI.ksmExponent_V = { -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5 }
	self.ksmUI.ksmExponent = {}
	for i,e in pairs( self.ksmUI.ksmExponent_V ) do
		self.ksmUI.ksmExponent[i] = string.format("%3.0f %%", 100 * ( 1.1 ^ e ), true )
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
