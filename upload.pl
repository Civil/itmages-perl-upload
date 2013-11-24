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
    [ "configure"       => "Configure program",            { optional => 1 } ],
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
        eval { $response = upload_file( $lwp, "$path/$file" ) };
        if ( $@ ) {
            print "Failed to upload $path/$file: $@";
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

    print "Choose what style of links to print:
    1 - direct links to image
    2 - links to itmage page
    3 - BB code link with thumbnail
    4 - BB code link full size
    5 - all links
(1/2/3/4/5)? [2]:";
    my $direct_links = read_input();
    if ( $direct_links eq "1" )  { $direct_links = "1"; }
    elsif( $direct_links eq "2" ){ $direct_links = "2"; }
    elsif( $direct_links eq "3" ){ $direct_links = "3"; }
    elsif( $direct_links eq "4" ){ $direct_links = "4"; }
    elsif( $direct_links eq "5" ){ $direct_links = "5"; }
    else{  $direct_links = "2"; }    

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
    my $choice = $config->{ direct_links };    
    my $response = shift;

    my $picture = from_json( $response->content )->{ success };
    my $link = 'http://itmages.ru/image/view/'.$picture->{ pictureId }.'/'.$picture->{ key };
    my $direct_link = 'http://'.$picture->{ storage }.'.static.itmages.ru/'.$picture->{ picture };
    my $thumbnail_link = 'http://'.$picture->{ storage }.'.static.itmages.ru/'.$picture->{ thumbnail };    

    print "Link to image page: $link\n" if (($choice eq "2") || ($choice eq "5"));
    print "Direct link to image: $direct_link\n" if (($choice eq "1") || ($choice eq "5"));
 
    print "BB code thumbnail: \[url=$link\]\[img\]$thumbnail_link\[/img\]\[/url\]\n" if (($choice eq "3") || ($choice eq "5"));
    print "BB code full size: \[url=$link\]\[img\]$direct_link\[/img\]\[/url\]\n" if (($choice eq "4") || ($choice eq "5"));
    
}
