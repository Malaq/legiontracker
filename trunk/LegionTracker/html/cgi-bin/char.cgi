#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

# For debug output
print "<pre>";

# Setup our DB connection
my $database = 'legiontracker_tg';
my $username = 'legiontracker_tg';
my $password = 'legio3';
my $hostname = 'fdb1.awardspace.com';
my $dbport = '3306';

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

my $input = param('data');

print "$input";

my $statement =
	$dbh->prepare("SELECT chr.NAME, it.ITEM_ID, it.ITEM_NAME, rc.DATE, il.SPEC, il.ZONE, il.SUBZONE " .
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
	$statement->bind_param(1, $input);
        print "<HTML>\n";
	print "<form method=\"POST\" action=\"char.cgi\">\n";
	print "Enter a character name:";
	print "<input type=\"text\" name=\"data\">";
	print "<input type=\"submit\" value=\"Submit\"></input>\n";
	print "</form>\n";
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
	$statement->execute() or die $dbh->errstr;
	while (my $row = $statement->fetchrow_hashref()) {
		print "<TR>";
		print "<TD>$row->{NAME}</TD><TD><a href=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\">$row->{ITEM_NAME}</a></TD><TD>$row->{DATE}</TD>";
		print "<TD>$row->{SPEC}</TD><TD>$row->{ZONE}</TD><TD>$row->{SUBZONE}</TD>";
		print "</TR>\n";
		print "\n";
	}
	print "</TABLE>";
	print "</HTML>";
	$statement->finish();
$dbh->disconnect();
print "</pre>";
