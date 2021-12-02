--
-- vehicleControlAddonConfig
--

local function compareSimple( a, b )
	return a==b 
end 
local function compareFloat( a, b )
	return math.abs( a - b ) < 1e-4 
end 

VCAValueType = {}
VCAValueType.bool   = { valueType = XMLValueType.BOOL,   emptyValue = false,streamRead=streamReadBool   , streamWrite=streamWriteBool   , getXML=getXMLBool  , setXML=setXMLBool  , compare=compareSimple }
VCAValueType.int16  = { valueType = XMLValueType.INT,    emptyValue = 0    ,streamRead=streamReadInt16  , streamWrite=streamWriteInt16  , getXML=getXMLInt   , setXML=setXMLInt   , compare=compareSimple }
VCAValueType.float  = { valueType = XMLValueType.FLOAT,  emptyValue = 0.0  ,streamRead=streamReadFloat32, streamWrite=streamWriteFloat32, getXML=getXMLFloat , setXML=setXMLFloat , compare=compareFloat }
VCAValueType.string = { valueType = XMLValueType.STRING, emptyValue = ""   ,streamRead=streamReadString , streamWrite=streamWriteString , getXML=getXMLString, setXML=setXMLString, compare=compareSimple }

local ConfigItems = {}
local ConfigItemIndex = {}
VCAGlobals  = {}

local function addConfigItem( name, configType, value )
	table.insert( ConfigItemIndex, name )
	ConfigItems[name] = { configType = configType, value = value }
	VCAGlobals[name]  = value 
end 

local function init()
	addConfigItem( "debugPrint"          , VCAValueType.bool  , false )
	
	addConfigItem( "cameraRotFactor"     , VCAValueType.float , 0.5   )
	addConfigItem( "cameraRotFactorRev"  , VCAValueType.float , 0.3   )
	addConfigItem( "cameraRotTime"       , VCAValueType.float , 0.001 )
	addConfigItem( "limitThrottle"       , VCAValueType.int16 , 15    ) -- 9 => 90%/100% 15 => 100%/75% -->
	addConfigItem( "snapAngle"           , VCAValueType.int16 , 4     ) -- 45° -->
	addConfigItem( "brakeForceFactor"    , VCAValueType.float , 0.25  )
	addConfigItem( "snapAngleHudX"       , VCAValueType.float , -1    ) -- any value >= 0 => position of bottom left corner / -1 above HUD -->
	addConfigItem( "snapAngleHudY"       , VCAValueType.float , -1    ) -- any value >= 0 => position of bottom left corner / -1 above HUD -->
	addConfigItem( "drawHud"             , VCAValueType.bool  , true  )
	addConfigItem( "mouseAutoRotateBack" , VCAValueType.bool  , false )
	addConfigItem( "turnOffAWDSpeed"     , VCAValueType.int16 , 30    ) -- km/h -->
	-- defaults --
	addConfigItem( "adaptiveSteering"    , VCAValueType.bool  , false )
	addConfigItem( "camOutsideRotation"  , VCAValueType.int16 , 0     )
	addConfigItem( "camInsideRotation"   , VCAValueType.int16 , 0     )
	addConfigItem( "camReverseRotation"  , VCAValueType.bool  , false )
	addConfigItem( "camRevOutRotation"   , VCAValueType.bool  , false )
	addConfigItem( "peekLeftRight"       , VCAValueType.bool  , true  )
	addConfigItem( "hiredWorker2"        , VCAValueType.bool  , false ) -- differential for hired worker -->
	addConfigItem( "rotSpeedOut"         , VCAValueType.float , 0.5   ) 
	addConfigItem( "rotSpeedIn"          , VCAValueType.float , 0.5   ) 
	addConfigItem( "idleThrottle"        , VCAValueType.bool  , false ) 
end 
init()

function vcaDebugPrint( ... )
	if VCAGlobals.debugPrint then
		print( ... )
	end
end 

vehicleControlAddonConfig = {}
local vehicleControlAddonConfig_mt = Class(vehicleControlAddonConfig)

function vehicleControlAddonConfig.new()
	self = {}
	setmetatable(self, vehicleControlAddonConfig_mt)
	return self 
end 

local function loadConfig( fileName )
	if fileName == nil or fileName == "" or not fileExists(fileName) then
		return false 
	end 
	vcaDebugPrint("VCA config: "..tostring(fileName))
	local xmlFile = loadXMLFile( "vehicleControlAddon", fileName, "vehicleControlAddon" )
	local i = 0
	while true do
		local xmlKey = string.format("vehicleControlAddon.configuration(%d)", i)
		i = i + 1
		local name = getXMLString( xmlFile, xmlKey.."#name" )
		if name == nil then 
			break
		end 
		item = ConfigItems[name]
		if item ~= nil then 
			local value = item.configType.getXML( xmlFile, xmlKey.."#value" )
			if value ~= nil then 
				vcaDebugPrint("VCAGlobals."..tostring(name).." = "..tostring(value))
				VCAGlobals[name] = value 
			end 
		end 
	end 
	delete( xmlFile )
	return true 
