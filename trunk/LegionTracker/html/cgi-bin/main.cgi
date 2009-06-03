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
	if ($attendance > 85) {
		$attendance_type = 'high_attendance';
	} elsif ($attendance > 60) {
		$attendance_type = 'medium_attendance';
	} else {
		$attendance_type = 'low_attendance';
	}
	print "<TD class='$attendance_type' align=\"right\">$attendance</TD>";
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
my $database = 'legiontracker_tg';
my $username = 'legiontracker_tg';
my $password = 'legio3';
my $hostname = 'fdb1.awardspace.com';
my $dbport = '3306';

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

my $statement =
	$dbh->prepare(
	    "SELECT chr.NAME, chr.CLASS, chr.RANK, " .
            "IFNULL(7da.ATTENDANCE,'0') 7day,  " .
            "IFNULL(7dl.Main_Spec,0) 7MS,  " .
            "IFNULL(7dl.Alt_Spec,0) 7AS,  " .
            "IFNULL(7dl.Off_Spec,0) 7OS,  " .
            "IFNULL(30da.ATTENDANCE,'0') 30day,  " .
            "IFNULL(30dl.Main_Spec,0) 30MS,  " .
            "IFNULL(30dl.Alt_Spec,0) 30AS,  " .
            "IFNULL(30dl.Off_Spec,0) 30OS, " .
            "IFNULL(60da.ATTENDANCE,'0') 60day,  " .
            "IFNULL(60dl.Main_Spec,0) 60MS,  " .
            "IFNULL(60dl.Alt_Spec,0) 60AS,  " .
            "IFNULL(60dl.Off_Spec,0) 60OS " .
            "FROM `CHARACTER` chr " .
            " " .
            "LEFT JOIN " .
            "(select chr.char_id, " .
            "concat(floor((sum(length(REPLACE(ra.ATTENDANCE,'0','')))*100)/(sum(length(ra.ATTENDANCE)))),'%') ATTENDANCE, " .
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
            "concat(floor((sum(length(REPLACE(ra.ATTENDANCE,'0','')))*100)/(sum(length(ra.ATTENDANCE)))),'%') ATTENDANCE, " .
            "concat(concat(sum(length(REPLACE(ra.ATTENDANCE, '0', ''))),'/'),sum(length(ra.ATTENDANCE))) val " .
            "from RAID_ATTENDANCE ra, RAID_CALENDAR rc, `CHARACTER` chr " .
            "where ra.raid_id = rc.raid_id " . 
            "and chr.char_id = ra.char_id " .
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 30 DAY )) " .
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
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 30 DAY )) " . 
            "and rc.scheduled = 1  " .
            "group by chr.char_id) 30dl " .
            "ON 30dl.CHAR_ID = chr.CHAR_ID " .
            " " .
            "LEFT JOIN " .
            "(select chr.char_id, " .
            "concat(floor((sum(length(REPLACE(ra.ATTENDANCE,'0','')))*100)/(sum(length(ra.ATTENDANCE)))),'%') ATTENDANCE, " .
            "concat(concat(sum(length(REPLACE(ra.ATTENDANCE, '0', ''))),'/'),sum(length(ra.ATTENDANCE))) val " .
            "from RAID_ATTENDANCE ra, RAID_CALENDAR rc, `CHARACTER` chr " .
            "where ra.raid_id = rc.raid_id  " .
            "and chr.char_id = ra.char_id " .
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 60 DAY )) " .
            "and ra.ATTENDANCE Regexp '[[:digit:]]+' <> 0 " .
            "and rc.scheduled = 1 " .
            "group by chr.char_id) 60da " .
            "ON 60da.CHAR_ID = chr.CHAR_ID " .
            " " .
            "LEFT JOIN " .
            "(select chr.char_id, " .
            "IFNULL(sum(if(spec='Main', 1, 0)),0) Main_Spec,   " .
            "IFNULL(sum(if(spec='Alt', 1, 0)),0) Alt_Spec,   " .
            "IFNULL(sum(if(spec='Off', 1, 0)),0) Off_Spec  " .
            "from ITEMS_LOOTED il, RAID_CALENDAR rc, `CHARACTER` chr " . 
            "where chr.char_id = il.char_id  " .
            "and rc.raid_id = il.raid_id  " .
            "and rc.date >= DATE(DATE_SUB(LOCALTIME(),INTERVAL 60 DAY )) " . 
            "and rc.scheduled = 1  " .
            "group by chr.char_id) 60dl " .
            "ON 60dl.CHAR_ID = chr.CHAR_ID " .
            "WHERE chr.RANK not in ('Friend','Alt','Officer Alt', '') " . 
            "AND chr.DATE_REMOVED IS NULL " . 
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
<TH title=\"Main Spec Loot\"><U><B>MS</B></U></TH>
<TH title=\"Alternate Spec Loot\"><U><B>AS</B></U></TH>
<TH title=\"Off Spec Loot\"><U><B>OS</B></U></TH>
<TH><U><B>30 Day Attn</B></U></TH>
<TH title=\"Main Spec Loot\"><U><B>MS</B></U></TH>
<TH title=\"Alternate Spec Loot\"><U><B>AS</B></U></TH>
<TH title=\"Off Spec Loot\"><U><B>OS</B></U></TH>
<TH><U><B>60 Day Attn</B></U></TH>
<TH title=\"Main Spec Loot\"><U><B>MS</B></U></TH>
<TH title=\"Alternate Spec Loot\"><U><B>AS</B></U></TH>
<TH title=\"Off Spec Loot\"><U><B>OS</B></U></TH></TR>\n
</thead>
<tbody>
DELIMETER

	$statement->execute() or die $dbh->errstr;
	my $counter = 0;
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
		lootColor($row->{'7MS'});
		lootColor($row->{'7AS'});
		lootColor($row->{'7OS'});
		#30 day stats
		attendanceColor($row->{'30day'});
		lootColor($row->{'30MS'});
		lootColor($row->{'30AS'});
		lootColor($row->{'30OS'});
		#60 day stats
		attendanceColor($row->{'60day'});
		lootColor($row->{'60MS'});
		lootColor($row->{'60AS'});
		lootColor($row->{'60OS'});
		print "</TR>\n";
		$counter = $counter+1;
	}
	print "</TBODY>";
	print "<tfoot>";
	print "<TR>";
	print "<TD>";
	print "Total Raiders: $counter";
	print "</TD>";
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
