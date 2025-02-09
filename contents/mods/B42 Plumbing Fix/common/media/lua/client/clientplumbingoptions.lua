-- Author: Lightja 2/2/2025
-- This mod may be copied/edited/reuploaded by anyone for any reason with no preconditions.

plumbing_options = ModData.getOrCreate("LightjaPlumbing")

require "PZAPI/ui/organisms/Window"
require "PZAPI/ui/atoms/Text"
require "PZAPI/ui/molecules/ScrollBarVertical"
local UI = PZAPI.UI

local ltooltip = UI.Text{
	font = UIFont.Large,
	r=1,g=1,b=1,a=1,
	x_offset = 20,
	y_offset = -50,
	text = "test ltooltip",
	init = function(self)
		self:setVisible(false)
		self:setEnabled(false)
	end
}

local function pzapi_option_checkbox(option_name, tooltip_text, yy, size, new_font)
	if not yy   then yy = 0 end
	if not size then size = 32 end
	local   selected_texture = "media/lua/client/ui_images/checkbox_1_32.png"
	local unselected_texture = "media/lua/client/ui_images/checkbox_0_32.png"
	local selected      = {r=1,g=1,b=1,a=1}
	local not_selected  = {r=1,g=1,b=1,a=1}
	local PADDING = 5
	return UI.Node{
		width = size, height = size,
		x=PADDING,y=yy + PADDING,
		children = {
			selection = UI.Texture{
				anchorLeft = 0, anchorRight = 0, anchorDown = 0, anchorTop = 0,
				height = size, width = size,
				is_selected = false,
				option = option_name,
				init = function(self)
					self.is_selected = plumbing_options[self.option]
					if self.is_selected then self:setTexture(getTexture(selected_texture));
					else self:setTexture(getTexture(unselected_texture));
					end
				end,
				onLeftClick = function(self)
					getSoundManager():playUISound("UIActivateButton")
					-- print(string.format("[Lightja] Left clicked '%s' option button. BtnWidth: %s, BtnHeight: %s, pre-click value: %s, new value: %s",tostring(self.option), tostring(self.width),tostring(self.height),tostring(self.is_selected),tostring(not self.is_selected)))
					self.is_selected = not self.is_selected
					plumbing_options[self.option] = self.is_selected
					if self.is_selected then self:setTexture(getTexture(selected_texture));
					else self:setTexture(getTexture(unselected_texture));
					end
				end,
				onHover = function(self,hovered)
					if hovered then 
						self.parent.tooltip:setVisible(true)
						self.parent.tooltip:setEnabled(true)
						self.parent.tooltip.children.label:setText(self.parent.tooltip_text)
						self.parent.tooltip:setWidth(getTextManager():MeasureStringX(self.parent.tooltip.font, self.parent.tooltip_text) + 2*PADDING)
					else
						self.parent.tooltip:setVisible(false)
						self.parent.tooltip:setEnabled(false)
					end
				end,
				onMouseMove = function(self)
					local mx,my = getMouseX(),getMouseY()
					local dx,dy = mx - self.parent.parent_window.x, my - self.parent.parent_window.y
					-- print(string.format("[Lightja] mouse MOVE detected on plumbing option checkbox at (%s, %s). dx,dy: (%s, %s), window (%s, %s)",tostring(mx),tostring(my),tostring(dx),tostring(dy),tostring(self.parent.parent_window.x),tostring(self.parent.parent_window.x)))
					self.parent.tooltip:setX(dx + 10)
					self.parent.tooltip:setY(dy - 30)
				end
			},
			button_label = UI.Text{
				anchorLeft = size + 2*PADDING,anchorRight = 0, anchorTop = 0, anchorDown = 0,
				r=1,g=1,b=1,a=1,
				pivotY = 0.5,
				font = new_font,
				text = option_name
			},
			tooltip = UI.Node{
				visible = false,
				enabled = false,
				r,g,b,a = 0.1,0.1,0.1,0.9,
				children = {
					label = UI.Text{
						font = UIFont.Large,
						text = tooltip_text,
						r,g,b,a = 1,1,1,1,
					},
					background = UI.Texture{
						r,g,b,a = 0.1,0.1,0.1,1,
					}
				},
				init = function(self)
					self:setAlwaysOnTop(true)
				end
			}
		},
		init = function(self)
			self.tooltip_text = tooltip_text
		end
	}
end

-- UI_mods_ModEnable = "Enable",
 -- Fluid_Options = "Liquid Options",
--GameSound_ButtonAdvanced = "Advanced",


--IGUI_AttachmentEditor_New = "New"
--Challenge_Challenge2_TabItems = "Items"
--Challenge_Challenge2_Skills = "Skills"
--Tooltip_NeedWrench = "%1 required.",

