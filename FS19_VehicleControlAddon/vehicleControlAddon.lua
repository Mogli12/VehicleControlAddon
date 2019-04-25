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
	for _,n in pairs( { "onLoad", 
											"onPostLoad", 
											"onPreUpdate", 
											"onUpdate", 
											"onDraw",
											"onLeaveVehicle",
											"onReadStream", 
											"onWriteStream", 
											"onReadUpdateStream", 
											"onWriteUpdateStream", 
											"saveToXMLFile", 
											"onRegisterActionEvents", 
											"onStartReverseDirectionChange" } ) do
		SpecializationUtil.registerEventListener(vehicleType, n, vehicleControlAddon)
	end 
end 

local listOfProperties =
	{ { getFunc=getXMLBool , setFunc=setXMLBool , xmlName="steering",      propName="vcaSteeringIsOn"  },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="shuttle",       propName="vcaShuttleCtrl"   },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="peek",          propName="vcaPeekLeftRight" },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="limitSpeed",    propName="vcaLimitSpeed"    },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="keepSpeed",     propName="vcaKSToggle"      },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="camRotInside",  propName="vcaCamRotInside"  },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="camRotOutside", propName="vcaCamRotOutside" },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="camRevInside",  propName="vcaCamRevInside"  },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="camRevOutside", propName="vcaCamRevOutside" },
		{ getFunc=getXMLInt  , setFunc=setXMLInt  , xmlName="exponent",      propName="vcaExponent"      },
		{ getFunc=getXMLInt  , setFunc=setXMLInt  , xmlName="throttle",      propName="vcaLimitThrottle" },
		{ getFunc=getXMLInt  , setFunc=setXMLInt  , xmlName="snapAngle",     propName="vcaSnapAngle"     },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="snapDist",      propName="vcaSnapDistance"  },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="drawHud",       propName="vcaDrawHud"       }, 
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="brakeForce",    propName="vcaBrakeForce"    },
		{ getFunc=getXMLInt  , setFunc=setXMLInt  , xmlName="transmission",  propName="vcaTransmission"  },
		{ getFunc=getXMLInt  , setFunc=setXMLInt  , xmlName="launchGear",    propName="vcaLaunchGear"    },
		{ getFunc=getXMLInt  , setFunc=setXMLInt  , xmlName="currentGear",   propName="vcaGear",         },
		{ getFunc=getXMLInt  , setFunc=setXMLInt  , xmlName="currentRange",  propName="vcaRange",        },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="autoShift",     propName="vcaAutoShift"     },
		{ getFunc=getXMLBool , setFunc=setXMLBool , xmlName="autoClutch",    propName="vcaAutoClutch"    },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="maxSpeed",      propName="vcaMaxSpeed"      },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="ccSpeed2",      propName="vcaCCSpeed2"      },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="ccSpeed3",      propName="vcaCCSpeed3"      },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="snapDir",       propName="vcaLastSnapAngle" },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="snapPosX",      propName="vcaLastSnapPosX"  },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="snapPosZ",      propName="vcaLastSnapPosZ"  },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="handthrottle",  propName="vcaHandthrottle"  },
		{ getFunc=getXMLFloat, setFunc=setXMLFloat, xmlName="pitchFactor",   propName="vcaPitchFactor"   } }


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
	
	file = getUserProfileAppPath().. "modsSettings/FS19_VehicleControlAddon/config.xml"
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

function vehicleControlAddon:mpDebugPrint( ... )
	if VCAGlobals.debugPrint or self == nil or not ( self.isClient ) then 
		print( ... )
	end 
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

function vehicleControlAddon:vcaIsNonDefaultProp( propName, setting )
	if setting == nil then 
		setting = self 
	end 
	local check = self 
	if setting == self then 
		check = self.vcaDefaults 
	end 
	if check == nil or setting[propName] == nil or check[propName] == nil then 
		isEqual = true 
	end
	if type( setting[propName] ) == "number" and type( check[propName] ) == "number" then 
		if math.abs( setting[propName] - check[propName] ) < 1e-4 then 
			return false 
		end 
		return true 
	elseif setting[propName] == check[propName] then 
		return false 
	end 
	return true  
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
	
	local l = getCorrectTextSize(0.02)

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
	self.vcaScaleFx          = vehicleControlAddon.vcaScaleFx
	self.vcaSetState         = vehicleControlAddon.mbSetState
	self.vcaIsValidCam       = vehicleControlAddon.vcaIsValidCam
	self.vcaIsActive         = vehicleControlAddon.vcaIsActive
	self.vcaIsNonDefaultProp = vehicleControlAddon.vcaIsNonDefaultProp
	self.vcaGetSteeringNode  = vehicleControlAddon.vcaGetSteeringNode
	
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
	vehicleControlAddon.registerState( self, "vcaCamRotInside", VCAGlobals.camInsideRotation )
	vehicleControlAddon.registerState( self, "vcaCamRotOutside",VCAGlobals.camOutsideRotation )
	vehicleControlAddon.registerState( self, "vcaCamRevInside", vehicleControlAddon.getDefaultReverse( self, true ) )
	vehicleControlAddon.registerState( self, "vcaCamRevOutside",vehicleControlAddon.getDefaultReverse( self, false ) )
	vehicleControlAddon.registerState( self, "vcaExponent"    , 1    , vehicleControlAddon.vcaOnSetFactor )
	vehicleControlAddon.registerState( self, "vcaWarningText" , ""   , vehicleControlAddon.vcaOnSetWarningText )
	vehicleControlAddon.registerState( self, "vcaLimitThrottle",VCAGlobals.limitThrottle )
	vehicleControlAddon.registerState( self, "vcaSnapAngle"   , VCAGlobals.snapAngle, vehicleControlAddon.vcaOnSetSnapAngle )
	vehicleControlAddon.registerState( self, "vcaSnapDistance", 3 )
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
	vehicleControlAddon.registerState( self, "vcaAutoShift",    true) --, vehicleControlAddon.vcaOnSetAutoShift )
	vehicleControlAddon.registerState( self, "vcaShifterIndex", 0 )
	vehicleControlAddon.registerState( self, "vcaShifterLH",    true )
	vehicleControlAddon.registerState( self, "vcaLimitSpeed",   true )
	vehicleControlAddon.registerState( self, "vcaLaunchGear",   VCAGlobals.launchGear )
	vehicleControlAddon.registerState( self, "vcaBOVVolume",    0, vehicleControlAddon.vcaOnSetGearChanged )
	vehicleControlAddon.registerState( self, "vcaKSIsOn",       true ) --, vehicleControlAddon.vcaOnSetKSIsOn )
	vehicleControlAddon.registerState( self, "vcaKeepSpeed",    0 )
	vehicleControlAddon.registerState( self, "vcaKSToggle",     false )
	vehicleControlAddon.registerState( self, "vcaCCSpeed2",     10 )
	vehicleControlAddon.registerState( self, "vcaCCSpeed3",     15 )
	vehicleControlAddon.registerState( self, "vcaAutoClutch",   true )
	vehicleControlAddon.registerState( self, "vcaLastSnapAngle",10 ) --, vehicleControlAddon.vcaOnSetLastSnapAngle ) -- value should be between -pi and pi !!!
	vehicleControlAddon.registerState( self, "vcaLastSnapPosX", 0 )
	vehicleControlAddon.registerState( self, "vcaLastSnapPosZ", 0 )
	vehicleControlAddon.registerState( self, "vcaIsEnteredMP",  false )
	vehicleControlAddon.registerState( self, "vcaSnapDraw",     1 )
	vehicleControlAddon.registerState( self, "vcaHandthrottle", 0 )
	vehicleControlAddon.registerState( self, "vcaPitchFactor",  1 )
	
	self.vcaFactor        = 1
	self.vcaReverseTimer  = 1.5 / VCAGlobals.timer4Reverse
	self.vcaMovingDir     = 0
	self.vcaLastFactor    = 0
	self.vcaWarningTimer  = 0
	self.vcaShifter7isR1  = nil 
	self.vcaGearbox       = nil
	self.vcaTickDt        = 0
	self.vcaIsEntered     = false

	self.vcaClutchPercent = 0
	self.vcaClutchPercentS= 0
	self.vcaClutchDisp    = 0
	self.vcaClutchDispS   = 0
	self.vcaRpmFactor     = 1
	self.vcaRpmFactorS    = 1
	self.vcaLastRpmFactor = 1

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

		if vehicleControlAddon.grindingSample == nil then 
			local fileName = Utils.getFilename( "grinding.ogg", vehicleControlAddon.baseDirectory )
			vehicleControlAddon.grindingSample = createSample("vehicleControlAddonGrindingSample")
			loadSample(vehicleControlAddon.grindingSample, fileName, false)
		end 	
	
		if vehicleControlAddon.gearShiftSample == nil then 
			local fileName = Utils.getFilename( "shift.ogg", vehicleControlAddon.baseDirectory )
			vehicleControlAddon.gearShiftSample = createSample("vehicleControlAddonGearShiftSampleSample")
			loadSample(vehicleControlAddon.gearShiftSample, fileName, false)
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

	self.vcaDefaults = {}
	for _,prop in pairs( listOfProperties ) do 
		self.vcaDefaults[prop.propName] = self[prop.propName]
	end
	
	if self.isServer then 
		self.vcaUserSettings = {}	
	end 
	self.vcaControllerName = ""	
end

function vehicleControlAddon:onPostLoad(savegame)
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile

		vehicleControlAddon.debugPrint("Loading: "..tostring(savegame.key).."...")
		
		for _,prop in pairs( listOfProperties ) do 
			local v = prop.getFunc( savegame.xmlFile, savegame.key.."."..vehicleControlAddon_Register.specName.."#"..prop.xmlName )
			vehicleControlAddon.debugPrint(tostring(prop.xmlName)..": "..tostring(v))
			if v ~= nil then 
				self:vcaSetState( prop.propName, v, true ) 
			end 
		end 
		
		local u = 0 
		while true do 
			local key  = string.format( "%s.%s.users(%d)", savegame.key, vehicleControlAddon_Register.specName, u )
			u = u + 1 
			local name = getXMLString(xmlFile, key.."#user")
			if name == nil then 
				break 
			end 
			if self.vcaUserSettings == nil then 
				self.vcaUserSettings = {} 
			end 
			self.vcaUserSettings[name] = {} 

			for _,prop in pairs( listOfProperties ) do 
				local v = prop.getFunc( savegame.xmlFile, key.."#"..prop.xmlName )
				vehicleControlAddon.debugPrint("User: "..tostring(name).."; "..tostring(prop.xmlName)..": "..tostring(v))
				if v == nil then 
					self.vcaUserSettings[name][prop.propName] = self[prop.propName] 
				else 
					self.vcaUserSettings[name][prop.propName] = v 
				end 
			end 
		end 
	
		self:vcaSetState( "vcaKSIsOn", self.vcaKSToggle, true )
	end 
		
	if self.spec_motorized ~= nil then 
		local pMax  = 0
		local mMax1 = 0
		local mMax2 = 0
		for _,k in pairs( self.spec_motorized.motor.torqueCurve.keyframes ) do 
			local p = k.time * k[1]
			if p > pMax then 
				pMax  = p 
				mMax1 = k.time 
				mMax2 = k.time 
			elseif p > 0.9 * pMax then 
				mMax2 = k.time 
			end 
		end 
		
		vehicleControlAddon.debugPrint(tostring(self.configFileName)..": "..tostring( mMax1 ).." .. "..tostring(mMax2 ))
		
		self.vcaPowerRpm = mMax1 
		self.vcaRatedRpm = mMax2 
	end 
	
