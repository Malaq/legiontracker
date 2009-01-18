LT_VERSION = "Legion Tracker 0.3"
LT_NumPlayersShown = 5;
LT_Main_SortIndex = 1;
-- {0, 1, ..., n-1} -> player_name
LT_PlayerList = nil;
LT_NameLookup = {};
LT_Main_ST = nil;

function LT_OnLoad()
	LT_Main:SetParent(UIParent);
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("GUILD_ROSTER_UPDATE");
    this:RegisterEvent("CHAT_MSG_SYSTEM");
    this:RegisterEvent("CHAT_MSG_WHISPER");
    --this:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    LT_LoadLabels();
    LT_Main_SetupTable();
    this:EnableMouseWheel(true);
    this:SetScript("OnMouseWheel", LT_OnMouseWheel);
    SLASH_LEGIONTRACKER1 = "/lt";
    SLASH_LEGIONTRACKER2 = "/legiontracker";
	SlashCmdList['LEGIONTRACKER'] = function(msg)
		LT_SlashHandler(msg)
	end
    this:Show();
end

function LT_Main_OnShow()
end

function LT_SlashHandler(args)
    if args == '' then
		LT_Print("Legion Tracker", "yellow");
		LT_Print("-------------------------------------", "yellow");
		LT_Print("show - Displays the main window.", "yellow");
		LT_Print("hide - Hides the main window.", "yellow");
		LT_Print("loot - Loot commands.");
        LT_Print("timer - Timer commands.", "yellow");
        LT_Print("attendance - Attendance Commands.", "yellow");
	else
		if args == "show" then
		    LT_Main:Show();
		end
		if args == "hide" then
		    LT_Main:Hide();
		end
		if string.find(args, "^loot") ~= nil then
			LT_Loot_SlashHandler(args);
		elseif string.find(args, "^timer") ~= nil then
            LT_Timer_SlashHandler(args);
        elseif string.find(args, "^attendance") ~= nil then
            LT_Attendance_SlashHandler(args); 
        elseif args == "olt" then
            LT_OfficerLoot:StartNewItems({"Mirror of Truth", "Grim Toll", "Slime Stream Bands", "Totem of Dueling"});
            LT_OfficerLoot:OnShow();
          --  LT_OfficerLoot:AddBid("Grim Toll", "Yuzuki", "Main", "Shard of Contempt", "I like hit rating");
        end
	end
end

--Add color choices for msg_format?
function LT_Print(message, msg_format)
    if (msg_format == nil) then
        DEFAULT_CHAT_FRAME:AddMessage(message);
    else
        DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 1, 0);
    end
end

function LT_Main_SetupTable()
	local cols = {};
	local w = LT_SummaryPanel:GetWidth();
	table.insert(cols, {name="Name", width=w*0.25, align="LEFT", sort="asc"});
	table.insert(cols, {name="Class", width=w*0.15, align="LEFT", sortnext=1});
	table.insert(cols, {name="Attendance", width=w*0.15, align="LEFT", sortnext=1, comparesort=function(a, b, col)
		local a1 = LT_GetAttendance(a);
		local b1 = LT_GetAttendance(b);

		if (tonumber(a1) and tonumber(b1)) then
			a1 = tonumber(a1);
			b1 = tonumber(b1);
		else
			a1 = ""..a1;
			b1 = ""..b1;
		end

		if (a1 == b1) then
			return LT_Main_ST:CompareSort(a, b, col);
		end

		local direction = LT_Main_ST.cols[col].sort or LT_Main_ST.cols[col].defaultsort or "asc";
		if (direction:lower() == "asc") then
			return a1 > b1;
		else
			return a1 < b1;
		end
	end});
	table.insert(cols, {name="Main", width=w*0.06, align="CENTER", sortnext=1});
	table.insert(cols, {name="Alt", width=w*0.06, align="CENTER", sortnext=1});
	table.insert(cols, {name="Off", width=w*0.06, align="CENTER", sortnext=1});
	table.insert(cols, {name="DE'd", width=w*0.06, align="CENTER", sortnext=1});
	table.insert(cols, {name="Unassigned", width=w*0.14, align="CENTER", sortnext=1});

	local num_rows = math.floor(LT_SummaryPanel:GetHeight() / 15) - 1;
    local st = ScrollingTable:CreateST(cols, num_rows, 15, {r=0.3, g=0.3, b=0.4}, LT_SummaryPanel);
	st.frame:ClearAllPoints();
	st.frame:SetAllPoints(LT_SummaryPanel);
	LT_Main_ST = st;
	st:SetData({});
	st:Refresh();

	st:RegisterEvents({
		OnClick = function(row_frame, cell_frame, data, cols, row, realrow, column)
			if (realrow) then
                if (data[realrow].is_total ~= true) then
				    LT_Char_ShowPlayer(GetGuildRosterInfo(realrow));
                else
                    LT_AllLoot:ToggleShow();
                end
			end
		end
	});

	local dropdown = CreateFrame("Frame", "LT_LootFilterSelect", LT_Main, "UIDropDownMenuTemplate");
	dropdown:ClearAllPoints();
	dropdown:SetAllPoints(LT_Main_Dropdown);
    UIDropDownMenu_Initialize(dropdown, LT_Main_DropdownInit);
	UIDropDownMenu_SetText(dropdown, "All Loot");
