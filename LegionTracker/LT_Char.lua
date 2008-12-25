LT_Char_CurPlayer = nil;
LT_Char_Headings = nil;
LT_Char_HeadingText = nil;

function LT_Char_ShowPlayer(name)
    if (name == LT_Char_CurPlayer and LT_Char:IsShown()) then
        LT_Char:Hide();
        LT_Char_CurPlayer = nil;
        return
    end
	if (LT_AllLootPanel:IsShown()) then
		LT_AllLoot:ToggleShow();
	end
    LT_Char_CurPlayer = name;
    LT_LootUI:SetParent(LT_LootListPanel);
	LT_LootUI:UpdateFrame(name);

    LT_Char:SetFrameLevel(100);

    LT_Char:Show();
    LT_Char_UpdateLootFrame();

end

LT_Char_NumEntriesShown = 0;
LT_Char_EntryHeight = 15;
LT_Char_EntrySpread = 15;
LT_Char_NumEntries = 200;
LT_Char_Loots = nil;
LT_Char_SortIndex = -3;
LT_PrevNumTimelineEntries = -1;                   

function LT_Char_SortBy(index)
    if math.abs(LT_Char_SortIndex) == index then
        LT_Char_SortIndex = -LT_Char_SortIndex;
    else
        LT_Char_SortIndex = index;
    end
    LT_Char_UpdateLootFrame();
end

function LT_Char_Compare(l1, l2)
    local v1 = l1.time;
    local v2 = l2.time;
    local index = math.abs(LT_Char_SortIndex);
    if (index == 1) then
        v1 = GetItemInfo(l1.itemString);
        v2 = GetItemInfo(l2.itemString);
    elseif (index == 2) then
        v1 = l1.zone..l1.subzone;
        v2 = l2.zone..l2.subzone;
    elseif (index == 4) then
        v1 = LT_Loot_GetSpecId(l1.spec);
        v2 = LT_Loot_GetSpecId(l2.spec);
    end
    if (LT_Char_SortIndex > 0) then
        return v1 < v2;
    else
        return v1 > v2;
    end
end

function LT_Char_DrawTimeline()
    local attendance = LT_GetRawAttendance(LT_GetPlayerIndexFromName(LT_Char_CurPlayer))
    local num_entries = string.len(attendance);
    if (LT_IsNumber(attendance) == nil) then
        num_entries = 0;
        LT_Timeline:Hide();
    else
        LT_Timeline:Show();
    end
    local entry_width = (LT_Timeline:GetWidth()-10) / num_entries;
    if (LT_Timeline.texture == nil) then
        LT_Timeline.texture = LT_Timeline:CreateTexture();
        LT_Timeline.texture:SetAllPoints(LT_Timeline);
        LT_Timeline.texture:SetTexture(0.2, 0.2, 0.2);
    end
    
    for i = 1, LT_PrevNumTimelineEntries+1 do
        if (i ~= LT_PrevNumTimelineEntries + 1) then
            _G["LT_TimelineBlock_"..i]:Hide();
        end
        _G["LT_TimeLabel_"..i]:Hide();
    end
    LT_PrevNumTimelineEntries = num_entries;
    
    for i = 1, num_entries+1 do
        if (i ~= num_entries + 1) then
            local name = "LT_TimelineBlock_"..i;
            local block = _G[name] or CreateFrame("Frame", name, LT_Timeline);
            block:Show();
            block:SetWidth(entry_width-1.5);
            block:SetHeight(LT_Timeline:GetHeight()-10);
            if (block.texture == nil) then
                block.texture = block:CreateTexture();
            end
            block.texture:SetAllPoints(block);
            if (string.char(attendance:byte(i)) == "0") then
                block.texture:SetTexture(0, 0.0, 0.0);
            else
                block.texture:SetTexture(0.1, 1, 0.1);
            end
            block:ClearAllPoints();
            block:SetPoint("TOPLEFT", LT_Timeline, "TOPLEFT", (i - 1) * entry_width + 5, -3);
        end
        
        local label_name = "LT_TimeLabel_"..i;
        local label = _G[label_name] or CreateFrame("Button", label_name, LT_Timeline);
        label:Show();
        label:ClearAllPoints();
        label:SetWidth(entry_width);
        label:SetHeight(15);
        label:SetPoint("CENTER", LT_Timeline, "TOPLEFT", (i - 1) * entry_width + 5, -LT_Timeline:GetHeight()+3);

        local font_string = label:CreateFontString("$parentText", "OVERLAY", "GameFontNormal");
        font_string:SetFont("Fonts\\FRIZQT__.TTF", 5);
        font_string:SetText(date("%H:%M", LT_TIMER_START + (i-1)*LT_GetInterval()));
        font_string:SetTextColor(0.8, 1.0, 0.8);
        label:SetFontString(font_string);
    end
end

function LT_Char_UpdateLootFrame()
    
    local name, rank, _, _, class = GetGuildRosterInfo(LT_GetPlayerIndexFromName(LT_Char_CurPlayer));
    local color = LT_GetClassColor(class);
    if (rank == "Alt") then
        local main = LT_GetMainName(LT_GetPlayerIndexFromName(LT_Char_CurPlayer));
        if (main == name) then
            LT_CharMainNameLabel:SetText("Main: Fix officer note.");
        else
            LT_CharMainNameLabel:SetText("Main: "..main);
        end
    else
        LT_CharMainNameLabel:SetText("");
    end
    LT_CharTitleString:SetTextColor(color.r, color.g, color.b);
    LT_CharTitleString:SetText(LT_Char_CurPlayer);
    local temp = LT_GetAttendance(LT_GetPlayerIndexFromName(LT_Char_CurPlayer));
    if (temp == "") then
        LT_CharUpperLeftAttendancePercentLabel:SetText("");
        if (rank == "Friend") then
            LT_CharUpperLeftAttendancePercentLabel:SetText("Friend");
        elseif (rank == "Alt") then
            LT_CharUpperLeftAttendancePercentLabel:SetText("Alt");
        end
    else
        LT_CharUpperLeftAttendancePercentLabel:SetText(temp.."%");
    end
    LT_CharUpperRightMainSpecTotalLabel:SetText(LT_Loot_GetLootCount(1, LT_Char_CurPlayer).." Items");
    
    LT_Char_DrawTimeline();

	LT_LootUI:UpdateFrame(LT_Char_CurPlayer);
end

function LT_Char_OnLoad()
    this:Hide();
	LT_LootUI:SetupFrame(LT_LootListPanel);
    
    -- Makes ESC work
    tinsert(UISpecialFrames, this:GetName());
end
