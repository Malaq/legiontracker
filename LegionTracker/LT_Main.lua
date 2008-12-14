LT_VERSION = "Legion Tracker 0.1"
LT_NumPlayersShown = 5;
LT_Main_SortIndex = 1;
-- {0, 1, ..., n-1} -> player_name
LT_PlayerList = nil;
LT_NameLookup = nil;

function LT_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("GUILD_ROSTER_UPDATE");
    this:RegisterEvent("CHAT_MSG_SYSTEM");
    --this:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    
    LT_LoadLabels();
    this:EnableMouseWheel(true);
    this:SetScript("OnMouseWheel", LT_OnMouseWheel);
    SLASH_LEGIONTRACKER1 = "/lt";
    SLASH_LEGIONTRACKER2 = "/legiontracker";
	SlashCmdList['LEGIONTRACKER'] = function(msg)
		LT_SlashHandler(msg)
	end
end

function LT_Main_OnShow()
end

function LT_SlashHandler(args)
    if args == '' then
		LT_Print("Legion Tracker", "yellow");
		LT_Print("-------------------------------------", "yellow");
		LT_Print("show - Displays the main window.", "yellow");
		LT_Print("hide - Hides the main window.", "yellow");
		LT_Print("loot - Loot commands.");
        LT_Print("timer - Timer commands.", "yellow");
        LT_Print("attendance - Attendance Commands.", "yellow");
	else
		if args == "show" then
		    LT_Main:Show();
		end
		if args == "hide" then
		    LT_Main:Hide();
		end
		if string.find(args, "^loot") ~= nil then
			LT_Loot_SlashHandler(args);
		elseif string.find(args, "^timer") ~= nil then
            LT_Timer_SlashHandler(args);
        elseif string.find(args, "^attendance") ~= nil then
            LT_Attendance_SlashHandler(args);    
        end
	end
end

--Add color choices for msg_format?
function LT_Print(message, msg_format)
    if (msg_format == nil) then
        DEFAULT_CHAT_FRAME:AddMessage(message);
    else
        DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 1, 0);
    end
end

function LT_Main_SortBy(id)
    id = id+1;
    if math.abs(LT_Main_SortIndex) == id then
        LT_Main_SortIndex = -LT_Main_SortIndex;
    else
        LT_Main_SortIndex = id;
    end
    
    LT_UpdatePlayerList();
end

