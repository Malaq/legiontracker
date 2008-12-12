LT_VERSION = "Legion Tracker 0.1"

function LT_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("GUILD_ROSTER_UPDATE");
    this:RegisterEvent("CHAT_MSG_SYSTEM");
    --this:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    
    LT_LoadLabels();
    
    SLASH_LEGIONTRACKER1 = "/lt";
    SLASH_LEGIONTRACKER2 = "/legiontracker";
	SlashCmdList['LEGIONTRACKER'] = function(msg)
		LT_SlashHandler(msg)
	end
    
    GuildRoster();
end

function LT_SlashHandler(args)
    if args == '' then
		LT_Print("Legion Tracker", "blah");
		LT_Print("-------------------------------------", "blah");
		LT_Print("show - Displays the main window.", "blah");
		LT_Print("hide - Hides the main window.", "blah");
		LT_Print("loot - Loot commands.")
	else
		if args == "show" then
		    LT_Main:Show();
		end
		if args == "hide" then
		    LT_Main:Hide();
		end
		if string.find(args, "^loot") ~= nil then
			LT_Loot_SlashHandler(args);
		end
	end
end

function LT_Print(message, msg_format)
    if (msg_format == nil) then
        DEFAULT_CHAT_FRAME:AddMessage(message);
    else
        DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 1, 0);
    end
end

num_slots = 6;
function LT_SetupPlayerList()
    
    local name_label = getglobal("LT_Main".."NameHead".."Label");
    local class_label = getglobal("LT_Main".."ClassHead".."Label");
    local spread = (name_label:GetHeight()+10);
    local ms_label = getglobal("LT_Main".."MSHead".."Label");
    
    num_slots = floor((LT_Main:GetHeight() - (LT_Main:GetTop() - name_label:GetBottom())) / spread);
    for i = 0, num_slots-1 do
        -- NAME --
        local label_name = "LT_PlayerLabel_"..i;
        _G[label_name] = CreateFrame("Button", label_name, LT_Main);
        local label = _G[label_name];
        
        label:SetText("Player"..i);
        label:SetParent(LT_Main);
        
        label:SetWidth(name_label:GetWidth());
        label:SetHeight(name_label:GetHeight());
        label:ClearAllPoints();
        local x = 0;
        local y = -(i+1)*spread;
        label:SetPoint("TOPLEFT", name_label, "TOPLEFT", x, y);
        
        label:Show();
        local font_string = label:CreateFontString("$parentText", "OVERLAY", "GameFontNormal");
        font_string:SetFont("Fonts\\FRIZQT__.TTF", 9);
        font_string:SetText("Player"..i);
        font_string:SetTextColor(1.0, 0.9, 0.8);
        font_string:SetJustifyH("LEFT");
        label:SetFontString(font_string);
        
        -- CLASS --
        label_name = "LT_ClassLabel_"..i;
        _G[label_name] = CreateFrame("Button", label_name, LT_Main);
        label = _G[label_name];
        
        label:SetText("Class"..i);
        label:SetParent(LT_Main);
        
        label:SetWidth(class_label:GetWidth());
        label:SetHeight(class_label:GetHeight());
        label:ClearAllPoints();
        x = 0;
        y = -(i+1)*spread;
        label:SetPoint("CENTER", class_label, "CENTER", x, y);
        
        label:Show();
        font_string = label:CreateFontString("$parentText", "OVERLAY", "GameFontNormal");
        font_string:SetFont("Fonts\\FRIZQT__.TTF", 9);
        font_string:SetText("Player"..i);
        font_string:SetTextColor(0.6, 1.0, 0.8);
        font_string:SetJustifyH("LEFT");
        label:SetFontString(font_string);
        
        -- MAINSPEC --
        label_name = "LT_MainSpecLabel_"..i;
        _G[label_name] = CreateFrame("Button", label_name, LT_Main);
        label = _G[label_name];
        
        label:SetText("0");
        label:SetParent(LT_Main);
        
        label:SetWidth(ms_label:GetWidth());
        label:SetHeight(ms_label:GetHeight());
        label:ClearAllPoints();
        x = 0;
        y = -(i+1)*spread;
        label:SetPoint("CENTER", ms_label, "CENTER", x, y);
        
        label:Show();
        font_string = label:CreateFontString("$parentText", "OVERLAY", "GameFontNormal");
        font_string:SetFont("Fonts\\FRIZQT__.TTF", 9);
        font_string:SetText("0");
        font_string:SetTextColor(0.6, 0.9, 1.0);
        font_string:SetJustifyH("LEFT");
        label:SetFontString(font_string);

    end
