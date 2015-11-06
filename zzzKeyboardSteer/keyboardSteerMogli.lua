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
	KSMGlobals.cameraRotTime       = 0 --deprecated
	KSMGlobals.cameraRotTimeMax    = 0
	KSMGlobals.cameraRotTimeInc    = 0
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
  KSMGlobals.maxSpeed4Fx	       = 0
  KSMGlobals.timer4Reverse       = 0
  KSMGlobals.minSpeed4Fx	       = 0
  KSMGlobals.speedFxInc          = 0
  KSMGlobals.axisForwardSmooth   = 0
	KSMGlobals.enableAnalogCtrl    = false
	
-- defaults	
  KSMGlobals.ksmSteeringIsOn  = false
  KSMGlobals.ksmCameraIsOn    = false
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
	
-- compatibility	
	if KSMGlobals.cameraRotTimeMax == 0 and KSMGlobals.cameraRotTime > 0 then
		KSMGlobals.cameraRotTimeMax = KSMGlobals.cameraRotTime * 33
	end
	
	KSMGlobals.autoRotateBackFx = AnimCurve:new(linearInterpolator1)
	KSMGlobals.axisSideFx       = AnimCurve:new(linearInterpolator1)
	KSMGlobals.maxRotTimeFx     = AnimCurve:new(linearInterpolator1)
	
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
		
	print("keyboardSteerMogli initialized");
end

keyboardSteerMogli.globalsReset(false)

function keyboardSteerMogli:isValidCam( index, createIfMissing )
	local i = Utils.getNoNil( index, self.camIndex )
	
	if      self.cameras ~= nil 
			and i ~= nil 
			and self.cameras[i] ~= nil 
			and self.cameras[i].vehicle == self
			and self.cameras[i].isRotatable then
		if self.ksmCameras[i] == nil then
			if createIfMissing then
				self.ksmCameras[i] = { rotation = KSMGlobals.ksmCameraIsOn,
															 rev      = KSMGlobals.ksmReverseIsOn,
															 zero     = self.cameras[i].rotY,
															 last     = self.cameras[i].rotY,
															 smooth   = self.cameras[i].rotY }
			else
				return false
			end
		end
		return true
	end
	
	return false
end

function keyboardSteerMogli:load(xmlFile)
	self.ksmScaleFx       = keyboardSteerMogli.scaleFx
	self.ksmSetState      = keyboardSteerMogli.mbSetState

	keyboardSteerMogli.registerState( self, "ksmSteeringIsOn", false )
	keyboardSteerMogli.registerState( self, "ksmAnalogIsOn",   false )
	keyboardSteerMogli.registerState( self, "ksmLastCamIndex", 0,     keyboardSteerMogli.ksmOnSetCamIndex )
	keyboardSteerMogli.registerState( self, "ksmCameraIsOn"  , false, keyboardSteerMogli.ksmOnSetCamera )
	keyboardSteerMogli.registerState( self, "ksmReverseIsOn" , false, keyboardSteerMogli.ksmOnSetReverse )
	keyboardSteerMogli.registerState( self, "ksmCamFwd"      , true , keyboardSteerMogli.ksmOnSetCamFwd )
	keyboardSteerMogli.registerState( self, "ksmExponent"    , 1    , keyboardSteerMogli.ksmOnSetFactor )
	keyboardSteerMogli.registerState( self, "ksmWarningText" , ""   , keyboardSteerMogli.ksmOnSetWarningText )
	keyboardSteerMogli.registerState( self, "ksmMirror"      , true , keyboardSteerMogli.ksmOnSetMirror )
	keyboardSteerMogli.registerState( self, "ksmLCtrlPressed", false )
	keyboardSteerMogli.registerState( self, "ksmLShiftPressed", false )
	
	self.ksmSpeedFx       = 0
	self.ksmFactor        = 1
	self.ksmSpeedFxMin    = KSMGlobals.minSpeed4Fx / ( KSMGlobals.maxSpeed4Fx - KSMGlobals.minSpeed4Fx )
	self.ksmSpeedFxFactor = 3600 / ( KSMGlobals.maxSpeed4Fx - KSMGlobals.minSpeed4Fx )
	self.reverseTimer     = 1.5 / KSMGlobals.timer4Reverse
	self.ksmMovingDir     = 0
	self.ksmWandtedMovingDir = 0
	self.ksmWarningTimer  = 0
	self.ksmLCtrlPressed  = false
	self.ksmLShiftPressed = false
	self.ksmLastAxisFwd   = 0
	self.ksmDirChangeTimer= 0
	self.ksmChangeDir     = false
	self.ksmAddMirror     = true