end 

function vehicleControlAddon:saveToXMLFile(xmlFile, xmlKey)

	for _,prop in pairs( listOfProperties ) do 
		if self:vcaIsNonDefaultProp( prop.propName ) then 
			prop.setFunc( xmlFile, xmlKey.."#"..prop.xmlName, self[prop.propName] )
		end 
	end 
	
	if type( self.vcaUserSettings ) == "table" then 
		local u = 0
		for name,setting in pairs( self.vcaUserSettings ) do 
			local ins = true 
			local key = string.format( "%s.users(%d)", xmlKey, u ) 
			
			for _,prop in pairs( listOfProperties ) do 
				if self:vcaIsNonDefaultProp( prop.propName, setting ) then
					if ins then 
					-- store setting for this user 
						ins = false 
						u   = u + 1 
						setXMLString( xmlFile, key.."#user", name )
					end 
					prop.setFunc( xmlFile, key.."#"..prop.xmlName, setting[prop.propName] )
				end 
			end 
		end 
	end 
end 

function vehicleControlAddon:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	if self.isClient and self:getIsActiveForInput(true, true) then
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
                                "vcaSnapUP",        
                                "vcaSnapDOWN",      
                                "vcaSnapLEFT",      
                                "vcaSnapRIGHT",     
                                "vcaDIRECTION",     
                                "vcaFORWARD",     
                                "vcaREVERSE",
																"vcaNO_ARB",
																"vcaINCHING",
																"vcaKEEPSPEED",
																"vcaSWAPSPEED",
                                "vcaSNAP",
                                "vcaSNAPRESET",
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
																"vcaClutch" }) do
			if     isOnActiveVehicle 
					or actionName == "vcaUP"
          or actionName == "vcaDOWN"
          or actionName == "vcaLEFT"
          or actionName == "vcaRIGHT"
					or actionName == "vcaSWAPSPEED" then 
				-- above actions are still active for hired worker
				local pBool1, pBool2, pBool3, pBool4 = false, true, false, true 
				if     actionName == "vcaUP"
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
					pBool1 = true 
				elseif actionName == "vcaClutch" then 
					pBool2 = false 
					pBool3 = true 
				end 
				
				local _, eventName = self:addActionEvent(self.vcaActionEvents, InputAction[actionName], self, vehicleControlAddon.actionCallback, pBool1, pBool2, pBool3, pBool4, nil);

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
end

function vehicleControlAddon:actionCallback(actionName, keyStatus, callbackState, isAnalog, isMouse, deviceCategory)


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
		if self.vcaGearbox ~= nil then 
			self.vcaGearbox:actionCallback( actionName, keyStatus )
		end 
		return 
	end 

	if     actionName == "vcaClutch" then 
		self.vcaCloseClutchNonAnalog = nil 
		if     isAnalog then 
			self.vcaClutchPercent = math.min( 1, 1.2*math.max( keyStatus-0.1, 0 ) )
		elseif self.vcaAutoClutch then 
			self.vcaClutchPercent = keyStatus
		elseif keyStatus > 0.5 then 
			self.vcaClutchPercent = math.min( 1, self.vcaClutchPercent + 0.004 * self.vcaTickDt )
		else 
			self.vcaCloseClutchNonAnalog = true 
		end 
			
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
		
	elseif  -4 <= self.vcaLastSnapAngle and self.vcaLastSnapAngle <= 4
			and self.vcaSnapDistance >= 1
			and ( actionName == "vcaSnapUP"
				or  actionName == "vcaSnapDOWN"
				or  actionName == "vcaSnapLEFT"
				or  actionName == "vcaSnapRIGHT" ) then
		self.vcaSnapPosTimer = 3000
		
		local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )			
		local d = 0
		if lx*lx+lz*lz > 1e-6 then 
			d = math.atan2( lx, lz )
		end 
		local a  = vehicleControlAddon.vcaGetCurrentSnapAngle( self, d )
		local dx = math.sin( a )
		local dz = math.cos( a )			
		local fx = 0
		local fz = 0
		
		if     actionName == "vcaSnapUP"    then
			fz = 0.1
		elseif actionName == "vcaSnapDOWN"  then
			fz = -0.1
		elseif actionName == "vcaSnapLEFT"  then
			fx = 0.1 
		elseif actionName == "vcaSnapRIGHT" then
			fx = -0.1 
		end 

		self:vcaSetState( "vcaLastSnapPosX", self.vcaLastSnapPosX + fz * dx + fx * dz )
		self:vcaSetState( "vcaLastSnapPosZ", self.vcaLastSnapPosZ + fz * dz - fx * dx )
		
	elseif actionName == "vcaSNAPRESET" then
		self:vcaSetState( "vcaLastSnapAngle", 10 )
		self:vcaSetState( "vcaLastSnapPosX", 0 )
		self:vcaSetState( "vcaLastSnapPosZ", 0 )
		self:vcaSetState( "vcaSnapIsOn", false )
	elseif actionName == "vcaSNAP" then
		self:vcaSetState( "vcaSnapIsOn", not self.vcaSnapIsOn )
		
		if self.vcaSnapIsOn then 
			self.vcaSnapPosTimer = 3000
		end
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
	if self.vcaIsEntered then 
		self:vcaSetState( "vcaInchingIsOn", false )
		self:vcaSetState( "vcaNoAutoRotBack", false )
		self.vcaNewRotCursorKey  = nil
		self.vcaPrevRotCursorKey = nil
		self:vcaSetState( "vcaSnapIsOn", false )
		self:vcaSetState( "vcaShifterIndex", 0 )
		self:vcaSetState( "vcaKSIsOn", self.vcaKSToggle )
		self:vcaSetState( "vcaIsEnteredMP", false )
	end 

	self.vcaIsEntered = false 
end 

function vehicleControlAddon:vcaIsActive()
	if self:getIsEntered() and self:getIsVehicleControlledByPlayer() then 
		return true 
	end 
	return false
end 

function vehicleControlAddon:onPreUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if      self.isClient
			and self.vcaIsEntered
			and self.vcaSnapIsOn
			and self.spec_drivable ~= nil
			and self:getIsActiveForInput(true, true)
			and self:getIsVehicleControlledByPlayer()
			and math.abs( self.spec_drivable.lastInputValues.axisSteer ) > 0.05 then 
		self:vcaSetState( "vcaSnapIsOn", false )
	end 
	
end

