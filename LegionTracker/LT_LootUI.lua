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
							return { r = 1.0, g = 0.1, b = 0.1};
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
						local types = {"Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact"};
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
					value = ""
				}
			}
		};	
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
	self.st:SortData();
end

function LT_LootUI:OnClick(row_frame, cell_frame, data, cols, row, realrow, column, mouse_button)
	if (column == 5 and realrow ~= nil) then
		if (mouse_button == "LeftButton") then
			LT_Loot_ToggleSpec(self.loots[realrow].lootId, 1);
		else
			LT_Loot_ToggleSpec(self.loots[realrow].lootId, -1);
		end
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
end

function LT_LootUI:OnLeave(row_frame, cell_frame, data, cols, row, realrow, column)
	GameTooltip:Hide();
end

function LT_LootUI:CompareDates(cella, cellb, col)
	local column = self.st.cols[col];
	local direction = column.sort or column.defaultsort or "asc";
	local a1 = self.loots[cella].time;
	local b1 = self.loots[cellb].time;
	if direction:lower() == "asc" then
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
	table.insert(cols, {name="Item", width=parent:GetWidth()*0.25, align="LEFT"});
	table.insert(cols, {name="Zone", width=parent:GetWidth()*0.25, align="LEFT"});
	table.insert(cols, {name="Time", width=parent:GetWidth()*0.13, align="LEFT", sort="asc", comparesort=function(cella, cellb, col)
		return LT_LootUI:CompareDates(cella, cellb, col);
	end});
	table.insert(cols, {name="Player", width=parent:GetWidth()*0.13, align="LEFT"});
	table.insert(cols, {name="Spec", width=parent:GetWidth()*0.10, align="LEFT", bgcolor={r=0.2, g=0.2, b=0.25}});
	table.insert(cols, {name="Rarity", width=parent:GetWidth()*0.09, align="LEFT"});
	table.insert(cols, {name="", width=parent:GetWidth()*0.05, align="LEFT"});
	local num_rows = math.floor(parent:GetHeight() / 12) - 1;
	local st = ScrollingTable:CreateST(cols, num_rows, 12, {r=0.3, g=0.3, b=0.4}, parent);

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

