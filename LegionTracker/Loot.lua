LT_LootFrame = CreateFrame("Frame", "LegionTrackerLoot");
-- playername -> { {loot_ids}->1 }
LT_PlayerLootTable = {};
-- loot_id -> { ... }
LT_LootTable = {};
LT_UniqueLootId = 0;

LT_VarsLoaded = nil;

function Print(text)
	DEFAULT_CHAT_FRAME:AddMessage(text, 1, 1, 0);
end

function Loot_OnEvent(this, event, arg1)
	if event == "VARIABLES_LOADED" then
		LT_VarsLoaded = 1;
	end

	if LT_VarsLoaded == nil then
		return
	end

	if event == "CHAT_MSG_LOOT" then
		local player = nil;
		-- Remove receive* item, just for testing
		if (string.find(arg1, "receive loot:") or string.find(arg1, "receives loot:") or string.find(arg1, "receive* item")) then
			player = string.sub(arg1, string.find(arg1, " receive"));	
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

		Print("Players:");
		for key, value in pairs(LT_PlayerLootTable[player]) do
			Print(string.format("key: %s  value: %s", key, value));
		end

		Print("__________________");
		Print("Loots:");
		for k1, v1 in pairs(LT_LootTable) do
			Print("*");
			for key, value in pairs(LT_LootTable[k1]) do
				Print(string.format("key: %s  value: %s", key, value));
			end
		end
	end
end

LT_LootFrame:SetScript("OnEvent", Loot_OnEvent);
LT_LootFrame:RegisterEvent("CHAT_MSG_LOOT");
LT_LootFrame:RegisterEvent("VARIABLES_LOADED");

