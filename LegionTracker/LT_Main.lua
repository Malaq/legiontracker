function LT_OnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("GUILD_ROSTER_UPDATE");
    this:RegisterEvent("CHAT_MSG_SYSTEM");
    
    SLASH_LEGIONTRACKER1 = "/lt";
    --SLASH_LEGIONTRACKER2 = "/legiontracker";
	SlashCmdList['LEGIONTRACKER'] = function(msg)
		LT_SlashHandler(msg)
	end
end

function LT_SlashHandler(args)
    if args == '' then
		DEFAULT_CHAT_FRAME:AddMessage(format("Legion Tracker"), 1, 1, 0)
		DEFAULT_CHAT_FRAME:AddMessage(format("-------------------------------------"), 1, 1, 0)
		DEFAULT_CHAT_FRAME:AddMessage(format("show - Displays the main window."), 1, 1, 0)
		DEFAULT_CHAT_FRAME:AddMessage(format("hide - Hides the main window."), 1, 1, 0)
		DEFAULT_CHAT_FRAME:AddMessage(format("loot - Loot commands."), 1, 1, 0)
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

function prettyprint(message, msg_format)
    if (msg_format == nil) then
        DEFAULT_CHAT_FRAME:AddMessage(message);
    else
        DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 1, 0);
    end
end
