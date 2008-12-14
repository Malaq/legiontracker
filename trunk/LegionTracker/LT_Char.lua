﻿LT_Char_CurPlayer = nil;
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
    LT_Char:Show();
    
    LT_Char_UpdateLootFrame();
end

LT_Char_NumEntriesShown = 0;
LT_Char_EntryHeight = 15;
LT_Char_EntrySpread = 15;
LT_Char_NumEntries = 200;
LT_Char_Loots = nil;
function LT_Char_UpdateLootFrame()
    local scroll_frame = _G["LT_Char_ScrollFrame"];
    if (scroll_frame == nil) then
        return;
    end
    LT_Char_Loots = LT_Loot_GetLoots(LT_Char_CurPlayer);
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
            zone_label:SetText(LT_Char_Loots[id].zone);
            
            local date_label = _G["LT_CharDate_"..i];
            date_label:SetText("...");
            
            local spec_label = _G["LT_CharSpec_"..i];
            spec_label:SetText(LT_Char_Loots[id].spec);
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
end