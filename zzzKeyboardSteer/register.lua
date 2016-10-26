SpecializationUtil.registerSpecialization("keyboardSteerMogli", "keyboardSteerMogli", g_currentModDirectory.."keyboardSteerMogli.lua")

keyboardSteerMogli_Register = {};

function keyboardSteerMogli_Register:loadMap(name)
	if self.firstRun == nil then
		self.firstRun = false;
		print("--- loading "..g_i18n:getText("ksmVERSION").." by mogli ---")
		
		for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
			if v ~= nil then
				local allowInsertion = true;
				for i = 1, table.maxn(v.specializations) do
					local vs = v.specializations[i];
					if vs ~= nil and vs == SpecializationUtil.getSpecialization("steerable") then
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
		g_i18n.globalI18N.texts["ksmENABLE_ON"]   = g_i18n:getText("ksmENABLE_ON");		
		g_i18n.globalI18N.texts["ksmENABLE_OFF"]  = g_i18n:getText("ksmENABLE_OFF");		
		g_i18n.globalI18N.texts["ksmCAMERA_ON"]   = g_i18n:getText("ksmCAMERA_ON");		
		g_i18n.globalI18N.texts["ksmCAMERA_OFF"]  = g_i18n:getText("ksmCAMERA_OFF");		
		g_i18n.globalI18N.texts["ksmREVERSE_ON"]  = g_i18n:getText("ksmREVERSE_ON");		
		g_i18n.globalI18N.texts["ksmREVERSE_OFF"] = g_i18n:getText("ksmREVERSE_OFF");		
		g_i18n.globalI18N.texts["ksmANALOG_ON"]   = g_i18n:getText("ksmANALOG_ON");		
		g_i18n.globalI18N.texts["ksmANALOG_OFF"]  = g_i18n:getText("ksmANALOG_OFF");		
		g_i18n.globalI18N.texts["input_ksmPLUS"]  = g_i18n:getText("input_ksmPLUS");		
		g_i18n.globalI18N.texts["input_ksmMINUS"] = g_i18n:getText("input_ksmMINUS");		
	end;
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