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
my $mainchar = '';

# Database handle
my $dbh = DBI->connect("dbi:mysql:database=$database;host=$hostname;port=$dbport", $username, $password) or print $DBI::errstr;

my $char_name = param('data');

#print "<font size=\"6\" face=\"Monotype Corsiva\"><B>$char_name</B></font>";

#print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
#print "<HTML>\n";

# Overview
print "<fieldset>";
print "<legend>Character Details:</legend>";
my $sql_text = 
my $summary_statement =
	$dbh->prepare("SELECT char_id, name, class, rank, date_joined, date_removed " .
			"from `CHARACTER` " .
			"where name = ? ;");
$summary_statement->bind_param(1, $char_name);
$summary_statement->execute() or die $dbh->errstr;
my $row = $summary_statement->fetchrow_hashref();
my $utf8name = $row->{name};
utf8::encode($utf8name); 
$utf8name = URLEncode($utf8name);
print "<table>";
print "<TR>";
print "<TD rowspan=\"2\">";
print "<B>Name:</B> <A HREF=\"http://www.wowarmory.com/character-sheet.xml?r=Medivh&n=$utf8name\" TITLE=\"CHAR_ID=$row->{char_id}\" TARGET=\"_blank\">$row->{name}</A><BR>";
print "<B>Class:</B> $row->{class} <BR>";
print "<B>Rank:</B> $row->{rank} <BR>";
my $rank = $row->{rank};
print "<B>Date Joined:</B> $row->{date_joined} <BR>";
if ( $row->{date_removed} ne "" )
{
print "<B>Date Removed (estimated):</B> $row->{date_removed} <BR>";
}
$summary_statement->finish();
print "</TD>";
print "<TD>";
if (( $rank eq "Alt" ) || ( $rank eq "Officer Alt" ))
{
	print "<B>Main:</B>";
	print "</TD>";
	print "</TR>";
	print "<TR>";
	print "<TD>";
	#Mains
	my $sql_text = 
	my $main_statement =
		$dbh->prepare("SELECT ra.attendance MAIN " .
				"FROM `CHARACTER` chr, RAID_ATTENDANCE ra " .
				"WHERE chr.char_id = ra.char_id " .
				"AND chr.NAME = ? " .
				"and ra.raid_id = (select distinct max(raid_id) from RAID_ATTENDANCE ra, `CHARACTER` chr where ra.char_id = chr.char_id and chr.NAME = ? );");
	$main_statement->bind_param(1, $char_name);
	$main_statement->bind_param(2, $char_name);
	$main_statement->execute() or die $dbh->errstr;
	my $row = $main_statement->fetchrow_hashref();
	$mainchar = $row->{MAIN};
	print "<A HREF=\"char.shtml?data=$mainchar\" STYLE=\"text-decoration:none\" class='member_name'>";
	print "$mainchar";
	print "</A>";
	print "<br>";
	
	$main_statement->finish();

}
else
{
	print "<B>Alts:</B>";
	print "</TD>";
	print "</TR>";
	print "<TR>";
	print "<TD>";
	
	#Alts
	my $sql_text = 
	my $alt_statement =
		$dbh->prepare("SELECT DISTINCT chr.NAME " .
				"FROM RAID_ATTENDANCE ra, `CHARACTER` chr " .
				"WHERE ra.char_id = chr.char_id " .
				"AND ra.attendance = ? " .
				"and ra.raid_id = (select distinct max(raid_id) from RAID_ATTENDANCE ra, `CHARACTER` chr where ra.char_id = chr.char_id and chr.NAME = ? );");
	$alt_statement->bind_param(1, $char_name);
	$alt_statement->bind_param(2, $char_name);
	$alt_statement->execute() or die $dbh->errstr;
	while (my $row = $alt_statement->fetchrow_hashref()) {
		my $altname = $row->{NAME};
		print "<A HREF=\"char.shtml?data=$altname\" STYLE=\"text-decoration:none\" class='member_name'>";
		print "$altname";
		print "</A>";
		print "<br>";
	}
	$alt_statement->finish();
}
print "</TD>";
print "</TR>";
print "</TABLE>";
print "</fieldset>";
#End Alts

