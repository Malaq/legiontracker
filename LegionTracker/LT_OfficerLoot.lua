LT_OfficerLoot = LibStub("AceAddon-3.0"):NewAddon("LT_OfficerLoot", "AceComm-3.0", "AceSerializer-3.0");
LT_OfficerLoot_AwardedItems = {};
LT_OfficerLoot_ZoneData = {};

-- TODO:
-- - Handle dust?
-- - Restrict to officers

-- Interesting data structures:
-- self.bids: Map from item names to a list of bid info tables
-- self.items: List of item (names) currently being bid for

function LT_OfficerLoot:OnLoad()
    LT_OfficerLoot_Frame:SetParent(UIParent);
    
    tinsert(UISpecialFrames, "LT_OfficerLoot_Frame");
    
    self.msg_channel = "RAID";
    self.msg_target = nil;
    
    self.vote_tooltip = CreateFrame("GameTooltip", "LT_VoteTooltip", UIParent, "GameTooltipTemplate");
    self.vote_tooltip:Hide();
    
    self.slots = 3;
    self.table_frames = {};
    self.table_labels = {};
    self.table_ids = {};
    self.tables = {};
    self.remove_buttons = {};
    self.award_buttons = {};
    _G["LT_OfficerLoot_TimeSpentCurLabel"]:SetText("");
    _G["LT_OfficerLoot_TimeSpentTotalLabel"]:SetText("");
    for i = 1, self.slots do
        table.insert(self.table_frames, _G["LT_OfficerLoot_TableFrame"..i]);
        table.insert(self.table_labels, _G["LT_OfficerLoot_Label"..i.."Label"]);
        table.insert(self.table_ids, _G["LT_OfficerLoot_TableId"..i.."Label"]);
        table.insert(self.remove_buttons, _G["LT_OfficerLoot_Remove"..i]);
        table.insert(self.award_buttons, _G["LT_OfficerLoot_Award"..i]);
        self.remove_buttons[i]:SetParent(self.table_frames[i]);
        self.award_buttons[i]:SetParent(self.table_frames[i]);
        
        _G["LT_OfficerLoot_Label"..i]:SetScript("OnEnter", function()
            local link = self.table_labels[i]:GetText();
            if (link and link ~= "") then
                GameTooltip:ClearAllPoints();
                GameTooltip:SetPoint("CENTER", UIParent);
                GameTooltip:SetOwner(LT_OfficerLoot_Frame, "ANCHOR_CURSOR");
                
                GameTooltip:SetHyperlink(link);
                GameTooltip:Show();
            end
        end);
        _G["LT_OfficerLoot_Label"..i]:SetScript("OnLeave", function()
            GameTooltip:Hide();
        end);
        
        -- Setup the tables
        local parent = self.table_frames[i];
        local cols = {}
        table.insert(cols, {name="Votes", width=parent:GetWidth()*0.1, align="LEFT", bgcolor = {r=0.12, g=0.12, b=0.15}});
        table.insert(cols, {name="Player", width=parent:GetWidth()*0.15, align="LEFT"});
        table.insert(cols, {name="Spec", width=parent:GetWidth()*0.1, align="LEFT"});
        table.insert(cols, {name="Replacing", width=parent:GetWidth()*0.25, align="LEFT"});
        table.insert(cols, {name="Comments", width=parent:GetWidth()*0.35, align="LEFT"});
        table.insert(cols, {name="", width=parent:GetWidth()*0.05, align="LEFT"});
        local num_rows = math.floor(self.table_frames[i]:GetHeight() / 15) - 1;
	    local st = ScrollingTable:CreateST(cols, num_rows, 15, {r=0.3, g=0.3, b=0.4}, self.table_frames[i]);
        st:SetData({});
        st.frame:ClearAllPoints();
        st.frame:SetAllPoints(parent);
        
        st:RegisterEvents({
            OnClick = function(...)
                LT_OfficerLoot:OnClick(i, ...);
            end,
            OnEnter = function(...)
                LT_OfficerLoot:OnEnter(i, ...);
            end,
            OnLeave = function(...)
                LT_OfficerLoot:OnLeave(i, ...);
            end
	    });
        table.insert(self.tables, st);
        
    end
    
    self:StartNewItems({}, {});
    LT_OfficerLoot_Frame:Hide();
    
    self.last_instructed = {};
    self.mode = "Master";
    
    self:RegisterComm("LT_OfficerLoot_Vote", "OnReceiveVote");
    self:RegisterComm("LT_OfficerLoot_Bid", "OnReceiveBid");
    self:RegisterComm("LT_OfficerLoot_Command", "OnReceiveCommand");
    
    self.inc_msg_ignore = {};
    self.out_msg_ignore = {};
    -- Hook into whispers so that we can hide things...
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(...)
        return LT_OfficerLoot:WhisperFilter(...);
    end);
    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(...)
        return LT_OfficerLoot:OutgoingWhisperFilter(...);
    end);
