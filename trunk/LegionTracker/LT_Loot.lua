LT_LootFrame = CreateFrame("Frame", "LegionTrackerLoot");
-- playername -> { {loot_ids}->1 }
LT_PlayerLootTable = {};
-- loot_id -> { ... }
LT_LootTable = {};
LT_UniqueLootId = 0;

LT_VarsLoaded = nil;

function LT_Loot_SlashHandler(args)
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
		-- Remove receive* item, just for testing
		if (string.find(arg1, "receive loot:") or string.find(arg1, "receives loot:") or string.find(arg1, "receive* item")) then
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
		LT_LootTable[lootId]["time"] = time();
		LT_LootTable[lootId]["player"] = player;
		LT_LootTable[lootId]["spec"] = "Main";
		LT_LootTable[lootId]["zone"] = GetRealZoneText();
		LT_LootTable[lootId]["subzone"] = GetSubZoneText();


	end
end

LT_LootFrame:SetScript("OnEvent", Loot_OnEvent);
LT_LootFrame:RegisterEvent("CHAT_MSG_LOOT");
LT_LootFrame:RegisterEvent("VARIABLES_LOADED");

