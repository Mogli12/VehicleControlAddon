--
-- mogliBasics
-- This is the specialization for mogliBasics
--
-- change log
-- 2.01 initial 2.0 version 
-- 2.02 bug fix .../mogliBase30.lua:326: attempt to index field 'mbConfigHandler20' (a nil value) 
-- 2.03 bug fix forgot to rename mogliBase201Event 
-- 2.04 getText with default text
-- 3.01 initial 3.0 version: use g_currentModDirectory as part of the class name
-- 3.02 bug fix local functions / use local class instead
-- 3.03 input binding: check if shift/alt/crtl is pressed
-- 3.04 hide warnings of missing input bindings
-- 3.05 string support in globalsLoad
-- 3.06 degrees support in globalsLoad
-- 3.10 FS17 version
-- 3.11 postLoad to load old savegame
-- 3.12 getUiScale
-- 3.13 getUiScale (2)
-- 3.14 printCallStack
-- 3.15 more robust event handling
-- 3.16 show call stack if self.object is invalid
-- 3.17 log output in globalsLoad 
-- 3.18 sync events instead of readStream / writeStream  
-- 3.19 missing syncs in SP and MP
-- 3.20 WARNING: undefined input in gearboxMogli:  
-- 4.00 FS19

-- Usage:  source(Utils.getFilename("mogliBase.lua", g_currentModDirectory));
--         _G[g_currentModDirectory.."mogliBase"].newClass( "AutoCombine", "acParameters" )

local mogliBaseVersion   = 4.00
local mogliBaseClass     = g_currentModName..".mogliBase"
local mogliEventClass    = g_currentModName..".mogliEvent"
local mogliSyncRequest   = g_currentModName..".mogliSyncRequest"
local mogliSyncReply     = g_currentModName..".mogliSyncReply"
--local mogliEventClass_mt = g_currentModDirectory.."mogliEvent_mt"

if _G[mogliBaseClass] ~= nil and _G[mogliBaseClass].version ~= nil and _G[mogliBaseClass].version >= mogliBaseVersion then
	print("Factory class "..tostring(mogliBaseClass).." already exists in version "..tostring(_G[mogliBaseClass].version))
else
	local mogliBase30 = {}

	mogliBase30.version = mogliBaseVersion
	
	--print(mogliBaseClass..", version "..tostring(mogliBase30.version)..", located in "..g_currentModDirectory)

--=======================================================================================
-- class mogliBase30Event
--=======================================================================================	
	local mogliBase30Event = {} 
	local mogliBase30Request = {}
	local mogliBase30Reply = {}
	
--=======================================================================================
-- mogliBase30.checkForKeyModifiers
--=======================================================================================
	function mogliBase30.checkForKeyModifiers( keys )
		local modifiers = {}
		for keyId,bool in pairs( Input.keyIdIsModifier ) do
			modifiers[keyId] = true
		end
		for _, keyId in pairs(keys) do
			modifiers[keyId] = false
		end
		for keyId,bool in pairs(modifiers) do
			if bool and Input.isKeyPressed( keyId ) then
			--print("Modifier is pressed: "..tostring(Input.keyIdToIdName[keyId]))
				return false
			end
		end
		return true
	end
		