end

function LT_OfficerLoot:WhisperFilter(msg)
    if (self.inc_msg_ignore[msg]) then
        return true;
    end
end

function LT_OfficerLoot:OutgoingWhisperFilter(msg)
    if (self.out_msg_ignore[msg]) then
        return true;
    end
end

function LT_OfficerLoot:SendOfficerMessage(prefix, msg, channel)
    -- A hack to add whisper ids in...
    local _, cmd = self:Deserialize(msg);
    if (cmd.whisper_id == nil) then
        cmd.whisper_id = self.whisper_id;
    end
    msg = self:Serialize(cmd);
    
    if (channel == nil) then
        self:SendCommMessage(prefix, msg, self.msg_channel, self.msg_target);
    else
        self:SendCommMessage(prefix, msg, channel, self.msg_target);
    end
end

function LT_OfficerLoot:OnReceiveCommand(prefix, message, distr, sender)
    local success, cmd = self:Deserialize(message);
    if (success == false) then
        LT_Print("Error: received a bad command.  This shouldn't happen.");
        return;
    end
    
    if (cmd.type == "AwardItem") then
        Loot_OnEvent("AWARD", "CHAT_MSG_LOOT", cmd.message);
        if (LT_OfficerLoot_AwardedItems[cmd.pname] == nil) then
            LT_OfficerLoot_AwardedItems[cmd.pname] = {};
        end
        LT_OfficerLoot_AwardedItems[cmd.pname][cmd.iname] = 1;
    end
    
    if (cmd.type == "VersionCheck") then
        LT_Print(cmd.player.. " is running version check...", "yellow");
        local cmd = {type = "VersionResponse", version = LT_VERSION, player = UnitName("player"), target = cmd.player};
        self:SendOfficerMessage("LT_OfficerLoot_Command", LT_OfficerLoot:Serialize(cmd), "GUILD");
    end
    
    if (cmd.type == "VersionResponse") then
        --LT_Print("Version Response: from: "..cmd.player.." version: "..cmd.version.." LT_VERSION: " ..LT_VERSION);
        if (cmd.target ~= nil) then
            --LT_Print("Version Response: target="..cmd.target.." from: "..cmd.player.." version: "..cmd.version.." LT_VERSION: " ..LT_VERSION);
            if (cmd.target == UnitName("player")) then
                if (cmd.version == LT_VERSION) then
                    LT_Print(" "..cmd.player.. ": " ..cmd.version, "green");
                else
                    LT_Print(" "..cmd.player.. ": " ..cmd.version, "red");
                end
            end
        else
            --LT_Print(" * If you get this message, tell "..cmd.player.. " to upgrade from: " ..cmd.version);
            if (cmd.version == LT_VERSION) then
                LT_Print(" "..cmd.player.. ": " ..cmd.version, "green");
            else
                LT_Print(" "..cmd.player.. ": " ..cmd.version, "red");
            end
        end
    end
    
    if (cmd.type == "Start") then
        --LT_OfficerLoot_AwardedItems = {};
        LT_OfficerLoot_ZoneData = {};
        self.whisper_id = cmd.whisper_id;
        self:StartNewItems(cmd.items, cmd.item_links);
        LT_OfficerLoot_ZoneData["ZONE"] = cmd.real_zone;
        LT_OfficerLoot_ZoneData["SUBZONE"] = cmd.sub_zone;
    end
    
    if (self.whisper_id ~= cmd.whisper_id) then
        return
    end
    
    if (cmd.type == "Popup") then
        self:OnShow();
    elseif (cmd.type == "Remove") then
        for i = 1, #self.items do
            if (self.items[i] == cmd.name) then
                table.remove(self.item_links, i);
                table.remove(self.items, i);
                self:StartNewItems(self.items, self.item_links, true);
                self:Display();
                break;
            end
        end
    elseif (cmd.type == "Add") then
        local item, link = GetItemInfo(cmd.name);
        if (link) then
            table.insert(self.items, item);
            table.insert(self.item_links, link);
            self:StartNewItems(self.items, self.item_links, true);
            self:Display();
        end
    end