end

function LT_SliderVal()
    local sliderMax, sliderMin, slider;
    slider = getglobal("LT_PlayerListSliderSlider");
    sliderMin, sliderMax = slider:GetMinMaxValues();
    return slider:GetValue() / (sliderMax-sliderMin);
end

-- {0, 1, ..., n-1} -> player_name
LT_PlayerList = nil;
LT_ClassLookup = nil;

function LT_RedrawPlayerList()
    if (LT_PlayerList == nil) then
        LT_UpdatePlayerList();
    end
    
    local offset = floor(LT_SliderVal() * (#LT_PlayerList - num_slots) + 0.5) + 1;
    for i = 0, num_slots-1 do
        local name_label = getglobal("LT_PlayerLabel_"..i);
        local class_label = getglobal("LT_ClassLabel_"..i);
        local ms_label = getglobal("LT_MainSpecLabel_"..i);
        local name = LT_PlayerList[i + offset];
        if name ~= nil and name_label ~= nil then
            name_label:SetText(name);
            local class = LT_ClassLookup[name];
            class_label:SetText(class);
            
            local colors = RAID_CLASS_COLORS[string.upper(class)];
            class_label:GetFontString():SetTextColor(colors.r, colors.g, colors.b);
            local num_loots = 0;
            if LT_PlayerLootTable[name] ~= nil then
                for k,v in pairs(LT_PlayerLootTable[name]) do
                    num_loots = num_loots + 1;
                end
            end
           
            ms_label:SetText(num_loots);
        end
        
      --  LT_PlayerLootTable
    end
end

function LT_UpdatePlayerList()
    for k, v in pairs(RAID_CLASS_COLORS) do
        LT_Print("k "..k);
        for k2, v2 in pairs(RAID_CLASS_COLORS[k]) do
            LT_Print("k2 "..k2.." v2 "..v2);
        end
    end
   
    LT_PlayerList = {};
    LT_ClassLookup = {};
    local num_members = GetNumGuildMembers(false);
    for i = 1, num_members do
        local class;
        LT_PlayerList[i], _, _, _, class = GetGuildRosterInfo(i);
        LT_ClassLookup[LT_PlayerList[i]] = class;
    end
    table.sort(LT_PlayerList);
    LT_RedrawPlayerList();
end

function LT_PlayerListSliderChanged()
    LT_RedrawPlayerList();
end

function LT_LoadLabels()
    timer_label = getglobal("LT_Main".."Timer".."Label");
    timer_label:SetText(string.format("%02d:%02d:%02d", "0", "0", "0"));
    
    version_label = getglobal("LT_Main".."Version".."Label");
    version_label:SetText(LT_VERSION);
    
    name_label = getglobal("LT_Main".."NameHead".."Label");
    name_label:SetText("Name");
    
    class_label = getglobal("LT_Main".."ClassHead".."Label");
    class_label:SetText("Class");
    
    attendance_label = getglobal("LT_Main".."AttendanceHead".."Label");
    attendance_label:SetText("Attendance");
    
    ms_label = getglobal("LT_Main".."MSHead".."Label");
    ms_label:SetText("Main");
    
    as_label = getglobal("LT_Main".."ASHead".."Label");
    as_label:SetText("Alt");
    
    os_label = getglobal("LT_Main".."OSHead".."Label");
    os_label:SetText("Off");
    
    unassigned_label = getglobal("LT_Main".."UnassignedHead".."Label");
    unassigned_label:SetText("Unassigned");
    
    LT_SetupPlayerList();
end

function LT_Main_OnEvent(this, event, arg1)
    if (event == "GUILD_ROSTER_UPDATE") then
        LT_UpdatePlayerList();
    end
end