--=======================================================================================
-- mogliBase30.newclass
--=======================================================================================
	function mogliBase30.newClass( _globalClassName_, _level0_ )
		local _newClass_ = {}
		
		--print("Creating new global class in "..g_currentModDirectory.." with name ".._globalClassName_..". Prefix is: "..tostring(_level0_))

		_newClass_.baseDirectory = g_currentModDirectory
		_newClass_.modsDirectory = g_modsDirectory.."/"

	--********************************
	-- globalsReset
	--********************************
		function _newClass_.globalsReset( createIfMissing )
		end

	--********************************
	-- globalsLoad
	--********************************
		function _newClass_.globalsLoad( file , rootTag, globals, writeLog )	

			local xmlFile = loadXMLFile( "mogliBasics", file, rootTag )
			_newClass_.globalsLoad2( xmlFile , rootTag, globals, writeLog )	
		end
		
	--********************************
	-- globalsLoad2
	--********************************
		function _newClass_.globalsLoad2( xmlFile , rootTag, globals, writeLog )	

			local wl = true
			for name,value in pairs(globals) do
				local tp = getXMLString(xmlFile, rootTag.."." .. name .. "#type")
				local tm = 1
				if     tp == nil then
					tm = 0
				elseif tp == "bool" then
					local bool = getXMLBool( xmlFile, rootTag.."." .. name .. "#value" )
					if bool ~= nil then
						globals[name] = bool
					end
				elseif tp == "float" then
					local float = getXMLFloat( xmlFile, rootTag.."." .. name .. "#value" )
					if float ~= nil then globals[name] = float end
		--			print(file..": "..name.." = "..tostring(globals[name]))
				elseif tp == "degree" then
					local float = getXMLFloat( xmlFile, rootTag.."." .. name .. "#value" )
					if float ~= nil then globals[name] = math.rad( float ) end
		--			print(file..": "..name.." = "..tostring(globals[name]))
				elseif tp == "int" then
					local int = getXMLInt( xmlFile, rootTag.."." .. name .. "#value" )
					if int ~= nil then globals[name] = int end
		--			print(file..": "..name.." = "..tostring(globals[name]))
				elseif tp == "string" then
					local str = getXMLString( xmlFile, rootTag.."." .. name .. "#value" )
					if str ~= nil then globals[name] = str end
		--			print(file..": "..name.." = "..tostring(globals[name]))
				else
					tm = 2
					print(file..": "..name..": invalid XML type : "..tp)
				end
				if writeLog and tm > 0 then
					if wl then
						wl = false
						print('Loading settings from "'..tostring(file)..'"')
					end
					if tm == 1 then
						print('    <'..name..' type="'..tostring(tp)..'" value="'..tostring(globals[name])..'"/>')
					else
						print('    <'..name..' .../>: invalid XML type : '..tostring(tp))
					end
				end
			end
		end

	--********************************
	-- getUiScale
	--********************************
		function _newClass_.getUiScale()
			-- compatibility < patch 1.3
			if g_uiScale ~= nil and 0 < g_uiScale and g_uiScale < 2 then
				return g_uiScale
			end
			-- patch 1.3 and above
			local uiScale = 1.0
			if g_gameSettings ~= nil and g_gameSettings.getValue ~= nil then
					uiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"), 1.0)
			end
			return uiScale 
		end
		
	--********************************
	-- getText
	--********************************
		function _newClass_.getText(id, default)
			if id == nil then
				return "nil";
			end;
			
			if g_i18n:hasText( id ) then
				return g_i18n:getText( id )
			end
			
			if default ~= nil then	
				return default 
			end
			
			return id
		end;

	--********************************
	-- normalizeAngle
	--********************************
		function _newClass_.normalizeAngle( angle )
			local normalizedAngle = angle
			while normalizedAngle > math.pi do
				normalizedAngle = normalizedAngle - math.pi - math.pi
			end 
			while normalizedAngle <= -math.pi do
				normalizedAngle = normalizedAngle + math.pi + math.pi
			end
			return normalizedAngle
		end

	--********************************
	-- mbClamp
	--********************************
		function _newClass_.mbClamp( v, minV, maxV )
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

	--********************************
	-- getSaveAttributesAndNodes
	--********************************
	--function _newClass_:saveStatsToXMLFile(xmlFile, key)
		function _newClass_:saveToXMLFile(xmlFile, key)
			if self[_globalClassName_.."StateHandler"] ~= nil then		
				local i = 0
				for level1,state in pairs( self[_globalClassName_.."StateHandler"] ) do
					if state.save then
						local value = _newClass_.mbGetState( self, level1 )
						
						if value ~= nil and ( state.default == nil or not mogliBase30.compare( state.default, value ) ) then
							local vType  = mogliBase30.getValueType( value )
							local xmlKey = string.format("%s.state(%d)", key, i)
							i = i + 1
							setXMLString(xmlFile, xmlKey.."#name", HTMLUtil.encodeToHTML(level1))
							setXMLString(xmlFile, xmlKey.."#type", HTMLUtil.encodeToHTML(vType))
							
							if     vType == "string"  then 
								setXMLString(xmlFile, xmlKey.."#value", HTMLUtil.encodeToHTML(value))
							elseif vType == "int8"    
									or vType == "int32" then   
								setXMLInt(xmlFile, xmlKey.."#value", value)
							elseif vType == "float32" 
									or vType == "number"  then 
								setXMLFloat(xmlFile, xmlKey.."#value", value)
							elseif vType == "boolean" then 
								setXMLBool(xmlFile, xmlKey.."#value", value)
							end
						end
					end
				end	
			end		
		end;

	--********************************
	-- loadFromAttributesAndNodes
	--********************************
		function _newClass_:onPostLoad(samegame)
			if savegame ~= nil then
				local xmlFile = savegame.xmlFile
				local key     = savegame.key
				local i = 0
				while true do
					local xmlKey = string.format("%s.%s.state(%d)", key, _globalClassName_, i)
					i = i + 1
					local level1 = HTMLUtil.decodeFromHTML(getXMLString(xmlFile, xmlKey.."#name"))
					if level1 == nil then
						break
					end
					local vType = HTMLUtil.decodeFromHTML(getXMLString(xmlFile, xmlKey.."#type"))
					local value = nil
					if     vType == nil then
					elseif vType == "string"  then 
						value = HTMLUtil.decodeFromHTML(getXMLString(xmlFile, xmlKey.."#value"))
					elseif vType == "int8"    
							or vType == "int32" then 
						value = getXMLInt(xmlFile, xmlKey.."#value")
					elseif vType == "float32" 
							or vType == "number"  then 
						value = getXMLFloat(xmlFile, xmlKey.."#value")
					elseif vType == "boolean" then 
						value = getXMLBool(xmlFile, xmlKey.."#value")
					end
					
				--print(tostring(xmlKey).." "..tostring(level1).." "..tostring(vType).." "..tostring(value))
					
					if value ~= nil then
						_newClass_.mbSetState( self, level1, value, true)
					end
				end
			end
		end

	--********************************
	-- initStateHandling
	--********************************
		function _newClass_:initStateHandling( )
			if self == nil then
				_newClass_:debugEvent( "initStateHandling" )
			end
			if self[_globalClassName_.."ConfigHandler"] == nil then
				self[_globalClassName_.."ConfigHandler"] = {}
			end
			if self[_globalClassName_.."StateHandler"] == nil then
				self[_globalClassName_.."StateHandler"] = {}
			end
			if _level0_ ~= nil and _level0_ ~= "" and self[_level0_] == nil then
				self[_level0_] = {}
			end
		end
		
	--********************************
	-- getValueType
	--********************************
		function _newClass_.getValueType( value )
			return mogliBase30.getValueType( value )
		end

	--********************************
	-- mbSetStateInternal
	--********************************
		function _newClass_:mbSetStateInternal(level1, value)
			if _level0_ == nil or _level0_ == "" then
				self[level1] = value 	
			else
				if self[_level0_] == nil then
					self[_level0_] = {}
				end
				self[_level0_][level1] = value 	
			end
		end
		
	--********************************
	-- registerState
	--********************************
		function _newClass_:registerServerField( level1 )
			_newClass_.initStateHandling( self )
			self[_globalClassName_.."ConfigHandler"][level1] = true
		end
		
	--********************************
	-- mbGetState
	--********************************
		function _newClass_:mbGetState(level1)
			if _level0_ == nil or _level0_ == "" then
				return self[level1]
			end
			if self[_level0_] == nil then
				return nil
			end
			return self[_level0_][level1]
		end
		
	--********************************
	-- registerState
	--********************************
		function _newClass_:registerState( level1, default, handler, saveAttribute )
			_newClass_.initStateHandling( self )
			self[_globalClassName_.."StateHandler"][level1] = {}
			if default ~= nil then
				self[_globalClassName_.."StateHandler"][level1].default = default 
				_newClass_.mbSetStateInternal(self,level1,default)
			end
			if handler ~= nil then
				self[_globalClassName_.."StateHandler"][level1].handler = handler
			end
			self[_globalClassName_.."StateHandler"][level1].save = saveAttribute
		end
		
	--********************************
	-- mbSetState
	--********************************
		function _newClass_:mbSetState(level1, value, noEventSend)
		--if not _newClass_.mbIsSynced( self ) then return end
			_newClass_.initStateHandling( self )
			
			if self[_globalClassName_.."StateHandler"][level1] == nil then
				_newClass_.registerState( self, level1 )
			end
			
			local old = _newClass_.mbGetState( self, level1 )
			if     old == nil or not ( mogliBase30.compare( old, value ) ) then			
				if self[_globalClassName_.."StateHandler"][level1].handler ~= nil then
					local noEventSend2 = true 
					if self.isServer then
						noEventSend2 = noEventSend 
					end 
					
					local state, message = pcall( self[_globalClassName_.."StateHandler"][level1].handler, self, old, value, noEventSend2 )
					if not state then
						print("Error: "..tostring(message)) 
						_newClass_.debugEvent( self, self[level1], value, noEventSend ) 
						_newClass_.mbSetStateInternal(self, level1, value)
					end
				else
					_newClass_.mbSetStateInternal(self, level1, value)
				end 	
				
				if noEventSend == nil or noEventSend == false then
					local eventObject = mogliBase30Event:new(_globalClassName_, self, level1, value)
					if g_server ~= nil then 
						g_server:broadcastEvent( eventObject ) 
					else
						_newClass_.mbSync( self )
						g_client:getServerConnection():sendEvent( eventObject ) 
					end 
				end 										
			end 	
		end 

	--********************************
	-- toMbDocument
	--********************************
		function _newClass_:toMbDocument()
			local mbDocument  = {}		

			if self[_globalClassName_.."ConfigHandler"] ~= nil then		
				mbDocument.config = {}
				for level1,state in pairs( self[_globalClassName_.."ConfigHandler"] ) do
					mbDocument.config[level1] = _newClass_.mbGetState( self, level1 )
				end
			end

			if self[_globalClassName_.."StateHandler"] ~= nil then			
				mbDocument.state  = {}
				for level1,state in pairs( self[_globalClassName_.."StateHandler"] ) do
					mbDocument.state[level1] = _newClass_.mbGetState( self, level1 )
				end
			end
			
			return mbDocument
		end
		
	--********************************
	-- fromMbDocument
	--********************************
		function _newClass_:fromMbDocument( mbDocument )
			if mbDocument.config ~= nil then
				for level1,value in pairs( mbDocument.config ) do
					_newClass_.mbSetStateInternal(self, level1, value)
				end
			end
			
			if mbDocument.state ~= nil then
				for level1,value in pairs( mbDocument.state ) do
					_newClass_.mbSetState(self, level1, value, true)
				end
			end
		end
		
	--********************************
	-- readStream
	--********************************
		function _newClass_:readStream(streamId, connection)
		--print(tostring(_globalClassName_).." / "..tostring(self.configFileName)..": synced via readStream")
			local mbDocument, pos, err = "", 0, ""
			local mode = streamReadString( streamId )
			--print("readStream using mode: "..tostring(mode))
			if     mode == "nil"  then
				mbDocument = {}
			else
				err, mbDocument = mogliBase30.readStreamEx( streamId )
				if err ~= _globalClassName_ then
					print("Error: '".._globalClassName_.."' expected")
					mbDocument = {}
				end
			end
			
			_newClass_.fromMbDocument( self, mbDocument )
			self[_globalClassName_.."SyncRequested"] = true
			self[_globalClassName_.."SyncReceived"]  = true
		end 
		 
	--********************************
	-- writeStream
	--********************************
		function _newClass_:writeStream(streamId, connection)

			if      self[_globalClassName_.."ConfigHandler"] == nil
					and self[_globalClassName_.."StateHandler"]  == nil then
				streamWriteString( streamId, "nil" )
			else
				streamWriteString( streamId, "no json" )
				mogliBase30.writeStreamEx( streamId, _globalClassName_, _newClass_.toMbDocument( self ) )
			end
		end 

	--********************************
	-- printCallStack
	--********************************
		function _newClass_:printCallStack( depth )
			mogliBase30.printCallStack( depth )
		end 

	--********************************
	-- debugEvent
	--********************************
		function _newClass_:debugEvent( old, new, noEventSend )
			_newClass_.printCallStack( self )
			print(tostring(old).." "..tostring(new).." "..tostring(noEventSend)) 
		end 
	--********************************
	-- mogliBaseTestStream
	--********************************
		function _newClass_:mogliBaseTestStream( )
			if      self[_globalClassName_.."ConfigHandler"] == nil
					and self[_globalClassName_.."StateHandler"]  == nil then
				return
			end
			if g_client ~= nil then
				self[_globalClassName_.."SyncReceived"] = nil
				g_client:getServerConnection():sendEvent(mogliBase30Request:new( _globalClassName_, self ),true)
			end
		end	
		
		function _newClass_:mbSync()
			if self == nil then
				print("Error: moglieBase.mbSync called with self == nil")
				mogliBase30.printCallStack()
				return 
			end
			if g_server ~= nil then
				self[_globalClassName_.."SyncReceived"]  = true
			end
			if      self[_globalClassName_.."ConfigHandler"] == nil
					and self[_globalClassName_.."StateHandler"]  == nil then
				return
			end
			if self[_globalClassName_.."SyncConnections"] ~= nil then
				local temp = self[_globalClassName_.."SyncConnections"]
				self[_globalClassName_.."SyncConnections"] = nil
				for connection,doit in pairs(temp) do
					connection:sendEvent(mogliBase30Reply:new( _globalClassName_, self ),true)
				end
			end
			if not ( self[_globalClassName_.."SyncRequested"] ) then
				self[_globalClassName_.."SyncRequested"] = true
				if g_server == nil then
					g_client:getServerConnection():sendEvent(mogliBase30Request:new( _globalClassName_, self ),true)
				end
			end
		end
		
		function _newClass_:mbIsSynced()
			if g_server ~= nil then
				return true
			end
			if self == nil then
				print("Error: moglieBase.mbIsSynced called with self == nil")
				mogliBase30.printCallStack()
				return 
			end
			if self[_globalClassName_.."SyncReceived"] then
				return true
			end
			return false
		end
		
		
		_G[_globalClassName_] = _newClass_ 
	end
		
