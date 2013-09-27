#!/usr/bin/perl

use warnings;
use strict;

use LWP::UserAgent;
use HTTP::Request::Common qw( POST );
use Getopt::Long::Descriptive;
use Params::Validate qw(:all);
use JSON;
use Config::Any;
use Data::Dumper;

my $config_path = "$ENV{HOME}/.itmages.conf";

#get options
my @opts = (
    [ "username|u=s"    => "Username",                      { type => SCALAR, optional => 1 } ],
    [ "password|p=s"    => "Password",                      { type => SCALAR, optional => 1 } ],
    [ "config|c=s"      => "Path to configuration file",    { type => SCALAR, default => $config_path } ],
    [ "configure"       => "Configure programm",            { optional => 1 } ],
    [ "help|h"          => "Print usage message and exit",  { optional => 1 } ],
);

my ( $opts, $usage );
my $desc = "Picture uploade script for itmages.ru";

my $format = "$desc\nUsage:\n%c %o";

( $opts, $usage ) = describe_options( $format, @opts );

print($usage->text), exit if $opts->help;

setup_config( $opts->config ) unless -e $opts->config;
setup_config() if $opts->configure;

#get path to file or folder
my $path = $ARGV[0];
die "You must specify upload files" unless $path;

#get session params
my $user = $opts->username;
my $pass = $opts->password;

#upload file
my $lwp = LWP::UserAgent->new();
my $request = POST( 'http://itmages.ru/api/v3/pictures/',
                   'Content-Type' => 'form-data',
                    $user ? ('X-Username' => $user) : '',
                    $pass ? ('X-Password' => $pass) : '',
                    Content => [
                        "file" => [ $path, $path, content_type => 'image/png' ],
                    ],
);
my $response = $lwp->request( $request );
die $response->status_line, "\n" unless $response->is_success;

#get links to image
my $picture = from_json( $response->content )->{success};
my $link = 'http://itmages.ru/image/view/'.$picture->{pictureId}.'/'.$picture->{key};
my $direct_link = 'http://'.$picture->{storage}.'.static.itmages.ru/'.$picture->{picture};
print "Link to image: $link\nDirect link to image: $direct_link\n";

sub setup_config ($) {
    my $config_file = shift;

    print "This helper will help you to configure itmages.ru upload script\n";
    print "Would you like to get direct links for uploaded images?(default \"no\")\n";
}