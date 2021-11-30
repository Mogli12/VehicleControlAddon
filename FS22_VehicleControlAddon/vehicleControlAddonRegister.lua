
local directory = g_currentModDirectory
local modName = g_currentModName
local specName = "zzzVehicleControlAddon"

VCAGlobals  = {
	cameraRotFactor     = 0.5,
	cameraRotFactorRev  = 0.3,
	cameraRotTime       = 0.001,
	limitThrottle       = 15, -- 9 => 90%/100% 15 => 100%/75% -->
	snapAngle           = 4,  -- 45° -->
	brakeForceFactor    = 0.25,
	snapAngleHudX       = -1, -- any value >= 0 => position of bottom left corner / -1 above HUD -->
	snapAngleHudY       = -1, -- any value >= 0 => position of bottom left corner / -1 above HUD -->
	drawHud             = true,
	mouseAutoRotateBack = false,
	turnOffAWDSpeed     = 30,-- km/h -->
	
	-- defaults -->
	adaptiveSteering    = false,
	camOutsideRotation  = 0,
	camInsideRotation   = 0,
	camReverseRotation  = false,
	camRevOutRotation   = false,
	peekLeftRight       = true,
	hiredWorker2        = false, -- differential for hired worker -->
	rotSpeedOut         = 0.5, 
	rotSpeedIn          = 0.5, 
}

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

local function beforeFinalizeTypes( typeManager )

	if vehicleControlAddon == nil then 
		print("Failed to add specialization vehicleControlAddon")
	else 
		local allTypes = typeManager:getTypes( )
		for k, typeDef in pairs(allTypes) do
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
	vehicleControlAddon.initSpecialization()

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
		
	if g_client ~= nil then 
		local function loadTextElement( self, xmlFile, key )		
			local id = getXMLString(xmlFile, key .. "#vcaTextID")
			if id ~= nil and g_i18n:hasText( id ) and type( self.setText ) == "function" then 
				self:setText( g_i18n:getText( id ) )
			end 
		end
		local function loadGuiElement( self, xmlFile, key )		
			local id = getXMLString(xmlFile, key .. "#vcaTextID")
			if id ~= nil and g_i18n:hasText( id ) and type( self.setText ) == "function" then 
				self:setText( g_i18n:getText( id ) )
			end 
		end
		
		local origTextElementLoadFromXML = TextElement.loadFromXML
		local origGuiElementLoadFromXML  = GuiElement.loadFromXML
		
		TextElement.loadFromXML = Utils.appendedFunction( origTextElementLoadFromXML, loadTextElement )
		GuiElement.loadFromXML  = Utils.appendedFunction( origGuiElementLoadFromXML, loadTextElement )
		
		local function loadVCAMenu()
			-- settings screen
			g_gui:loadProfiles(Utils.getFilename("gui/guiProfiles.xml", self.vcaDirectory))
			g_vehicleControlAddonMenu = VehicleControlAddonMenu:new()
			g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonMenu.xml",   self.vcaDirectory), "vehicleControlAddonMenu", g_vehicleControlAddonMenu)
		end 

		local state, result = pcall( loadVCAMenu )
		if not ( state ) then 
			print("Error loading VCA UI: "..tostring(result)) 
		end 
		
		TextElement.loadFromXML = origTextElementLoadFromXML
		GuiElement.loadFromXML  = origGuiElementLoadFromXML
	end 
end;

function vehicleControlAddonRegister:loadMap(name)
	local configDir, configFile
	
	if g_server ~= nil then 
		self.isDedi = g_dedicatedServerInfo ~= nil  
		if self.isDedi then 
			self.isMP = true 
		elseif g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then 
			self.isMP = true 
		else 
			self.isMP = false 
		end 
	else 
		self.isMP   = true 
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

local function init()
	Mission00.load = Utils.prependedFunction(Mission00.load, beforeLoadMission)
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, postLoadMissionFinished)
	TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, beforeFinalizeTypes)
end 

init()