--=======================================================================================
-- mogliBase30.printCallStack
--=======================================================================================
	function mogliBase30.printCallStack( depth )
		if debug == nil then return end 
		local i = 2 
		local d = 10
		if type( depth ) == "number" and depth > 1 then
			d = depth
		end
		local info 
		print("------------------------------------------------------------------------") 
		while i <= d do
			info = debug.getinfo(i) 
			if info == nil then break end
			print(string.format("%i: %s (%i): %s", i, info.short_src, Utils.getNoNil(info.currentline,0), Utils.getNoNil(info.name,"<???>"))) 
			i = i + 1 
		end
		if info ~= nil and info.name ~= nil and info.currentline ~= nil then
			print("...") 
		end
		print("------------------------------------------------------------------------") 
	end 
		
--=======================================================================================
-- mogliBase30.writeStreamTypedValue
--=======================================================================================
	function mogliBase30.writeStreamTypedValue( streamId, valueType, value )
		if     valueType == "string"  then
			streamWriteString(streamId, value) 
		elseif valueType == "int32"   then
			streamWriteInt32(streamId, value) 
		elseif valueType == "int8"    then
			streamWriteInt8(streamId, value) 
		elseif valueType == "float32" 
				or valueType == "number"  then
			streamWriteFloat32(streamId, value)  
		elseif valueType == "boolean" then
			streamWriteBool(streamId, value) 
		else 
			streamWriteString(streamId,tostring(value))
		end		
	end

