LT_AllLoot = {};

function LT_AllLoot:ToggleShow()
    if (LT_AllLootPanel:IsShown()) then
        LT_AllLootPanel:Hide();
    else
		if (LT_Char:IsShown()) then
			LT_Char_ShowPlayer(LT_Char_CurPlayer); -- toggles it off
		end
        LT_LootUI:SetParent(LT_AllLootTable);
        LT_LootUI:UpdateFrame();
        LT_AllLootPanel:Show();
    end
end

function LT_AllLoot:OnShow()
    
end

function LT_AllLoot:OnLoad()
    LT_AllLootPanel:Hide();
	LT_AllLootPanel:SetParent(UIParent);
    tinsert(UISpecialFrames, this:GetName());
    LT_AllLootPanel:SetFrameLevel(100);
	LT_LootUI:SetupFrame(LT_AllLootTable);
end
