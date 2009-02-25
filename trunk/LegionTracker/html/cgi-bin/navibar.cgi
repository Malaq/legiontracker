#!/usr/bin/perl

# The libraries we're using
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

# Tells the browser that we're outputting HTML
print "Content-type: text/html\n\n";

print "<fieldset>";
print "<legend>Navigation</legend>";
print "<A HREF=\"allchars.shtml\" STYLE=\"text-decoration:none\">";
print "<B>Characters</B>";
print "</A><br>";
print "<A HREF=\"raids.shtml\" STYLE=\"text-decoration:none\">";
print "<B>Raids</B>";
print "</A><br>";
print "<A HREF=\"allitems.shtml\" STYLE=\"text-decoration:none\">";
print "<B>Items</B>";
print "</A><br>";
#print "</fieldset>";

print "<form method=\"GET\" action=\"char.shtml\">\n";
print "<font color=#FFFFFF>Enter a character name:</font><br>";
print "<input type=\"text\" name=\"data\"><br>";
#print "<input type=\"submit\" value=\"Search\" />\n<br>";
print "</form>\n";
print "<form method=\"GET\" action=\"item.shtml\">\n";
print "<font color=#FFFFFF>Enter an item name:</font><br>";
print "<input type=\"text\" name=\"data\"><br>";
#print "<input type=\"submit\" value=\"Search\" />\n<br>";
print "</form>\n";
print "<br>";
print "</fieldset>";

print "<fieldset>";
print "<legend>External Links</legend>";
print "<A HREF=\"http://wowwebstats.com/cdxnr4iegef2w\" TARGET=\"_blank\" STYLE=\"text-decoration:none\"> ";
print "<B>Wow Web Stats</B>";
print "</A><br>";
print "<A HREF=\"http://www.wowmeteronline.com/browse/guild/15265\" TARGET=\"_blank\" STYLE=\"text-decoration:none\"> ";
print "<B>WoW Meter Online</B>";
print "</A><br>";
print "<A HREF=\"http://www.tgguild.com/forums\" TARGET=\"_blank\" STYLE=\"text-decoration:none\">";
print "<B>Forums</B>";
print "</A>";
print "</fieldset>";

print <<DELIMETER;
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("UA-7581504-1");
pageTracker._trackPageview();
} catch(err) {}</script>
DELIMETER

