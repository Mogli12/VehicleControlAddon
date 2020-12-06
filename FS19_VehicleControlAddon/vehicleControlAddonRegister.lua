
local directory = g_currentModDirectory
local modName = g_currentModName
local specName = "zzzVehicleControlAddon"

VCAGlobals  = {}
VCADefaults = {}

vehicleControlAddonRegister = {}

local vehicleControlAddonRegister_mt = Class(vehicleControlAddonRegister)

function vehicleControlAddonRegister:new( i18n )
	self = {}
	setmetatable(self, vehicleControlAddonRegister_mt)
	self.vcaDirectory = directory
	self.vcaModName = modName 
	self.vcaSpecName = specName
	self.i18n = i18n

	return self 
end 

function vehicleControlAddonRegister:beforeFinalizeVehicleTypes()

	if vehicleControlAddon == nil then 
		print("Failed to add specialization vehicleControlAddon")
	else 
		for k, typeDef in pairs(g_vehicleTypeManager.vehicleTypes) do
			if typeDef ~= nil and k ~= "locomotive" and k ~= "woodCrusherTrailerDrivable" then 
				local isDrivable   = false
				local isEnterable  = false
				local hasMotor     = false 
				local hasLights    = false 
				local hasWheels    = false 
				local isAttachable = false 
				local isAiVehicle  = false 
				local hasNotVCA    = true 
				for name, spec in pairs(typeDef.specializationsByName) do
					if     name == "drivable"   then 
						isDrivable = true 
					elseif name == "motorized"  then 
						hasMotor = true 
					elseif name == "enterable"  then 
						isEnterable = true 
					elseif name == "lights"     then 
						hasLights = true 
					elseif name == "wheels"     then 
						hasWheels = true 
					elseif name == "attachable" then 
						isAttachable = true 
					elseif name == "aiVehicle" then 
						isAiVehicle = true 
					elseif name == specName then 
						hasNotVCA = false 
					end 
				end 
				if hasNotVCA and isDrivable and isEnterable and hasMotor and hasLights and hasWheels and ( isAiVehicle or not isAttachable ) then 
					print("  adding vehicleControlAddon to vehicleType '"..tostring(k).."'")
					typeDef.specializationsByName[specName] = vehicleControlAddon
					table.insert(typeDef.specializationNames, specName)
					table.insert(typeDef.specializations, vehicleControlAddon)	
				end 
			end 
		end 	
	end 
end 

local function postLoadMissionFinished( mission, node )
	local state, result = pcall( vehicleControlAddonRegister.postLoadMission, g_vehicleControlAddon, mission )
	if state then 
		return result 
	else 
		print("Error calling vehicleControlAddonRegister.postLoadMission :"..tostring(result)) 
	end 
end 
	
local vcaGetText
	
