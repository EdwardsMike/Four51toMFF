#!/usr/bin/perl

use strict;
use warnings;
use RPC::XML;
use RPC::XML::Server;
use EGA::MidnightFF;
use Data::Dumper;


my $host    = '192.168.0.70';
#my $host    = 'http://services.ceprinter.com';
my $port    = 8888;

my $daemon  = RPC::XML::Server->new( host => $host, port => $port );

#$daemon->add_method( {
$daemon->add_function( {
	name	    => 'toMFF',
	#	hidden	    => 1,
	signature   => [ 'string' ],
	#code	    => \&Four51toMFF(),
	code	    => \&test,
    });

$daemon->server_loop();

sub test {
    #    my $server_obj  = shift;
    my $xml	    = shift;
    #print Dumper $xml;
    Four51toMFF( $xml );
    return "200";
}

