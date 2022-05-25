#!/usr/bin/perl
#
## Purpose: 
#Usage: 

use strict;
use warnings;
use Data::Dumper;

use XMLRPC::Lite;

my $xml	    = '<test><foo>FOO</foo></test>';

my $host    = 'http://services.ceprinter.com:8888';
#my $host    = 'http://192.168.0.70:8888';

my $server  = XMLRPC::Lite->proxy( $host );
my $call  = $server->call( 'toMFF', $xml );
die $call->faultstring if $call->fault;
print $call->result . "\n";
