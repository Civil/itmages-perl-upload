#!/usr/bin/perl

use warnings;
use strict;

use LWP::UserAgent;
use HTTP::Request::Common qw( POST );
use Getopt::Long::Descriptive;
use Params::Validate qw(:all);
use JSON qw( from_json );
use Config::General qw( ParseConfig SaveConfig );

sub setup_config($);
sub read_input();
sub upload_file($$);
sub print_link($$);

my $config_path = "$ENV{HOME}/.itmages.conf";

#get options
my @opts = (
    [ "config|c=s"      => "Path to configuration file",    { type => SCALAR, default => $config_path } ],
    [ "configure"       => "Configure programm",            { optional => 1 } ],
    [ "help|h"          => "Print usage message and exit",  { optional => 1 } ],
);

my ( $opts, $usage );
my $desc = "Picture uploade script for itmages.ru";

my $format = "$desc\nUsage:\n%c %o";

( $opts, $usage ) = describe_options( $format, @opts );

print( $usage->text ), exit if $opts->help;

#check configuration
setup_config( $opts->config ) unless -e $opts->config;
setup_config( $opts->config ), exit if $opts->configure;

#get path to file or folder
my $path = $ARGV[ 0 ];
die "You must specify upload files" unless $path;

#parse config
my $config = +{ ParseConfig(
    -ConfigFile => $opts->config,
) };

#get session params
my $user = $config->{ username };
my $pass = $config->{ password };

#upload file
my $lwp = LWP::UserAgent->new();
if ( -d $path ) {
    opendir PATH, $path or die "Cannot read directory: $!";
    my @dir = grep { -f "$path/$_" } readdir PATH;
    foreach my $file ( @dir ) {
        my $response;
        eval { $response = upload_file( $lwp, "$path$file" ) };
        if ( $@ ) {
            print "Failed to upload $path$file: $@";
        } else {
            print_link( $config, $response );
        }
    }
} else {
    my $response;
    eval { $response = upload_file( $lwp, $path ) };
    if ( $@ ) {
        print "Failed to upload $path: $@";
    } else {
        print_link( $config, $response );
    }
}

sub setup_config ($) {
    my $config_file = shift;

    print "This helper will help you to configure itmages.ru upload script\n";

    print "Would you like to get direct links for uploaded images (otherwise you would get links to itmages page) (yes/no)? [no]: ";
    my $direct_links = read_input();
    $direct_links = ($direct_links =~ "yes") ? 1 : 0;

    print "OpenId login is not implemented yet, so you have to register (or use anonymous upload)\n";
    print "Enter your login (or enter nothing if you want to use anonymous mode): ";
    my $username = read_input();

    my $password = '';
    if ( $username ) {
        print "Enter your password: ";
        $password = read_input();
    }

    my %configuration = ( direct_links => $direct_links, username => $username, password => $password );
    SaveConfig( $config_file, \%configuration );

    print "Script is now configured to use.\n";
}

sub read_input () {
    my $input_param = <STDIN>;
    chomp $input_param;
    return $input_param;
}

sub upload_file ($$) {
    my $lwp = shift;
    my $file = shift;

    my $request = POST( 'http://itmages.ru/api/v3/pictures/',
                       'Content-Type' => 'form-data',
                        $user ? ('X-Username' => $user) : '',
                        $pass ? ('X-Password' => $pass) : '',
                        Content => [
                            "file" => [ $file, $file, content_type => 'image/png' ],
                        ],
    );
    my $response = $lwp->request( $request );
    die $response->status_line, "\n" unless $response->is_success;

    return $response;
}

sub print_link ($$) {
    my $config = shift;
    my $response = shift;

    my $picture = from_json( $response->content )->{ success };
    my $link = 'http://itmages.ru/image/view/'.$picture->{ pictureId }.'/'.$picture->{ key };
    my $direct_link = 'http://'.$picture->{ storage }.'.static.itmages.ru/'.$picture->{ picture };
    print "Link to image: $link\n";
    print "Direct link to image: $direct_link\n" if $config->{ direct_links };
}