function vehicleControlAddonRegister:postLoadMission(mission)

	print("--- loading "..self.i18n:getText("vcaVERSION").." by mogli ---")

	self.mogliTexts = {}
	
	local l10nFilenamePrefixFull = Utils.getFilename("modDesc_l10n", directory);
	local langs = {"en", "de", g_languageShort};
	for _, lang in ipairs(langs) do
		local l10nFilename = l10nFilenamePrefixFull.."_"..lang..".xml";
		if fileExists(l10nFilename) then
			local l10nXmlFile = loadXMLFile("TempConfig", l10nFilename);
			local textI = 0;
			while true do
				local key = string.format("l10n.longTexts.longText(%d)", textI);
				if not hasXMLProperty(l10nXmlFile, key) then
					break;
				end;
				local name = getXMLString(l10nXmlFile, key.."#name");
				local text = getXMLString(l10nXmlFile, key);
				if name ~= nil and text ~= nil then
				--self.mogliTexts[name] = text:gsub("\r\n", "\n")
					self.i18n:setText( name, text:gsub("\r\n", "\n") )
				end;
				textI = textI+1;
			end;
			delete(l10nXmlFile);
		end
	end 
	
	local function handleText( self, xmlFile, key, tag )
		local value = self[tag]
		if value == nil then 
			return 
		end 
		local orig = getXMLString(xmlFile, key..'#'..tag)
		local i10n
		if orig ~= nil and orig:sub(1,6) == "$l10n_" then			
			i10n = g_i18n:getText(orig:sub(7))
		end 				
	--print( tostring(self.id)..' #'..tostring(tag)..': "'..tostring(value)..'", "'..tostring(orig)..'", "'..tostring(i10n)..'"' )
		if i10n ~= nil and i10n ~= "" then 
			self[tag] = i10n
		end 
	end 
		
	if g_client ~= nil then 
		local function loadGuiElement( self, xmlFile, key )		
			handleText( self, xmlFile, key, "toolTipText" )
		end
		
		local function loadTextElement( self, xmlFile, key )		
			handleText( self, xmlFile, key, "text" )
		end
		
		GuiElement.loadFromXML = Utils.appendedFunction( GuiElement.loadFromXML, loadGuiElement )
		TextElement.loadFromXML = Utils.appendedFunction( TextElement.loadFromXML, loadTextElement )
		
		-- settings screen
		g_gui:loadProfiles(Utils.getFilename("gui/guiProfiles.xml", self.vcaDirectory))

		g_vehicleControlAddonTabbedMenu = VehicleControlAddonMenu:new(g_messageCenter, self.i18n, g_gui.inputManager)
		
		g_vehicleControlAddonTabbedFrame1 = VehicleControlAddonFrame1:new(g_vehicleControlAddonTabbedMenu,self.i18n)
		g_vehicleControlAddonTabbedFrame2 = VehicleControlAddonFrame2:new(g_vehicleControlAddonTabbedMenu,self.i18n)
		g_vehicleControlAddonTabbedFrame3 = VehicleControlAddonFrame3:new(g_vehicleControlAddonTabbedMenu,self.i18n)
		g_vehicleControlAddonTabbedFrame4 = VehicleControlAddonFrame4:new(g_vehicleControlAddonTabbedMenu,self.i18n)
		g_vehicleControlAddonTabbedFrame5 = VehicleControlAddonFrame5:new(g_vehicleControlAddonTabbedMenu,self.i18n)
		g_vehicleControlAddonTabbedFrame6 = VehicleControlAddonFrame6:new(g_vehicleControlAddonTabbedMenu,self.i18n)
		
		g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame1.xml", self.vcaDirectory), "vehicleControlAddonFrame1", g_vehicleControlAddonTabbedFrame1, true)
		g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame2.xml", self.vcaDirectory), "vehicleControlAddonFrame2", g_vehicleControlAddonTabbedFrame2, true)
		g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame3.xml", self.vcaDirectory), "vehicleControlAddonFrame3", g_vehicleControlAddonTabbedFrame3, true)
		g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame4.xml", self.vcaDirectory), "vehicleControlAddonFrame4", g_vehicleControlAddonTabbedFrame4, true)
		g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame5.xml", self.vcaDirectory), "vehicleControlAddonFrame5", g_vehicleControlAddonTabbedFrame5, true)
		g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame6.xml", self.vcaDirectory), "vehicleControlAddonFrame6", g_vehicleControlAddonTabbedFrame6, true)
		g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonMenu.xml",   self.vcaDirectory), "vehicleControlAddonMenu", g_vehicleControlAddonTabbedMenu)
	end 
end;

