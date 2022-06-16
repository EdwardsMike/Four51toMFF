#!/usr/bin/perl
#
# Purpose: 
# Usage: 

use strict;
use warnings;
use EGA::Utils;
use List::Util;
use Getopt::Long;
use EGA::Four51;
use EGA::MidnightFF;

$|++;
$, = "|";
$\ = "\n";

# Start with our config file
my $config  = '/home/customers/Resources/Sitecore/BUYERS.psv';
my $ACCTS   = parse_config( $config );

my @PRODUCTS;

# Now get item details
foreach my $buyer ( sort keys %{ $ACCTS } ) {
    next if $buyer =~ m/^KT/;
    my $mff_id	= $ACCTS->{ $buyer }->{ MFF_ID };
    my $hashref	= inventory_status( $mff_id );

    foreach ( sort keys %{ $hashref } ) {
	my ( $product, $variant );
	if ( m{/} ) {
	    ( $product, $variant ) = split /\//, $_;
	}
	else {
	    $product = $variant = $_;
	}
	my $qty	    = $hashref->{ $_ };
	push @PRODUCTS, [ $product, $variant, $qty ];
    }
}

my $result  = bulk_update_inventory( \@PRODUCTS );


sub parse_config {
    my $fn = shift;
    open my $fh, "<", $fn
	or die "Can't open $fn: $!";
    my %HASH;
    while ( <$fh> ) {
	next if m/BUYER/i;
	chomp;
	my @rec = split '\|', $_, -1;
	$HASH{ $rec[0] }{ MFF_ID } = $rec[3];
    }
    close $fh;
    return \%HASH;
}


