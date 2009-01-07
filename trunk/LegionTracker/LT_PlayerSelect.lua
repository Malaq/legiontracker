

LT_PlayerSelect = {};

function LT_PlayerSelect:Show(player_name, loot_id)
    LT_PlayerSelectForm:SetParent(LT_LootUI.st.frame);
    LT_PlayerSelectForm:Show();
    LT_PlayerSelectText:SetText(player_name);
    LT_PlayerSelectForm:SetFrameLevel(200);
    LT_PlayerSelectText:SetFocus();
    LT_PlayerSelectText:HighlightText();
    self.loot_id = loot_id;
end

function LT_PlayerSelect:OnLoad()
    LT_PlayerSelectForm:SetParent(UIParent);
    LT_PlayerSelectForm:Hide();
    tinsert(UISpecialFrames, this:GetName());
    LT_PlayerSelectForm:SetFrameLevel(200);
end

function LT_PlayerSelect:Enter()
    -- Only make the change if the new name is a valid guildy.
    if (LT_NameLookup[LT_PlayerSelectText:GetText()]) then
        LT_Loot_ChangeOwner(self.loot_id, LT_PlayerSelectText:GetText());
        LT_PlayerSelectForm:Hide();
    end
end

function LT_PlayerSelect:Escape()
    LT_PlayerSelectForm:Hide();
end