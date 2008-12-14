LT_TIMER_TOGGLE = false;
LT_TIMER_START = time();
LT_TIME_OF_LAST_TIC = time();
LT_TIMER_TOTAL = 0;
LT_Timer_UpdateInterval = 1.0;
LT_TIME_EXPIRED = false;

function LT_TimerOnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
end

function LT_Timer_Clicked(args)
    --LT_Print("Clicked: "..args);
    if (args == "LeftButton") then
        LT_TimerToggle();
    elseif (args == "RightButton") then
        LT_Timer_Settings:Show();
    end
end

function LT_Timer_SlashHandler(args)
    if (string.find(args, " ") == nil) then
		LT_Print("lt timer default");
		return;
	end
    local cmd = string.sub(args, string.find(args, " ")+1);
    if (cmd == "default") then
            LT_SetInterval(10,"min");
            LT_SetInterval(0,"sec");
            LT_SetInterval(4,"durationhr");
            LT_SetInterval(0,"durationmin");
            LT_SetInterval(0,"durationsec");
            local info_label = getglobal("LT_Main".."TimerInfo".."Label");
            info_label:SetText(string.format("Tic: %02d:%02d; Stop: %02d:%02d:%02d", LT_GetInterval("min"), LT_GetInterval("sec"), LT_GetInterval("durationhr"),LT_GetInterval("durationmin"),LT_GetInterval("durationsec")));
    end
end

function LT_Timer_OnEvent(arg)
    if (event == "VARIABLES_LOADED") then
        if (LT_TimerInterval == nil) then
            LT_TimerInterval = {};
            LT_SetInterval(10,"min");
            LT_SetInterval(0,"sec");
            LT_SetInterval(4,"durationhr");
            LT_SetInterval(0,"durationmin");
            LT_SetInterval(0,"durationsec");
            --LT_Print("LT_Timer: min-"..LT_TimerInterval["min"].." sec-"..LT_TimerInterval["sec"].." total-"..LT_TimerInterval["total"]);
        end
        LT_Timer_ShowInfo("");
    end
end

function LT_Timer_Settings_OK()
    LT_SetInterval(LT_Timer_SettingsMinInterval:GetText(),"min");
    LT_SetInterval(LT_Timer_SettingsSecInterval:GetText(),"sec");
    LT_SetInterval(LT_Timer_SettingsDurationHr:GetText(),"durationhr");
    LT_SetInterval(LT_Timer_SettingsDurationMin:GetText(),"durationmin");
    LT_SetInterval(LT_Timer_SettingsDurationSec:GetText(),"durationsec");
    LT_Timer_Settings:Hide();
    LT_Timer_ShowInfo();
end

function LT_Timer_Settings_Cancel()
    LT_Timer_Settings:Hide();
end

function LT_Timer_ShowInfo(args)
    local info_label = getglobal("LT_Main".."TimerInfo".."Label");
    if (args == nil) then
        info_label:SetTextColor(1, 1, 1);
        info_label:SetText(string.format("Tic: %02d:%02d; Stop: %02d:%02d:%02d", LT_GetInterval("min"), LT_GetInterval("sec"), LT_GetInterval("durationhr"),LT_GetInterval("durationmin"),LT_GetInterval("durationsec")));
    else
        info_label:SetText(args);
    end
end

function LT_Timer_HideInfo()
    local info_label = getglobal("LT_Main".."TimerInfo".."Label");
    info_label:SetText("");
end

function LT_Timer_Settings_OnShow()
    local min_int = getglobal("LT_Timer_Settings".."MinInterval");
    min_int:SetText(LT_GetInterval("min"));
    local min_label = getglobal("LT_Timer_Settings".."MinLabel".."Label");
    min_label:SetText("Min:");
    
    local sec_int = getglobal("LT_Timer_Settings".."SecInterval");
    sec_int:SetText(LT_GetInterval("sec"));
    local sec_label = getglobal("LT_Timer_Settings".."SecLabel".."Label");
    sec_label:SetText("Sec:");
    
    local durhr_int = getglobal("LT_Timer_Settings".."DurationHr");
    durhr_int:SetText(LT_GetInterval("durationhr"));
    local durhr_label = getglobal("LT_Timer_Settings".."DurationHrLabel".."Label");
    durhr_label:SetText("Hr:");
    
    local durmin_int = getglobal("LT_Timer_Settings".."DurationMin");
    durmin_int:SetText(LT_GetInterval("durationmin"));
    local durmin_label = getglobal("LT_Timer_Settings".."DurationMinLabel".."Label");
    durmin_label:SetText("Min:");
    
    local dursec_int = getglobal("LT_Timer_Settings".."DurationSec");
    dursec_int:SetText(LT_GetInterval("durationsec"));
    local dursec_label = getglobal("LT_Timer_Settings".."DurationSecLabel".."Label");
    dursec_label:SetText("Sec:");
