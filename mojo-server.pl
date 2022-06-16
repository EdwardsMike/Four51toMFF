#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::DOM; # in case you need to parse the incoming XML
use EGA::Utils qw( TimeStamp );
use EGA::Four51;

post '/toMFF' => sub ( $c ) {
    my $body = $c->req->body;
    my $dom = Mojo::DOM->new->xml( 1 )->parse( $body ); # example
    $c->render( 'response', format => 'xml',
        timestamp => ( TimeStamp() =~ s/\s/T/r ) );
    
    save_xml( $dom ); 
    my $ff_order = Four51toMFF( $dom ); # This may silently fail...
};
 
app->start;

__DATA__
@@ response.xml.ep
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE cXML SYSTEM "http://xml.cXML.org/schemas/cXML/1.1.009/cXML.dtd">
<cXML payloadID="mike.edwards@ceprinter.com" xml:lang="en-US" timestamp="<%= $timestamp %>">
    <Response>
    <Status code="200" text="OK" />
    </Response>
</cXML> 
