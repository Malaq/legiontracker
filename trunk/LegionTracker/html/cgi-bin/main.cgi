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
			"AND f.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 7  ".
			"DAY ) )  ".
			"UNION  ".
			"SELECT c.CHAR_ID, d.ATTENDANCE ".
			"FROM `CHARACTER` c, `RAID_ATTENDANCE` d, `RAID_CALENDAR` g ".
			"WHERE c.CHAR_ID = d.CHAR_ID ".
			"AND d.RAID_ID = g.RAID_ID ".
			"AND d.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '0', d.ATTENDANCE ) <>0 ".
			"AND g.SCHEDULED = 1 ".
			"AND g.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 7  ".
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
			"AND rci7.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 7 DAY ) )  ".
			"GROUP BY ilm7.CHAR_ID ".
			")main_spec ON main_spec.CHAR_ID = chr7dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ila7.CHAR_ID, count( ila7.ITEM_ID ) as_total ".
			"FROM ITEMS_LOOTED ila7, RAID_CALENDAR rci7 ".
			"WHERE ila7.RAID_ID = rci7.RAID_ID ".
			"AND ila7.SPEC = 'Alt' ".
			"AND rci7.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 7 DAY ) )  ".
			"GROUP BY ila7.CHAR_ID ".
			")alt_spec ON alt_spec.CHAR_ID = chr7dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ilo7.CHAR_ID, count( ilo7.ITEM_ID ) os_total ".
			"FROM ITEMS_LOOTED ilo7, RAID_CALENDAR rci7 ".
			"WHERE ilo7.RAID_ID = rci7.RAID_ID ".
			"AND ilo7.SPEC = 'Off' ".
			"AND rci7.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 7 DAY ) )  ".
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
			"AND f.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 30  ".
			"DAY ) )  ".
			"UNION  ".
			"SELECT c.CHAR_ID, d.ATTENDANCE ".
			"FROM `CHARACTER` c, `RAID_ATTENDANCE` d, `RAID_CALENDAR` g ".
			"WHERE c.CHAR_ID = d.CHAR_ID ".
			"AND d.RAID_ID = g.RAID_ID ".
			"AND d.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '0', d.ATTENDANCE ) <>0 ".
			"AND g.SCHEDULED = 1 ".
			"AND g.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 30  ".
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
			"AND rci30.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 30 DAY ) )  ".
			"GROUP BY ilm30.CHAR_ID ".
			")main_spec ON main_spec.CHAR_ID = chr30dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ila30.CHAR_ID, count( ila30.ITEM_ID ) as_total ".
			"FROM ITEMS_LOOTED ila30, RAID_CALENDAR rci30 ".
			"WHERE ila30.RAID_ID = rci30.RAID_ID ".
			"AND ila30.SPEC = 'Alt' ".
			"AND rci30.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 30 DAY ) )  ".
			"GROUP BY ila30.CHAR_ID ".
			")alt_spec ON alt_spec.CHAR_ID = chr30dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ilo30.CHAR_ID, count( ilo30.ITEM_ID ) os_total ".
			"FROM ITEMS_LOOTED ilo30, RAID_CALENDAR rci30 ".
			"WHERE ilo30.RAID_ID = rci30.RAID_ID ".
			"AND ilo30.SPEC = 'Off' ".
			"AND rci30.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 30 DAY ) )  ".
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
			"AND f.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 60  ".
			"DAY ) )  ".
			"UNION  ".
			"SELECT c.CHAR_ID, d.ATTENDANCE ".
			"FROM `CHARACTER` c, `RAID_ATTENDANCE` d, `RAID_CALENDAR` g ".
			"WHERE c.CHAR_ID = d.CHAR_ID ".
			"AND d.RAID_ID = g.RAID_ID ".
			"AND d.ATTENDANCE NOT LIKE 'Friend%' ".
			"AND LOCATE( '0', d.ATTENDANCE ) <>0 ".
			"AND g.SCHEDULED = 1 ".
			"AND g.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 60  ".
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
			"AND rci60.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 60 DAY ) )  ".
			"GROUP BY ilm60.CHAR_ID ".
			")main_spec ON main_spec.CHAR_ID = chr60dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ila60.CHAR_ID, count( ila60.ITEM_ID ) as_total ".
			"FROM ITEMS_LOOTED ila60, RAID_CALENDAR rci60 ".
			"WHERE ila60.RAID_ID = rci60.RAID_ID ".
			"AND ila60.SPEC = 'Alt' ".
			"AND rci60.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 60 DAY ) )  ".
			"GROUP BY ila60.CHAR_ID ".
			")alt_spec ON alt_spec.CHAR_ID = chr60dl.CHAR_ID ".
			"LEFT JOIN (  ".
			"SELECT ilo60.CHAR_ID, count( ilo60.ITEM_ID ) os_total ".
			"FROM ITEMS_LOOTED ilo60, RAID_CALENDAR rci60 ".
			"WHERE ilo60.RAID_ID = rci60.RAID_ID ".
			"AND ilo60.SPEC = 'Off' ".
			"AND rci60.DATE > DATE( DATE_SUB( LOCALTIME( ) , INTERVAL 60 DAY ) )  ".
			"GROUP BY ilo60.CHAR_ID ".
			")off_spec ON off_spec.CHAR_ID = chr60dl.CHAR_ID) 60dl ".
			"ON 60dl.CHAR_ID = chr.CHAR_ID ".
			"WHERE chr.RANK not like 'Alt%' " .
			"AND chr.RANK not like 'Friend%' " .
			"AND chr.RANK not like '' " .
			"ORDER BY chr.NAME;");
  	print "<HTML>\n";
	print "<script src=\"sorttable.js\"></script>\n";
	print "<TABLE class=\"sortable\" style=\"filter:alpha(opacity=75);-moz-opacity:.75;opacity:.75;\" BORDER=2 ALIGN=LEFT><TR>";
	print "<TH WIDTH=90><U><B><font color=black>Name</B></U></TH>";
	print "<TH WIDTH=100><U><B>Class</B></U></TH>";
	print "<TH WIDTH=100><U><B>Rank</B></U></TH>";
	print "<TH WIDTH=120><U><B>7 Day Attn</B></U></TH>";
	print "<TH WIDTH=40><U><B>MS</B></U></TH>";
	print "<TH WIDTH=40><U><B>AS</B></U></TH>";
	print "<TH WIDTH=40><U><B>OS</B></U></TH>";
	print "<TH WIDTH=120><U><B>30 Day Attn</B></U></TH>";
	print "<TH WIDTH=40><U><B>MS</B></U></TH>";
	print "<TH WIDTH=40><U><B>AS</B></U></TH>";
	print "<TH WIDTH=40><U><B>OS</B></U></TH>";
	print "<TH WIDTH=120><U><B>60 Day Attn</B></U></TH>";
	print "<TH WIDTH=40><U><B>MS</B></U></TH>";
	print "<TH WIDTH=40><U><B>AS</B></U></TH>";
	print "<TH WIDTH=40><U><B>OS</B></U></TH></TR>\n";
	$statement->execute() or die $dbh->errstr;
	while (my $row = $statement->fetchrow_hashref()) {
		print "<TR>";
		print "<TD><B><A HREF=\"char.shtml?data=$row->{NAME}\"> $row->{NAME} </A></B></TD>";
		print "<TD>$row->{CLASS}</TD><TD>$row->{RANK}</TD>";
		print "<TD>$row->{'7day'}</TD><TD>$row->{'7MS'}</TD><TD>$row->{'7AS'}</TD><TD>$row->{'7OS'}</TD>";
		print "<TD>$row->{'30day'}</TD><TD>$row->{'30MS'}</TD><TD>$row->{'30AS'}</TD><TD>$row->{'30OS'}</TD>";
		print "<TD>$row->{'60day'}</TD><TD>$row->{'60MS'}</TD><TD>$row->{'60AS'}</TD><TD>$row->{'60OS'}</TD>";
		print "</TR>\n";
		print "\n";
	}
	print "</TABLE>";
	print "</HTML>";
	$statement->finish();
$dbh->disconnect();
print "</pre>";