end

function LT_Main_DropdownInit()
    local info = UIDropDownMenu_CreateInfo();
    info.text = "All Loot";
    info.owner = this:GetParent();
    info.checked = nil;
    info.icon = nil;
	info.func = function()
		LT_Loot_SetFilter();
		UIDropDownMenu_SetText(LT_LootFilterSelect, "All Loot");
	end
    UIDropDownMenu_AddButton(info, 1);
    
    info.text = "Epics (no badges)"
	info.func = function()
		LT_Loot_SetFilter("Epic !Emblem !Abyss");
		UIDropDownMenu_SetText(LT_LootFilterSelect, "Epics (no badges)");
	end
    UIDropDownMenu_AddButton(info, 1);
end

function LT_GetClassColor(class)
	if (class == nil) then
		return {r=1, g=1, b=1};
	end

    local color_class = string.upper(class);
    if (color_class == "DEATH KNIGHT") then
        color_class = "DEATHKNIGHT";
    end
    return RAID_CLASS_COLORS[color_class];
end

function LT_GetClassColorFromName(name)
    if (LT_GetPlayerIndexFromName(name) == nil) then
        return {r=0.5, g=0.5, b=0.5};
    end
    
    local _, _, _, _, class = GetGuildRosterInfo(LT_GetPlayerIndexFromName(name));
    return LT_GetClassColor(class);
end

function LT_Main_CreateTotalRow()
	local row = _G["LT_Main_TotalRow"];
	if (row == nil) then
		row = {
            ["is_total"] = true,
			["cols"] = {
				{ -- Name
					value = "*Totals*",
				},
				{ -- Class
					value = "--";
				},
				{ -- Attendance
					value = "--";
				},
				{ -- Main
					value = function()
						return LT_Loot_GetLootCount(1, nil);
					end
				},
				{ -- Alt
					value = function()
						return LT_Loot_GetLootCount(2, nil);
					end
				},
				{ -- Off
					value = function()
						return LT_Loot_GetLootCount(3, nil);
					end
				},
				{ -- DE'd
					value = function()
						return LT_Loot_GetLootCount(5, nil);
					end
				},
				{ -- Unassigned
					value = function()
						return LT_Loot_GetLootCount(4, nil);
					end,
					color = function()
						local num = LT_Loot_GetLootCount(4, nil);
						if (num > 0) then
							return {r=1, g=0, b=0.5};
						else
							return {r=0.8, g=1, b=1.0};
						end
					end
				},
			},
			["color"] = {
				r = 0.6,
				g = 0.6,
				b = 1.0,
			}
		};
		_G["LT_Main_TotalRow"] = row;
	end
	return row;
end

function LT_Main_CreateRow(id)
	local row = _G["LT_Main_SummaryRow"..id];
	if (row == nil) then
		row = {
			["cols"] = {
				{ -- Name
					value = function()
						local name = GetGuildRosterInfo(id);
						if (LT_GetMainName(id) ~= name) then
							name = name.." ("..LT_GetMainName(id)..")";
						end
						return name;
					end,
                    color = function()
                        local _, _, _, _, _, _, _, _, online = GetGuildRosterInfo(id);
                        if (online) then
                            return {r=1, g=1, b=1};
                        else
                            return {r=0.4, g=0.4, b=0.4};
                        end
                    end
				},
				{ -- Class
					value = function()
						local _, _, _, _, class = GetGuildRosterInfo(id);
						return class;
					end,
					color = function()
						local _, _, _, _, class = GetGuildRosterInfo(id);
						return LT_GetClassColor(class);
					end
				},
				{ -- Attendance
					value = function()
						local attendance = LT_GetAttendance(id);
						if ( attendance == "" ) then
							return "N/A";
						else
							return ""..attendance.."%";
						end
					end
				},
				{ -- Main
					value = function()
						return LT_Loot_GetLootCount(1, GetGuildRosterInfo(id));
					end
				},
				{ -- Alt
					value = function()
						return LT_Loot_GetLootCount(2, GetGuildRosterInfo(id));
					end
				},
				{ -- Off
					value = function()
						return LT_Loot_GetLootCount(3, GetGuildRosterInfo(id));
					end
				},
				{ -- DE'd
					value = function()
						return LT_Loot_GetLootCount(5, GetGuildRosterInfo(id));
					end
				},
				{ -- Unassigned
					value = function()
						return LT_Loot_GetLootCount(4, GetGuildRosterInfo(id));
					end,
					color = function()
						local num = LT_Loot_GetLootCount(4, GetGuildRosterInfo(id));
						if (num > 0) then
							return {r=1, g=0, b=0};
						else
							return {r=0.8, g=1, b=0.8};
						end
					end
				},
			}
		};
		_G["LT_Main_SummaryRow"..id] = row;
	end
	return row;
