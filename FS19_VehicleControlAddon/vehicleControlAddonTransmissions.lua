function vcaClass(subClass, baseClass)
	if baseClass == nil then 
		return { __metatable = subClass, __index  = subClass }
	end 
	return { __metatable = subClass, __index = baseClass }
end

vehicleControlAddonTransmissionBase = {}
vehicleControlAddonTransmissionBase_mt = vcaClass(vehicleControlAddonTransmissionBase)

vehicleControlAddonTransmissionBase.gearRatios = { 0.120, 0.145, 0.176, 0.213, 0.259, 0.314, 0.381, 0.462, 0.560, 0.680, 0.824, 1.000 }


function vehicleControlAddonTransmissionBase:new( params, mt )

	local self = {}

	if mt == nil then 
		setmetatable(self, vehicleControlAddonTransmissionBase_mt)
	else 
		setmetatable(self, mt)
	end 

	self.firstTimeRun     = false 
	self.name             = params.name 
	self.numberOfGears    = params.noGears 
	self.numberOfRanges   = 1 + #params.rangeGearOverlap
	self.numberOfRevGears = 0
	self.numberOfRevRange = 0
	self.rangeGearFromTo  = {} 
	local ft = { from = 1, to = self.numberOfGears, ofs = 0 }
	local i  = 1
	while true do 
		table.insert( self.rangeGearFromTo, { from = ft.from, to = ft.to, ofs = ft.ofs, overlap = params.rangeGearOverlap[i] } )
		if params.rangeGearOverlap[i] == nil then 
			break 
		end 
		ft.from = ft.from + self.numberOfGears - params.rangeGearOverlap[i]
		ft.to   = ft.to   + self.numberOfGears - params.rangeGearOverlap[i]
		ft.ofs  = ft.ofs  + self.numberOfGears - params.rangeGearOverlap[i]
		i       = i + 1
	end 
	self.changeTimeGears  = Utils.getNoNil( params.timeGears, 750 )
	self.changeTimeRanges = Utils.getNoNil( params.timeRanges, 1000 )
	local n = self.rangeGearFromTo[self.numberOfRanges].ofs + self.numberOfGears 
	self.gearRatios       = {}
	for i=1,n do 		
		if params.gearRatios == nil then 
			r = vehicleControlAddonTransmissionBase.gearRatios[i] 
		else 
			r = params.gearRatios[i]
		end 
		if r == nil then	
			print("Error: not enough gear ratios provided for transmission "..tostring(name))
			r = 1
		end 
		table.insert( self.gearRatios, r )
	end 

	if params.gearTexts == nil then 
		if     self.numberOfGears <= 1 then 
			self.gearTexts = { "" } 
		elseif self.numberOfRanges <= 4 or self.numberOfGears > 4 then 
			self.gearTexts = {} 
			for i=1,self.numberOfGears do 
				self.gearTexts[i] = tostring(i) 
			end 
		elseif self.numberOfGears == 2 then 
			self.gearTexts = { "L", "H" }
		elseif self.numberOfGears == 3 then 
			self.gearTexts = { "L", "M", "H" }
		else 
			self.gearTexts = { "LL", "L", "M", "H" }
		end 
	else 
		self.gearTexts = params.gearTexts 
	end 

	if params.rangeTexts == nil then 
		if     self.numberOfRanges <= 1 then 
			self.rangeTexts = { "" } 
		elseif self.numberOfRanges > 4 then 
			self.rangeTexts = {} 
			for i=1,self.numberOfRanges do 
				self.rangeTexts[i] = tostring(i) 
			end 
		elseif self.numberOfRanges == 2 then 
			self.rangeTexts = { "L", "H" }
		elseif self.numberOfRanges == 3 then 
			self.rangeTexts = { "L", "M", "H" }
		else 
			self.rangeTexts = { "LL", "L", "M", "H" }
		end 
	else 
		self.rangeTexts = params.rangeTexts 
	end 
	
	if params.isIVT then 
		self.isIVT = true 
	else 
		self.isIVT = false 
	end 
	
	if params.autoGears == nil or params.autoGears then 
		self.autoShiftGears = true 
	else 
		self.autoShiftGears = false 
	end 
	
	if params.autoRanges == nil or params.autoRanges then 
		self.autoShiftRange = true 
	else 
		self.autoShiftRange = false 
	end 
	
	if params.splitGears4Shifter == nil or params.splitGears4Shifter then 
		self.splitGears4Shifter = true 
	else 
		self.splitGears4Shifter = false 
	end 
	
	if params.speedMatching == nil then
		self.speedMatching = self.autoShiftGears
	elseif params.speedMatching then 
		self.speedMatching = true 
	else 
		self.speedMatching = false
	end 
	
	if type( params.reverseGears ) == "table" and table.getn( params.reverseGears ) >= 1 then 
		self.blockedRevGears  = {}
		self.reverseGearTexts = {}
		for i=1,self.numberOfGears do 
			self.blockedRevGears[i]  = true 
			self.reverseGearTexts[i] = self.gearTexts[i]
		end 
		local l = 0
		for j,i in pairs( params.reverseGears ) do 
			if 1 <= i and i <= self.numberOfGears then 
				self.numberOfRevGears   = self.numberOfRevGears + 1 
				self.blockedRevGears[i] = false  
				if type( params.reverseGearTexts ) == "table" then 
					if params.reverseGearTexts[j] ~= nil then 
						self.reverseGearTexts[i] = params.reverseGearTexts[j]
					end 
				else 
					self.reverseGearTexts[i]   = "R"..tostring(self.numberOfRevGears)
				end 
				l = i 
			end 
		end 
		if     type( params.reverseGearTexts ) == "table" then 
		-- keep external texts
		elseif self.numberOfRevGears == 1 then 
			self.reverseGearTexts[l] = "R"
		end 
	end 
	
	if type( params.reverseRanges ) == "table" and table.getn( params.reverseRanges ) >= 1 then 
		self.blockedRevRange  = {}
		self.reverseRangeTexts = {} 
		for i=1,self.numberOfRanges do 
			self.blockedRevRange[i]   = true 
			self.reverseRangeTexts[i] = self.rangeTexts[i]
		end 
		local f, l = 0, 0
		for j,i in pairs( params.reverseRanges ) do 
			if 1 <= i and i <= self.numberOfRanges then 
				self.numberOfRevRange   = self.numberOfRevRange + 1 
				self.blockedRevRange[i] = false  
				if type( params.reverseRangeTexts ) == "table" then 
					if params.reverseRangeTexts[j] ~= nil then 
						self.reverseRangeTexts[i] = params.reverseRangeTexts[j]
					end 
				else 
					self.reverseRangeTexts[i]   = "r"..tostring(self.numberOfRevRange)
				end 
				l = i 
				if f <= 0 then 
					f = i 
				end 
			end 
		end
		if     type( params.reverseRangeTexts ) == "table" then 
		-- keep external texts
		elseif self.reverseGearTexts ~= nil and self.numberOfRevRange == 1 then 
			self.reverseRangeTexts[l] = "" 
		elseif f >= l then 
			self.reverseRangeTexts[l] = "R" 
		elseif self.numberOfRevRange <= 3 then 
			self.reverseRangeTexts[f] = "L" 
			self.reverseRangeTexts[l] = "H" 
			for i=f+1,l-1 do 
				if not self.blockedRevRange[i] then 
					self.reverseRangeTexts[l] = "M" 
				end 
			end 
		end 
	end 
	
	if self.blockedRevGears ~= nil or self.blockedRevRange ~= nil then 
		self.blockedRevIndex = {}
		for i,r in pairs( self.gearRatios ) do 
			self.blockedRevIndex[i] = false 
		end 
		
		if self.blockedRevGears ~= nil then 
			for gear,b in pairs( self.blockedRevGears ) do 
				if b then 
					for range=1,self.numberOfRanges do 
						local i = self.rangeGearFromTo[range].ofs + gear 
						self.blockedRevIndex[i] = true 
					end 
				end 
			end 
		end 

		if self.blockedRevRange ~= nil then 
			for range,b in pairs( self.blockedRevRange ) do 
				if b then 
					for gear=1,self.numberOfGears do 
						local i = self.rangeGearFromTo[range].ofs + gear 
						self.blockedRevIndex[i] = true 
					end 
				end 
			end 
		end 
	end 
	
	if params.reverseRatio == nil then 
		self.reverseRatio = 1 
	else 
		self.reverseRatio = params.reverseRatio
	end 
	
	self.shifterIndexList = params.shifterIndexList
	
	return self
