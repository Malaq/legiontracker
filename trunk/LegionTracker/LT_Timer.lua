TIMER_TOGGLE = "false";
TIMER_START = time();
TIMER_TOTAL = 0;
LT_Timer_UpdateInterval = 1.0;

function LT_TimerOnLoad()
    LT_Print("Loaded LT_Timer");
    if (LT_TimerInterval == nil) then
        LT_TimerInterval = {};
        LT_SetInterval(1,"min");
        LT_SetInterval(0,"sec");
        LT_Print("LT_Timer: min-"..LT_TimerInterval["min"].." sec-"..LT_TimerInterval["sec"].." total-"..LT_TimerInterval["total"]);
    end
end

function LT_Timer_Clicked(args)
    --LT_Print("Clicked: "..args);
    if (args == "LeftButton") then
        LT_TimerToggle();
    elseif (args == "RightButton") then
        LT_Timer_Settings:Show();
    end
end

function LT_Timer_Settings_OnShow()
    min_int = getglobal("LT_Timer_Settings".."MinInterval");
    min_int:SetText(""..LT_GetInterval("min"));
    min_label = getglobal("LT_Timer_Settings".."MinLabel".."Label");
    min_label:SetText("Min:");
    
    sec_int = getglobal("LT_Timer_Settings".."SecInterval");
    sec_int:SetText(""..LT_GetInterval("sec"));
    sec_label = getglobal("LT_Timer_Settings".."SecLabel".."Label");
    sec_label:SetText("Sec:");
end

function LT_SetInterval(args, arg2)
    if (arg2 ~= nil) then
        if (arg2 == "sec") then
            LT_TimerInterval["sec"] = args;
            if (LT_TimerInterval["min"] == nil) then
                LT_TimerInterval["min"] = 0;
            end
        elseif (arg2 == "min") then
            LT_TimerInterval["min"] = args;
            if (LT_TimerInterval["sec"] == nil) then
                LT_TimerInterval["sec"] = 0;
            end
        end
        LT_TimerInterval["total"] = LT_TimerInterval["min"]*60 + LT_TimerInterval["sec"];
    else
        LT_TimerInterval["total"] = args;
    end
    LT_Print("Timer reset to total: "..LT_TimerInterval["total"]);
end

function LT_GetInterval(args)
    if (LT_TimerInterval == nil) then
        LT_Print("DEBUG:  TABLE IS EMPTY");
        return "Err.";
    end
    if (args == nil) then
        LT_Print("DEBUG1: "..LT_TimerInterval["total"]);
        return ""..LT_TimerInterval["total"];
    elseif (args == "min") then
        LT_Print("DEBUG2: "..LT_TimerInterval["min"]);
        return ""..LT_TimerInterval["min"];
    elseif (args == "sec") then
        LT_Print("DEBUG3: "..LT_TimerInterval["sec"]);
        return ""..LT_TimerInterval["sec"];
    end
end

function LT_TimerToggle()
    if (TIMER_TOGGLE == "true") then
        TIMER_TOGGLE = "false";
        timer_label = getglobal("LT_Main".."Timer".."Label");
        timer_label:SetText("<Click for timer>");
    elseif (TIMER_TOGGLE == "false") then
        TIMER_START = time();
        timer_label = getglobal("LT_Main".."Timer".."Label");
        timer_label:SetText("Starting timer...");
        TIMER_TOGGLE = "true";
    end 
end

function LT_TimerOnUpdate(self, elapsed)
    if (TIMER_TOGGLE == "true") then
        self.TimeSinceLastUpdate  = self.TimeSinceLastUpdate + elapsed;
        
        --Prevent code from running more than once a second.
        if (self.TimeSinceLastUpdate > LT_Timer_UpdateInterval) then
            --DEFAULT_CHAT_FRAME:AddMessage("Thrashing?");
            TIMER_TOTAL = difftime(time(), TIMER_START);
            TICKER = mod(TIMER_TOTAL, LT_TimerInterval["total"]);
            --Prevent painting data if the window its in is not shown.
            if (LT_Main:IsShown()) then
                TIMER_SEC = mod(TIMER_TOTAL,60);
                TIMER_MIN = mod(floor(TIMER_TOTAL/60),60);
                TIMER_HR = floor(TIMER_TOTAL/3600);
                
                timer_label = getglobal("LT_Main".."Timer".."Label");
                timer_label:SetText(string.format("%02d:%02d:%02d", TIMER_HR, TIMER_MIN, TIMER_SEC));
            end
            
            --Reset the interval checker
            self.TimeSinceLastUpdate = 0;
            
            --If your specified interval has been met, run the code (watch out for lag problems here)
            if (TICKER == 0) and (TIMER_TOTAL ~= 0) then
                LT_Print(LT_TimerInterval["total"].." SECONDS PASSED!!!","bleh");
                --Add attendance ticking code here!
            end
        end
    end
end