end 

local function saveConfig( fileName )
	if fileName == nil or fileName == "" then 
		return false 
	end 
	vcaDebugPrint("VCA config: "..tostring(fileName))
--if fileExists(fileName) then
--	getfenv(0).deleteFile(fileName)
--end 
	local xmlFile = createXMLFile( "vehicleControlAddon", fileName, "vehicleControlAddon" )
	local i = 0
  for name,item in pairs(ConfigItems) do 	
		if not item.configType.compare( VCAGlobals[name], item.value ) then 
			vcaDebugPrint("VCAGlobals."..tostring(name).." = "..tostring(VCAGlobals[name]))
			local xmlKey = string.format("vehicleControlAddon.configuration(%d)", i)
			i = i + 1
			setXMLString( xmlFile, xmlKey.."#name", name )
			item.configType.setXML( xmlFile, xmlKey.."#value", VCAGlobals[name] )
		end 
	end 
	saveXMLFile(xmlFile)
	delete( xmlFile )
	if fileExists(fileName) then
		vcaDebugPrint("VCA config saved")
		return true 
	end 
	return false 
end 

function vehicleControlAddonConfig:getSavegameFileName()
	if g_careerScreen and g_careerScreen.currentSavegame ~= nil and g_careerScreen.currentSavegame.savegameDirectory ~= nil then 
		return g_careerScreen.currentSavegame.savegameDirectory .. "/vehicleControlAddon.xml"
	end 
end 

function vehicleControlAddonConfig:getModSettingsFileName()
	return getUserProfileAppPath().. "modSettings/vehicleControlAddon.xml"
end 

function vehicleControlAddonConfig:load() 
	if not loadConfig( self:getSavegameFileName() ) and g_dedicatedServerInfo == nil then 
		loadConfig( self:getModSettingsFileName() )
	end 
end

function vehicleControlAddonConfig:save()
	if g_server == nil then 
		return 
	end 
	
	saveConfig( self:getSavegameFileName() )
	if g_dedicatedServerInfo == nil then 
		saveConfig( self:getModSettingsFileName() )
	end 
end 


vehicleControlAddonConfigEvent = {}
vehicleControlAddonConfigEvent_mt = Class(vehicleControlAddonConfigEvent, Event)
InitEventClass(vehicleControlAddonConfigEvent, "vehicleControlAddonConfigEvent")
function vehicleControlAddonConfigEvent.emptyNew()
  local self = Event.new(vehicleControlAddonConfigEvent_mt)
 	self.check1 = 244
	self.check2 = 108
	return self
end
function vehicleControlAddonConfigEvent.new(init)
  local self = vehicleControlAddonConfigEvent.emptyNew()
  return self
end
function vehicleControlAddonConfigEvent:readStream(streamId, connection)
	local check1 = streamReadUInt8(streamId)
	self.globals = {}
  for i,name in pairs( ConfigItemIndex ) do
		local item  = ConfigItems[name]
		self.globals[name] = item.configType.streamRead( streamId ) 
		vcaDebugPrint("Info: vehicleControlAddonConfigEvent received value "..tostring(self.globals[name]).." for state "..tostring(name))
	end
	local check2 = streamReadUInt8(streamId)
	
	if     check1 ~= self.check1 then 
		print("Error in vehicleControlAddonConfigEvent: Event has wrong start marker. Check other mods.")
	elseif check2 ~= self.check2 then 
		print("Error in vehicleControlAddonConfigEvent: Event has wrong end marker. ")
	else 
		self:run(connection)
	end 
end
function vehicleControlAddonConfigEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.check1 )
  for i,name in pairs( ConfigItemIndex ) do
		local item  = ConfigItems[name]
		item.configType.streamWrite( streamId, VCAGlobals[name] )
	end
	streamWriteUInt8(streamId, self.check2 )
end
function vehicleControlAddonConfigEvent:run(connection)
	if type( self.globals ) == "table" then 
		for name, value in pairs( self.globals ) do
			local old = VCAGlobals[name]
			VCAGlobals[name] = value
			local item = ConfigItems[name]
			if not item.configType.compare( old, value ) then 
				for _, vehicle in pairs(g_currentMission.vehicles) do
					if type( vehicle.vcaSetNewDefault ) == "function" then 
						vehicle:vcaSetNewDefault( name, old, value, true )
					end
				end
			end 
		end
	end 
  if not connection:getIsServer() then
    g_server:broadcastEvent( vehicleControlAddonConfigEvent.new(self.save), nil, connection, nil )
  end
end