end

function LT_SetInterval(args, arg2)
    --If they entered nothing, set value to 0.
    if (args == "") then
        args = 0;
    end
    
    --If they entered a non-numeric, set value to 0.
    local test = string.find(args, "%D");
    if (test ~= nil) then
        return;
    end
    
    --Flags for total calculations at the bottom
    local timeflag = false;
    local durflag = false;
    --If they didn't specify what to set, end.
    if (arg2 ~= nil) then
        --Handle attendance timer.
        if (arg2 == "sec") then
            LT_TimerInterval["sec"] = args;
            if (LT_TimerInterval["min"] == nil) then
                LT_TimerInterval["min"] = 0;
            end
            timeflag = true;
        elseif (arg2 == "min") then
            LT_TimerInterval["min"] = args;
            if (LT_TimerInterval["sec"] == nil) then
                LT_TimerInterval["sec"] = 0;
            end
            timeflag = true;
        end
        
        --Handle duration timer.
        if (arg2 == "durationhr") then
            LT_TimerInterval["durationhr"] = args;
            if (LT_TimerInterval["durationmin"] == nil) then
                LT_TimerInterval["durationmin"] = 0;
            end
            if (LT_TimerInterval["durationsec"] == nil) then
                LT_TimerInterval["durationsec"] = 0;
            end
            durflag = true;
        elseif (arg2 == "durationmin") then
            LT_TimerInterval["durationmin"] = args;
            if (LT_TimerInterval["durationhr"] == nil) then
                LT_TimerInterval["durationhr"] = 0;
            end
            if (LT_TimerInterval["durationsec"] == nil) then
                LT_TimerInterval["durationsec"] = 0;
            end
            durflag = true;
        elseif (arg2 == "durationsec") then
            LT_TimerInterval["durationsec"] = args;
            if (LT_TimerInterval["durationhr"] == nil) then
                LT_TimerInterval["durationhr"] = 0;
            end
            if (LT_TimerInterval["durationmin"] == nil) then
                LT_TimerInterval["durationmin"] = 0;
            end
            durflag = true;
        end
        
        if (timeflag) then
            LT_TimerInterval["total"] = LT_TimerInterval["min"]*60 + LT_TimerInterval["sec"];
        elseif (durflag) then
            LT_TimerInterval["durationtotal"] = LT_TimerInterval["durationhr"]*3600 + LT_TimerInterval["durationmin"]*60 + LT_TimerInterval["durationsec"];
        end
        
    else
        return;
    end
    --LT_Print("Duration reset to total: "..LT_TimerInterval["durationtotal"]);
end

function LT_GetInterval(args)
    if (LT_TimerInterval == nil) then
        LT_Print("CRITICAL ERROR, TimerInterval is empty");
        return "Err.";
    end
    if (args == nil) then
        return LT_TimerInterval["total"];
    elseif (args == "min") then
        LT_TimerInterval["min"] = floor(LT_TimerInterval["total"]/60);
        return LT_TimerInterval["min"];
    elseif (args == "sec") then
        LT_TimerInterval["sec"] = mod(LT_TimerInterval["total"],60);
        return LT_TimerInterval["sec"];
    elseif (args == "durationhr") then
        LT_TimerInterval["durationhr"] = floor(LT_TimerInterval["durationtotal"]/3600);
        return LT_TimerInterval["durationhr"];
    elseif (args == "durationmin") then
        LT_TimerInterval["durationmin"] = mod(floor(LT_TimerInterval["durationtotal"]/60),60);
        return LT_TimerInterval["durationmin"];
    elseif (args == "durationsec") then
        LT_TimerInterval["durationsec"] = mod(LT_TimerInterval["durationtotal"],60);
        return LT_TimerInterval["durationsec"];
    end
