function LT_Export_OnShow()
    local export_label = getglobal("LT_Export".."ExportTextWindow".."Edit");
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
            local itemName = GetItemInfo(item);
            local _, blizItemId = strsplit(":",item);
            
            --export_label:Insert("<"..itemName..";"..blizItemId..";"..spec..";"..ltime..";"..zone..";"..subzone..">");
            export_label:Insert("$"..name..";"..itemName..";"..blizItemId..";"..ltime..";"..spec..";"..zone..";"..subzone.."\n");
        end
        --export_label:Insert("\n");
    end
end