function LT_SetupPlayerList()
    local name_label = getglobal("LT_Main".."NameHead".."Label");
    local class_label = getglobal("LT_Main".."ClassHead".."Label");
    local ms_label = getglobal("LT_Main".."MSHead".."Label");
    local attendance_label = getglobal("LT_Main".."AttendanceHead".."Label");
    local as_label = getglobal("LT_Main".."ASHead".."Label");   
    local os_label = getglobal("LT_Main".."OSHead".."Label");
    local unassigned_label = getglobal("LT_Main".."UnassignedHead".."Label");
    
    local spread = (name_label:GetHeight() + 4);
    
    local labels = {name_label, class_label, attendance_label, ms_label, as_label, os_label, unassigned_label};
    local headings = {"Name", "Class", "Attendance", "MainSpec", "AltSpec", "OffSpec", "Unassigned"};
    LT_NumPlayersShown = floor((LT_Main:GetHeight() - (LT_Main:GetTop() - name_label:GetBottom())) / spread);
    local offset = floor(LT_SliderVal() * (#LT_PlayerList - LT_NumPlayersShown) + 0.5) + 1;
    for i = 0, LT_NumPlayersShown-1 do
        local id = i+offset;
        for j = 1, #labels do
            local label_name = "LT_"..headings[j].."Label_"..i;
            _G[label_name] = CreateFrame("Button", label_name, LT_Main);
            local label = _G[label_name];
            
            label:SetScript("OnClick", function (this)
                if (LT_PlayerList[i+offset] ~= nil) then
                    local cur_offset = floor(LT_SliderVal() * (#LT_PlayerList - LT_NumPlayersShown) + 0.5) + 1;
                    LT_Char_ShowPlayer(GetGuildRosterInfo(LT_PlayerList[cur_offset + i]));
                end
            end);
            
            label:SetWidth(labels[j]:GetWidth());
            label:SetHeight(labels[j]:GetHeight());
            label:ClearAllPoints();
            local x = 0;
            local y = -(i+1)*spread;
            label:SetPoint("CENTER", labels[j], "CENTER", x, y);
            
            label:Show();
            local font_string = label:CreateFontString("$parentText", "OVERLAY", "GameFontNormal");
            font_string:SetFont("Fonts\\FRIZQT__.TTF", 9);
            font_string:SetText("");
            font_string:SetTextColor(0.8, 1.0, 0.8);
            label:SetFontString(font_string);
        end

    end
end

function LT_SliderVal()
    local sliderMax, sliderMin, slider;
    slider = getglobal("LT_PlayerListSliderSlider");
    sliderMin, sliderMax = slider:GetMinMaxValues();
    return slider:GetValue() / (sliderMax-sliderMin);
end

function LT_OnMouseWheel(this, amt)
    local slider = getglobal("LT_PlayerListSliderSlider");
    local diff = 1500;
    slider:SetValue(slider:GetValue() - diff * amt);
    LT_RedrawPlayerList();
end

function LT_GetClassColor(class)
    local color_class = string.upper(class);
    if (color_class == "DEATH KNIGHT") then
        color_class = "DEATHKNIGHT";
    end
    return RAID_CLASS_COLORS[color_class];
end

function LT_RedrawPlayerList()
    if (LT_PlayerList == nil) then
        LT_UpdatePlayerList();
    end
    
    local headings = {"Name", "Class", "Attendance", "MainSpec", "AltSpec", "OffSpec", "Unassigned"};
    local offset = floor(LT_SliderVal() * (#LT_PlayerList - LT_NumPlayersShown) + 0.5) + 1;
    if (offset < 1) then
        offset = 1;
    end
    for i = 0, LT_NumPlayersShown-1 do
        local labels = {};
        for j = 1, #headings do
            labels[j] = getglobal("LT_"..headings[j].."Label_"..i);
        end
        
        local name_label = labels[1];
        local class_label = labels[2];
        local ms_label = labels[3];
		if LT_PlayerList[i+offset] == nil then
			return
		end
        local name = GetGuildRosterInfo(LT_PlayerList[i + offset]);
        if name ~= nil and name_label ~= nil then
            name_label:SetText(name);
            name_label:GetFontString():SetTextColor(1.0, 1.0, 1.00);
            local _, _, _, _, class = GetGuildRosterInfo(LT_PlayerList[i + offset]);
            class_label:SetText(class);
            local colors = LT_GetClassColor(class);
            class_label:GetFontString():SetTextColor(colors.r, colors.g, colors.b);
            
            -- Loots
            for i = 1, 4 do
                labels[3 + i]:SetText(LT_Loot_GetLootCount(i, name));
            end
            
            -- Attendance
            local attendance_ph = LT_GetAttendance(LT_PlayerList[i+offset]);
            if ( attendance_ph == "" ) then
                labels[3]:SetText("");
            else
                labels[3]:SetText(""..LT_GetAttendance(LT_PlayerList[i+offset]).."%");
            end
        else
            for i = 1, #labels do
                labels[i]:SetText("");
            end
        end
    end
end

function LT_IsNumber(str)
    if string.find(""..str, "%d") and string.find(""..str, "%D")==nil then
        return 1;
    else
        return nil;
    end
end

function LT_ComparePlayerOrder(p1, p2)
    local headings = {"Name", "Class", "Attendance", "MainSpec", "AltSpec", "OffSpec", "Unassigned"};
    local sort_index = math.abs(LT_Main_SortIndex);
    if sort_index == 1 then
        if (GetGuildRosterInfo(p1) ~= nil and GetGuildRosterInfo(p2) ~= nil) then
            p1 = GetGuildRosterInfo(p1);
            p2 = GetGuildRosterInfo(p2);
        end
    elseif sort_index == 2 then
        _, _, _, _, p1 = GetGuildRosterInfo(p1);
        _, _, _, _, p2 = GetGuildRosterInfo(p2);
    elseif sort_index == 3 then
        p1 = LT_GetAttendance(p1);
        p2 = LT_GetAttendance(p2);
        if LT_IsNumber(p1)==nil then
            p1 = -1;
        end
        if LT_IsNumber(p2)==nil then
            p2 = -1;
        end
    elseif sort_index >= 4 then
        p1 = LT_Loot_GetLootCount(sort_index - 3, GetGuildRosterInfo(p1));
        p2 = LT_Loot_GetLootCount(sort_index - 3, GetGuildRosterInfo(p2));
    end
    
    if (LT_Main_SortIndex < 0) then
        return p1 > p2;
    else
        return p1 < p2;
    end
end

function LT_GetPlayerIndexFromName(name)
    return LT_NameLookup[name];
end

function LT_UpdatePlayerList()
    LT_PlayerList = {};
    LT_NameLookup = {};
    local num_members = GetNumGuildMembers(false);
    for i = 1, num_members do
        LT_PlayerList[i] = i;
        local name = GetGuildRosterInfo(i);
        if (name ~= nil) then
            LT_NameLookup[name] = i;
        end
    end
    table.sort(LT_PlayerList, LT_ComparePlayerOrder);
    LT_RedrawPlayerList();
end

function LT_PlayerListSliderChanged()
    LT_RedrawPlayerList();
end

function LT_ResetAll()
    StaticPopupDialogs["Reset Warning"] = {
    text = "You are about to reset all attendance and loot data, are you sure?  This process can not be reversed.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        LT_ResetAttendance();
        LT_PlayerLootTable = {};
		LT_LootTable = {};
        LT_UpdatePlayerList();
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
    };
    
    StaticPopup_Show("Reset Warning");
end

function LT_LoadLabels()
    local timer_label = getglobal("LT_Main".."Timer".."Label");
    timer_label:SetTextColor(0, 1, 1);
    timer_label:SetText("<Click for timer>");
    
    local version_label = getglobal("LT_Main".."TitleString");
    version_label:SetText(LT_VERSION);
    
    local name_label = getglobal("LT_Main".."NameHead".."Label");
    name_label:SetText("Name");
    
    local class_label = getglobal("LT_Main".."ClassHead".."Label");
    class_label:SetText("Class");
    
    local attendance_label = getglobal("LT_Main".."AttendanceHead".."Label");
    attendance_label:SetText("Attendance");
    
    local ms_label = getglobal("LT_Main".."MSHead".."Label");
    ms_label:SetText("Main");
    
    local as_label = getglobal("LT_Main".."ASHead".."Label");
    as_label:SetText("Alt");
    
    local os_label = getglobal("LT_Main".."OSHead".."Label");
    os_label:SetText("Off");
    
    local unassigned_label = getglobal("LT_Main".."UnassignedHead".."Label");
    unassigned_label:SetText("Unassigned");
    
    LT_SetupPlayerList();
end

function LT_Main_OnEvent(this, event, arg1)
    -- A hack to get the list working on startup... the guild roster is empty until some
    -- arbitrary amount of time into the game.
    if (LT_PlayerList == nil or #LT_PlayerList == 0) then
        GuildRoster();
    end
    
    if (event == "GUILD_ROSTER_UPDATE") then
        LT_UpdatePlayerList();
    elseif (event == "VARIABLES_LOADED") then
        LT_UpdatePlayerList();
    end
end

function LT_ExportButton()
    StaticPopupDialogs["Example_HelloWorld"] = {
    text = "You are about to export all data, are you sure?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        LT_Print("You clicked Yes.","Yellow");
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
    };
    
    StaticPopup_Show("Example_HelloWorld");
end