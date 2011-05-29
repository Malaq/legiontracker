LT_AttendanceCheckList = {};
LT_FirstTic = false;
LT_NewRosterUpdate = false;
LT_Ticks = {};
LT_Attendance = {};

function LT_Attendance_SlashHandler(args)
    if (string.find(args, " ") == nil) then
		LT_Print("lt attendance reset","yellow");
        LT_Print("lt attendance check","yellow");
        LT_Print("lt attendance raiders","yellow");
		return;
	end
    local cmd = string.sub(args, string.find(args, " ")+1);
    if (cmd == "reset") then
        LT_ResetAttendance();
    elseif (cmd == "check") then
        LT_CheckForUnevenTicks();
    elseif (cmd == "raiders") then
        LT_GetNumRaiders(true);
    end
end

--This is called when the timer is stopped to ensure all ticks from
--the localized table get applied to officer notes before export.
function LT_ApplyAttendance()
    local counter = 0;
    local LT_Attendance_bak = {};
    LT_Attendance_bak = LT_Attendance;
    for k,v in pairs(LT_Attendance_bak) do
        local attendance = LT_Attendance_bak[k];
        local guildId = LT_GetPlayerIndexFromName(k);
        if (guildId ~= nil) then
            LT_SetPlayerInfoFromName(k,"onote",attendance);
            LT_SetPlayerInfoFromName(k,"attendance",attendance);
            GuildRosterSetOfficerNote(guildId, attendance);
            counter = counter+1;
        end
    end
    return counter;
end

--function LT_SimpleAttendanceTic()
function LT_AttendanceTic()   
    LT_NewRosterUpdate = false;
    LT_Ticks = {};
    local counter = 0;
    
    --SetGuildRosterShowOffline(true);
    local num_all_members,num_online_members = GetNumGuildMembers();
    LT_Print("Online guildmates: "..num_online_members.."/"..num_all_members,"yellow");
    
    for i=1, num_all_members do
        if (LT_NewRosterUpdate == true) then
            LT_Print("ERROR1 - Roster updated during attendance tick.  Restarting attendance tick.");
            LT_AttendanceTic();
            return nil;
        end
        LT_SingleMemberTic(i);
    end
    
    local raidCount = GetNumRaidMembers();
    --I am not in the raid, skip raid tick.
    if (raidCount ~= 0) then
        LT_RaiderTick();
    end
    
    --Apply ticks to attendance and officer notes
    for k,v in pairs(LT_Ticks) do
        local attendance = "";
        local guildId = LT_Ticks[k]["id"];
        if (LT_FirstTic) then
            attendance = LT_Ticks[k]["tick"];
        else
            --LT_Print("onote: "..LT_GetPlayerInfoFromName(k,"onote"));
            --LT_Print("tick:"..LT_Ticks[k]["tick"]);
            
            --why would you do this...seriously? After redesigning attendance you
            --leave in this gaping hole.  Corrected it to use the localized table
            --instead of onotes.
            --attendance = LT_GetPlayerInfoFromName(k,"onote")..LT_Ticks[k]["tick"];
            attendance = LT_GetPlayerInfoFromName(k,"attendance")..LT_Ticks[k]["tick"];
        end
        --LT_Print(k.." id: "..guildId.." setting attendance: "..attendance);
        LT_SetPlayerInfoFromName(k,"onote",attendance);
        LT_SetPlayerInfoFromName(k,"attendance",attendance);
        GuildRosterSetOfficerNote(guildId, attendance);
        --LT_Print("k: "..k.." tick: "..LT_Ticks[k]["tick"]);
        counter = counter+1;
    end
    
    local raiders = LT_GetNumRaiders();
    LT_Print("LT: Set attendance for "..counter.." raiders.","yellow");
    LT_Print("LT: Attendance should have been set for "..raiders.." raiders.","yellow");
    if (raiders ~= counter) then
        LT_Print("LT: WARNING WARNING WARNING, ticks do not match raiders.","red");
    end
    LT_FirstTic = false;
    GuildRoster();
end

