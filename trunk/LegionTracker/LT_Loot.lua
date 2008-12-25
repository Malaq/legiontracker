LT_LootFrame = CreateFrame("Frame", "LegionTrackerLoot");
-- playername -> { {loot_ids}->1 }
LT_PlayerLootTable = {};
-- loot_id -> { ... }
LT_LootTable = {};
LT_UniqueLootId = 0;

LT_VarsLoaded = nil;


function LT_Loot_SlashHandler(args)
    LT_Print("Loot with args: "..args);
    if (string.find(args, " ") == nil) then
		LT_Print("lt loot reset");
		LT_Print("lt loot print loot");
		LT_Print("lt loot print players");
		return
	end

	local cmd = string.sub(args, string.find(args, " ")+1);
	LT_Print("Got command "..cmd);
	if cmd == "reset" then
		LT_PlayerLootTable = {};
		LT_LootTable = {};
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
		LT_LootTable[lootId]["zone"] = GetRealZoneText();
		LT_LootTable[lootId]["subzone"] = GetSubZoneText();
        LT_LootTable[lootId]["lootId"] = lootId;

        LT_RedrawPlayerList();
	end
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
    if LT_PlayerLootTable[player_name] ~= nil then
        for lootid in pairs(LT_PlayerLootTable[player_name]) do
            if LT_LootTable[lootid]["spec"] == loot_types[loot_type] or loot_type == "All" then
                num_loots = num_loots + 1;
            end
        end
    end
    return num_loots;
end

function LT_Loot_GetLoots(player_name)
    local loots = {};
	if (player_name == nil) then
		for loot_id, loot in pairs(LT_LootTable) do
            if LT_GetPlayerIndexFromName(loot.player) ~= nil then
			    table.insert(loots, loot)
            end
		end
	elseif LT_PlayerLootTable[player_name] ~= nil then
        for lootid in pairs(LT_PlayerLootTable[player_name]) do
            LT_LootTable[lootid].lootId = lootid; -- Going to save this value from now on, but in some old stuff it wasn't there.
            table.insert(loots, LT_LootTable[lootid]);
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
end

LT_LootFrame:SetScript("OnEvent", Loot_OnEvent);
LT_LootFrame:RegisterEvent("CHAT_MSG_LOOT");
LT_LootFrame:RegisterEvent("VARIABLES_LOADED");

