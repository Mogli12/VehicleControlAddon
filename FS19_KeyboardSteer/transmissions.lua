

keyboardSteerTransmissionBase = {}
keyboardSteerTransmissionBase_mt = Class(keyboardSteerTransmissionBase)

keyboardSteerTransmissionBase.gearRatios = { 0.120, 0.145, 0.176, 0.213, 0.259, 0.314, 0.381, 0.462, 0.560, 0.680, 0.824, 1.000 }


function keyboardSteerTransmissionBase:new( mt, name, noGears, timeGears, rangeGearOverlap, timeRanges )
	local self = {}

	if mt == nil then 
		setmetatable(self, keyboardSteerTransmissionBase_mt)
	else 
		setmetatable(self, mt)
	end 

	self.name             = name 
	self.numberOfGears    = noGears 
	self.numberOfRanges   = 1 + #rangeGearOverlap
	self.rangeGearFromTo  = {} 
	local ft = { from = 1, to = self.numberOfGears, ofs = 0 }
	local i  = 1
	while true do 
		table.insert( self.rangeGearFromTo, { from = ft.from, to = ft.to, ofs = ft.ofs } )
		if rangeGearOverlap[i] == nil then 
			break 
		end 
		ft.from = ft.from + self.numberOfGears - rangeGearOverlap[i]
		ft.to   = ft.to   + self.numberOfGears - rangeGearOverlap[i]
		ft.ofs  = ft.ofs  + self.numberOfGears - rangeGearOverlap[i]
		i       = i + 1
	end 
	self.rangeGearOverlap = rangeGearOverlap
	self.changeTimeGears  = timeGears
	self.changeTimeRanges = timeRanges

	return self
end 

function keyboardSteerTransmissionBase:initGears( vehicle )
	local initGear = false 
	if     vehicle.ksmGear == 0 then 
		initGear = true 
		vehicle:ksmSetState( "ksmGear", 1 )
		vehicle:ksmSetState( "ksmRange", self.numberOfRanges )			
	elseif vehicle.ksmGear < 1 then 
		initGear = true 
		vehicle:ksmSetState( "ksmGear", 1 )
	elseif vehicle.ksmGear > self.numberOfGears then 
		initGear = true 
		vehicle:ksmSetState( "ksmGear", self.numberOfGears )
	end 
	if     vehicle.ksmRange < 1 then   
		initGear = true 
		vehicle:ksmSetState( "ksmRange", 1 )
	elseif vehicle.ksmRange > self.numberOfRanges then 
		initGear = true 
		vehicle:ksmSetState( "ksmRange", self.numberOfRanges )
	end 
	return initGear 
end 

function keyboardSteerTransmissionBase:getName()
	return self.name 
end 

function keyboardSteerTransmissionBase:getGearText( gear, range )
	local text = ""
	if     self.numberOfRanges <= 1 then 
	elseif self.numberOfRanges == 2 then
		if range <= 1 then 
			text = "L"
		else 
			text = "H"
		end 
	elseif self.numberOfRanges <= 4 then
		if     range <= 1 then 
			text = "L"
		elseif range == 2 then
			text = "M"
		elseif range == 3 then 
			text = "H"
		else
			text = "S" 
		end 
	else
		text = tostring( range )
	end 
	
	if     self.numberOfRanges <= 1 then 
	elseif self.numberOfRanges == 2 then
		if gear <= 1 then 
			text = text .." +"
		else 
			text = text .." -"
		end 
	else 
		text = text.." "..tostring(gear)
	end 
	
	return text 
end 

function keyboardSteerTransmissionBase:gearUp( vehicle )
	vehicle:ksmSetState("ksmShifterIndex", 0)
	if vehicle.ksmGear < self.numberOfGears then 
		vehicle:ksmSetState( "ksmGear", vehicle.ksmGear + 1 )
	end 
end 

function keyboardSteerTransmissionBase:gearDown( vehicle )
	vehicle:ksmSetState("ksmShifterIndex", 0)
	if vehicle.ksmGear > 1 then 
		vehicle:ksmSetState( "ksmGear", vehicle.ksmGear - 1 )
	end 
end 

