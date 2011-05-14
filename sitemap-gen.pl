#!/usr/bin/perl

# Taken from here and heavily modified for my needs
# http://groups.google.com/group/google-sitemaps/browse_thread/thread/83b34a59a05a104d/?pli=1

use strict;
use warnings;
use LWP::Simple;

# server base path
my $basepath = "/srv/http";

# site url
my $website = "http://example.com";

# directories to search through -- make this qw(.) for all directories
my @dirs = qw(blog coolstuff otherdir);

# default priority
my $priority = "0.5";

# default change frequency
#   always, hourly, daily, weekly, monthly, yearly, never
my $freq = "monthly";

# sites to submit sitemap to
my @notify = (
    "http://www.google.com/webmasters/sitemaps/ping?sitemap=$website/sitemap.xml",
    "http://www.bing.com/webmaster/ping.aspx?siteMap=$website/sitemap.xml",
    "http://submissions.ask.com/ping?sitemap=$website/sitemap.xml",
    "http://search.yahooapis.com/SiteExplorerService/V1/updateNotification?appid=SitemapWriter&url=$website/sitemap.xml",
);


# let's get started
chdir($basepath);
open(F, ">sitemap.xml");
print F <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOF

# check if we want all directories
if ($#dirs == 0 and $dirs[0] eq '.') {
    my @files = `find . -type f -name "*.html"`;
    print_entries(@files);
}
else {
    # find files in top directory first
    my @files = `find . -maxdepth 1 -type f -name "*.html"`;
    print_entries(@files);

    # now loop over directories requested
    foreach my $dir (@dirs) {
        @files = `find $dir -type f -name "*.html"`;
        print_entries(@files);
    }
}

print F "</urlset>\n";
close F;

# notify search engines
foreach (@notify) {
    get($_);
}

# the real generator
sub print_entries {
    my @files = @_;
    foreach (@files) {
        # clean up filename
        chomp;
        my $badone = $_;
        $badone =~ tr/-_.\/a-zA-Z0-9//cd;
        print if ($badone ne $_);
        s/^\.\///;

        # get file modification time
        my $rfile = "$basepath/$_";
        my $mtime = (stat($rfile))[9];
        my ($sec, $min, $hour, $mday, $mon, $year) = localtime($mtime);
        $year += 1900;
        $mon++;
        my $mod = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2d-04:00",
            $year, $mon, $mday, $hour, $min, $sec);

        # raise frequency for index files
        $freq = "daily" if /index\.html/;

        # if we're at the top index file, generate entry for base url
        if (/^index\.html/) {
            print F <<EOF;
    <url>
        <loc>$website/</loc>
        <lastmod>$mod</lastmod>
        <changefreq>$freq</changefreq>
        <priority>$priority</priority>
    </url>
EOF
        }
        print F <<EOF;
    <url>
        <loc>$website/$_</loc>
        <lastmod>$mod</lastmod>
        <changefreq>$freq</changefreq>
        <priority>$priority</priority>
    </url>
EOF
    }
}
