LT_Table = {}
LT_Table.UniqueIndex = 0;

function LT_Table:MakeLabel(text, width, height, name)
    local label = CreateFrame("Button", name, UIParent);
    if (name != nil) then
        _G[name] = label;
    end
    
    label:SetWidth(width);
    label:SetHeight(height);
    label:ClearAllPoints();

    local font_string = label:CreateFontString("$parentText", "OVERLAY", "GameFontNormal");
    font_string:SetFont("Fonts\\FRIZQT__.TTF", 9);
    font_string:SetText(text);
    font_string:SetTextColor(0.8, 1.0, 0.8);
    label:SetFontString(font_string);
    
    return label;
end

function LT_Table:CreateTable(headers, rows, parent)
    local this = {};
    this.headers = headers;
    this.rows = rows;
    
    local frame = CreateFrame("ScrollFrame", "$parentScrollFrame"..LT_Table.UniqueIndex, parent, "FauxScrollFrameTemplate");
    LT_Table.UniqueIndex = LT_Table.UniqueIndex+1;
    this.frame = frame;
    
    return this;
end
LT_Table