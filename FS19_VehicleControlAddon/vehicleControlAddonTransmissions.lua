function vcaClass(subClass, baseClass)
	if baseClass == nil then 
		return { __metatable = subClass, __index  = subClass }
	end 
	return { __metatable = subClass, __index = baseClass }
end

vehicleControlAddonTransmissionBase = {}
vehicleControlAddonTransmissionBase_mt = vcaClass(vehicleControlAddonTransmissionBase)

vehicleControlAddonTransmissionBase.gearRatios = { 0.120, 0.145, 0.176, 0.213, 0.259, 0.314, 0.381, 0.462, 0.560, 0.680, 0.824, 1.000 }


function vehicleControlAddonTransmissionBase:new( name, noGears, timeGears, rangeGearOverlap, timeRanges, gearRatios, autoGears, autoRanges, splitGears4Shifter, gearTexts, rangeTexts )
	local self = {}

	if mt == nil then 
		setmetatable(self, vehicleControlAddonTransmissionBase_mt)
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
		table.insert( self.rangeGearFromTo, { from = ft.from, to = ft.to, ofs = ft.ofs, overlap = rangeGearOverlap[i] } )
		if rangeGearOverlap[i] == nil then 
			break 
		end 
		ft.from = ft.from + self.numberOfGears - rangeGearOverlap[i]
		ft.to   = ft.to   + self.numberOfGears - rangeGearOverlap[i]
		ft.ofs  = ft.ofs  + self.numberOfGears - rangeGearOverlap[i]
		i       = i + 1
	end 
	self.changeTimeGears  = Utils.getNoNil( timeGears, 750 )
	self.changeTimeRanges = Utils.getNoNil( timeRanges, 1000 )
	local n = self.rangeGearFromTo[self.numberOfRanges].ofs + self.numberOfGears 
	self.gearRatios       = {}
	for i=1,n do 		
		if gearRatios == nil then 
			r = vehicleControlAddonTransmissionBase.gearRatios[i] 
		else 
			r = gearRatios[i]
		end 
		if r == nil then	
			print("Error: not enough gear ratios provided for transmission "..tostring(name))
			r = 1
		end 
		table.insert( self.gearRatios, r )
	end 

	if gearTexts == nil then 
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
		self.gearTexts = gearTexts 
	end 

	if rangeTexts == nil then 
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
		self.rangeTexts = rangeTexts 
	end 
	
	if autoGears == nil then 
		self.autoShiftGears = true 
	elseif autoGears  then 
		self.autoShiftGears = true 
	else 
		self.autoShiftGears = false 
	end 
	
	if autoRanges == nil then 
		self.autoShiftRange = true 
	elseif autoRanges  then 
		self.autoShiftRange = true 
	else 
		self.autoShiftRange = false 
	end 
	
	if splitGears4Shifter == nil then 
		self.splitGears4Shifter = true 
	elseif splitGears4Shifter then 
		self.splitGears4Shifter = true 
	else 
		self.splitGears4Shifter = false 
	end 
	
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
	if     self.vehicle.vcaGear == 0 then 
		initGear = true 
		self.vehicle:vcaSetState( "vcaGear", 1, noEventSend )
		self.vehicle:vcaSetState( "vcaRange", self.numberOfRanges, noEventSend )			
	elseif self.vehicle.vcaGear < 1 then 
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
	return initGear 
end 

function vehicleControlAddonTransmissionBase:getName()
	return self.name 
end 

function vehicleControlAddonTransmissionBase:getGearText( gear, range )
	if self.rangeTexts[range] ~= nil and self.gearTexts[gear] ~= nil then 
		return self.rangeTexts[range].." "..self.gearTexts[gear]
	elseif self.rangeTexts[range] ~= nil then 
		return self.rangeTexts[range] ~= nil 
	elseif self.gearTexts[gear] then 
		return self.gearTexts[gear]
	end 
	return ""
end 

function vehicleControlAddonTransmissionBase:grindingGears()
	if vehicleControlAddon.grindingSample ~= nil then 
		playSample( vehicleControlAddon.grindingSample, 1, 1, 0, 0, 0)
	end
end

function vehicleControlAddonTransmissionBase:gearShiftSound()
	if vehicleControlAddon.gearShiftSample ~= nil then 
		playSample( vehicleControlAddon.gearShiftSample, 1, 1, 0, 0, 0)
	end
end

function vehicleControlAddonTransmissionBase:powerShiftSound()
	if self.vehicle ~= nil and self.vehicle.spec_lights ~= nil and self.vehicle.spec_lights.samples ~= nil and self.vehicle.spec_lights.samples.turnLight then 
		g_soundManager:playSample(self.vehicle.spec_lights.samples.turnLight)
	end
end