function vehicleControlAddonRegister:loadMap(name)
	local configDir, configFile
	
	if g_server ~= nil then 
		self.isDedi = g_dedicatedServerInfo ~= nil  
		if self.isDedi then 
			if g_careerScreen and type( g_careerScreen.selectedIndex ) == "number" then 
				configFile = getUserProfileAppPath() .. "savegame" .. g_careerScreen.selectedIndex .. "/vehicleControlAddonConfig.xml"
			end 
			self.isMP = true 
		else 
			configDir  = getUserProfileAppPath().. "modsSettings/FS19_VehicleControlAddon"
			configFile = "config.xml" 
			
			if g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then 
				self.isMP = true 
			else 
				self.isMP = false 
			end 
		end 
	else 
		self.isMP   = true 
	end 
	
	local nameList ={ "cameraRotFactor",
										"cameraRotFactorRev",
										"cameraRotTime",
										"timer4Reverse",
										"limitThrottle",
										"snapAngle",
										"brakeForceFactor",
										"snapAngleHudX",
										"snapAngleHudY",
										"drawHud",
										"transmission",
										"clutchTimer",
										"debugPrint",
										"mouseAutoRotateBack",
										"rotInertiaFactor",
										"rotInertiaFactorLow",
										"rotInertiaFactorPS",
										"modifyPitch",
										"turnOffAWDSpeed",
										"minAuthShiftWait",
										"adaptiveSteering",
										"camOutsideRotation",
										"camInsideRotation",
										"camReverseRotation",
										"camRevOutRotation",
										"shuttleControl",
										"peekLeftRight",
										"hiredWorker",
										"hiredWorker2",
										"g27Mode",
										"blowOffVolume",
										"rotSpeedOut",
										"rotSpeedIn",
										"torqueCheatFactor1",
										"torqueCheatFactor2",
										"gearShiftSampleVol",
										"grindingSampleVol",
										"pitchFactor",
										"autoHoldTimer",
									}

	print('VCAregister; isMP: '..tostring(self.isMP)..', isDedi: '..tostring(self.isDedi)..', local config: "'..tostring(configFile)..'", local directory: "'..tostring(configDir)..'"')

	local fileDft = self.vcaDirectory.."vehicleControlAddonConfig.xml"
	vehicleControlAddon.globalsLoadNew( fileDft, configFile, nameList, "VCAGlobals", "VCAGlobals", "VCADefaults", configDir, true ) -- false for public version
	
	if not self.isMP then 
		vehicleControlAddonTransmissionBase.loadSettings()
	end 
end;

function vehicleControlAddonRegister:deleteMap()
  
end;

function vehicleControlAddonRegister:keyEvent(unicode, sym, modifier, isDown)

end;

function vehicleControlAddonRegister:mouseEvent(posX, posY, isDown, isUp, button)

end;

function vehicleControlAddonRegister:update(dt)
	
end;

function vehicleControlAddonRegister:draw()
  
end;

local function beforeLoadMission(mission)
	assert( g_vehicleControlAddon == nil )
	local base = vehicleControlAddonRegister:new( g_i18n )
	getfenv(0)["g_vehicleControlAddon"] = base
	addModEventListener(base);
end 

local function afterConnectionFinishedLoading(mission, connection, x,y,z, viewDistanceCoeff)
-- call on server after a client connected to the server 
-- send event with settings from server to new client 
  connection:sendEvent(vehicleControlAddon.createGlobalsEvent(false))
end 

local function newLoadSampleAttributesFromTemplate( self, superFunc, ... )
	local res = { superFunc( self, ... ) }
	print('========================================================')
	DebugUtil.printTableRecursively( {...}, "..", 1, 3 )
	print('--------------------------------------------------------')
	DebugUtil.printTableRecursively( res, "..", 1, 3 )
	return unpack( res ) 
end 

local function init()
  Mission00.load = Utils.prependedFunction(Mission00.load, beforeLoadMission)
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, postLoadMissionFinished)
	VehicleTypeManager.finalizeVehicleTypes = Utils.prependedFunction(VehicleTypeManager.finalizeVehicleTypes, vehicleControlAddonRegister.beforeFinalizeVehicleTypes)
	FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction( FSBaseMission.onConnectionFinishedLoading, afterConnectionFinishedLoading )
--SoundManager.loadSampleAttributesFromTemplate = Utils.overwrittenFunction( SoundManager.loadSampleAttributesFromTemplate, newLoadSampleAttributesFromTemplate )
end 

init()

