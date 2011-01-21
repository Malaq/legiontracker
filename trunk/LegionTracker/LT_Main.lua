LT_VERSION = "Legion Tracker 0.904"
LT_NumPlayersShown = 5;
LT_Main_SortIndex = 1;
-- {0, 1, ..., n-1} -> player_name
LT_PlayerList = nil;
LT_NameLookup = {};
LT_InfoLookup = {};
LT_Main_ST = nil;
LT_Main_ST1 = nil;
LT_LDB = LibStub("LibDataBroker-1.1", true)
LT_LDBIcon = LibStub("LibDBIcon-1.0", true)
--LT_Show_Minimap_Icon = true;
LT_raiderFilter = false;
LT_offlineFilter = true;
LT_Rows_Shown = 0;
LT_NewRosterUpdate = false;
LT_FirstRosterUpdate = true;

function LT_OnLoad(self)
	LT_Main:SetParent(UIParent);
    --Makes Esc Work?
    tinsert(UISpecialFrames, self:GetName());
    --Minimap icon?
    --if LT_LDB then
    --    LT_createLDB();
    --end
    self:RegisterEvent("VARIABLES_LOADED");
    self:RegisterEvent("GUILD_ROSTER_UPDATE");
    self:RegisterEvent("CHAT_MSG_SYSTEM");
    self:RegisterEvent("CHAT_MSG_WHISPER");
    self:RegisterEvent("RAID_ROSTER_UPDATE");
    --this:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    LT_LoadLabels();
    LT_Main_SetupTable(self);
    self:EnableMouseWheel(true);
    self:SetScript("OnMouseWheel", LT_OnMouseWheel);
    SLASH_LEGIONTRACKER1 = "/lt";
    SLASH_LEGIONTRACKER2 = "/legiontracker";
	SlashCmdList['LEGIONTRACKER'] = function(msg)
		LT_SlashHandler(msg)
	end
    self:Hide();
end

--function LT_Main_OnEvent(this, event, arg1, arg2)
function LT_Main_OnEvent(self, event, ...)

    --LT_Print("LT_MAIN_EVENT event: "..event,"yellow");
    if (event == "GUILD_ROSTER_UPDATE") then
        LT_NewRosterUpdate = true;
        LT_UpdatePlayerList();
        -- We get guildroster if someone else updates an officer note.
        -- Very possible this is the lag bomb when you have the window open.
        LT_Attendance_OnChange();
    elseif (event == "VARIABLES_LOADED") then
        LT_UpdatePlayerList();
        if (LT_savedVarTable == nil) then
            LT_savedVarTable = {};
        end
        LT_createLDB();
--        if (LT_Show_Minimap_Icon == true) then
--            LT_Print("456");
--            LT_LDBIcon:Show("LT_LDB");
--        elseif (LT_Show_Minimap_Icon == false) then
--            LT_Print("654");
--            LT_LDBIcon:Hide("LT_LDB");
--        end
    elseif (event == "CHAT_MSG_WHISPER") then
        local arg1, arg2 = ...;
        LT_OfficerLoot:OnEvent(event, arg1, arg2);
    elseif (event == "CHAT_MSG_SYSTEM") then
        local arg1 = ...;
        --LT_Print("System message received: "..arg1);
        if (arg1 == "You have joined a raid group.") then
            LT_ResetLootButton();
        end
    end
end

function LT_Main_OnShow()
    --Load all items into local cache.
    --For some reason this had no effect when fired from variables loaded.  So I moved
    --it here instead.
    Loot_CacheLoot(true);
end

