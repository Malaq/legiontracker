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
	$dbh->prepare("SELECT RAID_ID, DATE, ATTENDANCE_COUNT " .
			"FROM `RAID_CALENDAR` " .
			"WHERE SCHEDULED = 1 " .
			"ORDER BY DATE desc;");

$list_statement->execute() or die $dbh->errstr;
print "<script src=\"sorttable.js\"></script>\n";
print "<TABLE class=\"sortable\" style=\"filter:alpha(opacity=75);-moz-opacity:.75;opacity:.75;\" BORDER=2 ALIGN=LEFT><TR>";
print "<TH WIDTH=155><U><B><font color=black>Raid Date</B></U></TH>";
print "<TH WIDTH=100><U><B>Members Available</B></U></TH>";
print "</TR>\n";
while (my $row = $list_statement->fetchrow_hashref()) {
	print "<TR>";
	print "<TD><A HREF=\"raiddetail.shtml?data=$row->{RAID_ID}\">$row->{DATE}</A></TD>";
	print "<TD>$row->{ATTENDANCE_COUNT}</TD>";
	print "</TR>\n";
	print "\n";
}
print "</TABLE>";
print "</HTML>";
$list_statement->finish();
$dbh->disconnect();
