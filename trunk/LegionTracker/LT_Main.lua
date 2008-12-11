LT_VERSION = "Legion Tracker 0.1"

function LT_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("GUILD_ROSTER_UPDATE");
    this:RegisterEvent("CHAT_MSG_SYSTEM");
    --this:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    
    LT_LoadLabels();
    
    SLASH_LEGIONTRACKER1 = "/lt";
    SLASH_LEGIONTRACKER2 = "/legiontracker";
	SlashCmdList['LEGIONTRACKER'] = function(msg)
		LT_SlashHandler(msg)
	end
end

function LT_SlashHandler(args)
    if args == '' then
		LT_Print("Legion Tracker", "blah");
		LT_Print("-------------------------------------", "blah");
		LT_Print("show - Displays the main window.", "blah");
		LT_Print("hide - Hides the main window.", "blah");
		LT_Print("loot - Loot commands.")
	else
		if args == "show" then
		    LT_Main:Show();
		end
		if args == "hide" then
		    LT_Main:Hide();
		end
		if args == "loot" then
			LT_Loot_SlashHandler(args);
		end
	end
end

function LT_Print(message, msg_format)
    if (msg_format == nil) then
        DEFAULT_CHAT_FRAME:AddMessage(message);
    else
        DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 1, 0);
    end
end

function LT_LoadLabels()
    timer_label = getglobal("LT_Main".."Timer".."Label");
    timer_label:SetText(string.format("%02d:%02d:%02d", "0", "0", "0"));
    
    version_label = getglobal("LT_Main".."Version".."Label");
    version_label:SetText(LT_VERSION);
    
    name_label = getglobal("LT_Main".."NameHead".."Label");
    name_label:SetText("Name");
    
    class_label = getglobal("LT_Main".."ClassHead".."Label");
    class_label:SetText("Class");
    
    attendance_label = getglobal("LT_Main".."AttendanceHead".."Label");
    attendance_label:SetText("Attendance");
    
    ms_label = getglobal("LT_Main".."MSHead".."Label");
    ms_label:SetText("Main");
    
    as_label = getglobal("LT_Main".."ASHead".."Label");
    as_label:SetText("Alt");
    
    os_label = getglobal("LT_Main".."OSHead".."Label");
    os_label:SetText("Off");
    
    unassigned_label = getglobal("LT_Main".."UnassignedHead".."Label");
    unassigned_label:SetText("Unassigned");
end