end 

function vehicleControlAddonTransmissionBase:delete() 
	self.rangeGearFromTo = nil 
	self.gearTexts       = nil 
	self.rangeTexts      = nil
	self.gearRatios      = nil 
	self.vehicle         = nil 
end 

function vehicleControlAddonTransmissionBase:setVehicle( vehicle )
	self.vehicle = vehicle 
end

function vehicleControlAddonTransmissionBase:initGears( noEventSend )	
	local initGear = false 
	if     self.vehicle.vcaGear < 1 then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaGear", 1, noEventSend )
	elseif self.vehicle.vcaGear > self.numberOfGears then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaGear", self.numberOfGears, noEventSend )
	end 
	if     self.vehicle.vcaRange < 1 then   
		initGear = true 
		self.vehicle:vcaSetState( "vcaRange", 1, noEventSend )
	elseif self.vehicle.vcaRange > self.numberOfRanges then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaRange", self.numberOfRanges, noEventSend )
	end 
	
	if self.blockedRevIndex ~= nil then 
		if self.vehicle:vcaGetIsReverse() then 
			self.lastReverse = true 
			local g, r = self:findBestReverse()
			self.vehicle:vcaSetState( "vcaGear",  g )
			self.vehicle:vcaSetState( "vcaRange", r )
		elseif self.lastReverse then 
			self.lastReverse = false 
			if self.lastGear  ~= nil then 
				self.vehicle:vcaSetState( "vcaGear",  self.lastGear )
				self.lastGear  = nil 
			end 
			if self.lastRange ~= nil then 
				self.vehicle:vcaSetState( "vcaRange", self.lastRange )
				self.lastRange = nil 
			end 
		else 
			if self.blockedRevGears ~= nil and self.blockedRevGears[self.vehicle.vcaGear]  then 
				self.lastGear  = self.vehicle.vcaGear
			else
				self.lastGear  = nil 
			end 
			if self.blockedRevRange ~= nil and self.blockedRevRange[self.vehicle.vcaRange] then 
				self.lastRange = self.vehicle.vcaRange 
			else 
				self.lastRange = nil 
			end 
		end 
	end 
	
	return initGear 
end 

function vehicleControlAddonTransmissionBase:findBestReverse()
	local g, r = self.vehicle.vcaGear, self.vehicle.vcaRange

	if self.blockedRevGears ~= nil and self.vehicle:vcaGetIsReverse() then 
		local j = g
		for i=1,self.numberOfGears do 
			if not self.blockedRevGears[j] then 
				g = j 
				break
			end 
			j = j - 1
			if j < 1 then 
				j = self.numberOfGears 
			end 
		end 
	end 
	
	if self.blockedRevRange ~= nil and self.vehicle:vcaGetIsReverse() then 
		local j = r
		for i=1,self.numberOfRanges do 
			if not self.blockedRevRange[j] then 
				r = j 
				break
			end 
			j = j - 1
			if j < 1 then 
				j = self.numberOfRanges 
			end 
		end 
	end 
	
	vehicleControlAddon.debugPrint(tostring(self.name)..", findBestReverse: "..tostring(self.vehicle.vcaGear)..", "..tostring(self.vehicle.vcaRange).." => "..tostring(g)..", "..tostring(r))	
	
	return g, r 
end 


function vehicleControlAddonTransmissionBase:getName()
	return self.name 
end 

function vehicleControlAddonTransmissionBase:getGearText( gear, range )
	local gt = self.gearTexts[gear]
	local rt = self.rangeTexts[range]

	if self.blockedRevIndex == nil and self.vehicle.vcaSingleReverse ~= 0 and self.vehicle:vcaGetIsReverse() then 
		if self.vehicle.vcaSingleReverse > 0 then 
			gt = "R"
		else
			rt = "R"
		end 
	end 
	
	if self.vehicle:vcaGetIsReverse() then 
		if self.reverseGearTexts ~= nil then 
			gt = self.reverseGearTexts[gear] 
		end 
		if self.reverseRangeTexts ~= nil then 
			rt = self.reverseRangeTexts[range] 
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

