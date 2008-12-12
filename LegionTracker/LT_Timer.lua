TIMER_TOGGLE = false;
TIMER_START = time();
TIME_OF_LAST_TIC = time();
TIMER_TOTAL = 0;
LT_Timer_UpdateInterval = 1.0;

function LT_TimerOnLoad()
    this:RegisterEvent("VARIABLES_LOADED");
    LT_Print("Loaded LT_Timer");
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
    end
end

function LT_Timer_OnEvent(arg)
    if (event == "VARIABLES_LOADED") then
        LT_Print("EVENT: "..event);
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
    min_int = getglobal("LT_Timer_Settings".."MinInterval");
    min_int:SetText(LT_GetInterval("min"));
    min_label = getglobal("LT_Timer_Settings".."MinLabel".."Label");
    min_label:SetText("Min:");
    
    sec_int = getglobal("LT_Timer_Settings".."SecInterval");
    sec_int:SetText(LT_GetInterval("sec"));
    sec_label = getglobal("LT_Timer_Settings".."SecLabel".."Label");
    sec_label:SetText("Sec:");
    
    durhr_int = getglobal("LT_Timer_Settings".."DurationHr");
    durhr_int:SetText(LT_GetInterval("durationhr"));
    durhr_label = getglobal("LT_Timer_Settings".."DurationHrLabel".."Label");
    durhr_label:SetText("Hr:");
    
    durmin_int = getglobal("LT_Timer_Settings".."DurationMin");
    durmin_int:SetText(LT_GetInterval("durationmin"));
    durmin_label = getglobal("LT_Timer_Settings".."DurationMinLabel".."Label");
    durmin_label:SetText("Min:");
    
    dursec_int = getglobal("LT_Timer_Settings".."DurationSec");
    dursec_int:SetText(LT_GetInterval("durationsec"));
    dursec_label = getglobal("LT_Timer_Settings".."DurationSecLabel".."Label");
    dursec_label:SetText("Sec:");
end

function LT_SetInterval(args, arg2)
    --If they entered nothing, set value to 0.
    if (args == "") then
        args = 0;
    end
    
    --If they entered a non-numeric, set value to 0.
    test = string.find(args, "%D");
    if (test ~= nil) then
        return;
    end
    
    --Flags for total calculations at the bottom
    timeflag = false;
    durflag = false;
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
    if (TIMER_TOGGLE == true) then
        TIMER_TOGGLE = false;
        timer_label = getglobal("LT_Main".."Timer".."Label");
        timer_label:SetText("<Click for timer>");
        LT_Timer_HideInfo();
    elseif (TIMER_TOGGLE == false) then
        TIMER_START = time();
        TIME_OF_LAST_TIC = time();
        timer_label = getglobal("LT_Main".."Timer".."Label");
        timer_label:SetText("Starting timer...");
        TIMER_TOGGLE = true;
        LT_Timer_ShowInfo();
    end 
end

function LT_TimerOnUpdate(self, elapsed)
    if (TIMER_TOGGLE == true) then
        self.TimeSinceLastUpdate  = self.TimeSinceLastUpdate + elapsed;
        
        --Prevent code from running more than once a second.
        if (self.TimeSinceLastUpdate > LT_Timer_UpdateInterval) then
            --DEFAULT_CHAT_FRAME:AddMessage("Thrashing?");
            TIMER_TOTAL = difftime(time(), TIMER_START);
            --TICKER = mod(TIMER_TOTAL, LT_TimerInterval["total"]);
            --Prevent painting data if the window its in is not shown.
            if (LT_Main:IsShown()) then
                TIMER_SEC = mod(TIMER_TOTAL,60);
                TIMER_MIN = mod(floor(TIMER_TOTAL/60),60);
                TIMER_HR = floor(TIMER_TOTAL/3600);
                
                timer_label = getglobal("LT_Main".."Timer".."Label");
                timer_label:SetTextColor(0, 1, 1);
                timer_label:SetText(string.format("%02d:%02d:%02d", TIMER_HR, TIMER_MIN, TIMER_SEC));
            end
            
            --Reset the interval checker
            self.TimeSinceLastUpdate = 0;
            
            --If your specified interval has been met, run the code (watch out for lag problems here)
            --if (TICKER == 0) and (TIMER_TOTAL ~= 0) then
            if ( (time()-TIME_OF_LAST_TIC) >= LT_TimerInterval["total"]) then
                TIME_OF_LAST_TIC = time();
                LT_Print(LT_TimerInterval["total"].." SECONDS PASSED!!!","bleh");
                --Add attendance ticking code here!
            end
            if ( (time()-TIMER_START) >= LT_TimerInterval["durationtotal"]) then
                TIMER_TOGGLE = false;
            end
        end
    end
end