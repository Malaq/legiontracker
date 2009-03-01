function LT_Settings_VersionCheck()
    SendChatMessage("Running version check...", "OFFICER");
    local cmd = {type = "VersionCheck"};
    LT_OfficerLoot:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd));
    cmd = {type = "VersionResponse", version = LT_VERSION, player = UnitName("player")};
    self:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd));
end