function vehicleControlAddon:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	self.vcaTickDt = dt

	if self.isClient and self.getIsEntered ~= nil and self:getIsControlled() and self:getIsEntered() then 
		self.vcaIsEntered = not g_gui:getIsGuiVisible()
		self:vcaSetState( "vcaIsEnteredMP", self.vcaIsEntered or self.spec_drivable.cruiseControl.state == 1 )
	else 
		self.vcaIsEntered = false 
	end 	
	
	
	--*******************************************************************
	-- user settings
	lastControllerName = self.vcaControllerName
	if self:getIsControlled() then 
		self.vcaControllerName = self:getControllerName()
		if lastControllerName == nil or lastControllerName ~= self.vcaControllerName then 
			vehicleControlAddon.mpDebugPrint( self,"New controller of vehicle is: "..self.vcaControllerName)
		end 
	elseif lastControllerName ~= nil then 
		if lastControllerName ~= "" then 
			vehicleControlAddon.mpDebugPrint( self,lastControllerName.." left vehicle")
		end 
		self.vcaControllerName = "" 
	end 
		
	if self.isServer and self.vcaControllerName ~= lastControllerName then 
		if lastControllerName ~= "" then 
			if self.vcaUserSettings[lastControllerName] == nil then 
				print("Error in vehicleControlAddon.lua: self.vcaUserSettings["..tostring(lastControllerName).."] is nil")
				self.vcaUserSettings[lastControllerName] = {} 
			end 
		-- remember previous user settings 
			for _,prop in pairs( listOfProperties ) do 
				self.vcaUserSettings[lastControllerName][prop.propName] = self[prop.propName] 
			end 
		end 
	
		if self.vcaControllerName ~= "" then 
			if self.vcaUserSettings[self.vcaControllerName] == nil then 
			-- new user or no settings in save game => create setting from self
				vehicleControlAddon.mpDebugPrint( self,"Creating settings for user "..self.vcaControllerName)
				self.vcaUserSettings[self.vcaControllerName] = {} 
				for _,prop in pairs( listOfProperties ) do 
					self.vcaUserSettings[self.vcaControllerName][prop.propName] = self[prop.propName]
				end 
			else
			-- changed user => restore user settings 
				vehicleControlAddon.mpDebugPrint( self,"Restoring settings for user "..self.vcaControllerName)
				for _,prop in pairs( listOfProperties ) do 
					if self.vcaUserSettings[self.vcaControllerName][prop.propName] ~= nil then 
						self:vcaSetState( prop.propName, self.vcaUserSettings[self.vcaControllerName][prop.propName] )
						vehicleControlAddon.mpDebugPrint( self, prop.propName.." of "..self.vcaControllerName..": "
																					..tostring( self[prop.propName]) .." ("..tostring(self.vcaUserSettings[	self.vcaControllerName][prop.propName])..")")
					end 
				end 
			end 
			if self.isClient and self.getIsEntered ~= nil and self:getIsEntered() then 
				self.vcaUserSettings[self.vcaControllerName].isMain = true 
			end 
		end 
	end 
	
	
	--*******************************************************************
	-- start the transmission
	if not ( self:getIsVehicleControlledByPlayer() 
			 and self:getIsMotorStarted()
			 and ( ( self.isClient and self.vcaIsEntered ) 
					or ( self.isServer and self.vcaIsEnteredMP ) ) ) then 
		if self.vcaLastTransmission ~= nil then 
			vehicleControlAddon.mpDebugPrint( self, "*********************************************" )
			vehicleControlAddon.mpDebugPrint( self, tostring(self.configFileName))
			vehicleControlAddon.mpDebugPrint( self, "Resetting transmission")
			vehicleControlAddon.mpDebugPrint( self, "*********************************************" )
		end 
		self.vcaLastTransmission = nil 
	elseif self.vcaLastTransmission == nil or self.vcaLastTransmission ~= self.vcaTransmission then 	
		vehicleControlAddon.mpDebugPrint( self, "*********************************************" )
		vehicleControlAddon.mpDebugPrint( self, tostring(self.configFileName))
		vehicleControlAddon.mpDebugPrint( self, "Old transmission: "..tostring(self.vcaLastTransmission)..", new transmission: "..tostring(self.vcaTransmission))
		self.vcaLastTransmission = self.vcaTransmission
		
		if self.vcaGearbox ~= nil then 
			self.vcaGearbox:delete()
		end 
		
		local transmissionDef = vehicleControlAddonTransmissionBase.transmissionList[self.vcaTransmission]
		if transmissionDef == nil then 
			self.vcaGearbox = nil  
		else 
			self.vcaGearbox = transmissionDef.class:new( unpack( transmissionDef.params ) )
		end 
		
		if self.vcaGearbox ~= nil then 
			self.vcaGearbox:setVehicle( self )
		end 
		
		if self.isServer and self.vcaLastTransmission == nil or self.vcaLastTransmission <= 1 then 
			vehicleControlAddon.mpDebugPrint( self, "New launch gear index: "..tostring(VCAGlobals.launchGear))
			self:vcaSetState( "vcaLaunchGear", VCAGlobals.launchGear, noEventSend )
		end 
		
		if self.vcaGearbox ~= nil then 
			self.vcaGearbox:initGears( true )	
		end 
		
		vehicleControlAddon.mpDebugPrint( self, "Gear: "..tostring(self.vcaGear)..", range: "..tostring(self.vcaRange))
		vehicleControlAddon.mpDebugPrint( self, "*********************************************" )
		
		self:updateMotorProperties()
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
	-- disable shuttle and transmission in case of FS19_RealManualTransmission
	if self.hasRMT then 
		self:vcaSetState( "vcaShuttleCtrl", false )
	end 
	if self.rmtIsOn then 
		self:vcaSetState( "vcaTransmission", 0 )
	end 
	
	if self.vcaCloseClutchNonAnalog then 
		self.vcaClutchPercent = self.vcaClutchPercent - 0.001 * dt
		if self.vcaClutchPercent <= 0 then 
			self.vcaClutchPercent = 0
			self.vcaCloseClutchNonAnalog = nil 
		end 
	end 

	--*******************************************************************
	-- overwrite or reset some values 
	if self.vcaShuttleCtrl and self:getIsVehicleControlledByPlayer() then 
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
	
	if self.vcaShuttleCtrl and self:getIsVehicleControlledByPlayer() then 
		if self.vcaReverseDriveSample == nil then 
			self.vcaReverseDriveSample = self.spec_motorized.samples.reverseDrive 
		end 
		self.spec_motorized.samples.reverseDrive = nil 
	elseif self.vcaReverseDriveSample ~= nil then 
		self.spec_motorized.samples.reverseDrive = self.vcaReverseDriveSample
		self.vcaReverseDriveSample               = nil
	end 
	
	if     self.spec_motorized.motor.lowBrakeForceScale == nil then
	elseif self:vcaIsActive() and self.vcaBrakeForce <= 0.99 then 
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

	if self.vcaNoAutoRotBack and self.vcaIsEntered then
		if self.vcaAutoRotateBackSpeed == nil then 
			self.vcaAutoRotateBackSpeed = self.autoRotateBackSpeed
		end 
		self:vcaSetState( "vcaSnapIsOn", false )
		self.autoRotateBackSpeed      = 0
	elseif self.vcaAutoRotateBackSpeed ~= nil then
		self.autoRotateBackSpeed      = self.vcaAutoRotateBackSpeed
		self.vcaAutoRotateBackSpeed   = nil 
	end 
	
	if self.vcaInchingIsOn and self.vcaIsEntered and self.spec_drivable.cruiseControl.state == 1 then
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
		elseif self.vcaShuttleCtrl and self:getIsVehicleControlledByPlayer() then 
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
	-- Keep Speed 
	local lastKSStopTimer = self.vcaLastKSStopTimer
	if self.vcaKSIsOn and self.vcaIsEntered then
		if     self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_FULL then 
			self:vcaSetState( "vcaKeepSpeed", self.lastSpeed * 3600 * self.movingDirection  )
		elseif self.spec_drivable.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ON then 
			self:vcaSetState( "vcaKeepSpeed", self:getCruiseControlSpeed() * self.movingDirection  )
			self:setCruiseControlState( Drivable.CRUISECONTROL_STATE_OFF )
		elseif math.abs( self.spec_drivable.axisForward ) > 0.01 then 
			local f = 3.6 * math.max( -self.spec_motorized.motor.maxBackwardSpeed, self.lastSpeed * 1000 * self.movingDirection - 1 )
			local t = 3.6 * math.min(  self.spec_motorized.motor.maxForwardSpeed,  self.lastSpeed * 1000 * self.movingDirection + 1  )
			local a = self.spec_drivable.axisForward
			if     self.vcaReverserDirection ~= nil then 
				a = a * self.vcaReverserDirection
			elseif self.spec_drivable.reverserDirection ~= nil then 
				a = a * self.spec_drivable.reverserDirection
			end 
			local s = vehicleControlAddon.mbClamp( self.vcaKeepSpeed + a * 0.0067 * dt, f, t ) 
			
			if math.abs( self.lastSpeed * 3600 ) > 2 then 
				self.vcaLastKSStopTimer = g_currentMission.time + 2000 
			elseif lastKSStopTimer == nil then 
				self.vcaLastKSStopTimer = g_currentMission.time
			elseif g_currentMission.time < lastKSStopTimer then 
				s = 0
			end 
				
			self:vcaSetState( "vcaKeepSpeed", s )
		end 
	end 
	
	--*******************************************************************
	-- Camera Rotation
	if      self:getIsActive() 
			and self.isClient 
			and self:getIsVehicleControlledByPlayer()
			and self:vcaIsValidCam() then
			
		local camera  = self.spec_enterable.cameras[i]
		local rotIsOn = self.vcaCamRotOutside
		local revIsOn = self.vcaCamRevOutside
		
		if camera.isInside then 
			rotIsOn = self.vcaCamRotInside
		  revIsOn = self.vcaCamRevInside
		end 
		
	--vehicleControlAddon.debugPrint( "Cam: "..tostring(rotIsOn)..", "..tostring(revIsOn)..", "..tostring(self.vcaLastCamIndex)..", "..tostring(self.vcaLastCamFwd))

		if     self.vcaLastCamIndex == nil 
				or self.vcaLastCamIndex ~= i then
				
			if      self.vcaLastCamIndex ~= nil
					and self.vcaZeroCamRotY  ~= nil
					and self.vcaLastCamRotY  ~= nil
					and self:vcaIsValidCam( self.vcaLastCamIndex ) then
				local oldCam = self.spec_enterable.cameras[self.vcaLastCamIndex]
				
				if (oldCam.resetCameraOnVehicleSwitch == nil and g_gameSettings:getValue("resetCamera")) or oldCam.resetCameraOnVehicleSwitch then
				-- camera is automatically reset
				elseif ( not oldCam.isInside and self.vcaCamRotOutside )
						or (     oldCam.isInside and self.vcaCamRotInside  ) then 
					oldCam.rotY = self.vcaZeroCamRotY + oldCam.rotY - self.vcaLastCamRotY
				end 
			end 
				
			self.vcaLastCamIndex = self.spec_enterable.camIndex
			self.vcaZeroCamRotY  = camera.rotY
			self.vcaLastCamRotY  = camera.rotY 
			self.vcaLastCamFwd   = nil
			
		elseif  g_gameSettings:getValue("isHeadTrackingEnabled") 
				and isHeadTrackingAvailable() 
				and camera.isInside 
				and camera.headTrackingNode ~= nil then
				
			if requestedBack ~= nil then 
				self.vcaCamBack = requestedBack 
			end 
			
			if revIsOn or self.vcaCamBack ~= nil then			
				if camera.headTrackingMogliPF == nil then 
					local p = getParent( camera.headTrackingNode )
					camera.headTrackingMogliPF = createTransformGroup("headTrackingMogliPF")
					link( p, camera.headTrackingMogliPF )
					link( camera.headTrackingMogliPF, camera.headTrackingNode )
					setRotation( camera.headTrackingMogliPF, 0, 0, 0 )
					setTranslation( camera.headTrackingMogliPF, 0, 0, 0 )
					camera.headTrackingMogliPR = false 
				end 
				
				local targetBack = false 
				if revIsOn and not ( self.vcaCamFwd ) then 
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
					if not camera.headTrackingMogliPR then 
						camera.headTrackingMogliPR = true 
						setRotation( camera.headTrackingMogliPF, 0, math.pi, 0 )
					end 
				else 
					if camera.headTrackingMogliPR then 
						camera.headTrackingMogliPR = false  
						setRotation( camera.headTrackingMogliPF, 0, 0, 0 )
					end 
				end 
			end 
			
		elseif rotIsOn 
				or revIsOn then

			local pi2 = math.pi / 2
			local eps = 1e-6
			oldRotY = camera.rotY
			local diff = oldRotY - self.vcaLastCamRotY
			
			
			if newRotCursorKey ~= nil then
				self.vcaZeroCamRotY = vehicleControlAddon.normalizeAngle( camera.origRotY + newRotCursorKey )
			elseif rotIsOn then
				self.vcaZeroCamRotY = self.vcaZeroCamRotY + diff
			else
				self.vcaZeroCamRotY = camera.rotY
			end
				
		--diff = math.abs( vehicleControlAddon.vcaGetAbsolutRotY( self, i ) )
			local isRev = false
			local aRotY = vehicleControlAddon.normalizeAngle( vehicleControlAddon.vcaGetAbsolutRotY( self, i ) - camera.rotY + self.vcaZeroCamRotY )
			if -pi2 < aRotY and aRotY < pi2 then
				isRev = true
			end
			
			if revIsOn then
				if     newRotCursorKey ~= nil then
				-- nothing
				elseif self.vcaLastCamFwd == nil or self.vcaLastCamFwd ~= self.vcaCamFwd then
					if isRev == self.vcaCamFwd then
						self.vcaZeroCamRotY = vehicleControlAddon.normalizeAngle( self.vcaZeroCamRotY + math.pi )
						isRev = not isRev						
					end
				end
				self.vcaLastCamFwd = self.vcaCamFwd
			end
			
			local newRotY = self.vcaZeroCamRotY
			
			if rotIsOn then
				
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

			camera.rotY = newRotY			
			
		--if math.abs( vehicleControlAddon.normalizeAngle( camera.rotY - newRotY ) ) > 0.5 * math.pi then
		--	if camera.positionSmoothingParameter > 0 then
		--		camera:updateRotateNodeRotation()
		--		local xlook,ylook,zlook = getWorldTranslation(camera.rotateNode)
		--		camera.lookAtPosition[1] = xlook
		--		camera.lookAtPosition[2] = ylook
		--		camera.lookAtPosition[3] = zlook
		--		local x,y,z = getWorldTranslation(camera.cameraPositionNode)
		--		camera.position[1] = x
		--		camera.position[2] = y
		--		camera.position[3] = z
		--		camera:setSeparateCameraPose()
		--	end
		--end 			
		end
		
		self.vcaLastCamRotY = camera.rotY
	elseif self.vcaLastCamIndex ~= nil then 
		if self.vcaZeroCamRotY and self:vcaIsValidCam( self.vcaLastCamIndex ) then
			self.spec_enterable.cameras[self.vcaLastCamIndex].rotY = self.vcaZeroCamRotY 
		end 
		self.vcaLastCamIndex = nil
		self.vcaZeroCamRotY  = nil
		self.vcaLastCamRotY  = nil
		self.vcaLastCamFwd   = nil
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
	if self.vcaSteeringIsOn and not ( self.vcaSnapIsOn ) and self:vcaIsActive() then 
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
	if self.isClient and self:vcaIsActive() then 
		if self.vcaShuttleCtrl and self:getIsVehicleControlledByPlayer() and self.vcaReverseDriveSample ~= nil then 
			local notRev = self.vcaShuttleFwd or self.vcaNeutral
			if not g_soundManager:getIsSamplePlaying(self.vcaReverseDriveSample) and not notRev then
				g_soundManager:playSample(self.vcaReverseDriveSample)
			elseif notRev then
				g_soundManager:stopSample(self.vcaReverseDriveSample)
			end
		end
	end 	
	
