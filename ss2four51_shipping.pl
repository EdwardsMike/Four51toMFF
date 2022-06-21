#!/usr/bin/perl
#
# Purpose:  Fetch shipments from ShipStation and post the details to Four51/Storefront
# Usage:    ./ss2four51_shipping.pl
#
# Run this from cron at 17:00
#
# TODO May need to add an external file to keep track of 
# used tracking numbers so we don't post the same shipment 
# twice. If we are consistent about running this, we 
# probably won't need to, but I'm sure there will come a 
# day when this script has to be run manually. I think I 
# just talked myself into adding this functionality.

use strict;
use warnings;
use EGA::Utils;
use EGA::ShipStation;
use EGA::Four51;
use List::Util;
use Getopt::Long;
use Date::Calc qw( check_date Add_Delta_Days );
use Carp;
use Data::Dumper;

$|++;
$, = "|";


my $debug++;

# Start with our config file
my $config  = '/home/customers/Resources/Sitecore/BUYERS.psv';
my $ACCTS   = parse_config( $config );

# This is for keeping track of tracking numbers to avoid
# re-posting the same shipment more than once
my $track_file	= '/home/customers/Resources/Sitecore/TRACKING.psv';
my $TRACK	= read_tracking( $track_file );

my $window  = 1;
my $date    = get_date( $window ); # YYYYMMDD


GetOptions( 
	    "debug!"	=> \$debug,
	    "date|d=i"	=> \$date,
);

print STDERR "Using date $date\n"
    if $debug;

unless ( $date =~ m/^\d{8}$/ && check_date( unpack "A4 A2 A2", $date ) ) {
    croak "Must pass a valid date in the format YYYYMMDD!";
}

foreach my $buyer ( sort keys %{ $ACCTS } ) {
    my $store_id    = $ACCTS->{ $buyer }{ SS_STORE };
    print STDERR "Processing $buyer (store ID $store_id)\n"
	if $debug;
    my $shipped	    = fetch_orders_shipped_since_date( $store_id, $date );
    #print Dumper $shipped;

    my @shipments   = @{ $shipped->{ shipments } };
    foreach my $order ( @shipments ) {

	# Check to see if we've already processed this
	if ( $TRACK->{ $order->{ trackingNumber } } ) {
	    next;
	}
	else {
	    write_track( $order->{ trackingNumber } );
	}

	$order->{ carrierCode } = uc $order->{ carrierCode };
	$order->{ carrierCode } =~ s/fedex/FedEx/;

	my %HASH    = (
	    'ORDER_KEY'	=> $order->{ orderKey },
	    'ORDER_ID'	=> $order->{ orderId },
	    'SHIP_ID'	=> $order->{ shipmentId },
	    'CARRIER'	=> $order->{ carrierCode },
	    'TRACKNO'	=> $order->{ trackingNumber },
	    'COST'	=> ( $order->{ shipmentCost } || 0.00 ),
	    'SHIP_DATE'	=> $order->{ shipDate },
	);

	my @items;
	foreach my $item ( @{ $order->{ shipmentItems } } ) {
	    my $qty	    = $item->{ quantity };
	    my $item_key    = $item->{ lineItemKey };
	    push @items, [ $item_key, $qty ];
	}
        $HASH{ ITEMS }  = \@items;

	say STDERR $HASH{ ORDER_KEY }, $HASH{ SHIP_DATE }, @items 
	    if $debug;

	# Mark this as shipped in Storefront
	# We'll pass a data structure for this
	post_Four51_shipment( \%HASH );
    }
    


}

sub get_date {
    my $delta	= shift;
    my ( $day, $month, $year ) = ( localtime )[ 3 .. 5 ];
    $month += 1;
    $year  += 1900;

    my ( $y1, $m1, $d1 ) = Add_Delta_Days( $year, $month, $day, $delta * -1 );
    my $date = sprintf "%04d%02d%02d", $y1, $m1, $d1;
    return $date;
}

sub parse_config {
    my $fn = shift;
    open my $fh, "<", $fn
	or die "Can't open $fn: $!";
    my %HASH;
    while ( <$fh> ) {
	next if m/BUYER/i;
	chomp;
	my @rec = split '\|', $_, -1;
	$HASH{ $rec[0] }{ SS_STORE } = $rec[2];
    }
    close $fh;
    return \%HASH;
}

sub read_track {
    my $fn = shift;
    open my $fh, "<", $fn
	or die "Can't open $fn: $!";
    my %HASH;
    while ( <$fh> ) {
	chomp;
	$HASH{ $_ }++;
    }
    close $fh;
    return \%HASH;
}

sub write_track {
    my $trackno	= shift;
    my $fn	= $track_file;
    open my $fh, ">", $fn
	or die "Can't open $fn: $!";
    print $fh "$trackno\n";
    close $fh;
}
