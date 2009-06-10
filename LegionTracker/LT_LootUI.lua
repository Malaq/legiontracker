LT_LootUI = {};

function LT_LootUI:CreateRow(id)
	local row = _G["LT_LootUIRow_"..id];
	if (row == nil) then
		row = {
			["cols"] = {
				{ 
					value = function() 
						local _, link = GetItemInfo(self.loots[id].itemString);
						return link;
					end
				},

				{
					value = function()
						local ret = self.loots[id].zone;
						if (self.loots[id].subzone ~= "") then
							ret = ret.." - "..self.loots[id].subzone;
						end
						return ret;
					end,
					color = {r = 0.4, g = 0.7, b = 0.9}
				},

				{
					value = function()
						return date("%b %d %H:%M", self.loots[id].time);
					end,
				},

				{
					value = function()
						return self.loots[id].player;
					end,
					color = function()
						local _, _, _, _, class = GetGuildRosterInfo(LT_GetPlayerIndexFromName(self.loots[id].player));
						return LT_GetClassColor(class);
					end
				},

				{
					value = function()
						return self.loots[id].spec;
					end,
					color = function()
						if (self.loots[id].spec == "Unassigned") then
							return { r = 0.8, g = 0.1, b = 0.1};
						elseif (self.loots[id].spec == "Main") then
							return { r = 0.9, g = 0.9, b = 1.0};
						elseif (self.loots[id].spec == "DE'd") then
							return { r = 0.4, g = 1.0, b = 0.4};
						elseif (self.loots[id].spec == "Alt") then
							return { r = 0.7, g = 0.7, b = 0.7};
						elseif (self.loots[id].spec == "Off") then
							return { r = 0.7, g = 0.7, b = 0.4};
						end
					end
				},

				{
					value = function()
						local types = {"Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact", "Heirloom"};
						local _, _, rarity = GetItemInfo(self.loots[id].itemString);
						return types[rarity+1];
					end,
					color = function()
						local _, _, rarity = GetItemInfo(self.loots[id].itemString);
						local cr, cg, cb = GetItemQualityColor(rarity);
						return {r = cr, g = cg, b = cb};
					end
				},

				{
					value = "X"
				}
			}
		};	
		_G["LT_LootUIRow_"..id] = row;
	end
	return row;
end

function LT_LootUI:UpdateFrame(player)
	self.loots = LT_Loot_GetLoots(player);
	self.data_table = {};
	self.player = player;
	for i = 1, #self.loots do
		table.insert(self.data_table, self:CreateRow(i));	
	end

	self.st:SetData(self.data_table);
end

function LT_LootUI:OnClick(row_frame, cell_frame, data, cols, row, realrow, column, mouse_button)
	if (column == 5 and realrow ~= nil) then
		if (mouse_button == "LeftButton") then
			LT_Loot_ToggleSpec(self.loots[realrow].lootId, 1);
		else
			LT_Loot_ToggleSpec(self.loots[realrow].lootId, -1);
		end
	elseif (column == 4 and realrow) then
        LT_PlayerSelect:Show(self.loots[realrow].player, self.loots[realrow].lootId);
    elseif (column == 7 and realrow) then
		  local _, item_link = GetItemInfo(self.loots[realrow].itemString);
        StaticPopupDialogs["Delete Item"] = {
        text = "LegionTracker: You are about to delete: "..item_link..", are you sure?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
				local loot_id = self.loots[realrow].lootId;
            LT_LootTable[loot_id] = nil;
				LT_PlayerLootTable[self.player][loot_id] = nil;
				LT_Loot_OnChange();
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
        };
        StaticPopup_Show("Delete Item");
    end
end

function LT_LootUI:OnEnter(row_frame, cell_frame, data, cols, row, realrow, column)
	if (column == 1 and realrow ~= nil) then
		GameTooltip:ClearAllPoints();
		GameTooltip:SetPoint("CENTER", UIParent);
		GameTooltip:SetOwner(row_frame, "ANCHOR_CURSOR");
		GameTooltip:SetHyperlink(self.loots[realrow].itemString);
		GameTooltip:Show();
	else
		GameTooltip:Hide();
	end
    
    if (column == 4 and realrow) then
        cell_frame.text:SetText(">" .. cell_frame.text:GetText() .. "<");
        cell_frame.text:SetTextColor(1.0, 0, 1.0);
    elseif (column == 5 and realrow) then
        cell_frame.text:SetTextColor(1.0, 0, 1.0);
    end
