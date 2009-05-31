#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

sub attendanceColor {
	my $attendance = shift;
	my $attendance_type = '';
	if ($attendance > 27) {
		$attendance_type = 'high_attendance';
	} elsif ($attendance > 22) {
		$attendance_type = 'medium_attendance';
	} else {
		$attendance_type = 'low_attendance';
	}
	print "<TD class='$attendance_type'>$attendance</TD>";
}

sub saturationColor {
	my $saturation = shift;
	my $satnum = substr($saturation, 0, - 1);
	my $attendance_type = '';
	if ($satnum < 25) {
		$attendance_type = 'high_attendance';
	} elsif ($satnum < 50) {
		$attendance_type = 'medium_attendance';
	} else {
		$attendance_type = 'low_attendance';
	}
	print "<TD class='$attendance_type'>$saturation</TD>";
}


# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

# Setup our DB connection
my $database = 'legiontracker_tg';
my $username = 'legiontracker_tg';
my $password = 'legio3';
my $hostname = 'fdb1.awardspace.com';
my $dbport = '3306';

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

my $char_name = param('data');

print "<font size=\"6\" face=\"Monotype Corsiva\"><B>$char_name</B></font>";

	print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
	print "<HTML>\n";

# Raid table
my $list_statement =
	$dbh->prepare("SELECT rc.RAID_ID, rc.DATE, date_format(rc.DATE, '%a') DAYOFWEEK, rc.ATTENDANCE_COUNT, IFNULL(total_members.numb,'n/a') MEMBERS, IFNULL(total_loot.numb,0) DROPS, " .
			"concat(IFNULL(floor((de.numb*100)/total_loot.numb),0),'%') SATURATION " .
			"FROM `RAID_CALENDAR` rc " .
			"LEFT JOIN " .
		        "(SELECT raid_id, count(item_id) numb " .
			 "FROM ITEMS_LOOTED " .
			 "WHERE spec in ('DE\\'d', 'Off') " .
			 "GROUP BY raid_id) de " .
			"ON de.raid_id = rc.raid_id " .
			"LEFT JOIN " .
			 "(SELECT raid_id, count(item_id) numb " .
			 "FROM ITEMS_LOOTED " .
			 "WHERE spec <> 'Unassigned' " .
			 "GROUP BY raid_id) total_loot " .
			"ON total_loot.raid_id = rc.raid_id " .
			"LEFT JOIN " .
			"(SELECT raid_id, count(*) numb " .
			 "FROM RAID_ATTENDANCE " .
			 "WHERE ATTENDANCE Regexp '[[:digit:]]+' <> 0 " .
			 "GROUP BY raid_id) total_members " .
			"ON total_members.raid_id = rc.raid_id " .
			"WHERE rc.SCHEDULED = 1 " .
			"GROUP BY raid_id " .
			"ORDER BY rc.DATE desc;");

$list_statement->execute() or die $dbh->errstr;
print "<fieldset>";
print "<legend>Scheduled Raids</legend>";
print "<script src=\"sorttable.js\"></script>\n";
print "<TABLE class=\"sortable normal\" ALIGN=LEFT>";
print "<THEAD>\n";
print "<TR>";
print "<TH WIDTH=100><U><B>Raid Date</B></U></TH>";
print "<TH WIDTH=75><U><B>Weekday</B></U></TH>";
print "<TH WIDTH=100><U><B>Members Available</B></U></TH>";
print "<TH WIDTH=75><U><B>Members</B></U></TH>";
print "<TH WIDTH=100><U><B>Epics Dropped</B></U></TH>";
print "<TH WIDTH=100><U><B>Loot Saturation</B></U></TH>";
print "<TH><U><B>Zones Raided</B></U></TH>";
print "</TR>\n";
print "</THEAD>";
while (my $row = $list_statement->fetchrow_hashref()) {
	my $raidid = $row->{RAID_ID};
	print "<TR onMouseOver=\"this.className='highlight'\" onMouseOut=\"this.className='normal'\" onclick=\"location.href='raiddetail.shtml?data=$raidid'\">";
	print "<TD>";
	print "<A HREF=\"raiddetail.shtml?data=$raidid\">";
	print "$row->{DATE}";
	print "</A>";
	print "</TD>";
	print "<TD>";
	print "$row->{DAYOFWEEK}";
	print "</TD>";
	attendanceColor($row->{ATTENDANCE_COUNT});
	print "<TD>";
	print "$row->{MEMBERS}";
	print "</TD>";
	print "<TD>";
	print "$row->{DROPS}";
	print "</TD>";
	saturationColor($row->{SATURATION});
	print "<TD>";
	#start
	my $zone_statement =
	$dbh->prepare("SELECT DISTINCT il.zone ZONE " .
			"FROM ITEMS_LOOTED il " .
			"WHERE il.raid_id = ? " .
			"AND il.spec NOT IN ('Unassigned', 'DE''d');");
	$zone_statement->bind_param(1, $raidid);
	$zone_statement->execute() or die $dbh->errstr;
	my $count = 0;
	while (my $zonerow = $zone_statement->fetchrow_hashref()) {
		if ( $count ne "0" ) {
			print ", ";
		}	
		print "$zonerow->{ZONE}";
		$count=$count+1;
	}
	$zone_statement->finish();

	if ( $count eq "0" ) {
	my $zone_statement =
	$dbh->prepare("SELECT DISTINCT il.zone ZONE " .
			"FROM ITEMS_LOOTED il " .
			"WHERE il.raid_id = ? ;");
	$zone_statement->bind_param(1, $raidid);
	$zone_statement->execute() or die $dbh->errstr;
	my $count = 0;
	while (my $zonerow = $zone_statement->fetchrow_hashref()) {
		if ( $count ne "0" ) {
			print ", ";
		}	
		print "$zonerow->{ZONE}";
		$count=$count+1;
	}
	$zone_statement->finish();
	}
	#finish
	print "</TD>";
	print "</TR>\n";
	print "\n";
}
print "</fieldset>";
print "</TABLE>";
print "</HTML>";
$list_statement->finish();
$dbh->disconnect();