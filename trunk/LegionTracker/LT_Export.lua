function LT_Export_OnShow()
    local export_label = getglobal("LT_Export".."ExportTextWindow");
    export_label:SetText("");
    --use pipe delimiters \n is return
    local count = 0;
    SortGuildRoster("name");
    local guildCount = GetNumGuildMembers(true);
    for i = 1, guildCount do 
        local name, rank, _, level, class, _, _, onote = GetGuildRosterInfo(i);
        export_label:Insert(name.."|"..rank.."|"..level.."|"..class.."|"..onote.."|".."\n");
    end
end