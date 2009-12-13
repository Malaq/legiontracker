#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

# For debug output
#print "<pre>";
#my $rowcolor = '#A69C8B';
my $rowcolor = '#463C2B';
#my $rowcolor = 'silver';

sub round {
    my($number) = shift;
    return int($number + .5);
}

#Class Coloring
sub classColor {
	my $tempclass = shift;
	my $classclr = 'black';
	#my $classbg = 'black';
	#my $classbg = '#867C6B';
	#my $classbg = 'silver';
	if ($tempclass eq 'Druid') {
		$classclr='#FF7D0A';
	} elsif ($tempclass eq 'Hunter') {
		$classclr='#ABD473';
	} elsif ($tempclass eq 'Mage') {
		$classclr='#69CCF0';
	} elsif ($tempclass eq 'Paladin') {
		$classclr='#F58CBA';
	} elsif ($tempclass eq 'Priest') {
		$classclr='#FFFFFF';
	} elsif ($tempclass eq 'Rogue') {
		$classclr='#FFF569';
	} elsif ($tempclass eq 'Shaman') {
		$classclr='#2459FF';
	} elsif ($tempclass eq 'Warlock') {
		$classclr='#9482C9';
	} elsif ($tempclass eq 'Warrior') {
		$classclr='#C79C6E';
	} elsif ($tempclass eq 'Death Knight') {
		$classclr='#C41F3B';
	}
	#print "<TD BGCOLOR=$rowcolor>";
	print "<TD>";
	print "<B>";
	print "<font color=$classclr>$tempclass</font>";
	print "</B>";
	print "</TD>";
}

#Attendance Coloring
sub attendanceColor {
	my $attendance = shift;
	my $attendance_type = '';
	if ($attendance > 84) {
		$attendance_type = 'high_attendance';
	} elsif ($attendance > 59) {
		$attendance_type = 'medium_attendance';
	} else {
		$attendance_type = 'low_attendance';
	}
	print "<TD class='$attendance_type' align=\"right\">$attendance%</TD>";
}

#Sitting Coloring
sub sittingColor {
	my $attendance = shift;
#	my $attendance_type = '';
#	if ($attendance > 84) {
#		$attendance_type = 'high_attendance';
#	} elsif ($attendance > 59) {
#		$attendance_type = 'medium_attendance';
#	} else {
#		$attendance_type = 'low_attendance';
#	}
	#print "<TD class='$attendance_type' align=\"right\">$attendance%</TD>";
	print "<TD class='sitting_neutral' align=\"right\">$attendance%</TD>";
}

#Loot Coloring
sub lootColor {
	my $temploot = shift;
	my $loot_type = '';
	my $bold1 = '';
	my $bold2 = '';
	if ($temploot > 0) {
		$loot_type='loot';
	} else {
		$loot_type='no_loot';
	}
	print "<TD class='$loot_type'>$temploot</TD>";
}

# Setup our DB connection
my $database = 'legion_lt';
my $username = 'legion_hermit';
my $password = 'mikey881!';
my $hostname = 'www.legiontracker.com';
my $dbport = '3306';

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

my $oldilevelmin = '';
my $oldilevelmax = '';
my $newilevelmin = '';
my $newilevelmax = '';

my $ilevelquery1 =
	$dbh->prepare(
		"SELECT LOOKUP_VALUE, LOOKUP_VALUE_2 " .
		"FROM LT_CONFIG_LOOKUPS " .
		"WHERE LOOKUP_NAME = 'OLD_TIER' " .
		"ORDER BY LOOKUP_VALUE;");

$ilevelquery1->execute() or die $dbh->errstr;
while (my $row = $ilevelquery1->fetchrow_hashref()) {
	$oldilevelmin = $row->{LOOKUP_VALUE};
	$oldilevelmax = $row->{LOOKUP_VALUE_2};
}

my $ilevelquery2 =
	$dbh->prepare(
		"SELECT LOOKUP_VALUE, LOOKUP_VALUE_2 " .
		"FROM LT_CONFIG_LOOKUPS " .
		"WHERE LOOKUP_NAME = 'NEW_TIER' " .
		"ORDER BY LOOKUP_VALUE;");

