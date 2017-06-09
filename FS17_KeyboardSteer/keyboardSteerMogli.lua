--
-- keyboardSteerMogli
-- This is the specialization for keyboardSteerMogli
--

--***************************************************************
source(Utils.getFilename("mogliBase.lua", g_currentModDirectory))
_G[g_currentModName..".mogliBase"].newClass( "keyboardSteerMogli" )
--***************************************************************

function keyboardSteerMogli.globalsReset( createIfMissing )
	KSMGlobals                   = {}
	KSMGlobals.cameraRotFactor     = 0
	KSMGlobals.cameraRotFactorRev  = 0
	KSMGlobals.cameraRotTime       = 0
	KSMGlobals.speedFxPoint1       = 0
	KSMGlobals.speedFxPoint2       = 0
	KSMGlobals.speedFxPoint3       = 0
	KSMGlobals.autoRotateBackFx0   = 0
	KSMGlobals.autoRotateBackFx1   = 0
	KSMGlobals.autoRotateBackFx2   = 0
	KSMGlobals.autoRotateBackFx3   = 0
	KSMGlobals.autoRotateBackFxMax = 0
	KSMGlobals.axisSideFx0         = 0
	KSMGlobals.axisSideFx1         = 0
	KSMGlobals.axisSideFx2         = 0
	KSMGlobals.axisSideFx3         = 0
	KSMGlobals.axisSideFxMax       = 0
	KSMGlobals.maxRotTimeFx0       = 0
	KSMGlobals.maxRotTimeFx1       = 0
	KSMGlobals.maxRotTimeFx2       = 0
	KSMGlobals.maxRotTimeFx3       = 0
	KSMGlobals.maxRotTimeFxMax     = 0
	KSMGlobals.waitTimeFx0	       = 0
	KSMGlobals.waitTimeFx1	       = 0
	KSMGlobals.waitTimeFx2	       = 0
	KSMGlobals.waitTimeFx3	       = 0
	KSMGlobals.waitTimeFxMax	     = 0
  KSMGlobals.maxSpeed4Fx	       = 0
  KSMGlobals.timer4Reverse       = 0
  KSMGlobals.minSpeed4Fx	       = 0
  KSMGlobals.speedFxInc          = 0
  KSMGlobals.autoRotateBackWait  = 0	
  KSMGlobals.axisSideWait        = 0	
  KSMGlobals.limitThrottle       = 0	
	KSMGlobals.enableAnalogCtrl    = false
	KSMGlobals.debugPrint          = false
	