--if g_settingsRearMirrors and g_rearMirrorsAvailable then
--	self.ksmAddMirror   = false
--else
		self.mirrorAvailable = self.ksmMirror
--end
	
--self:ksmSetState( "ksmSteeringIsOn", KSMGlobals.ksmSteeringIsOn,true )
	if KSMGlobals.ksmSteeringIsOn then
		self:ksmSetState( "ksmSteeringIsOn", true, true )
	end
	if KSMGlobals.enableAnalogCtrl then
		self:ksmSetState( "ksmAnalogIsOn", true, true )
	end
	
	self.ksmCameras       = {}
	
	for i,c in pairs(self.cameras) do
		if keyboardSteerMogli.isValidCam( self, i, true ) then
			if c.isInside and SpecializationUtil.hasSpecialization(Combine, self.specializations) then
				self.ksmCameras[i].rev = false
			end
		end
	end
	
	self.ksmCameraDefaultOn  = KSMGlobals.ksmCameraIsOn
	self.ksmReverseDefaultOn = KSMGlobals.ksmReverseIsOn
end

function keyboardSteerMogli:update(dt)

	local lastCamIndex = self.ksmLastCamIndex
	if      self:getIsActive() 
			and self.cameras ~= nil 
			and self.camIndex ~= nil then
		self:ksmSetState( "ksmLastCamIndex", self.camIndex )
	end

	if self.isEntered and self.isClient and self:getIsActive() then
		if     InputBinding.hasEvent(InputBinding.ksmPLUS) then
			self:ksmSetState( "ksmExponent", self.ksmExponent +1 )
			self:ksmSetState( "ksmWarningText", string.format("Sensitivity %3.0f %%", 100 * self.ksmFactor, true ) )
		elseif InputBinding.hasEvent(InputBinding.ksmMINUS) then
			self:ksmSetState( "ksmExponent", self.ksmExponent -1 )
			self:ksmSetState( "ksmWarningText", string.format("Sensitivity %3.0f %%", 100 * self.ksmFactor, true ) )
		elseif self.ksmAddMirror and InputBinding.hasEvent(InputBinding.ksmMIRROR) then		
			self:ksmSetState( "ksmMirror", not self.ksmMirror )
		elseif InputBinding.hasEvent(InputBinding.ksmENABLE) then		
			self:ksmSetState( "ksmSteeringIsOn", not self.ksmSteeringIsOn )
		elseif InputBinding.hasEvent(InputBinding.ksmCAMERA) then
			self:ksmSetState( "ksmCameraIsOn", not self.ksmCameraIsOn )
		elseif InputBinding.hasEvent(InputBinding.ksmREVERSE) then
			self:ksmSetState( "ksmReverseIsOn", not self.ksmReverseIsOn )
		elseif InputBinding.hasEvent(InputBinding.ksmANALOG) then
			self:ksmSetState( "ksmAnalogIsOn", not self.ksmAnalogIsOn )
		end
		
		local newRot = nil
		if     InputBinding.hasEvent(InputBinding.ksmUP)    then
			newRot = 0
		elseif InputBinding.hasEvent(InputBinding.ksmDOWN)  then
			newRot = math.pi
		elseif InputBinding.hasEvent(InputBinding.ksmLEFT)  then
			newRot = 0.3*math.pi
		elseif InputBinding.hasEvent(InputBinding.ksmRIGHT) then
			newRot = -0.3*math.pi
		end
		
		if      newRot ~= nil 
				and keyboardSteerMogli.isValidCam( self ) then
			local diff = self.cameras[self.camIndex].rotY - self.ksmCameras[self.camIndex].last
			self.cameras[self.camIndex].rotY = keyboardSteerMogli.normalizeAngle( self.cameras[self.camIndex].origRotY + newRot )
			if self.ksmCameraIsOn then
				self.ksmCameras[self.camIndex].zero = self.cameras[self.camIndex].rotY
				if newRot > 0.55 * math.pi then
					self.cameras[self.camIndex].rotY = self.cameras[self.camIndex].rotY - self:ksmScaleFx( KSMGlobals.cameraRotFactor, 0.1, 3 ) * self.rotatedTime			
				else
					self.cameras[self.camIndex].rotY = self.cameras[self.camIndex].rotY + self:ksmScaleFx( KSMGlobals.cameraRotFactor, 0.1, 3 ) * self.rotatedTime			
				end
				self.ksmCameras[self.camIndex].last   = self.cameras[self.camIndex].rotY
				self.ksmCameras[self.camIndex].smooth = self.cameras[self.camIndex].rotY
			end
		end
	end

	if self:getIsActive() and self.isServer then
		local deltaFx      = math.max( self.lastSpeed * self.ksmSpeedFxFactor - self.ksmSpeedFxMin, 0 )  - self.ksmSpeedFx
		self.ksmSpeedFx    = math.min( self.ksmSpeedFx + KSMGlobals.speedFxInc * deltaFx, 1 )
		
		self.ksmChangeDir = false
		if      self.mrGbMS ~= nil
				and self.mrGbMS.IsOn then
			local rev = self.mrGbMS.ReverseActive
			if self.isReverseDriving then rev = not ( rev ) end
				
			self:ksmSetState( "ksmCamFwd", not ( rev ) )
			if     rev then 
				self.ksmMovingDir = -1
			elseif self.mrGbMS.NeutralActive then
				self.ksmMovingDir = 0 
			else 
				self.ksmMovingDir = 1
			end
			self.ksmShuttleControl = true
		elseif  self.mrGbMIsOn then
			local rev = self.mrGbMReverseActive
			if self.isReverseDriving then rev = not ( rev ) end

			self:ksmSetState( "ksmCamFwd", not ( rev ) )
			if     rev then 
				self.ksmMovingDir = -1
			elseif self.mrGbMNeutralActive then
				self.ksmMovingDir = 0 
			else 
				self.ksmMovingDir = 1
			end
			self.ksmShuttleControl = true
		elseif  g_currentMission.driveControl ~= nil
				and g_currentMission.driveControl.useModules ~= nil
				and g_currentMission.driveControl.useModules.shuttle 
				and self.driveControl ~= nil 
				and self.driveControl.shuttle ~= nil 
				and self.driveControl.shuttle.direction ~= nil 
				and self.driveControl.shuttle.isActive then
			if self.driveControl.shuttle.direction < 0 then
				self:ksmSetState( "ksmCamFwd", false )
			else
				self:ksmSetState( "ksmCamFwd", true )
			end
			self.ksmMovingDir = self.driveControl.shuttle.direction
		else
			self.ksmChangeDir = true
			local movingDirection = self.movingDirection
			if math.abs( self.lastSpeed ) < 0.00054 then
				movingDirection = 0
			end
				
			local maxDelta    = dt * self.reverseTimer
			self.ksmMovingDir = self.ksmMovingDir + Utils.clamp( movingDirection - self.ksmMovingDir, -maxDelta, maxDelta )
			
			if math.abs( self.ksmMovingDir ) >  0.5 then
				local newCamFwd = ( self.ksmMovingDir >= 0 )
				if self.ksmCamFwd ~= newCamFwd then
					self:ksmSetState( "ksmCamFwd", newCamFwd )
				end
			end
		end
	end
	
	if      self:getIsActive() 
			and self.steeringEnabled
			and self.ksmCameraIsOn 
			and keyboardSteerMogli.isValidCam( self ) then
		
		local diff = self.cameras[self.camIndex].rotY - self.ksmCameras[self.camIndex].last
		self.ksmCameras[self.camIndex].zero   = self.ksmCameras[self.camIndex].zero   + diff
		self.ksmCameras[self.camIndex].smooth = self.ksmCameras[self.camIndex].smooth + diff
			
		local newRotY = self.ksmCameras[self.camIndex].zero
		local diff = math.abs( keyboardSteerMogli.normalizeAngle( self.cameras[self.camIndex].rotY - self.cameras[self.camIndex].origRotY ) )
		if     self.isReverseDriving and diff > 0.55* math.pi
				or ( not ( self.isReverseDriving ) and diff <= 0.55* math.pi ) then
			newRotY = newRotY + self:ksmScaleFx( KSMGlobals.cameraRotFactor, 0.1, 3 ) * self.rotatedTime			
		else
			newRotY = newRotY - self:ksmScaleFx( KSMGlobals.cameraRotFactorRev, 0.1, 3 ) * self.rotatedTime
		end		
	
		if lastCamIndex ~= nil and lastCamIndex == self.ksmLastCamIndex then
			diff = newRotY - self.ksmCameras[self.camIndex].smooth
		--diff = Utils.clamp( diff, -KSMGlobals.cameraRotTime*dt, KSMGlobals.cameraRotTime*dt )

			self.ksmCameras[self.camIndex].smooth = self.ksmCameras[self.camIndex].smooth + KSMGlobals.cameraRotTimeInc * diff
			
			diff = self.ksmCameras[self.camIndex].smooth - self.cameras[self.camIndex].rotY
			diff = Utils.clamp( diff, -KSMGlobals.cameraRotTimeMax*dt, KSMGlobals.cameraRotTimeMax*dt )
			
			self.cameras[self.camIndex].rotY = self.cameras[self.camIndex].rotY + diff
		else
			self.cameras[self.camIndex].rotY      = newRotY
			self.ksmCameras[self.camIndex].smooth = newRotY
		end
		
		self.ksmCameras[self.camIndex].last = self.cameras[self.camIndex].rotY
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

  self.ksmSteeringIsOn = streamReadBool(streamId) 
  self.ksmCameraIsOn   = streamReadBool(streamId) 
  self.ksmReverseIsOn  = streamReadBool(streamId) 
  self.ksmCamFwd       = streamReadBool(streamId) 
	self.ksmExponent     = streamReadInt16(streamId)     
	