$ilevelquery2->execute() or die $dbh->errstr;
while (my $row = $ilevelquery2->fetchrow_hashref()) {
	$newilevelmin = $row->{LOOKUP_VALUE};
	$newilevelmax = $row->{LOOKUP_VALUE_2};
}



my $statement =
	$dbh->prepare(
	    "SELECT chr.NAME, chr.CLASS, chr.RANK, " .
            "IFNULL(7da.ATTENDANCE,'0') 7day,  " .
            "IFNULL(7da.SITTING,'0') 7sit,  " .
            "IFNULL(7dl.Main_Spec,0) 7MS,  " .
            "IFNULL(7dl.Alt_Spec,0) 7AS,  " .
            "IFNULL(7dl.Off_Spec,0) 7OS,  " .
            "IFNULL(30da.ATTENDANCE,'0') 30day,  " .
            "IFNULL(30da.SITTING,'0') 30sit,  " .
            "IFNULL(30dl.Main_Spec,0) 30MS,  " .
            "IFNULL(30dl.Alt_Spec,0) 30AS,  " .
            "IFNULL(30dl.Off_Spec,0) 30OS, " .
	    "IFNULL(tier_list.old_tier,0) old_tier, " .
	    "IFNULL(tier_list.new_tier,0) new_tier, " .
	    "IFNULL(tier_list.old_contested,0) old_contested, " .
	    "IFNULL(tier_list.new_contested,0) new_contested, " .
	    "IFNULL(tier_list.old_trophy,0) old_trophy, ".
	    "IFNULL(tier_list.new_trophy,0) new_trophy ".
            "FROM `CHARACTER` chr " .
            " " .
            "LEFT JOIN " .
            "(select chr.char_id, " .
            "floor((sum(length(REPLACE(ra.ATTENDANCE,'0','')))*100)/(sum(length(ra.ATTENDANCE)))) ATTENDANCE, " .
	    "floor(sum(length(REPLACE(REPLACE(ra.ATTENDANCE,'0',''),'1',''))*100)/(sum(length(ra.ATTENDANCE)))) SITTING, " .
            "concat(concat(sum(length(REPLACE(ra.ATTENDANCE, '0', ''))),'/'),sum(length(ra.ATTENDANCE))) val " .
            "from RAID_ATTENDANCE ra, RAID_CALENDAR rc, `CHARACTER` chr " .
            "where ra.raid_id = rc.raid_id  " .
            "and chr.char_id = ra.char_id " .
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 7 DAY )) " .
            "and ra.ATTENDANCE Regexp '[[:digit:]]+' <> 0 " .
            "and rc.scheduled = 1 " .
            "group by chr.char_id) 7da " .
            "ON 7da.CHAR_ID = chr.CHAR_ID " .
            " " .
            "LEFT JOIN " .
            "(select chr.char_id, " .
            "IFNULL(sum(if(spec='Main', 1, 0)),0) Main_Spec,   " .
            "IFNULL(sum(if(spec='Alt', 1, 0)),0) Alt_Spec,   " .
            "IFNULL(sum(if(spec='Off', 1, 0)),0) Off_Spec  " .
            "from ITEMS_LOOTED il, RAID_CALENDAR rc, `CHARACTER` chr " . 
            "where chr.char_id = il.char_id  " .
            "and rc.raid_id = il.raid_id  " .
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 7 DAY )) " . 
            "and rc.scheduled = 1  " .
            "group by chr.char_id) 7dl " .
            "ON 7dl.CHAR_ID = chr.CHAR_ID " .
            " " .
            "LEFT JOIN " .
            "(select chr.char_id, " .
            "floor((sum(length(REPLACE(ra.ATTENDANCE,'0','')))*100)/(sum(length(ra.ATTENDANCE)))) ATTENDANCE, " .
	    "floor(sum(length(REPLACE(REPLACE(ra.ATTENDANCE,'0',''),'1',''))*100)/(sum(length(ra.ATTENDANCE)))) SITTING, " .
            "concat(concat(sum(length(REPLACE(ra.ATTENDANCE, '0', ''))),'/'),sum(length(ra.ATTENDANCE))) val " .
            "from RAID_ATTENDANCE ra, RAID_CALENDAR rc, `CHARACTER` chr " .
            "where ra.raid_id = rc.raid_id " . 
            "and chr.char_id = ra.char_id " .
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 21 DAY )) " .
            "and ra.ATTENDANCE Regexp '[[:digit:]]+' <> 0 " .
            "and rc.scheduled = 1 " .
            "group by chr.char_id) 30da " .
            "ON 30da.CHAR_ID = chr.CHAR_ID " .
            " " .
            "LEFT JOIN " .
            "(select chr.char_id, " .
            "IFNULL(sum(if(spec='Main', 1, 0)),0) Main_Spec, " .  
            "IFNULL(sum(if(spec='Alt', 1, 0)),0) Alt_Spec, " .  
            "IFNULL(sum(if(spec='Off', 1, 0)),0) Off_Spec " . 
            "from ITEMS_LOOTED il, RAID_CALENDAR rc, `CHARACTER` chr " . 
            "where chr.char_id = il.char_id " . 
            "and rc.raid_id = il.raid_id " . 
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 21 DAY )) " . 
            "and rc.scheduled = 1  " .
            "group by chr.char_id) 30dl " .
            "ON 30dl.CHAR_ID = chr.CHAR_ID " .
            " " .
            "LEFT JOIN " .
	    "(select chr.char_id,   " .
	    "IFNULL(sum(if(spec='Main' and lcl.LOOKUP_NAME = 'NEW_TIER' AND it.ITEM_LEVEL BETWEEN lcl.LOOKUP_VALUE AND lcl.LOOKUP_VALUE_2, 1, 0)),0) New_Tier,  " .
	    "IFNULL(sum(if(spec='Main' and lcl.LOOKUP_NAME = 'NEW_TIER' AND it.ITEM_LEVEL BETWEEN lcl.LOOKUP_VALUE AND lcl.LOOKUP_VALUE_2 and it.ITEM_EQUIPLOC in ('INVTYPE_TRINKET','INVTYPE_NECK','INVTYPE_CLOAK','INVTYPE_FINGER'),1,0)),0) New_Contested,  " .
	    "IFNULL(sum(if(spec='Main' and lcl.LOOKUP_NAME = 'NEW_TIER' AND it.ITEM_NAME like '% Mark of Sanctification', 1, 0)),0) New_Trophy, " .
	    "IFNULL(sum(if(spec='Main' and lcl.LOOKUP_NAME = 'OLD_TIER' AND it.ITEM_LEVEL BETWEEN lcl.LOOKUP_VALUE AND lcl.LOOKUP_VALUE_2, 1, 0)),0) Old_Tier,  " .
	    "IFNULL(sum(if(spec='Main' and lcl.LOOKUP_NAME = 'OLD_TIER' AND it.ITEM_LEVEL BETWEEN lcl.LOOKUP_VALUE AND lcl.LOOKUP_VALUE_2 and it.ITEM_EQUIPLOC in ('INVTYPE_TRINKET','INVTYPE_NECK','INVTYPE_CLOAK','INVTYPE_FINGER'),1,0)),0) Old_Contested,  " .
	    "IFNULL(sum(if(spec='Main' and lcl.LOOKUP_NAME = 'OLD_TIER' and it.ITEM_NAME like 'Regalia of the%' or spec='Main' and lcl.LOOKUP_NAME = 'OLD_TIER' and it.ITEM_NAME = 'Trophy of the Crusade', 1, 0)),0) Old_Trophy " .
	    "from ITEMS_LOOTED il,   " .
	    "     RAID_CALENDAR rc,   " .
	    "		 `CHARACTER` chr,   " .
	    "		 ITEM it,   " .
	    "		 LT_CONFIG_LOOKUPS lcl  " .
    	    "where chr.char_id = il.char_id   " .
    	    "and rc.raid_id = il.raid_id  " .
    	    "and il.item_id = it.item_id  " .
    	    "and rc.scheduled = 1  " .
    	    "and lcl.GUILD_ID = 1  " .
    	    "group by chr.char_id) tier_list " .
	    "ON tier_list.CHAR_ID = chr.CHAR_ID " .
            "WHERE chr.RANK not in ('Friend','Alt','Officer Alt','P.U.G.', '') " . 
            "AND chr.DATE_REMOVED IS NULL " . 
	    "OR chr.RANK = 'Alt' " .
            "AND chr.DATE_REMOVED IS NULL " . 
	    "AND IFNULL(30dl.Main_Spec,0) > 0 " .
            "ORDER BY chr.NAME;");

		
