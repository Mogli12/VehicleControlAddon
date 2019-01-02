source(Utils.getFilename("keyboardSteerMogli.lua", g_currentModDirectory))
source(Utils.getFilename("keyboardSteerMogliScreen.lua", g_currentModDirectory))

keyboardSteerMogli_Register = {};
keyboardSteerMogli_Register.g_currentModDirectory = g_currentModDirectory
keyboardSteerMogli_Register.specName = "zzzKeyboardSteerMogli"
if g_specializationManager:getSpecializationByName("keyboardSteerMogli") == nil then
--g_specializationManager:addSpecialization("keyboardSteerMogli", "keyboardSteerMogli", g_currentModDirectory.."keyboardSteerMogli.lua")
	if keyboardSteerMogli == nil then 
		print("Failed to add specialization keyboardSteerMogli")
	else 
		for k, typeDef in pairs(g_vehicleTypeManager.vehicleTypes) do
			if typeDef ~= nil and k ~= "locomotive" then 
				local isDrivable  = false
				local isEnterable = false
				local hasMotor    = false 
				for name, spec in pairs(typeDef.specializationsByName) do
					if     name == "drivable"  then 
						isDrivable = true 
					elseif name == "motorized" then 
						hasMotor = true 
					elseif name == "enterable" then 
						isEnterable = true 
					end 
				end 
				if isDrivable and isEnterable and hasMotor then 
				--print("  adding keyboardSteerMogli to vehicleType '"..tostring(k).."'")
					typeDef.specializationsByName[keyboardSteerMogli_Register.specName] = keyboardSteerMogli
					table.insert(typeDef.specializationNames, keyboardSteerMogli_Register.specName)
					table.insert(typeDef.specializations, keyboardSteerMogli)	
				end 
			end 
		end 	
	end 
end 

function keyboardSteerMogli_Register:loadMap(name)
	print("--- loading "..g_i18n:getText("ksmVERSION").." by mogli ---")
	g_i18n.texts["ksmVERSION"] = g_i18n:getText("ksmVERSION")

	keyboardSteerMogli_Register.mogliTexts = {}
	for n,t in pairs( g_i18n.texts ) do
		keyboardSteerMogli_Register.mogliTexts[n] = t
	end
	
	local l10nFilenamePrefixFull = Utils.getFilename("modDesc_l10n", keyboardSteerMogli_Register.g_currentModDirectory);
	local l10nXmlFile;
	local l10nFilename
	local langs = {g_languageShort, "en", "de"};
	for _, lang in ipairs(langs) do
		l10nFilename = l10nFilenamePrefixFull.."_"..lang..".xml";
		if fileExists(l10nFilename) then
			l10nXmlFile = loadXMLFile("TempConfig", l10nFilename);
			break;
		end
	end
	if l10nXmlFile ~= nil then
		local textI = 0;
		while true do
			local key = string.format("l10n.longTexts.longText(%d)", textI);
			if not hasXMLProperty(l10nXmlFile, key) then
				break;
			end;
			local name = getXMLString(l10nXmlFile, key.."#name");
			local text = getXMLString(l10nXmlFile, key);
			if name ~= nil and text ~= nil then
				keyboardSteerMogli_Register.mogliTexts[name] = text:gsub("\r\n", "\n")
			end;
			textI = textI+1;
		end;
		delete(l10nXmlFile);
	end
	
end;

function keyboardSteerMogli_Register:deleteMap()
  
end;

function keyboardSteerMogli_Register:keyEvent(unicode, sym, modifier, isDown)

end;

function keyboardSteerMogli_Register:mouseEvent(posX, posY, isDown, isUp, button)

end;

function keyboardSteerMogli_Register:update(dt)
	
end;

function keyboardSteerMogli_Register:draw()
  
end;

addModEventListener(keyboardSteerMogli_Register);

--local oldVehicleLoad = Vehicle.load 
--Vehicle.load = function( ... )
--	for n,v in pairs({...}) do	
--		print(tostring(n)..": "..tostring(v).." ("..type(v)..")")
--	end 
--	
--	local oldGetXmlString = XMLUtil.getXMLStringWithDefault
--	XMLUtil.getXMLStringWithDefault = function( ... )
--		print( "getXMLString" )
--		return oldGetXmlString( ... )
--	end 
--	
--	local s,r = pcall( oldVehicleLoad, ... )
--	
--	XMLUtil.getXMLStringWithDefault = oldGetXmlString
--	
--	if s then 
--		return r 
--	else
--		print("Error: "..tostring(r))
--	end 
--end 

