function LT_Settings_OnLoad()
    LT_Credits:SetParent(UIParent);
    tinsert(UISpecialFrames, this:GetName());
    this:RegisterEvent("VARIABLES_LOADED");
    this:Hide();
end

function LT_Settings_OnEvent(this, event, arg1, arg2)
    if (event == "VARIABLES_LOADED") then
        LT_Settings:SetFrameLevel(100);
    end
end
    

function LT_Settings_VersionCheck()
    --SendChatMessage("Running version check...", "OFFICER");
    --LT_Print("LegionTracker: Running version check...", "yellow");
    --LT_Print(UnitName("player").. ": " ..LT_VERSION);
    LT_Print("LegionTracker: Running version check...", "yellow");
    local cmd = {type = "VersionCheck", player = UnitName("player")};
    LT_OfficerLoot:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd), "GUILD");
    --cmd = {type = "VersionResponse", version = LT_VERSION, player = UnitName("player")};
    --LT_OfficerLoot:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd));
end

function LT_OfflineCheckBoxClicked()
    if (LT_MainOfflineCheckBox:GetChecked() == 1) then
        SetGuildRosterShowOffline(true);
    else
        SetGuildRosterShowOffline(false);
    end
end

function LT_RaidersCheckboxClicked()
    if (LT_MainRaidersCheckbox:GetChecked() == 1) then
        LT_raiderFilter = true;
        LT_UpdatePlayerList();
    else
        LT_raiderFilter = false;
        LT_UpdatePlayerList();
    end
end