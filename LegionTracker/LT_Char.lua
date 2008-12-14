LT_Char_CurPlayer = nil;
LT_Char_Headings = nil;
LT_Char_HeadingText = nil;
LT_Char_Tooltip = CreateFrame("GameTooltip", "LT_LootTooltip", UIParent, "GameTooltipTemplate");
LT_Char_Tooltip:Hide();
function LT_Char_ShowPlayer(name)
    if (name == LT_Char_CurPlayer) then
        LT_Char:Hide();
        LT_Char_CurPlayer = nil;
        return
    end
    LT_Char_CurPlayer = name;

    LT_Char:SetFrameLevel(100);

    LT_Char:Show();
    local scroll_frame = _G["LT_Char_ScrollFrame"];
    if (scroll_frame ~= nil) then
        scroll_frame:SetVerticalScroll(0);
    end
    LT_Char_UpdateLootFrame();
end

LT_Char_NumEntriesShown = 0;
LT_Char_EntryHeight = 15;
LT_Char_EntrySpread = 15;
LT_Char_NumEntries = 200;
LT_Char_Loots = nil;
LT_Char_SortIndex = -3;
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
LT_PrevNumTimelineEntries = -1;                   
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
    local scroll_frame = _G["LT_Char_ScrollFrame"];
    if (scroll_frame == nil) then
        return;
    end
    
    local _, rank, _, _, class = GetGuildRosterInfo(LT_GetPlayerIndexFromName(LT_Char_CurPlayer));
    local color = LT_GetClassColor(class);
    LT_CharTitleString:SetTextColor(color.r, color.g, color.b);
    LT_CharTitleString:SetText(LT_Char_CurPlayer);
    local temp = LT_GetAttendance(LT_GetPlayerIndexFromName(LT_Char_CurPlayer));
    if (temp == "") then
        LT_CharUpperLeftAttendancePercentLabel:SetText("");
        if (rank == "Friend") then
            LT_CharUpperLeftAttendancePercentLabel:SetText("Friend");
        end
    else
        LT_CharUpperLeftAttendancePercentLabel:SetText(temp.."%");
    end
    LT_CharUpperRightMainSpecTotalLabel:SetText(LT_Loot_GetLootCount(1, LT_Char_CurPlayer).." Items");
    
    LT_Char_DrawTimeline();

    LT_Char_Loots = LT_Loot_GetLoots(LT_Char_CurPlayer);
    table.sort(LT_Char_Loots, LT_Char_Compare);
    LT_Char_NumEntries = #LT_Char_Loots;
    FauxScrollFrame_Update(scroll_frame, math.max(LT_Char_NumEntriesShown+1, LT_Char_NumEntries), LT_Char_NumEntriesShown, LT_Char_EntrySpread);
    local offset = FauxScrollFrame_GetOffset(scroll_frame);
    for i=1, LT_Char_NumEntriesShown do
        local id = i + offset;
        if (id > LT_Char_NumEntries) then
            local name_label = _G["LT_CharName_"..i];
            name_label:SetText("");
            local zone_label = _G["LT_CharZone_"..i];
            zone_label:SetText("");       
            local date_label = _G["LT_CharDate_"..i];
            date_label:SetText("");
            local spec_label = _G["LT_CharSpec_"..i];
            spec_label:SetText("");
        else
        
            local name_label = _G["LT_CharName_"..i];
            local _, link = GetItemInfo(LT_Char_Loots[id].itemString)
            name_label:SetText(link);
            name_label:SetScript("OnClick", function()
                LT_Char_Tooltip:SetHyperlink(link);
                LT_Char_Tooltip:Show();
                LT_Char_Tooltip:SetWidth(300);
                LT_Char_Tooltip:SetHeight(300);
                LT_Char_Tooltip:ClearAllPoints();
                LT_Char_Tooltip:SetPoint("CENTER", 0, 0);
            end);
            local zone_label = _G["LT_CharZone_"..i];
            zone_label:SetText(LT_Char_Loots[id].zone.." - "..LT_Char_Loots[id].subzone);
            zone_label:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 7);
            
            local date_label = _G["LT_CharDate_"..i];
            local secs = LT_Char_Loots[id].time;
            date_label:SetText(date("%b %d %H:%M", secs));
            date_label:GetFontString():SetTextColor(1, 1, 1);
            
            local spec_label = _G["LT_CharSpec_"..i];
            spec_label:SetText(LT_Char_Loots[id].spec);
            local color = LT_Loot_GetSpecColor(LT_Char_Loots[id].spec);
            spec_label:GetFontString():SetTextColor(color.r, color.g, color.b);
            spec_label:SetScript("OnClick", function()
                LT_Loot_ToggleSpec(LT_Char_Loots[id].lootId);
                LT_Char_UpdateLootFrame();
            end);
        end
    end
end

function LT_Char_OnLoad()
    this:Hide();
    LT_Char_Headings = {_G["LT_CharLabelNameLabel"], _G["LT_CharLabelZoneLabel"], _G["LT_CharLabelDateLabel"], _G["LT_CharLabelSpecLabel"]};
    LT_Char_HeadingText = {"Name", "Zone", "Date", "Spec"};
    
    for i = 1, #LT_Char_Headings do
        LT_Char_Headings[i]:SetText(LT_Char_HeadingText[i]);
    end
    
    _G["LT_Char_ScrollFrame"] = CreateFrame("ScrollFrame", "LT_Char_ScrollFrame", LT_LootListPanel, "FauxScrollFrameTemplate");
    local scroll_frame = _G["LT_Char_ScrollFrame"];
    scroll_frame:SetWidth(LT_LootListPanel:GetWidth() - 10)
    scroll_frame:SetHeight(LT_LootListPanel:GetHeight())
    scroll_frame:ClearAllPoints();
    scroll_frame:SetPoint("CENTER", LT_LootListPanel, "CENTER", 0, 0);
    
    LT_Char_NumEntriesShown = floor(LT_LootListPanel:GetHeight() / LT_Char_EntrySpread);
    for j=1, #LT_Char_Headings do 
        local heading_text = LT_Char_HeadingText[j];
        local heading = LT_Char_Headings[j];
        for i=1, LT_Char_NumEntriesShown do
            local label_name = "LT_Char"..heading_text.."_"..i;
            _G[label_name] = CreateFrame("Button", label_name, scroll_frame);
            
            local label = _G[label_name];
            label:SetParent(scroll_frame);
            label:SetWidth(heading:GetWidth());
            label:SetHeight(LT_Char_EntryHeight);
            label:ClearAllPoints();
            local x = 0;
            local y = -(i)*LT_Char_EntrySpread;
            label:SetPoint("CENTER", heading, "CENTER", x, y);

            local font_string = label:CreateFontString("$parentText", "OVERLAY", "GameFontNormal");
            font_string:SetFont("Fonts\\FRIZQT__.TTF", 9);
            font_string:SetText("asdf"..i);
            font_string:SetTextColor(0.8, 1.0, 0.8);
            label:SetFontString(font_string);
        end
        scroll_frame:SetScript("OnVerticalScroll", function (this, offset)
            FauxScrollFrame_OnVerticalScroll(this, offset, LT_Char_EntrySpread, LT_Char_UpdateLootFrame);
        end);
    end
    
    -- Makes ESC work
    tinsert(UISpecialFrames, this:GetName());
end
