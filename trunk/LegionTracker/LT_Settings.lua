function LT_Settings_OnLoad(self)
    LT_Credits:SetParent(UIParent);
    tinsert(UISpecialFrames, self:GetName());
    self:RegisterEvent("VARIABLES_LOADED");
    self:Hide();
end

function LT_Settings_OnEvent(self, event, arg1, arg2)
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

function LT_Settings_Table_Request(args)
    if (string.find(args, " ") == nil) then
		LT_Print("tablecopy <playername>");
		return
	end
    
    local targetPlayer = string.sub(args, string.find(args, " ")+1);
    if (targetPlayer ~= nil) then
        if (string.lower(targetPlayer) == string.lower(UnitName("player"))) then
            LT_Print("You can not request a table copy from yourself!","red");
            return;
        end
        LT_Print("Table request: "..targetPlayer,"yellow");
        LT_OfficerLoot.msg_channel = "WHISPER";
        LT_OfficerLoot.msg_target = targetPlayer;
        local cmd = {type = "TableRequest", player = UnitName("player"), target = targetPlayer};
        LT_OfficerLoot:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd),nil);
        LT_OfficerLoot.msg_channel = "RAID";
        LT_OfficerLoot.msg_target = nil;
    end
end

function LT_Settings_Table_Undo()
    if (LT_LootTable_backup ~= nil and LT_PlayerLootTable_backup ~= nil) then
        LT_Print("Restoring old table data.","yellow");
        LT_LootTable = LT_LootTable_backup;
        LT_PlayerLootTable = LT_PlayerLootTable_backup;
        LT_Print("Restore complete.","yellow");
    else
        LT_Print("LT: No data available to restore.  Command failed.","red");
    end
end

function LT_OfflineCheckBoxClicked()
    if (LT_MainOfflineCheckBox:GetChecked() == 1) then
        --SetGuildRosterShowOffline(true);
        LT_offlineFilter = false;
        LT_UpdatePlayerList();
    else
        --SetGuildRosterShowOffline(false);
        LT_offlineFilter = true;
        LT_UpdatePlayerList();
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

function LT_Settings_Minimap_SlashHandler(args)
    if (string.find(args, " ") == nil) then
        --LT_Print(LT_Show_Minimap_Icon,"yellow");
        if (LT_Show_Minimap_Icon == true) then
		    LT_Print("LT: Show minimap is currently toggled to: TRUE","yellow");
        elseif (LT_Show_Minimap_Icon == false) then
            LT_Print("LT: Show minimap is currently toggled to: FALSE","yellow");
        else
            LT_Print("LT: Show minimap is currently: NOT SET","yellow");
		end
        return;
	end
    
    local cmd = string.sub(args, string.find(args, " ")+1);
    if (cmd == "hide") then
        LT_LDBIcon:Hide("LT_LDB");
        --LT_Show_Minimap_Icon = false;
    elseif (cmd == "show") then
        LT_LDBIcon:Show("LT_LDB");
        --LT_Show_Minimap_Icon = true;
    end
end