--
-- mogliBasics
-- This is the specialization for mogliBasics
--
-- change log
-- 1.00 initial version
-- 1.07 FS19, title

-- Usage:  source(Utils.getFilename("mogliScreen.lua", g_currentModDirectory));
--         _G[g_currentModDirectory.."mogliScreen"].newClass( "AutoCombine", "acParameters" )

local mogliScreenVersion   = 1.08
local mogliScreenClass     = g_currentModName..".mogliScreen"

if _G[mogliScreenClass] ~= nil and _G[mogliScreenClass].version ~= nil and _G[mogliScreenClass].version >= mogliScreenVersion then
	print("Factory class "..tostring(mogliScreenClass).." already exists in version "..tostring(_G[mogliScreenClass].version))
else
	local mogliScreen10 = {}

	mogliScreen10.version = mogliScreenVersion
		
--=======================================================================================
-- mogliScreen10.newclass
--=======================================================================================
	function mogliScreen10.newClass( _globalClassName_, _refClassName_, _methodPrefix_, _uiPrefix_ )
		if _uiPrefix_     == nil then	_uiPrefix_     = "" end
		if _methodPrefix_ == nil then	_methodPrefix_ = "" end
	
		local _newClass_ = {}
		
		--print("Creating new global class in "..g_currentModDirectory.." with name ".._globalClassName_..". Prefix is: "..tostring(_level0_))

		_newClass_.baseDirectory = g_currentModDirectory
		_newClass_.modsDirectory = g_modsDirectory.."/"
		_newClass_.buttonBackFocusId = "101"
		_newClass_.buttonLeftFocusId = "1"
		
		local mogliScreen_mt = Class(_newClass_, ScreenElement)

	--********************************
	-- new
	--********************************
		function _newClass_:new(target, custom_mt)
			if custom_mt == nil then
				custom_mt = mogliScreen_mt
			end	
			local self = ScreenElement:new(target, custom_mt)
			self.returnScreenName = "";
			self.vehicle = nil
			self.mogliScreenElements = {}
			self.mogliTexts = {}
			if type(_newClass_.mogliScreenNew)=="function" then
				_newClass_.mogliScreenNew(self) 
			end			
			return self
		end
		
	--********************************
	-- onCreate
	--********************************
		function _newClass_:onCreate(element, parameter)
			if self.pageStateElement ~= nil then
				self.pageStateElement:unlinkElement()
			end
			self.buttonBack = FocusManager:getElementById(_newClass_.buttonBackFocusId);
			self.buttonLeft = FocusManager:getElementById(_newClass_.buttonLeftFocusId);
			if self.pagingElement ~= nil then
				self.pagingElement:setPage(1, true);
			end
			if type(_newClass_.mogliScreenOnCreate)=="function" then
				_newClass_.mogliScreenOnCreate(self,element) 
			end
		end

	--********************************
	-- setTitle
	--********************************
		function _newClass_:setTitle( title )
			replaceTexts( self, self, title )
		end 
		
	--********************************
	-- setVehicle
	--********************************
		function _newClass_:setVehicle( vehicle )
			self.vehicle       = vehicle 
			
			if self.vehicle ~= nil then
				for name,s in pairs( self.mogliScreenElements ) do
					if s.parameter == "list" or s.parameter == "list0" then
						if type( self.vehicle[_uiPrefix_][name] ) == "table" then
							s.element:setTexts(self.vehicle[_uiPrefix_][name])
						else
							s.element:setTexts({"<empty>"})
						end
					end
				end
			end
			if type( _newClass_.mogliScreenSetVehicle ) == "function" then
				_newClass_.mogliScreenSetVehicle( self, vehicle )
			end
		end

	--********************************
	-- update
	--********************************
		function _newClass_:update(dt)
			_newClass_:superClass().update(self, dt)
			
			if not ( self.isOpen ) then
			-- closed by MENU_CANCEL key (ESC)
				return 
			end
			
			if type( _newClass_.mogliScreenPreUpdate ) == "function" then
				_newClass_.mogliScreenPreUpdate( self, dt )
			end
			
			if self.pageSelector ~= nil then
				self.pageSelector:setCanChangeState(true)
			end
		
			if self.vehicle ~= nil then
				for name,s in pairs( self.mogliScreenElements ) do
					if s.parameter == "callback" then
						local getter = _G[_refClassName_][_uiPrefix_.."Draw"..name]
						local texts  = getter( self.vehicle )
						s.element:setTexts(texts)
					end
				end
			end
			if type( _newClass_.mogliScreenPostUpdate ) == "function" then
				_newClass_.mogliScreenPostUpdate( self, dt )
			end
			
			InputBinding:setShowMouseCursor(true)			
		end

	--********************************
	-- onOpen
	--********************************
		function _newClass_:onOpen()
			_newClass_:superClass().onOpen(self)
			
			if self.vehicle == nil then
				print("Error: vehicle is empty")
			else
				for name,s in pairs( self.mogliScreenElements ) do
					local element = s.element
					
					local getter = nil					
					local debugPrint = false
					
					if     type( _G[_refClassName_][_uiPrefix_.."Get"..name] ) == "function" then
						if debugPrint then print( _uiPrefix_.."Get"..name ) end
						getter = _G[_refClassName_][_uiPrefix_.."Get"..name]
					elseif type( _G[_refClassName_][_methodPrefix_.."Get"..name] ) == "function" then
						if debugPrint then print( _methodPrefix_.."Get"..name ) end
						getter = _G[_refClassName_][_methodPrefix_.."Get"..name]
					elseif type( _G[_refClassName_].mbGetState ) == "function" then
						if debugPrint then print( 'mbGetState(vehicle, "'..name..'")' ) end
						getter = function( vehicle ) return _G[_refClassName_].mbGetState( vehicle, name ) end
					elseif self.vehicle[name] ~= nil then
						if debugPrint then print( 'self.'..name ) end
						getter = function( vehicle ) return vehicle[name] end
					end		
					
					if     getter == nil then
						print("Invalid UI element ID: "..tostring(name))
					else
						local value = getter( self.vehicle )
						
						if     element.typeName == "checkedOption" then
							local b = value
							if s.parameter then
								b = not b
							end
							element:setIsChecked( b )
						elseif element.typeName == "multiTextOption" then
							local i = 1
							if     s.parameter == "percent10" then
								i = math.floor( value * 10 + 0.5 ) + 1
							elseif s.parameter == "percent5" then
								i = math.floor( value * 20 + 0.5 ) + 1
							elseif s.parameter == "list0" then
								i = value + 1
							elseif s.parameter == "bool" then 
								if value then i = 2 end
							else
								i = value 
							end
							element:setState( i )
						end
					end
				end
			end
				
			if type(_newClass_.mogliScreenOnOpen)=="function" then
				_newClass_.mogliScreenOnOpen(self) 
			end
			
			if self.pageStateBox ~= nil then
				self:setPageStates()
				self:updatePageState()
			end							
		end

	--********************************
	-- onClickOk
	--********************************
		function _newClass_:onClickOk(...)
			if self.vehicle == nil then
				print("Error: vehicle is empty")
			else
				for name,s in pairs( self.mogliScreenElements ) do
					local element = s.element
					
					local setter = nil
					if     type( _G[_refClassName_][_uiPrefix_.."Set"..name] ) == "function" then
						setter = _G[_refClassName_][_uiPrefix_.."Set"..name]
					elseif type( _G[_refClassName_][_methodPrefix_.."Set"..name] ) == "function" then
						setter = _G[_refClassName_][_methodPrefix_.."Set"..name]
					elseif type( _G[_refClassName_].mbSetState ) == "function" then
						setter = function( vehicle, value ) _G[_refClassName_].mbSetState( vehicle, name, value ) end
					elseif self.vehicle[name] ~= nil then
						setter = function( vehicle, value ) vehicle[name] = value end
					end
					
					if     setter == nil then
						print("Invalid UI element ID: "..tostring(name))
					elseif element.typeName == "checkedOption" then
						local b = element:getIsChecked()
						if s.parameter then
							b = not b
						end
					--print("SET: "..tostring(name)..": '"..tostring(b).."'")
						setter( self.vehicle, b )
					elseif element.typeName == "multiTextOption" then
						local i = element:getState()
						local value = i
						if     s.parameter == "percent10" then
							value = (i-1) * 0.1
						elseif s.parameter == "percent5" then
							value = (i-1) * 0.05
						elseif s.parameter == "list0" then
							value = i - 1
						elseif s.parameter == "bool" then 
							value = ( i > 1 )
						end
					--print("SET: "..tostring(name)..": '"..tostring(value).."'")
						
						setter( self.vehicle, value )
					end
				end
			end
			
			self:onClickBack()
		end

	--********************************
	-- onClose
	--********************************
		function _newClass_:onClose(...)
			if type( _newClass_.mogliScreenOnClose ) == "function" then
				_newClass_.mogliScreenOnClose( self )
			end
			self.vehicle = nil
			_newClass_:superClass().onClose(self, ...);
		end

	--********************************
	-- replaceTexts (local)
	--********************************
		function replaceTexts( screen, element, title )
			if element.mogliTextReplaced then 
				return 
			end 
			element.mogliTextReplaced = true 
			if element.toolTipText ~= nil and element.toolTipText:sub(1,7) == "$mogli_" then 
				local n = element.toolTipText:sub(8)
				element.toolTipText = Utils.getNoNil( screen.mogliTexts[n], n )			
			end 
			if element.text ~= nil and element.text:sub(1,7) == "$mogli_" then 
				local n = element.text:sub(8)
				if type( element.setText ) == "function" then 
					element:setText( Utils.getNoNil( screen.mogliTexts[n], n ) )
				else 
					element.text = Utils.getNoNil( screen.mogliTexts[n], n )
				end 
			elseif title ~= nil and element.id ~= nil and element.id == "mogliHeaderText" then 
				if type( element.setText ) == "function" then 
					element:setText( screen.mogliTexts[title] )
				else 
					element.text = screen.mogliTexts[title]
				end 
			end 
			if type( element.elements ) == "table" then 
				for _,e in pairs(element.elements) do 
					replaceTexts( screen, e, title ) 
				end 
			end 
		end 
	
	--********************************
	-- onCreateSubElement
	--********************************
		function _newClass_:onCreateSubElement( element, parameter )
			if element == nil or element.typeName == nil then 
				print("Invalid element.typeName: <nil>")
				return
			end 
			local checked = true
			if element.id == nil then
				checked = false
			end
			if     element.typeName == "multiTextOption" then
				if     parameter == nil 
						or parameter == "bool" then
					parameter = "bool"
				--if table.getn(element.texts) ~= 2 then 
				--	element:setTexts({g_i18n:getText("ui_off"), g_i18n:getText("ui_on")})
				--end 
				elseif parameter == "list"
						or parameter == "list0" then
					element:setTexts({"vehicle is <nil>"})
				elseif parameter == "percent10" then
					local texts = {}
					for i=0,10 do
						table.insert( texts, string.format("%d%%",i*10) )
					end
					element:setTexts(texts)
				elseif parameter == "percent5" then
					local texts = {}
					for i=0,20 do
						table.insert( texts, string.format("%d%%",i*5) )
					end
					element:setTexts(texts)
				elseif parameter == "callback" then
					if type( _G[_refClassName_][_uiPrefix_.."Draw"..element.id] ) == "function" then
						local getter = _G[_refClassName_][_uiPrefix_.."Draw"..element.id]
						local state, message = pcall( getter, self.vehicle )
						if state then
							element:setTexts(message)
						else
							print("Invalid MultiTextOptionElement callback: ".._uiPrefix_.."Draw"..tostring(element.id)..", '"..tostring(message).."'")
						end
					else
						print("Invalid MultiTextOptionElement callback: ".._uiPrefix_.."Draw"..tostring(element.id))
						checked = false
					end
				else
					print("Invalid MultiTextOptionElement parameter: "..tostring(parameter))
					checked = false
				end
			end
			if checked then
				self.mogliScreenElements[element.id] = { element=element, parameter=parameter }
			else	
				print("Error inserting UI element with ID: "..tostring(element.id))
			end			
		end
		
	--********************************
	-- onCreatePaging(element)
	--********************************
		function _newClass_:onCreatePaging(element)
			local texts = {}
			for _, page in pairs(element.pages) do
				table.insert(texts, self:mogliScreenGetPageTitle(page))
			end
			self.pageSelector:setTexts(texts)
			self.pageSelector:setState(1)
		end

	--********************************
	-- onClickPageSelection(state)
	--********************************
		function _newClass_:onClickPageSelection(state)
			self.pagingElement:setPage(state)
		end

	--********************************
	-- onCreatePageState(element)
	--********************************
		function _newClass_:onCreatePageState(element)
			if self.pageStateElement == nil then
				self.pageStateElement = element
			end
		end

	--********************************
	-- updatePageState()
	--********************************
		function _newClass_:updatePageState()
			for index, state in pairs(self.pageStateBox.elements) do
				state.state = GuiOverlay.STATE_NORMAL
				if index == self.pageSelector:getState() then
					state.state = GuiOverlay.STATE_FOCUSED
				end
			end
		end

	--********************************
	-- onPageChange(pageId, pageMappingIndex)
	--********************************
		function _newClass_:onPageChange(pageId, pageMappingIndex)
			self:updatePageState()

			local bottomTarget = nil;
			local topTarget    = nil;
			
			if type( _newClass_.mogliScreenGetPageFocus ) == "function" and self.pages ~= nil then
				for _,page in pairs(self.pages) do
					if page.id == pageId then
						topTarget, bottomTarget = _newClass_.mogliScreenGetPageFocus( self, element )
					end
				end
			end
			
			self.buttonBack.focusChangeData[FocusManager.TOP] = bottomTarget
			self.buttonLeft.focusChangeData[FocusManager.BOTTOM] = topTarget
		end

	--********************************
	-- setPageStates()
	--********************************
		function _newClass_:setPageStates()
			for i=#self.pageStateBox.elements, 1, -1 do
				self.pageStateBox.elements[i]:delete();
			end

			local texts = {}
			self.statePageMapping = {}
			for _, page in pairs(self.pagingElement.pages) do
				page.disabled = false
				if      type( _newClass_.mogliScreenIsPageDisabled ) == "function"
						and _newClass_.mogliScreenIsPageDisabled( self, page.element ) then
					page.disabled = true
				end
				if not page.disabled then
					table.insert(texts, self:mogliScreenGetPageTitle(page))
					self.pageStateElement:clone(self.pageStateBox)
					table.insert(self.statePageMapping, page)
				end
			end

			self.pageSelector:setTexts(texts)
		end

	--********************************
	-- onLeaveSettingsBox()
	--********************************
		function _newClass_:mogliLeaveToolTip(element)
			if self.mogliToolTipBox ~= nil then
				self.mogliToolTipBoxText:setText("")
				self.mogliToolTipBox:setVisible(false)
			end
		end

	--********************************
	-- onFocusSettingsBox()
	--********************************
		function _newClass_:mogliFocusToolTip(element)
			if self.mogliToolTipBox ~= nil and element.toolTipText ~= nil then
				self.mogliToolTipBoxText:setText(element.toolTipText)
				self.mogliToolTipBox:setVisible(true)
			end
		end		

		--********************************
	-- mogliScreenGetPageTitle()
	--********************************
		function _newClass_:mogliScreenGetPageTitle(page)
			if page.element.toolTipText ~= nil then
				return page.element.toolTipText
			end
			return page.element.name
		end

	--********************************
		_G[_globalClassName_] = _newClass_ 
	--********************************
	end

	--********************************
	_G[mogliScreenClass] = mogliScreen10
	--********************************
		
end
