LT_AttendanceCheckList = {};
LT_FirstTic = false;
LT_NewRosterUpdate = false;

function LT_Attendance_SlashHandler(args)
    if (string.find(args, " ") == nil) then
		LT_Print("lt attendance reset");
		return;
	end
    local cmd = string.sub(args, string.find(args, " ")+1);
    if (cmd == "reset") then
        LT_ResetAttendance();
    end
end

function LT_GetAttendees()
    local count = 0;
    local guildCount = GetNumGuildMembers(true);
    for i = 1, guildCount do 
        local _, _, _, _, _, _, _, onote = GetGuildRosterInfo(i);
        if (string.find(onote, "1") ~= nil) or (string.find(onote, "2") ~= nil) then
            count = count + 1;
        end
    end
    return count;
end

function LT_AttendanceTic()
    LT_NewRosterUpdate = false;
    local counter = 0;
    local num_all_members = GetNumGuildMembers(true);

    for i=1, num_all_members do
        if (LT_NewRosterUpdate == true) then
            LT_Print("ERROR1 - Roster updated during attendance tick.  Cancelling attendance tick.");
            return nil;
        end
        LT_NewSingleMemberOnlineTic(i);
    end
    
    for i=1, num_all_members do
        if (LT_NewRosterUpdate == true) then
            LT_Print("ERROR2 - Roster updated during attendance tick.  Cancelling attendance tick.");
            return nil;
        end
        LT_NewSingleMemberOfflineTic(i);
    end
    
--    for i=1, num_all_members do
--        local name = LT_GetPlayerIndexFromName(i);
--        LT_Print("LT: ["..name.."]["..LT_GetPlayerInfoFromName(name,"onote").."]","yellow");
--    end
    
    for i=1, num_all_members do
        if (LT_NewRosterUpdate == true) then
            LT_Print("ERROR3 - Roster updated during attendance tick.  Cancelling attendance tick.");
            return nil;
        end
        local name = LT_GetPlayerIndexFromName(i);
        local onote = LT_GetPlayerInfoFromName(name,"onote")
        local sync = LT_GetPlayerInfoFromName(name,"sync")
        if (sync == true) then
            GuildRosterSetOfficerNote(i, onote);
            counter = counter+1;
        end
    end
    
    if (LT_FirstTic) then
        LT_FirstTic = false;
    end
    LT_Print("Synchronized "..counter.." officer notes.","yellow");
    GuildRoster();
end

--Adjusts online member officer notes
function LT_NewSingleMemberOnlineTic(i)
        local name = LT_GetPlayerIndexFromName(i);
        local onlineValue = "1";
        if (name == nil) then
            LT_Print("Character not in guild, index: "..i);
            --Character not in guild
            return;
        end
        
        --Attendance for this player has aleady been done.
        --LT_Print(i.." starting tick for name: "..name);
        if (LT_GetPlayerInfoFromName(name,"updated") == true) then
            return;
        end
        
        --Collect information from the last roster update
        local onote = LT_GetPlayerInfoFromName(name,"onote");
        local rank = LT_GetPlayerInfoFromName(name,"rank");
        local online = LT_GetPlayerInfoFromName(name,"online");
        
        if (rank == "Friend") and (onote ~= "Friend") then
            LT_SetPlayerInfoFromName(name,"onote","Friend");
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        elseif (rank == "Friend") then
            return;
        end
        
        --If they are online
        if (online ~= nil) then
            if (rank == "Alt") or (rank == "Officer Alt") then
                --If they have a looping officer note, don't cause a recursive loop.
                if (name == onote) or (LT_GetPlayerInfoFromName(onote,"rank") == "Alt") or (LT_GetPlayerInfoFromName(onote,"rank") == "Officer Alt")  or (LT_GetPlayerInfoFromName(onote,"rank") == "-1") then
                    LT_SetPlayerInfoFromName(name,"onote","<Enter Main Name>");
                    LT_SetPlayerInfoFromName(name,"updated",true);
                    LT_SetPlayerInfoFromName(name,"sync",true);
                    return;
                end
                LT_NewSingleMemberOnlineTic(LT_GetPlayerIndexFromName(onote));
                LT_SetPlayerInfoFromName(name,"updated",true);
                LT_SetPlayerInfoFromName(name,"sync",false);
                return;
            end

            local raidCount = GetNumRaidMembers();
            --I am not in the raid, default to online-inraid
            if (raidCount == 0) then
                onlineValue = "1";
            else
                --I am in the raid
                local subGroup = LT_Attendance_Raid_Group(name, raidCount);
                if (subGroup < 6) and (subGroup > 0) then
                    --They are in the raid and online
                    onlineValue = "1";
                else
                    --They are online but not in the first 5 raid groups (sitting).
                    onlineValue = "2";
                end
            end
        else
            --Otherwise we do not want to deal with offline members until online have completed.
            return;
        end 
        
        if (LT_FirstTic) then
            LT_SetPlayerInfoFromName(name,"onote",onlineValue);
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        else
            LT_SetPlayerInfoFromName(name,"onote",onote..onlineValue);
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        end
        LT_Print(name.." failed all attendance checks for onlineTic.  Logic error, please review code.");
