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

my $item_name = param('data');

#print "<font size=\"6\" face=\"Monotype Corsiva\"><B>$char_name</B></font>";

#print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
#print "<HTML>\n";

# Overview
print "<script src=\"http://www.wowhead.com/widgets/power.js\"></script>\n";
print "<fieldset>";
print "<legend>Item Details:</legend>";
my $sql_text = 
my $summary_statement =
	$dbh->prepare("SELECT it1.ITEM_NAME, it1.ITEM_ID, il.TIMESTAMP, chr.NAME " .
			"FROM `CHARACTER` chr, ITEMS_LOOTED il, ITEM it1, ( " .
			"SELECT il.ITEM_ID, MIN( il.TIMESTAMP ) TIMESTAMP " .
			"FROM ITEMS_LOOTED il, ITEM it " .
			"WHERE il.ITEM_ID = it.ITEM_ID " .
			"AND it.ITEM_NAME like ? " .
			"GROUP BY il.ITEM_ID " .
			")firstl " .
			"WHERE firstl.ITEM_ID = il.ITEM_ID " .
			"AND firstl.TIMESTAMP = il.TIMESTAMP " .
			"AND chr.CHAR_ID = il.CHAR_ID " .
			"AND il.ITEM_ID = it1.ITEM_ID " .
			"ORDER BY TIMESTAMP;");
$summary_statement->bind_param(1, '%'.$item_name.'%');
$summary_statement->execute() or die $dbh->errstr;
my $row = $summary_statement->fetchrow_hashref();
if ( $row->{ITEM_ID} ne "" ) {
	print "<B>Name:</B><a href=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\" TARGET=\"_blank\">$row->{ITEM_NAME}</a><BR>";
	print "<B>First Time Looted:</B> $row->{TIMESTAMP} <BR>";
	print "<B>Who First Looted:</B> $row->{NAME} <BR>";
	print "<B>Percent Dusted:</B> n/a <BR>";
} else {
	print "<B>Item $item_name is not found.</B>";
}
print "</fieldset>";

$summary_statement->finish();

# Loot table
print "<fieldset>";
print "<legend>Loot History:</legend>";
my $sql_text = 
my $loot_statement =
	$dbh->prepare("SELECT chr.NAME, it.ITEM_NAME, it.ITEM_ID, il.SPEC, il.TIMESTAMP, il.ZONE, il.SUBZONE " .
			"FROM `CHARACTER` chr, ITEMS_LOOTED il, RAID_CALENDAR rc, ITEM it " .
			"WHERE chr.CHAR_ID = il.CHAR_ID " .
			"AND il.RAID_ID = rc.RAID_ID " .
			"AND it.ITEM_ID = il.ITEM_ID " .
			"AND it.ITEM_NAME like ? " .
			"ORDER BY it.ITEM_NAME, il.TIMESTAMP DESC;");
$loot_statement->bind_param(1, '%'.$item_name.'%');
$loot_statement->execute() or die $dbh->errstr;
print "<script src=\"sorttable.js\"></script>\n";
print "<script src=\"http://www.wowhead.com/widgets/power.js\"></script>\n";
print "<table cellspacing=\"1\" cellpadding=\"2\" class=\"sortable\" id=\"lootDetail\">";
print "<THEAD>";
print "<TR>";
print "<TH><U><B><font color=black>Name</B></U></TH>";
print "<TH><U><B>Item Name</B></U></TH>";
print "<TH><U><B>Spec</B></U></TH>";
print "<TH><U><B>Date</B></U></TH>";
print "<TH><U><B>Zone</B></U></TH>";
print "<TH><U><B>SubZone</B></U></TH>";
print "</TR>";
print "</THEAD>\n";
print "<TBODY>";
while (my $row = $loot_statement->fetchrow_hashref()) {
	print "<TR>";
	print "<TD><B><A HREF=\"char.shtml?data=$row->{NAME}\">$row->{NAME}</A></B></TD><TD><a href=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\" TARGET=\"_blank\">$row->{ITEM_NAME}</a></TD>";
	print "<TD>$row->{SPEC}</TD><TD>$row->{TIMESTAMP}</TD><TD>$row->{ZONE}</TD><TD>$row->{SUBZONE}</TD>";
	print "</TR>\n";
	print "\n";
}
print "</TBODY>";
print "</TABLE>";
#print "<script type=\"text/javascript\">";
#print "var t = new ScrollableTable(document.getElementById('lootDetail'), 500);";
#print "</script>";
print "</fieldset>";
#print "</HTML>";
$loot_statement->finish();
$dbh->disconnect();
