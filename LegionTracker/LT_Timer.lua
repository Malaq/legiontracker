TIMER_TOGGLE = "false";
TIMER_START = time();
TIMER_TOTAL = 0;
LT_Timer_UpdateInterval = 1.0;
LT_Timer_AttendanceInterval = 10;

function LT_TimerOnLoad()
    LT_Print("Loaded LT_Timer");
end

function LT_Timer_Clicked(args)
    LT_Print("Clicked: "..args);
    if (args == "LeftButton") then
        LT_TimerToggle();
    elseif (args == "RightButton") then
        LT_Timer_Settings:Show();
    end
end

function LT_Timer_Settings_OnShow()
    form_label = getglobal("LT_Timer_Settings".."TimeInterval");
    form_label:SetText(LT_GetInterval());
end

function LT_SetInterval(args)
    if (args ~= nil) then
        LT_Timer_AttendanceInterval = args;
    end
end

function LT_GetInterval()
    return LT_Timer_AttendanceInterval;
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
            TICKER = mod(TIMER_TOTAL, LT_Timer_AttendanceInterval);
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
                LT_Print(LT_Timer_AttendanceInterval.." SECONDS PASSED!!!","bleh");
                --Add attendance ticking code here!
            end
        end
    end
end