end

function LT_TimerToggle()
    if (LT_TIME_EXPIRED) then
            local timer_label = getglobal("LT_Main".."Timer".."Label");
            timer_label:SetTextColor(0, 1, 1);
            timer_label:SetText("<Click for timer>");
            LT_Timer_HideInfo();
            LT_TIME_EXPIRED = false;
            return;
    end
    if (LT_TIMER_TOGGLE == true) then
        StaticPopupDialogs["Stop Timer Warning"] = {
        text = "Are you sure you want to stop the raid timer?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            LT_TIMER_TOGGLE = false;
            local timer_label = getglobal("LT_Main".."Timer".."Label");
            timer_label:SetTextColor(0, 1, 1);
            timer_label:SetText("<Click for timer>");
            LT_Timer_HideInfo();
        end,
        timeout = 5,
        whileDead = 1,
        hideOnEscape = 1
        };
        
        StaticPopup_Show("Stop Timer Warning");
        
    elseif (LT_TIMER_TOGGLE == false) then
        LT_TIMER_START = time();
        LT_TIME_OF_LAST_TIC = time();
        local timer_label = getglobal("LT_Main".."Timer".."Label");
        timer_label:SetTextColor(0, 1, 1);
        timer_label:SetText("Starting timer...");
        LT_TIMER_TOGGLE = true;
        LT_Timer_ShowInfo();
    end 
end

LT_GameTimeOffset = nil;
LT_GameTimeStart = nil;
function LT_GetGameTime()
    if LT_GameTimeOffset == nil then
        local hour, minute = GetGameTime();
        local time_table = date("*t", time());
        time_table.hour = hour;
        time_table.min = minute;
        return time(time_table);
    else
        return time() + LT_GameTimeOffset;
    end
end

function LT_TimerOnUpdate(self, elapsed)
    if (LT_Main:IsShown()) then
        GuildRoster();
    end
    if (LT_GameTimeOffset == nil) then
        local hour, minute = GetGameTime();
        if (LT_GameTimeStart == nil) then
            LT_GameTimeStart = minute;
        elseif (LT_GameTimeStart ~= minute) then
            local seconds = time();
            local time_table = date("*t", seconds);
            time_table.hour = hour;
            time_table.min = minute;
            time_table.sec = 0;
            LT_GameTimeOffset = time(time_table) - time();
        end
    end
    if (LT_TIMER_TOGGLE == true) then
        self.TimeSinceLastUpdate  = self.TimeSinceLastUpdate + elapsed;
        
        --Prevent code from running more than once a second.
        if (self.TimeSinceLastUpdate > LT_Timer_UpdateInterval) then
            --DEFAULT_CHAT_FRAME:AddMessage("Thrashing?");
            LT_TIMER_TOTAL = difftime(time(), LT_TIMER_START);

            --Prevent painting data if the window its in is not shown.
            if (LT_Main:IsShown()) then
                TIMER_SEC = mod(LT_TIMER_TOTAL,60);
                TIMER_MIN = mod(floor(LT_TIMER_TOTAL/60),60);
                TIMER_HR = floor(LT_TIMER_TOTAL/3600);
                
                local timer_label = getglobal("LT_Main".."Timer".."Label");
                timer_label:SetTextColor(0, 1, 1);
                timer_label:SetText(string.format("%02d:%02d:%02d", TIMER_HR, TIMER_MIN, TIMER_SEC));
            end
            
            --Reset the interval checker
            self.TimeSinceLastUpdate = 0;
            
            --If your specified interval has been met, run the code (watch out for lag problems here)
            if ( (time()-LT_TIME_OF_LAST_TIC) >= LT_TimerInterval["total"]) then
                LT_TIME_OF_LAST_TIC = time();
                LT_Print(LT_TimerInterval["total"].." SECONDS PASSED!!!","yellow");
                LT_AttendanceTic();
            end
            if ( (time()-LT_TIMER_START) >= LT_TimerInterval["durationtotal"]) then
                LT_TIMER_TOGGLE = false;
                local timer_label = getglobal("LT_Main".."Timer".."Label");
                timer_label:SetTextColor(1, 0, 0);
                LT_TIME_EXPIRED = true;
            end
        end
    end
end