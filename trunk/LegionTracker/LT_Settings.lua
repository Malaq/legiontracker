function LT_Settings_VersionCheck()
    --SendChatMessage("Running version check...", "OFFICER");
    LT_Print("LegionTracker: Running version check...", "yellow");
    LT_Print(UnitName("player").. ": " ..LT_VERSION);
    local cmd = {type = "VersionCheck", player = UnitName("player")};
    LT_OfficerLoot:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd));
    cmd = {type = "VersionResponse", version = LT_VERSION, player = UnitName("player")};
    LT_OfficerLoot:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd));
end