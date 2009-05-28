LT_AttendanceCheckList = {};
LT_FirstTic = false;

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
        if (string.find(onote, "1") ~= nil) and (string.find(onote, "2") ~= nil) then
            count = count + 1;
        end
    end
    return count;
end

function LT_AttendanceTic()
    SetGuildRosterShowOffline(false);
    --Do online first
    local guildCount = GetNumGuildMembers(false);
    for i = 1, guildCount do 
        LT_SingleMemberTic(i);
    end
    
    --Then do offline
    local guildCount = GetNumGuildMembers(true);
    for i = 1, guildCount do 
        LT_SingleMemberTic(i);
    end
    LT_AttendanceCheckList = {};
    LT_Print("Attendance updated for " ..guildCount.. " players.");
    LT_Attendance_OnChange();
    if (LT_FirstTic) then
        LT_FirstTic = false;
    end
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

--Remove hard coded friend rank
function LT_SingleMemberTic(memberIndex,ticfromalt)
    local name, rank, _, _, _, _, _, onote, online = GetGuildRosterInfo(memberIndex);
    if (rank == "Friend") and (onote ~= "Friend") then
        GuildRosterSetOfficerNote(memberIndex,"Friend"); 
    elseif (rank == "Friend") then
            return;
    elseif (rank == "Alt") or (rank == "Officer Alt") then
        if (online ~= nil) or (ticfromalt ~= nil) then
            local pname = LT_GetPlayerIndexFromName(onote);
            if (pname ~= nil) then
                LT_SingleMemberTic(pname,true);
            end
        else
            return;
        end
    else
        if (ticfromalt) then
            online = "yes";
        end
        if (online == nil) then
            --DEFAULT_CHAT_FRAME:AddMessage("DEBUG1: " ..name.." is Offline.");
            if ( LT_AttendanceCheckList[name] == nil ) then
                if (LT_FirstTic) then
                    GuildRosterSetOfficerNote(memberIndex, "0");
                else
                    GuildRosterSetOfficerNote(memberIndex, onote.."0");
                end
                LT_AttendanceCheckList[name] = 1;
            end
        else
            --DEFAULT_CHAT_FRAME:AddMessage("DEBUG1: " ..name.." is Online ");
            if ( LT_AttendanceCheckList[name] == nil ) then
                local onlineValue = "1";
                --Adding code for people sitting out.
                --onlineValue 1 - Online in raid, 2 - Online, sitting out.
                local raidGroup;
                local raidCount = GetNumRaidMembers();
                if (raidCount ~= 0) then --If you are in the raid.
                    if (UnitInRaid(name)) then --If they are in the raid
                        raidGroup = LT_Attendance_Raid_Group(name, raidCount);
                        if (raidGroup < 6) and (raidGroup > 0) then
                            onlineValue = "1"; --Group 1-5
                        elseif (raidGroup == "-1") then
                            --Errored, but we dont want to stop attendance recording.
                            onlineValue = "1";
                        else
                            onlineValue = "2";
                        end
                    else
                        --Online, but not in raid
                        onlineValue = "2";
                    end                    
                end
                --End code for sitting out.
                if (LT_FirstTic) then
                    GuildRosterSetOfficerNote(memberIndex, onlineValue);
                else
                    GuildRosterSetOfficerNote(memberIndex, onote..onlineValue);
                end
                LT_AttendanceCheckList[name] = 1;
            end
        end
    end
end

--Used to return their percentage
--if the second arg is true, it will return benched percent
function LT_GetAttendance(playerIndex, bench)
    local counter = 0;
    local name, rank, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
    if (name == nil) then
        return playerIndex;
    end
    --If their onote is empty return nothing.
    if (rank == "Alt") or (rank == "Officer Alt") then
        local pname = LT_GetPlayerIndexFromName(onote);
        if (pname ~= nil) then
            return LT_GetAttendance(pname);
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
    local _, rank, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
    if (rank == "Alt") or (rank == "Officer Alt") then
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
        if (rname == playerName) then
            --LT_Print(playerName.." is in group: "..rsubgroup);
            return rsubgroup;
        end
    end
    LT_Print(playerName.."- LT_Error, not in raid?");
    return "-1";
end