--******************************************************************************************************************************************
-- Real RPM 
	if self.isServer then 
		self.vcaRpmFactor = 1 
		if self.vcaTransmission ~= nil and self.vcaTransmission >= 1 and self:getIsMotorStarted() and self.spec_motorized.motor.vcaFakeRpm == nil then 
			local motor = self.spec_motorized.motor 
		
			local m = motor:getMinRpm()
			local r = motor:getNonClampedMotorRpm()
			if self:getIsMotorStarted() and motor:getMinRpm() > 0 and r < m then 
				self.vcaRpmFactor = math.max( 0.1, r / m )
			end 
			m = motor:getMaxRpm() / self.vcaPitchFactor
			if self:getIsMotorStarted() and motor:getMaxRpm() > 0 and r > m then 
				self.vcaRpmFactor = math.min( 1.9, r / m )
			end 
		end 
	end 
	
	if      self.isClient
			and self.spec_motorized.motorSamples ~= nil
			and ( math.abs( self.vcaLastRpmFactor - self.vcaRpmFactor ) > 0.02 or ( self.vcaRpmFactor == 1 and self.vcaLastRpmFactor ~= 1 ) ) then 
		self.vcaLastRpmFactor = self.vcaRpmFactor
		if self.vcaPitchBackup == nil then 
			self.vcaPitchBackup = {}
			for i,s in pairs( self.spec_motorized.motorSamples ) do 
				local indoor, outdoor = nil, nil 
				if s.indoorAttributes ~= nil then 
					indoor = s.indoorAttributes.pitch 
				end 
				if s.outdoorAttributes ~= nil then 
					outdoor = s.outdoorAttributes.pitch 
				end 
				self.vcaPitchBackup[i] =  { indoor = indoor, outdoor = outdoor }
			end 
		end 
		
		for i,s in pairs( self.spec_motorized.motorSamples ) do
			local indoor  = self.vcaPitchBackup[i].indoor 
			local outdoor = self.vcaPitchBackup[i].outdoor
			if indoor  ~= nil then 
				s.indoorAttributes.pitch  = self.vcaRpmFactor * indoor 
			end 
			if outdoor ~= nil then 
				s.outdoorAttributes.pitch = self.vcaRpmFactor * outdoor 
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
	                   "vcaCamRotInside"  ,
	                   "vcaCamRotOutside"  ,
	                   "vcaCamRevInside"  ,
	                   "vcaCamRevOutside"  ,
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

	if self.vcaIsEntered and self:getIsVehicleControlledByPlayer() then
		local x = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX
		local y = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + g_currentMission.inGameMenu.hud.speedMeter.fuelGaugeRadiusY * 1.6
		local l = getCorrectTextSize(0.02)
		
		setTextAlignment( RenderText.ALIGN_CENTER ) 
		setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_MIDDLE )
		setTextColor(1, 1, 1, 1) 
		setTextBold(false)
		
		self.vcaDebugT = nil 
		if self.vcaGearbox ~= nil then 
			local t = self.vcaGearbox
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
		
		local lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )			
		local d = 0
		if lx*lx+lz*lz > 1e-6 then 
			d = math.atan2( lx, lz )
		end 
		local curSnapAngle = vehicleControlAddon.vcaGetCurrentSnapAngle( self, d )
		

		
		if self.vcaDrawHud then 
			if VCAGlobals.snapAngleHudX >= 0 then 
				x = VCAGlobals.snapAngleHudX
				y = VCAGlobals.snapAngleHudY
				setTextAlignment( RenderText.ALIGN_LEFT ) 
				setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_BASELINE )
			else 
				y = y + l * 1.2
			end 
			
			if self.vcaTransmission >= 2 and self.vcaGearbox ~= nil then 
				local gear  = self.vcaGearbox:getRatioIndex( self.vcaGear, self.vcaRange )		
				local ratio = self.vcaGearbox:getGearRatio( gear )
				local maxSpeed = 0
				local text 
				local l2    = l
				if gear ~= nil and ratio ~= nil and self.vcaMaxSpeed ~= nil then 
					maxSpeed = 3.6 * ratio * self.vcaMaxSpeed
					text = self.vcaGearbox:getGearText( self.vcaGear, self.vcaRange )	
					
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

				text = text .." "..string.format(" %3.0f km/h",maxSpeed )
				
				local c
				if self.vcaAutoClutch then 
					c = self.vcaClutchDisp
				else 
					c = self.vcaClutchPercent 
				end 
				if c > 0.01 then 
					text = text ..string.format(" %3.0f%%",c*100 )
				else 
				end 
				renderText(x, y, l2, text)
				y = y + l * 1.2	
			end 

			if self.aiveAutoSteer or not ( -4 <= self.vcaLastSnapAngle and self.vcaLastSnapAngle <= 4 ) then 
				renderText(x, y, l, string.format( "%4.1f°", math.deg( math.pi - d )))
				y = y + l * 1.2	
			else
				if self.vcaSnapIsOn then 
					setTextColor(0, 1, 0, 0.5) 
					if self.vcaSnapDistance >= 1 then 
						renderText(x, y, l, string.format( "%4.1f° / %4.1fm", math.deg( math.pi - curSnapAngle ), self.vcaSnapDistance))
					else 
						renderText(x, y, l, string.format( "%4.1f° / %4.1f°", math.deg( math.pi - curSnapAngle ), math.deg( math.pi - d )))
					end 
					y = y + l * 1.2	
					setTextColor(1, 1, 1, 1) 
				else
					renderText(x, y, l, string.format( "%4.1f° / %4.1f°", math.deg( math.pi - curSnapAngle ), math.deg( math.pi - d )))
					y = y + l * 1.2	
				end
			end
			
			if self.vcaKSIsOn and self.spec_drivable.cruiseControl.state == 0 then 
				renderText(x, y, l, string.format( "%5.1f km/h",self.vcaKeepSpeed))
				y = y + l * 1.2	
			end

		end 
			
		local snapDraw = false
		if self.aiveAutoSteer or not ( -4 <= self.vcaLastSnapAngle and self.vcaLastSnapAngle <= 4 ) then 		
			self.vcaSnapDrawTimer = nil
			self.vcaSnapPosTimer  = nil 
		elseif self.vcaSnapDistance  < 1 then 
			snapDraw = false
			self.vcaSnapPosTimer  = nil 
		elseif self.vcaSnapPosTimer ~= nil and self.vcaSnapDistance >= 1 then 
			snapDraw = true
			self.vcaSnapDrawTimer = 3000
		elseif self.vcaSnapDraw >= 2 then 
			snapDraw = true 
		elseif self.vcaSnapDraw >= 1 and not self.vcaSnapIsOn then  
			snapDraw = true 
			self.vcaSnapDrawTimer = 3000
		elseif self.vcaSnapDrawTimer ~= nil then 
			if math.abs( self.lastSpeedReal ) * 3600 > 1 then 
				self.vcaSnapDrawTimer = self.vcaSnapDrawTimer - self.vcaTickDt 
			end 
			if self.vcaSnapDrawTimer < 0 then 
				self.vcaSnapDrawTimer = nil 
			else 
				snapDraw = true 
			end 
		end 		
		if snapDraw then
			local wx,wy,wz = getWorldTranslation( self:vcaGetSteeringNode() )
			
			local dx    = math.sin( curSnapAngle )
			local dz    = math.cos( curSnapAngle )			
			local distX = wx - self.vcaLastSnapPosX
			local distZ = wz - self.vcaLastSnapPosZ 	
			
			local iMax  = 2
			if self.vcaSnapIsOn then 
				iMax = 1 
			end 
			for i=1,iMax do
				local dist  = distX * dz - distZ * dx

				while dist+dist > self.vcaSnapDistance do 
					dist = dist - self.vcaSnapDistance
				end 
				while dist+dist <-self.vcaSnapDistance do 
					dist = dist + self.vcaSnapDistance
				end 

				setTextAlignment( RenderText.ALIGN_CENTER ) 
				setTextVerticalAlignment( RenderText.VERTICAL_ALIGN_MIDDLE )
				
				if     i > 1 then 
					setTextColor(0.5, 0.5, 0.5, 0.5) 
				elseif self.vcaSnapIsOn then 
					setTextColor(0, 1, 0, 0.5) 
				else 
					setTextColor(1, 0, 0, 1) 
				end 
				
				for z=-20,20,0.5 do 
					if math.abs( z ) >= 5 then 
						for x=-1,1 do 
							local px = wx - dist * dz + z * dx - x * 0.5 * self.vcaSnapDistance * dz
							local pz = wz + dist * dx + z * dz + x * 0.5 * self.vcaSnapDistance * dx
							local py = getTerrainHeightAtWorldPos( g_currentMission.terrainRootNode, px, 0, pz )
							local sx,sy,sz = project(px,py,pz)
							if 0 < sz and sz <= 2 and 0 <= sx and sx <= 1 and 0 <= sy and sy <= 1 then 
								renderText(sx, sy, getCorrectTextSize(0.04) * sz, ".")					
							end 
						end 
					end 
				end 
				dx, dz = -dz, dx
			end 
		end 
		
		if self.vcaSnapPosTimer ~= nil then 
			self.vcaSnapPosTimer = self.vcaSnapPosTimer - self.vcaTickDt 
			if self.vcaSnapPosTimer < 0 then 
				self.vcaSnapPosTimer = nil 
			end 
		
			local dx = math.sin( curSnapAngle )
			local dz = math.cos( curSnapAngle )	
			local df = 0.5 * self.vcaSnapDistance
	
			setTextColor(0, 0, 1, 1) 
			
			for f=-df,df,0.1 do 
				for i=1,4 do 
					local vx, vz = f, self.vcaSnapDistance + f 
					if     i == 1 then 
						vz = self.vcaSnapDistance + df
					elseif i == 2 then 
						vz = self.vcaSnapDistance - df
					elseif i == 3 then 
						vx = df
					elseif i == 4 then 
						vx = -df
					end 
				
					local px = self.vcaLastSnapPosX + vz * dx + vx * dz 
					local pz = self.vcaLastSnapPosZ + vz * dz - vx * dx 				
					local py = getTerrainHeightAtWorldPos( g_currentMission.terrainRootNode, px, 0, pz )
					local sx,sy,sz = project(px,py,pz)
					if 0 < sz and sz <= 2 and 0 <= sx and sx <= 1 and 0 <= sy and sy <= 1 then 
						renderText(sx, sy, getCorrectTextSize(0.04) * sz, ".")					
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

	self.vcaSteeringIsOn  = streamReadBool(streamId) 
  self.vcaCamRotInside  = streamReadBool(streamId) 
  self.vcaCamRotOutside = streamReadBool(streamId) 
  self.vcaCamRevInside  = streamReadBool(streamId) 
  self.vcaCamRevOutside = streamReadBool(streamId) 
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
	self.vcaLastSnapAngle = streamReadFloat32(streamId)
	self.vcaLastSnapPosX  = streamReadFloat32(streamId)
	self.vcaLastSnapPosZ  = streamReadFloat32(streamId)
	