function vehicleControlAddonTransmissionBase:getChangeTimeGears ()
	return self.changeTimeGears
end 

function vehicleControlAddonTransmissionBase:getChangeTimeRanges()
	return self.changeTimeRanges
end 

function vehicleControlAddonTransmissionBase:grindingGears()
	if vehicleControlAddon.grindingSample ~= nil and VCAGlobals.grindingSampleVol > 0 then 
		playSample( vehicleControlAddon.grindingSample, 1, VCAGlobals.grindingSampleVol, 0, 0, 0)
	end
end

function vehicleControlAddonTransmissionBase:gearShiftSound()
	if vehicleControlAddon.gearShiftSample ~= nil and VCAGlobals.gearShiftSampleVol > 0 then 
		playSample( vehicleControlAddon.gearShiftSample, 1, VCAGlobals.gearShiftSampleVol, 0, 0, 0)
	end
end

function vehicleControlAddonTransmissionBase:powerShiftSound()
	if self.vehicle ~= nil and self.vehicle.spec_lights ~= nil and self.vehicle.spec_lights.samples ~= nil and self.vehicle.spec_lights.samples.turnLight then 
		g_soundManager:playSample(self.vehicle.spec_lights.samples.turnLight)
	end
end

function vehicleControlAddonTransmissionBase:gearUp()
	vehicleControlAddon.debugPrint(tostring(self.name)..", gearUp: "..tostring(self.vehicle.vcaGear)..", "..tostring(self.numberOfGears))
	
	if self.blockedRevIndex == nil and self.vehicle.vcaSingleReverse > 0 and self.vehicle:vcaGetIsReverse() then 
		return 
	end 
	
	local old = self.vehicle.vcaGear
	local new = self.vehicle.vcaGear + 1
	
	if self.blockedRevGears ~= nil and self.vehicle:vcaGetIsReverse() then 
		while new <= self.numberOfGears and self.blockedRevGears[new] do 
			new = new + 1
		end 
	end 
	
	if new > self.numberOfGears or new == old then  
		return 
	end 

	if self:getChangeTimeGears() > 100 then 
		if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
			self:grindingGears()
			return 
		end 
		self:gearShiftSound()
	else 
		self:powerShiftSound()
	end 

	self.vehicle:vcaSetState( "vcaGear", new )
	vehicleControlAddon.debugPrint(tostring(self.name)..", result: "..tostring(self.vehicle.vcaGear)..", "..tostring(self.numberOfGears))
end 

function vehicleControlAddonTransmissionBase:gearDown()
	
	if self.blockedRevIndex == nil and self.vehicle.vcaSingleReverse > 0 and self.vehicle:vcaGetIsReverse() then 
		return 
	end 
	
	local old = self.vehicle.vcaGear
	local new = self.vehicle.vcaGear - 1
	
	if self.blockedRevGears ~= nil and self.vehicle:vcaGetIsReverse() then 
		while new >= 1 and self.blockedRevGears[new] do 
			new = new - 1
		end 
	end 
	
	if new < 1 or new == old then  
		return 
	end 

	if self:getChangeTimeGears() > 100 then 
		if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
			self:grindingGears()
			return 
		end 
		self:gearShiftSound()
	else 
		self:powerShiftSound()
	end 

	self.vehicle:vcaSetState( "vcaGear", new )
end 

function vehicleControlAddonTransmissionBase:rangeSpeedMatching( noSpeedMatching )
	if      self.vehicle ~= nil 
			and not ( self.vehicle.vcaNeutral )
			and self.speedMatching
			and not self.vehicle.vcaShifterUsed
			and self.rangeGearFromTo[self.vehicle.vcaRange] ~= nil 
			and not ( noSpeedMatching )
			and not self.vehicle:vcaGetAutoHold()
			and ( self.blockedRevGears == nil or not self.vehicle:vcaGetIsReverse() )
			then
		return true 
	end 
	return false 
end 

function vehicleControlAddonTransmissionBase:rangeUp( noSpeedMatching )
	vehicleControlAddon.debugPrint(tostring(self.name)..", rangeUp: "..tostring(self.vehicle.vcaRange)..", "..tostring(self.numberOfRanges))
	
	if self.blockedRevIndex == nil and self.vehicle.vcaSingleReverse < 0 and self.vehicle:vcaGetIsReverse() then 
		return 
	end 
	
	local old = self.vehicle.vcaRange
	local new = self.vehicle.vcaRange + 1
	
	if self.blockedRevRange ~= nil and self.vehicle:vcaGetIsReverse() then 
		while new <= self.numberOfRanges and self.blockedRevRange[new] do 
			new = new + 1
		end 
	end 
	
	if new > self.numberOfRanges or new == old then  
		return 
	end	

	if self:getChangeTimeRanges() > 100 then
		if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
			self:grindingGears()
			return 
		end 
		self:gearShiftSound()
	else 
		self:powerShiftSound()
	end 

	self.vehicle:vcaSetState( "vcaRange", new )
	
	if self:rangeSpeedMatching( noSpeedMatching ) then 
		local j = self:getRatioIndex( self.vehicle.vcaGear, old )
		local r = self.gearRatios[j] 
		local g = 1
		for i=1,self.numberOfGears do 
			g = i 
			local j = self:getRatioIndex( i, self.vehicle.vcaRange )
			if j ~= nil and self.gearRatios[j] ~= nil and self.gearRatios[j] > r * 1.1 then 
				break 
			end 
		end 
		self.vehicle:vcaSetState( "vcaGear", g )				
	end 
	vehicleControlAddon.debugPrint(tostring(self.name)..", result: "..tostring(self.vehicle.vcaRange)..", "..tostring(self.numberOfRanges))
end 

