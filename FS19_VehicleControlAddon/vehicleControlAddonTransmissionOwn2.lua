vehicleControlAddonTransmissionOwn2 = {}

local vehicleControlAddonTransmissionOwn2_mt = Class(vehicleControlAddonTransmissionOwn2, vehicleControlAddonTransmissionBase)

function vehicleControlAddonTransmissionOwn2:new( params )

	--params.gearRatios   
	--params.rangeRatios  
	--params.reverseRatios
	--
	--params.gear2Names   
	--params.rangeNames   
	--params.reverseNames 
	
	--params.reverserMode
	
	--params.timeGears  = self.vcaOwnGearTime
	--params.timeRanges = self.vcaOwnRangeTime
	--params.autoGears  = self.vcaOwnAutoGears
	--params.autoRanges = self.vcaOwnAutoRange

	if type( params.gearRatios ) ~= "table" or table.getn( params.gearRatios ) < 1 then 
		params.gearRatios = { 1 }
	end 
	if type( params.rangeRatios ) ~= "table" or table.getn( params.rangeRatios ) < 1 then 
		params.rangeRatios = { 1 }
	end 
	if     type( params.reverseRatios ) ~= "table" or table.getn( params.reverseRatios ) < 1
			or ( params.reverserMode ~= 1 and params.reverserMode ~= 2 ) then 
		params.reverserMode = 0 
		params.reverseRatios = {} 
	end 

	local baseParams = {}

	baseParams.name               = params.name
	baseParams.noGears            = table.getn( params.gearRatios )
	baseParams.timeGears          = params.timeGears
	baseParams.rangeGearOverlap   = {}
	baseParams.timeRanges         = params.timeRanges
	baseParams.gearRatios         = {}
	baseParams.autoGears          = params.autoGears
	baseParams.autoRanges         = params.autoRanges

	for j,r in pairs( params.rangeRatios ) do 
		if j > 1 then 
			table.insert( baseParams.rangeGearOverlap, 0  )
		end 
		for i,g in pairs( params.gearRatios ) do 
			table.insert( baseParams.gearRatios, 1 / ( r * g ) )
		end 
	end 
	
	local self = vehicleControlAddonTransmissionBase:new( baseParams, vehicleControlAddonTransmissionOwn2_mt )
	
	self.gear2Ratios   = params.gearRatios 
	self.gear2Names    = params.gearNames 

	self.rangeRatios   = params.rangeRatios
	self.rangeNames    = params.rangeNames

	self.reverseRatios = params.reverseRatios 
	self.reverseNames  = params.reverseNames
	self.reverserMode  = params.reverserMode
	
	local ng = table.getn( self.gear2Ratios )
	local nr = table.getn( self.rangeRatios )
	if     self.reverserMode == 1 then 
		ng = math.max( ng, table.getn( self.reverseRatios ) )
	elseif self.reverserMode == 2 then 
		nr = math.max( nr, table.getn( self.reverseRatios ) )
	end 
	
	local k = 0
	self.gearRangeIndex = {} 
	self.indexGearRange = {}
	for i=1,ng do 
		self.gearRangeIndex[i] = {}
		for j=1,nr do 
			k = k + 1
			self.gearRangeIndex[i][j] = k
			self.indexGearRange[k] = { i, j }
		end 
	end 
	
	return self
end



function vehicleControlAddonTransmissionOwn2:delete() 
	vehicleControlAddonTransmissionBase.delete( self )
	
	self.gear2Ratios   = nil
  self.gear2Names    = nil

  self.rangeRatios   = nil
  self.rangeNames    = nil

  self.reverseRatios = nil
  self.reverseNames  = nil
end 


