function LT_Credits_OnLoad(self)
    LT_Credits:SetParent(UIParent);
    tinsert(UISpecialFrames, self:GetName());
    self:RegisterEvent("VARIABLES_LOADED");
    self:Hide();
end

function LT_Credits_Fill()
    LT_Credits:SetFrameLevel(100);
    local credit_label = _G["LT_Credits".."CreditsLabel".."Edit"];
    credit_label:SetTextColor(1, .75, 0);
    credit_label:SetText("");
    credit_label:Insert("Original Developers:\n");
    credit_label:Insert("Malaaq <Trismegistus> Medivh-US\n");
    credit_label:Insert("Happyduude <Trismegistus> Medivh-US\n");
    credit_label:Insert("\n");
    credit_label:Insert("Graphics:\n");
    credit_label:Insert("Threelibra <Trismegistus> Medivh-US\n");
    credit_label:Insert("\n");
    credit_label:Insert("Pre-Release Users/Testing:\n");
    credit_label:Insert("Yuzuki <Trismegistus> Medivh-US\n");
    credit_label:Insert("Nobunaga <Trismegistus> Medivh-US\n");
    credit_label:Insert("Happyduude <Trismegistus> Medivh-US\n");
    credit_label:Insert("Malaaq <Trismegistus> Medivh-US\n");
    credit_label:Insert("Littletoe <Trismegistus> Medivh-US\n");
    credit_label:Insert("Sindaga <Trismegistus> Medivh-US\n");
    credit_label:Insert("Vaulk <Trismegistus> Medivh-US\n");
    credit_label:Insert("Soulzar <Trismegistus> Medivh-US\n");
    credit_label:Insert("\n");
    credit_label:Insert("First External Guild Beta Test:\n");
    credit_label:Insert("Guinea <Providence> Sen'Jin-US\n");
    credit_label:Insert("Epicthread <Providence> Sen'Jin-US\n");
    credit_label:Insert("Selaniene <Providence> Sen'Jin-US\n");
    credit_label:Insert("Aristei <Providence> Sen'Jin-US\n");
    credit_label:Insert("Bragas <Providence> Sen'Jin-US\n");
    credit_label:Insert("\n");
    credit_label:Insert("Special Thanks:\n");
    credit_label:Insert("Thanks to the members and officers of Trismegistus \n");
    credit_label:Insert("for all of your suggestions and interest in this project.\n");
end

function LT_Credits_OnEvent(self, event, ...)
    if (event == "VARIABLES_LOADED") then
        --LT_Credits_Fill();
    end
end