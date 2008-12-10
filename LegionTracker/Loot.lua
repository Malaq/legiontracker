lootFrame = CreateFrame("Frame", "LegionTrackerLoot");
-- playername -> { loot_ids }
playerLootTable = {};
-- loot_id -> { ... }
lootIdTable = {};


function Print(text)
	DEFAULT_CHAT_FRAME:AddMessage(text, 1, 1, 0);
end

function Loot_OnEvent(this, event, arg1)
	if event == "CHAT_MSG_LOOT" then
		local player = "Happyduude";
		local name, link, rarity = GetItemInfo(string.sub(arg1, string.find(arg1, "|c.*|r")));
		local _, color, itemString = strsplit("|", link);
		Print(string.format("Item string: %s", itemString));
		Print(string.format("Item link: %s", link));
		local _, itemId = strsplit(":", itemString);
		Print(string.format("Item id: %d  item name: %s", itemId, name));


		if (playerLootTable[player] == nil) then
			playerLootTable[player] = {};
		end

		playerLootTable[player][itemId] = 1;

		for key, value in pairs(playerLootTable[player]) do
			Print(string.format("key: %d  value: %d", key, value));
		end
	end
end

lootFrame:SetScript("OnEvent", Loot_OnEvent);
lootFrame:RegisterEvent("CHAT_MSG_LOOT");