function vehicleControlAddonTransmissionOwn2:initGears( noEventSend )	
	
	local ng = table.getn( self.gear2Ratios )
	local nr = table.getn( self.rangeRatios )
	
	local currentReverse = self.vehicle:vcaGetIsReverse()
	
	if     not currentReverse 
			or self.reverserMode == 0 then 
	elseif self.reverserMode == 1 then 
		ng = table.getn( self.reverseRatios )
	else 
		nr = table.getn( self.reverseRatios )
	end 
	
	if     self.lastReverse == nil 
			or self.lastReverse == currentReverse then
	elseif self.reverserMode == 1 then 
		local o = self.vehicle.vcaGear
		print("changing direction 1: "..tostring(self.lastReverse).." -> "..tostring(currentReverse).."; "..tostring(o).." -> "..tostring(self.lastOther))
		if self.lastOther ~= nil then  
			self.vehicle:vcaSetState( "vcaGear", self.lastOther, noEventSend )
		end
		self.lastOther = o
	elseif self.reverserMode == 2 then 
		local o = self.vehicle.vcaRange
		print("changing direction 1: "..tostring(self.lastReverse).." -> "..tostring(currentReverse).."; "..tostring(o).." -> "..tostring(self.lastOther))
		if self.lastOther ~= nil then  
			self.vehicle:vcaSetState( "vcaRange", self.lastOther, noEventSend )	
		end 
		self.lastOther = o
	end 

	self.lastReverse = currentReverse
	
	if     self.lastReverse == nil
			or self.vehicle.vcaGear == 0 then 
		self.vehicle:vcaSetState( "vcaGear", 1, noEventSend )
		self.vehicle:vcaSetState( "vcaRange", nr, noEventSend )			
	elseif self.vehicle.vcaGear < 1 then 
		print("correcting gear: "..tostring(self.vehicle.vcaGear))
		self.vehicle:vcaSetState( "vcaGear", 1, noEventSend )
	elseif self.vehicle.vcaGear > ng then 
		print("correcting gear: "..tostring(self.vehicle.vcaGear))
		self.vehicle:vcaSetState( "vcaGear", ng, noEventSend )
	end 
	if     self.vehicle.vcaRange < 1 then   
		print("correcting range: "..tostring(self.vehicle.vcaRange))
		self.vehicle:vcaSetState( "vcaRange", 1, noEventSend )
	elseif self.vehicle.vcaRange > nr then 
		print("correcting range: "..tostring(self.vehicle.vcaRange))
		self.vehicle:vcaSetState( "vcaRange", nr, noEventSend )
	end 

	return false 
end 

function vehicleControlAddonTransmissionOwn2:getGearText( gear, range )
	local gt, rt

	if self.gear2Names ~= nil and self.gear2Names[gear] ~= nil then 
		gt = self.gear2Names[gear]
	end 
	if self.rangeNames ~= nil and self.rangeNames[range] ~= nil then 
		rt = self.rangeNames[range]
	end 

	if not self.vehicle:vcaGetIsReverse() or self.reverserMode == 0 then 
	
	elseif self.reverserMode == 1 then 
		if self.reverseNames ~= nil and self.reverseNames[gear] ~= nil then 
			gt = self.reverseNames[gear]
		elseif table.getn( self.reverseRatios ) <= 1 then 
			gt = "R" 
		else 
			gt = "R"..gt 
		end 
	elseif self.reverserMode == 2 then 
		if self.reverseNames ~= nil and self.reverseNames[range] ~= nil then 
			rt = self.reverseNames[range]
		elseif table.getn( self.reverseRatios ) <= 1 then 
			rt = "R" 
		else 
			rt = "R"..rt 
		end 
	end 

	if rt ~= nil and gt ~= nil then 
		return tostring(rt).." "..tostring(gt)
	elseif rt ~= nil then 
		return tostring(rt)
	elseif gt then 
		return tostring(gt)
	end 
	return ""
end 

function vehicleControlAddonTransmissionOwn2:gearUp()
	local ng = table.getn( self.gear2Ratios )	
	if self.vehicle:vcaGetIsReverse() and self.reverserMode == 1 then 
		ng = table.getn( self.reverseRatios )
	end 

	if self.vehicle.vcaGear >= ng then 
		self.vehicle:vcaSetState( "vcaGear", ng )
	else 
		if self:getChangeTimeGears() > 100 then 
			if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaGear", self.vehicle.vcaGear + 1 )
	end 
end 

function vehicleControlAddonTransmissionOwn2:gearDown()
	if self.vehicle.vcaGear > 1 then 
		if self:getChangeTimeGears() > 100 then 
			if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaGear", self.vehicle.vcaGear - 1 )
	end 
end 

function vehicleControlAddonTransmissionOwn2:rangeUp( noSpeedMatching )
	local nr = table.getn( self.rangeRatios )	
	if self.vehicle:vcaGetIsReverse() and self.reverserMode == 2 then 
		nr = table.getn( self.reverseRatios )
	end 
	
	if self.vehicle.vcaRange >= nr then 
		self.vehicle:vcaSetState( "vcaRange", nr )
	else 
		if self:getChangeTimeRanges() > 100 then
			if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaRange", self.vehicle.vcaRange + 1 )		
	end 
end 

function vehicleControlAddonTransmissionOwn2:rangeDown( noSpeedMatching )
	if self.vehicle.vcaRange > 1 then 
		if self:getChangeTimeRanges() > 100 then
			if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaRange", self.vehicle.vcaRange - 1 )		
	end 
end 

function vehicleControlAddonTransmissionOwn2:getGearShifterIndeces( maxNum, noSplit )
end 

function vehicleControlAddonTransmissionOwn2:getGearRatio( index )
	if self.indexGearRange[index] == nil then 
		return 0 
	end 
	
	local rg = self.gear2Ratios
	local rr = self.rangeRatios
	
	if self.vehicle:vcaGetIsReverse() then 
		if     self.reverserMode == 1 then 
			rg = self.reverseRatios
		elseif self.reverserMode == 2 then 
			rr = self.reverseRatios
		end 
	end 

	local g, r = unpack( self.indexGearRange[index] )
	
	g = math.min( math.max( g, 1 ), table.getn( rg ) )
	r = math.min( math.max( r, 1 ), table.getn( rr ) )
	
	return 1 / ( rg[g] * rr[r] )