function keyboardSteerTransmissionBase:rangeUp( vehicle )
	if vehicle.ksmRange < self.numberOfRanges then 
		local o = self.rangeGearOverlap[vehicle.ksmRange]
		vehicle:ksmSetState( "ksmRange", vehicle.ksmRange + 1 )
		if o ~= nil and o ~= 0 and vehicle.ksmShifterIndex <= 0 then 
			vehicle:ksmSetState( "ksmGear", math.max( 1, vehicle.ksmGear - o ) )
		end 
	end 
end 

function keyboardSteerTransmissionBase:rangeDown( vehicle )
	if vehicle.ksmRange > 1 then 
		vehicle:ksmSetState( "ksmRange", vehicle.ksmRange - 1 )
		local o = self.rangeGearOverlap[vehicle.ksmRange]
		if o ~= nil and o ~= 0 and vehicle.ksmShifterIndex <= 0 then 
			vehicle:ksmSetState( "ksmGear", math.min( self.numberOfGears, vehicle.ksmGear + o ) )
		end 
	end 
end 

function keyboardSteerTransmissionBase:gearShifter( vehicle, number, isPressed )
	if isPressed then 
		local goFwd = nil 
		local list  = self:getGearShifterIndeces( vehicle.ksmShifterLH )
		local num2  = 0
		
		if number == 7 then 
			if not vehicle.ksmShuttleCtrl then 
				return 
			end 
			
			vehicle.ksmShifter7isR1 = true 
			goFwd = false 
			
			num2 = 2
			for i,l in pairs(list) do  
				if i > 1 and l > vehicle.ksmLaunchGear then 
					break 
				end 
				num2 = i  
			end 
		else			
			if vehicle.ksmShuttleCtrl and vehicle.ksmShifter7isR1 == nil then 
				vehicle.ksmShifter7isR1 = true 
			end 
			if vehicle.ksmShifter7isR1 then 
				goFwd = true 
			end 
			
			num2 =  number + number 
		end 
		
		if not vehicle.ksmShifterLH and num2 > 1 then 
			num2 = num2 - 1
		end 
		local index = list[num2] 
		if index == nil then 
			print("Cannot find correct gear for shifter position "..tostring(number))
			return 
		end 
		
		local g, r = self:getBestGearRangeFromIndex( vehicle.ksmGear, vehicle.ksmRange, index )
	
		vehicle:ksmSetState( "ksmShifterIndex", number )
		vehicle:ksmSetState( "ksmGear", g )
		vehicle:ksmSetState( "ksmRange", r )
		vehicle:ksmSetState( "ksmNeutral", false )
		if goFwd ~= nil then
			vehicle:ksmSetState( "ksmShuttleFwd", goFwd )
		end
	else 
		vehicle:ksmSetState( "ksmNeutral", true )
		if vehicle.spec_motorized.motor.ksmLoad ~= nil then  
			vehicle:ksmSetState("ksmBOVVolume",vehicle.spec_motorized.motor.ksmLoad)
		end 
	end 
end 

function keyboardSteerTransmissionBase:getGearShifterIndeces( )
	if self.gearShifterIndeces == nil then 
		self.gearShifterLH = highRange
		local numGears = self:getNumberOfRatios()	
		local offset   = 0
		offset = math.max( numGears - 12 )	
		self.gearShifterIndeces = {} 
		for i=1,12 do 
			table.insert( self.gearShifterIndeces, math.max( 1, i + offset ) )
		end 
	end 
			
	return self.gearShifterIndeces
end 

function keyboardSteerTransmissionBase:getGearRatio( index )
	return keyboardSteerTransmissionBase.gearRatios[index]
end 

function keyboardSteerTransmissionBase:getNumberOfRatios( )
	return 12
end 

function keyboardSteerTransmissionBase:getRatioIndex( gear, range )
	if self.rangeGearFromTo[range] == nil then 
		return 0
	end
	return self.rangeGearFromTo[range].ofs + gear 
end 