--=======================================================================================
-- mogliBase30.readStreamTypedValue
--=======================================================================================
	function mogliBase30.readStreamTypedValue( streamId, valueType )
		local value = nil
		if     valueType == "string"  then
			value = streamReadString(streamId) 
		elseif valueType == "int32"   then
			value = streamReadInt32(streamId) 
		elseif valueType == "int8"    then
			value = streamReadInt8(streamId) 
		elseif valueType == "float32" 
				or valueType == "number"  then
			value = streamReadFloat32(streamId) 
		elseif valueType == "boolean" then
			value = streamReadBool(streamId) 
		else
			value = streamReadString(streamId) 
		end
		return value
	end 
	
--=======================================================================================
-- mogliBase30.writeStreamType
--=======================================================================================
	function mogliBase30.writeStreamType( streamId, valueType )
		local uint2
		if     valueType == "nil"     then uint2 = 1
		elseif valueType == "string"  then uint2 = 2 
		elseif valueType == "int8"    then uint2 = 3
		elseif valueType == "int32"   then uint2 = 4
		elseif valueType == "float32" then uint2 = 5
		elseif valueType == "number"  then uint2 = 6
		elseif valueType == "boolean" then uint2 = 7
		elseif valueType == "table"   then uint2 = 8
		else
			print("ERROR in server coding of mogliBase.lua: unknown type: "..tostring(valueType))
			return false			
		end
		--print("MP-INFO: "..valueType.." / "..tostring(uint2))
		streamWriteUInt8( streamId, uint2 )
		return true
	end
	
