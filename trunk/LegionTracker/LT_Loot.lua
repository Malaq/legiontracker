LT_LootFrame = CreateFrame("Frame", "LegionTrackerLoot");
-- playername -> { {loot_ids}->1 }
LT_PlayerLootTable = {};
-- loot_id -> { ... }
LT_LootTable = {};
LT_UniqueLootId = 0;

LT_VarsLoaded = nil;

LT_Loot_FilterVal = nil;
LT_Loot_FilterNeg = {};
LT_Loot_FilterString = "";

LT_Loot_SavedSpecs = {};

function LT_ResetLoot()
    LT_PlayerLootTable = {};
    LT_LootTable = {};
    LT_Loot_OnChange();
end

function LT_Loot_SlashHandler(args)
    LT_Print("Loot with args: "..args);
    if (string.find(args, " ") == nil) then
		LT_Print("lt loot reset");
		LT_Print("lt loot print loot");
		LT_Print("lt loot print players");
        LT_Print("lt loot filter <filter tags>");
		return
	end

	local cmd = string.sub(args, string.find(args, " ")+1);
	LT_Print("Got command "..cmd);
	if cmd == "reset" then
		LT_ResetLoot();
	elseif cmd == "print loot" then
		LT_Print("Loots:");
		for k1, v1 in pairs(LT_LootTable) do
			LT_Print("*");
			for key, value in pairs(LT_LootTable[k1]) do
				LT_Print(string.format("%s:  %s", key, value));
			end
		end
	elseif cmd == "print players" then
		LT_Print("Players:");
		for k1, v1 in pairs(LT_PlayerLootTable) do
			LT_Print(k1..":");
			for key, value in pairs(LT_PlayerLootTable[k1]) do
				LT_Print(string.format("%s", key));
			end
		end
	elseif cmd == "prof getloot" then
		debugprofilestart();
		local i;
		for i = 1, 100 do
			LT_Loot_GetLoots();
		end
		LT_Print("100 getloots: "..(debugprofilestop()/1000));
	elseif cmd == "prof setfilter" then
		debugprofilestart();
		for i = 1, 1000 do
			LT_Loot_SetFilter("Epic !Emblem");
            --LT_Loot_SetFilter("!Poor !Uncommon !Common !Rare !Emblem");
		end
		LT_Print("1000 setfilters: "..(debugprofilestop()/1000));
	elseif cmd == "prof lootui" then
		debugprofilestart();
		for i = 1, 10 do
			LT_LootUI:UpdateFrame();
		end
		LT_Print("10 lootui:update_frames: "..(debugprofilestop()/1000));
	elseif cmd == "prof sort" then
		debugprofilestart();
		for i = 1, 10 do
			LT_LootUI.st:SortData();
		end
		LT_Print("10 lootui:sort: "..(debugprofilestop()/1000));
	end
end

function Loot_OnEvent(this, event, arg1)
	if event == "CHAT_MSG_LOOT" then
		local player = nil;
		if (string.find(arg1, "receive loot:") or string.find(arg1, "receives loot:")) then
			player = string.sub(arg1, 0, string.find(arg1, " receive")-1);	
			if (player == "You") then
				player = UnitName("player");
			end
		else 
			return
		end

		local name, link, rarity = GetItemInfo(string.sub(arg1, string.find(arg1, "|c.*|r")));
		local _, color, itemString = strsplit("|", link);
		local _, itemId = strsplit(":", itemString);
        
        -- If its a regular loot, see if its been awarded, if so, ignore the message
        if (this ~= "AWARD") then
            -- Does the player exist in the awarded items table?
            if (LT_OfficerLoot_AwardedItems[player] ~= nil) then
                if (LT_OfficerLoot_AwardedItems[player][name] ~= nil) then
                    LT_OfficerLoot_AwardedItems[player][name] = nil;
                    return
                end
            end
        end
        
		if (LT_PlayerLootTable[player] == nil) then
			LT_PlayerLootTable[player] = {};
		end

		local lootId = LT_UniqueLootId;
		LT_UniqueLootId = LT_UniqueLootId + 1;
		LT_PlayerLootTable[player][lootId] = 1;

		LT_LootTable[lootId] = {};
		LT_LootTable[lootId]["itemString"] = itemString;
		LT_LootTable[lootId]["time"] = LT_GetGameTime();
		LT_LootTable[lootId]["player"] = player;
		LT_LootTable[lootId]["spec"] = "Unassigned";
        if (this == "AWARD") then
            LT_LootTable[lootId]["zone"] = LT_OfficerLoot_ZoneData["ZONE"];
		    LT_LootTable[lootId]["subzone"] = LT_OfficerLoot_ZoneData["SUBZONE"];
            if (LT_Loot_SavedSpecs[player] and LT_Loot_SavedSpecs[player][GetItemInfo(itemString)]) then
                LT_LootTable[lootId]["spec"] = LT_Loot_SavedSpecs[player][GetItemInfo(itemString)];
            end
        else
    		LT_LootTable[lootId]["zone"] = GetRealZoneText();
		    LT_LootTable[lootId]["subzone"] = GetSubZoneText();
        end
        LT_LootTable[lootId]["lootId"] = lootId;
        
        LT_Loot_OnChange();
    elseif event == "VARIABLES_LOADED" then
        if (LT_LastRunVersion ~= LT_VERSION) then
            LT_LastRunVersion = LT_VERSION;
        end
	end
end

function LT_Loot_ChangeOwner(loot_id, new_owner)
    local loot = LT_LootTable[loot_id];
    LT_PlayerLootTable[loot.player][loot_id] = nil;
    loot.player = new_owner;
    if (LT_PlayerLootTable[loot.player] == nil) then
        LT_PlayerLootTable[loot.player] = {};
    end
    LT_PlayerLootTable[loot.player][loot_id] = 1;
    LT_Loot_OnChange();
