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

function LT_AttendanceTic()
    local guildCount = GetNumGuildMembers(true);
    for i = 1, guildCount do 
        LT_SingleMemberTic(i);
    end
    LT_Print("Attendance updated for " ..guildCount.. " players.");
end

function LT_ResetAttendance()
    local count = 0;
    guildCount = GetNumGuildMembers(true);
    for i = 1, guildCount do 
        --temp = GetGuildRosterSelection();
        _, rank, _, _, _, _, _, onote = GetGuildRosterInfo(i);
        if (rank ~= "Friend") then
            GuildRosterSetOfficerNote(i, "");
            count = count+1;
        elseif (rank == "Friend") and (onote ~= "Friend") then
            GuildRosterSetOfficerNote(i, "Friend");
            count = count+1;
        end
    end
    LT_Print("Attendance reset for " ..count.. " players.");
end

--Remove hard coded friend rank
function LT_SingleMemberTic(memberIndex)
    local name, rank, _, _, _, _, _, onote, online = GetGuildRosterInfo(memberIndex);
    if (rank ~= "Friend") then
        if (online == nil) then
            --DEFAULT_CHAT_FRAME:AddMessage("DEBUG1: " ..name.." is Offline.");
            GuildRosterSetOfficerNote(memberIndex, onote.."0");
        else
            --DEFAULT_CHAT_FRAME:AddMessage("DEBUG1: " ..name.." is Online ");
            GuildRosterSetOfficerNote(memberIndex, onote.."1");
        end
    elseif (rank == "Friend") and (onote ~= "Friend") then
       GuildRosterSetOfficerNote(memberIndex,"Friend"); 
    end
end

function LT_GetAttendance(playerIndex)
    local counter = 0;
    local _, _, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
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
    local _, _, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
    return onote;
end