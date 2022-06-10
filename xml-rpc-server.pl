#!/usr/bin/perl

use strict;
use warnings;
use EGA::Utils;
use RPC::XML;
use RPC::XML::Server;
use EGA::MidnightFF;
use Data::Dumper;
use LWP::Protocol::https;


my $host    = '192.168.0.70';
#my $host    = 'http://services.ceprinter.com';
my $port    = 8888;

my $daemon  = RPC::XML::Server->new( 
		    host => $host, 
		    port => $port,
		    #	    url  => 'https://services.ceprintercom',
		);

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
    print STDERR "{ATTEMPT}";
    #print Dumper $xml;
    Four51toMFF( $xml );

    my $timestamp   = TimeStamp();
    my $response    = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE cXML SYSTEM "http://xml.cXML.org/schemas/cXML/1.1.009/cXML.dtd">
<cXML payloadID="foo&commat;ceprinter.com" xml:lang="en-US" timestamp="$timestamp">
    <Response>
	<Status code="200" text="OK" />
    </Response>
</cXML>
EOF
    return $response;
}

