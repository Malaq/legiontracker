function LT_Export_OnShow()
    local export_label = _G["LT_Export".."ExportTextWindow".."Edit"];
    export_label:SetText("");
    LT_Export:SetFrameLevel(100);
    LT_Loot_SetFilter();
    --use pipe delimiters \n is return
    local count = 0;
    SortGuildRoster("name");
    local guildCount = GetNumGuildMembers(true);
    --date("%b %d %H:%M:%S", LT_Char_Loots[i].time);-
    export_label:Insert("#"..LT_RAID_NAME.."/1/"..LT_GetAttendees().."\n");
    for i = 1, guildCount do 
        local name, rank, _, level, class, _, _, onote = GetGuildRosterInfo(i);
        --export_label:Insert(name..";"..rank..";"..level..";"..class..";"..onote..";");
        export_label:Insert("@"..name..";"..class..";"..onote..";"..rank.."\n");
        local LT_Char_Loots = LT_Loot_GetLoots(name);
        local NumEntries = #LT_Char_Loots;
        for i=1, NumEntries do
            local item = LT_Char_Loots[i]["itemString"];
            local ltime = date("%Y-%m-%d %H:%M:%S", LT_Char_Loots[i].time);--LT_Char_Loots[i]["time"];
            --local player = LT_LootTable[i]["player"];
            local spec = LT_Char_Loots[i]["spec"];
            local zone = LT_Char_Loots[i]["zone"];
            local subzone = LT_Char_Loots[i]["subzone"];
            if (GetItemInfo(item) ~= nil) then
                local itemName, tempItemLink, rarity, iLevel, _, iType, iSubType, _, iEquipLoc = GetItemInfo(item);
                --local _, blizItemId = strsplit(":",item);
                local _, blizItemId = strsplit(":",tempItemLink);
                rarity = LT_Export_ConvertRarity(rarity);
                
                --export_label:Insert("$"..name..";"..itemName..";"..blizItemId..";"..ltime..";"..spec..";"..zone..";"..subzone..";"..rarity.."\n");
                export_label:Insert("$"..name..";"..itemName..";"..blizItemId..";"..ltime..";"..spec..";"..zone..";"..subzone..";"..rarity..";"..iLevel..";"..iType..";"..iSubType..";"..iEquipLoc.."\n");
            else
                LT_Print("ERROR DURING EXPORT!!! ITEM: "..item.." could not be extracted.","yellow");
            end
        end
        --export_label:Insert("\n");
    end

    --Handle unguilded chars
    local unguildedLoot = {};
    local LT_Char_Loots = {};
    for id, info in pairs(LT_LootTable) do
        if (info["spec"] ~= "Unassigned" and LT_NameLookup[info["player"]] == nil and unguildedLoot[info["player"]] == nil) then
        --if (LT_NameLookup[info["player"]] == nil and unguildedLoot[info["player"]] == nil) then
            --Make sure we dont record them twice
            unguildedLoot[info["player"]] = 1;
            --Get all their loots
            local LT_Char_Loots = LT_Loot_GetLoots(info["player"]);
            --Insert their player record
            --export_label:Insert("@"..info["player"]..";Unguilded;Friend;Friend\n");
            export_label:Insert("@"..info["player"]..";Unknown;P.U.G.;P.U.G.\n");
            --LT_Print("@"..info["player"]..";Unknown;Friend;Unguilded");
            --Insert their loot records
            for i=1, #LT_Char_Loots do
                local item = LT_Char_Loots[i]["itemString"];
                local ltime = date("%Y-%m-%d %H:%M:%S", LT_Char_Loots[i].time);--LT_Char_Loots[i]["time"];
                --local player = LT_LootTable[i]["player"];
                local spec = LT_Char_Loots[i]["spec"];
                local zone = LT_Char_Loots[i]["zone"];
                local subzone = LT_Char_Loots[i]["subzone"];
                if (GetItemInfo(item) ~= nil) then
                    local itemName, tempItemLink, rarity, iLevel, _, iType, iSubType, _, iEquipLoc = GetItemInfo(item);
                    --local itemName, _, rarity = GetItemInfo(item);
                    local _, blizItemId = strsplit(":",tempItemLink);
                    rarity = LT_Export_ConvertRarity(rarity);
                    if (spec ~= "Unassigned") then
                        --export_label:Insert("$"..info["player"]..";"..itemName..";"..blizItemId..";"..ltime..";"..spec..";"..zone..";"..subzone..";"..rarity.."\n");
                        export_label:Insert("$"..info["player"]..";"..itemName..";"..blizItemId..";"..ltime..";"..spec..";"..zone..";"..subzone..";"..rarity..";"..iLevel..";"..iType..";"..iSubType..";"..iEquipLoc.."\n");
                        --LT_Print("$"..info["player"]..";"..itemName..";"..blizItemId..";"..ltime..";"..spec..";"..zone..";"..subzone..";"..rarity);
                    end
                else
                    LT_Print("ERROR DURING EXPORT!!! ITEM: "..item.." could not be extracted.","yellow");
                end
            end
        end
    end
end

function LT_Export_ConvertRarity(value)
    if (value >= 0) and (value <=8) then
        local types = {"Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact", "Heirloom"};
        return types[value+1];
    else
        return "Unknown";
    end
end