function vehicleControlAddonTransmissionBase:rangeDown( noSpeedMatching )
	
	if self.blockedRevIndex == nil and self.vehicle.vcaSingleReverse < 0 and self.vehicle:vcaGetIsReverse() then 
		return 
	end 
	
	local old = self.vehicle.vcaRange
	local new = self.vehicle.vcaRange - 1
	
	if self.blockedRevRange ~= nil and self.vehicle:vcaGetIsReverse() then 
		while new >= 1 and self.blockedRevRange[new] do 
			new = new - 1
		end 
	end 
	
	if new < 1 or new == old then  
		return 
	end 

	if self:getChangeTimeRanges() > 100 then
		if not ( self.vehicle:vcaGetAutoClutch() or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
			self:grindingGears()
			return 
		end 
		self:gearShiftSound()
	else 
		self:powerShiftSound()
	end 

	self.vehicle:vcaSetState( "vcaRange", new )

	if self:rangeSpeedMatching( noSpeedMatching ) then 
		local j = self:getRatioIndex( self.vehicle.vcaGear, old )
		local r = self.gearRatios[j] 
		local g = self.numberOfGears
		for i=self.numberOfGears,1,-1 do 
			g = i 
			local j = self:getRatioIndex( i, self.vehicle.vcaRange )
			if j ~= nil and self.gearRatios[j] ~= nil and self.gearRatios[j] < r / 1.1 then 
				break 
			end 
		end 
		self.vehicle:vcaSetState( "vcaGear", g )				
	end 
end 

function vehicleControlAddonTransmissionBase:getGearShifterIndeces( maxNum, noSplit )

	if noSplit == nil then 
		noSplit = false 
	end 

	if self.gearShifterIndeces == nil then 
		self.gearShifterIndeces         = {}
		self.gearShifterIndeces[maxNum] = {} 
	elseif self.gearShifterIndeces[maxNum] == nil then 
		self.gearShifterIndeces[maxNum] = {} 
	elseif self.gearShifterIndeces[maxNum][noSplit] ~= nil then 
		return self.gearShifterIndeces[maxNum][noSplit]
	end 

	self.gearShifterIndeces[maxNum][noSplit] = {}
	
	if noSplit then 
		for i=1,maxNum do 
			table.insert( self.gearShifterIndeces[maxNum][noSplit], math.max( 1, i + self.numberOfGears - maxNum ) )
		end 
	else 
		local maxI = maxNum + maxNum 
		local numGears = self:getNumberOfRatios()	
		for i=1,maxI do 
			table.insert( self.gearShifterIndeces[maxNum][noSplit], math.max( 1, i + numGears - maxI ) )
		end 
	end 

	return self.gearShifterIndeces[maxNum][noSplit]
end 

function vehicleControlAddonTransmissionBase:getGearRatio( index )
	if self.reverseRatio ~= 1 and self.vehicle:vcaGetIsReverse() then 
		return self.gearRatios[index] * self.reverseRatio
	end 
	return self.gearRatios[index]
end 

function vehicleControlAddonTransmissionBase:getNumberOfRatios()
	return table.getn( self.gearRatios )
end 

function vehicleControlAddonTransmissionBase:getAutoShiftIndeces( curRatio, lowRatio, searchDown, searchUp )
	local gearList = {}
	
	local delta = 0
	if self.vehicle.vcaMaxSpeed ~= nil and self.vehicle.vcaMaxSpeed > 0 then 
		delta = 0.5 / self.vehicle.vcaMaxSpeed 
	end
	
	local ag = self.autoShiftGears
	local ar = self.autoShiftRange
	local cg = self.vehicle.vcaGear
	local cr = self.vehicle.vcaRange

	if self.blockedRevIndex == nil and self.vehicle.vcaSingleReverse ~= 0 and self.vehicle:vcaGetIsReverse() then 
		if self.vehicle.vcaSingleReverse > 0 then 
			ag = false 
			cg = math.min( self.vehicle.vcaSingleReverse, self.numberOfGears )
		else
			ar = false 
			cr = math.min( -self.vehicle.vcaSingleReverse, self.numberOfRanges )
		end 
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
	
	if ag and ar then 
		for i=1,table.getn( self.gearRatios ) do 
			local r = self.gearRatios[i]
			if 			( rf <= r and r <= rt )
					and ( ( r < curRatio and searchDown and r >= lowRatio ) or ( searchUp and r > curRatio ) )
					and not ( self.blockedRevIndex ~= nil and self.vehicle:vcaGetIsReverse() and self.blockedRevIndex[i] ) 
					then 
				table.insert( gearList, i )
			end 
		end 
	elseif not ag and not ar then 
	else
		local tmpList = nil
		if     ag then 
			tmpList = self:getRatioIndexListOfRange( cr )
		elseif ar then 
			tmpList = self:getRatioIndexListOfGear( cg )
		end 
		if tmpList ~= nil then 
			for _,i in pairs(tmpList) do 
				local r = self.gearRatios[i]
				if 			( rf <= r and r <= rt )
						and ( ( r < curRatio and searchDown and r >= lowRatio ) or ( searchUp and r > curRatio ) ) 
						and not ( self.blockedRevIndex ~= nil and self.vehicle:vcaGetIsReverse() and self.blockedRevIndex[i] ) 
						then 
					table.insert( gearList, i )
				end 
			end 
		end 
	end 
	
	return gearList
end 

function vehicleControlAddonTransmissionBase:getRatioIndex( gear, range )
	if self.blockedRevIndex == nil and self.vehicle.vcaSingleReverse ~= 0 and self.vehicle:vcaGetIsReverse() then 
		if self.vehicle.vcaSingleReverse > 0 then
			gear  =  self.vehicle.vcaSingleReverse
		else
			range = -self.vehicle.vcaSingleReverse
		end 
	end 
	if gear == nil or range == nil or self.rangeGearFromTo[range] == nil then 
		return 0
	end
	return self.rangeGearFromTo[range].ofs + gear 
end 

function vehicleControlAddonTransmissionBase:getBestGearRangeFromIndex( oldGear, oldRange, index )
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

function vehicleControlAddonTransmissionBase:getRatioIndexListOfGear( gear )
	local list = {}
	
	if self.vehicle ~= nil then 
		self.vehicle.vcaDebugG = "" 
	end 
	
	for i,r in pairs(self.rangeGearFromTo) do 
		local i = gear + r.ofs
		if self.gearRatios[i] ~= nil and not ( self.blockedRevIndex ~= nil and self.vehicle:vcaGetIsReverse() and self.blockedRevIndex[i] ) then 
			table.insert( list, i ) 
			
			if self.vehicle ~= nil then 
				self.vehicle.vcaDebugG = self.vehicle.vcaDebugG .. string.format( "%d  ",i )
			end 
		end 
	end 
	return list 
end 

function vehicleControlAddonTransmissionBase:getRatioIndexListOfRange( range )
	if self.rangeGearFromTo[range] == nil then 
		return {} 
	end 
	list = {}

	if self.vehicle ~= nil then 
		self.vehicle.vcaDebugR = "" 
	end 
	
	for i=self.rangeGearFromTo[range].from,self.rangeGearFromTo[range].to do	
		if self.gearRatios[i] ~= nil and not ( self.blockedRevIndex ~= nil and self.vehicle:vcaGetIsReverse() and self.blockedRevIndex[i] ) then 
			table.insert( list, i )
			if self.vehicle ~= nil then 
				self.vehicle.vcaDebugR = self.vehicle.vcaDebugR .. string.format( "%d  ",i )
			end 
		end 
	end 
	return list
end 

-- vehicleControlAddon.g27Mode6R 
-- vehicleControlAddon.g27Mode6S 
-- vehicleControlAddon.g27Mode6D 
-- vehicleControlAddon.g27Mode8R 
-- vehicleControlAddon.g27Mode8S 
-- vehicleControlAddon.g27Mode4RR
-- vehicleControlAddon.g27Mode4RS
-- vehicleControlAddon.g27Mode4RD
-- vehicleControlAddon.g27ModeSGR

function vehicleControlAddonTransmissionBase:actionCallback( actionName, keyStatus )
	vehicleControlAddon.debugPrint(tostring(self.name)..": "..actionName)
	if     actionName == "vcaGearUp"   then
		self.vehicle:vcaSetState("vcaShifterUsed", false)
		self:gearUp()
	elseif actionName == "vcaGearDown" then
		self.vehicle:vcaSetState("vcaShifterUsed", false)
		self:gearDown()
	elseif actionName == "vcaRangeUp"  then
		self.vehicle:vcaSetState("vcaShifterUsed", false)
		self:rangeUp()
	elseif actionName == "vcaRangeDown"then
		self.vehicle:vcaSetState("vcaShifterUsed", false)
		self:rangeDown()
	else
		self.vehicle:vcaSetState("vcaShifterUsed", true)
		if     self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RR
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RS
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RD then 
			if     actionName == "vcaShifter1" then
				self:gearShifter( 1, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter2" then
				self:gearShifter( 2, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter3" then
				self:gearShifter( 3, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter4" then
				self:gearShifter( 4, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter7" then
				self:gearShifter( 5, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter8" then
				self:gearShifter( 6, keyStatus >= 0.5 )
			elseif keyStatus < 0.5 then 
			-- nothing
			elseif actionName == "vcaShifter5" then
				self:rangeUp( true )
			elseif actionName == "vcaShifter6" then
				self:rangeDown( true )
			end 
		elseif self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6RR
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6RS then 
			if     actionName == "vcaShifter1" then
				self:gearShifter( 1, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter2" then
				self:gearShifter( 2, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter3" then
				self:gearShifter( 3, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter4" then
				self:gearShifter( 4, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter5" then
				self:gearShifter( 5, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter6" then
				self:gearShifter( 6, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter9" then
				self:gearShifter( 7, keyStatus >= 0.5 )
			elseif keyStatus < 0.5 then 
			-- nothing
			elseif actionName == "vcaShifter7" then
				self:rangeUp( true )
			elseif actionName == "vcaShifter8" then
				self:rangeDown( true )
			end 
		elseif self.vehicle.vcaG27Mode == vehicleControlAddon.g27ModeSGR then 
			if     keyStatus < 0.5 then 
			-- nothing
				if actionName == "vcaShifter1" or actionName == "vcaShifter2" then
					self.vehicle:vcaSetState( "vcaNeutral", true )
				end 
			elseif actionName == "vcaShifter1" then
				self.vehicle:vcaSetState( "vcaNeutral", false )
				self.vehicle:vcaSetState( "vcaShuttleFwd", true )
			elseif actionName == "vcaShifter2" then
				self.vehicle:vcaSetState( "vcaNeutral", false )
				self.vehicle:vcaSetState( "vcaShuttleFwd", false )
			elseif actionName == "vcaShifter3" then
				self:gearUp()
			elseif actionName == "vcaShifter4" then
				self:gearDown()
			elseif actionName == "vcaShifter5" then
				self:rangeUp( true )
			elseif actionName == "vcaShifter6" then
				self:rangeDown( true )
			elseif actionName == "vcaShifter7" then
				self.vehicle:vcaSetState( "vcaNeutral", not self.vehicle.vcaNeutral )
			end 
		else
			if     actionName == "vcaShifter1" then
				self:gearShifter( 1, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter2" then
				self:gearShifter( 2, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter3" then
				self:gearShifter( 3, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter4" then
				self:gearShifter( 4, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter5" then
				self:gearShifter( 5, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter6" then
				self:gearShifter( 6, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter7" then 
				self:gearShifter( 7, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter8" then 
				self:gearShifter( 8, keyStatus >= 0.5 )
			elseif actionName == "vcaShifter9" then 
				self:gearShifter( 9, keyStatus >= 0.5 )
			elseif keyStatus < 0.5 then 
			-- nothing
			elseif actionName == "vcaShifterLH" and self.vehicle.vcaShifterIndex > 0 then 
				self.vehicle:vcaSetState( "vcaShifterLH", not self.vehicle.vcaShifterLH )
				if not self.vehicle.vcaNeutral then 
					self:gearShifter( self.vehicle.vcaShifterIndex, keyStatus >= 0.5 )
				end 
			end 
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:getG27ShifterOnGears()
	if     self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RR
			or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RS
			or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RD then 
		return true 
	elseif self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6RR
			or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6RS then 
		return true 
	end 
	return false 
end 

function vehicleControlAddonTransmissionBase:gearShifter( number, isPressed )
	if not isPressed then 
		self.vehicle:vcaSetState( "vcaNeutral", true )
		if self.vehicle.spec_motorized.motor.vcaLoad ~= nil and math.abs( self.vehicle.lastSpeedReal ) * 3600 > 1 then  
			self.vehicle:vcaSetState("vcaBOVVolume",self.vehicle.spec_motorized.motor.vcaLoad)
		end 
	else 
		local goFwd   = nil 
		local num2    = 0
		local maxNum  = 6 
		local noSplit = self:getG27ShifterOnGears()
		
		if     self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode8R  
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode8S  then 
			maxNum = 8
		elseif self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RR
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RS
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RD then 
			maxNum  = 4
		elseif self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6RR
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6RS then 
			maxNum  = 6
		end 
		
		local list  
		if self.shifterIndexList == nil then 
			list  = self:getGearShifterIndeces( maxNum, noSplit )
		else 
			list = self.shifterIndexList
		end 
				
		if number <= maxNum then 			
			if self.vehicle.vcaShifter7isR1 then 
				goFwd = true 
			end 
			
			if noSplit then 
				num2 = number 
			elseif self.splitGears4Shifter then 
				num2 =  number + number 
				if not self.vehicle.vcaShifterLH and num2 > 1 then 
					num2 = num2 - 1
				end 
			else 
				if self.vehicle.vcaShifterLH then 
					num2 = number + maxNum 
				else 
					num2 = number 
				end 
			end 
		elseif not self.vehicle.vcaShuttleCtrl then 
			return 
		elseif self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6S
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode8S
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RS
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6RS then 
			self.vehicle:vcaSetState( "vcaShuttleFwd", not self.vehicle.vcaShuttleFwd )
			return 
		elseif self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode6D
				or self.vehicle.vcaG27Mode == vehicleControlAddon.g27Mode4RD then 
			if number == maxNum + 1 then 
				self.vehicle:vcaSetState( "vcaShuttleFwd", true )
			else 
				self.vehicle:vcaSetState( "vcaShuttleFwd", false )
			end 
			return 
		else 
			goFwd = false 
			
			if noSplit then 
				num2 = 1
			elseif self.splitGears4Shifter then 
				num2 = 2
				for i,l in pairs(list) do  
					if i > 1 and self.gearRatios[l] * self.vehicle.vcaMaxSpeed > self.vehicle.vcaLaunchSpeed then 
						break 
					end 
					num2 = i  
				end 
				if not self.vehicle.vcaShifterLH and num2 > 1 then 
					num2 = num2 - 1
				elseif self.vehicle.vcaShifterLH and num2 == 1 then 
					num2 = 2
				end 
			else 
				if self.vehicle.vcaShifterLH then 
					num2 = number 
				else 
					num2 = number - maxNum 
				end 
			end 
		end 
		
		local index = list[num2] 
		if index == nil then 
			print("Cannot find correct gear for shifter position "..tostring(number))
			return 
		end 
		
		local g, r
		if noSplit then 
			g = index 
			r = nil
		else 
			g, r = self:getBestGearRangeFromIndex( self.vehicle.vcaGear, self.vehicle.vcaRange, index )
		end 
		
		vehicleControlAddon.debugPrint( tostring(number).." "..tostring(isPressed)..": "..
																		tostring(maxNum)..", "..tostring(self.vehicle.vcaShifterLH)..", "..tostring(self.splitGears4Shifter)..", "..
																		tostring(noSplit).." => "..tostring(num2)..", "..tostring(index)..", "..tostring(g)..", "..tostring(r)..", "..tostring(goFwd))
		
		if not ( self.vehicle:vcaGetAutoClutch() ) and self.vehicle.vcaClutchPercent < 1
				and ( ( g ~= self.vehicle.vcaGear  and self:getChangeTimeGears()  > 100 )
					 or ( r ~= self.vehicle.vcaRange and self:getChangeTimeRanges() > 100 ) ) then 
			self:grindingGears()
		else 
			self.vehicle:vcaSetState( "vcaShifterIndex", number )
			self.vehicle:vcaSetState( "vcaGear", g )
			if r ~= nil then 
				self.vehicle:vcaSetState( "vcaRange", r )
			end 
			self.vehicle:vcaSetState( "vcaNeutral", false )
			if goFwd ~= nil then
				self.vehicle:vcaSetState( "vcaShuttleFwd", goFwd )
			end
		end 
	end 
end 


--( name, noGears, timeGears, rangeGearOverlap, timeRanges, gearRatios, autoGears, autoRanges, splitGears4Shifter, gearTexts, rangeTexts, shifterIndexList, speedMatching )
vehicleControlAddonTransmissionBase.transmissionList = 
	{ { class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "IVT",
								 isIVT              = true,
			           noGears            = 1, 
			           rangeGearOverlap   = {}, 
			           gearRatios         = { 1.0 }, 
			           gearTexts          = {""}, 
			           rangeTexts         = {""} },
			text   = "IVT" }, 
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "4x4", 
                 noGears            = 4, 
                 rangeGearOverlap   = {2,1,1}, 
								 timeRanges         = 1000,
								 autoRanges         = false,
								 speedMatching      = false },
			text   = "4x4" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { name               = "4PS",
                 noGears            = 4,
								 timeGears          = 0,
                 rangeGearOverlap   = {2,1,1}, 
                 timeRanges         = 750 },
			text   = "4x4 PowerShift" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { name               = "2x6",
                 noGears            = 6,
                 rangeGearOverlap   = {0},
								 reverseGears       = { 3, 6 },
								 reverseRanges      = { 1 },
								 reverseGearTexts   = { "RL",  "RH" },
								 shifterIndexList   = { 1,7, 2,8, 3,9, 4,10, 5,11, 6,12, 3,6 } },
			text   = "2x6" },
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "FPS", 
                 noGears            = 12, 
                 timeGears          = 0, 
                 rangeGearOverlap   = {} },
			text   = "FullPowerShift" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { name               = "6PS", 
                 noGears            = 2, 
                 timeGears          = 0, 
                 rangeGearOverlap   = {0,0,0,0,0}, 
                 timeRanges         = 750,
                 gearTexts          = {"-", "+"}, 
                 speedMatching      = false },
			text   = "6 Gears with Splitter" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { name               = "64A", 
                 noGears            = 4, 
                 timeGears          = 0, 
                 rangeGearOverlap   = {0,0,0,0,0}, 
                 timeRanges         = 750, 
                 gearRatios         = { 0.0638968, 0.0766104, 0.0916914, 0.1096000,
																				0.1149676, 0.1378428, 0.1649775, 0.1972000,
																				0.1844612, 0.2211636, 0.2647002, 0.3164000,
																				0.2778578, 0.3331434, 0.3987236, 0.4766000,
																				0.3820982, 0.4581246, 0.5483076, 0.6554000,
																				0.5830000, 0.6990000, 0.8366000, 1.0000000 }, 
                 autoRanges         = false, 
                 gearTexts          = {"A","B","C","D"}, 
                 rangeTexts         = {"1","2","3","4","5","6"}, 
                 shifterIndexList   = { 3, 4, 7, 8, 11, 12, 15, 16, 19, 20, 23, 24, 3, 4 } },
			text   = "6x4 AutoPowerShift" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { name               = "PKW", 
                 noGears            = 6, 
                 timeGears          = 500, 
                 rangeGearOverlap   = {3}, 1000, 
                 gearRatios         = { 0.1, 0.15, 0.2, 
																				0.2778, 0.3889, 0.5278, 0.7222, 1, 1.3889 }, 
								 reverseGears       = { 1 },
								 reverseRatio       = 1.2,
								 shifterIndexList   = { 1,4, 2,5, 3,6, 4,7, 5,8, 6,9, 1,4 },
                 autoRanges         = false },
			text   = "Car with low range" },
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "VARIO",
								 isIVT              = true,
			           noGears            = 1, 
			           rangeGearOverlap   = {0}, 
			           gearRatios         = { 0.5, 1.0 }, 
			           autoRanges         = false, 
			           gearTexts          = {""}, 
			           rangeTexts         = { "I", "II" } },
			text   = "Vario" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { name               = "46A", 
                 noGears            = 6, 
                 timeGears          = 0, 
                 rangeGearOverlap   = {0,0,0}, 
                 timeRanges         = 750, 
                 gearRatios         = { 0.0305810,	0.0364330,	0.0434047,	0.0517105,	0.0616057,	0.0733945,
																				0.0825688,	0.0983690,	0.1171927,	0.1396184,	0.1663355,	0.1981651,
																				0.1582569,	0.1885406,	0.2246193,	0.2676020,	0.3188098,	0.3798165,
																				0.4166667,	0.4963992,	0.5913890,	0.7045560,	0.8393783,	1.0000000 }, 
                 autoRanges         = false, 
                 gearTexts          = {"1","2","3","4","5","6"}, 
                 rangeTexts         = {"A","B","C","D"}, 
                 shifterIndexList   = { 7, 9, 13, 15, 17, 18, 19, 20, 21, 22, 23, 24, 13, 17 } },
			text   = "4x6 HexaShift" },
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "HAR",
								 isIVT              = true,
			           noGears            = 1, 
			           rangeGearOverlap   = {0,0}, 
			           gearRatios         = { 0.3, 0.5, 1.0 }, 
			           autoRanges         = false, 
			           gearTexts          = {""}, 
			           rangeTexts         = { "1", "2", "3" } },
			text   = "Harvester" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { name               = "DSG", 
                 noGears            = 8, 
                 timeGears          = 0, 
                 rangeGearOverlap   = {0,0}, 
                 timeRanges         = 750, 
                 gearRatios         = { 0.0416667,	0.0508333,	0.0620167,	0.0756603,	0.0923056,	0.1126128, 0.1373877, 0.1676131,
																				0.0838065,	0.1022439,	0.1247376,	0.1521798,	0.1856594,	0.2265044, 0.2763354, 0.3371292,
																				0.2497253,	0.3046649,	0.3716912,	0.4534633,	0.5532252,	0.6749347, 0.8234203, 1.0000000 }, 
                 autoRanges         = false, 
                 gearTexts          = {"1","2","3","4","5","6","7","8"}, 
                 rangeTexts         = {"A","B","C"}, 
                 shifterIndexList   = { 7, 9, 13, 15, 17, 18, 19, 20, 21, 22, 23, 24, 13, 17 } },
			text   = "Direct Drive" },
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "F16", 
                 noGears            = 16, 
                 timeGears          = 0, 
                 gearRatios         = { 0.051219512, 0.068292683, 0.090243902, 0.12195122 ,
                                        0.136585366, 0.156097561, 0.180487805, 0.209756098,
																				0.241463415, 0.27804878 , 0.324390244, 0.373170732,
																				0.43902439 , 0.587804878, 0.782926829, 1 },
								 reverseGears       = { 1, 5, 7, 11, 13 },
								 reverseRatio       = 0.92,
								 shifterIndexList   = { 1,3, 5,7, 9,10, 11,12, 13,14, 15,16, 7,13 },
                 rangeGearOverlap   = {} },
			text   = "16x5 full power shift" },
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "E23", 
                 noGears            = 23, 
                 timeGears          = 0, 
                 gearRatios         = { 0.04467354 , 0.049828179, 0.058419244, 0.067010309,
                                        0.077319588, 0.089347079, 0.103092784, 0.118556701,
																				0.135738832, 0.156357388, 0.180412371, 0.20790378 ,
																				0.240549828, 0.274914089, 0.317869416, 0.369415808,
																				0.426116838, 0.493127148, 0.568728522, 0.654639175,
																				0.756013746, 0.865979381, 1 }, 
								 reverseGears       = { 1, 3, 5, 7, 8, 10, 12, 14, 16, 18, 20 },
								 reverseRatio       = 0.935,
								 shifterIndexList   = { 1,3, 5,7, 9,11, 13,15, 17,19, 21,23, 10, 14 },
                 rangeGearOverlap   = {} },
			text   = "John Deere e23" },
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { name               = "OWN", 
                 noGears            = 1, 
                 rangeGearOverlap   = {},
								 autoRanges         = false,
								 autoGears          = true,
								 speedMatching      = true },
			text   = "own configuration" },
	}
vehicleControlAddonTransmissionBase.ownTransmission  = table.getn( vehicleControlAddonTransmissionBase.transmissionList )


function vehicleControlAddonTransmissionBase.loadSettings()
	if g_server == nil or g_client == nil then return end 

	local file = getUserProfileAppPath().. "modsSettings/FS19_VehicleControlAddon/transmissions.xml"
	
	if fileExists(file) then	
		print('Loading "'..tostring(file)..'"...')
	
		local xmlFile = loadXMLFile( "vehicleControlAddonTransmissionBase", file, "transmissions" )
		local i = 0
		while true do
			local key  = string.format( "transmissions.transmission(%d)", i )
			local label = getXMLString( xmlFile, key.."#label" )
			if label == nil then 
				break 
			end 
			i = i + 1 
			
			local name               = string.format( "X%02d", i )

      local timeGears          = nil
      local timeRanges         = nil
      local autoGears          = nil
      local autoRanges         = nil
			local rangeGearOverlap   = {}
			local gearRatios         = nil
			local gearTexts          = nil
			local rangeTexts         = nil
			local shifterIndexList   = nil
			local speedMatching      = nil

			local splitGears4Shifter = getXMLBool( xmlFile, key.."#splitGears4Shifter" )
			local noGears            = getXMLInt(  xmlFile, key.."#numberOfGears" )
			
			local j
			
		--print("Transmission: "..tostring(label))
			
			if getXMLFloat( xmlFile, key..".gears.gear(1)#speed" ) ~= nil then 
			--print("gears and ranges")
			
				local gears = {} 
				
				local baseSpeed = getXMLFloat( xmlFile, key..".gears#baseSpeed" )
				timeGears       = getXMLInt(   xmlFile, key..".gears#shiftTimeMs" )
				timeRanges      = getXMLInt(   xmlFile, key..".ranges#shiftTimeMs" )
				autoGears       = true 
				autoRanges      = false 
				gearRatios      = {}
				local maxSpeed  = 0
				
				j = 0
				while true do 
					local key2  = key..string.format( ".gears.gear(%d)", j )
					local speed = getXMLFloat( xmlFile, key2.."#speed" ) 
					if speed == nil then 
						break 
					end 
					
					table.insert( gears, speed )
					
					if maxSpeed < speed then 
						maxSpeed = speed 
					end 
					
					local text = getXMLString( xmlFile, key2.."#text" ) 
					if text ~= nil then 
						if j == 0 then 
							gearTexts = { text } 
						elseif gearTexts  ~= nil then 
							table.insert( gearTexts, text ) 
						end 
					end
					j = j + 1 
				end 
				
				if #gears < 1 then 
					if baseSpeed == nil then 
						baseSpeed = 1 
					end 
					gears = { baseSpeed }
				elseif baseSpeed == nil then 
					baseSpeed = maxSpeed 
				end 
				
				noGears = #gears 
				
				j = 0
				while true do 
					local key2  = key..string.format( ".ranges.range(%d)", j )
					local ratio = getXMLFloat( xmlFile, key2.."#ratio" ) 
					if ratio == nil then
						if j == 0 then 
							for _,g in pairs(gears) do 
								table.insert( gearRatios, g / baseSpeed )
							end 
						end 
						break 
					end 
					
					for _,g in pairs(gears) do 
						table.insert( gearRatios, g * ratio / baseSpeed )
					end 
					
					if j > 0 then 
						table.insert( rangeGearOverlap, 0 )
					end 
					
					local text = getXMLString( xmlFile, key2.."#text" ) 
					if text ~= nil then 
						if j == 0 then 
							rangeTexts = { text } 
						elseif rangeTexts  ~= nil then 
							table.insert( rangeTexts, text ) 
						end 
					end
					j = j + 1 
				end 
				
			elseif noGears ~= nil then 
			--print("gears and ranges with offset")
				
				timeGears          = getXMLInt(  xmlFile, key.."#gearShiftTimeMs" )
				timeRanges         = getXMLInt(  xmlFile, key.."#rangeShiftTimeMs" )
				autoGears          = getXMLBool( xmlFile, key.."#autoShiftGears" )
				autoRanges         = getXMLBool( xmlFile, key.."#autoShiftRanges" )
				speedMatching      = getXMLBool( xmlFile, key.."#rangeSpeedMatching" )
				
				j = 0
				while true do 
					local key2   = key..string.format( ".gearRatios.gearRatio(%d)", j )
					local number = getXMLFloat( xmlFile, key2.."#value" ) 
				--print(tostring(key2)..": "..tostring(number))
					if number == nil then
						break 
					end 
					if j == 0 then 
						gearRatios = { number } 
					else 
						table.insert( gearRatios, number ) 
					end 
					j = j + 1 
				end 
				
				j = 0
				while true do 
					local key2   = key..string.format( ".rangeGearOffsets.rangeGearOffset(%d)", j )
					local number = getXMLInt( xmlFile, key2.."#value" ) 
				--print(tostring(key2)..": "..tostring(number))
					if number == nil then
						break 
					end 
					local offset = noGears - number
					table.insert( rangeGearOverlap, offset ) 
					j = j + 1 
				end 
				
				j = 0
				while true do 
					local key2 = key..string.format( ".gearTexts.gearText(%d)", j )
					local text = getXMLString( xmlFile, key2.."#value" ) 
				--print(tostring(key2)..": "..tostring(text))
					if text == nil then
						break 
					end 
					if j == 0 then 
						gearTexts = { text } 
					else 
						table.insert( gearTexts, text ) 
					end 
					j = j + 1 
				end 
				
				j = 0
				while true do 
					local key2 = key..string.format( ".rangeTexts.rangeText(%d)", j )
					local text = getXMLString( xmlFile, key2.."#value" ) 
				--print(tostring(key2)..": "..tostring(text))
					if text == nil then
						break 
					end 
					if j == 0 then 
						rangeTexts = { text } 
					else 
						table.insert( rangeTexts, text ) 
					end 
					j = j + 1 
				end 
				
			end 
			
			if noGears ~= nil and noGears > 0 then 		
				print("Transmission: "..tostring(label)..", #gears "..tostring(noGears)..", #ranges "..tostring(#rangeGearOverlap+1))

				table.insert( vehicleControlAddonTransmissionBase.transmissionList, 
											{ class  = vehicleControlAddonTransmissionBase,
												params = { name               = name,
                                   noGears            = noGears,
                                   timeGears          = timeGears,
                                   rangeGearOverlap   = rangeGearOverlap,
                                   timeRanges         = timeRanges,
                                   gearRatios         = gearRatios,
                                   autoGears          = autoGears,
                                   autoRanges         = autoRanges,
                                   splitGears4Shifter = splitGears4Shifter,
                                   gearTexts          = gearTexts,
                                   rangeTexts         = rangeTexts,
                                   shifterIndexList   = shifterIndexList,
                                   speedMatching      = speedMatching },
												text   = label } )
			end 		
		end 		
	end 

end 