--IGUI_CraftUI_RequiredItems = "Required items:", getText("IGUI_CraftUI_RequiredItems")
--ItemName_Base.LeadPipe = "Lead Pipe", getText("ItemName_Base.LeadPipe")
--ItemName_Base.MetalPipe = "Iron Pipe", getText("ItemName_Base.MetalPipe")
--ItemName_Base.Pipe = "Plastic Pipe", getText("ItemName_Base.Pipe")
--ItemName_Base.BlowTorch = "Welding Torch", getText("ItemName_Base.BlowTorch")
--ItemName_Base.WeldingMask = "Welder Mask", getText("ItemName_Base.WeldingMask")
--ItemName_Base.WeldingRods = "Welding Rods", getText("ItemName_Base.WeldingRods")
--IGUI_CraftUI_RequiredSkills = "Required skills:", getText("IGUI_CraftUI_RequiredSkills")
--IGUI_perks_Maintenance = "Maintenance", getText("IGUI_perks_Maintenance")
--ContextMenu_MetalWelding = "Welding", getText("ContextMenu_MetalWelding")
--IGUI_PlayerStats_Add = "Add"
--IGUI_AdminPanel_ItemList_AddX = "Add Multiple"
--ContextMenu_Remove = "Remove" 
--                     "Plumb Options" = getText("ContextMenu_PlumbItem", getText("IGUI_DebugMenu_Options"))
--IGUI_CraftUI_FromBaseItem = "From %1"
--ItemName_Base.MenuCard = "Menu"
-- UI_mods_ModDisable = "Disable"
--                    "Plumb Options" = getText("ContextMenu_PlumbItem", getText("IGUI_DebugMenu_Options"))
--UI_DisplayOptions_Cursor = "Cursor",
-- ItemName_Base.MenuCard = "Menu"
--IGUI_Tutorial_MoreInfo = "More Info",



local option_localized = {
	         ["adv_plumbing_enabled"] = string.format("%s '%s (%s)' - %s",getText("Enable"), getText("Fluid_Options"), getText("Advanced"),getText("Tooltip_NeedWrench",string.format("%s %s/%s",getText("IGUI_AttachmentEditor_New"),getText("Challenge_Challenge2_TabItems"),getText("Challenge_Challenge2_Skills")))),
	["adv_plumbing_context_disabled"] = string.format("%s '%s' %s",getText("UI_mods_ModDisable"),getText("ContextMenu_PlumbItem", getText("IGUI_DebugMenu_Options")),getItemNameFromFullType("Base.MenuCard"))
}
local tooltip_localized = {
	         ["adv_plumbing_enabled"] = string.format("%s %s, %s, %s, %s, %s, %s. %s %s & %s.",getText("IGUI_CraftUI_RequiredItems"),getText("ItemName_Base.LeadPipe"), getText("ItemName_Base.MetalPipe"), getText("ItemName_Base.Pipe"), getText("ItemName_Base.BlowTorch"), getText("ItemName_Base.WeldingMask"), getText("ItemName_Base.WeldingRods"), getText("IGUI_CraftUI_RequiredSkills"), getText("IGUI_perks_Maintenance"), getText("ContextMenu_MetalWelding")),
	["adv_plumbing_context_disabled"] = string.format("%s %s %s %s (%s)",getText("UI_mods_ModDisable"),getText("ContextMenu_PlumbItem", getText("IGUI_DebugMenu_Options")),getText("UI_DisplayOptions_Cursor"),getText("ItemName_Base.MenuCard"),"Still can RightClick PipeWrench for menu")
}