#<TR>
#<TD colspan=\"3\">Character Data</TD>
#<TD colspan=\"4\">7 Day Data</TD>
#<TD colspan=\"4\">30 Day Data</TD>
#<TD colspan=\"4\">60 Day Data</TD>
#</TR>
	print <<DELIMETER;
<fieldset>
<legend><font color=white>Raiding Members</font></legend>
<form name=\"myform\" id=\"myform\" action=\"checkboxes.asp\" method=\"post\">
<script src=\"sorttable.js\"></script>\n
<TABLE class=\"sortable normal\" ALIGN=LEFT id=\"mainTable\">
<thead>
<TR>
<TH CLASS=\"sorttable_nosort\" style=\"display:none;\"><input type=\"checkbox\" id=\"checkall\" onclick=\"if(this.checked) checkAll(); else clearAll();\" /></TH>
<TH><U><B>Name</B></U></TH>
<TH><U><B>Class</B></U></TH>
<TH><U><B>Rank</B></U></TH>
<TH><U><B>7 Day Attn</B></U></TH>
<TH title=\"7 Day Benched %\"><U><B>Sit</B></U></TH>
<TH title=\"Main Spec Loot\"><U><B>MS</B></U></TH>
<TH title=\"Alternate Spec Loot\"><U><B>AS</B></U></TH>
<TH title=\"Off Spec Loot\"><U><B>OS</B></U></TH>
<TH><U><B>21 Day Attn</B></U></TH>
<TH title=\"21 Day Benched %\"><U><B>Sit</B></U></TH>
<TH title=\"Main Spec Loot\"><U><B>MS</B></U></TH>
<TH title=\"Alternate Spec Loot\"><U><B>AS</B></U></TH>
<TH title=\"Off Spec Loot\"><U><B>OS</B></U></TH>
<TH title=\" - \"><U><B> - </B></U></TH>
<TH title=\"New i-level\"><U><B>$newilevelmin-$newilevelmax</B></U></TH>
<TH title=\"Cloaks, Necks, Trinkets, Rings\"><U><B>C,N,T,R</B></U></TH>
<TH title=\"Trophies or Tier Pieces\"><U><B>Tier</B></U></TH>
<TH title=\"Old i-level\"><U><B>$oldilevelmin-$oldilevelmax</B></U></TH>
<TH title=\"Cloaks, Necks, Trinkets, Rings\"><U><B>C,N,T,R</B></U></TH>
<TH title=\"Trophies or Tier Pieces\"><U><B>Tier</B></U></TH>
</thead>
<tbody>
DELIMETER

	$statement->execute() or die $dbh->errstr;
	my $counter = 0;
	my $ms7d = 0;
	my $as7d = 0;
	my $os7d = 0;
	my $avg7d = 0;
	my $avg7sit= 0;
	my $ms30d = 0;
	my $as30d = 0;
	my $os30d = 0;
	my $avg30d = 0;	
	my $avg30sit= 0;
	my $old_tier_total = 0;
	my $new_tier_total = 0;
	my $old_contested_total = 0;
	my $new_contested_total = 0;
	my $old_trophy_count = 0;
	my $new_trophy_count = 0;
	while (my $row = $statement->fetchrow_hashref()) {
		#print "<TR onMouseOver=\"this.className='highlight'\" onMouseOut=\"this.className='normal'\" onclick=\"location.href='char.shtml?data=$row->{NAME}'\">";
		print "<TR id=\"check_$counter\" onClick=\"toggle($counter);\" onMouseOver=\"this.className='highlight'\" onMouseOut=\"mouseHighlight($counter);\">";
		#print "<TD><input name\"list[]\" id=\"$counter\" type=\"checkbox\" value=\"$counter\" onClick=\"highlightRow(this);\" /></TD>";
		print "<TD style=\"display:none;\"><input name\"list[]\" id=\"$counter\" type=\"checkbox\" value=\"$counter\" onClick=\"toggle($counter);\" /></TD>";
		print "<TD><B><A HREF=\"char.shtml?data=$row->{NAME}\" STYLE=\"text-decoration:none\" class='member_name'> $row->{NAME} </A></B></TD>";
		classColor($row->{CLASS});
		print "<TD class='rank'>$row->{RANK}</TD>";
		#7 day stats
		attendanceColor($row->{'7day'});
		sittingColor($row->{'7sit'});
		lootColor($row->{'7MS'});
		lootColor($row->{'7AS'});
		lootColor($row->{'7OS'});
		#30 day stats
		attendanceColor($row->{'30day'});
		sittingColor($row->{'30sit'});
		lootColor($row->{'30MS'});
		lootColor($row->{'30AS'});
		lootColor($row->{'30OS'});
		#Tiered Loot
		print "<TD> - </TD>";
		lootColor($row->{'new_tier'});
		lootColor($row->{'new_contested'});
		lootColor($row->{'new_trophy'});
		lootColor($row->{'old_tier'});
		lootColor($row->{'old_contested'});
		lootColor($row->{'old_trophy'});
		print "</TR>\n";
		$counter = $counter+1;
		$avg7d = $avg7d+$row->{'7day'};
		$avg7sit = $avg7sit+$row->{'7sit'};
		$ms7d = $ms7d+$row->{'7MS'};
		$as7d = $as7d+$row->{'7AS'};
		$os7d = $os7d+$row->{'7OS'};
		$avg30d = $avg30d+$row->{'30day'};	
		$avg30sit = $avg30sit+$row->{'30sit'};	
		$ms30d = $ms30d+$row->{'30MS'};
		$as30d = $as30d+$row->{'30AS'};
		$os30d = $os30d+$row->{'30OS'};
		$old_tier_total = $old_tier_total+$row->{'old_tier'};
		$old_contested_total = $old_contested_total+$row->{'old_contested'};
		$old_trophy_total = $old_trophy_total+$row->{'old_trophy'};
		$new_tier_total = $new_tier_total+$row->{'new_tier'};
		$new_contested_total = $new_contested_total+$row->{'new_contested'};
		$new_trophy_total = $new_trophy_total+$row->{'new_trophy'};
	}
	print "</TBODY>";
	$avg7d = round($avg7d/$counter);
	$avg7sit = round($avg7sit/$counter);
	$avg30d = round($avg30d/$counter);
	$avg30sit = round($avg30sit/$counter);
	print "<tfoot>";
	print "<TR>";
	print "<TD colspan=\"3\">";
	print "Total Raiders: $counter";
	print "</TD>";
	attendanceColor($avg7d);
	sittingColor($avg7sit);
	lootColor($ms7d);
	lootColor($as7d);
	lootColor($os7d);
	attendanceColor($avg30d);
	sittingColor($avg30sit);
	lootColor($ms30d);
	lootColor($as30d);
	lootColor($os30d);
	print "<TD> - </TD>";
	lootColor($new_tier_total);
	lootColor($new_contested_total);
	lootColor($new_trophy_total);
	lootColor($old_tier_total);
	lootColor($old_contested_total);
	lootColor($old_trophy_total);
	print "</TR>";
	print "</tfoot>";
	print "</TABLE>";
	#print "<script type=\"text/javascript\">";
	#print "var t = new ScrollableTable(document.getElementById('mainTable'),100);";
	#print "</script>";
	#print "<script type=\"text/javascript\">";
	#print "var t = new SortableTable(document.getElementById('mainTable'),100);";
	#print "</script>";
	#print "</fieldset>";
	print "<BR CLEAR=all>";
	print "<input type=\"button\" name=\"Compare\" value=\"Compare Selected\" onClick=\"hideUnchecked();\">";
	print "<BR>";
	print "<input type=\"button\" name=\"Select_All\" value=\"Select All\" onClick=\"checkAll();\">";
	print "<input type=\"button\" name=\"Show_All\" value=\"Reset\" onClick=\"showAll();\">";
	print "</form>";
	print "</fieldset>";
	$statement->finish();
$dbh->disconnect();
#print "</pre>";
