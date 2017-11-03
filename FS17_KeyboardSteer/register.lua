SpecializationUtil.registerSpecialization("keyboardSteerMogli", "keyboardSteerMogli", g_currentModDirectory.."keyboardSteerMogli.lua")

source(Utils.getFilename("keyboardSteerMogliScreen.lua", g_currentModDirectory))

keyboardSteerMogli_Register = {};
keyboardSteerMogli_Register.g_currentModDirectory = g_currentModDirectory

function keyboardSteerMogli_Register:loadMap(name)
	if self.firstRun == nil then
		self.firstRun = false;
		print("--- loading "..g_i18n:getText("ksmVERSION").." by mogli ---")
		
		for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
			if v ~= nil then
				local allowInsertion = true;
				for i = 1, table.maxn(v.specializations) do
					local vs = v.specializations[i];
					if vs ~= nil and vs == SpecializationUtil.getSpecialization("drivable") then
						local v_name_string = v.name 
						local point_location = string.find(v_name_string, ".", nil, true)
						if point_location ~= nil then
							local _name = string.sub(v_name_string, 1, point_location-1);
							if rawget(SpecializationUtil.specializations, string.format("%s.keyboardSteerMogli", _name)) ~= nil then
								allowInsertion = false;								
							end;							
						end;
						if allowInsertion then	
							table.insert(v.specializations, SpecializationUtil.getSpecialization("keyboardSteerMogli"));
						end;						
					end;
				end;
			end;	
		end;
	end
	
	-- make l10n global 
	local prefix = g_i18n.texts.ksmInputPrefix
	local prelen = 0
	if prefix ~= nil and prefix ~= "" then
		prelen = string.len( prefix )
	end
	for m,t in pairs( g_i18n.texts ) do
		local n = nil
		if     string.sub( m, 1, 9 ) == "input_ksm" then
			n = string.sub( m, 7 )
			if prelen > 0 and string.sub( t, 1, prelen ) == prefix then
				t = string.sub( t, prelen+1, -1 )
			end
		elseif string.sub( m, 1, 3 ) == "ksm"       then
			n = m
		end
		if n ~= nil and g_i18n.globalI18N.texts[n] == nil then
			g_i18n.globalI18N.texts[n] = t
		end
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
				g_i18n.globalI18N.texts[name] = text:gsub("\r\n", "\n")
			end;
			textI = textI+1;
		end;
		delete(l10nXmlFile);
	end
	
	
	g_keyboardSteerMogliScreen = keyboardSteerMogliScreen:new()
	g_gui:loadGui(keyboardSteerMogli_Register.g_currentModDirectory .. "keyboardSteerMogliScreen.xml", "keyboardSteerMogliScreen", g_keyboardSteerMogliScreen)	
	FocusManager:setGui("MPLoadingScreen")
	
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