--=======================================================================================
-- mogliBase30.readStreamType
--=======================================================================================
	function mogliBase30.readStreamType( streamId, debugPrint )
		local uint2 = streamReadUInt8( streamId ) 
		if     uint2 == 1 then valueType = "nil"     
		elseif uint2 == 2 then valueType = "string"  
		elseif uint2 == 3 then valueType = "int8"    
		elseif uint2 == 4 then valueType = "int32"   
		elseif uint2 == 5 then valueType = "float32" 
		elseif uint2 == 6 then valueType = "number"  
		elseif uint2 == 7 then valueType = "boolean" 
		elseif uint2 == 8 then valueType = "table"   
		else
			print("ERROR in client coding of mogliBase.lua: unknown type: "..tostring(uint2))
			return nil			
		end
		if debugPrint then
			print("MP-INFO: "..valueType.." / "..tostring(uint2))
		end
		return valueType
	end
	
--=======================================================================================
-- mogliBase30.writeStreamEx
--=======================================================================================
	function mogliBase30.writeStreamEx( streamId, name, value )
		local nameType  = mogliBase30.getValueType( name )
		
		if      nameType ~= "string"
				and nameType ~= "int8"
				and nameType ~= "int32"
				and nameType ~= "float32"
				and nameType ~= "number"
				and nameType ~= "boolean" then
			return false
		end 
		
		local valueType = mogliBase30.getValueType( value )
		
		if      valueType ~= "nil"
				and valueType ~= "string"
				and valueType ~= "int8"
				and valueType ~= "int32"
				and valueType ~= "float32"
				and valueType ~= "number"
				and valueType ~= "boolean"
				and valueType ~= "table" then
			return false			
		end
		
		mogliBase30.writeStreamType( streamId, nameType ) 
		mogliBase30.writeStreamType( streamId, valueType ) 
		mogliBase30.writeStreamTypedValue( streamId, nameType, name )
		
		--print("MP-INFO: Writing server field "..tostring(name).."("..nameType..") of type "..valueType..":")
		
		if     valueType == "nil"   then
		elseif valueType ~= "table" then
			mogliBase30.writeStreamTypedValue( streamId, valueType, value )
			--print("MP-INFO: ...and value "..tostring(value))
		else			
			local tableGetn = 0
			for n,v in pairs( value ) do
				tableGetn = tableGetn + 1
			end
			streamWriteInt32( streamId, tableGetn )
			--print("MP-INFO: ...and "..tostring( tableGetn ).." elements")
			if tableGetn > 0 then
				for n,v in pairs( value ) do
					mogliBase30.writeStreamEx( streamId, n, v )
				end
			end
		end 
		
		return true 
	end
	