function keyboardSteerTransmissionBase:getBestGearRangeFromIndex( oldGear, oldRange, index )
	local i = self:getRatioIndex( oldGear, oldRange )
	
	if index == nil or i == index then 
		return oldGear, oldRange 
	end 
	
	local g = oldGear 
	local r = oldRange 
	
	while true do 
		if self.rangeGearFromTo[r] ~= nil then 
			g = index - self.rangeGearFromTo[r].ofs 
			if 1 <= g and g <= self.numberOfGears then 
				return g, r 
			end 
		end 
		if i < index then 
			r = r + 1 
			if r > self.numberOfRanges then 
				return self.numberOfGears, self.numberOfRanges 
			end 
		else 
			r = r - 1 
			if r < 1 then 
				return 1, 1
			end 
		end 
	end 
	
	return 1, self.numberOfRanges
end 

function keyboardSteerTransmissionBase:getRatioIndexList()
	return { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }
end 

function keyboardSteerTransmissionBase:getRatioIndexListOfGear( gear )
	return self:getRatioIndexList()
end 

function keyboardSteerTransmissionBase:getRatioIndexListOfRange( range )
	return self:getRatioIndexList()
end 

function keyboardSteerTransmissionBase:actionCallback( vehicle, actionName, keyStatus )
	if     actionName == "ksmGearUp"   then
		self:gearUp( vehicle )
	elseif actionName == "ksmGearDown" then
		self:gearDown( vehicle )
	elseif actionName == "ksmRangeUp"  then
		self:rangeUp( vehicle )
	elseif actionName == "ksmRangeDown"then
		self:rangeDown( vehicle )
	elseif actionName == "ksmShifter1" then
		self:gearShifter( vehicle, 1, keyStatus >= 0.5 )
	elseif actionName == "ksmShifter2" then
		self:gearShifter( vehicle, 2, keyStatus >= 0.5 )
	elseif actionName == "ksmShifter3" then
		self:gearShifter( vehicle, 3, keyStatus >= 0.5 )
	elseif actionName == "ksmShifter4" then
		self:gearShifter( vehicle, 4, keyStatus >= 0.5 )
	elseif actionName == "ksmShifter5" then
		self:gearShifter( vehicle, 5, keyStatus >= 0.5 )
	elseif actionName == "ksmShifter6" then
		self:gearShifter( vehicle, 6, keyStatus >= 0.5 )
	elseif actionName == "ksmShifter7" then 
		self:gearShifter( vehicle, 7, keyStatus >= 0.5 )
	elseif actionName == "ksmShifterLH" and vehicle.ksmShifterIndex > 0 then 
		vehicle:ksmSetState( "ksmShifterLH", not vehicle.ksmShifterLH )
		if not vehicle.ksmNeutral then 
			self:gearShifter( vehicle, vehicle.ksmShifterIndex, keyStatus >= 0.5 )
		end 
	end 
end 

keyboardSteerIVT = {}
function keyboardSteerIVT:new()
	local self = keyboardSteerTransmissionBase:new( Class(keyboardSteerIVT,keyboardSteerTransmissionBase), "IVT", 1, 0, {}, 0 )
	return self 
end 

keyboardSteer4x4 = {}
function keyboardSteer4x4:new()
	local self = keyboardSteerTransmissionBase:new( Class(keyboardSteer4x4,keyboardSteerTransmissionBase), "4X4", 4, 750, {2,1,1}, 1000 )
	return self 
end 

keyboardSteer4PS = {}
function keyboardSteer4PS:new()
	local self = keyboardSteerTransmissionBase:new( Class(keyboardSteer4PS,keyboardSteerTransmissionBase), "4PS", 4, 0, {2,1,1}, 750 )
	return self 
end 

keyboardSteer2x6 = {}
function keyboardSteer2x6:new()
	local self = keyboardSteerTransmissionBase:new( Class(keyboardSteer2x6,keyboardSteerTransmissionBase), "2X6", 6, 750, {0}, 1000 )
	return self 
end 

keyboardSteerFPS = {}
function keyboardSteerFPS:new()
	local self = keyboardSteerTransmissionBase:new( Class(keyboardSteerFPS,keyboardSteerTransmissionBase), "FPS", 12, 0, {}, 0 )
	return self 
end 

keyboardSteer6PS = {}
function keyboardSteer6PS:new()
	local self = keyboardSteerTransmissionBase:new( Class(keyboardSteer6PS,keyboardSteerTransmissionBase), "6PS", 2, 0, {0,0,0,0,0}, 750 )
	return self 
end 

