#!/usr/bin/perl

use warnings;
use strict;

use LWP;
use HTTP::Request::Common qw(POST);
use Getopt::Long::Descriptive;
use Params::Validate qw(:all);
use Data::Dumper;

my $config_path = "$ENV{HOME}/.itmages.conf";

#get options
my @opts = (
    [ "user=s"      => "Username",                      { type => SCALAR, optinal => 1 } ],
    [ "pass=s"      => "Password",                      { type => SCALAR, optinal => 1 } ],
    [ "path|p=s"    => "Path to file or directory",     { type => SCALAR, default => $ARGV[0] } ],
    [ "config|c=s"  => "Path to configuration file",    { type => SCALAR, default => $config_path } ],
    [ "configure"   => "Configure programm",            { type => SCALAR, optional => 1 } ],
    [ "help|h"      => "Print usage message and exit",  { optional => 1 } ],
);

my ( $opts, $usage );
my $desc = "Picture uploade script for itmages.ru";

my $format = "$desc\nUsage:\n%c %o";

( $opts, $usage ) = describe_options( $format, @opts );

print($usage->text), exit if $opts->help;

#get session params
my $username = $opts->user;
my $password = $opts->pass;

#start session
my $lwp = LWP::UserAgent->new();
my $request = POST('https://itmages.ru/api/v3/pictures/',
Content => [
"UFileManager[picture]" => "",
"UFileManager[picture]" => [ $opts->path,
               $opts->path,
               Content_Type => 'image/png' ],
yt0 => "Upload",
]);
$request->header('X-Username' => $username);
$request->header('X-Password' => $password);
my $response = $lwp->request($request);
die $response->status_line, "\n" unless $response->is_success;
