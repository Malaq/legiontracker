LootFrame = CreateFrame("Frame", "LegionTrackerLoot");

function Print(text)
	DEFAULT_CHAT_FRAME:AddMessage(text, 1, 1, 0);
end

function Loot_OnEvent(this, event, arg1)
	if event == "CHAT_MSG_LOOT" then
		Print(string.format("%s", string.sub(arg1, string.find(arg1, "|c.*|r"))));
	end
end

LootFrame:SetScript("OnEvent", Loot_OnEvent);
LootFrame:RegisterEvent("CHAT_MSG_LOOT");

