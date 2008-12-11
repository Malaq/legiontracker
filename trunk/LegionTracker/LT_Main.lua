function LT_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("GUILD_ROSTER_UPDATE");
    this:RegisterEvent("CHAT_MSG_SYSTEM");
    
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
		LT_Print("loot - Loot commands.");
	else
		if args == "show" then
		    LT_Main:Show();
		end
		if args == "hide" then
		    LT_Main:Hide();
		end
		if string.find(args, "loot") then
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