end

function LT_OfficerLoot:BroadcastNewItems(items, item_links)
    local cmd = {["type"] = "Start", ["items"] = items, ["item_links"] = item_links, ["whisper_id"] = time(), ["real_zone"] = GetRealZoneText(), ["sub_zone"] = GetSubZoneText()};
    self:SendOfficerMessage("LT_OfficerLoot_Command", self:Serialize(cmd));
end

function LT_OfficerLoot:ForcePopup()
    local cmd = {type = "Popup"};
    self:SendOfficerMessage("LT_OfficerLoot_Command", self:Serialize(cmd));
end

function LT_OfficerLoot:Remove(id, dust)
    local real_id = id + self.cur_id - 1;
    local item = self.items[real_id];
    local link = self.item_links[real_id];
    local cmd = {type = "Remove", name = item}; 
    self:SendOfficerMessage("LT_OfficerLoot_Command", self:Serialize(cmd));
    
    if (dust) then
        SendChatMessage("Dusting item: " ..link, "RAID");
    end
end

function LT_OfficerLoot:Add(item)
    LT_Print("Adding "..item);
    local cmd = {type = "Add", name = item};
    self:SendOfficerMessage("LT_OfficerLoot_Command", self:Serialize(cmd));
end

function LT_OfficerLoot:GetBestBid(id)
    local real_id = id + self.cur_id - 1;
    local item = self.items[real_id];
    local bids = self.bids[item];
    local bid; -- winner
    local best_votes = -1;
    for i = 1, #bids do
        local num_votes = LT_TableSize(bids[i].votes);
        if (num_votes > best_votes) then
            best_votes = num_votes;
            bid = bids[i];
        elseif (num_votes == best_votes) then
            bid = nil;
        end
    end
    
    return bid
end

function LT_OfficerLoot:CanAward(id)
    return self:GetBestBid(id) ~= nil;
end

function LT_OfficerLoot:Award(id)
    local bid = self:GetBestBid(id);
    local iname, link = GetItemInfo(bid.item);
    SendChatMessage("Grats to " .. bid.player .. " on " .. link .. " (" .. bid.spec .. " spec)", "RAID");
    LT_OfficerLoot:AwardItem(bid.player .. " receives loot: " .. link, bid.player,iname);
    self:Remove(id);
end

function LT_OfficerLoot:AwardItem(msg,player,item)
    local cmd = {type = "AwardItem", message = msg, pname = player, iname = item};
    self:SendOfficerMessage("LT_OfficerLoot_Command", self:Serialize(cmd));
end

function LT_OfficerLoot:OnReceiveVote(prefix, message, distr, sender)
    local success, vote = self:Deserialize(message);
    if (success == false) then
        LT_Print("Error: received a bad vote.  This shouldn't happen.");
        return;
    end
    
    if (self.whisper_id ~= vote.whisper_id) then
        return
    end
    
    if (self.bids[vote.item] == nil) then
        return
    end
    
    -- Remove any old votes from this person
    for i = 1, #self.bids[vote.item] do
        local bid = self.bids[vote.item][i];
        bid.votes[sender] = nil;
    end
    
    -- Add the vote in
    for i = 1, #self.bids[vote.item] do
        local bid = self.bids[vote.item][i];
        if (bid.player == vote.player) then
            bid.votes[sender] = 1;
        end
    end
    
    self:Display();
end


function LT_OfficerLoot:BroadcastVote(item, player)
    local vote = {};
    vote.item = item;
    vote.player = player;
    self:SendOfficerMessage("LT_OfficerLoot_Vote", self:Serialize(vote));
end



function LT_OfficerLoot:OnClick(table_id, row_frame, cell_frame, data, cols, row, realrow, column, btn)
    local bids = self.bids[self.items[table_id + self.cur_id - 1]];
    if (column == 1 and realrow ~= nil and bids[realrow] ~= nil) then
        if (btn == "LeftButton") then
            LT_OfficerLoot:BroadcastVote(self.items[table_id + self.cur_id - 1], bids[realrow].player);
        else
            LT_OfficerLoot:BroadcastVote(self.items[table_id + self.cur_id - 1], "");
        end
    end
