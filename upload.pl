#!/usr/bin/perl

use warnings;
use strict;

use LWP;
use HTTP::Cookies;
use HTTP::Request;
use Template;
use JSON;
use Getopt::Long::Descriptive;
use Params::Validate qw(:all);
use Data::Dumper;

#get options
my @opts = (
    [ "username|u=s"    => "Username",                      { type => SCALAR, required => 1 } ],
    [ "password|p=s"    => "Password",                      { type => SCALAR, required => 1 } ],
    [ "help|h"          => "Print usage message and exit",  {optional => 1}],
);

my ( $opts, $usage );
my $desc = "Picture uploade script for itmages.ru";

my $format = "$desc\nUsage:\n%c %o";

( $opts, $usage ) = describe_options( $format, @opts );

print($usage->text), exit if $opts->help;

#get session params
my $username = $opts->username;
my $password = $opts->password;

#start session
my $lwp = LWP::UserAgent->new();
my $request = HTTP::Request->new(GET => "https://itmages.ru/api/v3/pictures/");
$request->header('X-Username' => $username);
$request->header('X-Password' => $password);
my $response = $lwp->request($request);
die $response->status_line, "\n" unless $response->is_success;
warn Dumper $response;