end

function LT_RedrawPlayerList()
	if (LT_Main:IsShown()) then
	    LT_Main_ST:Refresh();
    end
end

function LT_IsNumber(str)
    if string.find(""..str, "%d") and string.find(""..str, "%D")==nil then
        return 1;
    else
        return nil;
    end
end

function LT_GetPlayerIndexFromName(name)
    return LT_NameLookup[name];
end

function LT_UpdatePlayerList()
    LT_NameLookup = {};
    
    -- This always needs to be done regardless of whether or not
    -- we're shown, because attendance and loot depend on the lookup.
    local num_all_members = GetNumGuildMembers(true);
    local non_nil = true;
    for i = 1, num_all_members do
        local name = GetGuildRosterInfo(i);
        if (name ~= nil) then
            LT_NameLookup[name] = i;
        else
            non_nil = false;
        end
    end
    
    if (LT_Main:IsShown() and non_nil == true) then
        local st = LT_Main_ST;
        local data = {};
    
        local num_members = GetNumGuildMembers(false);
        for i = 1, num_members do
            table.insert(data, LT_Main_CreateRow(i));
        end

		table.insert(data, LT_Main_CreateTotalRow());
    
        st:SetData(data);
        st:Refresh();
    end
end

function LT_GetMainName(playerIndex)
    local name, rank, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
    if (rank == "Alt") then
        local pindex = LT_GetPlayerIndexFromName(onote);
        if (pindex ~= nil) then
            return LT_GetMainName(pindex);
        end
        return name;
    else
        return name;
    end
end

function LT_ResetAll()
    StaticPopupDialogs["Reset Warning"] = {
    text = "You are about to reset all attendance and loot data, are you sure?  This process can not be reversed.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        LT_ResetAttendance();
        LT_PlayerLootTable = {};
		LT_LootTable = {};
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
    };
    
    StaticPopup_Show("Reset Warning");
end

function LT_LoadLabels()
    local timer_label = getglobal("LT_Main".."Timer".."Label");
    timer_label:SetTextColor(0, 1, 1);
    timer_label:SetText("<Click for timer>");
    
    local version_label = getglobal("LT_Main".."TitleString");
    version_label:SetText(LT_VERSION);
end

function LT_Main_OnEvent(this, event, arg1, arg2)
    if (event == "GUILD_ROSTER_UPDATE") then
        LT_UpdatePlayerList();
        -- We get guildroster if someone else updates an officer note.
        LT_Attendance_OnChange();
    elseif (event == "VARIABLES_LOADED") then
        LT_UpdatePlayerList();
    elseif (event == "CHAT_MSG_WHISPER") then
        LT_OfficerLoot:OnEvent(event, arg1, arg2);
    end
end

function LT_ExportButton()
    LT_Export:Show();
end

function LT_Main_StartLootWhispers()
    if (GetNumLootItems() == 0) then
        LT_Print("Error: must have the loot window open.");
        return;
    end
    
    local items = {};
    for i = 1, GetNumLootItems() do
        if (GetLootSlotLink(i)) then -- money returns nil
            local item, link = GetItemInfo(GetLootSlotLink(i));
            if (item and string.find(item, "Emblem of") == nil) then
                table.insert(items, link);
            end
        end
    end
    LT_OfficerLoot:BroadcastNewItems(items);
    LT_OfficerLoot:OnShow();
    
    LT_OfficerLoot:SendInstructions("RAID");
    SendChatMessage("Items are:", "RAID");
    for i = 1, #items do
        SendChatMessage(items[i], "RAID");
    end
end

function LT_Main_ViewVotes()
    LT_OfficerLoot:OnShow();
end

function LT_TableSize(table)
    local num = 0;
    for a in pairs(table) do
        num = num+1;
    end
    return num;
end
