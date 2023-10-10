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
addon.version  = '1.0.0';
-- The idea for this addon is based off of ticker which was originally written by
-- Almavivaconte & ported to Ashita v4 by Zal Das, & GetAwayCoxn. It has been completely
-- rewritten using imgui to provide more graphical options.

require ('common');
local imgui = require('imgui');
local settings = require('settings');
local chat = require('chat');

local defaultConfig = T{
	window = T{
		scale			= T{1.0},
		opacity			= T{0.8},
		backgroundColor	= T{0.23, 0.23, 0.26, 1.0},
		textColor		= T{1.00, 1.00, 1.00, 1.0},
		borderColor		= T{0.00, 0.00, 0.00, 1.0},	
	},
	resyncTicks		= T{false},
	alwaysVisible	= T{false},
}
local config = settings.load(defaultConfig);

local hticks = T{
	settings = settings.load(defaultConfig);

	curHP		= 0;
	curMP		= 0;
	nextTick	= 0;
	heal		= true;

	configMenuOpen = false;
}




--------------------------------------------------------------------
function renderMenu()

	imgui.SetNextWindowSize({500});
	if (imgui.Begin('hticks Configuration Menu', true, bit.bor(ImGuiWindowFlags_NoSavedSettings))) then
		imgui.Text("Display Options");
		imgui.BeginChild('display_settings', { 0, 300, }, true);
			imgui.SliderFloat('Window Scale', hticks.settings.window.scale, 0.1, 2.0, '%.2f');
			imgui.ShowHelp('Scale the window bigger/smaller.');

			imgui.SliderFloat('Window Opacity', hticks.settings.window.opacity, 0.0, 1.0, '%.2f');
			imgui.ShowHelp('Set the window opacity.');

			imgui.ColorEdit4("Text Color", hticks.settings.window.textColor);
			imgui.ColorEdit4("Border Color", hticks.settings.window.borderColor);
			imgui.ColorEdit4("Background Color", hticks.settings.window.backgroundColor);

			imgui.Checkbox('Resync Ticks', hticks.settings.resyncTicks);
			imgui.ShowHelp('Resync the tick counter when hp/mp increases while resting. Note: This will lead to the counter jumping around a *lot*.');

			imgui.Checkbox('Always Show Window', hticks.settings.alwaysVisible);
			imgui.ShowHelp('Shows the tick window even when not resting.');
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

	local windowSize = 10 * hticks.settings.window.scale[1];
    imgui.SetNextWindowBgAlpha(hticks.settings.window.opacity[1]);
    --rimgui.SetNextWindowSize({ windowSize, -1, }, ImGuiCond_Always);
	imgui.PushStyleColor(ImGuiCol_WindowBg, hticks.settings.window.backgroundColor);
	imgui.PushStyleColor(ImGuiCol_Border, hticks.settings.window.borderColor);
	imgui.PushStyleColor(ImGuiCol_Text, hticks.settings.window.textColor);

	if (imgui.Begin('hticks', true, bit.bor(ImGuiWindowFlags_NoDecoration))) then
		imgui.SetWindowFontScale(hticks.settings.window.scale[1]);

		if (player.Status ~= 33) then
			imgui.Text("Not healing");
		else
			if (hticks.heal == false) then
				hticks.nextTick = os.time() + 21;
				hticks.heal = true;
			end
			
			if (hticks.nextTick - os.time() <= 0) then
				hticks.nextTick = os.time() + 10;
			end

			if (hticks.settings.resyncTicks[1] == true) then
				local party = AshitaCore:GetMemoryManager():GetParty();
				local selfIndex = party:GetMemberTargetIndex(0);
			
				local hp = party:GetMemberHP(0);
				local mp = party:GetMemberMP(0);
				
				if (hticks.nextTick - os.time() <= 10) then
					if ((hp > hticks.curHP + 10) or (mp > hticks.curMP + 12)) then
						hticks.nextTick = os.time() + 10;
					end
				end
			
				hticks.curHP = hp;
				hticks.curMP = mp;

			end

			if (hticks.nextTick - os.time() <= 20) then --hide at start (when ticks is 21)
				imgui.Text(tostring(hticks.nextTick - os.time()));
			end
		end
		
		imgui.SetWindowFontScale(1.0); -- reset window scale
    end
    imgui.PopStyleColor(3);
	imgui.End();
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
ashita.events.register('load', 'load_cb', function()

end);

--------------------------------------------------------------------
ashita.events.register('unload', 'unload_cb', function()

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
			end
		
			if ((player.Status == 33) or (hticks.settings.alwaysVisible[1] == true)) then
				renderTickWindow(player);
			end
			
			if (hticks.configMenuOpen == true) then
				renderMenu();
			end

		end

		--[[
		selfIndex = party:GetMemberTargetIndex(0);
		if selfIndex ~= nil then
			local me = GetEntity(selfIndex)
			if me ~= nil then
				currentStatus = me.Status;
			end
		end

		if currentStatus ~= nil then
			if currentStatus == 33 then
		]]
		

	end
end);