--=======================================================================================
-- mogliBase30.readStreamEx
--=======================================================================================
	function mogliBase30.readStreamEx( streamId, debugPrint )
		local nameType  = mogliBase30.readStreamType( streamId, debugPrint )		
		local valueType = mogliBase30.readStreamType( streamId, debugPrint )
		local name      = mogliBase30.readStreamTypedValue( streamId, nameType )
			
		if debugPrint then
			print("MP-INFO: Reading server field "..tostring(name).."("..nameType..") of type "..valueType..":")
		end
		
		local value
		if     valueType == "nil"   then
			value = nil
		elseif valueType ~= "table" then
			value = mogliBase30.readStreamTypedValue( streamId, valueType )
			if debugPrint then
				print("MP-INFO: ...and value "..tostring(value))
			end
		else 
			value = {}
			local tableGetn = streamReadInt32( streamId ) 
			if debugPrint then
				print("MP-INFO: ...and "..tostring(tableGetn).." elements")
			end
			for i=1,tableGetn do
				n,v = mogliBase30.readStreamEx( streamId, debugPrint )
				value[n] = v
			end
		end
		
		return name,value 
	end
			
--=======================================================================================
-- mogliBase30.getValueType
--=======================================================================================
	function mogliBase30.getValueType( value )

		if value == nil then
			return "string"
		end

		local valueType = type( value )
		
		if valueType == "number" then
			local n = value
			if      n > -128 
					and n < 127 
					and n - math.floor( n ) < 1E-6 then
				valueType = "int8"
			elseif  n > -2e9
					and n < 2e9
					and n - math.floor( n ) < 1E-6 then
				valueType = "int32"
			else
				valueType = "float32"
			end
		end
		
		return valueType
	end

