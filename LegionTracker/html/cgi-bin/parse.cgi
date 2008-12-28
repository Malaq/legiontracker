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
		
		# TODO: Do some kind of insert into the raid table here...
		# Syntax is "$dbh->do(SQL_STATEMENT) or die $dbh->errstr;"
		# e.g. $dbh->do("INSERT INTO RAIDTABLE date=$date") or die $dbh->errstr;

		
	} elsif ($type eq '@') { # Attendance info
		($player, $class, $attendance) = split(/;/, $data);

		# Debug output
		print "**Attendance Info**\tPlayer: $player\tClass: $class\tAttendance: $attendance\n";

		# TODO: Do some kind of SQL here....

	} elsif ($type eq '$') { # Loot info
		($player, $item_name, $item_id, $date, $spec, $zone, $subzone) = split(/;/, $data);

		# Debug output
		print "**Item info**\tPlayer: $player\titem: $item_name\tzone: $zone\n";

		# TODO: Do some kind of SQL here....
	}
}

print "</pre>";
