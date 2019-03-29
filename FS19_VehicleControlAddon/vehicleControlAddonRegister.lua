vehicleControlAddon_Register = {};
vehicleControlAddon_Register.g_currentModDirectory = g_currentModDirectory
vehicleControlAddon_Register.specName = "zzzVehicleControlAddon"

if g_specializationManager:getSpecializationByName(vehicleControlAddon_Register.specName) == nil then 
	if vehicleControlAddon == nil then 
		print("Failed to add specialization vehicleControlAddon")
	else 
		for k, typeDef in pairs(g_vehicleTypeManager.vehicleTypes) do
			if typeDef ~= nil and k ~= "locomotive" then 
				local isDrivable   = false
				local isEnterable  = false
				local hasMotor     = false 
				local hasLights    = false 
				local hasWheels    = false 
				local isAttachable = false 
				for name, spec in pairs(typeDef.specializationsByName) do
					if     name == "drivable"   then 
						isDrivable = true 
					elseif name == "motorized"  then 
						hasMotor = true 
					elseif name == "enterable"  then 
						isEnterable = true 
					elseif name == "lights"     then 
						hasLights = true 
					elseif name == "wheels"     then 
						hasWheels = true 
					elseif name == "attachable" then 
						isAttachable = true 
					end 
				end 
				if isDrivable and isEnterable and hasMotor and hasLights and hasWheels and not isAttachable then 
					print("  adding vehicleControlAddon to vehicleType '"..tostring(k).."'")
					typeDef.specializationsByName[vehicleControlAddon_Register.specName] = vehicleControlAddon
					table.insert(typeDef.specializationNames, vehicleControlAddon_Register.specName)
					table.insert(typeDef.specializations, vehicleControlAddon)	
				end 
			end 
		end 	
	end 
end 

function vehicleControlAddon_Register:loadMap(name)
	print("--- loading "..g_i18n:getText("vcaVERSION").." by mogli ---")

	g_i18n.texts["vcaVERSION"] = g_i18n:getText("vcaVERSION")

	vehicleControlAddon_Register.mogliTexts = {}
	for n,t in pairs( g_i18n.texts ) do
		vehicleControlAddon_Register.mogliTexts[n] = t
	end
	
	local l10nFilenamePrefixFull = Utils.getFilename("modDesc_l10n", vehicleControlAddon_Register.g_currentModDirectory);
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
				vehicleControlAddon_Register.mogliTexts[name] = text:gsub("\r\n", "\n")
			end;
			textI = textI+1;
		end;
		delete(l10nXmlFile);
	end
	
end;

function vehicleControlAddon_Register:deleteMap()
  
end;

function vehicleControlAddon_Register:keyEvent(unicode, sym, modifier, isDown)

end;

function vehicleControlAddon_Register:mouseEvent(posX, posY, isDown, isUp, button)

end;

function vehicleControlAddon_Register:update(dt)
	
end;

function vehicleControlAddon_Register:draw()
  
end;

addModEventListener(vehicleControlAddon_Register);