function LT_SlashHandler(args)
    if args == '' then
		LT_Print("Legion Tracker", "yellow");
		LT_Print("-------------------------------------", "yellow");
		LT_Print("attendance - Display attendance commands.", "yellow");
        LT_Print("hide - Hides the main window.", "yellow");
        LT_Print("loot - Display loot commands.", "yellow");
        LT_Print("show - Displays the main window.", "yellow");
        LT_Print("startloot - Starts accepting loot whispers.", "yellow");
        LT_Print("timer - Display timer commands.", "yellow");
        LT_Print("version - Broadcasts a LT version check.", "yellow");
        LT_Print("vote - Show vote window.", "yellow");
        LT_Print("tableundo - Restore old table data prior to tablecopy.","yellow");
        LT_Print("tablecopy <player> - Request a copy of the loot data from <player>","yellow");
        LT_Print("minimap hide/show - Displays or hides the minimap icon.","yellow");
        --LT_Print("mainchange <oldmain> <newmain> - This will correct all onotes for that player.","yellow");
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
        elseif string.find(args, "^vote") ~= nil then
            LT_Main_ViewVotes();
        elseif string.find(args, "^startloot") ~= nil then
            LT_Main_StartLootWhispers();
        elseif string.find(args, "^version") ~= nil then
            LT_Settings_VersionCheck();
        elseif string.find(args, "tablecopy") ~= nil then
            LT_Settings_Table_Request(args);
        elseif string.find(args, "tableundo") ~= nil then
            LT_Settings_Table_Undo();
        elseif string.find(args, "^add") ~= nil then
            LT_OfficerLoot:Add(string.sub(args, 4));
        elseif string.find(args, "^minimap") ~= nil then
            LT_Settings_Minimap_SlashHandler(args);
        elseif args == "olt1" then
            LT_OfficerLoot.msg_channel = "WHISPER";
            LT_OfficerLoot.msg_target = "Malaaq";
            --local items = {"Mirror of Truth", "Grim Toll", "Slime Stream Bands", "Totem of Dueling", "Aged Winter Cloak", "Favor of the Dragon Queen", "Ring of Invincibility", "Ring of Invincibility"};
            local items = {"Azure Silk Belt", "Hydrocane", "Jeweler's Kit", "Simple Grinder", "Flask of Enhancement", "Guild Tabard", "Hearthstone", "Hearthstone"};
            local item_links = {};
            for i = 1, #items do 
                local _, link = GetItemInfo(items[i]);
                table.insert(item_links, link);
            end
            LT_OfficerLoot:BroadcastNewItems(items, item_links);
            LT_OfficerLoot:OnShow();
        elseif args == "olt2" then
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Yuzuki", "main", "Shard of Contempt", "Shouldn't see this");
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Yuzuki", "main", "Shard of Contempt", "I like hit rating");
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Happyduude", "main", "", "Wooo");
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Vaulk", "alt", "Mirror of Truth", "I also like hit rating");
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Sindaga", "alt", "Mirror of Truth", "I also like hit rating");
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Malaaq", "alt", "Mirror of Truth", "I also like hit rating");
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Jinkoos", "alt", "Mirror of Truth", "I also like hit rating");
            LT_OfficerLoot:AddBid("Azure Silk Belt", "Ntrx", "alt", "Mirror of Truth", "I also like hit rating");
            
            LT_OfficerLoot:AddBid("Hydrocane", "Yuzuki", "main", "Shard of Contempt", "I like hit rating");
            LT_OfficerLoot:AddBid("Hydrocane", "Happyduude", "main", "Shard of Contempt", "I like hit rating");
            LT_OfficerLoot:AddBid("Hydrocane", "Sindaga", "main", "Shard of Contempt", "I like hit rating");
            LT_OfficerLoot:AddBid("Hydrocane", "Cahrin", "main", "Shard of Contempt", "I like hit rating");
            LT_OfficerLoot:AddBid("Hydrocane", "Nobunaga", "main", "Shard of Contempt", "I like hit rating");
            LT_OfficerLoot:AddBid("Simple Grinder", "Threelibra", "main", "Shard of Contempt", "I like hit rating");
        end
	end
end

--Add color choices for msg_format?
function LT_Print(message, msg_format)
    if (message == nil) then
        message = "LT_BLANK_MESSAGE";
    end
    
    if (msg_format == nil) then
        DEFAULT_CHAT_FRAME:AddMessage(message);
    else
        if (msg_format == "yellow") then
            DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 1, 0);
        elseif (msg_format == "red") then
            DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 0, 0);
        elseif (msg_format == "blue") then
            DEFAULT_CHAT_FRAME:AddMessage(format(message), 0, 0, 1);
        elseif (msg_format == "green") then
            DEFAULT_CHAT_FRAME:AddMessage(format(message), 0, 1, 0);
        else
            DEFAULT_CHAT_FRAME:AddMessage(format(message), 1, 1, 0);
        end
    end
end