end

function LT_LootUI:OnLeave(row_frame, cell_frame, data, cols, row, realrow, column)
	GameTooltip:Hide();
    if (column == 4 and realrow) then
        self.st:Refresh();
    end
    if (column == 5 and realrow) then
        self.st:Refresh();
    end
end

function LT_LootUI:CompareDates(cella, cellb, col)
	local column = self.st.cols[col];
	local direction = column.sort or column.defaultsort or "asc";
	local a1 = self.loots[cella].time;
	local b1 = self.loots[cellb].time;
    -- The table tends to screw up with non-unique sorts, and everything else relies on unique date sorting
    -- to fix that... so make sure dates are uniquely sorted.
    if (a1 == b1) then
        a1 = self.loots[cella].lootId;
        b1 = self.loots[cellb].lootId;
    end
	if direction:lower() == "asc" then
		return a1 > b1;
	else
		return a1 < b1;
	end
end

function LT_LootUI:CompareItems(cella, cellb, col)
	local column = self.st.cols[col];
	local direction = column.sort or column.defaultsort or "asc";
	local a1 = GetItemInfo(self.loots[cella].itemString);	
	local b1 = GetItemInfo(self.loots[cellb].itemString);	
	if direction:lower() == "asc" then
		return a1 > b1;
	else
		return a1 < b1;
	end
end

function LT_LootUI:CompareRarity(cella, cellb, col)
    local column = self.st.cols[col];
	local direction = column.sort or column.defaultsort or "asc";
	local _, _, a1 = GetItemInfo(self.loots[cella].itemString);	
	local _, _, b1 = GetItemInfo(self.loots[cellb].itemString);
    if (a1 == b1) then
        return self.st:CompareSort(cella, cellb, col);
    elseif direction:lower() == "asc" then
        return a1 > b1;
    else
        return a1 < b1;
    end
end

function LT_LootUI:SetParent(parent)
	if (parent ~= UIParent) then
		self.st.frame:ClearAllPoints();
		self.st.frame:SetAllPoints(parent);
	else
        self.st:SetWidth(400);
        self.st:SetHeight(100);
    end
    self.st.frame:SetParent(parent);

end

function LT_LootUI:SetupFrame(parent)
    if (self.st ~= nil) then
        return
    end
	local cols = {};
	table.insert(cols, {name="Item", width=parent:GetWidth()*0.25, align="LEFT", sortnext=3, comparesort=function(cella, cellb, col)
		return LT_LootUI:CompareItems(cella, cellb, col);
	end});
	table.insert(cols, {name="Zone", width=parent:GetWidth()*0.25, align="LEFT", sortnext=3});
	table.insert(cols, {name="Time", width=parent:GetWidth()*0.13, align="LEFT", sort="asc", comparesort=function(cella, cellb, col)
		return LT_LootUI:CompareDates(cella, cellb, col);
	end});
	table.insert(cols, {name="Player", width=parent:GetWidth()*0.13, align="LEFT", sortnext=3});
	table.insert(cols, {name="Spec", width=parent:GetWidth()*0.10, align="LEFT", bgcolor={r=0.2, g=0.2, b=0.25}, sortnext=3});
	table.insert(cols, {name="Rarity", width=parent:GetWidth()*0.09, align="LEFT", sortnext=3, comparesort=function(cella, cellb, col)
        return LT_LootUI:CompareRarity(cella, cellb, col);
    end});
	table.insert(cols, {name="", width=parent:GetWidth()*0.05, align="LEFT", sortnext=3});
	local num_rows = math.floor(parent:GetHeight() / 15) - 1;
	local st = ScrollingTable:CreateST(cols, num_rows, 15, {r=0.3, g=0.3, b=0.4}, parent);

	self.data_table = {};
	st:SetData(self.data_table);

	st:Refresh();
	self.st = st;
    
    self:SetParent(parent);

	st:RegisterEvents({
		OnClick = function(...)
			LT_LootUI:OnClick(...)
			LT_LootUI:UpdateFrame(self.player);
		end,
		OnEnter = function(...)
			LT_LootUI:OnEnter(...);
		end,
		OnLeave = function(...)
			LT_LootUI:OnLeave(...);
		end
	});
end