end

function keyboardSteerMogli:writeStream(streamId, connection)

	streamWriteBool(streamId, self.ksmSteeringIsOn )
	streamWriteBool(streamId, self.ksmCameraIsOn )
	streamWriteBool(streamId, self.ksmReverseIsOn )
	streamWriteBool(streamId, self.ksmCamFwd )     
	streamWriteInt16(streamId,self.ksmExponent )     

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
		g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmPLUS"),  InputBinding.ksmPLUS)
		g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmMINUS"), InputBinding.ksmMINUS)
		
		if self.ksmAddMirror then
			if self.ksmMirror then
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmMIRROR_ON"),  InputBinding.ksmMIRROR)
			else
				g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmMIRROR_OFF"), InputBinding.ksmMIRROR)
			end
		end
	elseif KSMGlobals.ksmDrawIsOn or self.ksmLShiftPressed then
		if self.ksmSteeringIsOn then
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmENABLE_ON"),  InputBinding.ksmENABLE)
		else
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmENABLE_OFF"), InputBinding.ksmENABLE)
		end
		if self.ksmAnalogIsOn then
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmANALOG_ON"),  InputBinding.ksmANALOG)
		else
			g_currentMission:addHelpButtonText(keyboardSteerMogli.getText("ksmANALOG_OFF"), InputBinding.ksmANALOG)
		end
		
		if keyboardSteerMogli.isValidCam( self ) then
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
       