end

LT_Loot_LootTypes = {"Main", "Alt", "Off", "Unassigned", "DE'd"};

function LT_Loot_GetSpecColor(spec)
    local color = {r=1, g=1, b=1};
    if (spec == "Main") then
        color={r=0.8,g=0.8,b=1};
    elseif (spec == "Alt") then
        color={r=0.6,g=0.6,b=0.75};
    elseif (spec == "Off") then
        color={r=0.5,g=0.5,b=0.5};
    elseif (spec == "Unassigned") then
        color={r=1.0,g=0.4,b=0.4};
    elseif (spec == "DE'd") then
        color={r=0.7,g=1.0,b=0.7};
    end
    return color;
end

function LT_Loot_GetSpecId(spec)
    for i=1,#LT_Loot_LootTypes do
        if (LT_Loot_LootTypes[i] == spec) then
            return i;
        end;
    end
    return 1;
end

function LT_Loot_GetLootCount(loot_type, player_name)
    local loot_types = LT_Loot_LootTypes;
    local num_loots = 0;
    if player_name ~= nil and LT_PlayerLootTable[player_name] ~= nil then
        for lootid in pairs(LT_PlayerLootTable[player_name]) do
            if (LT_LootTable[lootid]["spec"] == loot_types[loot_type] or loot_type == "All") and LT_Loot_Filter(LT_LootTable[lootid]) then
                num_loots = num_loots + 1;
            end
        end
	else
		if (player_name == nil) then
			for _, loot in pairs(LT_LootTable) do
				if (loot["spec"] == loot_types[loot_type] or loot_type == "All") and LT_Loot_Filter(loot) then
					num_loots = num_loots + 1;
				end
			end
		end
    end
    return num_loots;
end

function LT_Loot_SetFilter(filter)
	if (filter == nil or filter == "") then
		LT_Loot_FilterVal = nil;
        LT_Loot_FilterString = "";
	else
        LT_Loot_FilterString = filter;
        LT_Loot_FilterVal = { strsplit(" ", filter) };
        for i=1,#LT_Loot_FilterVal do
            LT_Loot_FilterNeg[i] = false;
            if (string.sub(LT_Loot_FilterVal[i], 1, 1) == "!") then
                LT_Loot_FilterVal[i] = LT_Loot_FilterVal[i]:sub(2);
                LT_Loot_FilterNeg[i] = true;
            end
            LT_Loot_FilterVal[i] = LT_Loot_FilterVal[i]:lower();
        end
    end
    LT_Loot_OnChange();
end

function LT_Loot_Filter(loot)
	if (LT_Loot_FilterVal == nil) then
		return 1;
	end
	local filter = LT_Loot_FilterVal;
	local types = {"Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact"};

	for i=1,#filter do
		local token = LT_Loot_FilterVal[i];
        if (token ~= "" and GetItemInfo(loot.itemString)) then -- Catches the case where you've just typed !
            local name, _, rarity = GetItemInfo(loot.itemString);
            local ss = name.."|"..types[rarity+1].."|"..loot.player.."|"..loot.spec;
            rarity = types[rarity+1];
            if (string.find(ss:lower(), token)) then
                if (LT_Loot_FilterNeg[i] == true) then
                    return nil;
                end
            else
                if (LT_Loot_FilterNeg[i] == false) then
                    return nil;
                end
            end
         end
	end
	return 1;
end

function LT_Loot_GetLoots(player_name)
    local loots = {};
	if (player_name == nil) then
		for loot_id, loot in pairs(LT_LootTable) do
            --if LT_GetPlayerIndexFromName(loot.player) ~= nil and LT_Loot_Filter(loot) then
            if LT_Loot_Filter(loot) then
			    table.insert(loots, loot)
            end
		end
	elseif LT_PlayerLootTable[player_name] ~= nil then
        for lootid in pairs(LT_PlayerLootTable[player_name]) do
			if LT_Loot_Filter(LT_LootTable[lootid]) then
            	table.insert(loots, LT_LootTable[lootid]);
			end
        end
    end
    return loots;
end

function LT_Loot_ToggleSpec(loot_id, dir)
    local loot_types = LT_Loot_LootTypes;
    local cur_type = 1;
    for i = 1, #loot_types do
        if (loot_types[i] == LT_LootTable[loot_id].spec) then
            cur_type = i;
        end
    end
	if (dir == 1) then
    	cur_type = mod(cur_type, #loot_types) + 1;
	else
		cur_type = mod(cur_type-2+#loot_types, #loot_types) + 1;
	end
    LT_LootTable[loot_id].spec = loot_types[cur_type];
    
    LT_Loot_OnChange();
end

-- This function should be called whenever the list of loot changes.
-- It will call the appropriate refresh functions.
function LT_Loot_OnChange()
    LT_AllLoot:UpdateFrame();
    LT_Char_UpdateFrame();
    LT_RedrawPlayerList();
end

function LT_Loot_SaveSpec(player, item, spec)

    if (LT_Loot_SavedSpecs[player] == nil) then
        LT_Loot_SavedSpecs[player] = {};
    end
    if (string.lower(spec) == "main") then
        spec = "Main";
    elseif (string.lower(spec) == "alt") then
        spec = "Alt";
    elseif (string.lower(spec) == "off") then
        spec = "Off";
    end
    
    LT_Loot_SavedSpecs[player][item] = spec;
end

LT_LootFrame:SetScript("OnEvent", Loot_OnEvent);
LT_LootFrame:RegisterEvent("CHAT_MSG_LOOT");
LT_LootFrame:RegisterEvent("VARIABLES_LOADED");

