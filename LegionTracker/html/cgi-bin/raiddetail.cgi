#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

# Setup our DB connection
my $database = 'legiontracker_tg';
my $username = 'legiontracker_tg';
my $password = 'legio3';
my $hostname = 'fdb1.awardspace.com';
my $dbport = '3306';
my $sched = "Error";

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

my $raid_id = param('data');

print "<font size=\"6\" face=\"Monotype Corsiva\"><B>$char_name</B></font>";

	print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
	print "<HTML>\n";

# Raid info
my $raid_query =
	$dbh->prepare("SELECT DATE, SCHEDULED, ATTENDANCE_COUNT " .
			"FROM RAID_CALENDAR " .
			"WHERE RAID_ID = ?;");

$raid_query->bind_param(1, $raid_id);
$raid_query->execute() or die $dbh->errstr;
my $row = $raid_query->fetchrow_hashref();
print "<fieldset style=\"width: 200px;\">";
print "<legend>Raid Summary:</legend>";
print "<p>Raid ID: <B>$raid_id</B><br>";
print "Date: <B>$row->{DATE}</B><br>";
if ($row->{SCHEDULED} == "1") {
	$sched = "True";
} else {
	$sched = "False";
}
print "Scheduled: <B>$sched</B><br>";
print "Raiders Available: <B>$row->{ATTENDANCE_COUNT}</B><br></p>";
print "</fieldset>";
print "<br>";

$raid_query->finish();

# Loot table
#print "<B><font size=5>Loot</font></B><br>";
print "<fieldset>";
print "<legend>Loot Details:</legend>";
my $loot_statement =
	$dbh->prepare("SELECT chr.NAME, it.ITEM_ID, it.ITEM_NAME, il.TIMESTAMP, il.SPEC, il.ZONE, il.SUBZONE " .
			"FROM `CHARACTER` chr, ITEMS_LOOTED il, RAID_CALENDAR rc, ITEM it " .
			"WHERE il.RAID_ID = rc.RAID_ID " .
			"AND il.CHAR_ID = chr.CHAR_ID " .
			"AND it.ITEM_ID = il.ITEM_ID " .
			"AND il.SPEC <> 'Unassigned' " .
			"AND rc.RAID_ID = ?" .
			"ORDER BY timestamp DESC;");

$loot_statement->bind_param(1, $raid_id);
$loot_statement->execute() or die $dbh->errstr;
print "<script src=\"sorttable.js\"></script>\n";
print "<script src=\"http://www.wowhead.com/widgets/power.js\"></script>\n";
print "<TABLE class=\"sortable\" style=\"filter:alpha(opacity=75);-moz-opacity:.75;opacity:.75;\" BORDER=2 ALIGN=LEFT><TR>";
print "<TH WIDTH=155><U><B><font color=black>Name</B></U></TH>";
print "<TH WIDTH=100><U><B>Item Name</B></U></TH>";
print "<TH WIDTH=100><U><B>Date</B></U></TH>";
print "<TH WIDTH=100><U><B>Spec</B></U></TH>";
print "<TH WIDTH=155><U><B>Zone</B></U></TH>";
print "<TH WIDTH=40><U><B>SubZone</B></U></TH>";
print "</TR>\n";
while (my $row = $loot_statement->fetchrow_hashref()) {
	print "<TR>";
	print "<TD><B>$row->{NAME}</B></TD><TD><a href=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\">$row->{ITEM_NAME}</a></TD><TD>$row->{TIMESTAMP}</TD>";
	print "<TD>$row->{SPEC}</TD><TD>$row->{ZONE}</TD><TD>$row->{SUBZONE}</TD>";
	print "</TR>\n";
	print "\n";
}
print "</TABLE>";
print "</fieldset>";
$loot_statement->finish();

#Attendees
print "<BR CLEAR=all>";
print "<fieldset>";
print "<legend>Attendance Details:</legend>";
#print "<B><font size=5>Attendees</font></B><br>";
my $attendance_stmt =
	$dbh->prepare("SELECT chr.NAME, chr.CLASS, ra.ATTENDANCE, " .
			"concat( floor( length(replace(ATTENDANCE,'0',''))*100 / length(ATTENDANCE)) ,'%') PERCENT " .
			"FROM `CHARACTER` chr, `RAID_ATTENDANCE` ra " .
			"WHERE ra.CHAR_ID = chr.CHAR_ID " .
			"AND ra.RAID_ID = ?" .
			"AND INSTR(ra.ATTENDANCE, '1') > 0 " .
			"ORDER BY chr.NAME;");

$attendance_stmt->bind_param(1, $raid_id);
$attendance_stmt->execute() or die $dbh->errstr;
print "<script src=\"sorttable.js\"></script>\n";
print "<TABLE class=\"sortable\" style=\"filter:alpha(opacity=75);-moz-opacity:.75;opacity:.75;\" BORDER=2 ALIGN=LEFT><TR>";
print "<TH WIDTH=100><U><B><font color=black>Name</B></U></TH>";
print "<TH WIDTH=100><U><B><font color=black>Class</B></U></TH>";
print "<TH WIDTH=50><U><B>Pct</B></U></TH>";
print "<TH WIDTH=500 colspan=100><U><B>Attendance</B>(10 min increments)</U></TH>";
print "</TR>\n";
while (my $row = $attendance_stmt->fetchrow_hashref()) {
	my $attn = $row->{ATTENDANCE};
	$attn =~ s|0|~|g;
	#$attn =~ s|1|<div style='width:10px;height:10px;background-color:green;display:inline-block'></div>|g;
	#$attn =~ s|~|<div style='width:10px;height:10px;background-color:red;display:inline-block'></div>|g;
	$attn =~ s|1|<td style='background-color:green;'></td>|g;
	$attn =~ s|~|<td style='background-color:red;'></td>|g;
	print "<tr>";
	print "<td><B>$row->{NAME}</B></td>";
	print "<td>$row->{CLASS}</td>";
	print "<td>$row->{PERCENT}</td>";
	print "$attn ";
	print "</tr>";
	}
print "</TABLE>";
print "</fieldset>";
print "</HTML>";
$attendance_stmt->finish();

$dbh->disconnect();