function keyboardSteerMogli:getSaveAttributesAndNodes(nodeIdent)
	local attributes = ""
	if self.ksmSteeringIsOn ~= nil and self.ksmSteeringIsOn ~= KSMGlobals.ksmSteeringIsOn then
		attributes = attributes.." ksmSteeringIsOn=\""  .. tostring(self.ksmSteeringIsOn) .. "\""
	end
	if self.ksmCameraDefaultOn ~= nil and self.ksmCameraDefaultOn ~= KSMGlobals.ksmCameraIsOn then
		attributes = attributes.." ksmCameraIsOn=\""  .. tostring(self.ksmCameraDefaultOn) .. "\""
	end
	if self.ksmAnalogIsOn ~= nil and self.ksmAnalogIsOn ~= KSMGlobals.enableAnalogCtrl then
		attributes = attributes.." ksmAnalogIsOn=\""  .. tostring(self.ksmAnalogIsOn) .. "\""
	end
	if self.ksmMirror ~= nil and self.ksmMirror ~= true then
		attributes = attributes.." ksmMirror=\""  .. tostring(self.ksmMirror) .. "\""
	end
	
	for i,b in pairs(self.ksmCameras) do
		if b.rotation ~= self.ksmCameraDefaultOn then
			attributes = attributes.." ksmCameraIsOn_"..tostring(i).."=\""  .. tostring(b.rotation) .. "\""
		end
		if b.rev ~= self.ksmReverseDefaultOn then
			attributes = attributes.." ksmReverseIsOn_"..tostring(i).."=\""  .. tostring(b.rev) .. "\""
		end
	end
	if self.ksmExponent ~= nil and math.abs( self.ksmExponent - 1 ) > 1E-3 then
		attributes = attributes.." ksmExponent=\""  .. tostring(self.ksmExponent) .. "\""
	end

	return attributes
