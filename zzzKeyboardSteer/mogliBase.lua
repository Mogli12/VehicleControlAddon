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

-- Usage:  source(Utils.getFilename("mogliBase.lua", g_currentModDirectory));
--         _G[g_currentModDirectory.."mogliBase"].newClass( "AutoCombine", "acParameters" )

local mogliBaseVersion   = 3.06
local mogliBaseClass     = g_currentModName..".mogliBase"
local mogliEventClass    = g_currentModName..".mogliEvent"
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
	local mogliBase30Event_mt = Class(mogliBase30Event, Event) 

	InitEventClass(mogliBase30Event, mogliEventClass) 

--=======================================================================================
-- mogliBase30Event:emptyNew
--=======================================================================================
	mogliBase30Event.emptyNew = function(self)
		local self = Event:new(mogliBase30Event_mt) 
	--self.className = mogliEventClass
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
		function _newClass_.globalsLoad( file , rootTag, globals )	

			local xmlFile = loadXMLFile( "mogliBasics", file, rootTag )
			_newClass_.globalsLoad2( xmlFile , rootTag, globals )	
		end
		
	--********************************
	-- globalsLoad2
	--********************************
		function _newClass_.globalsLoad2( xmlFile , rootTag, globals )	

			for name,value in pairs(globals) do
				local tp = getXMLString(xmlFile, rootTag.."." .. name .. "#type")
				if     tp == nil then
		--			print(file..": "..name.." = nil")
				elseif tp == "bool" then
					local bool = getXMLBool( xmlFile, rootTag.."." .. name .. "#value" )
					if bool ~= nil then
						--if bool then globals[name] = 1 else globals[name] = 0 end
						globals[name] = bool
					end
		--			print(file..": "..name.." = "..tostring(globals[name]))
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
					print(file..": "..name..": invalid XML type : "..tp)
				end
			end
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

	--**********************************************************************************************************	
	-- hasInputEvent
	--**********************************************************************************************************	
		function _newClass_.mbHasInputEvent( name, noWarning )
			if InputBinding[name] == nil then
				if not ( noWarning or _newClass_.noInputWarning ) then
					if _newClass_.mbUndefinedInputs == nil then
						_newClass_.mbUndefinedInputs = {}
					end
					if not ( _newClass_.mbUndefinedInputs[name] ) then
						_newClass_.mbUndefinedInputs[name] = true
						print("WARNING: undefined input in ".._globalClassName_..": "..tostring(name))
					end
				end
				return false
			end
			if InputBinding.hasEvent(InputBinding[name]) then
				if InputBinding.areKeysPressed( InputBinding.actions[InputBinding[name]].keys1 ) then
				  return mogliBase30.checkForKeyModifiers( InputBinding.actions[InputBinding[name]].keys1 )
				end
				if InputBinding.areKeysPressed( InputBinding.actions[InputBinding[name]].keys2 ) then
				  return mogliBase30.checkForKeyModifiers( InputBinding.actions[InputBinding[name]].keys2 )
				end
				return true
			end
			return false
		end

	--**********************************************************************************************************	
	-- hasInputEvent
	--**********************************************************************************************************	
		function _newClass_.mbIsInputPressed( name, noWarning )
			if InputBinding[name] == nil then
				if not ( noWarning or _newClass_.noInputWarning ) then
					if _newClass_.mbUndefinedInputs == nil then
						_newClass_.mbUndefinedInputs = {}
					end
					if not ( _newClass_.mbUndefinedInputs[name] ) then
						_newClass_.mbUndefinedInputs[name] = true
						print("WARNING: undefined input in ".._globalClassName_..": "..tostring(name))
					end
				end
				return false
			end
			return InputBinding.isPressed(InputBinding[name])		
		end

	--********************************
	-- normalizeAngle
	--********************************
		function _newClass_.normalizeAngle( angle )
			local normalizedAngle = angle
			if angle > math.pi then
				normalizedAngle = angle - math.pi - math.pi
			elseif angle <= -math.pi then
				normalizedAngle = angle + math.pi + math.pi
			end
			return normalizedAngle
		end

	--********************************
	-- prerequisitesPresent
	--********************************
		function _newClass_.prerequisitesPresent(specializations)
			return true
		end

	--********************************
	-- load
	--********************************
		function _newClass_:load(xmlFile)
		-- should always be overwritten
			_newClass_.registerState( self, "mogliBasicsDummy", false, _newClass_.debugEvent )
		end

	--********************************
	-- delete
	--********************************
		function _newClass_:delete()
		end

	--********************************
	-- mouseEvent
	--********************************
		function _newClass_:mouseEvent(posX, posY, isDown, isUp, button)
		end

	--********************************
	-- keyEvent
	--********************************
		function _newClass_:keyEvent(unicode, sym, modifier, isDown)
		end

	--********************************
	-- update
	--********************************
		function _newClass_:update(dt)
		end

	--********************************
	-- updateTick
	--********************************
		function _newClass_:updateTick(dt)	
		end

	--********************************
	-- draw
	--********************************
		function _newClass_:draw()	
		end  
					 
	--********************************
	-- getSaveAttributesAndNodes
	--********************************
		function _newClass_:getSaveAttributesAndNodes(nodeIdent)
			local attributes = ""
			local nodes      = ""
			
			if self[_globalClassName_.."StateHandler"] ~= nil then			
				for level1,state in pairs( self[_globalClassName_.."StateHandler"] ) do
					if state.save then
						local value = _newClass_.mbGetState( self, level1 )
						
						if value ~= nil and ( state.default == nil or not mogliBase30.compare( state.default, value ) ) then
							local vType  = mogliBase30.getValueType( value )
							local xValue = nil
							if     vType == "string"  then 
								xValue = value
							elseif vType == "int8"    
									or vType == "int32"   
									or vType == "float32" 
									or vType == "number"  then 
								xValue = tostring(value)
							elseif vType == "boolean" then 
								xValue = tostring(value)
							end
							if xValue ~= nil then
								if nodes == "" then
									nodes = nodeIdent..'<'.._globalClassName_..'>'
								end
								nodes = nodes .. '\n'..nodeIdent..'  <state name="'..level1..'" type="'..vType..'" value="'..xValue..'"/>'
							end
						end
					end
				end
				
				if nodes ~= "" then
					nodes = nodes .. '\n'..nodeIdent..'</'.._globalClassName_..'>'
				end
			end
						
			return attributes, nodes
		end;

	--********************************
	-- loadFromAttributesAndNodes
	--********************************
		function _newClass_:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
			local i = 0
			while true do
				local xmlKey = string.format("%s.%s.state(%d)", key, _globalClassName_, i)
				i = i + 1
				local level1 = getXMLString(xmlFile, xmlKey.."#name")
				if level1 == nil then
					break
				end
				local vType = getXMLString(xmlFile, xmlKey.."#type")
				local value = nil
				if     vType == nil then
				elseif vType == "string"  then 
					value = getXMLString(xmlFile, xmlKey.."#value")
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
			
			return BaseMission.VEHICLE_LOAD_OK;
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
			if self.isServer then
				self.mbClientInitDone30 = true
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
			_newClass_.initStateHandling( self )
			
			if self[_globalClassName_.."StateHandler"][level1] == nil then
				_newClass_.registerState( self, level1 )
			end
			
			local old = _newClass_.mbGetState( self, level1 )
			if     old == nil or not ( mogliBase30.compare( old, value ) ) then
				if noEventSend == nil or noEventSend == false then
					local eventObject = mogliBase30Event:new(_globalClassName_, self, level1, value)
					if g_server ~= nil then 
						g_server:broadcastEvent( eventObject ) 
					else
						g_client:getServerConnection():sendEvent( eventObject ) 
					end 
				end 						
			
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
		
			local mbDocument, pos, err = "", 0, ""
			local mode = streamReadString( streamId )
			--print("readStream using mode: "..tostring(mode))
			if     mode == "nil"  then
				mbDocument = {}
			elseif mode ~= "json" then
				err, mbDocument = mogliBase30.readStreamEx( streamId )
				if err ~= _globalClassName_ then
					print("Error: '".._globalClassName_.."' expected")
					mbDocument = {}
				end
			elseif json == nil then
				print("no json to parse: "..streamReadString( streamId ))
			else
				mbDocument, pos, err = json.decode ( streamReadString( streamId ), 1, nil)	
				if err then
					print ("Error:", err)
					mbDocument = {}
				end
			end
			
			_newClass_.fromMbDocument( self, mbDocument )
			self.mbClientInitDone30 = true
		end 
		 
	--********************************
	-- writeStream
	--********************************
		function _newClass_:writeStream(streamId, connection)

			if      self[_globalClassName_.."ConfigHandler"] == nil
					and self[_globalClassName_.."StateHandler"]  == nil then
				streamWriteString( streamId, "nil" )
			else
			  local mbDocument = _newClass_.toMbDocument( self )
			
			--if json == nil then
			--	print("writeStream using writeStreamEx")
				streamWriteString( streamId, "no json" )
				mogliBase30.writeStreamEx( streamId, _globalClassName_, mbDocument )
			--else
			--	print("writeStream using dkjson.lua")
			--	streamWriteString( streamId, "json" )
			--	streamWriteString( streamId, json.encode( mbDocument ) ) 	
			--end
			end
		end 

	--********************************
	-- debugEvent
	--********************************
		function _newClass_:debugEvent( old, new, noEventSend )
			local i = 2 
			local info 
			print("------------------------------------------------------------------------") 
			while i <= 10 do
				info = debug.getinfo(i) 
				if info == nil then break end
				print(string.format("%i: %s (%i): %s", i, info.short_src, Utils.getNoNil(info.currentline,0), Utils.getNoNil(info.name,"<???>"))) 
				i = i + 1 
			end
			if info ~= nil and info.name ~= nil and info.currentline ~= nil then
				print("...") 
			end
			print("------------------------------------------------------------------------") 
			print(tostring(old).." "..tostring(new).." "..tostring(noEventSend)) 
		end 

	--********************************
	-- mogliBase20TestStream
	--********************************
		function _newClass_:mogliBaseTestStream( )
			local streamId = createStream()
			_newClass_.writeStream( self, streamId )
			local mode = streamReadString( streamId )
			print("readStream using mode: "..tostring(mode))
			print("Bytes: "..tostring(math.ceil(0.125*streamGetNumOfUnreadBits(streamId))))
			name, value = mogliBase30.readStreamEx( streamId, true )
			print("Name of document received: "..tostring(name))
		end	
		
		
		_G[_globalClassName_] = _newClass_ 
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
	