--New attendance ticker for simpletick
function LT_SingleMemberTic(guildId, tickFromAlt, altName, tickFromRaid)
    --If you're not in the raid, just count everyone as online.
    local raidCount = GetNumRaidMembers();
    local onlineValue = "2";
    if (raidCount == 0) then
        onlineValue = "1";
    end
    
    local name, rank, rankIndex, level, class, zone, note, officernote, online, status, classFileName, achievementPoints, achievementRank, isMobile = GetGuildRosterInfo(guildId);
    if (isMobile) then
        LT_Print("Player: "..name..", isMobile.","yellow");
    end
    if (rank == "Alt") or (rank == "Officer Alt") then
        local mainRank = LT_GetPlayerInfoFromName(officernote,"rank");
        local mainId = LT_GetPlayerInfoFromName(officernote,"index");
        
        if (tickFromAlt ~= nil) or (mainRank == "-1") then
            --No longer allowing alt names to go multiple levels deep.  Too many possibilities for deadlock.
            if (altName == nil) then
                altName = name;
            end
            LT_Print("Please fix "..altName.."'s officer note.","red");
            return nil;
        end
        --Recursively run the function but stop this instance once the tick has occurred.
        if ((online == 1) and (not isMobile)) then
            --LT_Print("Giving "..officernote.." a tick from alt "..name);
            LT_SingleMemberTic(mainId, true, name, tickFromRaid);
            return nil;
        else
            --If the alt is offline, we'll set the attendance elsewhere.
            return nil;
        end
    end
    
    if (rank == "Friend") then
        if (officernote ~= "Friend") then
            GuildRosterSetOfficerNote(guildId, "Friend");
        end
        return nil;
    end
    
    if (rank ~= "Alt") and (rank ~= "Officer Alt") and (rank ~= "Friend") then 
        --Give a online sitting out tick, we will overwrite these ticks with raider ticks later
        --LT_Print("Test: "..name.." guildid: "..guildId);
        if (LT_Ticks[name] == nil) then
            LT_Ticks[name] = {};
        end
        LT_Ticks[name]["id"] = guildId;
        if ((online == 1) and (not isMobile)) or (tickFromAlt ~= nil) then
            --Online
            if (tickFromRaid ~= nil) then
                LT_Ticks[name]["tick"] = "1";
            else
                LT_Ticks[name]["tick"] = onlineValue;
            end
        else
            --Offline
            --Don't overwrite a online tick with offline tick.
            --this doesn't seem to work
            local temptick = LT_Ticks[name]["tick"] or "test";
            
            if (temptick == "1") or (temptick == "2") then
                --LT_Print("Not changing tick for: "..name);
                return nil;
            else
                LT_Ticks[name]["tick"] = "0";
            end
        end
        
        return nil;
        --LT_SetPlayerInfoFromName(name,"onote","Friend");
    else
        LT_Print("Error with player "..name..".  Did not pass the alt and friend validation.  Please review.");
        return nil;
    end
    LT_Print("Attendance error, player: "..name.." failed all validation.  Please review.");
end

function LT_RaiderTick()
    local raidCount = GetNumRaidMembers();
    for i=1, raidCount do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
        local guildId = LT_GetPlayerInfoFromName(name,"index");
        if (guildId ~= "-1") and (subgroup < 6) and (subgroup > 0) then
            LT_SingleMemberTic(guildId, nil, nil, true);
        end        
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

function LT_AttendanceTicold()   
    LT_NewRosterUpdate = false;
    local counter = 0;
    SetGuildRosterShowOffline(false);
    local num_all_members,num_online_members = GetNumGuildMembers(false);
    
    LT_Print("Online members: "..num_online_members,"yellow");

    for i=1, num_online_members do
        if (LT_NewRosterUpdate == true) then
            LT_Print("ERROR1 - Roster updated during attendance tick.  Restarting attendance tick.");
            LT_AttendanceTic();
            return nil;
        end
        LT_NewSingleMemberOnlineTic(i);
    end
    
    --num_all_members = GetNumGuildMembers(true);
    
    LT_Print("All members: "..num_all_members,"yellow");
    
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
        local attendance = LT_GetPlayerInfoFromName(name,"attendance")
        local sync = LT_GetPlayerInfoFromName(name,"sync")
        if (sync == true) then
            GuildRosterSetOfficerNote(i, attendance);
            counter = counter+1;
        end
    end
    
    if (LT_FirstTic) then
        LT_FirstTic = false;
    end
    LT_Print("Synchronized "..counter.." officer notes.","yellow");
    --LT_CheckForUnevenTicks();
    GuildRoster();
end