-- defaults	
  KSMGlobals.ksmSteeringIsOn  = false
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
	
	KSMGlobals.autoRotateBackFx = AnimCurve:new(linearInterpolator1)
	KSMGlobals.axisSideFx       = AnimCurve:new(linearInterpolator1)
	KSMGlobals.maxRotTimeFx     = AnimCurve:new(linearInterpolator1)
	KSMGlobals.waitTimeFx       = AnimCurve:new(linearInterpolator1)
	
	KSMGlobals.autoRotateBackFx:addKeyframe({v=KSMGlobals.autoRotateBackFx0, time = 0})
	KSMGlobals.autoRotateBackFx:addKeyframe({v=KSMGlobals.autoRotateBackFx1, time = KSMGlobals.speedFxPoint1/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.autoRotateBackFx:addKeyframe({v=KSMGlobals.autoRotateBackFx2, time = KSMGlobals.speedFxPoint2/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.autoRotateBackFx:addKeyframe({v=KSMGlobals.autoRotateBackFx3, time = KSMGlobals.speedFxPoint3/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.autoRotateBackFx:addKeyframe({v=KSMGlobals.autoRotateBackFxMax, time = 1})
	
	KSMGlobals.axisSideFx:addKeyframe({v=KSMGlobals.axisSideFx0, time = 0})
	KSMGlobals.axisSideFx:addKeyframe({v=KSMGlobals.axisSideFx1, time = KSMGlobals.speedFxPoint1/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.axisSideFx:addKeyframe({v=KSMGlobals.axisSideFx2, time = KSMGlobals.speedFxPoint2/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.axisSideFx:addKeyframe({v=KSMGlobals.axisSideFx3, time = KSMGlobals.speedFxPoint3/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.axisSideFx:addKeyframe({v=KSMGlobals.axisSideFxMax, time = 1})

	KSMGlobals.maxRotTimeFx:addKeyframe({v=KSMGlobals.maxRotTimeFx0, time = 0})
	KSMGlobals.maxRotTimeFx:addKeyframe({v=KSMGlobals.maxRotTimeFx1, time = KSMGlobals.speedFxPoint1/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.maxRotTimeFx:addKeyframe({v=KSMGlobals.maxRotTimeFx2, time = KSMGlobals.speedFxPoint2/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.maxRotTimeFx:addKeyframe({v=KSMGlobals.maxRotTimeFx3, time = KSMGlobals.speedFxPoint3/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.maxRotTimeFx:addKeyframe({v=KSMGlobals.maxRotTimeFxMax, time = 1})
		
	KSMGlobals.waitTimeFx:addKeyframe({v=KSMGlobals.waitTimeFx0, time = 0})
	KSMGlobals.waitTimeFx:addKeyframe({v=KSMGlobals.waitTimeFx1, time = KSMGlobals.speedFxPoint1/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.waitTimeFx:addKeyframe({v=KSMGlobals.waitTimeFx2, time = KSMGlobals.speedFxPoint2/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.waitTimeFx:addKeyframe({v=KSMGlobals.waitTimeFx3, time = KSMGlobals.speedFxPoint3/KSMGlobals.maxSpeed4Fx})
	KSMGlobals.waitTimeFx:addKeyframe({v=KSMGlobals.waitTimeFxMax, time = 1})
		
	print("keyboardSteerMogli initialized");
end

keyboardSteerMogli.globalsReset(false)

function keyboardSteerMogli.debugPrint( ... )
	if KSMGlobals.debugPrint then
		print( ... )
	end
end

function keyboardSteerMogli:isValidCam( index, createIfMissing )
	local i = Utils.getNoNil( index, self.camIndex )
	
	if      self.cameras ~= nil 
			and i ~= nil 
			and self.cameras[i] ~= nil 
			and self.cameras[i].vehicle == self
			and self.cameras[i].isRotatable then
		if self.ksmCameras[i] == nil then
			if createIfMissing then
				self.ksmCameras[i] = { rotation = keyboardSteerMogli.getDefaultRotation( self, i ),
															 rev      = keyboardSteerMogli.getDefaultReverse( self, i ),
															 zero     = self.cameras[i].rotY,
															 last     = self.cameras[i].rotY }
			else
				return false
			end
		end
		return true
	end
	
	return false
end

function keyboardSteerMogli:load(savegame)

	self.ksmScaleFx       = keyboardSteerMogli.scaleFx
	self.ksmSetState      = keyboardSteerMogli.mbSetState
	self.ksmIsValidCam    = keyboardSteerMogli.isValidCam

	keyboardSteerMogli.registerState( self, "ksmSteeringIsOn", false )
	keyboardSteerMogli.registerState( self, "ksmAnalogIsOn",   false )
	keyboardSteerMogli.registerState( self, "ksmCamFwd"      , true )
	keyboardSteerMogli.registerState( self, "ksmCameraIsOn"  , false, keyboardSteerMogli.ksmOnSetCamera )
	keyboardSteerMogli.registerState( self, "ksmReverseIsOn" , false, keyboardSteerMogli.ksmOnSetReverse )
	keyboardSteerMogli.registerState( self, "ksmExponent"    , 1    , keyboardSteerMogli.ksmOnSetFactor )
	keyboardSteerMogli.registerState( self, "ksmWarningText" , ""   , keyboardSteerMogli.ksmOnSetWarningText )
	keyboardSteerMogli.registerState( self, "ksmLCtrlPressed", false )
	keyboardSteerMogli.registerState( self, "ksmLShiftPressed", false )
	keyboardSteerMogli.registerState( self, "ksmLimitThrottle", KSMGlobals.limitThrottle )
	
	self.ksmSpeedFx       = 0
	self.ksmFactor        = 1
	self.ksmSpeedFxMin    = KSMGlobals.minSpeed4Fx / ( KSMGlobals.maxSpeed4Fx - KSMGlobals.minSpeed4Fx )
	self.ksmSpeedFxFactor = 3600 / ( KSMGlobals.maxSpeed4Fx - KSMGlobals.minSpeed4Fx )
	self.ksmReverseTimer  = 1.5 / KSMGlobals.timer4Reverse
	self.ksmMovingDir     = 0
	self.ksmLastFactor    = 0
	self.ksmWarningTimer  = 0
	self.ksmLCtrlPressed  = false
	self.ksmLShiftPressed = false

	if KSMGlobals.ksmSteeringIsOn then
		self:ksmSetState( "ksmSteeringIsOn", true, true )
	end
	if KSMGlobals.enableAnalogCtrl then
		self:ksmSetState( "ksmAnalogIsOn", true, true )
	end
	
	self.ksmCameras = {}
	
	for i,c in pairs(self.cameras) do
		self:ksmIsValidCam( i, true )
	end	
end

function keyboardSteerMogli:update(dt)

	local newRotCursorKey = nil
	local i               = self.camIndex
			

	if self.isEntered and self.isClient and self:getIsActive() then
		if     InputBinding.hasEvent(InputBinding.ksmPLUS) then
			self:ksmSetState( "ksmExponent", self.ksmExponent +1 )
			self:ksmSetState( "ksmWarningText", string.format("Sensitivity %3.0f %%", 100 * self.ksmFactor, true ) )
		elseif InputBinding.hasEvent(InputBinding.ksmMINUS) then
			self:ksmSetState( "ksmExponent", self.ksmExponent -1 )
			self:ksmSetState( "ksmWarningText", string.format("Sensitivity %3.0f %%", 100 * self.ksmFactor, true ) )
		elseif InputBinding.hasEvent(InputBinding.ksmTPLUS) then		
			self:ksmSetState( "ksmLimitThrottle", math.min( self.ksmLimitThrottle +1, 20 ) )
			self:ksmSetState( "ksmWarningText", string.format("Gaspedal %3d%%/%3d%%", 45 + 5 * math.min( self.ksmLimitThrottle, 11 ), 150 - 5 * math.max( self.ksmLimitThrottle, 10 ) , true ) )
		elseif InputBinding.hasEvent(InputBinding.ksmTMINUS) then
			self:ksmSetState( "ksmLimitThrottle", math.max( self.ksmLimitThrottle -1, 1 ) )
			self:ksmSetState( "ksmWarningText", string.format("Gaspedal %3d%%/%3d%%", 45 + 5 * math.min( self.ksmLimitThrottle, 11 ), 150 - 5 * math.max( self.ksmLimitThrottle, 10 ) , true ) )
		elseif InputBinding.hasEvent(InputBinding.ksmENABLE) then		
			self:ksmSetState( "ksmSteeringIsOn", not self.ksmSteeringIsOn )
		elseif InputBinding.hasEvent(InputBinding.ksmCAMERA) then
			self:ksmSetState( "ksmCameraIsOn", not self.ksmCameraIsOn )
		elseif InputBinding.hasEvent(InputBinding.ksmREVERSE) then
			self:ksmSetState( "ksmReverseIsOn", not self.ksmReverseIsOn )
		elseif InputBinding.hasEvent(InputBinding.ksmANALOG) then
			self:ksmSetState( "ksmAnalogIsOn", not self.ksmAnalogIsOn )
		end
		
		if self:ksmIsValidCam() then
			local newRot = nil
			if     InputBinding.hasEvent(InputBinding.ksmUP)    then
				newRotCursorKey = 0
			elseif InputBinding.hasEvent(InputBinding.ksmDOWN)  then
				newRotCursorKey = math.pi
			elseif InputBinding.hasEvent(InputBinding.ksmLEFT)  then
				newRotCursorKey = 0.3*math.pi
			elseif InputBinding.hasEvent(InputBinding.ksmRIGHT) then
				newRotCursorKey = -0.3*math.pi
			end
			
			if newRotCursorKey ~= nil then
				self.cameras[i].rotY = keyboardSteerMogli.normalizeAngle( self.cameras[i].origRotY + newRotCursorKey )
			end
		end
	end

	if self:getIsActive() and self.isServer then
		local deltaFx      = math.max( self.lastSpeed * self.ksmSpeedFxFactor - self.ksmSpeedFxMin, 0 )  - self.ksmSpeedFx
		self.ksmSpeedFx    = math.min( self.ksmSpeedFx + KSMGlobals.speedFxInc * deltaFx, 1 )

		if      self.mrGbMS ~= nil
				and self.mrGbMS.IsOn then
			if self.mrGbMS.ReverseActive then
				self.ksmMovingDir = -1
			else
				self.ksmMovingDir = 1
			end
		elseif  self.dCcheckModule        ~=  nil 
				and self.driveControl         ~= nil
				and self:dCcheckModule("shuttle")
				and self.driveControl.shuttle ~= nil 
				and self.driveControl.shuttle.isActive 
				and self.driveControl.shuttle.direction ~= nil 
				and self.driveControl.shuttle.isActive then
			self.ksmMovingDir = self.driveControl.shuttle.direction * self.reverserDirection
		else
			local movingDirection = self.movingDirection * self.reverserDirection
			if math.abs( self.lastSpeed ) < 0.00054 then
				movingDirection = 0
			end
					
			local maxDelta    = dt * self.ksmReverseTimer
			self.ksmMovingDir = self.ksmMovingDir + Utils.clamp( movingDirection - self.ksmMovingDir, -maxDelta, maxDelta )
		
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
			and self.steeringEnabled 
			and self:ksmIsValidCam()
			and not ( g_settingsIsHeadTrackingEnabled 
						and isHeadTrackingAvailable() 
						and self.cameras[i].isInside 
						and self.cameras[i].headTrackingNode ~= nil ) then
			
		if     self.ksmLastCamIndex == nil 
				or self.ksmLastCamIndex ~= i then
				
			self:ksmSetState( "ksmCameraIsOn",  self.ksmCameras[i].rotation )
			self:ksmSetState( "ksmReverseIsOn", self.ksmCameras[i].rev )
			self.ksmLastCamIndex = self.camIndex
			self.ksmCameras[i].zero       = self.cameras[i].rotY
			self.ksmCameras[i].lastCamFwd = nil
			
		elseif self.ksmCameraIsOn 
				or self.ksmReverseIsOn then

			local pi2 = math.pi / 2
			local eps = 1e-6
			oldRotY = self.cameras[i].rotY
			local diff = oldRotY - self.ksmCameras[i].last
			
			if self.ksmCameraIsOn then
				if newRotCursorKey ~= nil then
					self.ksmCameras[i].zero = keyboardSteerMogli.normalizeAngle( self.cameras[i].origRotY + newRotCursorKey )
				else
					self.ksmCameras[i].zero = self.ksmCameras[i].zero + diff
				end
			else
				self.ksmCameras[i].zero = self.cameras[i].rotY
			end
				
		--diff = math.abs( keyboardSteerMogli.getAbsolutRotY( self, i ) )
			local isRev = false
			local aRotY = keyboardSteerMogli.normalizeAngle( keyboardSteerMogli.getAbsolutRotY( self, i ) - self.cameras[i].rotY + self.ksmCameras[i].zero )
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
				self.ksmLastFactor = self.ksmLastFactor + Utils.clamp( f - self.ksmLastFactor, -KSMGlobals.cameraRotTime*dt, KSMGlobals.cameraRotTime*dt )
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
				
			--if self.ksmReverseIsOn then
			--	newRotY = keyboardSteerMogli.normalizeAngle( newRotY )
			--	
			--	if isRev then
			--		newRotY = math.min( math.max( newRotY, eps-pi2 ), pi2-eps )
			--	elseif -pi2-eps < newRotY and newRotY < pi2+eps then
			--		if newRotY < 0 then
			--			newRotY = -pi2-eps
			--		else
			--			newRotY = pi2+eps
			--		end
			--	end
			--end
			else
				self.ksmLastFactor = 0
			end

			self.cameras[i].rotY = newRotY			
		end
	
		self.ksmCameras[i].last = self.cameras[i].rotY
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

function keyboardSteerMogli:readStream(streamId, connection)

  self.ksmSteeringIsOn  = streamReadBool(streamId) 
  self.ksmCameraIsOn    = streamReadBool(streamId) 
  self.ksmReverseIsOn   = streamReadBool(streamId) 
  self.ksmCamFwd        = streamReadBool(streamId) 
	self.ksmExponent      = streamReadInt16(streamId)     
	self.ksmLimitThrottle = streamReadInt16(streamId)     
	
end

function keyboardSteerMogli:writeStream(streamId, connection)

	streamWriteBool(streamId, self.ksmSteeringIsOn )
	streamWriteBool(streamId, self.ksmCameraIsOn )
	streamWriteBool(streamId, self.ksmReverseIsOn )
	streamWriteBool(streamId, self.ksmCamFwd )     
	streamWriteInt16(streamId,self.ksmExponent )     
	streamWriteInt16(streamId,self.ksmLimitThrottle )     

end

function keyboardSteerMogli:keyEvent(unicode, sym, modifier, isDown)
	if sym == Input.KEY_lctrl then
		self:ksmSetState( "ksmLCtrlPressed", isDown )
	end
	if sym == Input.KEY_lshift then
		self:ksmSetState( "ksmLShiftPressed", isDown )
	end
end

function keyboardSteerMogli:onLeave()
	self:ksmSetState( "ksmLCtrlPressed", false )
	self:ksmSetState( "ksmLShiftPressed", false )
end

function keyboardSteerMogli:draw()		
	if self.ksmLCtrlPressed then
		if self.ksmLShiftPressed then
			if self.ksmAnalogIsOn then
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmANALOG_ON"),  InputBinding.ksmANALOG)
			else
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmANALOG_OFF"), InputBinding.ksmANALOG)
			end
		else
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("input_ksmPLUS"),  InputBinding.ksmPLUS)
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("input_ksmMINUS"), InputBinding.ksmMINUS)
		end
		
	elseif KSMGlobals.ksmDrawIsOn or self.ksmLShiftPressed then
		if self.ksmSteeringIsOn then
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmENABLE_ON"),  InputBinding.ksmENABLE)
		else
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmENABLE_OFF"), InputBinding.ksmENABLE)
		end
		
		if self:ksmIsValidCam() then
			if self.ksmCameraIsOn then
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmCAMERA_ON"),  InputBinding.ksmCAMERA)
			else
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmCAMERA_OFF"), InputBinding.ksmCAMERA)
			end
			if self.ksmReverseIsOn then
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmREVERSE_ON"),  InputBinding.ksmREVERSE)
			else
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmREVERSE_OFF"), InputBinding.ksmREVERSE)
			end
		end
	end
	if self.ksmWarningText ~= "" then
		g_currentMission:addExtraPrintText( self.ksmWarningText )
	end
end  

function keyboardSteerMogli:getDefaultRotation( camIndex )
	if     self.cameras           == nil
			or self.cameras[camIndex] == nil then
		keyboardSteerMogli.debugPrint( "invalid camera" )
		return false
	elseif not ( self.cameras[camIndex].isRotatable )
			or self.cameras[camIndex].vehicle ~= self then
		keyboardSteerMogli.debugPrint( "fixed camera" )
		return false
	elseif  KSMGlobals.ksmCamInsideIsOn 
			and self.cameras[camIndex].isInside then
		keyboardSteerMogli.debugPrint( "camera is inside" )
		return true
	end
	keyboardSteerMogli.debugPrint( "other camera: "..tostring(KSMGlobals.ksmCameraIsOn) )
	return KSMGlobals.ksmCameraIsOn
end

function keyboardSteerMogli:getDefaultReverse( camIndex )
	if     self.cameras           == nil
			or self.cameras[camIndex] == nil then
		return false
	elseif not ( self.cameras[camIndex].isRotatable )
			or self.cameras[camIndex].vehicle ~= self then
		return false
	elseif  self.cameras[camIndex].isInside
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

function keyboardSteerMogli:getSaveAttributesAndNodes(nodeIdent)
	local attributes = ""
	if self.ksmSteeringIsOn ~= nil and self.ksmSteeringIsOn ~= KSMGlobals.ksmSteeringIsOn then
		attributes = attributes.." ksmSteeringIsOn=\""  .. tostring(self.ksmSteeringIsOn) .. "\""
	end
	if self.ksmAnalogIsOn ~= nil and self.ksmAnalogIsOn ~= KSMGlobals.enableAnalogCtrl then
		attributes = attributes.." ksmAnalogIsOn=\""  .. tostring(self.ksmAnalogIsOn) .. "\""
	end
	
	for i,b in pairs(self.ksmCameras) do
		if b.rotation ~= keyboardSteerMogli.getDefaultRotation( self, i ) then
			attributes = attributes.." ksmCameraIsOn_"..tostring(i).."=\""  .. tostring(b.rotation) .. "\""
		end
		if b.rev ~= keyboardSteerMogli.getDefaultReverse( self, i ) then
			attributes = attributes.." ksmReverseIsOn_"..tostring(i).."=\""  .. tostring(b.rev) .. "\""
		end
	end
	if self.ksmExponent ~= nil and math.abs( self.ksmExponent - 1 ) > 1E-3 then
		attributes = attributes.." ksmExponent=\""  .. tostring(self.ksmExponent) .. "\""
	end
	if self.ksmLimitThrottle ~= nil and math.abs( self.ksmLimitThrottle - 15 ) > 1E-3 then
		attributes = attributes.." ksmLimitThrottle=\""  .. tostring(self.ksmLimitThrottle) .. "\""
	end

	return attributes
end;

function keyboardSteerMogli:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)

	local b = getXMLBool(xmlFile, key .. "#ksmSteeringIsOn" )
	if b ~= nil then
		self:ksmSetState( "ksmSteeringIsOn", b,  true ) 
	end
	b = getXMLBool(xmlFile, key .. "#ksmAnalogIsOn" )
	if b ~= nil then
		self.ksmAnalogIsOn = b
	end
	
	if self.ksmCameras == nil then
		self.ksmCameras = {}
	end
	
	for i,c in pairs(self.cameras) do
		if self:ksmIsValidCam( i, true ) then
			b = getXMLBool(xmlFile, key .. "#ksmCameraIsOn_"..tostring(i) )
			if b ~= nil then
				self.ksmCameras[i].rotation = b
			end
			b = getXMLBool(xmlFile, key .. "#ksmReverseIsOn_"..tostring(i) )
			if b ~= nil then
				self.ksmCameras[i].rev      = b
			end
		end
	end
	
	local i = getXMLInt(xmlFile, key .. "#ksmExponent" )
	if i ~= nil then
		self:ksmSetState( "ksmExponent", i,  true ) 
	end
	
	local i = getXMLInt(xmlFile, key .. "#ksmLimitThrottle" )
	if i ~= nil then
		self:ksmSetState( "ksmLimitThrottle", i,  true ) 
	end
	
	return BaseMission.VEHICLE_LOAD_OK;
end

function keyboardSteerMogli:scaleFx( fx, mi, ma )
	return Utils.clamp( 1 + self.ksmFactor * ( fx - 1 ), mi, ma )
end

function keyboardSteerMogli:newUpdateVehiclePhysics( superFunc, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt, ... )
	local backup1 = self.autoRotateBackSpeed
	local backup2 = self.minRotTime
	local backup3 = self.maxRotTime
	if self.ksmSteeringIsOn and ( self.ksmAnalogIsOn or not ( axisSideIsAnalog ) ) then
		local arbs = backup1
		
		if self.lastSpeed < 0.000278 then
			self.autoRotateBackSpeed = 0
		elseif self.rotatedTime >= 0 then
			self.autoRotateBackSpeed = ( 0.2 + 0.8 * self.rotatedTime / self.maxRotTime ) * self:ksmScaleFx( KSMGlobals.autoRotateBackFx:get( self.ksmSpeedFx ), 0.1, 3 ) * arbs
		else                                                      
			self.autoRotateBackSpeed = ( 0.2 + 0.8 * self.rotatedTime / self.minRotTime ) * self:ksmScaleFx( KSMGlobals.autoRotateBackFx:get( self.ksmSpeedFx ), 0.1, 3 ) * arbs
		end
		
		local f = self:ksmScaleFx( KSMGlobals.maxRotTimeFx:get( self.ksmSpeedFx ), 0, 1 )
		
		self.minRotTime = f * backup2
		self.maxRotTime = f * backup3
		
		local w = 1000 * KSMGlobals.waitTimeFx:get( self.ksmSpeedFx )
		if axisSideIsAnalog or w <= 0 or axisSide * self.rotatedTime > 0 then
			self.ksmAxisSideTimer1 = nil
			self.ksmAxisSideTimer2 = nil
		else		
			local t									
			if math.abs( axisSide ) < 0.001 then
				t = self.ksmAxisSideTimer2
			else
				t = self.ksmAxisSideTimer1
			end
			
			if t == nil then
				t = g_currentMission.time - dt
			end
			
			local f = 1
			if g_currentMission.time < t + w then
				f = ( g_currentMission.time - t ) / w
			end
			
			if math.abs( axisSide ) < 0.001 then
				self.ksmAxisSideTimer1 = nil
				self.ksmAxisSideTimer2 = t				
				if f < 1 and KSMGlobals.autoRotateBackWait > 0 then
					self.autoRotateBackSpeed = self.autoRotateBackSpeed * ( 1 - KSMGlobals.autoRotateBackWait + f * KSMGlobals.autoRotateBackWait )
				end
			else
				self.ksmAxisSideTimer1 = t
				self.ksmAxisSideTimer2 = nil
				if f < 1 and KSMGlobals.axisSideWait > 0 then
					axisSide = axisSide  * ( 1 - KSMGlobals.axisSideWait + f * KSMGlobals.axisSideWait )
				end
			end
		end
		
		axisSide = self:ksmScaleFx( KSMGlobals.axisSideFx:get( self.ksmSpeedFx ), 0.1, 3 ) * axisSide
		if axisSide > 0 and self.rotatedTime > 0 then
			axisSide = math.max( axisSide, self.autoRotateBackSpeed )
		end
		if axisSide < 0 and self.rotatedTime < 0 then
			axisSide = math.min( axisSide, -self.autoRotateBackSpeed )
		end
	end
	
	local limitThrottleRatio     = 0.75
	local limitThrottleIfPressed = true
	if self.ksmLimitThrottle < 11 then
		limitThrottleIfPressed = false
		limitThrottleRatio     = 0.45 + 0.05 * self.ksmLimitThrottle
	else
		limitThrottleIfPressed = true
		limitThrottleRatio     = 1.5 - 0.05 * self.ksmLimitThrottle
	end
	
	if      self.ksmSteeringIsOn 
			and ( self.ksmLShiftPressed == limitThrottleIfPressed )
			and ( self.ksmAnalogIsOn or not ( axisForwardIsAnalog ) ) then
		axisForward = Utils.clamp( axisForward, -limitThrottleRatio, limitThrottleRatio )
		axisForwardIsAnalog = true
	end
	
	local state, result = pcall( superFunc, self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, doHandbrake, dt, ... )
	if not ( state ) then
		print("Error in updateVehiclePhysics :"..tostring(result))
	end

	self.autoRotateBackSpeed = backup1
	self.minRotTime          = backup2
	self.maxRotTime          = backup3
end

function keyboardSteerMogli:ksmOnSetCamera( old, new, noEventSend ) 
	self.ksmCameraIsOn = new
	if self:ksmIsValidCam() then
		self.ksmCameras[self.camIndex].rotation = new
		if new and not ( old ) then
			self.ksmCameras[self.camIndex].zero = self.cameras[self.camIndex].origRotY
			self.ksmCameras[self.camIndex].last = self.cameras[self.camIndex].rotY
			self.ksmCameras[self.camIndex].lastCamFwd = nil
		end
	end
end

function keyboardSteerMogli:ksmOnSetReverse( old, new, noEventSend ) 
	self.ksmReverseIsOn = new
	if self:ksmIsValidCam() then
		self.ksmCameras[self.camIndex].rev = new
		self.ksmCameras[self.camIndex].lastCamFwd = nil
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

function keyboardSteerMogli:getAbsolutRotY( camIndex )
	if     self.cameras == nil
			or self.cameras[camIndex] == nil then
		return 0
	end
  return keyboardSteerMogli.getRelativeYRotation( self.cameras[camIndex].cameraNode, self.steeringCenterNode )
end

function keyboardSteerMogli.getRelativeYRotation(root,node)
	if root == nil or node == nil then
		return 0
	end
	local x, y, z = worldDirectionToLocal(node, localDirectionToWorld(root, 0, 0, 1))
	local dot = z
	dot = dot / Utils.vector2Length(x, z)
	local angle = math.acos(dot)
	if x < 0 then
		angle = -angle
	end
	return angle
end


Drivable.updateVehiclePhysics = Utils.overwrittenFunction( Drivable.updateVehiclePhysics, keyboardSteerMogli.newUpdateVehiclePhysics )

