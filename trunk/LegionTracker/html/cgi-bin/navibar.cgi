#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

#print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";
#print "<HTML>\n";

# For debug output
print "<P>";
print "<A HREF=\"index.shtml\">";
print "<B>Home</B>";
print "</A><br>";
print "<A HREF=\"allchars.shtml\">";
print "<B>Characters</B>";
print "</A><br>";
print "<A HREF=\"raids.shtml\">";
print "<B>Raids</B>";
print "</A><br>";
print "<A HREF=\"allitems.shtml\">";
print "<B>Items</B>";
print "</A><br>";
print "<A HREF=\"http://www.tgguild.com/forums\">";
print "<B>Forums</B>";
print "</A><br>";
print "</P>";
print "<form method=\"GET\" action=\"char.shtml\">\n";
print "Enter a character name:<br>";
print "<input type=\"text\" name=\"data\"><br>";
print "<input type=\"submit\" value=\"Submit\"></input>\n<br>";
print "</form>\n";
print "<form method=\"GET\" action=\"item.shtml\">\n";
print "Enter an item name:<br>";
print "<input type=\"text\" name=\"data\"><br>";
print "<input type=\"submit\" value=\"Submit\"></input>\n<br>";
print "</form>\n";
print "</HTML>";
