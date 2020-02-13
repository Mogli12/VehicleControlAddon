
local directory = g_currentModDirectory
local modName = g_currentModName
local specName = "zzzVehicleControlAddon"

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
			if typeDef ~= nil and k ~= "locomotive" then 
				local isDrivable   = false
				local isEnterable  = false
				local hasMotor     = false 
				local hasLights    = false 
				local hasWheels    = false 
				local isAttachable = false 
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
					elseif name == specName then 
						hasNotVCA = false 
					end 
				end 
				if hasNotVCA and isDrivable and isEnterable and hasMotor and hasLights and hasWheels and not isAttachable then 
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

		if false then 
			g_vehicleControlAddonScreen = vehicleControlAddonScreen:new()
			g_gui:loadGui(self.vcaDirectory .. "vehicleControlAddonScreen.xml", "vehicleControlAddonScreen", g_vehicleControlAddonScreen)	
			g_vehicleControlAddonScreen:setTitle( "vcaVERSION" )
		else 
			g_vehicleControlAddonTabbedMenu = VehicleControlAddonMenu:new(g_messageCenter, self.i18n, g_gui.inputManager)

			g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame1.xml", self.vcaDirectory), "vehicleControlAddonFrame1", VehicleControlAddonFrame1:new(g_vehicleControlAddonTabbedMenu,self.i18n), true)
			g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame2.xml", self.vcaDirectory), "vehicleControlAddonFrame2", VehicleControlAddonFrame2:new(g_vehicleControlAddonTabbedMenu,self.i18n), true)
			g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame3.xml", self.vcaDirectory), "vehicleControlAddonFrame3", VehicleControlAddonFrame3:new(g_vehicleControlAddonTabbedMenu,self.i18n), true)
			g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonFrame4.xml", self.vcaDirectory), "vehicleControlAddonFrame4", VehicleControlAddonFrame4:new(g_vehicleControlAddonTabbedMenu,self.i18n), true)
			g_gui:loadGui(Utils.getFilename("gui/vehicleControlAddonMenu.xml",   self.vcaDirectory), "vehicleControlAddonMenu", g_vehicleControlAddonTabbedMenu)
		end 
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
	print("VCA beforeLoadMission")
	assert( g_vehicleControlAddon == nil )
	local base = vehicleControlAddonRegister:new( g_i18n )
	getfenv(0)["g_vehicleControlAddon"] = base
	addModEventListener(base);
end 

local function init()
	print("VCA init")
  Mission00.load = Utils.prependedFunction(Mission00.load, beforeLoadMission)
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, postLoadMissionFinished)
	VehicleTypeManager.finalizeVehicleTypes = Utils.prependedFunction(VehicleTypeManager.finalizeVehicleTypes, vehicleControlAddonRegister.beforeFinalizeVehicleTypes)
end 

init()

