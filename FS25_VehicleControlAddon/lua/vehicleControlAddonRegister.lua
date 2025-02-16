
local directory = g_currentModDirectory
local modName = g_currentModName
local specName = "zzzVehicleControlAddon"

vehicleControlAddonRegister = {}

local vehicleControlAddonRegister_mt = Class(vehicleControlAddonRegister)

function vehicleControlAddonRegister.new( i18n )
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
	self.postLoadMissionDone = true 
	print("--- loading "..self.i18n:getText("vcaVERSION").." by mogli ---")
		
	if g_languageShort ~= "en" then
		l10nXmlFile = loadXMLFile("modL10n", Utils.getFilename("l10n/modDesc_l10n_en.xml",self.vcaDirectory))

		if l10nXmlFile ~= nil then
			local textI = 0

			while true do
				local key = string.format("l10n.texts.text(%d)", textI)

				if not hasXMLProperty(l10nXmlFile, key) then
					break
				end

				local name = getXMLString(l10nXmlFile, key .. "#name")
				local text = getXMLString(l10nXmlFile, key .. "#text")

				if name ~= nil and text ~= nil then
					if not g_i18n:hasModText(name) then
						print("Info (VCA): text "..tostring(name).." is not translated yet. Using English text.")
						g_i18n:setText(name, text:gsub("\r\n", "\n"))
					end
				end

				textI = textI + 1
			end

			delete(l10nXmlFile)
		end 
	end 		
end;

function vehicleControlAddonRegister:loadMap(name)
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
	
	self.configuration = vehicleControlAddonConfig.new()
	if g_server ~= nil then 
		self.configuration:load()
	end 
	vehicleControlAddon.initSpecialization()
end;

function vehicleControlAddonRegister:deleteMap()
  
end;

function vehicleControlAddonRegister:keyEvent(unicode, sym, modifier, isDown)

end;

function vehicleControlAddonRegister:mouseEvent(posX, posY, isDown, isUp, button)

end;

function vehicleControlAddonRegister:update(dt)

end

function vehicleControlAddonRegister:draw()
  
end;

local function beforeLoadMission(mission)
	assert( g_vehicleControlAddon == nil )
	local base = vehicleControlAddonRegister.new( g_i18n )
	getfenv(0)["g_vehicleControlAddon"] = base
	addModEventListener(base);
end 

local function afterConnectionFinishedLoading(mission, connection, x,y,z, viewDistanceCoeff)
-- call on server after a client connected to the server 
-- send event with settings from server to new client 
  connection:sendEvent(vehicleControlAddonConfigEvent.new(true))
end 

local function afterMissionInfoSaveToXMLFile()
	if g_server ~= nil then 
		g_vehicleControlAddon.configuration:save() 
	end 
end 

local function init()
	Mission00.load = Utils.prependedFunction(Mission00.load, beforeLoadMission)
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, postLoadMissionFinished)
	FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction( FSBaseMission.onConnectionFinishedLoading, afterConnectionFinishedLoading )
	TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, beforeFinalizeTypes)
	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction( FSCareerMissionInfo.saveToXMLFile, afterMissionInfoSaveToXMLFile )
end 

init()