function LT_Main_SetupTable(self)
	local cols = {};
    --New totals table
    local total_row = {};
	local w = LT_SummaryPanel:GetWidth();
	--table.insert(cols, {name="Name", width=w*0.25, align="LEFT", sort="asc"});
    table.insert(cols, {name="Name", width=w*0.25, align="LEFT", sort="desc"});
	table.insert(cols, {name="Class", width=w*0.15, align="LEFT", sortnext=1});
	table.insert(cols, {name="Attend.", width=w*0.08, align="LEFT", sortnext=1, comparesort=function(a, b, col)
		--local a1 = LT_GetAttendance(a);
		--local b1 = LT_GetAttendance(b);
        local a1 = LT_GetAttendance(LT_GetPlayerIndexFromName(LT_Main_ST.data[a].cols[1].charname()));
		local b1 = LT_GetAttendance(LT_GetPlayerIndexFromName(LT_Main_ST.data[b].cols[1].charname()));
        --local a1 = 0;
        --local b1 = 0;

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
    table.insert(cols, {name="Sitting", width=w*0.08, align="CENTER", sortnext=1, comparesort=function(a, b, col)
        --local a1 = LT_GetAttendance(a, true);
		--local b1 = LT_GetAttendance(b, true);
        local a1 = LT_GetAttendance(LT_GetPlayerIndexFromName(LT_Main_ST.data[a].cols[1].charname()),true);
		local b1 = LT_GetAttendance(LT_GetPlayerIndexFromName(LT_Main_ST.data[b].cols[1].charname()),true);
        --local a1 = 0;
        --local b1 = 0;

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
    
    --total columns
    table.insert(total_row, {name="", width=w*0.25, align="LEFT", ""});
	table.insert(total_row, {name="", width=w*0.15, align="LEFT", ""});
	table.insert(total_row, {name="", width=w*0.15, align="LEFT", ""});
	table.insert(total_row, {name="", width=w*0.06, align="CENTER", ""});
	table.insert(total_row, {name="", width=w*0.06, align="CENTER", ""});
	table.insert(total_row, {name="", width=w*0.06, align="CENTER", ""});
	table.insert(total_row, {name="", width=w*0.06, align="CENTER", ""});
	table.insert(total_row, {name="", width=w*0.14, align="CENTER", ""});
    --end total columns

	--local num_rows = math.floor(LT_SummaryPanel:GetHeight() / 15) - 1;
    local num_rows = math.floor(LT_SummaryPanel:GetHeight() / 15);
    local st = ScrollingTable:CreateST(cols, num_rows, 15, {r=0.3, g=0.3, b=0.4}, LT_SummaryPanel);
	st.frame:ClearAllPoints();
	st.frame:SetAllPoints(LT_SummaryPanel);
	LT_Main_ST = st;
	st:SetData({});
	st:Refresh();
    
    --Added for totals table.
    local st1 = ScrollingTable:CreateST1(total_row, 1, 15, {r=0.3, g=0.3, b=0.4}, LT_TotalPanel);
    st1.frame:ClearAllPoints();
	st1.frame:SetAllPoints(LT_TotalPanel);
	LT_Main_ST1 = st1;
	st1:SetData({});
	st1:Refresh();

	st:RegisterEvents({
		OnClick = function(row_frame, cell_frame, data, cols, row, realrow, column)
			if (realrow) then
                if (data[realrow].is_total ~= true) then
                    --LT_Char_ShowPlayer(GetGuildRosterInfo(realrow));
                    --LT_Print("cols1"..data[realrow].[name]);
                    LT_Char_ShowPlayer(data[realrow].cols[1].charname());
                else
                    LT_AllLoot:ToggleShow();
                end
			end
		end
	});
    
    --Totals Event
    st1:RegisterEvents({
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

function LT_Main_DropdownInit(self)
    local info = UIDropDownMenu_CreateInfo();
    info.text = "All Loot";
    info.owner = self;
    info.checked = nil;
    info.icon = nil;
	info.func = function()
		LT_Loot_SetFilter();
		UIDropDownMenu_SetText(LT_LootFilterSelect, "All Loot");
	end
    UIDropDownMenu_AddButton(info, 1);
    
    info.text = "Epics+ (no badges)"
	info.func = function()
		LT_Loot_SetFilter("!Poor !Uncommon !Common !Rare !Emblem !Abyss");
		UIDropDownMenu_SetText(LT_LootFilterSelect, "Epics+ (no badges)");
	end
    UIDropDownMenu_AddButton(info, 1);
end

function LT_GetClassColor(class)
	if (class == nil) then
		--return {r=1, g=1, b=1};
        return {r=0.5, g=0.5, b=0.5};
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
					value = function()
                        return "Rows: "..LT_Main_GetRows();
                    end
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

function LT_Main_CreateRow(id,manual_rowid)
    --LT_Print("id = "..id.." rowid = "..rowid);
    local row = _G["LT_Main_SummaryRow"..id];
    if (manual_rowid == nil) then
        row = _G["LT_Main_SummaryRow"..id];
    else
        row = _G["LT_Main_SummaryRow"..manual_rowid];
    end
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
                    end,
                    charname = function()
                        local name = GetGuildRosterInfo(id);
                        return name;
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
                { -- Sitting %
                    value = function()
                        local sitting = LT_GetAttendance(id,true);
                        if ( sitting == "" ) then
                            return "N/A";
                        else
                            return ""..sitting.."%";
                        end
                    end,
                    color = {r=1, g=0.5, b=0};
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
        if (manual_rowid == nil) then
        	_G["LT_Main_SummaryRow"..id] = row;
        else
            _G["LT_Main_SummaryRow"..manual_rowid] = row;
        end
		--_G["LT_Main_SummaryRow"..id] = row;
	end
	return row;
end

function LT_RedrawPlayerList()
	if (LT_Main:IsShown()) then
	    LT_Main_ST:Refresh();
        LT_Main_ST1:Refresh();
    end
end

function LT_IsNumber(str)
    if string.find(""..str, "%d") and string.find(""..str, "%D")==nil then
        return 1;
    else
        return nil;
    end
end

function LT_GetNumRaiders(verbose)
    counter = 0;
    for k,v in pairs(LT_InfoLookup) do
        --LT_Print("Key: "..k);
        local rank = LT_GetPlayerInfoFromName(k,"rank");
        if (rank ~= "Friend") and (rank ~= "Alt") and (rank ~= "Officer Alt") then
            if (verbose ~= nil) then
                LT_Print(k.." rank: "..rank,"yellow");
            end
            counter = counter+1;
        end
    end
    return counter;
end

function LT_GetPlayerIndexFromName(name)
    return LT_NameLookup[name];
end

function LT_GetPlayerInfoFromName(name,option)
    if (option == nil) then
        return;
    elseif (name == nil) or (name == "") then
    --Come back and fix this later.  It hit this condition if attendance was checking
    --the rank of a bad officernote on line 122 and 208.
        --LT_Print("LT_GetPlayerInfoFromName, nil name passed in for option: "..option);
        return "-1";
    elseif (LT_GetPlayerIndexFromName(name) == nil) then    
        return "-1";
    elseif (option == "index") then    
        return LT_InfoLookup[name][option];
    elseif (option == "rank") then
        return LT_InfoLookup[name][option];
    elseif (option == "onote") then
        if (LT_InfoLookup[name][option] == nil) then
            return "";
        else
            return LT_InfoLookup[name][option];
        end
    elseif (option == "online") then
        return LT_InfoLookup[name][option];
    elseif (option == "updated") then
        return LT_InfoLookup[name][option];
    elseif (option == "sync") then
        return LT_InfoLookup[name][option];
    elseif (option == "attendance") then
        if (LT_Attendance[name] == nil) then
            return "";
        else
            return LT_Attendance[name];
        end
    end
    return nil;
end

function LT_SetPlayerInfoFromName(name,option,value)
    if (option == nil) or (value == nil) then
        return nil;
    elseif (name == nil) then
        LT_Print("LT_SetPlayerInfoFromName, nil name passed in");
        return;
    elseif (option == "index") then    
        LT_InfoLookup[name][option] = value;
    elseif (option == "rank") then
        LT_InfoLookup[name][option] = value;
    elseif (option == "onote") then
        LT_InfoLookup[name][option] = value;
    elseif (option == "online") then
        LT_InfoLookup[name][option] = value;
    elseif (option == "updated") then
        LT_InfoLookup[name][option] = value;
    elseif (option == "sync") then    
        LT_InfoLookup[name][option] = value;
    elseif (option == "attendance") then
        LT_Attendance[name] = value;
    end
    return nil;
end

function LT_RankIsRaider(rank)
    if (rank ~= "Friend") and (rank ~= "Alt") and (rank ~= "Officer Alt") then
        return true;
    else
        return false;
    end
end

function LT_NameIsRaider(name)
    rank = LT_GetPlayerInfoFromName(name,"rank");
    if (rank ~= "Friend") and (rank ~= "Alt") and (rank ~= "Officer Alt") then
        return true;
    else
        return false;
    end
end

function LT_CheckForUnevenTicks()
    local maxTicks = 0;
    local sensor = 0;
    for i = 1, GetNumGuildMembers() do        
        local name = LT_GetPlayerIndexFromName(i);
        local rank = LT_GetPlayerInfoFromName(name,"rank");
        if (rank ~= "Friend") and (rank ~= "Alt") and (rank ~= "Officer Alt") then
            local ticks = string.len(LT_GetPlayerInfoFromName(name,"attendance"));
            --local oticks = string.len(LT_GetPlayerInfoFromName(name,"onote"));
            local name, _, _, _, _, _, _, onote = GetGuildRosterInfo(i);
            if (onote == nil) then
                onote = "";
            end
            local oticks = string.len(onote);
            local color = nil;
            if (oticks ~= ticks) then
                color = "red";
                sensor = 2;
            end
            if (sensor ~= 0) and (ticks ~= maxTicks) then
                color = "yellow";
            end
            LT_Print("Name: "..name.." has -- Onote: "..oticks.." - LT Table: "..ticks,color);
            if (ticks ~= maxTicks) then
                maxTicks = ticks;
                sensor = sensor+1;
            end
        end
    end
    if (sensor > 1) then
        LT_Print("LT: Attendance has an inconcistancy, please review.","red");
    end
end


function LT_UpdatePlayerList()
    LT_NameLookup = {};
    LT_CleanUp = {};
    --LT_InfoLookup = {};
    
    -- This always needs to be done regardless of whether or not
    -- we're shown, because attendance and loot depend on the lookup.

    local num_all_members = GetNumGuildMembers(true);
    
    local non_nil = true;
    for i = 1, num_all_members do
        --local name = GetGuildRosterInfo(i);
        local name, rank, _, _, _, _, _, officernote, online = GetGuildRosterInfo(i);
        if (name ~= nil) then
            LT_NameLookup[name] = i;
            LT_NameLookup[i] = name;
            LT_InfoLookup[name] = {};
            LT_InfoLookup[name]["index"] = i;
            LT_InfoLookup[name]["rank"] = rank;
            --if (LT_TIMER_TOGGLE == true) and (rank ~= "Friend") and (rank ~= "Alt") and (rank ~= "Officer Alt") then
            --    LT_Print(name.." is not having their officer note updated.");
            --else
            LT_InfoLookup[name]["onote"] = officernote;
            -- Added LT_FirstRosterUpdate to correct attendance data from crashes or relogins.
            if (LT_TIMER_TOGGLE == false) or (LT_FirstRosterUpdate == true) then
                LT_Attendance[name] = officernote;
                LT_FirstRosterUpdate = false;
            end
            LT_InfoLookup[name]["online"] = online;
            LT_InfoLookup[name]["updated"] = false;
            LT_InfoLookup[name]["sync"] = false;

            --LT_Print("LT_NameLookup Count: "..#LT_NameLookup.." Info: "..#LT_InfoLookup.." rank: "..LT_InfoLookup[name]["rank"]);
        else
            non_nil = false;
        end
    end

    if (LT_Main:IsShown() and non_nil == true) then
        local st = LT_Main_ST;
        local st1 = LT_Main_ST1;
        local totals = {};
        local data = {};
        local counter = 1;
        local mainRank, mainOnline;
    
        --Stupid reminder...OfflineFilter true = checkbox is not checked
        --                  offlineFilter false = checkbox IS checked
        --The thought was that when it is checked, you are displaying offline players
        --when its not checked, you want to filter out the offline players...
        --fail logic.
        
        local num_members = GetNumGuildMembers(true);
        --Added logic for raider filter
        --NEW LOGIC
        for i = 1, num_members do
            mainRank = nil;
            mainOnline = nil;
            local name,rank,_,_,_,_,_,_,online = GetGuildRosterInfo(i);
            if (rank == "Alt") or (rank == "Officer Alt") then
                local myMainName = LT_GetMainName(i);
                local mainIndex = LT_GetPlayerIndexFromName(myMainName);
                if (myMainName ~= "<Enter Main Name>") then
                    _,mainRank,_,_,_,_,_,_,mainOnline = GetGuildRosterInfo(mainIndex);
                end
            end

            if (LT_raiderFilter == false) and (LT_offlineFilter) then
                --Show everyone online
                if (online == 1) then
                    table.insert(data, LT_Main_CreateRow(i));
                end
            elseif (LT_raiderFilter) and (LT_offlineFilter) then
                --Show all online raiders
                if (online == 1) then
                    if (rank ~= "Alt") and (rank ~= "Officer Alt") and (rank ~= "Friend") then
                        table.insert(data, LT_Main_CreateRow(i));
                        LT_CleanUp[name] = # data;
                    elseif (rank == "Alt") or (rank == "Officer Alt") then
                        if (mainRank ~= "Friend") and (mainOnline ~= 1) then
                            table.insert(data, LT_Main_CreateRow(i));
                            LT_CleanUp[name] = # data;
                            LT_CleanUp[counter] = LT_GetMainName(i);--LT_GetMainName(i);
                            counter = counter+1;
                        end
                    end
                end
            elseif (LT_raiderFilter == false) and (LT_offlineFilter == false) then
                --Show everyone
                table.insert(data, LT_Main_CreateRow(i));
            elseif (LT_raiderFilter) and (LT_offlineFilter == false) then
                --Show all raider mains (on or offline)
                if (rank ~= "Alt") and (rank ~= "Officer Alt") and (rank ~= "Friend") then
                    table.insert(data, LT_Main_CreateRow(i));
                end
            end
        end
        
--        --OLD LOGIC
--        for i = 1, num_members do
--            local name,rank,_,_,_,_,_,_,online = GetGuildRosterInfo(i);
--            if (LT_raiderFilter) then    
--                if (rank ~= "Alt") and (rank ~= "Officer Alt") and (rank ~= "Friend") then
--                    table.insert(data, LT_Main_CreateRow(i));                    
--                    LT_CleanUp[name] = # data;
--                elseif (rank == "Alt") or (rank == "Officer Alt") then
--                    local myMainName = LT_GetMainName(i);
--                    if (myMainName ~= "<Enter Main Name>") then
--                        local _,mainRank,_,_,_,_,_,_,mainOnline = GetGuildRosterInfo(LT_GetPlayerIndexFromName(myMainName));
--                        if (mainRank ~= "Friend") and (LT_offlineFilter) then
--                        --(LT_MainOfflineCheckBox:GetChecked() ~= 1) then
--                        --Attempt to show alts instead of mains if the alt is online.
--                        --if (mainRank ~= "Friend") then
--                            if (online == 1) and (mainOnline ~= 1) then
--                                table.insert(data, LT_Main_CreateRow(i));
--                                LT_CleanUp[name] = # data;
--                                LT_CleanUp[counter] = LT_GetMainName(i);--LT_GetMainName(i);
--                                counter = counter+1;
--                            end
--                        end
--                    end
--                end
--            else
--                if (LT_offlineFilter) and (online == 1) then  
--                    table.insert(data, LT_Main_CreateRow(i));
--                elseif (LT_offlineFilter == false) then    
--                    table.insert(data, LT_Main_CreateRow(i));
--                end
--            end
--        end
        
        --Attempted logic to show alts instead of mains if the alt is online
--        if (LT_MainOfflineCheckBox:GetChecked() == 1) then
--            for i=1,counter-1 do
--                local value = LT_CleanUp[i];
--                table.remove(data,LT_CleanUp[value]);
--            end
--        end
        
        --Populate the global variable 
        LT_Rows_Shown = # data;

		--table.insert(data, LT_Main_CreateTotalRow());
        --Added for totals
        table.insert(totals, LT_Main_CreateTotalRow());
    
        st:SetData(data);
        st:Refresh();
        st1:SetData(totals);
        st1:Refresh();
    end
end

function LT_Main_GetRows()
    --LT_Print(LT_Rows_Shown);
    return LT_Rows_Shown;
end

function LT_GetMainName(playerIndex)
    local name, rank, _, _, _, _, _, onote = GetGuildRosterInfo(playerIndex);
    if (rank == "Alt") or (rank == "Officer Alt") then
        if (onote == "<Enter Main Name>") then
            return onote;
        end
        if (name == onote) then
            GuildRosterSetOfficerNote(LT_GetPlayerIndexFromName(name), "<Enter Main Name>");
            LT_Print(name.." has a looping officer note.  Fix immediately.","yellow");
            LT_Main:Hide();
            return name;
        end
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
    text = "LegionTracker: RESET ATTENDANCE/LOOT?\nAre you sure, this process can not be reversed.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        LT_ResetAttendance();
        LT_ResetLoot();
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
    };
    
    StaticPopup_Show("Reset Warning");
end

function LT_ResetLootButton()
    StaticPopupDialogs["Reset Warning"] = {
    text = "LegionTracker: RESET LOOT?\nAre you sure, this process can not be reversed.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        LT_ResetLoot();
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
    };
    
    StaticPopup_Show("Reset Warning");
end

function LT_LoadLabels()
    local timer_label = _G["LT_Main".."Timer".."Label"];
    timer_label:SetTextColor(0, 1, 1);
    timer_label:SetText("<Click for timer>");
    
    local version_label = _G["LT_Main".."TitleString"];
    version_label:SetText(LT_VERSION);
end

function LT_ExportButton()
    LT_Export:Show();
end

function LT_Main_StartLootWhispers()
    --LT_OfficerLoot_AwardedItems = {};
    --LT_OfficerLoot_ZoneData = {};
    if (GetNumLootItems() == 0) then
        LT_Print("LT_Error: must have the loot window open.");
        return;
    end
    
    if (LT_OfficerLoot:IsLootRunning() == 1) then
        LT_Print("LT_Error: loot is already running.  Please finish awarding loot before starting another loot distribution.");
        LT_Main_ViewVotes();
        return;
    end
    
    --Test to try to change the icon.
    --LT_LDB.icon = "Interface\\AddOns\\LegionTracker\\Icons\\LT_map_gold";
    --LT_LDBIcon:Refresh("LT_LDB", LT_savedVarTable);
    
    LT_OfficerLoot:ForcePopup();
    local items = {};
    local item_links = {};
    for i = 1, GetNumLootItems() do
        if (GetLootSlotLink(i)) then -- money returns nil
            local item, link = GetItemInfo(GetLootSlotLink(i));
            if (item and string.find(item, "Emblem of") == nil) then
                table.insert(item_links, link);
                table.insert(items, item);
            end
        end
    end
    LT_OfficerLoot:BroadcastNewItems(items, item_links);
    LT_OfficerLoot:OnShow();
    
    SendChatMessage("Whisper !bid to an officer for instructions", "RAID");
    SendChatMessage("Items are:", "RAID");
    for i = 1, #item_links do
        SendChatMessage(item_links[i], "RAID");
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

function LT_createLDB()
    --local L_BT_LEFT = L["|cffffff00Click|r to toggle bar lock"]
	--local L_BT_RIGHT = L["|cffffff00Right-click|r to open the options menu"]
    
    local LT_LDB = LibStub("LibDataBroker-1.1"):NewDataObject("LegionTracker", {
            type = "launcher",
            label = "LegionTracker",
            OnClick = function(_, msg)
                if msg == "LeftButton" then
                    if (LT_Main:IsShown()) then
                        LT_Main:Hide();
                    else
                        LT_Main:Show();
                    end
                elseif msg == "RightButton" then
                    if (LT_OfficerLoot_Frame:IsShown()) then
                        LT_OfficerLoot_Frame:Hide();
                    else
                        LT_Main_ViewVotes();
                    end
                end
            end,
            icon = "Interface\\AddOns\\LegionTracker\\Icons\\LT_map_silver",
            OnTooltipShow = function(tooltip)
			    if not tooltip or not tooltip.AddLine then return end
			    tooltip:AddLine("LegionTracker")
			    tooltip:AddLine("Left click - Toggle main window.")
			    tooltip:AddLine("Right click - View vote screen.")
            end,
    })
    if LT_LDBIcon then
        LT_LDBIcon:Register("LT_LDB", LT_LDB, LT_savedVarTable);
    end
    LT_LDBIcon:Show("LT_LDB");
--    if (LT_Show_Minimap_Icon == true) then
--        LT_LDBIcon:Show("LT_LDB");
--        LT_Print("123");
--    elseif (LT_Show_Minimap_Icon == false) then
--        LT_LDBIcon:Hide("LT_LDB");
--        LT_Print("321");
--    end
end
