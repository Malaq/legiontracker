#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

# For debug output
print "<pre>";
print "<A HREF=\"index.shtml\">";
print "<img src=\"images/tg_logo.jpg\">";
print "</A>";
print "<A HREF=\"http://wowwebstats.com/cdxnr4iegef2w\"> ";
print "<img src=\"images/a_logo.gif\" align=\"top\" alt=\"WWS icon\">";
print "</A>";
print "</pre>";