end

----Adjusts offline member officer notes
function LT_NewSingleMemberOfflineTic(i)
        local name = LT_GetPlayerIndexFromName(i);
        local onlineValue = "0";
        if (name == nil) then
            LT_Print("Character not in guild, index: "..i);
            --Character not in guild
            return;
        end
        
        --Attendance for this player has aleady been done.
        if (LT_GetPlayerInfoFromName(name,"updated") == true) then
            return;
        end
        
        --Collect information from the last roster update
        local onote = LT_GetPlayerInfoFromName(name,"onote");
        local rank = LT_GetPlayerInfoFromName(name,"rank");
        local online = LT_GetPlayerInfoFromName(name,"online");
        
        if (rank == "Friend") and (onote ~= "Friend") then
            LT_SetPlayerInfoFromName(name,"onote","Friend");
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        elseif (rank == "Friend") then
            return;
        end
        
        --If they are not online
        if (online == nil) then
            if (rank == "Alt") or (rank == "Officer Alt") then
                --If they have a looping officer note, don't cause a recursive loop.
                if (name == onote) or (LT_GetPlayerInfoFromName(onote,"rank") == "Alt") or (LT_GetPlayerInfoFromName(onote,"rank") == "Officer Alt") or (LT_GetPlayerInfoFromName(onote,"rank") == "-1") then
                    LT_SetPlayerInfoFromName(name,"onote","<Enter Main Name>");
                    LT_SetPlayerInfoFromName(name,"updated",true);
                    LT_SetPlayerInfoFromName(name,"sync",true);
                    return;
                end
                LT_NewSingleMemberOfflineTic(LT_GetPlayerIndexFromName(onote));
                LT_SetPlayerInfoFromName(name,"updated",true);
                LT_SetPlayerInfoFromName(name,"sync",false);
                return;
            end
            
            onlineValue = "0";
        else
            --We already dealt with online characters, we should never hit this.
            LT_Print("Logic error, found an online person that has not had attendance updated in offlineTic. Name: "..name.." onote: "..onote);
            return;
        end 
        
        if (LT_FirstTic) then
            LT_SetPlayerInfoFromName(name,"onote",onlineValue);
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        else
            LT_SetPlayerInfoFromName(name,"onote",onote..onlineValue);
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        end
        LT_Print(name.." failed all attendance checks for offlineTic.  Logic error, please review code.");
end