end

function vehicleControlAddon:onWriteStream(streamId, connection)

	streamWriteBool(streamId,    self.vcaSteeringIsOn )
	streamWriteBool(streamId,    self.vcaCamRotInside )
	streamWriteBool(streamId,    self.vcaCamRotOutside )
	streamWriteBool(streamId,    self.vcaCamRevInside )
	streamWriteBool(streamId,    self.vcaCamRevOutside )
	streamWriteBool(streamId,    self.vcaCamFwd )     
	streamWriteBool(streamId,    self.vcaShuttleCtrl )     
	streamWriteBool(streamId,    self.vcaShuttleFwd )     
	streamWriteBool(streamId,    self.vcaNeutral )     
	streamWriteBool(streamId,    self.vcaDrawHud )     
	streamWriteInt16(streamId,   self.vcaExternalDir )     
	streamWriteInt16(streamId,   self.vcaExponent )     
	streamWriteInt16(streamId,   self.vcaSnapAngle )     
	streamWriteBool(streamId,    self.vcaPeekLeftRight )
	streamWriteBool(streamId,    self.vcaAutoShift     )
	streamWriteBool(streamId,    self.vcaLimitSpeed    )
	streamWriteInt16(streamId,   self.vcaLimitThrottle )
	streamWriteInt16(streamId,   math.floor( 20 * self.vcaBrakeForce + 0.5 ) )
	streamWriteInt16(streamId,   self.vcaLaunchGear    )
	streamWriteInt16(streamId,   self.vcaTransmission  )
	streamWriteFloat32(streamId, self.vcaMaxSpeed      )
	streamWriteFloat32(streamId, self.vcaLastSnapAngle )
	streamWriteFloat32(streamId, self.vcaLastSnapPosX  )
	streamWriteFloat32(streamId, self.vcaLastSnapPosZ  )

end 


function vehicleControlAddon:onReadUpdateStream(streamId, timestamp, connection)
	local motor = self.spec_motorized.motor
	if streamReadBool(streamId) then
		if not connection:getIsServer() then
		-- receive vcaClutchPercent from client  
			self.vcaClutchPercent = streamReadUIntN(streamId, 10) / 1023 
		else 
		-- receive vcaClutchDisp from server 
			self.vcaClutchDisp = streamReadUIntN(streamId, 10) / 1023
			self.vcaRpmFactor  = streamReadUIntN(streamId, 6 ) / 43
		end 
	end
end

function vehicleControlAddon:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_motorized
	if connection:getIsServer() then
	-- send vcaClutchPercent to server 
		if streamWriteBool(streamId, math.abs( self.vcaClutchPercent - self.vcaClutchPercentS ) > 0.001) then
			streamWriteUIntN(streamId, math.floor( self.vcaClutchPercent * 1023 + 0.5 ), 10)
			self.vcaClutchPercentS = self.vcaClutchPercent
		end
	else 
	-- send vcaClutchDisp and vcaRpmFactor to client
		local hasUpdate = false 
		if     math.abs( self.vcaClutchDisp - self.vcaClutchDispS ) > 0.001
				or math.abs( self.vcaRpmFactor  - self.vcaRpmFactorS  ) > 0.02 then 
			hasUpdate = true 
		end 
			
		if streamWriteBool(streamId, hasUpdate ) then
			streamWriteUIntN(streamId, vehicleControlAddon.mbClamp( math.floor( 0.5 + self.vcaClutchDisp * 1023 ), 0, 1023 ), 10)			
			-- 0 to 1.1 * maxRpm; 3723 * 1.1 = 4095.3
			streamWriteUIntN(streamId, vehicleControlAddon.mbClamp( math.floor( 0.5 + self.vcaRpmFactor * 43 ), 0, 63 ), 6)
			self.vcaClutchDispS = self.vcaClutchDisp  
			self.vcaRpmFactorS  = self.vcaRpmFactor 
		end
	end

end

function vehicleControlAddon:onStartReverseDirectionChange()
	if self.vcaShuttleCtrl then 
		self:vcaSetState( "vcaShuttleFwd", not self.vcaShuttleFwd )
	end 
end 

function vehicleControlAddon:vcaGetSteeringNode()
	if self.spec_aiVehicle ~= nil and self.spec_aiVehicle.steeringNode ~= nil then 
		return self.spec_aiVehicle.steeringNode
	end 
	return self.components[1].node  
end 

function vehicleControlAddon:vcaGetCurrentSnapAngle(curRot)

	if self.vcaLastSnapAngle == nil or curRot == nil then 
		return 0 
	end
	
	local a = self.vcaLastSnapAngle
	local c = curRot 

	while a - c <= -math.pi*0.25 do 
		a = a + math.pi*0.5
	end 
	while a - c > math.pi*0.25 do 
		a = a - math.pi*0.5
	end

	return a			
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

function vehicleControlAddon:getDefaultReverse( isInside )
	if isInside then 
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

--******************************************************************************************************************************************
function vehicleControlAddon:vcaUpdateVehiclePhysics( superFunc, axisForward, axisSide, doHandbrake, dt )
	--*******************************************************************
	-- Snap Angle
	local axisSideLast       = self.vcaAxisSideLast
	local lastSnapAngleTimer = self.vcaSnapAngleTimer
	self.vcaAxisSideLast     = nil
	self.vcaSnapAngleTimer   = nil
	self.vcaLastSnapIsOn     = self.vcaSnapIsOn 
	
	if self.vcaSnapIsOn then 
		if not ( self.vcaIsEnteredMP ) then
			self:vcaSetState( "vcaSnapIsOn", false )
		elseif self.spec_aiVehicle ~= nil and self.spec_aiVehicle.isActive then 
			self:vcaSetState( "vcaSnapIsOn", false )
		elseif self.aiveAutoSteer then 
			self:vcaSetState( "vcaSnapIsOn", false )
		end 
	end 
	
	if self.vcaSnapIsOn then 
		local lx, lz 
		if self.vcaMovingDir < 0 then 
			lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, -1 )	
		else 
			lx,_,lz = localDirectionToWorld( self:vcaGetSteeringNode(), 0, 0, 1 )		
		end 
		local wx,_,wz = getWorldTranslation( self:vcaGetSteeringNode() )
		if lx*lx+lz*lz > 1e-6 then 
			local rot    = math.atan2( lx, lz )
			local d      = vehicleControlAddon.snapAngles[self.vcaSnapAngle]
			
			if not ( -4 <= self.vcaLastSnapAngle and self.vcaLastSnapAngle <= 4 ) then 
				self:vcaSetState( "vcaLastSnapPosX", wx )
				self:vcaSetState( "vcaLastSnapPosZ", wz )
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
				
				self:vcaSetState( "vcaLastSnapAngle", vehicleControlAddon.normalizeAngle( target ) )
			end 
			
			local curSnapAngle = vehicleControlAddon.vcaGetCurrentSnapAngle( self, rot )

			local dist    = 0
			local diffR   = vehicleControlAddon.normalizeAngle( rot - curSnapAngle )
			
			if     diffR > 0.5 * math.pi then 
				curSnapAngle = curSnapAngle + math.pi
				diffR = vehicleControlAddon.normalizeAngle( rot - curSnapAngle )
			elseif diffR <-0.5 * math.pi then 
				curSnapAngle = curSnapAngle - math.pi
				diffR = vehicleControlAddon.normalizeAngle( rot - curSnapAngle )
			end 
	
			if self.vcaSnapDistance >= 1 then 
				local dx    = math.sin( curSnapAngle )
				local dz    = math.cos( curSnapAngle )			
				local distX = wx - self.vcaLastSnapPosX
				local distZ = wz - self.vcaLastSnapPosZ 			
				local dist  = dist + distX * dz - distZ * dx

				while dist+dist > self.vcaSnapDistance do 
					dist = dist - self.vcaSnapDistance
				end 
				while dist+dist <-self.vcaSnapDistance do 
					dist = dist + self.vcaSnapDistance
				end 
				
				local alpha = math.asin( vehicleControlAddon.mbClamp( 0.1 * dist, -0.851, 0.851 ) )
				
				diffR = diffR + alpha
			end 
			
			local a = vehicleControlAddon.mbClamp( diffR / 0.174, -1, 1 ) 
			local m = self.movingDirection
			if self.lastSpeedReal * 3600 < 1 or ( -0.5 < m and m < 0.5 ) then 
				m = self.vcaMovingDir 
			end 
			if m < 0 then 
				a = -a 
			end

			d = 0.0005 * ( 2 + math.min( 18, self.lastSpeed * 3600 ) ) * dt
			
			if axisSideLast == nil then 
				axisSideLast = axisSide
			end 
			
			axisSide = axisSideLast + vehicleControlAddon.mbClamp( a - axisSideLast, -d, d )
		end 
	end 
	self.vcaAxisSideLast = axisSide
	
	return superFunc( self, axisForward, axisSide, doHandbrake, dt )
end 