if ( $rank ne "Friend" )
{
# Attendance
print "<fieldset>";
if (( $rank eq "Alt") || ( $rank eq "Officer Alt" ))
{
	print "<legend>Attendance Details (<B>$mainchar</B>):</legend>";
}
else
{
	print "<legend>Attendance Details:</legend>";
}
print <<STRINGDELIM;
	<table cellspacing="1" cellpadding="2" class="sortable normal" id="attnDetail">
	<thead>
	<tr>
		<th>Date</th>
		<TH>Weekday</TH>
		<th>Attendance (10 min increments)</th>
		<th>Percent</th>
	</tr>
	</thead>	
STRINGDELIM

my $sql_text = <<STRINGDELIM;
SELECT rc.RAID_ID, rc.DATE, date_format(rc.DATE,'%a') WEEKDAY, ra.ATTENDANCE, concat(FLOOR(IFNULL(length(REPLACE(ra.ATTENDANCE, '0', ''))*100/length(ra.ATTENDANCE),'0')),'%') PERCENT
from `CHARACTER` chr, RAID_ATTENDANCE ra, RAID_CALENDAR rc
where ra.RAID_ID = rc.RAID_ID
and chr.CHAR_ID = ra.CHAR_ID
and chr.NAME = ?
and rc.scheduled = 1
order by rc.DATE desc;
STRINGDELIM

my $attn_statement = $dbh->prepare( $sql_text );
if (( $rank eq "Alt") || ( $rank eq "Officer Alt" ))
{
$attn_statement->bind_param(1, $mainchar);
}
else
{
$attn_statement->bind_param(1, $char_name);
}
$attn_statement->execute() or die $dbh->errstr;

print "<TBODY>";
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
	        <TR onMouseOver=\"this.className='highlight'\" onMouseOut=\"this.className='normal'\" onclick=\"location.href='raiddetail.shtml?data=$row->{RAID_ID}'\">
			<td><A HREF=\"raiddetail.shtml?data=$row->{RAID_ID}\" TITLE=\"RAID_ID=$row->{RAID_ID}\">$row->{DATE}</A></td><TD>$row->{WEEKDAY}</TD><td>$attn</td><td>$row->{PERCENT}</td>
		</tr>
STRINGDELIM
}
print <<STRINGDELIM;
</TBODY>
</table>
STRINGDELIM
print "</fieldset>";

$attn_statement->finish();
}


# Loot table
print "<fieldset>";
print "<legend>Loot Details (<B>$char_name</B>):</legend>";
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
print "<table cellspacing=\"1\" cellpadding=\"2\" class=\"sortable normal\" id=\"lootDetail\">";
print "<THEAD>";
print "<TR>";
print "<TH><U><B>Name</B></U></TH>";
print "<TH><U><B>Item Name</B></U></TH>";
print "<TH><U><B>Date</B></U></TH>";
print "<TH><U><B>Spec</B></U></TH>";
print "<TH><U><B>Zone</B></U></TH>";
print "<TH><U><B>SubZone</B></U></TH>";
print "</TR>";
print "</THEAD>\n";
print "<TBODY>";
while (my $row = $loot_statement->fetchrow_hashref()) {
	my $url = URLEncode($row->{ITEM_NAME}); 
	print "<TR onMouseOver=\"this.className='highlight'\" onMouseOut=\"this.className='normal'\" onclick=\"location.href='item.shtml?data=$url'\">";
	print "<TD>$row->{NAME}</TD><TD><a href=\"http://www.wowhead.com/?item=$row->{ITEM_ID}\">$row->{ITEM_NAME}</a></TD><TD>$row->{TIMESTAMP}</TD>";
	print "<TD>$row->{SPEC}</TD><TD>$row->{ZONE}</TD><TD>$row->{SUBZONE}</TD>";
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