LT_OfficerLoot = LibStub("AceAddon-3.0"):NewAddon("LT_OfficerLoot", "AceComm-3.0", "AceSerializer-3.0");

function LT_OfficerLoot:OnLoad()
    LT_OfficerLoot_Frame:SetParent(UIParent);

    self.slots = 3;
    self.table_frames = {};
    self.table_labels = {};
    self.table_ids = {};
    self.tables = {};
    for i = 1, self.slots do
        table.insert(self.table_frames, _G["LT_OfficerLoot_TableFrame"..i]);
        table.insert(self.table_labels, _G["LT_OfficerLoot_Label"..i.."Label"]);
        table.insert(self.table_ids, _G["LT_OfficerLoot_TableId"..i.."Label"]);
        
        _G["LT_OfficerLoot_Label"..i]:SetScript("OnEnter", function()
            local _, link = GetItemInfo(self.table_labels[i]:GetText() or "");
            if (link) then
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
        table.insert(cols, {name="Votes", width=parent:GetWidth()*0.1, align="LEFT"});
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
    
    self:StartNewItems({});
    LT_OfficerLoot_Frame:Hide();
    
    self.last_instructed = {};
    self.mode = "Master";
    
    self:RegisterComm("LT_OfficerLoot_Vote", "OnReceiveVote");
    self:RegisterComm("LT_OfficerLoot_Bid", "OnReceiveBid");
    self:RegisterComm("LT_OfficerLoot_Command", "OnReceiveCommand");
end

function LT_OfficerLoot:OnReceiveCommand(prefix, message, distr, sender)
    local success, cmd = self:Deserialize(message);
    if (success == false) then
        LT_Print("Error: received a bad command.  This shouldn't happen.");
        return;
    end
    
    if (cmd.type == "Start") then
        self:StartNewItems(cmd.items);
    elseif (cmd.type == "Popup") then
        self:OnShow();
    end
end

function LT_OfficerLoot:BroadcastNewItems(items)
    local cmd = {["type"] = "Start", ["items"] = items};
    self:SendCommMessage("LT_OfficerLoot_Command", self:Serialize(cmd), "RAID");
end

function LT_OfficerLoot:ForcePopup()
    local cmd = {type = "Popup"};
    self:SendCommMessage("LT_OfficerLoot_Command", self:Serialize(cmd), "RAID");
end

function LT_OfficerLoot:OnReceiveVote(prefix, message, distr, sender)
    local success, vote = self:Deserialize(message);
    if (success == false) then
        LT_Print("Error: received a bad vote.  This shouldn't happen.");
        return;
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
    self:SendCommMessage("LT_OfficerLoot_Vote", self:Serialize(vote), "RAID");
end



function LT_OfficerLoot:OnClick(table_id, row_frame, cell_frame, data, cols, row, realrow, column)
    local bids = self.bids[self.items[table_id + self.cur_id - 1]];
    if (column == 1 and realrow ~= nil and bids[realrow] ~= nil) then
        LT_OfficerLoot:BroadcastVote(self.items[table_id + self.cur_id - 1], bids[realrow].player);
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
	else
		GameTooltip:Hide();
	end
    
    if (column == 1 and realrow ~= nil) then
        cell_frame.text:SetText("+ " .. cell_frame.text:GetText());
        cell_frame.text:SetTextColor(0.0, 1.0, 0.0);
    end
end

function LT_OfficerLoot:OnLeave(table_id, row_frame, cell_frame, data, cols, row, realrow, column)
    GameTooltip:Hide();
    
    if (column == 1 and realrow ~= nil) then
        self.tables[table_id]:Refresh();
    end
end

function LT_OfficerLoot:SendInstructions(channel, player)
    local instructions = {
        "To bid for an item, send a tell in the following format:",
        "[Item], [Replacing], spec (main/alt/off), (short) comments",
        "For example, if you want to bid for a Grim Toll, you could send: ",
        "\124cffa335ee\124Hitem:40256:0:0:0:0:0:0:0:0\124h[Grim Toll]\124h\124r,  \124cffa335ee\124Hitem:34472:0:0:0:0:0:0:0:0\124h[Shard of Contempt]\124h\124r, Main, best in slot"
    };
    
    for i = 1, #instructions do
        SendChatMessage(instructions[i], channel, nil, player);
    end
end

function LT_OfficerLoot:OnReceiveBid(prefix, message, distr, sender)
    local success, bid = self:Deserialize(message);
    if (success == false) then
        LT_Print("Error: received a bad bid.  This shouldn't happy.");
        return;
    end
    table.insert(self.bids[GetItemInfo(bid.item)], bid);
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
    self:SendCommMessage("LT_OfficerLoot_Bid", self:Serialize(bid), "GUILD");
end

function LT_OfficerLoot:OnEvent(event, arg1, arg2)
    if (event == "CHAT_MSG_WHISPER" and self.mode == "Master") then
        local player = arg2;
        local msg = { strsplit(",", arg1) };
        -- Format: [item], [replacing], spec, comments
        -- replacing can be blank, comments are optional
        if (#msg < 3) then
            -- Is this a bid?  Probably not.
            return;
        end
        
        local _, item = GetItemInfo(strtrim(msg[1]));
        local _, replacing = GetItemInfo(strtrim(msg[2]));
        local spec = strlower(strtrim(msg[3]));
        local comments = msg[4];
        
        if (item == nil) then
            -- Could send back an error message here... but if you aren't linking an item first,
            -- you're probably not bidding...
            return;
        end
        
        if (self.bids[GetItemInfo(item)] == nil) then
            SendChatMessage(item.." isn't an item being bid on...", "WHISPER", nil, player);
            return;
        end
        
        if (spec ~= "main" and spec ~= "alt" and spec ~= "off") then
            SendChatMessage("Please specify a spec of 'Main', 'Alt', or 'Off' (instead of '" .. spec .."')", "WHISPER", nil, player);
            return;
        end
        
        if (replacing == nil) then
            replacing = "";
        end
        if (comments == nil) then
            comments = "";
        end
        for i = 5, #msg do
            comments = comments .. "," .. msg[i];
        end
        comments = strtrim(comments);
        self:AddBid(item, player, spec, replacing, comments);
        
    end
end


function LT_OfficerLoot:StartNewItems(item_links)
    self.cur_id = 1;
    self.item_links = item_links;
    self.items = {}
    self.bids = {};
    for i = 1, #item_links do
        local name = GetItemInfo(item_links[i]);
        table.insert(self.items, name);
        self.bids[self.items[i]] = {};
    end
    
    self:Display();
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
                    if bid.votes["Happyduude"] then
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
            self.table_ids[i]:SetText(string.format("%d/%d", id, #self.items));
            local _, link = GetItemInfo(self.item_links[id]);
            self.table_labels[i]:SetText(link);
            self.table_frames[i]:Show();
            self.tables[i]:SetData(self:GetTable(id));
        end
    end
end

function LT_OfficerLoot:ScrollDown()
    if (self.cur_id + self.slots <= #self.items) then
        self.cur_id = self.cur_id + 1;
        self:Display();
    end
end

function LT_OfficerLoot:ScrollUp()
    if (self.cur_id > 1) then
        self.cur_id = self.cur_id - 1;
        self:Display();
    end
end