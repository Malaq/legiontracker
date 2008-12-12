LT_Char_CurPlayer = nil;
function LT_Char_ShowPlayer(name)
    if (name == LT_Char_CurPlayer) then
        LT_Char:Hide();
        LT_Char_CurPlayer = nil;
        return
    end
    LT_Char_CurPlayer = name;
    LT_Char:Show();
    LT_Loot_Messages:Clear();
    if (LT_PlayerLootTable[name] == nil) then
        return
    end
    
    for lootid in pairs(LT_PlayerLootTable[name]) do
        local _, link = GetItemInfo(LT_LootTable[lootid]["itemString"]);
        LT_Loot_Messages:AddMessage(link.." "..LT_LootTable[lootid]["zone"]);
    end
end