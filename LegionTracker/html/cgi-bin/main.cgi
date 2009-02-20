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
	my $tempattn = shift;
	my $attnclr = 'black';
	if ($tempattn > 85) {
		$attnclr='green';
		#$attnclr='#ABD473';
	} elsif ($tempattn > 60) {
		$attnclr='yellow';
	} else {
		$attnclr='red';
	}
	#print "<TD BGCOLOR=$rowcolor>";
	print "<TD>";
	print "<font color=$attnclr>$tempattn</font>";
	print "</TD>";
}

#Loot Coloring
sub lootColor {
	my $temploot = shift;
	my $lootclr = 'black';
	my $bold1 = '';
	my $bold2 = '';
	if ($temploot > 0) {
		$lootclr='violet';
		$bold1='';
		$bold2='';
	} else {
		$lootclr='red';
		$bold1='';
		$bold2='';
	}
	print "<font color=$lootclr>$bold1$temploot$bold2</font>";
}

# Setup our DB connection
my $database = 'legiontracker_tg';
my $username = 'legiontracker_tg';
my $password = 'legio3';
my $hostname = 'fdb1.awardspace.com';
my $dbport = '3306';

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
print "<HTML>\n";

my $statement =
	$dbh->prepare("SELECT chr.NAME, chr.CLASS, chr.RANK, ".
			"IFNULL(7da.ATTENDANCE,'0') 7day, 7dl.7MS, 7dl.7AS, 7dl.7OS,  ".
			"IFNULL(30da.ATTENDANCE,'0') 30day, 30dl.30MS, 30dl.30AS, 30dl.30OS, ".
			"IFNULL(60da.ATTENDANCE,'0') 60day, 60dl.60MS, 60dl.60AS, 60dl.60OS ".
			"FROM `CHARACTER` chr ".
			" ".
			"LEFT JOIN ".
			"(SELECT e.CHAR_ID, concat( floor( (  ".
			"sum( length(  ".
			"REPLACE (  ".
			"ATTENDANCE, ".
			"'0', ".
			"'' ".
			") ) ) *100 ) / ( sum( length( ATTENDANCE ) ) ) ) , ".
			"'%' ".
			")ATTENDANCE ".
			"FROM (  ".
			"SELECT a.CHAR_ID, b.ATTENDANCE ".
			"FROM `CHARACTER` a, `RAID_ATTENDANCE` b, `RAID_CALENDAR` f ".
			"WHERE a.CHAR_ID = b.CHAR_ID ".
			"AND f.RAID_ID = b.RAID_ID ".
			"AND b.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '1', b.ATTENDANCE ) <>0 ".
			"AND f.SCHEDULED = 1 ".
			"AND f.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 8  ".
			"DAY ) )  ".
			"UNION  ".
			"SELECT c.CHAR_ID, d.ATTENDANCE ".
			"FROM `CHARACTER` c, `RAID_ATTENDANCE` d, `RAID_CALENDAR` g ".
			"WHERE c.CHAR_ID = d.CHAR_ID ".
			"AND d.RAID_ID = g.RAID_ID ".
			"AND d.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '0', d.ATTENDANCE ) <>0 ".
			"AND g.SCHEDULED = 1 ".
			"AND g.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 8  ".
			"DAY ) )  ".
			")e ".
			"GROUP BY e.CHAR_ID) 7da  ".
			"ON 7da.CHAR_ID = chr.CHAR_ID ".
			" ".
			"LEFT JOIN ".
			"(SELECT chr7dl.CHAR_ID, IFNULL( main_spec.ms_total, 0 ) 7MS, IFNULL( alt_spec.as_total, 0 ) 7AS, IFNULL( off_spec.os_total, 0 ) 7OS ".
			"FROM `CHARACTER` chr7dl ".
			"LEFT JOIN (  ".
			"SELECT ilm7.CHAR_ID, count( ilm7.ITEM_ID ) ms_total ".
			"FROM ITEMS_LOOTED ilm7, RAID_CALENDAR rci7 ".
			"WHERE ilm7.RAID_ID = rci7.RAID_ID ".
			"AND ilm7.SPEC = 'Main' ".
			"AND rci7.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 8 DAY ) )  ".
			"GROUP BY ilm7.CHAR_ID ".
			")main_spec ON main_spec.CHAR_ID = chr7dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ila7.CHAR_ID, count( ila7.ITEM_ID ) as_total ".
			"FROM ITEMS_LOOTED ila7, RAID_CALENDAR rci7 ".
			"WHERE ila7.RAID_ID = rci7.RAID_ID ".
			"AND ila7.SPEC = 'Alt' ".
			"AND rci7.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 8 DAY ) )  ".
			"GROUP BY ila7.CHAR_ID ".
			")alt_spec ON alt_spec.CHAR_ID = chr7dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ilo7.CHAR_ID, count( ilo7.ITEM_ID ) os_total ".
			"FROM ITEMS_LOOTED ilo7, RAID_CALENDAR rci7 ".
			"WHERE ilo7.RAID_ID = rci7.RAID_ID ".
			"AND ilo7.SPEC = 'Off' ".
			"AND rci7.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 8 DAY ) )  ".
			"GROUP BY ilo7.CHAR_ID ".
			")off_spec ON off_spec.CHAR_ID = chr7dl.CHAR_ID) 7dl  ".
			"ON 7dl.CHAR_ID = chr.CHAR_ID ".
			" ".
			"LEFT JOIN ".
			"(SELECT e.CHAR_ID, concat( floor( (  ".
			"sum( length(  ".
			"REPLACE (  ".
			"ATTENDANCE, ".
			"'0', ".
			"'' ".
			") ) ) *100 ) / ( sum( length( ATTENDANCE ) ) ) ) , ".
			"'%' ".
			")ATTENDANCE ".
			"FROM (  ".
			"SELECT a.CHAR_ID, b.ATTENDANCE ".
			"FROM `CHARACTER` a, `RAID_ATTENDANCE` b, `RAID_CALENDAR` f ".
			"WHERE a.CHAR_ID = b.CHAR_ID ".
			"AND f.RAID_ID = b.RAID_ID ".
			"AND b.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '1', b.ATTENDANCE ) <>0 ".
			"AND f.SCHEDULED = 1 ".
			"AND f.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 31  ".
			"DAY ) )  ".
			"UNION  ".
			"SELECT c.CHAR_ID, d.ATTENDANCE ".
			"FROM `CHARACTER` c, `RAID_ATTENDANCE` d, `RAID_CALENDAR` g ".
			"WHERE c.CHAR_ID = d.CHAR_ID ".
			"AND d.RAID_ID = g.RAID_ID ".
			"AND d.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '0', d.ATTENDANCE ) <>0 ".
			"AND g.SCHEDULED = 1 ".
			"AND g.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 31  ".
			"DAY ) )  ".
			")e ".
			"GROUP BY e.CHAR_ID) 30da ".
			"ON 30da.CHAR_ID = chr.CHAR_ID ".
			" ".
			"LEFT JOIN ".
			"(SELECT chr30dl.CHAR_ID, IFNULL( main_spec.ms_total, 0 ) 30MS, IFNULL( alt_spec.as_total, 0 ) 30AS, IFNULL( off_spec.os_total, 0 ) 30OS ".
			"FROM `CHARACTER` chr30dl ".
			"LEFT JOIN (  ".
			"SELECT ilm30.CHAR_ID, count( ilm30.ITEM_ID ) ms_total ".
			"FROM ITEMS_LOOTED ilm30, RAID_CALENDAR rci30 ".
			"WHERE ilm30.RAID_ID = rci30.RAID_ID ".
			"AND ilm30.SPEC = 'Main' ".
			"AND rci30.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 31 DAY ) )  ".
			"GROUP BY ilm30.CHAR_ID ".
			")main_spec ON main_spec.CHAR_ID = chr30dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ila30.CHAR_ID, count( ila30.ITEM_ID ) as_total ".
			"FROM ITEMS_LOOTED ila30, RAID_CALENDAR rci30 ".
			"WHERE ila30.RAID_ID = rci30.RAID_ID ".
			"AND ila30.SPEC = 'Alt' ".
			"AND rci30.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 31 DAY ) )  ".
			"GROUP BY ila30.CHAR_ID ".
			")alt_spec ON alt_spec.CHAR_ID = chr30dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ilo30.CHAR_ID, count( ilo30.ITEM_ID ) os_total ".
			"FROM ITEMS_LOOTED ilo30, RAID_CALENDAR rci30 ".
			"WHERE ilo30.RAID_ID = rci30.RAID_ID ".
			"AND ilo30.SPEC = 'Off' ".
			"AND rci30.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 31 DAY ) )  ".
			"GROUP BY ilo30.CHAR_ID ".
			")off_spec ON off_spec.CHAR_ID = chr30dl.CHAR_ID) 30dl ".
			"ON 30dl.CHAR_ID = chr.CHAR_ID ".
			" ".
			"LEFT JOIN ".
			"(SELECT e.CHAR_ID, concat( floor( (  ".
			"sum( length(  ".
			"REPLACE (  ".
			"ATTENDANCE, ".
			"'0', ".
			"'' ".
			") ) ) *100 ) / ( sum( length( ATTENDANCE ) ) ) ) , ".
			"'%' ".
			")ATTENDANCE ".
			"FROM (  ".
			" ".
			"SELECT a.CHAR_ID, b.ATTENDANCE ".
			"FROM `CHARACTER` a, `RAID_ATTENDANCE` b, `RAID_CALENDAR` f ".
			"WHERE a.CHAR_ID = b.CHAR_ID ".
			"AND f.RAID_ID = b.RAID_ID ".
			"AND b.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '1', b.ATTENDANCE ) <>0 ".
			"AND f.SCHEDULED = 1 ".
			"AND f.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 61  ".
			"DAY ) )  ".
			"UNION  ".
			"SELECT c.CHAR_ID, d.ATTENDANCE ".
			"FROM `CHARACTER` c, `RAID_ATTENDANCE` d, `RAID_CALENDAR` g ".
			"WHERE c.CHAR_ID = d.CHAR_ID ".
			"AND d.RAID_ID = g.RAID_ID ".
			"AND d.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '0', d.ATTENDANCE ) <>0 ".
			"AND g.SCHEDULED = 1 ".
			"AND g.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 61  ".
			"DAY ) )  ".
			")e ".
			"GROUP BY e.CHAR_ID) 60da ".
			"ON 60da.CHAR_ID = chr.CHAR_ID ".
			" ".
			"LEFT JOIN ".
			"(SELECT chr60dl.CHAR_ID, IFNULL( main_spec.ms_total, 0 ) 60MS, IFNULL( alt_spec.as_total, 0 ) 60AS, IFNULL( off_spec.os_total, 0 ) 60OS ".
			"FROM `CHARACTER` chr60dl ".
			"LEFT JOIN (  ".
			"SELECT ilm60.CHAR_ID, count( ilm60.ITEM_ID ) ms_total ".
			"FROM ITEMS_LOOTED ilm60, RAID_CALENDAR rci60 ".
			"WHERE ilm60.RAID_ID = rci60.RAID_ID ".
			"AND ilm60.SPEC = 'Main' ".
			"AND rci60.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 61 DAY ) )  ".
			"GROUP BY ilm60.CHAR_ID ".
			")main_spec ON main_spec.CHAR_ID = chr60dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ila60.CHAR_ID, count( ila60.ITEM_ID ) as_total ".
			"FROM ITEMS_LOOTED ila60, RAID_CALENDAR rci60 ".
			"WHERE ila60.RAID_ID = rci60.RAID_ID ".
			"AND ila60.SPEC = 'Alt' ".
			"AND rci60.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 61 DAY ) )  ".
			"GROUP BY ila60.CHAR_ID ".
			")alt_spec ON alt_spec.CHAR_ID = chr60dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ilo60.CHAR_ID, count( ilo60.ITEM_ID ) os_total ".
			"FROM ITEMS_LOOTED ilo60, RAID_CALENDAR rci60 ".
			"WHERE ilo60.RAID_ID = rci60.RAID_ID ".
			"AND ilo60.SPEC = 'Off' ".
			"AND rci60.DATE >= DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 61 DAY ) )  ".
			"GROUP BY ilo60.CHAR_ID ".
			")off_spec ON off_spec.CHAR_ID = chr60dl.CHAR_ID) 60dl ".
			"ON 60dl.CHAR_ID = chr.CHAR_ID ".
			"WHERE chr.RANK not in ('Friend','Alt','Officer Alt', '') " .
			"AND chr.DATE_REMOVED IS NULL " .
			"ORDER BY chr.NAME;");
	print "<fieldset>";
	print "<legend><font color=white>Raiding Members</font></legend>";
	print "<script src=\"sorttable.js\"></script>\n";
	print "<TABLE class=\"sortable\" ALIGN=LEFT id=\"mainScrollTable\">";
	#print "<TR><TH colspan=\"3\">Char Info</TH><TH colspan=\"4\">7 Day Info</TH><TH colspan=\"4\">30 Day Info</TH><TH colspan=\"4\">60 Day Info</TH></TR>";
	print "<thead>";
	print "<TR>";
	print "<TD WIDTH=90><U><B><font color=#C5BCAC>Name</font></B></U></TD>";
	print "<TD WIDTH=100><U><B><font color=#C5BCAC>Class</font></B></U></TD>";
	print "<TD WIDTH=100><U><B><font color=#C5BCAC>Rank</font></B></U></TD>";
	print "<TD WIDTH=120><U><B><font color=#C5BCAC>7 Day Attn</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>MS</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>AS</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>OS</font></B></U></TD>";
	print "<TD WIDTH=120><U><B><font color=#C5BCAC>30 Day Attn</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>MS</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>AS</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>OS</font></B></U></TD>";
	print "<TD WIDTH=120><U><B><font color=#C5BCAC>60 Day Attn</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>MS</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>AS</font></B></U></TD>";
	print "<TD WIDTH=40><U><B><font color=#C5BCAC>OS</font></B></U></TD></TR>\n";
	print "</thead>";
	$statement->execute() or die $dbh->errstr;
	while (my $row = $statement->fetchrow_hashref()) {
		print "<TR onMouseOver=\"this.className='highlight'\" onMouseOut=\"this.className='normal'\">";
		#print "<TR>";
		print "<TD><B><A HREF=\"char.shtml?data=$row->{NAME}\" STYLE=\"text-decoration:none\"> $row->{NAME} </A></B></TD>";
		classColor($row->{CLASS});
		print "<TD><font color=#FFFFFF>$row->{RANK}</font></TD>";
		#7 day stats
		attendanceColor($row->{'7day'});
		print "<TD>";
		lootColor($row->{'7MS'});
		print "</TD>";
		print "<TD>";
		lootColor($row->{'7AS'});
		print "</TD>";
		print "<TD>";
		lootColor($row->{'7OS'});
		print "</TD>";
		#30 day stats
		attendanceColor($row->{'30day'});
		print "<TD>";
		lootColor($row->{'30MS'});
		print "</TD>";
		print "<TD>";
		lootColor($row->{'30AS'});
		print "</TD>";
		print "<TD>";
		lootColor($row->{'30OS'});
		print "</TD>";
		#60 day stats
		attendanceColor($row->{'60day'});
		print "<TD>";
		lootColor($row->{'60MS'});
		print "</TD>";
		print "<TD>";
		lootColor($row->{'60AS'});
		print "</TD>";
		print "<TD>";
		lootColor($row->{'60OS'});
		print "</TD>";
		print "</TR>\n";
		print "\n";
	}
	print "</TABLE>";
	#print "<script type=\"text/javascript\">";
	#print "var t = new ScrollableTable(document.getElementById('mainScrollTable'),100);";
	#print "</script>";
	#print "<script type=\"text/javascript\">";
	#print "var t = new SortableTable(document.getElementById('mainScrollTable'),100);";
	#print "</script>";
	print "</fieldset>";
	print "</HTML>";
	$statement->finish();
$dbh->disconnect();
#print "</pre>";