--=======================================================================================
-- mogliBase30.compare
--=======================================================================================
	function mogliBase30.compare( value1, value2 )
		if ( value1 == nil and value2 ~= nil ) or ( value1 ~= nil and value2 == nil ) then
			return false
		end
		if value1 == nil and value2 == nil then
			return true
		end
		local vt1 = mogliBase30.getValueType( value1 ) 
		local vt2 = mogliBase30.getValueType( value2 )
		if vt1 == "table" and vt2 == "table" then
			local c1 = 0
			local c2 = 0
			for n,v in pairs( value1 ) do
				c1 = c1 + 1
				if not ( mogliBase30.compare( v, value2[n] ) ) then 
					return false
				end
			end
			for n,v in pairs( value2 ) do
				c2 = c2 + 1
				if v ~= nil and value1[n] == nil then
					return false 
				end
			end
			if c1 ~= c2 then
				return false
			end
			return true
		elseif vt1 == vt2 then
			return value1 == value2 
		elseif  ( vt1 == "int8" or vt1 == "int32" )
				and ( vt2 == "int8" or vt2 == "int32" ) then
			return value1 == value2 
		elseif  ( vt1 == "number" or vt1 == "int8" or vt1 == "int32" or vt1 == "float32" )
				and ( vt2 == "number" or vt2 == "int8" or vt2 == "int32" or vt2 == "float32" ) then
			local m = math.max( math.abs( value1 ), math.abs( value2 ) )
			if m < 1E-12 then
				return true
			elseif math.abs( value1 - value2 ) > 1E-6 * m then
				return false
			end
			return true
		end
					
		return false
	end
	
	_G[mogliBaseClass] = mogliBase30
	
	local mogliBase30Event_mt = Class(mogliBase30Event, Event) 
	InitEventClass(mogliBase30Event, mogliEventClass) 

--=======================================================================================
-- mogliBase30Event:emptyNew
--=======================================================================================
	mogliBase30Event.emptyNew = function(self)
		local self = Event:new(mogliBase30Event_mt) 
		return self 
	end 
	
