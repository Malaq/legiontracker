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

# Loot table
my $list_statement =
	$dbh->prepare("SELECT it.ITEM_NAME, it.ITEM_ID, min(rc.DATE) First_Loot, max(rc.DATE) Last_Looted " .
		"FROM `ITEM` it, `ITEMS_LOOTED` il, RAID_CALENDAR rc " .
		"where it.ITEM_ID = il.ITEM_ID " .
		"and il.RAID_ID = rc.RAID_ID " .
		"group by il.ITEM_ID " .
		"order by it.ITEM_NAME;");

$list_statement->execute() or die $dbh->errstr;
print "<fieldset>";
print "<legend>All Items Looted</legend>";
print "<script src=\"sorttable.js\"></script>\n";
print "<script src=\"http://www.wowhead.com/widgets/power.js\"></script>\n";
print "<TABLE class=\"sortable\" style=\"filter:alpha(opacity=75);-moz-opacity:.75;opacity:.75;\" BORDER=2 ALIGN=LEFT><TR>";
print "<TH WIDTH=155><U><B><font color=black>Item Name</B></U></TH>";
print "<TH WIDTH=100><U><B>First Looted</B></U></TH>";
print "<TH WIDTH=100><U><B>Last Looted</B></U></TH>";
print "</TR>\n";
while (my $row = $list_statement->fetchrow_hashref()) {
	print "<TR>";
	print "<TD><A HREF=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\" TARGET=\"_blank\">$row->{ITEM_NAME}</A></TD><TD>$row->{First_Loot}</TD><TD>$row->{Last_Looted}</TD>";
	print "</TR>\n";
	print "\n";
}
print "</fieldset>";
print "</TABLE>";
print "</HTML>";
$list_statement->finish();
$dbh->disconnect();
