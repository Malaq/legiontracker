function LT_Export_OnShow()
    local export_label = getglobal("LT_Export".."ExportTextWindow".."Edit");
    export_label:SetText("");
    LT_Export:SetFrameLevel(100);
    --use pipe delimiters \n is return
    local count = 0;
    SortGuildRoster("name");
    local guildCount = GetNumGuildMembers(true);
    for i = 1, guildCount do 
        local name, rank, _, level, class, _, _, onote = GetGuildRosterInfo(i);
        export_label:Insert(name..";"..rank..";"..level..";"..class..";"..onote..";");
        --local line = name..";"..rank..";"..level..";"..class..";"..onote..";";
        local LT_Char_Loots = LT_Loot_GetLoots(name);
        local NumEntries = #LT_Char_Loots;
        for i=1, NumEntries do
            local item = LT_Char_Loots[i]["itemString"];
            local ltime = LT_Char_Loots[i]["time"];
            --local player = LT_LootTable[i]["player"];
            local spec = LT_Char_Loots[i]["spec"];
            local zone = LT_Char_Loots[i]["zone"];
            local subzone = LT_Char_Loots[i]["subzone"];
            local itemName = GetItemInfo(item);
            local _, blizItemId = strsplit(":",item);
            
            export_label:Insert("<"..itemName..";"..blizItemId..";"..spec..";"..ltime..";"..zone..";"..subzone..">");
            --local line = line.."<"..itemName..";"..blizItemId..";"..spec..";"..ltime..";"..zone..";"..subzone..">";
        end
        --local line = line.."\n";
        export_label:Insert("\n");
    end
end