--Adjusts online member officer notes
function LT_NewSingleMemberOnlineTic(i,tickFromAlt,altName)
        local name = LT_GetPlayerIndexFromName(i);
        --if (tickFromAlt == nil) then
        --    tickFromAlt = false;
        --end

        if (name == nil) or (name == "") then
            LT_Print("Please fix "..altName.."'s officer note.");
            return;
        end
        
        local onlineValue = "1"; 
        if (name == nil) or (name == "") then
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
        if (tickFromAlt ~= nil) then
            if (tickFromAlt == true) then
                online = 1;
            else
                online = nil;
            end
        end
        
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
                    LT_Print("Please fix "..name.."'s officer note.");
                    LT_SetPlayerInfoFromName(name,"onote","<Enter Main Name>");
                    LT_SetPlayerInfoFromName(name,"updated",true);
                    LT_SetPlayerInfoFromName(name,"sync",true);
                    return;
                end
                LT_NewSingleMemberOnlineTic(LT_GetPlayerIndexFromName(onote),true,name);
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
                if (tickFromAlt ~= nil) then
                    if (tickFromAlt == true) then
                        subGroup = LT_Attendance_Raid_Group(altName, raidCount);
                    end
                    subGroup = LT_Attendance_Raid_Group(name, raidCount);
                end
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
            if (tickFromAlt ~= nil) then
                LT_Print(name.." was not dealt with because it was assumed they were offline.","yellow");
            end
            return;
        end 
        
        if (LT_FirstTic) or (onote == nil) or (onote == "") then
            LT_SetPlayerInfoFromName(name,"onote",onlineValue);
            LT_SetPlayerInfoFromName(name,"attendance",onlineValue);
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        else
            LT_SetPlayerInfoFromName(name,"onote",onote..onlineValue);
            local attendance = LT_GetPlayerInfoFromName(name,"attendance");
            LT_SetPlayerInfoFromName(name,"attendance",attendance..onlineValue);
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
        if (name == nil) or (name == "") then
            LT_Print("Character not in guild, index: "..i,"yellow");
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
                    LT_Print("Please fix "..name.."'s officer note.");
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
            LT_Print("Logic error, found an online person that has not had attendance updated in offlineTic. Name: "..name.." onote: "..onote,"yellow");
            return;
        end 
        
        if (LT_FirstTic) or (onote == nil) or (onote == "") then
            LT_SetPlayerInfoFromName(name,"onote",onlineValue);
            LT_SetPlayerInfoFromName(name,"attendance",onlineValue);
            LT_SetPlayerInfoFromName(name,"updated",true);
            LT_SetPlayerInfoFromName(name,"sync",true);
            return;
        else
            LT_SetPlayerInfoFromName(name,"onote",onote..onlineValue);
            local attendance = LT_GetPlayerInfoFromName(name,"attendance");
            LT_SetPlayerInfoFromName(name,"attendance",attendance..onlineValue);
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
        local name, rank, _, _, _, _, _, onote = GetGuildRosterInfo(i);
        if (rank == "Alt") or (rank == "Officer Alt") then
            local pname = LT_GetPlayerIndexFromName(onote);
            if (pname == nil) then
                LT_SetPlayerInfoFromName(name,"onote","<Enter Main Name>");
                GuildRosterSetOfficerNote(i, "<Enter Main Name>");
            end
            count = count+1;
        elseif (rank == "Friend") and (onote ~= "Friend") then
            LT_SetPlayerInfoFromName(name,"onote","Friend");
            GuildRosterSetOfficerNote(i, "Friend");
            count = count+1;
        elseif (rank == "Friend") then
            count = count+1;
        else
            GuildRosterSetOfficerNote(i, "");
            count = count+1;
        end
    end
    LT_Attendance = {};
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
    local attendance = LT_GetPlayerInfoFromName(name,"attendance");
    
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
    
    --if (onote == "") or (onote == nil) then
    if (attendance == "") or (attendance == nil) then
        return "";
    end
    
    local total = string.len(attendance);
    
    --Test if the o-note is valid.  Just 1's and 0's.
    local test = string.find(attendance, "%D");
    if (test ~= nil) then
        return "";
    end
    if (bench) then
        for w in string.gmatch(attendance, "2") do
            counter = counter + 1;
        end
    else
        for w in string.gmatch(attendance, "0") do
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
    local attendance = LT_GetPlayerInfoFromName(name,"attendance");
    
    if (rank == "Alt") or (rank == "Officer Alt") then
        if (name == onote) then
            return "";
        end
        local pname = LT_GetPlayerIndexFromName(onote);
        if (pname ~= nil) then
            return LT_GetRawAttendance(pname);
        end
    end
    if (attendance == "") or (attendance == nil) then
        return "";
    else
        return attendance;
    end
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
    return -1;
end