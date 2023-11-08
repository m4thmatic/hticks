--[[
* Addons - Copyright (c) 2021 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
hp

--]]

addon.author   = 'MathMatic';
addon.name     = 'hticks';
addon.desc     = 'Shows the amount of time until the next heal tick.';
addon.version  = '1.1.0';

require ('common');
local imgui = require('imgui');
local settings = require('settings');
local chat = require('chat');
local gdi = require('gdifonts.include');
local ffi = require('ffi');

ffi.cdef[[
    int16_t GetKeyState(int32_t vkey);
]]

local defaultConfig = T{
	textSize     = 12,
	textOpacity	 = 1.0,
	textColor	 = T{1.00, 1.00, 1.00, 1.0},
	textColor2	 = T{1.00, 1.00, 1.00, 1.0},
	outlineColor = T{0.00, 0.00, 0.00, 1.0},	
	outlineWidth = 4,
	position_x   = 100;
	position_y   = 100;
	alwaysShow	= false,
}

local hticks = T{
	settings = settings.load(defaultConfig);
	nextTick	= 0;
	heal		= true;
	configMenuOpen = false;
}

local fontSettings = {
    box_height = 0,
    box_width = 0,
    font_family = 'Courier New',
    font_flags = gdi.FontFlags.Bold,
    font_alignment = gdi.Alignment.Center,
    font_height = hticks.settings.textSize * 2,
    font_color = 0xFFFFFFFF,
    gradient_color = 0xFFFFFFFF,
    outline_color = 0xFF000000,
    gradient_style = gdi.Gradient.TopToBottom,
    outline_width = hticks.settings.outlineWidth,
    position_x = hticks.settings.position_x,
    position_y = hticks.settings.position_y,
    visible = true,
    text = '',
};
local myFontObject;

local lastPositionX, lastPositionY;
local dragActive = false;


--------------------------------------------------------------------
function hexToRBG(hexVal)
	local alpha = bit.band(bit.rshift(hexVal, 24), 0xff)/0xff;
	local red   = bit.band(bit.rshift(hexVal, 16), 0xff)/0xff;
	local green = bit.band(bit.rshift(hexVal,  8), 0xff)/0xff;
	local blue  = bit.band(bit.rshift(hexVal,  0), 0xff)/0xff;

	--return alpha, red, green, blue;
	return red, green, blue;
end

function argbToHex(alpha, red, green, blue)
	return	math.floor(alpha * 0xff) * 0x1000000 + 
			bit.lshift(red   * 0xff, 16) +
			bit.lshift(green * 0xff,  8) +
			bit.lshift(blue  * 0xff,  0);
end

--------------------------------------------------------------------
function renderMenu()

	imgui.SetNextWindowSize({500});
	if (imgui.Begin('hticks Configuration Menu', true)) then
		imgui.Text("Display Options");
		imgui.BeginChild('display_settings', { 0, 300, }, true);
			local textOpacity  = T{hticks.settings.textOpacity};
			local textSize     = T{hticks.settings.textSize};			
			local outlineWidth = T{hticks.settings.outlineWidth};
			local alwaysShow   = T{hticks.settings.alwaysShow};			

			imgui.SliderFloat('Window Opacity', textOpacity, 0.01, 1.0, '%.2f');
			imgui.ShowHelp('Set the window opacity.');		
			hticks.settings.textOpacity = textOpacity[1];
			
			imgui.SliderFloat('Font Size', textSize, 5, 40, '%1.0f');
			imgui.ShowHelp('Set the font size.');
			hticks.settings.textSize = textSize[1];
			myFontObject:set_font_height(hticks.settings.textSize * 2);

			imgui.ColorEdit3("Top Color", hticks.settings.textColor);
			imgui.ColorEdit3("Bottom Color", hticks.settings.textColor2);
			imgui.ColorEdit3("Outline Color", hticks.settings.outlineColor);
			
			local tc = hticks.settings.textColor;
			local tc2 = hticks.settings.textColor2;
			local oc = hticks.settings.outlineColor;
			myFontObject:set_font_color(argbToHex(hticks.settings.textOpacity, tc[1], tc[2], tc[3]));
			myFontObject:set_gradient_color(argbToHex(hticks.settings.textOpacity, tc2[1], tc2[2], tc2[3]));
			myFontObject:set_outline_color(argbToHex(hticks.settings.textOpacity, oc[1], oc[2], oc[3]));

			imgui.SliderFloat('Outline Width', outlineWidth, 0, 10, '%1.0f');
			imgui.ShowHelp('Set the thickness of the text outline.');
			hticks.settings.outlineWidth = outlineWidth[1];
			myFontObject:set_outline_width(hticks.settings.outlineWidth)
			
			imgui.Checkbox('Always Show Window', alwaysShow);
			imgui.ShowHelp('Shows the tick window even when not resting.');
			hticks.settings.alwaysShow = alwaysShow[1];
		imgui.EndChild();

		if (imgui.Button('  Save  ')) then
			settings.save();
			hticks.configMenuOpen = false;
            print(chat.header(addon.name):append(chat.message('Settings saved.')));
		end
		imgui.SameLine();
		if (imgui.Button('  Reset  ')) then
			settings.reset();
            print(chat.header(addon.name):append(chat.message('Settings reset to default.')));
		end
	end
	imgui.End();
end

