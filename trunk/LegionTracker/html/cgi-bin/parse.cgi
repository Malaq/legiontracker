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

# Grabs the data that was POST'd under the name 'data'.
my $input = param('data');

@lines = split(/\n/, $input);

# Deal with the data line-by-line
foreach $line (@lines) {
	$type = substr($line, 0, 1);
	$data = substr($line, 1);
	if ($type eq '#') { # Raid info
		($date, $scheduled, $attendees) = split(/\//, $data);

		# Debug output
		print "**Raid info**\tDate: $date\tScheduled: $scheduled\tAttendees: $attendees\n";
		
		#$dbh->do("INSERT INTO RAID_CALENDAR(DATE, SCHEDULED, ATTENDANCE_COUNT) VALUES('2008-12-28', $scheduled, $attendees);") or die $dbh->errstr;
		my $statement =
			$dbh->prepare("INSERT INTO RAID_CALENDAR (DATE, SCHEDULED, ATTENDANCE_COUNT) " .
					"VALUES (?, ?, ?);");
		$statement->bind_param(1, $date);
		$statement->bind_param(2, $scheduled);
		$statement->bind_param(3, $attendees);
		$statement->execute() or die $dbh->errstr;

		my $statement =
			$dbh->prepare("SELECT RAID_ID FROM RAID_CALENDAR " .
					"WHERE DATE=? " .
					"AND SCHEDULED=? " .
					"AND ATTENDANCE_COUNT=?;");
		$statement->bind_param(1, $date);
		$statement->bind_param(2, $scheduled);
		$statement->bind_param(3, $attendees);
		$statement->execute() or die $dbh->errstr;
		$row=$statement->fetchrow_hashref;
		$raid_id = "$row->{RAID_ID}";

		
		print "RAID_ID = $raid_id\n";

		
	} elsif ($type eq '@') { # Attendance info
		($player, $class, $attendance, $rank) = split(/;/, $data);

		# Debug output
		print "**Attendance Info**\tPlayer: $player\tClass: $class\tAttendance: $attendance\tRank: $rank\n";

		my $statement =
			$dbh->prepare("INSERT INTO `CHARACTER`(`NAME`, `CLASS`, `DATE_JOINED`) " .
					"VALUES(?, ?, ?);");
		$statement->bind_param(1, $player);
		$statement->bind_param(2, $class);
		$statement->bind_param(3, $date);
		$statement->execute() or print "$player already exists.\n";

		my $statement =
			$dbh->prepare("SELECT CHAR_ID FROM `CHARACTER` " .
					"WHERE `NAME`=?;");
		$statement->bind_param(1, $player);
		$statement->execute() or die $dbh->errstr;
		$row=$statement->fetchrow_hashref;
		$char_id = "$row->{CHAR_ID}";

		my $statement =
			$dbh->prepare("UPDATE `CHARACTER` " .
					"SET `RANK`=? " .
					"WHERE CHAR_ID=?;");
		$statement->bind_param(1, $rank);
		$statement->bind_param(2, $char_id);
		$statement->execute or die $dbh->errstr;

		print "CHAR_ID = $char_id\n";
		
		my $statement =
			$dbh->prepare("INSERT INTO `RAID_ATTENDANCE`(`CHAR_ID`, `RAID_ID`, `ATTENDANCE`) " .
					"VALUES(?, ?, ?);");
		$statement->bind_param(1, $char_id);
		$statement->bind_param(2, $raid_id);
		$statement->bind_param(3, $attendance);
		$statement->execute() or print "$player already has attendance for this raid.\n";


	} elsif ($type eq '$') { # Loot info
		($player, $item_name, $item_id, $date, $spec, $zone, $subzone) = split(/;/, $data);

		# Debug output
		print "**Item info**\tPlayer: $player\titem: $item_name\tzone: $zone\n";

		my $statement =
			$dbh->prepare("SELECT CHAR_ID FROM `CHARACTER` " .
					"WHERE `NAME`=?;");
		$statement->bind_param(1, $player);
		$statement->execute() or die $dbh->errstr;
		$row=$statement->fetchrow_hashref;
		$char_id = "$row->{CHAR_ID}";

		my $statement = 
			$dbh->prepare("INSERT INTO `ITEM`(`ITEM_ID`, `ITEM_NAME`) " .
					"VALUES(?, ?);");
		$statement->bind_param(1, $item_id);
		$statement->bind_param(2, $item_name);
		$statement->execute or print "$item_name already exists in the database.\n";

		my $statement =
			$dbh->prepare("INSERT INTO `ITEMS_LOOTED`(`CHAR_ID`, `ITEM_ID`, `RAID_ID`, `TIMESTAMP`, `SPEC`, `ZONE`, `SUBZONE`) " .
					"VALUES(?, ?, ?, ?, ?, ?, ?);");
		$statement->bind_param(1, $char_id);
		$statement->bind_param(2, $item_id);
		$statement->bind_param(3, $raid_id);
		$statement->bind_param(4, $date);
		$statement->bind_param(5, $spec);
		$statement->bind_param(6, $zone);
		$statement->bind_param(7, $subzone);
		$statement->execute() or die $dbh->errstr;
	}
}
$dbh->disconnect();
print "</pre>";