Drivable.updateVehiclePhysics = Utils.overwrittenFunction( Drivable.updateVehiclePhysics, vehicleControlAddon.vcaUpdateVehiclePhysics )
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
			elseif not self.vcaIsEnteredMP then 
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
	
	if  		self:getIsMotorStarted()
			and math.abs( acceleration ) < 0.001 
			and not doHandbrake
			and ( self.vcaTransmission ~= nil and self.vcaTransmission > 0 )
			and ( ( ( self.vcaNeutral or self.vcaClutchPercent >= 1 ) and currentSpeed * 3600 > 1 )
				 or ( self.vcaTransmission == 1 and not self.spec_motorized.motor.vcaAutoStop and currentSpeed * 1000 < 1 )
				 or ( self.spec_motorized.motor.vcaIdleAcc ~= nil and self.spec_motorized.motor.vcaIdleAcc > 0 ) ) then 
		-- apply 0.2% brake 
		if self.vcaShuttleCtrl then 
			acceleration = -0.002 
		elseif self.movingDirection * self.spec_drivable.reverserDirection < 0 then 
			acceleration = 0.002 
		else 
			acceleration = -0.002 
		end 
		-- in neutral apply 0.2% throttle
		if     self.vcaNeutral
				or self.vcaClutchPercent >= 1
				or self.vcaShuttleCtrl
				or ( self.spec_motorized.motor.vcaIdleAcc ~= nil and self.spec_motorized.motor.vcaIdleAcc > 0 ) then 
			acceleration = -acceleration 
		end 
	end 
	
	if self:getIsVehicleControlledByPlayer() and self.vcaShuttleCtrl then 
		self.spec_lights   = nil
		stopAndGoBraking   = true 
	end 
	
	local state, result = pcall( superFunc, self, dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking ) 
	if not ( state ) then
		print("Error in updateWheelsPhysics :"..tostring(result))
		self.spec_lights = lightsBackup
		self.vcaShuttleCtrl  = false 
		self.vcaTransmission = 0 
	end
	
	if self:getIsVehicleControlledByPlayer() and self.vcaShuttleCtrl then 
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
function vehicleControlAddon:vcaUpdateGear( superFunc, acceleratorPedal, dt )
	
	local lastMinRpm   = Utils.getNoNil( self.vcaMinRpm,   self.minRpm )
	local lastMaxRpm   = Utils.getNoNil( self.vcaMaxRpm,   self.maxRpm )
	local lastFakeRpm  = Utils.getNoNil( self.vcaFakeRpm,  math.max( self.equalizedMotorRpm, self.minRpm )) 
	local lastClutchRpm= Utils.getNoNil( self.vcaClutchRpm,math.max( self.equalizedMotorRpm, self.minRpm )) 
	local lastIdleAcc  = Utils.getNoNil( self.vcaIdleAcc,  1 )
	self.vcaMinRpm     = nil 
	self.vcaMaxRpm     = nil 
	self.vcaFakeRpm    = nil
	self.vcaClutchRpm  = nil 
	self.vcaIdleAcc    = nil
	local speed        = math.abs( self.vehicle.lastSpeedReal ) *3600
	local motorPtoRpm  = math.min(PowerConsumer.getMaxPtoRpm(self.vehicle)*self.ptoMotorRpmRatio, self.maxRpm)
	local motorRpm     = self.motorRotSpeed * vehicleControlAddon.factor30pi
	local rpmRange     = self.maxRpm - self.minRpm
	
	local idleRpm      = self.minRpm  
	if     self.vehicle.vcaHandthrottle == nil 
			or self.vehicle.vcaHandthrottle == 0 then 
	elseif self.vehicle.vcaHandthrottle < 0 then 
		idleRpm          = math.max( idleRpm, -self.vehicle.vcaHandthrottle * motorPtoRpm )
	elseif self.vehicle.vcaHandthrottle > 0 then 
		idleRpm          = self.minRpm + self.vehicle.vcaHandthrottle * rpmRange
		if self.vehicle.vcaTransmission ~= nil and self.vehicle.vcaTransmission > 1 and self.vehicle.vcaAutoShift then 
			idleRpm        = math.min( idleRpm, 0.95 * self.maxRpm )
		end 
	end 
	
	if      self.vehicle.vcaForceStopMotor ~= nil 
			and self.vehicle.vcaForceStopMotor > 0		
			and ( self.vehicle:getIsMotorStarted()
				 or self.vehicle.vcaNeutral
				 or self.vehicle.vcaAutoClutch 
				 or ( self.vehicle.vcaClutchPercent ~= nil and self.vehicle.vcaClutchPercent > 0.5 ) ) then 
		self.vehicle.vcaForceStopMotor = self.vehicle.vcaForceStopMotor - dt 
		if self.vehicle.vcaForceStopMotor < 0 then 
			self.vehicle.vcaForceStopMotor = nil 
		end 
	end 
	
	if not ( self.vehicle:getIsVehicleControlledByPlayer() 
			 and ( ( self.vehicle.vcaTransmission ~= nil and self.vehicle.vcaTransmission > 0 )			 
					or self.vehicle.vcaNeutral ) ) then 
		if self.vehicle.vcaClutchDisp ~= nil and self.vehicle.vcaClutchDisp ~= 0 then 
			self.vehicle.vcaClutchDisp = 0
		end 
		return superFunc( self, acceleratorPedal, dt )
	end 
	
	local fwd, curBrake
	local lastFwd  = Utils.getNoNil( self.vcaLastFwd, true )
	if self.vehicle.spec_wheels ~= nil then 
		curBrake = Utils.getNoNil( self.vehicle.spec_wheels.brakePedal, 0 )
	else 
		curBrake = 0
	end 
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
	end 

	self.vcaLastFwd = fwd
	
	local dftDirTimer = 1000
	if self.vehicle.vcaShuttleCtrl then
		dftDirTimer = 250
	elseif stopAndGoBraking then 
		dftDirTimer = 100
	end 
	
	if lastFwd ~= fwd then 
		if speed > 1 then 
			self.vcaDirTimer = nil 
		end 
		curBrake = 1
		newAcc   = 0
	elseif speed < 1 then 
		if self.vcaDirTimer ~= nil then
			self.vcaDirTimer = self.vcaDirTimer - dt
			if self.vcaDirTimer < 0 then 
				self.vcaDirTimer = nil 
			end 
		end 
	elseif not fwd and self.vehicle.movingDirection > 0 then 
		self.vcaDirTimer = dftDirTimer 
	elseif fwd and self.vehicle.movingDirection < 0 then 
		self.vcaDirTimer = dftDirTimer 
	end 
	
	if self.vcaDirTimer ~= nil then 
		self.vcaAutoStop = true 
		curBrake = 1
		newAcc   = 0
	end 
	
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
	if not self.vehicle.vcaIsEnteredMP then 
		newAcc = 0
	end 
	
	--****************************************
	-- neutral
	local curAcc      = math.abs( newAcc )
	local fakeAcc     = curAcc 
	if self.vehicle.vcaShuttleCtrl and self.vehicle.vcaOldAcc ~= nil then 
		fakeAcc         =  self.vehicle.vcaOldAcc
	end
	if self.vcaDirTimer ~= nil then 
		fakeAcc         = 0
	end 
	local fakeRpm     = math.max( self.minRpm + fakeAcc * rpmRange, idleRpm )
	if self.vehicle.vcaHandthrottle == 0 or self.vehicle.vcaHandthrottle < -0.8 then 
		fakeRpm         = math.max( fakeRpm, motorPtoRpm )
	end 
	
	if self.vcaAutoStop or self.vehicle.vcaNeutral or self.vehicle.vcaClutchPercent >= 1 then 
		self.vcaFakeRpm   = vehicleControlAddon.mbClamp( fakeRpm, lastFakeRpm - 0.001 * dt * rpmRange, lastFakeRpm + 0.001 * dt * rpmRange )		
		self.vcaFakeTimer = 500 
		newAcc            = 0
	elseif self.vcaFakeTimer ~= nil then 
		if math.abs( lastFakeRpm - self.equalizedMotorRpm ) < 2 then 
			self.vcaFakeTimer = nil 
		else 
			local rpmRange = self.maxRpm - self.minRpm	
			self.vcaFakeRpm   = vehicleControlAddon.mbClamp( self.equalizedMotorRpm, lastFakeRpm - 0.001 * dt * rpmRange, lastFakeRpm + 0.001 * dt * rpmRange )	
			self.vcaFakeTimer = self.vcaFakeTimer - dt 
			if self.vcaFakeTimer <= 0 then 
				self.vcaFakeTimer = nil 
			end 
		end 
	end 
	
	local transmission = self.vehicle.vcaGearbox 
	
	if not self.vehicle:getIsMotorStarted() or dt < 0 then 
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
		if self.vehicle.vcaClutchDisp ~= 0 then 
			self.vehiclevcaClutchDisp = 0
		end 
	
		if self.vehicle.vcaHandthrottle ~= 0 then 
			newMinRpm = math.max( self.minRpm, idleRpm * 0.95 )
			newMaxRpm = math.min( self.maxRpm, idleRpm * 1.05 )
		elseif motorPtoRpm > 0 then 
			newMinRpm = math.max( self.minRpm, motorPtoRpm * 0.95 )
			newMaxRpm = math.min( self.maxRpm, motorPtoRpm * 1.05 )
		else 
			newMinRpm = self.minRpm
			newMaxRpm = self.maxRpm
		end 
					
		if speed > 2 then 
			self.vcaIncreaseRpm = g_currentMission.time + 2000 
		end 
		
		local minReducedRpm = math.min( math.max( newMinRpm, 0.5*math.min( 2200, self.maxRpm ) ), newMaxRpm )
		if self.vehicle.spec_combine ~= nil then 
			minReducedRpm = math.min( math.max( newMinRpm, 0.8*math.min( 2200, self.maxRpm ) ), newMaxRpm )
		end 
		
		local noThrottle = ( curAcc <= 0.1 )
		if speed >= self:getSpeedLimit() - 0.5 then 
			if self.vehicle.vcaKSIsOn then 
				noThrottle = self.vehicle.vcaOldAcc <= 0.1
			else 
				noThrottle = true 
			end 
		end 
		if noThrottle then 
			minReducedRpm = math.max( minReducedRpm - 0.05 * self.maxRpm, newMinRpm )
		else 
			minReducedRpm = math.min( minReducedRpm + 0.05 * self.maxRpm, self.maxRpm )
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
		self.maxGearRatio = 1000
		
		if not fwd then 
			self.minGearRatio = -self.minGearRatio
			self.maxGearRatio = -self.maxGearRatio
		end 
		
		if     not self.vehicle.vcaIsEnteredMP
				or self.vcaAutoStop    == nil then 
			self.vcaAutoStop = true
		elseif curAcc > 0.1 and not self.vehicle.vcaNeutral then  
			self.vcaAutoStop = false 
		elseif self.vehicle.vcaNeutral and speed < 1 then 
			self.vcaAutoStop = true
		elseif speed < 3.6 and curBrake > 0.1 then 
			self.vcaAutoStop = true
		end 
				
		return newAcc

	elseif transmission ~= nil then 
	--****************************************	
	-- 4x4 / 4x4 PS / 2x6 / FPS 
	
		local initGear = transmission:initGears() 
				
		if     not self.vehicle.vcaIsEnteredMP
		    or self.vcaClutchTimer == nil 
				or self.vcaAutoStop    == nil then 
			self.vcaAutoStop = true
		elseif curAcc > 0.1 and not self.vehicle.vcaNeutral then  
			self.vcaAutoStop = false 
		elseif self.vehicle.vcaNeutral and speed < 1 then 
			self.vcaAutoStop = true
		elseif  ( motorRpm < 0.9 * self.minRpm or speed < 2 ) 
				and curBrake > 0.1 
				and ( self.vehicle.vcaAutoClutch
					 or self.vehicle.vcaAutoShift
					 or self.vehicle.vcaClutchPercent > 0.8 ) then 
			self.vcaAutoStop = true
		end 
		
		if self.gearChangeTimer == nil then 
			self.gearChangeTimer = 0
		elseif self.gearChangeTimer > 0 then 
			self.gearChangeTimer = self.gearChangeTimer - dt 
		end 
		if self.vcaAutoStop then 
			self.vcaClutchTimer   = VCAGlobals.clutchTimer 
			self.vcaAutoDownTimer = 0
			self.vcaAutoUpTimer   = VCAGlobals.clutchTimer
		elseif self.vcaClutchTimer > 0 then --and motorRpm > self.minRpm then
			self.vcaClutchTimer   = self.vcaClutchTimer - dt
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
		if self.gearChangeTimer <= 0 and not self.vcaAutoStop and not self.vehicle.vcaNeutral then 
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
		if motorPtoRpm < self.minRpm and curAcc < 0.1 and curBrake < 0.1 and self.vcaAutoDownTimer < 3000 then  
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
		if motorPtoRpm < self.minRpm and self.vcaLoad < 0.8 then 
			self.vcaAutoLowTimer = 5000 
		end 
		if curAcc < 0.1 and self.vcaAutoLowTimer < 2000 then 
			self.vcaAutoLowTimer = 2000
		end 
		if maxSpeed > 0.41667 * self:getSpeedLimit() and self.vcaAutoDownTimer > 1000 then -- 0.41667 = 1.5 / 3.6
			self.vcaAutoDownTimer = 1000
		end 
		
		local setLaunchGear = ( initGear or lastFwd ~= fwd or self.vcaAutoStop )
		local newGear  = gear 
		if initGear then 
			newGear = self.vehicle.vcaLaunchGear
		elseif  self.vehicle.vcaAutoShift 
				and gear > self.vehicle.vcaLaunchGear
				and setLaunchGear
				and not ( self.vcaSetLaunchGear ) then 
			if self.vehicle.vcaShifterIndex <= 0 then 
				local gearlist = transmission:getAutoShiftIndeces( gear, self.vehicle.vcaLaunchGear, true, false )
				if #gearlist > 0 then
					newGear = gearlist[1]
				end 
			end 
		elseif self.vehicle.vcaAutoShift and self.gearChangeTimer <= 0 and not self.vehicle.vcaNeutral and self.vehicle.vcaShifterIndex <= 0 then
			local m1 = self.minRpm * 1.1
			local m4 = math.min( math.max( self.vehicle.vcaRatedRpm, motorPtoRpm ), self.maxRpm * 0.975 )
			if motorPtoRpm <= 0 and curBrake <= 0 and curAcc > 0.1 and curAcc < 0.8 and self.gearChangeTimer <= 0 then 
				m4 = math.max( m1, math.min( m4, self.minRpm + curAcc * rpmRange * 0.975 ) )
			end 
			local m2 = math.min( m4, m1 / 0.72 )
			local m3 = math.max( m1, m4 * 0.72 )
			local autoMinRpm = m1 + self.vcaLoad * ( m3 - m1 )
			local autoMaxRpm = m3 + self.vcaLoad * ( m4 - m3 )
			if self.vehicle.vcaHandthrottle > 0 then 
				autoMaxRom = math.min( m4, idleRpm * 1.025 )
				autoMinRpm = math.min( m4, idleRpm * 0.975 )
			elseif motorPtoRpm > 0 then 
				if -1 < self.vehicle.vcaHandthrottle and self.vehicle.vcaHandthrottle < -0.8 then 
				-- 90% PTO 
					autoMaxRom = math.min( m4, motorPtoRpm * 1.025 )
					autoMinRpm = math.min( m4, idleRpm * 0.975 )
				elseif self.vehicle.vcaHandthrottle < 0 then 
				-- PTO ECO
					autoMaxRom = math.min( m4, idleRpm * 1.025 )
					autoMinRpm = math.min( m4, idleRpm * 0.975 )
				elseif motorPtoRpm > 0 then 
					autoMaxRom = math.min( m4, motorPtoRpm * 1.025 )
					autoMinRpm = math.min( m4, motorPtoRpm * 0.975 )
				end 
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
			
			if self.vcaAutoStop or curBrake > 0 then
				searchDown = true
				searchUp   = false 
				lowGear    = self.vehicle.vcaLaunchGear
			end 
			
			local gearlist = transmission:getAutoShiftIndeces( gear, lowGear, searchDown, searchUp )
			
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
			else 
				self.vehicle.vcaDebugA = string.format( "%3.0f%%; %3.0f%%; %4.0f..%4.0f; %4.0f no gear",
																								curAcc*100,self.vcaLoad*100,autoMinRpm,autoMaxRpm,wheelRpm)
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
		if not self.vcaAutoStop and not self.vehicle.vcaNeutral then 
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
		
		local lastStallTimer = self.vcaStallTimer
		self.vcaStallTimer   = nil
		local minRequiredRpm = math.max( self.minRpm, motorPtoRpm )
						
		
		if self.vcaGearIndex ~= nil and self.vcaGearIndex ~= gear then 
			if gear > self.vcaGearIndex then 
				self.vcaAutoUpTimer	  = math.max( self.vcaAutoUpTimer	 , 500  + self.gearChangeTimer * 2 )
				self.vcaAutoDownTimer = math.max( self.vcaAutoDownTimer, 3000 + self.gearChangeTimer )
			else                                    
				self.vcaAutoUpTimer	  = math.max( self.vcaAutoUpTimer	 , 3000 + self.gearChangeTimer * 2 )
				self.vcaAutoDownTimer = math.max( self.vcaAutoDownTimer, 500  + self.gearChangeTimer )
			end
		elseif motorRpm < 0.8 * self.minRpm and not self.vcaAutoStop and self.vcaFakeRpm == nil then 
			if self.vehicle.vcaAutoShift then  
				self.vcaClutchTimer = math.min( self.vcaClutchTimer + dt + dt, VCAGlobals.clutchTimer )
			else 
				if lastStallTimer == nil then 
					self.vcaStallTimer = dt
				else
					self.vcaStallTimer = lastStallTimer + dt
				end 
				if self.vcaStallTimer > 1000 and motorRpm < 0.5 * self.minRpm then 
					self.vehicle.vcaForceStopMotor = 2000
				end 
			end 
		elseif wheelRpm < minRequiredRpm and curBrake > 0 then 
			self.vcaClutchTimer = VCAGlobals.clutchTimer
		end 
		
		self.vehicle.vcaDebugM = string.format("%5.0f, %5.0f, %5.0f, %3.0f%%, %s, %5.0f", motorRpm, wheelRpm, minRequiredRpm, newAcc*100, tostring(self.vcaAutoStop), self.vcaClutchTimer )
		
		self.vcaGearIndex = gear
		self.vcaLastGear  = self.vehicle.vcaGear
		self.vcaLastRange = self.vehicle.vcaRange
		
		self.minGearRatio = self.maxRpm / ( maxSpeed * vehicleControlAddon.factor30pi )
		self.maxGearRatio = self.minGearRatio 
		
		local clutchFactor = 0 
		
		self.vehicle.vcaDebugK = string.format( "%5.0f > 0 and %5.0f > %5.0f and %5.0f <= 0 and %4.0f < %4.0f = %s",
																						self.vcaClutchTimer,
																						wheelRpm,
																						self.minRpm,
																						self.gearChangeTimer,
																						self.gearRatio,
																						1.1 * self.minGearRatio,
																						tostring( self.vcaClutchTimer > 0 and wheelRpm > self.minRpm and self.gearChangeTimer <= 0 and self.gearRatio < 1.1 * self.minGearRatio ) )

		if self.vcaClutchTimer > 0 and wheelRpm > self.minRpm and self.gearChangeTimer <= 0 and self.gearRatio < 1.1 * self.minGearRatio then 
			self.vcaClutchTimer = 0
		end 
		
		if self.vehicle.vcaAutoClutch then 
			if self.vehicle.vcaClutchPercent > 0 then 
				self.vcaClutchTimer = math.max( self.vcaClutchTimer, self.vehicle.vcaClutchPercent * VCAGlobals.clutchTimer )
			end 
			clutchFactor = math.max( self.vcaClutchTimer / VCAGlobals.clutchTimer, 0 )
		else 
			self.vcaClutchTimer = 0
			clutchFactor = self.vehicle.vcaClutchPercent
		end 
		self.vehicle.vcaClutchDisp =  clutchFactor

		if self.vcaAutoStop or self.vehicle.vcaNeutral or self.vehicle.vcaClutchPercent >= 1 then 
			self.vcaClutchTimer = VCAGlobals.clutchTimer
			self.vcaMinRpm      = 0
			self.vcaMaxRpm      = 1000000
		elseif self.gearChangeTimer > 0 then 
			self.vcaFakeRpm     = vehicleControlAddon.mbClamp( math.max( self.minRpm, motorPtoRpm ), 
																												lastFakeRpm - 0.001 * dt * rpmRange,
																												lastFakeRpm + 0.002 * dt * rpmRange )		
			self.vcaFakeTimer   = 100 
			newAcc              = 0
			self.vcaClutchTimer = VCAGlobals.clutchTimer
			self.vcaMinRpm      = 0
			self.vcaMaxRpm      = 1000000
		else
			if clutchFactor > 0 then 
			-- target RPM for clutch: at least wheelRpm so the vehicle does not brake
														--  PTO rpm 
														--  fakeRpm but not more than 20%
				self.vcaClutchRpm   = vehicleControlAddon.mbClamp(math.max( wheelRpm, motorPtoRpm, math.min( fakeRpm, self.minRpm + 0.2 * rpmRange ) ), 
																													lastClutchRpm - 0.001 * dt * rpmRange, lastClutchRpm + 0.002 * dt * rpmRange )
				-- open the RPM range as maxGearRatio decreases																									
				self.vcaMinRpm      = clutchFactor * self.vcaClutchRpm
				self.vcaMaxRpm      = self.vcaClutchRpm + clutchFactor * math.max( self.maxRpm - self.vcaClutchRpm, 0 )
				self.maxGearRatio   = math.max( self.minGearRatio, math.min( 1000, self.minGearRatio / math.max( 1 - clutchFactor, 0.0001 ) ) )
			else
				self.vcaMinRpm      = 0
				self.vcaMaxRpm      = self.maxRpm
			end  

			if     motorRpm <= 0.95 * idleRpm then
				self.vcaIdleAcc = 1
			elseif motorRpm > idleRpm then 
				self.vcaIdleAcc = 0
			elseif motorRpm <= idleRpm then
				f = 0.1 + 18 * ( 1 - motorRpm / idleRpm )
				self.vcaIdleAcc = lastIdleAcc + f * ( 1 - lastIdleAcc )
			else 
				local a = 0
				if curBrake <= 0 and motorRpm < 1.1 * idleRpm then 
					if motorRpm <= 0.9 * idleRpm then 
						a = 1
					else 
						a = math.max( curAcc , 5 * ( motorRpm / idleRpm - 1 ) )
					end 
				end 
				self.vcaIdleAcc = lastIdleAcc + 0.1 * ( a - lastIdleAcc )
			end 
			
			if curBrake <= 0 and self.vcaIdleAcc > curAcc then 
				newAcc = self.vcaIdleAcc
				if  not fwd then 
					newAcc = -newAcc
				end 
			end 	

			if clutchFactor > 0.5 and motorRpm < self.minRpm then 
				self.vcaFakeRpm   = self.minRpm
				self.vcaFakeTimer = 100
			end 
	
			if self.vehicle.vcaHandthrottle == 0 and not self.vehicle.vcaAutoShift and motorPtoRpm >= self.minRpm then 
				self.vcaMaxRpm = math.min( motorPtoRpm * 1.11, self.vcaMaxRpm )
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