--=======================================================================================
-- mogliBase30Event:new
--=======================================================================================
	mogliBase30Event.new = function(self, className, object, level1, value)
		local self = mogliBase30Event:emptyNew() 
		self.className = className
		self.object    = object 
		self.level1    = level1 
		self.value     = value 
		return self 
	end 
	

--=======================================================================================
-- readStream
--=======================================================================================
	mogliBase30Event.readStream = function(self, streamId, connection)
		self.object    = NetworkUtil.readNodeObject( streamId )				
		self.className = streamReadString(streamId)
		self.level1, self.value = _G[mogliBaseClass].readStreamEx( streamId )
		self:run(connection) 
	end 
	
--=======================================================================================
-- writeStream
--=======================================================================================
	mogliBase30Event.writeStream = function(self, streamId, connection)
		--both clients and server can send this event
		NetworkUtil.writeNodeObject( streamId, self.object )
		streamWriteString(streamId, self.className )
		_G[mogliBaseClass].writeStreamEx( streamId, self.level1, self.value )
	end 
	
--=======================================================================================
-- run
--=======================================================================================
	mogliBase30Event.run = function(self, connection)
		----both clients and server can "run" this event (after reading it)	
		if self.object == nil or self.className == nil or self.className == "" then
			print("Error running event: nil ("..tostring(self.className)..")")
			return 
		end
		
		_G[self.className].mbSetState(self.object, self.level1, self.value, true) 
		if not connection:getIsServer() then  
			g_server:broadcastEvent(mogliBase30Event:new(self.className, self.object, self.level1, self.value), nil, connection, self.object) 
		end 
	end 
	
	
	
	
	
	
	local mogliBase30Request_mt = Class(mogliBase30Request, Event)
	InitEventClass(mogliBase30Request, mogliSyncRequest)
	function mogliBase30Request:emptyNew()
		local self = Event:new(mogliBase30Request_mt)
		return self
	end
	function mogliBase30Request:new( className, object )
		local self = mogliBase30Request:emptyNew()
		self.className = className
		self.object    = object 
		return self
	end
	function mogliBase30Request:readStream(streamId, connection)
		self.object    = NetworkUtil.readNodeObject( streamId )				
		self.className = streamReadString(streamId)
		self:run(connection) 
	end
	function mogliBase30Request:writeStream(streamId, connection)
		NetworkUtil.writeNodeObject( streamId, self.object )
		streamWriteString(streamId, self.className )
	end
	function mogliBase30Request:run(connection)
		if self.object[self.className.."SyncConnections"] == nil then
			self.object[self.className.."SyncConnections"] = {}
		end
		self.object[self.className.."SyncConnections"][connection] = true
	end

	
	
	
	
	local mogliBase30Reply_mt = Class(mogliBase30Reply, Event)
	InitEventClass(mogliBase30Reply, mogliSyncReply)
	function mogliBase30Reply:emptyNew()
		local self = Event:new(mogliBase30Reply_mt)
		return self
	end
	function mogliBase30Reply:new( className, object )
		local self = mogliBase30Reply:emptyNew()
		self.className = className
		self.object    = object 
		self.document  = _G[self.className].toMbDocument( self.object )
		return self
	end
	function mogliBase30Reply:readStream(streamId, connection)
		self.object = NetworkUtil.readNodeObject( streamId )		
		self.className, self.document = mogliBase30.readStreamEx( streamId )
		self:run(connection) 
	end
	function mogliBase30Reply:writeStream(streamId, connection)
		NetworkUtil.writeNodeObject( streamId, self.object )
		mogliBase30.writeStreamEx( streamId, self.className, self.document )
	end
	function mogliBase30Reply:run(connection)
	--print(tostring(self.className).." / "..tostring(self.object.configFileName)..": synced via event")
		_G[self.className].fromMbDocument( self.object, self.document )
		self.object[self.className.."SyncReceived"] = true
	end
	
	
end