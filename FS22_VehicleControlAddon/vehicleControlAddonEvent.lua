--
-- vehicleControlAddonEvent
--
vehicleControlAddonEvent = {}
vehicleControlAddonEvent_mt = Class(vehicleControlAddonEvent, Event)
InitEventClass(vehicleControlAddonEvent, "vehicleControlAddonEvent")
function vehicleControlAddonEvent.emptyNew()
  local self = Event.new(vehicleControlAddonEvent_mt)
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
  self.object = NetworkUtil.readNodeObject( streamId )
	self.name   = streamReadString(streamId)
	if vehicleControlAddon.properties ~= nil and vehicleControlAddon.properties[self.name] ~= nil then 
		local prop = vehicleControlAddon.properties[self.name]
		self.value 	= prop.func.streamRead(streamId)
	end 
  self:run(connection)
end
function vehicleControlAddonEvent:writeStream(streamId, connection)
  NetworkUtil.writeNodeObject( streamId, self.object )
  streamWriteString(streamId,self.name)
	if vehicleControlAddon.properties ~= nil and vehicleControlAddon.properties[self.name] ~= nil then 
		local prop = vehicleControlAddon.properties[self.name]
    prop.func.streamWrite(streamId, Utils.getNoNil( self.value, prop.emptyValue ))
	end 
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
