
VehicleControlAddonMenu = {}

local VehicleControlAddonMenu_mt = Class(VehicleControlAddonMenu, TabbedMenu)

--- Page tab UV coordinates for display elements.
VehicleControlAddonMenu.TAB_UV = {
	SETTINGS    = { 0, 209, 65, 65 },
	GENERAL     = {844, 144, 65, 65},
	ENVIRONMENT = {65, 144, 65, 65},
	PLAYER      = {454, 209, 65, 65},
	FIELD       = {432, 96, 48, 48},
	VEHICLES    = {130, 144, 65, 65},
}

VehicleControlAddonMenu.CONTROLS = {
	BACKGROUND    = "inGameBackgroundElement",
	FRAME1 = "vcaFrame1",
	FRAME2 = "vcaFrame2",
	FRAME3 = "vcaFrame3",
	FRAME4 = "vcaFrame4",
}

VehicleControlAddonMenu.FRAMES = {
	{ name = "vcaFrame1", iconUVs = VehicleControlAddonMenu.TAB_UV.SETTINGS },
	{ name = "vcaFrame2", iconUVs = VehicleControlAddonMenu.TAB_UV.VEHICLES },
	{ name = "vcaFrame3", iconUVs = VehicleControlAddonMenu.TAB_UV.GENERAL },
	{ name = "vcaFrame4", iconUVs = VehicleControlAddonMenu.TAB_UV.PLAYER },
}

VehicleControlAddonMenu.L10N_SYMBOL = {
    BUTTON_BACK = "button_back",
}

function VehicleControlAddonMenu:new(messageCenter, i18n, inputManager)
	local self = TabbedMenu:new(nil, VehicleControlAddonMenu_mt, messageCenter, i18n, inputManager)
	self:registerControls(VehicleControlAddonMenu.CONTROLS)
	return self
end

function VehicleControlAddonMenu:onGuiSetupFinished()
	VehicleControlAddonMenu:superClass().onGuiSetupFinished(self)

	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

	local alwaysVisiblePredicate = function() return true end

	for i,f in pairs(VehicleControlAddonMenu.FRAMES) do 
		if f.name ~= nil and type( self[f.name] ) == "table" and type( self[f.name].initialize ) == "function" then 
			local frame = self[f.name]
			frame:initialize()
			self:registerPage( frame, i, Utils.getNoNil( f.predicate, alwaysVisiblePredicate ) )
			self:addPageTab( frame, Utils.getNoNil( f.uiFilename, g_baseUIFilename), getNormalizedUVs( f.iconUVs ) )
		else 
			print("ERROR: "..tostring(f.name).."; "..type( self[f.name] ) == "table")
		end 
	end 
end

function VehicleControlAddonMenu:onMenuOpened()
	VehicleControlAddonMenu:superClass().onMenuOpened(self)

	self.vcaInputEnabled = true  
end


function VehicleControlAddonMenu:onClose()
	VehicleControlAddonMenu:superClass().onClose(self)

	self.vcaInputEnabled = false 
end

function VehicleControlAddonMenu:setupMenuButtonInfo()
	VehicleControlAddonMenu:superClass().setupMenuButtonInfo(self)

	self.defaultMenuButtonInfo = {{ inputAction = InputAction.MENU_BACK,
																	text        = self.l10n:getText(VehicleControlAddonMenu.L10N_SYMBOL.BUTTON_BACK),
																	callback    = self.clickBackCallback },
															 }

	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]

	self.defaultButtonActionCallbacks = { [InputAction.MENU_BACK] = self.clickBackCallback }
end