end

function LT_OfficerLoot:OnEnter(table_id, row_frame, cell_frame, data, cols, row, realrow, column)
    local bids = self.bids[self.items[table_id + self.cur_id - 1]];
    if (column == 4 and realrow ~= nil and bids[realrow] ~= nil and GetItemInfo(bids[realrow].replacing)) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetPoint("CENTER", UIParent);
		GameTooltip:SetOwner(row_frame, "ANCHOR_CURSOR");
        local _, link = GetItemInfo(bids[realrow].replacing);
		GameTooltip:SetHyperlink(link);
		GameTooltip:Show();
	elseif (column == 1 and realrow ~= nil) then
        self.vote_tooltip:ClearAllPoints();
        self.vote_tooltip:SetPoint("CENTER", UIParent);
        self.vote_tooltip:SetOwner(row_frame, "ANCHOR_CURSOR");
        self.vote_tooltip:ClearLines();
        self.vote_tooltip:AddLine("Click to vote.  Right click to remove vote.");
        self.vote_tooltip:AddLine("Current votes:", 1, 1, 1);
        for person in pairs(bids[realrow].votes) do
            local color = LT_GetClassColorFromName(person);
            self.vote_tooltip:AddLine(person, color.r, color.g, color.b);
        end
        self.vote_tooltip:Show();
    elseif (column == 5 and realrow ~= nil) then
        --Hyjacking your vote_tooltip for use on comments
        self.vote_tooltip:ClearAllPoints();
        self.vote_tooltip:SetPoint("CENTER", UIParent);
        self.vote_tooltip:SetOwner(row_frame, "ANCHOR_CURSOR");
        self.vote_tooltip:ClearLines();
        local temp_comment = bids[realrow].comments;
        self.vote_tooltip:AddLine("Comment:");
        self.vote_tooltip:AddLine(temp_comment,1,1,1);
        self.vote_tooltip:Show();
    end
    
    
    if (column == 1 and realrow ~= nil) then
        cell_frame.text:SetText("+ " .. cell_frame.text:GetText());
        cell_frame.text:SetTextColor(0.0, 1.0, 0.0);
    end
end

function LT_OfficerLoot:OnLeave(table_id, row_frame, cell_frame, data, cols, row, realrow, column)
    GameTooltip:Hide();
    self.vote_tooltip:Hide();
    
    if (column == 1 and realrow ~= nil) then
        self.tables[table_id]:Refresh();
    end
end

function LT_OfficerLoot:SendInstructions(channel, player)
    local instructions = {
        "To bid for an item, send a tell in the following format:",
        "[Item],[Replacing], spec (main/alt/off), comments",
        "For example, if you want to bid for a Grim Toll, ",
        "You could send: \124cffa335ee\124Hitem:40256:0:0:0:0:0:0:0:0\124h[Grim Toll]\124h\124r,  \124cffa335ee\124Hitem:34472:0:0:0:0:0:0:0:0\124h[Shard of Contempt]\124h\124r, Main, best in slot"
    };
    
    for i = 1, #instructions do
        self:SendInvisChatMessage(instructions[i], channel, nil, player);
    end
end

function LT_OfficerLoot:OnReceiveBid(prefix, message, distr, sender)
    local success, bid = self:Deserialize(message);
    if (success == false) then
        LT_Print("Error: received a bad bid.  This shouldn't happy.");
        return;
    end
    
    if (self.whisper_id ~= bid.whisper_id) then
        return
    end
    
    local bids = self.bids[GetItemInfo(bid.item)];
    local repeated = false;
    for i = 1, #bids do
        if (bids[i].player == bid.player) then
            bids[i] = bid;
            repeated = true;
        end
    end
    if (repeated ~= true) then
        table.insert(self.bids[GetItemInfo(bid.item)], bid);
    end
    
    LT_Loot_SaveSpec(bid.player, GetItemInfo(bid.item), bid.spec);
    self:Display();
end

function LT_OfficerLoot:AddBid(item, player, spec, replacing, comments)
    local bid = {};
    bid.player = player;
    bid.replacing = replacing;
    bid.comments = comments;
    bid.spec = spec;
    bid.votes = {};
    bid.item = item;
    self:SendOfficerMessage("LT_OfficerLoot_Bid", self:Serialize(bid));
end

