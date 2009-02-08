LT_AttendanceCheckList = {};

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
        if (string.find(onote, "1") ~= nil) then
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
                GuildRosterSetOfficerNote(memberIndex, onote.."0");
                LT_AttendanceCheckList[name] = 1;
            end
        else
            --DEFAULT_CHAT_FRAME:AddMessage("DEBUG1: " ..name.." is Online ");
            if ( LT_AttendanceCheckList[name] == nil ) then
                GuildRosterSetOfficerNote(memberIndex, onote.."1");
                LT_AttendanceCheckList[name] = 1;
            end
        end
    end
end

--Used to return their percentage
function LT_GetAttendance(playerIndex)
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
    
    for w in string.gmatch(onote, "1") do
        counter = counter + 1;
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