local plumbing_options_str = getText("ContextMenu_PlumbItem", getText("IGUI_DebugMenu_Options"))
function do_plumbing_options_window(player)
	if isServer() then return end
	local more_info = getText("IGUI_Tutorial_MoreInfo")
	local PADDING = 5
	local OPTION_HEIGHT = 32
	local TAB_PANEL_HEADER_HEIGHT  = 21
	local WINDOW_HEADER_BAR_HEIGHT = 20
	local WINDOW_FOOTER_BAR_HEIGHT = 9
	local window_x = 320
	local window_y = 100
	local option_font = UIFont.NewLarge
	local options_list = {
							{text=option_localized["adv_plumbing_enabled"],tooltip=tooltip_localized["adv_plumbing_enabled"]},
							{text=option_localized["adv_plumbing_context_disabled"],tooltip=tooltip_localized["adv_plumbing_context_disabled"]}
						}
    local window = UI.Window{
        x = window_x, y = window_y,
        width  = 950, 
		height = 350,
        isPin = false,
        children = {
            body = UI.Window.children.body{
                children = {
                    tabPanel = UI.TabPanel{
                        tabs = {plumbing_options_str,more_info},
                        children = {
                            [plumbing_options_str] = UI.Node{
                                name = plumbing_options_str,
                                isStencil = true,
                                children = {
                                    container = UI.Node{
                                        anchorLeft = -1, anchorRight = -10,
                                        children = { },
                                        init = function(self)
											for i=1,#options_list do
												self.children["option"..tostring(i)] = pzapi_option_checkbox(options_list[i].text,options_list[i].tooltip,(i-1) * (PADDING+OPTION_HEIGHT),option_height,option_font)
												self.children["option"..tostring(i)].parent_window = self.parent.parent.parent.parent--handled by default init, just here for future reference in case future UI structure isnt identical
												self.children["option"..tostring(i)].tooltip       = self.parent.parent.parent.parent.children.tooltip
												UI._addChild(self, self.children["option" .. tostring(i)])
											end
                                        end,
                                    }
                                },
								init = function(self)
									local longest_str = options_list[1].text
									local num_options = #options_list
									for i=2,num_options do
										if getTextManager():MeasureStringX(option_font, options_list[i].text) > getTextManager():MeasureStringX(option_font,longest_str) then longest_str = options_list[i].text end
									end
									self.tab_width = getTextManager():MeasureStringX(option_font, longest_str) + 2*PADDING + OPTION_HEIGHT + 2*PADDING
									self.tab_height = OPTION_HEIGHT*num_options + PADDING*(num_options+1) + TAB_PANEL_HEADER_HEIGHT + WINDOW_HEADER_BAR_HEIGHT + WINDOW_FOOTER_BAR_HEIGHT
									self.parent.parent.parent:setWidth (self.tab_width)
									self.parent.parent.parent:setHeight(self.tab_height)
								end
                            },
							[more_info] = UI.Node{
								tab_height = 400,
								name = more_info,
								anchorLeft = -1, anchorRight = -10,
								children = { 
									adv_plumbing_header = UI.Text{
										text=option_localized["adv_plumbing_enabled"],
										x = PADDING
									},
									adv_plumbing_description = UI.Text{
										x = PADDING,
										y = OPTION_HEIGHT + PADDING,
										font = UIFont.Medium,
										text="\r\nEnables advanced plumbing features. (Coming Soon!)\r\n    Includes:\r\n        > Horizontal Piping (connect sinks along the same floor to share collectors)\r\n        > Vertical Piping (now required, existing sinks must be re-plumbed with pipe items!)\r\n        > Sprinklers & Valves\r\n        > Additional item requirements (Welding Rods + Pipes)\r\n        > Additional skill requirements (Maintenance & Welding)\r\n\r\nIf you prefer to keep it vanilla, you can disable the right-click menu option. \r\nIf needed, you can access the options again by right clicking a pipe wrench."
									}	
								},
								init = function(self)
									self.tab_width = getTextManager():MeasureStringX(self.children.adv_plumbing_header.font, options_list[1].text) + 2*PADDING
								end
							}
                        },
						select = function(self, id)
							for _, key in ipairs(self.tabs) do
								self.children[key]:setVisible(false)
								self.children[key]:setEnabled(false)
								self.children["button_" .. key]:setSelected(false)
							end
							self.children[id]:setVisible(true)
							self.children[id]:setEnabled(true)
							self.children["button_" .. id]:setSelected(true)
							local new_width, new_height = self.children[id].tab_width, self.children[id].tab_height
							-- print(string.format("[Lightja] changed options tab. New x,y: (%s, %s), old x,y: (%s,%s)",tostring(new_width),tostring(new_height),tostring(self.parent.parent.width),tostring(self.parent.parent.height)))
							self.parent.parent:setWidth(self.children[id].tab_width)
							self.parent.parent:setHeight(self.children[id].tab_height)
						end
                    }
                }
            }
        },
		init = function(self)
			self.children.tooltip = UI.Texture{
				height = 32 + 2*PADDING,
				children = { },
				init = function(self)
					self:setColor(0,0,0,1)
					self.children.label = UI.Text{
						font = UIFont.Small,
						x = PADDING,-- y = PADDING,
						init = function(self)
							self:setColor(1,1,1,1)
							self:setAlwaysOnTop(true)
						end
					}
					self.font = UIFont.Small
					self:setVisible(false)
					self:setEnabled(false)
					self:setHeight(getTextManager():getFontHeight(self.font))
					UI._addChild(self, self.children.label)
				end,
			}
			UI._addChild(self, self.children.tooltip)
		end
    }
    window:instantiate()
end

local function pipewrench_plumbing_options_menu(player, context, items)
	local test_item = nil
    for _,item in ipairs(items) do
		test_item = item
		if not instanceof(item, "InventoryItem") then
            test_item = item.items[1];
        end
		if not test_item:isBroken() and (test_item:getType() == "PipeWrench" or test_item:hasTag("PipeWrench")) then
			context:addOption(plumbing_options_str,player,do_plumbing_options_window)
			return
		end
	end
end

function advanced_plumbing_enabled()
	return plumbing_options[option_localized["adv_plumbing_enabled"]]
end

function advanced_plumbing_context_menu_disabled()
	return plumbing_options[option_localized["adv_plumbing_context_disabled"]]

end


Events.OnPreFillInventoryObjectContextMenu.Add(pipewrench_plumbing_options_menu)