function vehicleControlAddonTransmissionBase:gearUp()
	vehicleControlAddon.debugPrint(tostring(self.name)..", gearUp: "..tostring(self.vehicle.vcaGear)..", "..tostring(self.numberOfGears))
	self.vehicle:vcaSetState("vcaShifterIndex", 0)
	if self.vehicle.vcaGear < self.numberOfGears then 
		if self.changeTimeGears > 100 then 
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaGear", self.vehicle.vcaGear + 1 )
		vehicleControlAddon.debugPrint(tostring(self.name)..", result: "..tostring(self.vehicle.vcaGear)..", "..tostring(self.numberOfGears))
	end 
end 

function vehicleControlAddonTransmissionBase:gearDown()
	self.vehicle:vcaSetState("vcaShifterIndex", 0)
	if self.vehicle.vcaGear > 1 then 
		if self.changeTimeGears > 100 then 
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
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

function vehicleControlAddonTransmissionBase:rangeUp()
	vehicleControlAddon.debugPrint(tostring(self.name)..", rangeUp: "..tostring(self.vehicle.vcaRange)..", "..tostring(self.numberOfRanges))
	if self.vehicle.vcaRange < self.numberOfRanges then 
		if self.changeTimeRanges > 100 then
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		local o
		if self.vehicle.vcaShifterIndex <= 0 and self.rangeGearFromTo[self.vehicle.vcaRange] ~= nil then 
			o = self.rangeGearFromTo[self.vehicle.vcaRange].overlap
		end 
		self.vehicle:vcaSetState( "vcaRange", self.vehicle.vcaRange + 1 )
		if o ~= nil then 
			o = self.numberOfGears - o - 1
			self.vehicle:vcaSetState( "vcaGear", math.max( 1, self.vehicle.vcaGear - o ) )
		end 
		vehicleControlAddon.debugPrint(tostring(self.name)..", result: "..tostring(self.vehicle.vcaRange)..", "..tostring(self.numberOfRanges))
	end 
end 

function vehicleControlAddonTransmissionBase:rangeDown()
	if self.vehicle.vcaRange > 1 then 
		if self.changeTimeRanges > 100 then
			if not ( self.vehicle.vcaAutoClutch or self.vehicle.vcaNeutral ) and self.vehicle.vcaClutchPercent < 1 then 
				self:grindingGears()
				return 
			end 
			self:gearShiftSound()
		else 
			self:powerShiftSound()
		end 
		self.vehicle:vcaSetState( "vcaRange", self.vehicle.vcaRange - 1 )
		local o
		if self.vehicle.vcaShifterIndex <= 0 and self.rangeGearFromTo[self.vehicle.vcaRange] ~= nil then 
			o = self.rangeGearFromTo[self.vehicle.vcaRange].overlap
		end 
		if o ~= nil then 
			o = self.numberOfGears - o - 1
			self.vehicle:vcaSetState( "vcaGear", math.min( self.numberOfGears, self.vehicle.vcaGear + o ) )
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:gearShifter( number, isPressed )
	if isPressed then 
		local goFwd = nil 
		local list  = self:getGearShifterIndeces()
		local num2  = 0
		
		if number == 7 then 
			if not self.vehicle.vcaShuttleCtrl then 
				return 
			end 
			
			self.vehicle.vcaShifter7isR1 = true 
			goFwd = false 
			
			if self.splitGears4Shifter then 
				num2 = 2
				for i,l in pairs(list) do  
					if i > 1 and l > self.vehicle.vcaLaunchGear then 
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
					num2 = number - 6 
				end 
			end 
		else			
			if self.vehicle.vcaShuttleCtrl and self.vehicle.vcaShifter7isR1 == nil then 
				self.vehicle.vcaShifter7isR1 = true 
			end 
			if self.vehicle.vcaShifter7isR1 then 
				goFwd = true 
			end 
			
			if self.splitGears4Shifter then 
				num2 =  number + number 
				if not self.vehicle.vcaShifterLH and num2 > 1 then 
					num2 = num2 - 1
				end 
			else 
				if self.vehicle.vcaShifterLH then 
					num2 = number + 6 
				else 
					num2 = number 
				end 
			end 
		end 
		
		local index = list[num2] 
		if index == nil then 
			print("Cannot find correct gear for shifter position "..tostring(number))
			return 
		end 
		
		local g, r = self:getBestGearRangeFromIndex( self.vehicle.vcaGear, self.vehicle.vcaRange, index )
		
		if not ( self.vehicle.vcaAutoClutch ) and self.vehicle.vcaClutchPercent < 1
				and ( ( g ~= self.vehicle.vcaGear  and self.changeTimeGears  > 100 )
					 or ( r ~= self.vehicle.vcaRange and self.changeTimeRanges > 100 ) ) then 
			self:grindingGears()
		else 
			self.vehicle:vcaSetState( "vcaShifterIndex", number )
			self.vehicle:vcaSetState( "vcaGear", g )
			self.vehicle:vcaSetState( "vcaRange", r )
			self.vehicle:vcaSetState( "vcaNeutral", false )
			if goFwd ~= nil then
				self.vehicle:vcaSetState( "vcaShuttleFwd", goFwd )
			end
		end 
	else 
		self.vehicle:vcaSetState( "vcaNeutral", true )
		if self.vehicle.spec_motorized.motor.vcaLoad ~= nil then  
			self.vehicle:vcaSetState("vcaBOVVolume",self.vehicle.spec_motorized.motor.vcaLoad)
		end 
	end 