function vehicleControlAddon:vcaGetMaxClutchTorque( superFunc, ... )
	if not ( self.vehicle:getIsVehicleControlledByPlayer() and self.vehicle.vcaTransmission ~= nil and self.vehicle.vcaTransmission > 0 ) then 
		return superFunc( self, ... )
	end 
	if self.vehicle.vcaNeutral or self.gearChangeTimer > 0 or self.vehicle.vcaClutchDisp >= 1 then 
		return 0
	end 
	
	local c = 1
	if self.vehicle.vcaTransmission > 1 then 
		c = 1 - self.vehicle.vcaClutchDisp
	end 
	
	return math.min( self:getPeakTorque() * 0.75 * ( 1 - math.cos( math.pi * c ) ), superFunc( self, ... ) )
end 

VehicleMotor.getMaxClutchTorque = Utils.overwrittenFunction( VehicleMotor.getMaxClutchTorque, vehicleControlAddon.vcaGetMaxClutchTorque )

function vehicleControlAddon:vcaGetCanMotorRun( superFunc, ... )
	if self.vcaForceStopMotor ~= nil and self.vcaForceStopMotor > 0 then 
		return false 
	end 
	return superFunc( self, ... )
end

Motorized.getCanMotorRun = Utils.overwrittenFunction( Motorized.getCanMotorRun, vehicleControlAddon.vcaGetCanMotorRun )