end 

function vehicleControlAddonTransmissionOwn2:getNumberOfRatios()
	return table.getn( self.indexGearRange )
end 

function vehicleControlAddonTransmissionOwn2:getAutoShiftIndeces( curRatio, lowRatio, searchDown, searchUp, force )
	
	local ag = self.autoShiftGears
	local ar = self.autoShiftRange
	local cg = self.vehicle.vcaGear
	local cr = self.vehicle.vcaRange
	
	if force then 
		ag = true 
		ar = true 
	end 
	
	local rg = self.gear2Ratios
	local rr = self.rangeRatios	
	if self.vehicle:vcaGetIsReverse() then 
		if     self.reverserMode == 1 then 
			rg = self.reverseRatios
		elseif self.reverserMode == 2 then 
			rr = self.reverseRatios 
		end 
	end 
	local ng = table.getn( rg )
	local nr = table.getn( rr )
	
	if table.getn( rg ) <= 1 then 
		ag = false 
	end 
	if table.getn( rr ) <= 1 then 
		ar = false 
	end 
	
	cg = math.min( math.max( cg, 1 ) , ng )
	cr = math.min( math.max( cr, 1 ) , nr )

	
	if self.vehicle.vcaShifterUsed then 
		ag = false 
		ar = ar and self:getG27ShifterOnGears()
	end 
	
	if not ag and not ar then 
		return {} 
	end 

	local gearList = {}
	
	local delta = 0
	if self.vehicle.vcaMaxSpeed ~= nil and self.vehicle.vcaMaxSpeed > 0 then 
		delta = 0.5 / self.vehicle.vcaMaxSpeed 
	end
	local rf = math.max( 0, self.vehicle.vcaGearRatioF - delta )
	local rt = math.huge
	if self.vehicle.spec_motorized.motor.minRpm > 0 then 
		local l1   = math.huge
		local l2,c = self.vehicle:getSpeedLimit()
		if self.vehicle.vcaLimitSpeed then 
			if self.vehicle:vcaGetIsReverse() then	
				l1 = self.vehicle.spec_motorized.motor.maxBackwardSpeed
			else 
				l1 = self.vehicle.spec_motorized.motor.maxForwardSpeed
			end 
		end 
		if c or self.vehicle.vcaLimitSpeed then 
			rt = self.vehicle.spec_motorized.motor.maxRpm * math.min( l1, l2 ) / ( self.vehicle.spec_motorized.motor.minRpm * self.vehicle.vcaMaxSpeed )
		end 
	end 
	if self.vehicle.vcaGearRatioT > 0 then
		rt = math.min( rt, self.vehicle.vcaGearRatioT + delta )
	end 
	
	if     not ag then 
		for i=1,nr do 
			local r = 1 / ( rg[cg] * rr[i] )
			if 			( rf <= r and r <= rt )
					and ( ( r < curRatio and searchDown and r >= lowRatio ) or ( searchUp and r > curRatio ) ) then 
				table.insert( gearList, self.gearRangeIndex[cg][i] )
			end 
		end 
	elseif not ar then 
		for i=1,ng do 
			local r = 1 / ( rg[i] * rr[cr] )
				if 			( rf <= r and r <= rt )
						and ( ( r < curRatio and searchDown and r >= lowRatio ) or ( searchUp and r > curRatio ) ) then 
				table.insert( gearList, self.gearRangeIndex[i][nr] )
			end 
		end 
	else -- both
		for i=1,ng do 
			for j=1,nr do
				local r = 1 / ( rg[i] * rr[j] )
				if 			( rf <= r and r <= rt )
						and ( ( r < curRatio and searchDown and r >= lowRatio ) or ( searchUp and r > curRatio ) ) then 
					table.insert( gearList, self.gearRangeIndex[i][j] )
				end 
			end 
		end 
	end 
	
	return gearList
end 

function vehicleControlAddonTransmissionOwn2:getRatioIndex( gear, range )
	if self.gearRangeIndex[gear] == nil or self.gearRangeIndex[gear][range] == nil then 
		return 0
	end 
	return self.gearRangeIndex[gear][range]
end 

function vehicleControlAddonTransmissionOwn2:getBestGearRangeFromIndex( oldGear, oldRange, index )
	if self.indexGearRange[index] == nil then 
		return 1,1
	end 
	return unpack( self.indexGearRange[index] ) 
end 

function vehicleControlAddonTransmissionOwn2:getRatioIndexListOfGear( gear )
	--empty
end 

function vehicleControlAddonTransmissionOwn2:getRatioIndexListOfRange( range )
	--empty
end 
