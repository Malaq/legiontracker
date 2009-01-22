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

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

my $char_name = param('data');

print "<font size=\"6\" face=\"Monotype Corsiva\"><B>$char_name</B></font>";

	print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
	print "<HTML>\n";

# Attendance
print "<fieldset>";
print "<legend>Attendance Details:</legend>";
print <<STRINGDELIM;
	<table border=2>
	<tr>
		<th>Date</th>
		<th>Attendance (10 min increments)</th>
	</tr>
STRINGDELIM

my $sql_text = <<STRINGDELIM;
SELECT rc.RAID_ID, rc.DATE, ra.ATTENDANCE
from `CHARACTER` chr, RAID_ATTENDANCE ra, RAID_CALENDAR rc
where ra.RAID_ID = rc.RAID_ID
and chr.CHAR_ID = ra.CHAR_ID
and chr.NAME = ?
and rc.scheduled = 1
order by rc.DATE desc;
STRINGDELIM

my $attn_statement = $dbh->prepare( $sql_text );
$attn_statement->bind_param(1, $char_name);
$attn_statement->execute() or die $dbh->errstr;

while (my $row = $attn_statement->fetchrow_hashref()) {
	my $attn = $row->{ATTENDANCE};
	$attn =~ s|0|~|g;
	#$attn =~ s|1|<div style='width:10px;height:10px;background-color:green;display:inline-block'></div>|g;
	#$attn =~ s|~|<div style='width:10px;height:10px;background-color:red;display:inline-block'></div>|g;
	#$attn =~ s|1|<td style='background-color:green;'></td>|g;
	#$attn =~ s|~|<td style='background-color:red;'></td>|g;
	$attn =~ s|1|<img src=\"images/greenbox.JPG\">|g;
	$attn =~ s|~|<img src=\"images/redbox.JPG\">|g;
	print <<STRINGDELIM;
		<tr>
			<td><A HREF=\"raiddetail.shtml?data=$row->{RAID_ID}\">$row->{DATE}</A></td><td>$attn</td>
		</tr>
STRINGDELIM
}
print <<STRINGDELIM;
</table>
STRINGDELIM
print "</fieldset>";

$attn_statement->finish();



# Loot table
print "<fieldset>";
print "<legend>Loot Details:</legend>";
my $loot_statement =
	$dbh->prepare("SELECT chr.NAME, it.ITEM_ID, it.ITEM_NAME, il.TIMESTAMP, il.SPEC, il.ZONE, il.SUBZONE " .
			"FROM `CHARACTER` chr, ITEMS_LOOTED il, RAID_CALENDAR rc, ITEM it " .
			"WHERE il.RAID_ID = rc.RAID_ID " .
			"AND il.CHAR_ID = chr.CHAR_ID " .
			"AND it.ITEM_ID = il.ITEM_ID " .
			"AND rc.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 60 " .
			"DAY ) ) " .
			"AND il.SPEC <> 'Unassigned' " .
			"AND il.SPEC not like 'DE%' " .
			"AND chr.NAME = ? " .
			"ORDER BY timestamp DESC;");

$loot_statement->bind_param(1, $char_name);
$loot_statement->execute() or die $dbh->errstr;
print "<script src=\"sorttable.js\"></script>\n";
print "<script src=\"http://www.wowhead.com/widgets/power.js\"></script>\n";
print "<TABLE class=\"sortable\" style=\"filter:alpha(opacity=75);-moz-opacity:.75;opacity:.75;\" BORDER=2 ALIGN=LEFT><TR>";
print "<TH><U><B><font color=black>Name</B></U></TH>";
print "<TH><U><B>Item Name</B></U></TH>";
print "<TH><U><B>Date</B></U></TH>";
print "<TH><U><B>Spec</B></U></TH>";
print "<TH><U><B>Zone</B></U></TH>";
print "<TH><U><B>SubZone</B></U></TH>";
print "</TR>\n";
while (my $row = $loot_statement->fetchrow_hashref()) {
	print "<TR>";
	print "<TD>$row->{NAME}</TD><TD><a href=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\">$row->{ITEM_NAME}</a></TD><TD>$row->{TIMESTAMP}</TD>";
	print "<TD>$row->{SPEC}</TD><TD>$row->{ZONE}</TD><TD>$row->{SUBZONE}</TD>";
	print "</TR>\n";
	print "\n";
}
print "</TABLE>";
print "</fieldset>";
print "</HTML>";
$loot_statement->finish();
$dbh->disconnect();