function vehicleControlAddon:vcaUpdateMotorProperties( superFunc, ... )
	if self.vcaGearbox ~= nil then 
		local motor = self.spec_motorized.motor
		motor.vcaMinRpm = motor.minRpm
		motor.vcaMaxRpm = motor.maxRpm

		motor.minRpm = 0
	--motor.maxRpm = motor.vcaMaxRpm * 1.1

		local state, result = pcall( superFunc, self, ... ) 
		if not ( state ) then
			print("Error in updateMotorProperties :"..tostring(result))
			self.vcaTransmission    = 0 
			self.vehicle.vcaGearbox = nil
		end
		
		motor.minRpm = motor.vcaMinRpm
		motor.maxRpm = motor.vcaMaxRpm
	else 
		superFunc( self, ... )
	end 
end 

Motorized.updateMotorProperties = Utils.overwrittenFunction( Motorized.updateMotorProperties, vehicleControlAddon.vcaUpdateMotorProperties )
--******************************************************************************************************************************************

function vehicleControlAddon:vcaGetEqualizedMotorRpm( superFunc ) 		
	if self.vehicle.isServer then 
		local r = superFunc( self )
		if self.vcaFakeRpm ~= nil then 
			r = self.vcaFakeRpm
		elseif self.vehicle.vcaGearbox ~= nil then 
			r = self.motorRotSpeed * vehicleControlAddon.factor30pi
		end 
		return vehicleControlAddon.mbClamp( r, self.minRpm, self.maxRpm )
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
	
  if      ( old == nil or new ~= old ) then 
		if self.isClient and self:vcaIsActive() then
			if new and vehicleControlAddon.snapOnSample ~= nil then
				playSample(vehicleControlAddon.snapOnSample, 1, 0.2, 0, 0, 0)
			elseif not new and vehicleControlAddon.snapOffSample ~= nil then
				playSample(vehicleControlAddon.snapOffSample, 1, 0.2, 0, 0, 0)
			end 
		end 
		
	--print("Turning off snap angle (server:"..tostring(self.isServer).."/client:"..tostring(self.isClient)..")")
	--print("old: "..tostring(old).." => new: "..tostring(new))
	--printCallstack()
	end 
end 

function vehicleControlAddon:vcaOnSetKSIsOn( old, new, noEventSend )
	self.vcaKSIsOn = new 
	
--if      ( old == nil or new ~= old ) then 
--	printCallstack()
--end 
end 

function vehicleControlAddon:vcaOnSetLastSnapAngle( old, new, noEventSend )
	self.vcaLastSnapAngle = new 
	
--if      ( old == nil or new ~= old ) then 
--	print("vcaOnSetLastSnapAngle: "..tostring(new))
--	printCallstack()
--end 
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
			and self:vcaIsActive()
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

function vehicleControlAddon:vcaOnSetAutoShift( old, new, noEventSend )
	self.vcaAutoShift = new 
	
	if old and not ( new ) then 
		printCallstack()
	end 
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
	for i,t in pairs(vehicleControlAddonTransmissionBase.transmissionList) do 
		table.insert( self.vcaUI.vcaTransmission , t.text )
	end 
	
	local m = vehicleControlAddon.getDefaultMaxSpeed( self )
	self.vcaUI.vcaMaxSpeed_V = { 7, 8.889, 11.944, 14.722, 16.111, 18.056, 20.417, 25, 33.333, 50 }
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
	local transmission = self.vcaGearbox
	if transmission ~= nil then 
		for i=1,transmission:getNumberOfRatios() do
			self.vcaUI.vcaLaunchGear[i] = string.format( "%2d: %3.0f km/h", i, transmission:getGearRatio( i )*3.6*self.vcaMaxSpeed )
		end 
	end 
	self.vcaUI.oldTransmission = self.vcaTransmission
	
	self.vcaUI.vcaSnapDistance_V = {}
	self.vcaUI.vcaSnapDistance   = {}
	for i,v in pairs( { 0, 1.5, 1.6, 1.7, 1.8, 1.9,
											2, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 
											3, 3.1, 3.2, 3.4, 3.6, 3.8, 4, 4.2, 4.5, 4.8, 
											5, 5.5, 6, 6.5, 7, 7.5, 8, 8.4, 9, 10, 12, 13.5, 15, 
											18, 18.2, 21, 24, 28, 30, 36, 40, 48 } ) do
		self.vcaUI.vcaSnapDistance_V[i] = v
		self.vcaUI.vcaSnapDistance[i]   = string.format( "%4.1fm",v )
	end 
	
	self.vcaUI.vcaSnapDraw = { "off", "only if inactive", "always" }
	
	self.vcaUI.vcaHandthrottle = { "off", "PTO ECO", "90% PTO", "100% PTO" } 
	self.vcaUI.vcaHandthrottle_V = { 0, -0.7, -0.9, -1 }
	local m1 = self.spec_motorized.motor.minRpm 
	local m2 = self.spec_motorized.motor.maxRpm 
	local md = m2 - m1
	
	local r = m1 + 100 
	while r <= m2 do 
		h = ( r - m1 ) / md 
		table.insert( self.vcaUI.vcaHandthrottle, string.format( "%4d U/min", r ) )
		table.insert( self.vcaUI.vcaHandthrottle_V, h )
		r = r + 100
	end 
	
	self.vcaUI.vcaPitchFactor   = {}
	self.vcaUI.vcaPitchFactor_V = {}
	for i=1,15 do 
		local v = 0.8 + ( i - 1 ) * 0.05
		table.insert( self.vcaUI.vcaPitchFactor, string.format( "%3.0f%%", v*100 ) )
		table.insert( self.vcaUI.vcaPitchFactor_V, v )
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

function vehicleControlAddon:vcaUIGetvcaSnapDistance()
	local d, j
	for i,e in pairs( self.vcaUI.vcaSnapDistance_V ) do
		local f = math.abs( e - self.vcaSnapDistance )
		if d == nil or d > f then 
			d = f 
			j = i 
		end
	end
	return j
end

function vehicleControlAddon:vcaUISetvcaSnapDistance( value )
	if self.vcaUI.vcaSnapDistance_V[value] ~= nil then
		self:vcaSetState( "vcaSnapDistance", self.vcaUI.vcaSnapDistance_V[value] )
	end
end

function vehicleControlAddon:vcaUISetvcaLaunchGear( value )
	if      self.vcaUI.oldTransmission ~= nil 
			and self.vcaUI.oldTransmission > 1 then  
		self:vcaSetState( "vcaLaunchGear", value )
	end
end

function vehicleControlAddon:vcaUISetvcaHandthrottle( value )
	if self.vcaUI.vcaHandthrottle_V[value] ~= nil then
		self:vcaSetState( "vcaHandthrottle", self.vcaUI.vcaHandthrottle_V[value] )
	end
end

function vehicleControlAddon:vcaUIGetvcaHandthrottle()
	local i = 1
	local d = 2
	for j,h in pairs( self.vcaUI.vcaHandthrottle_V ) do 
		if math.abs( h - self.vcaHandthrottle ) < d then 
			d = math.abs( h - self.vcaHandthrottle )
			i = j 
		end 
	end 
	return i
end

function vehicleControlAddon:vcaUIGetvcaPitchFactor()
	local j = 5
	local d = math.abs( self.vcaPitchFactor - 1 )
	for i,v in pairs( self.vcaUI.vcaPitchFactor_V ) do 
		if math.abs( self.vcaPitchFactor - v ) < d then 
			j = i 
			d = math.abs( self.vcaPitchFactor - v )
		end 
	end 
	return j 
end 

function vehicleControlAddon:vcaUISetvcaPitchFactor( value )
	self:vcaSetState( "vcaPitchFactor", 0.8 + ( value - 1 ) * 0.05 )
end 