--------------------------------------------------------------------
function renderTickWindow(player)

	if (player.Status ~= 33) then
		myFontObject:set_text("20");
	else
		if (hticks.heal == false) then
			hticks.nextTick = os.time() + 21;
			hticks.heal = true;
		end
			
		if (hticks.nextTick - os.time() <= 0) then
			hticks.nextTick = os.time() + 10;
		end
		
		local ticksRemaining = "20";
			
		if (hticks.nextTick - os.time() < 20) then
			ticksRemaining = tostring(hticks.nextTick - os.time());
		end

		myFontObject:set_text(tostring(ticksRemaining));
	end

end

--------------------------------------------------------------------------------
-------------- This function is copied from the XITools addon ------------------
--------------------------------------------------------------------------------
local menuBase = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0);

--- Gets the name of the top-most menu element.
function GetMenuName()
    local subPointer = ashita.memory.read_uint32(menuBase);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

--- Determines if the map is open in game, or we are at the login screen
function hideWindow()
    local menuName = GetMenuName();
    return menuName:match('menu%s+map.*') ~= nil
        or menuName:match('menu%s+scanlist.*') ~= nil
        or menuName:match('menu%s+cnqframe') ~= nil
		or menuName:match('menu%s+dbnamese') ~= nil
		or menuName:match('menu%s+ptc6yesn') ~= nil
end

--------------------------------------------------------------------
local function HitTest(x, y)
    local rect = myFontObject.rect;
    if (rect) then
        local currentX = myFontObject.settings.position_x;
        local currentY = myFontObject.settings.position_y;
        return (x >= currentX) and (x <= (currentX + rect.right)) and (y >= currentY) and ((y <= currentY + rect.bottom));
    else
        return false;
    end        
end

local function IsControlHeld()
    return (bit.band(ffi.C.GetKeyState(0x10), 0x8000) ~= 0);
end

--------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
	myFontObject = gdi:create_object(fontSettings, false);

--	local tc = hticks.settings.textColor;
--	local tc2 = hticks.settings.textColor2;
--	local oc = hticks.settings.outlineColor;
--	myFontObject:set_font_color(argbToHex(hticks.settings.textOpacity, tc[1], tc[2], tc[3]));
--	myFontObject:set_gradient_color(argbToHex(hticks.settings.textOpacity, tc2[1], tc2[2], tc2[3]));
--	myFontObject:set_outline_color(argbToHex(hticks.settings.textOpacity, oc[1], oc[2], oc[3]));
--	myFontObject:set_position_x(hticks.settings.position_x);
--	myFontObject:set_position_y(hticks.settings.position_y);
end);

--------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()
    settings.save();
	gdi:destroy_interface();
end);

--------------------------------------------------------------------
settings.register('settings', 'settings_update', function(s)
    -- Update the settings table..
    if (s ~= nil) then
        hticks.settings = s;
 
		-- Set the text attributes
		local tc = hticks.settings.textColor;
		local tc2 = hticks.settings.textColor2;
		local oc = hticks.settings.outlineColor;
		myFontObject:set_font_color(argbToHex(hticks.settings.textOpacity, tc[1], tc[2], tc[3]));
		myFontObject:set_gradient_color(argbToHex(hticks.settings.textOpacity, tc2[1], tc2[2], tc2[3]));
		myFontObject:set_outline_color(argbToHex(hticks.settings.textOpacity, oc[1], oc[2], oc[3]));
		myFontObject:set_position_x(hticks.settings.position_x);
		myFontObject:set_position_y(hticks.settings.position_y);
	
	end
	
    -- Save the current settings..
    settings.save();
end);

--------------------------------------------------------------------
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or not args[1]:any('/ht', '/hticks')) then
        return;
    end

    -- Block all related commands..
    e.blocked = true;

	if (#args == 1) then
		hticks.configMenuOpen = not hticks.configMenuOpen;
	end
end);


--------------------------------------------------------------------
ashita.events.register('mouse', 'mouse_cb', function (e)
    if (dragActive) then
        local currentX = myFontObject.settings.position_x;
        local currentY = myFontObject.settings.position_y;
        myFontObject:set_position_x(currentX + (e.x - lastPositionX));
        myFontObject:set_position_y(currentY + (e.y - lastPositionY));
        lastPositionX = e.x;
        lastPositionY = e.y;
        if (e.message == 514) or (IsControlHeld() == false) then
            dragActive = false;
            e.blocked = true;
			
			hticks.settings.position_x = myFontObject.settings.position_x;
			hticks.settings.position_y = myFontObject.settings.position_y;
			settings.save();
            return;
        end
    end
    
    if (e.message == 513) then
        if (HitTest(e.x, e.y)) and (IsControlHeld()) then
            e.blocked = true;
            dragActive = true;
            lastPositionX = e.x;
            lastPositionY = e.y;
            return;
        end
    end
end);

--------------------------------------------------------------------
--[[
* event: d3d_present
* desc : Event called when the Direct3D device is presenting a scene.
--]]
ashita.events.register('d3d_present', 'present_cb', function ()

	if (hideWindow() == false) then
		local player = GetPlayerEntity();

		if (player == nil) then -- when zoning
			return;
		else
			if (player.Status ~= 33) then
				hticks.heal = false;
				myFontObject:set_visible(false);
			end
		
			if ((player.Status == 33) or (hticks.settings.alwaysShow == true)) then
				myFontObject:set_visible(true);
				renderTickWindow(player);
			end
			
			if (hticks.configMenuOpen == true) then
				renderMenu();
			end

		end

	end

end);