function LT_OfficerLoot:MungeItem(s)
    -- Look for an item link.
    if (s:sub(1,1) ~= "|") then
        return "", s;
    end
    local delim = s:find("|h|r") + 3;
    local itemlink = s:sub(1, delim);
    local _, item = GetItemInfo(itemlink);
    return item, s:sub(delim + 1);
end

function LT_OfficerLoot:MungeDelimeters(s)
    -- Remove the first block of non-alphanumeric characters.
    return s:gsub("^([ ,.;]+)","",1);
end

function LT_OfficerLoot:MungeSpec(s)
    local spec = s:gsub("(%w+).*", "%1"):lower();
    return spec, s:gsub("%w+(.*)", "%1");
end

function LT_OfficerLoot:OnEvent(event, arg1, arg2)
    if (event == "CHAT_MSG_WHISPER" and self.mode == "Master" and #self.items > 0) then
        if (arg1 == "!bid") then
            self:SendInstructions("WHISPER", arg2);
            LT_Print("Sent instructions to "..arg2);
            return;
        end
        
        local player = arg2;
        
        local item, replacing, spec, comments;
        msg = self:MungeDelimeters(arg1);
        item, msg = self:MungeItem(msg);
        msg = self:MungeDelimeters(msg);
        replacing, msg = self:MungeItem(msg);
        msg = self:MungeDelimeters(msg);
        spec, msg = self:MungeSpec(msg);
        msg = self:MungeDelimeters(msg);
        comments = msg;
        

        if (item == "") then
            -- Could send back an error message here... but if you aren't linking an item first,
            -- you're probably not bidding...
            return;
        end
        
        if (self.bids[GetItemInfo(item)] == nil) then
            SendChatMessage("Error: "..item.." isn't an item being bid on...", "WHISPER", nil, player);
            return;
        end

		-- This is a bit of a hack to get back the ability to put in nothing as a replacement item.
		-- It's somewhat ugly because you could end up eating the first comma in their comment.
		if (replacing == "main" or replacing == "alt" or replacing == "off") then
			comments = spec .. " " .. comments;
			spec = replacing;
			replacing = "";
		end
        
        if (spec ~= "main" and spec ~= "alt" and spec ~= "off") then
            SendChatMessage("Please specify a spec of 'Main', 'Alt', or 'Off' (instead of '" .. spec .."')", "WHISPER", nil, player);
            return;
        end
        
        self:AddBid(item, player, spec, replacing, comments);
        self.inc_msg_ignore[arg1] = 1;
        self:SendInvisChatMessage("Your bid for " .. item .. " was received successfully.", "WHISPER", nil, player);
    end
end

function LT_OfficerLoot:SendInvisChatMessage(msg, dist, lang, targ)
    self.out_msg_ignore[msg] = 1;
    SendChatMessage(msg, dist, lang, targ);
end


function LT_OfficerLoot:StartNewItems(items, item_links, dont_clear_bids)
    if (LT_OfficerLoot_TotalLootTime == nil) then
        -- So... I was going to make this a saved variable.  But the problem is, most people don't
        -- actually reset anything at the start of a raid night.  So this would accumulate forever.
        -- In the next version with timer sync'ing, we can save this and reset it on timer reset.
        LT_OfficerLoot_TotalLootTime = 0;
    end
        
    -- Setup the data structures
    if (self.cur_id == nil or dont_clear_bids == nil) then
        self.cur_id = 1;
    end
    self.item_links = item_links;
    self.items = items;
    
    if (self.bids == nil or dont_clear_bids == nil) then
        self.bids = {};
        self.inc_msg_ignore = {};
        self.out_msg_ignore = {};
    end
    
    for i = 1, #item_links do
        -- Do this to put everything into the local cache, so that all GetItemInfo calls work.
        GameTooltip:SetHyperlink(item_links[i]);
        GameTooltip:Hide();
        
        if (self.bids[self.items[i]] == nil or dont_clear_bids == nil) then
            self.bids[self.items[i]] = {};
        end
    end
    
    -- Setup the UI
    if (#item_links > self.slots) then
        LT_OfficerLoot_Slider:SetMinMaxValues(1, #item_links - self.slots + 1);
        LT_OfficerLoot_Slider:Show();
        LT_OfficerLoot_Up:Show();
        LT_OfficerLoot_Down:Show();
    else
        LT_OfficerLoot_Slider:SetValue(1);
        LT_OfficerLoot_Slider:Hide();
        LT_OfficerLoot_Up:Hide();
        LT_OfficerLoot_Down:Hide();
    end
    
    -- Deal with the loot timer
    if (dont_clear_bids == nil and #item_links > 0) then
        self.LootStartTime = time();
    end
    
    if (dont_clear_bids ~= nil and #item_links == 0 and self.LootStartTime) then
        local chg = time() - self.LootStartTime;
        LT_OfficerLoot_TotalLootTime = LT_OfficerLoot_TotalLootTime + chg;
        _G["LT_OfficerLoot_TimeSpentTotalLabel"]:SetText("(" .. self:TimeStr(LT_OfficerLoot_TotalLootTime) .. ")");
        _G["LT_OfficerLoot_TimeSpentCurLabel"]:SetText("");
        LT_Print("Time spent dealing with loot: "..self:TimeStr(chg));
    end
    
    self:Display();
end

function LT_OfficerLoot:TimeStr(seconds)
    local h = math.floor(seconds/3600);
    local m = math.floor(seconds/60)%60;
    local s = seconds%60;
    local str = "";
    if (h > 0) then
        str = str..h.."h";
    end
    if (m > 0) then
        str = str..m.."m";
    end
    str = str..s.."s";
    return str;
end

function LT_OfficerLoot:TimerUpdate()
    if (LT_OfficerLoot_Frame:IsShown() and self.LootStartTime and #self.items > 0) then
        _G["LT_OfficerLoot_TimeSpentCurLabel"]:SetText(self:TimeStr(time() - self.LootStartTime));
        -- _G["LT_OfficerLoot_TimeSpentTotalLabel"]:SetText(self:TimeStr(time() - self.LootStartTime + LT_OfficerLoot_TotalLootTime));
    end
end

function LT_OfficerLoot:OnShow()
    LT_OfficerLoot_Frame:SetFrameLevel(150);
    
    self:Display();
    LT_OfficerLoot_Frame:Show();
end

function LT_OfficerLoot:GetRow(bid)
    return {
        ["cols"] = {
            { 
                value = function()
                    local val = 0;
                    for a, b in pairs(bid.votes) do
                        val = val + 1;
                    end
                    return val;
                end,
                color = function()
                    if bid.votes[UnitName("player")] then
                        return {r = 0, g = 1, b = 1}
                    else
                        return {r = 1, g = 1, b = 1}
                    end
                end 
            },
            { value = bid.player, color = LT_GetClassColorFromName(bid.player) },
            { value = bid.spec },
            { value = bid.replacing },
            { value = bid.comments },
            { value = "" }
        }
    };
end

function LT_OfficerLoot:GetTable(item_id)
    local data = {};
    local bids = self.bids[self.items[item_id]];
    for i = 1, #bids do
        table.insert(data, self:GetRow(bids[i]));
    end
    return data;
end

function LT_OfficerLoot:Display()
    for i = 1, self.slots do
        local id = i + self.cur_id - 1;
        if id > #self.items then
            self.table_ids[i]:SetText("");
            self.table_labels[i]:SetText("");
            self.table_frames[i]:Hide();
        else
            self.table_ids[i]:SetText(string.format("Loot %d of %d", id, #self.items));
            self.table_labels[i]:SetText(self.item_links[id]);
            self.table_frames[i]:Show();
            self.tables[i]:SetData(self:GetTable(id));
            
            if (self:CanAward(i)) then
                self.award_buttons[i]:Enable();
            else
                self.award_buttons[i]:Disable();
            end
        end
    end
end

function LT_OfficerLoot:ScrollChanged()
    -- Check for self.slots to make sure we're initialized.
    if (self.slots) then
        self.cur_id = LT_OfficerLoot_Slider:GetValue();
        self:Display();
    end
end

function LT_OfficerLoot:ScrollDown()
    if (self.cur_id + self.slots <= #self.items) then
        LT_OfficerLoot_Slider:SetValue(LT_OfficerLoot_Slider:GetValue()+1);
    end
end

function LT_OfficerLoot:ScrollUp()
    if (self.cur_id > 1) then
        LT_OfficerLoot_Slider:SetValue(LT_OfficerLoot_Slider:GetValue()-1);
    end
end

function LT_OfficerLoot:ScrollWheel(dir)
    if (dir == -1) then
        LT_OfficerLoot:ScrollDown();
    else
        LT_OfficerLoot:ScrollUp();
    end
end
