
VehicleControlAddonMenu = {}

local VehicleControlAddonMenu_mt = Class(VehicleControlAddonMenu, TabbedMenu)

--- Page tab UV coordinates for display elements.
VehicleControlAddonMenu.TAB_UV = {
	SETTINGS    = { 0, 209, 65, 65 },
	GENERAL     = {844, 144, 65, 65},
	ENVIRONMENT = {65, 144, 65, 65},
	PLAYER      = {454, 209, 65, 65},
	FIELD       = {432, 96, 48, 48},
	VEHICLES    = {130, 144, 65, 65}
}

VehicleControlAddonMenu.CONTROLS = {
	BACKGROUND    = "inGameBackgroundElement",
	FRAME1 = "vcaFrame1",
	FRAME2 = "vcaFrame2",
	FRAME3 = "vcaFrame3",
	FRAME4 = "vcaFrame4"
}

VehicleControlAddonMenu.FRAMES = {
	{ name = "vcaFrame1", iconUVs = VehicleControlAddonMenu.TAB_UV.SETTINGS },
	{ name = "vcaFrame2", iconUVs = VehicleControlAddonMenu.TAB_UV.VEHICLES },
	{ name = "vcaFrame3", iconUVs = VehicleControlAddonMenu.TAB_UV.GENERAL },
	{ name = "vcaFrame4", iconUVs = VehicleControlAddonMenu.TAB_UV.PLAYER }
}

function VehicleControlAddonMenu:new(messageCenter, i18n, inputManager)
	local self = TabbedMenu:new(nil, VehicleControlAddonMenu_mt, messageCenter, i18n, inputManager)
	self:registerControls(VehicleControlAddonMenu.CONTROLS)
	return self
end

function VehicleControlAddonMenu:onGuiSetupFinished()
	VehicleControlAddonMenu:superClass().onGuiSetupFinished(self)

	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack) -- store to be able to apply it always when assigning menu button info

--if g_screenWidth >= 2560 and g_screenHeight >= 1080 then
--	self.dialogBackground:applyProfile("vcaDialogBgWide")
--	self.header:applyProfile("vcaMenuHeaderWide")
--	self.pageSelector:applyProfile("vcaHeaderSelectorWide")
--	self.pagingTabList:applyProfile("vcaPagingTabListWide")
--end

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

function VehicleControlAddonMenu:onOpen()
	VehicleControlAddonMenu:superClass().onOpen(self)

	self.inputDisableTime = 200
end

--- Define default properties and retrieval collections for menu buttons.
function VehicleControlAddonMenu:setupMenuButtonInfo()
	self.defaultMenuButtonInfo = {{ inputAction = InputAction.MENU_BACK, text = "BACK", callback = self.clickBackCallback }}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultButtonActionCallbacks = { [InputAction.MENU_BACK] = self.clickBackCallback }
end


