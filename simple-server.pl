#!/usr/bin/perl

use strict;
use warnings;

{
    package Four51Listener;
    use HTTP::Server::Simple::CGI;
    use base qw( HTTP::Server::Simple::CGI );
    use EGA::Utils;

    my %dispatch = (
	'/toMFF'    => \&toMFF,
    );

    sub handle_request {
	my ( $self, $cgi )  = @_;
	#my $method  = $ENV{ REQUEST_METHOD };

	my $path    = $cgi->path_info();
	my $handler = $dispatch{ $path };

	#print STDERR "$path, $handler\n";

	#if ( $method =~ m/post/i ) {
	if ( ref( $handler ) eq 'CODE' ) {
	    #my $xml = $cgi->param( 'POSTDATA' );
	    #print "[$xml]\n";
	    $handler->( $cgi );
	    print $cgi->header( -type => 'application/xml', -charset => 'ascii' ), response_ok();
	    #print $cgi->header( -type => 'text/plain', -status => '200 OK' );
	    #print "Content-Type: text/xml\r\n\r\n";
	    #print "Content-Type: application/xml; charset=ASCII\n\n";
	    #print STDERR response_ok();
	}
	#	else {
	#    print "Please POST a file.\n";
	#}
    }

    sub toMFF {
	my $cgi	= shift;
	my $xml = $cgi->param( 'POSTDATA' );
	#print STDERR "$xml\n";
	#print $cgi->header( -type => 'text/xml' ), response_ok();
	#print response_ok();
    }

    sub response_ok {
	my $timestamp   = TimeStamp();
	$timestamp	=~ s/\s/T/;
	my $response    = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE cXML SYSTEM "http://xml.cXML.org/schemas/cXML/1.1.009/cXML.dtd">
<cXML payloadID="foo\@ceprinter.com" xml:lang="en-US" timestamp="$timestamp">
    <Response>
	<Status code="200" text="OK" />
    </Response>
</cXML>
EOF
	#print STDERR "$response\n";
	#$response = "HTTP/1.0 200 OK\r\n";
	return $response;
    }
}

my $pid	= Four51Listener->new(8888)->background();
print "Kill $pid to stop server.\n";