--function LT_OldAttendanceTic()
--    LT_SummaryPanel:Hide();
--    SetGuildRosterShowOffline(false);
--    --Do online first
--    local guildCount = GetNumGuildMembers(false);
--    for i = 1, guildCount do 
--        LT_SingleMemberTic(i);
--    end
--    
--    --Then do offline
--    local guildCount = GetNumGuildMembers(true);
--    for i = 1, guildCount do 
--        LT_SingleMemberTic(i);
--    end
--    LT_AttendanceCheckList = {};
--    LT_Print("Attendance updated for " ..guildCount.. " players.");
--    
--    --Consider removing next line to fix performance of having
--    --the window open during a tick during raid.
--    LT_Attendance_OnChange();
--    if (LT_FirstTic) then
--        LT_FirstTic = false;
--    end
--    LT_SummaryPanel:Show();
--end

function LT_AttendanceResetButton()
    StaticPopupDialogs["Reset Attendance"] = {
    text = "LegionTracker: RESET ATTENDANCE?\nAre you sure, this process can not be reversed.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        LT_ResetAttendance();
    end,
    timeout = 5,
    whileDead = 1,
    hideOnEscape = 1
    };
    
    StaticPopup_Show("Reset Attendance");
end

function LT_ResetAttendance()
    local count = 0;
    guildCount = GetNumGuildMembers(true);
    for i = 1, guildCount do 
        --temp = GetGuildRosterSelection();
        _, rank, _, _, _, _, _, onote = GetGuildRosterInfo(i);
        if (rank == "Alt") or (rank == "Officer Alt") then
            local pname = LT_GetPlayerIndexFromName(onote);
            if (pname == nil) then
                GuildRosterSetOfficerNote(i, "<Enter Main Name>");
            end
            count = count+1;
        elseif (rank == "Friend") and (onote ~= "Friend") then
            GuildRosterSetOfficerNote(i, "Friend");
            count = count+1;
        elseif (rank == "Friend") then
            count = count+1;
        else
            GuildRosterSetOfficerNote(i, "");
            count = count+1;
        end
    end
    LT_Print("Attendance reset for " ..count.. " players.");
end

----Remove hard coded friend rank
--function LT_SingleMemberTic(memberIndex,ticfromalt,altName)
--    local name, rank, _, _, _, _, _, onote, online = GetGuildRosterInfo(memberIndex);
--    if (rank == "Friend") and (onote ~= "Friend") then
--        GuildRosterSetOfficerNote(memberIndex,"Friend"); 
--    elseif (rank == "Friend") then
--            return;
--    elseif (rank == "Alt") or (rank == "Officer Alt") then
--        if (name == onote) then
--            LT_Print(name.." has a looping officer note.  Fix immediately.","yellow");
--            return;
--        end
--        if (online ~= nil) or (ticfromalt ~= nil) then
--            local pname = LT_GetPlayerIndexFromName(onote);
--            if (pname ~= nil) then
--                LT_SingleMemberTic(pname,true,name);
--            end
--        else
--            return;
--        end
--    else
--        if (ticfromalt) then
--            online = "yes";
--        end
--        if (online == nil) then
--            --DEFAULT_CHAT_FRAME:AddMessage("DEBUG1: " ..name.." is Offline.");
--            if ( LT_AttendanceCheckList[name] == nil ) then
--                if (LT_FirstTic) then
--                    GuildRosterSetOfficerNote(memberIndex, "0");
--                else
--                    GuildRosterSetOfficerNote(memberIndex, onote.."0");
--                end
--                LT_AttendanceCheckList[name] = 1;
--            end
--        else
--            --DEFAULT_CHAT_FRAME:AddMessage("DEBUG1: " ..name.." is Online ");
--            if ( LT_AttendanceCheckList[name] == nil ) then
--                local onlineValue = "1";
--                --Adding code for people sitting out.
--                --onlineValue 1 - Online in raid, 2 - Online, sitting out.
--                local raidGroup;
--                local raidCount = GetNumRaidMembers();
--                local tempName;
--                if (raidCount ~= 0) then --If you are in the raid.
--                    if (ticfromalt) then
--                        if (UnitInRaid(altName)) then
--                            tempName = altName;
--                        elseif (UnitInRaid(name)) then
--                            tempName = name;
--                        else
--                            tempName = altName;
--                        end
--                    else
--                        tempName = name;
--                    end
--                    if (UnitInRaid(tempName)) then --If they are in the raid
--                        raidGroup = LT_Attendance_Raid_Group(tempName, raidCount);
--                        if (raidGroup < 6) and (raidGroup > 0) then
--                            onlineValue = "1"; --Group 1-5
--                        elseif (raidGroup == "-1") then
--                            --Errored, but we dont want to stop attendance recording.
--                            onlineValue = "1";
--                        else
--                            --LT_Print(tempName.." 1");
--                            onlineValue = "2";
--                        end
--                    else
--                        --Online, but not in raid
--                        --LT_Print(tempName.." 2");
--                        onlineValue = "2";
--                    end                    
--                end
--                --End code for sitting out.
--                if (LT_FirstTic) then
--                    GuildRosterSetOfficerNote(memberIndex, onlineValue);
--                else
--                    GuildRosterSetOfficerNote(memberIndex, onote..onlineValue);
--                end
--                LT_AttendanceCheckList[name] = 1;
--            end
--        end
--    end
--end

