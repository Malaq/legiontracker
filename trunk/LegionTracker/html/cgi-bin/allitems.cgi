#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

sub URLEncode {
my $theURL = $_[0];
$theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
return $theURL;
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

# Loot table
my $list_statement =
	$dbh->prepare("SELECT it.ITEM_NAME, it.ITEM_ID, min(rc.DATE) First_Loot, max(rc.DATE) Last_Looted, count(*) COUNT " .
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
print "<TABLE class=\"sortable normal\" ALIGN=LEFT WIDTH=\"600\" id=\"allItemsScrollTable\">";
print "<THEAD>";
print "<TR>";
print "<TH WIDTH=200><U><B>Item Name</B></U></TH>";
print "<TH WIDTH=20><U><B>Count</B></U></TH>";
print "<TH WIDTH=100><U><B>First Looted</B></U></TH>";
print "<TH WIDTH=100><U><B>Last Looted</B></U></TH>";
print "</TR>\n";
print "</THEAD>";
while (my $row = $list_statement->fetchrow_hashref()) {
	my $url = URLEncode($row->{ITEM_NAME});
	print "<TR onMouseOver=\"this.className='highlight'\" onMouseOut=\"this.className='normal'\" onclick=\"location.href='item.shtml?data=$url'\">";
	print "<TD><A HREF=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\" TARGET=\"_blank\">$row->{ITEM_NAME}</A></TD>";
	print "<TD>$row->{COUNT}</TD>";
	print "<TD>$row->{First_Loot}</TD>";
	print "<TD>$row->{Last_Looted}</TD>";
	print "</TR>\n";
	print "\n";
}
print "</TABLE>";
print "</fieldset>";
#print "<script type=\"text/javascript\">";
#print "var t = new ScrollableTable(document.getElementById('allItemsScrollTable'), 500, 600);";
#print "</script>";
print "</HTML>";
$list_statement->finish();
$dbh->disconnect();