--=======================================================================================
-- readStream
--=======================================================================================
	mogliBase30Event.readStream = function(self, streamId, connection)
		--both clients and server can receive this event
		self.className = streamReadString(streamId)
		local id       = streamReadInt32(streamId) 
		self.object    = networkGetObject(id) 
		self.level1, self.value = _G[mogliBaseClass].readStreamEx( streamId )
		
		if self.object == nil then
			print("Error reading network ID: "..tostring(id).." ("..tostring(self.className))
		else
			self:run(connection) 
		end
	end 
	
--=======================================================================================
-- writeStream
--=======================================================================================
	mogliBase30Event.writeStream = function(self, streamId, connection)
		--both clients and server can send this event
		streamWriteString(streamId, self.className)
		streamWriteInt32(streamId, networkGetObjectId(self.object)) 
		_G[mogliBaseClass].writeStreamEx( streamId, self.level1, self.value )
	end 
	
--=======================================================================================
-- run
--=======================================================================================
	mogliBase30Event.run = function(self, connection)
		----both clients and server can "run" this event (after reading it)	
		_G[self.className].mbSetState(self.object, self.level1, self.value, true) 
		if not connection:getIsServer() then  
			g_server:broadcastEvent(mogliBase30Event:new(self.className, self.object, self.level1, self.value), nil, connection, self.object) 
		end 
	end 
end