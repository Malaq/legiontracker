#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

print "<P>";
print "<A HREF=\"index.shtml\" STYLE=\"text-decoration:none\">";
print "<B>Home</B>";
print "</A><br>";
print "<A HREF=\"allchars.shtml\" STYLE=\"text-decoration:none\">";
print "<B>Characters</B>";
print "</A><br>";
print "<A HREF=\"raids.shtml\" STYLE=\"text-decoration:none\">";
print "<B>Raids</B>";
print "</A><br>";
print "<A HREF=\"allitems.shtml\" STYLE=\"text-decoration:none\">";
print "<B>Items</B>";
print "</A><br>";
print "<A HREF=\"http://www.tgguild.com/forums\" TARGET=\"_blank\" STYLE=\"text-decoration:none\">";
print "<B>Forums</B>";
print "</A><br>";
print "<A HREF=\"http://wowwebstats.com/cdxnr4iegef2w\" TARGET=\"_blank\" STYLE=\"text-decoration:none\"> ";
print "<B>Wow Web Stats</B>";
print "</A><br>";
print "</P>";
print "<form method=\"GET\" action=\"char.shtml\">\n";
print "<font color=#FFFFFF>Enter a character name:</font><br>";
print "<input type=\"text\" name=\"data\"><br>";
print "<input type=\"submit\" value=\"Submit\" />\n<br>";
print "</form>\n";
print "<form method=\"GET\" action=\"item.shtml\">\n";
print "<font color=#FFFFFF>Enter an item name:</font><br>";
print "<input type=\"text\" name=\"data\"><br>";
print "<input type=\"submit\" value=\"Submit\" />\n<br>";
print "</form>\n";
