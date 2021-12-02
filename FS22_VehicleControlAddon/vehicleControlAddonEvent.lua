--
-- vehicleControlAddonEvent
--
vehicleControlAddonEvent = {}
vehicleControlAddonEvent_mt = Class(vehicleControlAddonEvent, Event)
InitEventClass(vehicleControlAddonEvent, "vehicleControlAddonEvent")
function vehicleControlAddonEvent.emptyNew()
  local self = Event.new(vehicleControlAddonEvent_mt)
	self.check1 = 178
	self.check2 = 142
  return self
end
function vehicleControlAddonEvent.new(object,name,value)
  local self = vehicleControlAddonEvent.emptyNew()
  self.object = object
	self.name   = name
	self.value  = value
  return self
end
function vehicleControlAddonEvent:readStream(streamId, connection)
	local check1 = streamReadUInt8(streamId)
  self.object = NetworkUtil.readNodeObject( streamId )
	self.name   = streamReadString(streamId)
	if vehicleControlAddon.properties ~= nil and vehicleControlAddon.properties[self.name] ~= nil then 
		local prop = vehicleControlAddon.properties[self.name]
		self.value 	= prop.func.streamRead(streamId)
	else 
		print("Error in vehicleControlAddonEvent: invalid property '"..tostring(self.name).."'")
	end 
	local check2 = streamReadUInt8(streamId)

	if     check1 ~= self.check1 then 
		print("Error in vehicleControlAddonEvent: Event has wrong start marker. Check other mods.")
	elseif check2 ~= self.check2 then 
		print("Error in vehicleControlAddonEvent: Event has wrong end marker. ")
	else 
		self:run(connection)
	end 
end
function vehicleControlAddonEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.check1 )
  NetworkUtil.writeNodeObject( streamId, self.object )
  streamWriteString(streamId,self.name)
	if vehicleControlAddon.properties ~= nil and vehicleControlAddon.properties[self.name] ~= nil then 
		local prop = vehicleControlAddon.properties[self.name]
    prop.func.streamWrite(streamId, Utils.getNoNil( self.value, prop.emptyValue ))
	else 
		print("Error in vehicleControlAddonEvent: invalid property '"..tostring(self.name).."'")
	end 
	streamWriteUInt8(streamId, self.check2 )
end
function vehicleControlAddonEvent:run(connection)
	if self.object == nil then 
		return
	end 
  vehicleControlAddon.vcaSetState( self.object, self.name, self.value, true )
  if not connection:getIsServer() then
    g_server:broadcastEvent(vehicleControlAddonEvent.new(self.object,self.name,self.value), nil, connection, self.object)
  end
end
