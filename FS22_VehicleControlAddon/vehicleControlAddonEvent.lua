--
-- vehicleControlAddonEvent
--
vehicleControlAddonEvent = {}
vehicleControlAddonEvent_mt = Class(vehicleControlAddonEvent, Event)
InitEventClass(vehicleControlAddonEvent, "vehicleControlAddonEvent")
function vehicleControlAddonEvent.emptyNew()
  local self = Event:new(vehicleControlAddonEvent_mt)
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
	if self.object.spec_vcaProp ~= nil and self.object.spec_vcaProp[self.name] ~= nil then 
		prop = vehicleControlAddon.properties[name]
		self.value 	= prop.func.streamRead(streamId)
	end 
  self:run(connection)
end
function vehicleControlAddonEvent:writeStream(streamId, connection)
  NetworkUtil.writeNodeObject( streamId, self.object )
  streamWriteString(streamId,self.name)
	if self.object.spec_vcaProp ~= nil and self.object.spec_vcaProp[self.name] ~= nil then 
		prop = vehicleControlAddon.properties[name]
    prop.func.streamWrite(streamId, self.value)
	end 
end
function vehicleControlAddonEvent:run(connection)
  vehicleControlAddon.vcaSetState( self.object, self.name, self.value, true )
  if not connection:getIsServer() then
    g_server:broadcastEvent(vehicleControlAddonEvent:new(self.object,self.name,self.value), nil, connection, self.object)
  end
end