--Used to return their percentage
--if the second arg is true, it will return benched percent
function LT_GetAttendance(playerIndex, bench)
    local counter = 0;
    --local name, rank, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
    local name = LT_GetPlayerIndexFromName(playerIndex);
    local rank = LT_GetPlayerInfoFromName(name,"rank");
    local onote = LT_GetPlayerInfoFromName(name,"onote");
    
    if (name == nil) then
        return playerIndex;
    end
    --If their onote is empty return nothing.
    if (rank == "Alt") or (rank == "Officer Alt") then
        if (name == onote) then
            return "";
        end
        local pname = LT_GetPlayerIndexFromName(onote);
        if (pname ~= nil) then
            if (bench) then
                return LT_GetAttendance(pname,true);
            else
                return LT_GetAttendance(pname);
            end
        end
    end
    
    if (onote == "") then
        return "";
    end
    
    local total = string.len(onote);
    
    --Test if the o-note is valid.  Just 1's and 0's.
    local test = string.find(onote, "%D");
    if (test ~= nil) then
        return "";
    end
    if (bench) then
        for w in string.gmatch(onote, "2") do
            counter = counter + 1;
        end
    else
        for w in string.gmatch(onote, "0") do
            counter = counter + 1;
        end
        counter = total - counter;
    end
    local percent = floor(counter * 100 / total);
    return percent;
end

--For export and drawing timelines
function LT_GetRawAttendance(playerIndex)
    --local _, rank, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
    local name = LT_GetPlayerIndexFromName(playerIndex);
    local onote = LT_GetPlayerInfoFromName(name,"onote");
    
    if (rank == "Alt") or (rank == "Officer Alt") then
        if (name == onote) then
            return "";
        end
        local pname = LT_GetPlayerIndexFromName(onote);
        if (pname ~= nil) then
            return LT_GetRawAttendance(pname);
        end
    end
    return onote;
end

function LT_Attendance_OnChange()
    LT_RedrawPlayerList();
    LT_Char_UpdateFrame();
end

function LT_Attendance_Raid_Group(playerName, raidCount)
    local rname, rsubgroup;
    for i = 1, raidCount do --What group?
        rname, _, rsubgroup = GetRaidRosterInfo(i);
        if (rname == playerName) or (playerName == LT_GetPlayerInfoFromName(rname,"onote")) or (rname == LT_GetPlayerInfoFromName(playerName,"onote")) then
            --LT_Print(playerName.." is in group: "..rsubgroup);
            return rsubgroup;
        end
    end
    --LT_Print(playerName.."- LT_Error, not in raid?");
    return "-1";
end