end;

function keyboardSteerMogli:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	local b = getXMLBool(xmlFile, key .. "#ksmSteeringIsOn" )
	if b ~= nil then
		self:ksmSetState( "ksmSteeringIsOn", b,  true ) 
	end
	b = getXMLBool(xmlFile, key .. "#ksmCameraIsOn" )
	if b ~= nil then
		self.ksmCameraDefaultOn = b
	end
	b = getXMLBool(xmlFile, key .. "#ksmAnalogIsOn" )
	if b ~= nil then
		self.ksmAnalogIsOn = b
	end
	b = getXMLBool(xmlFile, key .. "#ksmMirror" )
	if b ~= nil then
		self:ksmSetState( "ksmMirror", b, true )
	end
	
	if self.ksmCameras == nil then
		self.ksmCameras = {}
	end
	
	for i,c in pairs(self.cameras) do
		if keyboardSteerMogli.isValidCam( self, i, true ) then
			local b1 = Utils.getNoNil( getXMLBool(xmlFile, key .. "#ksmCameraIsOn_"..tostring(i) ), self.ksmCameraDefaultOn )
			local b2 = Utils.getNoNil( getXMLBool(xmlFile, key .. "#ksmReverseIsOn_"..tostring(i) ), self.ksmReverseDefaultOn )			
			self.ksmCameras[i].rotation = b1
			self.ksmCameras[i].rev      = b2
		end
	end
	
	local i = getXMLInt(xmlFile, key .. "#ksmExponent" )
	if i ~= nil then
		self:ksmSetState( "ksmExponent", i,  true ) 
	end
	return BaseMission.VEHICLE_LOAD_OK;
end

function keyboardSteerMogli:scaleFx( fx, mi, ma )
	return Utils.clamp( 1 + self.ksmFactor * ( fx - 1 ), mi, ma )
end

function keyboardSteerMogli:newUpdateVehiclePhysics( superFunc, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, dt)
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
		
		axisSide = self:ksmScaleFx( KSMGlobals.axisSideFx:get( self.ksmSpeedFx ), 0.1, 3 ) * axisSide
		if axisSide > 0 and self.rotatedTime > 0 then
			axisSide = math.max( axisSide, self.autoRotateBackSpeed )
		end
		if axisSide < 0 and self.rotatedTime < 0 then
			axisSide = math.min( axisSide, -self.autoRotateBackSpeed )
		end
	end
	
	if      self.ksmSteeringIsOn 
			and ( self.ksmAnalogIsOn or not ( axisForwardIsAnalog ) )
			and ( self.mrGbMS == nil or not ( self.mrGbMS.IsOn ) ) then
		local limit = true
		if self.ksmWandtedMovingDir == 0 then
			if self.ksmChangeDir then
				if axisForward > 0 then
					self.ksmWandtedMovingDir = -1
				else
					self.ksmWandtedMovingDir = 1
				end
				self.ksmMovingDir = self.ksmWandtedMovingDir
			else
				self.ksmWandtedMovingDir = self.ksmMovingDir
			end
		elseif self.ksmWandtedMovingDir * axisForward > 0 then
			if math.abs( self.lastSpeed ) >= 0.00027 then
				self.ksmDirChangeTimer = 500
			else
				axisForward = 0
				limit       = false
				if self.ksmDirChangeTimer > 0 then
					self.ksmDirChangeTimer = self.ksmDirChangeTimer -dt
				else
					self.ksmWandtedMovingDir = 0
				end
			end
		end
		
		if self.ksmLShiftPressed and axisForwardIsAnalog then
			axisForward = 0.75 * axisForward
		end
			
		if limit then
			if self.ksmWandtedMovingDir * axisForward < 0 then
				axisForward = math.max( axisForward, self.ksmLastAxisFwd - self.ksmWandtedMovingDir * KSMGlobals.axisForwardSmooth * dt )
			end
		end
		
		self.ksmLastAxisFwd = axisForward
		axisForwardIsAnalog = true
	elseif  self.ksmSteeringIsOn 
			and not ( axisForwardIsAnalog )
			and self.ksmLShiftPressed 
			and self.mrGbMS ~= nil 
			and self.mrGbMS.IsOn then
		axisForward = 0.75 * axisForward
		axisForwardIsAnalog = true
	end
	
	local state, result = pcall( superFunc, self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, dt )
	if not ( state ) then
		print("Error in updateVehiclePhysics :"..tostring(result))
	end

	self.autoRotateBackSpeed = backup1
	self.minRotTime          = backup2
	self.maxRotTime          = backup3