end 

function vehicleControlAddonTransmissionBase:getGearShifterIndeces()
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

function vehicleControlAddonTransmissionBase:getGearRatio( index )
	return self.gearRatios[index]
end 

function vehicleControlAddonTransmissionBase:getNumberOfRatios()
	return table.getn( self.gearRatios )
end 

function vehicleControlAddonTransmissionBase:getAutoShiftIndeces( curIndex, minIndex, searchDown, searchUp )
	local gearList = {}
	
	if self.autoShiftGears and self.autoShiftRange then 
		for i=1,table.getn( self.gearRatios ) do 
			if ( i < curIndex and searchDown and i >= minIndex ) or ( searchUp and i > curIndex )  then 
				table.insert( gearList, i )
			end 
		end 
	else
		local tmpList = nil
		if     self.autoShiftGears then 
			tmpList = self:getRatioIndexListOfRange( self.vehicle.vcaRange )
		elseif self.autoShiftRange then 
			tmpList = self:getRatioIndexListOfGear( self.vehicle.vcaGear )
		end 
		if tmpList ~= nil then 
			for _,i in pairs(tmpList) do 
				if ( i < curIndex and searchDown and i >= minIndex ) or ( searchUp and i > curIndex )  then 
					table.insert( gearList, i )
				end 
			end 
		end 
	end 
	
	return gearList
end 

function vehicleControlAddonTransmissionBase:getRatioIndex( gear, range )
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
		if self.gearRatios[i] ~= nil then 
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
		if self.gearRatios[i] ~= nil then 
			table.insert( list, i )
			if self.vehicle ~= nil then 
				self.vehicle.vcaDebugR = self.vehicle.vcaDebugR .. string.format( "%d  ",i )
			end 
		end 
	end 
	return list
end 

function vehicleControlAddonTransmissionBase:actionCallback( actionName, keyStatus )
	vehicleControlAddon.debugPrint(tostring(self.name)..": "..actionName)
	if     actionName == "vcaGearUp"   then
		self:gearUp()
	elseif actionName == "vcaGearDown" then
		self:gearDown()
	elseif actionName == "vcaRangeUp"  then
		self:rangeUp()
	elseif actionName == "vcaRangeDown"then
		self:rangeDown()
	elseif actionName == "vcaShifter1" then
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
	elseif actionName == "vcaShifterLH" and self.vehicle.vcaShifterIndex > 0 then 
		self.vehicle:vcaSetState( "vcaShifterLH", not self.vehicle.vcaShifterLH )
		if not self.vehicle.vcaNeutral then 
			self:gearShifter( self.vehicle.vcaShifterIndex, keyStatus >= 0.5 )
		end 
	end 
end 

vehicleControlAddonTransmissionBase.transmissionList = 
	{ { class  = vehicleControlAddonTransmissionBase, 
			params = { "IVT", 1, 0, {}, 0 },
			text   = "IVT" }, 
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { "4x4", 4, 750, {2,1,1}, 1000 },
			text   = "4x4" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { "4PS", 4, 0, {2,1,1}, 750 },
			text   = "4x4 PowerShift" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { "2x6", 6, 750, {0}, 1000, nil, true, true, false },
			text   = "2x6" },
		{ class  = vehicleControlAddonTransmissionBase, 
			params = { "FPS", 12, 0, {}, 0 },
			text   = "FullPowerShift" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { "6PS", 2, 0, {0,0,0,0,0}, 750 },
			text   = "6 Gears with Splitter" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { "4PA", 4, 0, {2,1,1}, 750, nil, true, false },
			text   = "4x4 AutoQuad" },
		{ class  = vehicleControlAddonTransmissionBase,
			params = { "PKW", 6, 500, {3}, 1000, { 0.1, 0.15, 0.2, 0.2778, 0.3889, 0.5278, 0.7222, 1, 1.3889 }, true, false },
			text   = "Car with low range" }
	}
	
function vehicleControlAddonTransmissionBase.loadSettings()

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
					local key2 = key..string.format( ".gearTexts. gearText(%d)", j )
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
												params = { name, noGears, timeGears, rangeGearOverlap, timeRanges, gearRatios, autoGears, autoRanges, splitGears4Shifter, gearTexts, rangeTexts },
												text   = label } )
			end 		
		end 		
	end 

end 

vehicleControlAddonTransmissionBase.loadSettings()


