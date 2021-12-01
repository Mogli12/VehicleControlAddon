--
-- vehicleControlAddonConfig
--

VCAValueType = {}
VCAValueType.bool   = { valueType = XMLValueType.BOOL,   emptyValue = false,streamRead=streamReadBool   , streamWrite=streamWriteBool   , getXML=getXMLBool  , setXML=setXMLBool   }
VCAValueType.int16  = { valueType = XMLValueType.INT,    emptyValue = 0    ,streamRead=streamReadInt16  , streamWrite=streamWriteInt16  , getXML=getXMLInt   , setXML=setXMLInt    }
VCAValueType.float  = { valueType = XMLValueType.FLOAT,  emptyValue = 0.0  ,streamRead=streamReadFloat32, streamWrite=streamWriteFloat32, getXML=getXMLFloat , setXML=setXMLFloat  }
VCAValueType.string = { valueType = XMLValueType.STRING, emptyValue = ""   ,streamRead=streamReadString , streamWrite=streamWriteString , getXML=getXMLString, setXML=setXMLString }

local ConfigItems = {}
ConfigItems.debugPrint          = { configType = VCAValueType.bool  , value = false }

ConfigItems.cameraRotFactor     = { configType = VCAValueType.float , value = 0.5   }
ConfigItems.cameraRotFactorRev  = { configType = VCAValueType.float , value = 0.3   }
ConfigItems.cameraRotTime       = { configType = VCAValueType.float , value = 0.001 }
ConfigItems.limitThrottle       = { configType = VCAValueType.int16 , value = 15    } -- 9 => 90%/100% 15 => 100%/75% -->
ConfigItems.snapAngle           = { configType = VCAValueType.int16 , value = 4     } -- 45° -->
ConfigItems.brakeForceFactor    = { configType = VCAValueType.float , value = 0.25  }
ConfigItems.snapAngleHudX       = { configType = VCAValueType.float , value = -1    } -- any value >= 0 => position of bottom left corner / -1 above HUD -->
ConfigItems.snapAngleHudY       = { configType = VCAValueType.float , value = -1    } -- any value >= 0 => position of bottom left corner / -1 above HUD -->
ConfigItems.drawHud             = { configType = VCAValueType.bool  , value = true  }
ConfigItems.mouseAutoRotateBack = { configType = VCAValueType.bool  , value = false }
ConfigItems.turnOffAWDSpeed     = { configType = VCAValueType.int16 , value = 30,   } -- km/h -->
						-- defaults --       
ConfigItems.adaptiveSteering    = { configType = VCAValueType.bool  , value = false }
ConfigItems.camOutsideRotation  = { configType = VCAValueType.int16 , value = 0     }
ConfigItems.camInsideRotation   = { configType = VCAValueType.int16 , value = 0     }
ConfigItems.camReverseRotation  = { configType = VCAValueType.bool  , value = false }
ConfigItems.camRevOutRotation   = { configType = VCAValueType.bool  , value = false }
ConfigItems.peekLeftRight       = { configType = VCAValueType.bool  , value = true  }
ConfigItems.hiredWorker2        = { configType = VCAValueType.bool  , value = false } -- differential for hired worker -->
ConfigItems.rotSpeedOut         = { configType = VCAValueType.float , value = 0.5   } 
ConfigItems.rotSpeedIn          = { configType = VCAValueType.float , value = 0.5   } 

VCAGlobals  = {}
local function init()
	for name,item in pairs(ConfigItems) do 	
		VCAGlobals[name] = item.value 
	end
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
		local isNonDefault = false 
		if item.configType == VCAValueType.float then 
			isNonDefault = math.abs( VCAGlobals[name] - item.value ) > 1e-4
		elseif VCAGlobals[name] ~= item.value then 
			isNonDefault = true 
		end 
		if isNonDefault then 
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
  return self
end
function vehicleControlAddonConfigEvent.new(init)
  local self = vehicleControlAddonConfigEvent.emptyNew()
	if init then 
		self.init = true 
	else 
		self.init = false 
	end 
  return self
end
function vehicleControlAddonConfigEvent:readStream(streamId, connection)
	self.init = streamReadBool( streamId )
	local count = streamReadInt16( streamId )
  for i=1,count do 
		local name = streamReadString( streamId )
		local item = ConfigItems[name]
		VCAGlobals[name] = item.configType.streamRead( streamId )
	end
  self:run(connection)
end
function vehicleControlAddonConfigEvent:writeStream(streamId, connection)
	streamWriteBool( streamId, self.init )
	streamWriteInt16( streamId, #ConfigItems )
  for name,item in pairs(ConfigItems) do 	
		streamWriteString( streamId, name )
		item.configType.streamWrite( streamId, VCAGlobals[name] )
	end
end
function vehicleControlAddonConfigEvent:run(connection)
  if self.init then 
		if not ( vehicleControlAddon.initSpecializationDone ) then 
			vehicleControlAddon.initSpecialization()
		end 
	end 
  if not connection:getIsServer() then
    g_server:broadcastEvent( vehicleControlAddonConfigEvent.new(self.save), nil, connection, nil )
  end
end