end

function keyboardSteerMogli:ksmOnSetCamera( old, new, noEventSend ) 
	self.ksmCameraIsOn = new
	if      self.ksmLastCamIndex ~= nil
			and keyboardSteerMogli.isValidCam( self, self.ksmLastCamIndex ) then
		self.ksmCameras[self.ksmLastCamIndex].rotation = new
	end
	for i,c in pairs(self.cameras) do
		if keyboardSteerMogli.isValidCam( self, i ) then
			self.ksmCameras[i].zero = c.rotY
			self.ksmCameras[i].last = c.rotY
			self.ksmCameras[i].smooth = c.rotY
		end
	end
end

function keyboardSteerMogli:ksmOnSetReverse( old, new, noEventSend ) 
	self.ksmReverseIsOn = new
	if      self.ksmLastCamIndex ~= nil
			and keyboardSteerMogli.isValidCam( self, self.ksmLastCamIndex ) then
		self.ksmCameras[self.ksmLastCamIndex].rev = new
	end
end

function keyboardSteerMogli:ksmOnSetCamFwd( old, new, noEventSend ) 
	self.ksmCamFwd = new
	if new ~= old then
		keyboardSteerMogli.ksmSetCameraFwd( self, new )
	end
end

function keyboardSteerMogli:ksmSetCameraFwd( camFwd ) 
	if      self.steeringEnabled
			and camFwd                             ~= nil
			and self.ksmLastCamIndex               ~= nil 
			and keyboardSteerMogli.isValidCam( self, self.ksmLastCamIndex ) then
		local pi2 = math.pi / 2
		local i   = self.ksmLastCamIndex
		local rev = self.ksmReverseDefaultOn 
		if self.ksmCameras[i] ~= nil then
			rev = self.ksmCameras[i].rev
		end
		if self.cameras[i].isRotatable and rev then
			local diff = math.abs( keyboardSteerMogli.normalizeAngle( self.cameras[i].rotY - self.cameras[i].origRotY ) )
			if camFwd then
				if diff > pi2 then
					self.cameras[i].rotY = keyboardSteerMogli.normalizeAngle( self.cameras[i].rotY + math.pi )
				end
			else
				if diff < pi2 then
					self.cameras[i].rotY = keyboardSteerMogli.normalizeAngle( self.cameras[i].rotY + math.pi )
				end
			end
		end
	end
end

function keyboardSteerMogli:ksmOnSetMirror( old, new, noEventSend )
	self.ksmMirror = new
	
	if self.ksmAddMirror then
		self.mirrorAvailable = new
		if self.cameras[self.camIndex].useMirror then
			self.setMirrorVisible(self, new)
		end
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

function keyboardSteerMogli:ksmOnSetCamIndex( old, new, noEventSend )
	self.ksmLastCamIndex = new
	if      self.cameras ~= nil 
			and new ~= nil 
			and keyboardSteerMogli.isValidCam( self, new, true ) then
		keyboardSteerMogli.ksmSetCameraFwd( self, self.ksmCamFwd )
		if self.ksmCameras[new].rotation ~= self.ksmCameraIsOn then
			self:ksmSetState( "ksmCameraIsOn", self.ksmCameras[new].rotation, true )
		end
		if self.ksmCameras[new].rev ~= self.ksmReverseIsOn then
			self:ksmSetState( "ksmReverseIsOn", self.ksmCameras[new].rev, true )
		end
	end
end


Drivable.updateVehiclePhysics = Utils.overwrittenFunction( Drivable.updateVehiclePhysics, keyboardSteerMogli.newUpdateVehiclePhysics )

